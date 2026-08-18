import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/networthy_database.dart';
import 'package:networthy/data/repository/drift_category_repository.dart';
import 'package:networthy/data/repository/drift_account_repository.dart';
import 'package:networthy/data/repository/drift_ledger_repository.dart';
import 'package:networthy/data/repository/drift_transaction_repository.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/ledger_transaction.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/repository/ledger_repository.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('schema v5 creates stock trades and preserves v4 stock tables', () async {
    final database = NetworthyDatabase.inMemory();
    addTearDown(database.close);

    final tables = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();

    expect(database.schemaVersion, 5);
    expect(
      tables.map((row) => row.read<String>('name')),
      contains('stock_trades'),
    );
    expect(
      tables.map((row) => row.read<String>('name')),
      contains('stock_holdings'),
    );
  });

  test(
    'migration to schema 4 creates stock tables and preserves ledger data',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'networthy-stock-migration-',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final databaseFile = File('${tempDir.path}/networthy.db');
      _createSchemaVersion3Database(databaseFile);

      final database = NetworthyDatabase(NativeDatabase(databaseFile));
      addTearDown(database.close);
      final transaction = await DriftTransactionRepository(
        database,
      ).findById('00000000-0000-4000-8000-000000043001');
      final tables = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();

      expect(transaction?.amountMinor, 888);
      expect(
        tables.map((row) => row.read<String>('name')),
        contains('stock_accounts'),
      );
      expect(
        tables.map((row) => row.read<String>('name')),
        contains('stock_holdings'),
      );
    },
  );

  test('baseline migration preserves existing schema version 1 data', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'networthy-migration-',
    );
    addTearDown(() => tempDir.delete(recursive: true));
    final databaseFile = File('${tempDir.path}/networthy.db');

    final originalDatabase = NetworthyDatabase(NativeDatabase(databaseFile));
    addTearDown(originalDatabase.close);
    await DriftTransactionRepository(originalDatabase).save(
      BookkeepingTransaction.create(
        id: '00000000-0000-4000-8000-000000000301',
        type: TransactionType.expense,
        amountMinor: 777,
        categoryId: 'expense.food',
        transactionDate: LocalDate(2026, 8, 16),
        createdAtUtc: DateTime.utc(2026, 8, 16, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 16, 1),
      ),
    );
    await originalDatabase.close();

    final reopenedDatabase = NetworthyDatabase(NativeDatabase(databaseFile));
    addTearDown(reopenedDatabase.close);
    final transaction = await DriftTransactionRepository(
      reopenedDatabase,
    ).findById('00000000-0000-4000-8000-000000000301');

    expect(transaction?.amountMinor, 777);
  });

  test(
    'migration to schema 2 seeds categories and preserves transactions',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'networthy-category-migration-',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final databaseFile = File('${tempDir.path}/networthy.db');
      _createSchemaVersion1Database(databaseFile);

      final reopenedDatabase = NetworthyDatabase(NativeDatabase(databaseFile));
      addTearDown(reopenedDatabase.close);
      final transactions = DriftTransactionRepository(reopenedDatabase);
      final categories = DriftCategoryRepository(reopenedDatabase);
      await categories.ensureBuiltInCategoriesSeeded();

      final transaction = await transactions.findById(
        '00000000-0000-4000-8000-000000000309',
      );
      expect(transaction?.amountMinor, 777);
      expect(await categories.displayPathFor('expense.food'), '餐飲');
    },
  );

  test(
    'migration to schema 3 converts v2 transactions into ledger rows',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'networthy-ledger-migration-',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final databaseFile = File('${tempDir.path}/networthy.db');
      _createSchemaVersion2Database(databaseFile);

      final reopenedDatabase = NetworthyDatabase(NativeDatabase(databaseFile));
      addTearDown(reopenedDatabase.close);
      final accounts = DriftAccountRepository(reopenedDatabase);
      final ledger = DriftLedgerRepository(reopenedDatabase);

      final allAccounts = await accounts.listAll();
      expect(allAccounts, hasLength(1));
      expect(allAccounts.single.name, '現金 TWD');
      expect(allAccounts.single.currencyCode, CurrencyCode.twd);

      final records = await ledger.list(
        const LedgerQuery(year: 2026, month: 8),
      );
      expect(records, hasLength(2));
      expect(records.map((record) => record.transaction.type).toSet(), {
        LedgerTransactionType.income,
        LedgerTransactionType.expense,
      });

      final income = records.singleWhere(
        (record) => record.transaction.type == LedgerTransactionType.income,
      );
      final expense = records.singleWhere(
        (record) => record.transaction.type == LedgerTransactionType.expense,
      );
      expect(income.transaction.categoryId, 'income.salary');
      expect(income.transaction.note, 'salary');
      expect(income.entries.single.amountMinor, 5000);
      expect(expense.transaction.categoryId, 'expense.food');
      expect(expense.transaction.note, 'lunch');
      expect(expense.entries.single.amountMinor, -777);
    },
  );
}

