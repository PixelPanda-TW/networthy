abstract interface class DeviceAuthenticator {
  Future<bool> isDeviceSupported();

  Future<bool> hasEnrolledCredentials();

  Future<bool> canAuthenticate();

  Future<bool> authenticate({required String reason});
}

class NoOpDeviceAuthenticator implements DeviceAuthenticator {
  const NoOpDeviceAuthenticator();

  @override
  Future<bool> authenticate({required String reason}) async => true;

  @override
  Future<bool> canAuthenticate() async => true;

  @override
  Future<bool> hasEnrolledCredentials() async => true;

  @override
  Future<bool> isDeviceSupported() async => true;
}
