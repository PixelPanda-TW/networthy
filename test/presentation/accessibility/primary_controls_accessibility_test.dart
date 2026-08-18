import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/ledger/ledger_transaction_builder.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/presentation/app/networthy_app.dart';

import '../security/app_lock_widget_test.dart';
import '../test_app_harness.dart';

void main() {
  testWidgets('primary controls expose screen reader labels', (tester) async {
    final transactions = TestTransactionRepository();
    await transactions.save(
      BookkeepingTransaction.create(
        id: '00000000-0000-4000-8000-000000008001',
        type: TransactionType.expense,
        amountMinor: 120,
        categoryId: 'expense.food',
        transactionDate: LocalDate(2026, 8, 16),
        note: '早餐',
        createdAtUtc: DateTime.utc(2026, 8, 16, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 16, 1),
      ),
    );

    final accounts = TestAccountRepository();
    final ledger = await _ledgerFromTransactions(transactions, accounts);

    await tester.pumpWidget(
      _app(transactions: transactions, accounts: accounts, ledger: ledger),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('新增一筆記帳'), findsOneWidget);
    expect(find.bySemanticsLabel('切換到上一個月'), findsOneWidget);
    expect(find.bySemanticsLabel('切換到下一個月'), findsOneWidget);
    expect(find.byTooltip('開啟紀錄頁'), findsOneWidget);
    expect(find.byTooltip('開啟資產頁'), findsOneWidget);

    await tester.tap(find.byTooltip('開啟紀錄頁'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('刪除 早餐'), findsOneWidget);

    await tester.tap(find.byTooltip('開啟設定頁'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('啟用或停用 App 鎖定'), findsOneWidget);
    expect(find.bySemanticsLabel('清除所有本機資料'), findsOneWidget);
  });

  testWidgets('primary controls meet minimum touch target size', (
    tester,
  ) async {
    await tester.pumpWidget(_app(transactions: TestTransactionRepository()));
    await tester.pumpAndSettle();

    _expectMinTouchTarget(tester, find.bySemanticsLabel('新增一筆記帳'));
    _expectMinTouchTarget(tester, find.bySemanticsLabel('切換到上一個月'));
    _expectMinTouchTarget(tester, find.bySemanticsLabel('切換到下一個月'));
    _expectMinTouchTarget(tester, find.byTooltip('開啟紀錄頁'));
    _expectMinTouchTarget(tester, find.byTooltip('開啟資產頁'));
    _expectMinTouchTarget(tester, find.byTooltip('開啟設定頁'));
  });
}

NetworthyApp _app({
  required TestTransactionRepository transactions,
  TestAccountRepository? accounts,
  TestLedgerRepository? ledger,
}) {
  return NetworthyApp(
    transactions: transactions,
    accounts: accounts ?? TestAccountRepository(),
    ledger: ledger ?? TestLedgerRepository(),
    settings: TestSettingsRepository(
      const AppSettings(
        onboardingCompleted: true,
        biometricLockEnabled: false,
        currencyCode: 'TWD',
        lastExpenseCategoryId: null,
        lastIncomeCategoryId: null,
      ),
    ),
    categories: TestCategoryRepository(),
    clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
    idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000008002']),
    authenticator: TestDeviceAuthenticator(authenticateResults: [true]),
    initialDate: DateTime(2026, 8, 16),
  );
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

void _expectMinTouchTarget(WidgetTester tester, Finder finder) {
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
}
