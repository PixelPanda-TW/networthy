import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../application/security/app_lock_state_machine.dart';
import '../../application/security/device_authenticator.dart';
import '../../application/settings/local_data_clearer.dart';
import '../../application/settings/onboarding_use_case.dart';
import '../../domain/model/app_settings.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/transaction_repository.dart';
import '../home/home_shell.dart';
import '../security/lock_screen.dart';

class NetworthyApp extends StatelessWidget {
  const NetworthyApp({
    super.key,
    required this.transactions,
    required this.settings,
    required this.clock,
    required this.idGenerator,
    this.authenticator = const NoOpDeviceAuthenticator(),
    this.localDataClearer = const NoOpLocalDataClearer(),
    this.initialDate,
  });

  final TransactionRepository transactions;
  final SettingsRepository settings;
  final ApplicationClock clock;
  final TransactionIdGenerator idGenerator;
  final DeviceAuthenticator authenticator;
  final LocalDataClearer localDataClearer;
  final DateTime? initialDate;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: _AppGate(
        transactions: transactions,
        settings: settings,
        clock: clock,
        idGenerator: idGenerator,
        authenticator: authenticator,
        localDataClearer: localDataClearer,
        initialDate: initialDate,
      ),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate({
    required this.transactions,
    required this.settings,
    required this.clock,
    required this.idGenerator,
    required this.authenticator,
    required this.localDataClearer,
    this.initialDate,
  });

  final TransactionRepository transactions;
  final SettingsRepository settings;
  final ApplicationClock clock;
  final TransactionIdGenerator idGenerator;
  final DeviceAuthenticator authenticator;
  final LocalDataClearer localDataClearer;
  final DateTime? initialDate;

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> with WidgetsBindingObserver {
  late Future<AppSettings> _settingsFuture;
  var _locked = false;
  var _coldStartDecisionApplied = false;
  var _privacyOverlayVisible = false;
  AppLockStateMachine _lockStateMachine = const AppLockStateMachine();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settingsFuture = widget.settings.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      setState(() {
        _privacyOverlayVisible = true;
        _lockStateMachine = _lockStateMachine.onBackgrounded(
          widget.clock.nowUtc(),
        );
      });
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _settingsFuture.then((settings) {
        if (!mounted) {
          return;
        }
        final decision = _lockStateMachine.onResumed(
          widget.clock.nowUtc(),
          settings,
        );
        setState(() {
          _privacyOverlayVisible = false;
          _locked = decision.requiresUnlock;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppSettings>(
      future: _settingsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('載入中')));
        }

        final settings = snapshot.data!;
        if (!_coldStartDecisionApplied && settings.biometricLockEnabled) {
          final decision = const AppLockStateMachine().onColdStart(settings);
          _coldStartDecisionApplied = true;
          if (decision.requiresUnlock) {
            _locked = true;
          }
        } else if (!_coldStartDecisionApplied) {
          _coldStartDecisionApplied = true;
        }

        if (_locked) {
          return LockScreen(
            authenticator: widget.authenticator,
            onUnlocked: () => setState(() => _locked = false),
          );
        }

        if (!snapshot.data!.onboardingCompleted) {
          return _OnboardingPage(
            onComplete: () async {
              await CompleteOnboardingUseCase(widget.settings).execute();
              setState(() {
                _settingsFuture = widget.settings.load();
              });
            },
          );
        }

        if (_privacyOverlayVisible) {
          return const Scaffold(body: Center(child: Text('隱私保護中')));
        }

        return HomeShell(
          transactions: widget.transactions,
          settings: widget.settings,
          clock: widget.clock,
          idGenerator: widget.idGenerator,
          authenticator: widget.authenticator,
          localDataClearer: widget.localDataClearer,
          onResetToFirstUse: () {
            setState(() {
              _locked = false;
              _coldStartDecisionApplied = true;
              _settingsFuture = widget.settings.load();
            });
          },
          initialDate: widget.initialDate,
        );
      },
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Networthy')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('資料只存在這台裝置', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text(
              '這是離線記帳 App。解除安裝或清除 App 資料會造成本機資料遺失；V1 不提供雲端同步、備份或帳號登入。',
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onComplete, child: const Text('開始使用')),
          ],
        ),
      ),
    );
  }
}
