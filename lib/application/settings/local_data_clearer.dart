abstract interface class LocalDataClearer {
  Future<void> clear();
}

class NoOpLocalDataClearer implements LocalDataClearer {
  const NoOpLocalDataClearer();

  @override
  Future<void> clear() async {}
}