void _createSchemaVersion3Database(File databaseFile) {
  final database = sqlite3.open(databaseFile.path);
  try {
    database.execute('''
      CREATE TABLE transactions (
        id TEXT NOT NULL PRIMARY KEY, type TEXT NOT NULL,
        amount_minor INTEGER NOT NULL, currency_code TEXT NOT NULL,
        category_id TEXT NOT NULL, transaction_year INTEGER NOT NULL,
        transaction_month INTEGER NOT NULL, transaction_day INTEGER NOT NULL,
        note TEXT NULL, created_at_utc INTEGER NOT NULL,
        updated_at_utc INTEGER NOT NULL
      );
      CREATE TABLE app_settings_rows (
        id INTEGER NOT NULL PRIMARY KEY, onboarding_completed INTEGER NOT NULL,
        biometric_lock_enabled INTEGER NOT NULL, currency_code TEXT NOT NULL,
        last_expense_category_id TEXT NULL, last_income_category_id TEXT NULL
      );
      CREATE TABLE categories (
        id TEXT NOT NULL PRIMARY KEY, type TEXT NOT NULL, name TEXT NOT NULL,
        parent_id TEXT NULL, sort_order INTEGER NOT NULL,
        is_archived INTEGER NOT NULL, created_at_utc INTEGER NOT NULL,
        updated_at_utc INTEGER NOT NULL
      );
      CREATE TABLE accounts (
        id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL,
        currency_code TEXT NOT NULL, is_archived INTEGER NOT NULL,
        created_at_utc INTEGER NOT NULL, updated_at_utc INTEGER NOT NULL
      );
      CREATE TABLE ledger_transactions (
        id TEXT NOT NULL PRIMARY KEY, type TEXT NOT NULL,
        category_id TEXT NULL, transaction_year INTEGER NOT NULL,
        transaction_month INTEGER NOT NULL, transaction_day INTEGER NOT NULL,
        note TEXT NULL, created_at_utc INTEGER NOT NULL,
        updated_at_utc INTEGER NOT NULL
      );
      CREATE TABLE ledger_entries (
        id TEXT NOT NULL PRIMARY KEY, transaction_id TEXT NOT NULL,
        account_id TEXT NOT NULL, amount_minor INTEGER NOT NULL,
        currency_code TEXT NOT NULL, created_at_utc INTEGER NOT NULL
      );
    ''');
    database.execute(
      '''
      INSERT INTO transactions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        '00000000-0000-4000-8000-000000043001',
        'expense',
        888,
        'TWD',
        'expense.food',
        2026,
        8,
        18,
        'migration',
        DateTime.utc(2026, 8, 18, 1).millisecondsSinceEpoch,
        DateTime.utc(2026, 8, 18, 1).millisecondsSinceEpoch,
      ],
    );
    database.execute('PRAGMA user_version = 3;');
  } finally {
    database.close();
  }
}

void _createSchemaVersion1Database(File databaseFile) {
  final database = sqlite3.open(databaseFile.path);
  try {
    database.execute('''
      CREATE TABLE transactions (
        id TEXT NOT NULL PRIMARY KEY,
        type TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        currency_code TEXT NOT NULL,
        category_id TEXT NOT NULL,
        transaction_year INTEGER NOT NULL,
        transaction_month INTEGER NOT NULL,
        transaction_day INTEGER NOT NULL,
        note TEXT NULL,
        created_at_utc INTEGER NOT NULL,
        updated_at_utc INTEGER NOT NULL
      );
    ''');
    database.execute('''
      CREATE TABLE app_settings_rows (
        id INTEGER NOT NULL PRIMARY KEY,
        onboarding_completed INTEGER NOT NULL,
        biometric_lock_enabled INTEGER NOT NULL,
        currency_code TEXT NOT NULL,
        last_expense_category_id TEXT NULL,
        last_income_category_id TEXT NULL
      );
    ''');
    database.execute(
      '''
      INSERT INTO transactions (
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
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        '00000000-0000-4000-8000-000000000309',
        'expense',
        777,
        'TWD',
        'expense.food',
        2026,
        8,
        16,
        null,
        DateTime.utc(2026, 8, 16, 1).millisecondsSinceEpoch,
        DateTime.utc(2026, 8, 16, 1).millisecondsSinceEpoch,
      ],
    );
    database.execute('PRAGMA user_version = 1;');
  } finally {
    database.close();
  }
}

