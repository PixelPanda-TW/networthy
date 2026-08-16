import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release bundle identifiers are product identifiers', () {
    final androidBuild = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    final iosProject = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final mainActivity = File(
      'android/app/src/main/kotlin/tw/pixelpanda/networthy/MainActivity.kt',
    );

    expect(androidBuild, contains('namespace = "tw.pixelpanda.networthy"'));
    expect(androidBuild, contains('applicationId = "tw.pixelpanda.networthy"'));
    expect(
      iosProject,
      contains('PRODUCT_BUNDLE_IDENTIFIER = tw.pixelpanda.networthy;'),
    );
    expect(mainActivity.existsSync(), isTrue);

    expect(androidBuild, isNot(contains('com.example.networthy')));
    expect(iosProject, isNot(contains('com.example.networthy')));
  });
}
