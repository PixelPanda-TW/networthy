import 'dart:io';

import 'package:networthy/data/security/database_key.dart';
import 'package:networthy/data/spike/encrypted_database_spike.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/encrypted_database_spike_probe.dart <database-path>',
    );
    exitCode = 64;
    return;
  }

  final databasePath = args.single;
  final databaseFile = File(databasePath);
  if (databaseFile.existsSync()) {
    databaseFile.deleteSync();
  }

  final key = DatabaseKey.fromBytes(List<int>.generate(32, (index) => index));
  final probe = Sqlite3MultipleCiphersProbe(databasePath: databasePath);
  await probe.validate(key);

  stdout.writeln('Encrypted database probe completed.');
}
