import 'package:flutter/material.dart';
import 'package:networthy/data/security/flutter_secure_storage_secret_store.dart';
import 'package:networthy/data/security/database_key_store.dart';
import 'package:networthy/data/spike/encrypted_database_spike.dart';
import 'package:networthy/data/spike/encrypted_database_spike_result.dart';
import 'package:networthy/platform/app_document_database_path.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(runSpike: runAppEncryptedDatabaseSpike));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.runSpike});

  final Future<EncryptedDatabaseSpikeResult> Function()? runSpike;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Encrypted Database Spike')),
        body: Center(
          child: runSpike == null
              ? const Text('Spike runner disabled')
              : FutureBuilder<EncryptedDatabaseSpikeResult>(
                  future: runSpike!(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text('Running encrypted database spike');
                    }

                    return Text(snapshot.data!.safeMessage);
                  },
                ),
        ),
      ),
    );
  }
}

Future<EncryptedDatabaseSpikeResult> runAppEncryptedDatabaseSpike() async {
  final path = await const AppDocumentDatabasePath().resolve();
  final spike = EncryptedDatabaseSpike(
    databaseExists: () => databaseFileExists(path),
    keyStore: SecureDatabaseKeyStore(
      secrets: FlutterSecureStorageSecretStore(),
    ),
    probe: Sqlite3MultipleCiphersProbe(databasePath: path),
  );

  return spike.run();
}
