import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'networthy_database.g.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text()();
  TextColumn get categoryId => text()();
  IntColumn get transactionYear => integer()();
  IntColumn get transactionMonth => integer()();
  IntColumn get transactionDay => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettingsRows extends Table {
  IntColumn get id => integer()();
  BoolColumn get onboardingCompleted => boolean()();
  BoolColumn get biometricLockEnabled => boolean()();
  TextColumn get currencyCode => text()();
  TextColumn get lastExpenseCategoryId => text().nullable()();
  TextColumn get lastIncomeCategoryId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isArchived => boolean()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get currencyCode => text()();
  BoolColumn get isArchived => boolean()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LedgerTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get transactionYear => integer()();
  IntColumn get transactionMonth => integer()();
  IntColumn get transactionDay => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LedgerEntries extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text()();
  TextColumn get accountId => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text()();
  DateTimeColumn get createdAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StockAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get mode => text()();
  TextColumn get currencyCode => text()();
  BoolColumn get isArchived => boolean()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StockHoldings extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get symbol => text()();
  TextColumn get name => text()();
  TextColumn get mode => text()();
  TextColumn get currencyCode => text()();
  IntColumn get quantityMicro => integer().nullable()();
  IntColumn get averageCostMinor => integer().nullable()();
  IntColumn get currentPriceMinor => integer().nullable()();
  IntColumn get principalMinor => integer().nullable()();
  BoolColumn get isArchived => boolean()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StockTrades extends Table {
  TextColumn get id => text()();
  TextColumn get stockAccountId => text()();
  TextColumn get cashAccountId => text()();
  TextColumn get side => text()();
  TextColumn get symbol => text()();
  TextColumn get name => text()();
  TextColumn get mode => text()();
  TextColumn get currencyCode => text()();
  IntColumn get quantityMicro => integer().nullable()();
  IntColumn get priceMinor => integer().nullable()();
  IntColumn get principalMinor => integer().nullable()();
  IntColumn get tradeYear => integer()();
  IntColumn get tradeMonth => integer()();
  IntColumn get tradeDay => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Transactions,
    AppSettingsRows,
    Categories,
    Accounts,
    LedgerTransactions,
    LedgerEntries,
    StockAccounts,
    StockHoldings,
    StockTrades,
  ],
)
class NetworthyDatabase extends _$NetworthyDatabase {
  NetworthyDatabase(super.executor);

  NetworthyDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(categories);
      }
      if (from < 3) {
        await migrator.createTable(accounts);
        await migrator.createTable(ledgerTransactions);
        await migrator.createTable(ledgerEntries);
        await _migrateV2TransactionsToLedger();
      }
      if (from < 4) {
        await migrator.createTable(stockAccounts);
        await migrator.createTable(stockHoldings);
      }
      if (from < 5) {
        await migrator.createTable(stockTrades);
      }
    },
  );

  Future<void> _migrateV2TransactionsToLedger() async {
    const defaultAccountId = '00000000-0000-4000-8000-000000030000';
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await customStatement(
      '''
      INSERT OR IGNORE INTO accounts (
        id,
        name,
        currency_code,
        is_archived,
        created_at_utc,
        updated_at_utc
      ) VALUES (?, ?, ?, ?, ?, ?);
      ''',
      [defaultAccountId, '現金 TWD', 'TWD', 0, now, now],
    );

    final existingTransactions = await customSelect('''
      SELECT
        id,
        type,
        amount_minor,
        currency_code,
        category_id,
        transaction_year,
        transaction_month,
        transaction_day,
        note,
        created_at_utc,
        updated_at_utc
      FROM transactions;
      ''').get();
    for (final row in existingTransactions) {
      final id = row.read<String>('id');
      final type = row.read<String>('type');
      final amountMinor = row.read<int>('amount_minor');
      final signedAmount = type == 'expense' ? -amountMinor : amountMinor;
      final currencyCode = row.read<String>('currency_code');
      final createdAtUtc = row.read<int>('created_at_utc');
      await customStatement(
        '''
        INSERT OR IGNORE INTO ledger_transactions (
          id,
          type,
          category_id,
          transaction_year,
          transaction_month,
          transaction_day,
          note,
          created_at_utc,
          updated_at_utc
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        ''',
        [
          id,
          type,
          row.read<String>('category_id'),
          row.read<int>('transaction_year'),
          row.read<int>('transaction_month'),
          row.read<int>('transaction_day'),
          row.readNullable<String>('note'),
          createdAtUtc,
          row.read<int>('updated_at_utc'),
        ],
      );
      await customStatement(
        '''
        INSERT OR IGNORE INTO ledger_entries (
          id,
          transaction_id,
          account_id,
          amount_minor,
          currency_code,
          created_at_utc
        ) VALUES (?, ?, ?, ?, ?, ?);
        ''',
        [id, id, defaultAccountId, signedAmount, currencyCode, createdAtUtc],
      );
    }
  }
}
