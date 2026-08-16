enum ApplicationFailureType { decryption, persistence, validation }

class ApplicationDecryptionException implements Exception {
  const ApplicationDecryptionException();
}

class ApplicationFailure {
  const ApplicationFailure({required this.type, required this.safeMessage});

  final ApplicationFailureType type;
  final String safeMessage;

  factory ApplicationFailure.decryption() {
    return const ApplicationFailure(
      type: ApplicationFailureType.decryption,
      safeMessage: 'Local data could not be unlocked.',
    );
  }

  factory ApplicationFailure.persistence() {
    return const ApplicationFailure(
      type: ApplicationFailureType.persistence,
      safeMessage: 'Local data could not be saved or loaded.',
    );
  }

  factory ApplicationFailure.validation(String safeMessage) {
    return ApplicationFailure(
      type: ApplicationFailureType.validation,
      safeMessage: safeMessage,
    );
  }

  factory ApplicationFailure.fromException(Exception exception) {
    if (exception is ApplicationDecryptionException) {
      return ApplicationFailure.decryption();
    }
    return ApplicationFailure.persistence();
  }
}
