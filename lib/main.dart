import 'dart:math';

import 'package:flutter/material.dart';

import 'application/common/application_ports.dart';
import 'application/settings/local_data_clearer.dart';
import 'data/database/encrypted_database_opener.dart';
import 'data/repository/clear_local_data.dart';
import 'data/repository/drift_account_repository.dart';
import 'data/repository/drift_category_repository.dart';
import 'data/repository/drift_ledger_repository.dart';
import 'data/repository/drift_settings_repository.dart';
import 'data/repository/drift_transaction_repository.dart';
import 'data/repository/local_data_clearer_adapter.dart';
import 'data/security/database_key_store.dart';
import 'data/security/flutter_secure_storage_secret_store.dart';
import 'domain/repository/settings_repository.dart';
import 'domain/repository/transaction_repository.dart';
import 'domain/repository/category_repository.dart';
import 'domain/repository/account_repository.dart';
import 'domain/repository/ledger_repository.dart';
import 'platform/app_document_database_path.dart';
import 'presentation/app/networthy_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NetworthyBootstrapApp());
}

class NetworthyBootstrapApp extends StatelessWidget {
  const NetworthyBootstrapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppDependencies>(
      future: _createDependencies(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(body: Center(child: Text('本機加密資料無法開啟'))),
          );
        }
        if (!snapshot.hasData) {
          return MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(body: Center(child: Text('載入中'))),
          );
        }
        final dependencies = snapshot.data!;
        return NetworthyApp(
          transactions: dependencies.transactions,
          accounts: dependencies.accounts,
          ledger: dependencies.ledger,
          settings: dependencies.settings,
          categories: dependencies.categories,
          clock: const SystemApplicationClock(),
          idGenerator: SecureUuidV4Generator(),
          localDataClearer: dependencies.localDataClearer,
        );
      },
    );
  }

  Future<_AppDependencies> _createDependencies() async {
    final databasePath = await const AppDocumentDatabasePath().resolve();
    final keyStore = SecureDatabaseKeyStore(
      secrets: FlutterSecureStorageSecretStore(),
    );
    final database = await EncryptedDatabaseOpener(
      databasePath: databasePath,
      keyStore: keyStore,
    ).open();
    final categories = DriftCategoryRepository(database);
    await categories.ensureBuiltInCategoriesSeeded();
    final accounts = DriftAccountRepository(database);
    await accounts.ensureDefaultAccountSeeded();
    return _AppDependencies(
      transactions: DriftTransactionRepository(database),
      accounts: accounts,
      ledger: DriftLedgerRepository(database),
      settings: DriftSettingsRepository(database),
      categories: categories,
      localDataClearer: ClearLocalDataAdapter(
        ClearLocalData(
          databasePath: databasePath,
          keyStore: keyStore,
          preferences: const NoOpLocalPreferencesStore(),
        ),
      ),
    );
  }
}

class _AppDependencies {
  const _AppDependencies({
    required this.transactions,
    required this.accounts,
    required this.ledger,
    required this.settings,
    required this.categories,
    required this.localDataClearer,
  });

  final TransactionRepository transactions;
  final AccountRepository accounts;
  final LedgerRepository ledger;
  final SettingsRepository settings;
  final CategoryRepository categories;
  final LocalDataClearer localDataClearer;
}

class SystemApplicationClock implements ApplicationClock {
  const SystemApplicationClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

class SecureUuidV4Generator implements TransactionIdGenerator {
  SecureUuidV4Generator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  @override
  String generate() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
