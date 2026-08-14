enum EncryptedDatabaseSpikeStatus {
  success,
  missingKey,
  wrongKeyRejected,
  providerValidationFailed,
}

class EncryptedDatabaseSpikeResult {
  const EncryptedDatabaseSpikeResult({
    required this.status,
    required this.safeMessage,
  });

  final EncryptedDatabaseSpikeStatus status;
  final String safeMessage;
}
