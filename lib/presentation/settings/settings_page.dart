import 'package:flutter/material.dart';

import '../../application/security/device_authenticator.dart';
import '../../application/settings/local_data_clearer.dart';
import '../../domain/model/app_settings.dart';
import '../../domain/repository/category_repository.dart';
import '../../domain/repository/settings_repository.dart';
import 'category_management_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.categories,
    required this.authenticator,
    required this.localDataClearer,
    required this.onResetToFirstUse,
  });

  final SettingsRepository settings;
  final CategoryRepository categories;
  final DeviceAuthenticator authenticator;
  final LocalDataClearer localDataClearer;
  final VoidCallback onResetToFirstUse;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<AppSettings> _settingsFuture;
  String? _message;

  @override
  void initState() {
    super.initState();
    _settingsFuture = widget.settings.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: FutureBuilder<AppSettings>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text('載入中'));
          }
          final settings = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('版本 0.1.0', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              const Text('資料只儲存在這台裝置。'),
              const Text('解除安裝或清除 App 資料會刪除本機記帳資料。'),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('分類管理'),
                subtitle: const Text('新增、重新命名或封存分類'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openCategoryManagement,
              ),
              const SizedBox(height: 24),
              Semantics(
                label: '啟用或停用 App 鎖定',
                toggled: settings.biometricLockEnabled,
                child: SwitchListTile(
                  title: const Text('App 鎖定'),
                  subtitle: const Text('使用系統驗證保護記帳內容'),
                  value: settings.biometricLockEnabled,
                  onChanged: (value) => _setAppLock(settings, value),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                label: '清除所有本機資料',
                button: true,
                child: FilledButton.tonal(
                  onPressed: () => _clearAllData(settings),
                  child: const Text('清除所有資料'),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 8),
                Text(
                  _message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _setAppLock(AppSettings current, bool enabled) async {
    if (enabled) {
      final canAuthenticate = await widget.authenticator.canAuthenticate();
      if (!canAuthenticate) {
        setState(() {
          _message = '此裝置尚未設定可用的系統驗證。';
        });
        return;
      }
    }

    await widget.settings.save(
      AppSettings(
        onboardingCompleted: current.onboardingCompleted,
        biometricLockEnabled: enabled,
        currencyCode: current.currencyCode,
        lastExpenseCategoryId: current.lastExpenseCategoryId,
        lastIncomeCategoryId: current.lastIncomeCategoryId,
      ),
    );
    setState(() {
      _message = null;
      _settingsFuture = widget.settings.load();
    });
  }

  Future<void> _openCategoryManagement() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) =>
            CategoryManagementPage(categories: widget.categories),
      ),
    );
  }

  Future<void> _clearAllData(AppSettings current) async {
    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('第一次確認'),
        content: const Text('這會清除所有本機記帳資料。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('繼續'),
          ),
        ],
      ),
    );
    if (firstConfirmed != true || !mounted) {
      return;
    }

    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最後確認'),
        content: const Text('清除後無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (secondConfirmed != true || !mounted) {
      return;
    }

    if (current.biometricLockEnabled) {
      final authenticated = await widget.authenticator.authenticate(
        reason: '清除所有資料',
      );
      if (!authenticated || !mounted) {
        setState(() => _message = '系統驗證失敗，未清除資料。');
        return;
      }
    }

    await widget.localDataClearer.clear();
    await widget.settings.save(const AppSettings.defaults());
    widget.onResetToFirstUse();
  }
}
