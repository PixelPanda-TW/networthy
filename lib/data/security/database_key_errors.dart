class DatabaseKeyMissingException implements Exception {
  const DatabaseKeyMissingException();

  @override
  String toString() {
    return 'DatabaseKeyMissingException';
  }
}

class DatabaseKeyInvalidException implements Exception {
  const DatabaseKeyInvalidException();

  @override
  String toString() {
    return 'DatabaseKeyInvalidException';
  }
}