void _createSchemaVersion2Database(File databaseFile) {
  final database = sqlite3.open(databaseFile.path);
  try {
    database.execute('''
      CREATE TABLE transactions (
        id TEXT NOT NULL PRIMARY KEY,
        type TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        currency_code TEXT NOT NULL,
        category_id TEXT NOT NULL,
        transaction_year INTEGER NOT NULL,
        transaction_month INTEGER NOT NULL,
        transaction_day INTEGER NOT NULL,
        note TEXT NULL,
        created_at_utc INTEGER NOT NULL,
        updated_at_utc INTEGER NOT NULL
      );
    ''');
    database.execute('''
      CREATE TABLE app_settings_rows (
        id INTEGER NOT NULL PRIMARY KEY,
        onboarding_completed INTEGER NOT NULL,
        biometric_lock_enabled INTEGER NOT NULL,
        currency_code TEXT NOT NULL,
        last_expense_category_id TEXT NULL,
        last_income_category_id TEXT NULL
      );
    ''');
    database.execute('''
      CREATE TABLE categories (
        id TEXT NOT NULL PRIMARY KEY,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        parent_id TEXT NULL,
        sort_order INTEGER NOT NULL,
        is_archived INTEGER NOT NULL,
        created_at_utc INTEGER NOT NULL,
        updated_at_utc INTEGER NOT NULL
      );
    ''');
    _insertV2Transaction(
      database,
      id: '00000000-0000-4000-8000-000000032201',
      type: 'income',
      amountMinor: 5000,
      categoryId: 'income.salary',
      note: 'salary',
      createdAtUtc: DateTime.utc(2026, 8, 16, 1),
    );
    _insertV2Transaction(
      database,
      id: '00000000-0000-4000-8000-000000032202',
      type: 'expense',
      amountMinor: 777,
      categoryId: 'expense.food',
      note: 'lunch',
      createdAtUtc: DateTime.utc(2026, 8, 16, 2),
    );
    database.execute('PRAGMA user_version = 2;');
  } finally {
    database.close();
  }
}

void _insertV2Transaction(
  Database database, {
  required String id,
  required String type,
  required int amountMinor,
  required String categoryId,
  required String note,
  required DateTime createdAtUtc,
}) {
  database.execute(
    '''
    INSERT INTO transactions (
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
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''',
    [
      id,
      type,
      amountMinor,
      'TWD',
      categoryId,
      2026,
      8,
      16,
      note,
      createdAtUtc.millisecondsSinceEpoch,
      createdAtUtc.millisecondsSinceEpoch,
    ],
  );
}
