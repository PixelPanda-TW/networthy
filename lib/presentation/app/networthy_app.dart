import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../application/settings/onboarding_use_case.dart';
import '../../domain/model/app_settings.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/transaction_repository.dart';
import '../home/home_shell.dart';

class NetworthyApp extends StatelessWidget {
  const NetworthyApp({
    super.key,
    required this.transactions,
    required this.settings,
    required this.clock,
    required this.idGenerator,
    this.initialDate,
  });

  final TransactionRepository transactions;
  final SettingsRepository settings;
  final ApplicationClock clock;
  final TransactionIdGenerator idGenerator;
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
    this.initialDate,
  });

  final TransactionRepository transactions;
  final SettingsRepository settings;
  final ApplicationClock clock;
  final TransactionIdGenerator idGenerator;
  final DateTime? initialDate;

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  late Future<AppSettings> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = widget.settings.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppSettings>(
      future: _settingsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('載入中')));
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

        return HomeShell(
          transactions: widget.transactions,
          settings: widget.settings,
          clock: widget.clock,
          idGenerator: widget.idGenerator,
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
