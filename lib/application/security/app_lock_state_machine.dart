import '../../domain/model/app_settings.dart';

class AppLockDecision {
  const AppLockDecision({required this.requiresUnlock});

  final bool requiresUnlock;
}

class AppLockStateMachine {
  const AppLockStateMachine({DateTime? backgroundedAtUtc})
    : _backgroundedAtUtc = backgroundedAtUtc;

  static const Duration backgroundLockThreshold = Duration(seconds: 30);

  final DateTime? _backgroundedAtUtc;

  AppLockDecision onColdStart(AppSettings settings) {
    return AppLockDecision(requiresUnlock: settings.biometricLockEnabled);
  }

  AppLockStateMachine onBackgrounded(DateTime backgroundedAtUtc) {
    return AppLockStateMachine(backgroundedAtUtc: backgroundedAtUtc);
  }

  AppLockDecision onResumed(DateTime resumedAtUtc, AppSettings settings) {
    final backgroundedAtUtc = _backgroundedAtUtc;
    if (!settings.biometricLockEnabled || backgroundedAtUtc == null) {
      return const AppLockDecision(requiresUnlock: false);
    }

    return AppLockDecision(
      requiresUnlock:
          resumedAtUtc.difference(backgroundedAtUtc) > backgroundLockThreshold,
    );
  }
}
