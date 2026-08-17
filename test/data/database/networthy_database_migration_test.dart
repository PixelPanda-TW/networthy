import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/networthy_database.dart';
import 'package:networthy/data/repository/drift_category_repository.dart';
import 'package:networthy/data/repository/drift_transaction_repository.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
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
