import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib source does not use raw logging APIs', () {
    final rawLoggingPattern = RegExp(
      r'(^|[^\w.])(print|debugPrint|log)\s*\(',
      multiLine: true,
    );
    final offenders = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) {
        continue;
      }
      final contents = file.readAsStringSync();
      if (rawLoggingPattern.hasMatch(contents)) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use an explicit safe logging adapter and never log amounts, notes, '
          'database paths, encryption keys, or authentication state.',
    );
  });
}
