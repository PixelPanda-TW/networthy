import 'package:flutter/material.dart';

import '../../application/security/device_authenticator.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.authenticator,
    required this.onUnlocked,
  });

  final DeviceAuthenticator authenticator;
  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('已鎖定', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              const Text('請使用裝置驗證解鎖 Networthy。'),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(onPressed: _unlock, child: const Text('解鎖')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unlock() async {
    final ok = await widget.authenticator.authenticate(reason: '解鎖 Networthy');
    if (!mounted) {
      return;
    }
    if (ok) {
      widget.onUnlocked();
      return;
    }
    setState(() {
      _error = '驗證失敗，請再試一次。';
    });
  }
}
