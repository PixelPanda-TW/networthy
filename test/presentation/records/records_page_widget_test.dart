import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/ledger/ledger_transaction_builder.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/domain/repository/account_repository.dart';
import 'package:networthy/presentation/app/networthy_app.dart';

import '../test_app_harness.dart';

void main() {
  testWidgets('records tab sorts by transaction date then created time', (
    tester,
  ) async {
    final transactions = TestTransactionRepository();
    await transactions.save(
      _transaction(
        id: '00000000-0000-4000-8000-000000000801',
        amountMinor: 100,
        date: LocalDate(2026, 8, 15),
        createdAtUtc: DateTime.utc(2026, 8, 15, 10),
        note: 'older date',
      ),
    );
    await transactions.save(
      _transaction(
        id: '00000000-0000-4000-8000-000000000802',
        amountMinor: 200,
        date: LocalDate(2026, 8, 16),
        createdAtUtc: DateTime.utc(2026, 8, 16, 9),
        note: 'same day older create',
      ),
    );
    await transactions.save(
      _transaction(
        id: '00000000-0000-4000-8000-000000000803',
        amountMinor: 300,
        date: LocalDate(2026, 8, 16),
        createdAtUtc: DateTime.utc(2026, 8, 16, 11),
        note: 'same day newer create',
      ),
    );

    await _pumpApp(tester, transactions);
    await tester.tap(find.text('紀錄'));
    await tester.pumpAndSettle();

    expect(
      _topToBottomTextOrder(tester, [
        'same day newer create',
        'same day older create',
        'older date',
      ]),
      ['same day newer create', 'same day older create', 'older date'],
    );
  });

  testWidgets('records tab filters by month and transaction type', (
    tester,
  ) async {
    final transactions = TestTransactionRepository();
    await transactions.save(
      _transaction(
        id: '00000000-0000-4000-8000-000000000804',
        amountMinor: 100,
        date: LocalDate(2026, 8, 16),
        note: 'august expense',
      ),
    );
    await transactions.save(
      _transaction(
        id: '00000000-0000-4000-8000-000000000805',
        type: TransactionType.income,
        categoryId: 'income.salary',
        amountMinor: 200,
        date: LocalDate(2026, 8, 17),
        note: 'august income',
      ),
    );
    await transactions.save(
      _transaction(
        id: '00000000-0000-4000-8000-000000000806',
        amountMinor: 300,
        date: LocalDate(2026, 9, 1),
        note: 'september expense',
      ),
    );

    await _pumpApp(tester, transactions);
    await tester.tap(find.text('紀錄'));
    await tester.pumpAndSettle();

    expect(find.text('august expense'), findsOneWidget);
    expect(find.text('august income'), findsOneWidget);
    expect(find.textContaining('餐飲'), findsOneWidget);
    expect(find.textContaining('薪資'), findsOneWidget);
    expect(find.textContaining('expense.food'), findsNothing);
    expect(find.textContaining('income.salary'), findsNothing);
    expect(find.text('september expense'), findsNothing);

    await tester.tap(find.text('收入'));
    await tester.pumpAndSettle();

    expect(find.text('august expense'), findsNothing);
    expect(find.text('august income'), findsOneWidget);

    await tester.tap(find.byTooltip('下一個月'));
    await tester.pumpAndSettle();

    expect(find.text('august income'), findsNothing);
    expect(find.text('september expense'), findsNothing);

    await tester.tap(find.text('支出'));
    await tester.pumpAndSettle();

    expect(find.text('september expense'), findsOneWidget);
  });

  testWidgets('records tab edits a record and refreshes the list', (
    tester,
  ) async {
    final transactions = TestTransactionRepository();
    await transactions.save(
      _transaction(
        id: '00000000-0000-4000-8000-000000000807',
        amountMinor: 100,
        date: LocalDate(2026, 8, 16),
        note: 'before edit',
      ),
    );

    await _pumpApp(tester, transactions);
    await tester.tap(find.text('紀錄'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('before edit'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amount-field')), '1500');
    await tester.enterText(find.byKey(const Key('note-field')), 'after edit');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('after edit'), findsOneWidget);
    expect(find.textContaining('NT\$1,500'), findsOneWidget);
  });

  testWidgets('records tab confirms delete and overview summary refreshes', (
    tester,
  ) async {
    final transactions = TestTransactionRepository();
    await transactions.save(
      _transaction(
        id: '00000000-0000-4000-8000-000000000808',
        amountMinor: 1000,
        date: LocalDate(2026, 8, 16),
        note: 'delete me',
      ),
    );

    await _pumpApp(tester, transactions);
    await tester.tap(find.text('紀錄'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('刪除 delete me'));
    await tester.pumpAndSettle();

    expect(find.text('確認刪除'), findsOneWidget);
    await tester.tap(find.text('刪除'));
    await tester.pumpAndSettle();

    expect(find.text('delete me'), findsNothing);

    await tester.tap(find.text('總覽'));
    await tester.pumpAndSettle();

    expect(find.text('支出 NT\$0'), findsOneWidget);
  });

  testWidgets('records delete fallback uses category display name', (
    tester,
  ) async {
    final transactions = TestTransactionRepository();
    await transactions.save(
      _transaction(
        id: '00000000-0000-4000-8000-000000000809',
        amountMinor: 1000,
        date: LocalDate(2026, 8, 16),
        note: null,
      ),
    );

    await _pumpApp(tester, transactions);
    await tester.tap(find.text('紀錄'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('刪除 餐飲'), findsOneWidget);
    expect(find.byTooltip('刪除 expense.food'), findsNothing);
  });

  testWidgets('records tab uses renamed category display path', (tester) async {
    final categories = TestCategoryRepository();
    await categories.rename(id: 'expense.food', name: '吃飯');
    final transactions = TestTransactionRepository();
    await transactions.save(
      _transaction(
        id: '00000000-0000-4000-8000-000000000810',
        amountMinor: 1000,
        date: LocalDate(2026, 8, 16),
        note: null,
      ),
    );

    await _pumpApp(tester, transactions, categories: categories);
    await tester.tap(find.text('紀錄'));
    await tester.pumpAndSettle();

    expect(find.textContaining('吃飯'), findsOneWidget);
    expect(find.byTooltip('刪除 吃飯'), findsOneWidget);
    expect(find.textContaining('餐飲'), findsNothing);
  });

  testWidgets('records show account name and hide opening balances', (
    tester,
  ) async {
    final accounts = TestAccountRepository(seedDefault: false);
    final account = await accounts.create(
      const CreateAccountRequest(
        id: '00000000-0000-4000-8000-000000000811',
        name: '玉山台幣',
        currencyCode: CurrencyCode.twd,
        openingBalanceMinor: 0,
      ),
    );
    final ledger = TestLedgerRepository();
    await ledger.save(
      LedgerTransactionBuilder.openingBalance(
        transactionId: '00000000-0000-4000-8000-000000000812',
        entryId: '00000000-0000-4000-8000-000000000813',
        account: account,
        amountMinor: 1000,
        transactionDate: LocalDate(2026, 8, 1),
        createdAtUtc: DateTime.utc(2026, 8, 1, 1),
      ),
    );
    await ledger.save(
      LedgerTransactionBuilder.expense(
        transactionId: '00000000-0000-4000-8000-000000000814',
        entryId: '00000000-0000-4000-8000-000000000815',
        account: account,
        amountMinor: 1200,
        categoryId: 'expense.food',
        transactionDate: LocalDate(2026, 8, 16),
        note: '午餐',
        createdAtUtc: DateTime.utc(2026, 8, 16, 1),
      ),
    );

    await _pumpApp(
      tester,
      TestTransactionRepository(),
      accounts: accounts,
      ledger: ledger,
    );
    await tester.tap(find.text('紀錄'));
    await tester.pumpAndSettle();

    expect(find.text('午餐'), findsOneWidget);
    expect(find.textContaining('玉山台幣'), findsOneWidget);
    expect(find.textContaining('餐飲'), findsOneWidget);
    expect(find.textContaining('初始'), findsNothing);
    expect(find.textContaining('NT\$1,000'), findsNothing);
  });

  testWidgets('records display transfer as one row', (tester) async {
    final accounts = TestAccountRepository(seedDefault: false);
    final source = await accounts.create(
      const CreateAccountRequest(
        id: '00000000-0000-4000-8000-000000037101',
        name: '玉山台幣',
        currencyCode: CurrencyCode.twd,
        openingBalanceMinor: 0,
      ),
    );
    final target = await accounts.create(
      const CreateAccountRequest(
        id: '00000000-0000-4000-8000-000000037102',
        name: '現金 TWD',
        currencyCode: CurrencyCode.twd,
        openingBalanceMinor: 0,
      ),
    );
    final ledger = TestLedgerRepository();
    await ledger.save(
      LedgerTransactionBuilder.transfer(
        transactionId: '00000000-0000-4000-8000-000000037103',
        sourceEntryId: '00000000-0000-4000-8000-000000037104',
        targetEntryId: '00000000-0000-4000-8000-000000037105',
        source: source,
        target: target,
        amountMinor: 1000,
        transactionDate: LocalDate(2026, 8, 16),
        note: '領現',
        createdAtUtc: DateTime.utc(2026, 8, 16, 1),
      ),
    );

    await _pumpApp(
      tester,
      TestTransactionRepository(),
      accounts: accounts,
      ledger: ledger,
    );
    await tester.tap(find.text('紀錄'));
    await tester.pumpAndSettle();

    expect(find.text('玉山台幣 → 現金 TWD NT\$1,000'), findsOneWidget);
    expect(find.textContaining('-NT\$1,000'), findsNothing);
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  TestTransactionRepository transactions, {
  TestCategoryRepository? categories,
  TestAccountRepository? accounts,
  TestLedgerRepository? ledger,
}) async {
  final effectiveAccounts = accounts ?? TestAccountRepository();
  final effectiveLedger =
      ledger ?? await _ledgerFromTransactions(transactions, effectiveAccounts);
  await tester.pumpWidget(
    NetworthyApp(
      transactions: transactions,
      accounts: effectiveAccounts,
      ledger: effectiveLedger,
      settings: TestSettingsRepository(
        const AppSettings(
          onboardingCompleted: true,
          biometricLockEnabled: false,
          currencyCode: 'TWD',
          lastExpenseCategoryId: null,
          lastIncomeCategoryId: null,
        ),
      ),
      categories: categories ?? TestCategoryRepository(),
      clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
      idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000899']),
      initialDate: DateTime(2026, 8, 16),
    ),
  );
  await tester.pumpAndSettle();
}

Future<TestLedgerRepository> _ledgerFromTransactions(
  TestTransactionRepository transactions,
  TestAccountRepository accounts,
) async {
  final ledger = TestLedgerRepository();
  final account = await accounts.ensureDefaultAccountSeeded();
  for (final transaction in transactions.values.values) {
    final entryId =
        '${transaction.id.substring(0, transaction.id.length - 1)}a';
    final aggregate = switch (transaction.type) {
      TransactionType.expense => LedgerTransactionBuilder.expense(
        transactionId: transaction.id,
        entryId: entryId,
        account: account,
        amountMinor: transaction.amountMinor,
        categoryId: transaction.categoryId,
        transactionDate: transaction.transactionDate,
        note: transaction.note,
        createdAtUtc: transaction.createdAtUtc,
      ),
      TransactionType.income => LedgerTransactionBuilder.income(
        transactionId: transaction.id,
        entryId: entryId,
        account: account,
        amountMinor: transaction.amountMinor,
        categoryId: transaction.categoryId,
        transactionDate: transaction.transactionDate,
        note: transaction.note,
        createdAtUtc: transaction.createdAtUtc,
      ),
    };
    await ledger.save(aggregate);
  }
  return ledger;
}

BookkeepingTransaction _transaction({
  required String id,
  TransactionType type = TransactionType.expense,
  String categoryId = 'expense.food',
  required int amountMinor,
  required LocalDate date,
  DateTime? createdAtUtc,
  String? note,
}) {
  return BookkeepingTransaction.create(
    id: id,
    type: type,
    amountMinor: amountMinor,
    categoryId: categoryId,
    transactionDate: date,
    note: note,
    createdAtUtc: createdAtUtc ?? DateTime.utc(2026, 8, 16, 1),
    updatedAtUtc: createdAtUtc ?? DateTime.utc(2026, 8, 16, 1),
  );
}

List<String> _topToBottomTextOrder(WidgetTester tester, List<String> texts) {
  final positions = <({String text, double y})>[];
  for (final text in texts) {
    positions.add((text: text, y: tester.getTopLeft(find.text(text)).dy));
  }
  positions.sort((a, b) => a.y.compareTo(b.y));
  return positions.map((entry) => entry.text).toList(growable: false);
}
