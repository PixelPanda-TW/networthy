import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/common/application_failure.dart';

void main() {
  group('ApplicationFailure', () {
    test(
      'classifies decryption failures separately from persistence failures',
      () {
        final decryption = ApplicationFailure.decryption();
        final persistence = ApplicationFailure.persistence();

        expect(decryption.type, ApplicationFailureType.decryption);
        expect(persistence.type, ApplicationFailureType.persistence);
      },
    );

    test('uses non-sensitive safe messages for failures', () {
      expect(ApplicationFailure.decryption().safeMessage, isNotEmpty);
      expect(ApplicationFailure.persistence().safeMessage, isNotEmpty);
      expect(
        ApplicationFailure.persistence().safeMessage,
        isNot(contains('/Users/')),
      );
    });
  });
}
