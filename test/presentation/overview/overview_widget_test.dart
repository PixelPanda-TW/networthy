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
  testWidgets('overview shows empty state and month switching', (tester) async {
    await tester.pumpWidget(
      NetworthyApp(
        transactions: TestTransactionRepository(),
        accounts: TestAccountRepository(),
        ledger: TestLedgerRepository(),
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
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000711']),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026年8月'), findsOneWidget);
    expect(find.text('目前沒有記帳紀錄'), findsWidgets);
    expect(find.text('收入 NT\$0'), findsOneWidget);
    expect(find.text('支出 NT\$0'), findsOneWidget);
    expect(find.text('結餘 NT\$0'), findsOneWidget);

    await tester.tap(find.byTooltip('下一個月'));
    await tester.pumpAndSettle();

    expect(find.text('2026年9月'), findsOneWidget);
  });

  testWidgets('overview renders totals categories and recent transactions', (
    tester,
  ) async {
    final transactions = TestTransactionRepository();
    await transactions.save(
      BookkeepingTransaction.create(
        id: '00000000-0000-4000-8000-000000000712',
        type: TransactionType.expense,
        amountMinor: 12500,
        categoryId: 'expense.food',
        transactionDate: LocalDate(2026, 8, 16),
        note: '午餐',
        createdAtUtc: DateTime.utc(2026, 8, 16, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 16, 1),
      ),
    );
    final accounts = TestAccountRepository();
    final ledger = await _ledgerFromTransactions(transactions, accounts);

    await tester.pumpWidget(
      NetworthyApp(
        transactions: transactions,
        accounts: accounts,
        ledger: ledger,
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
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000713']),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('支出 NT\$12,500'), findsOneWidget);
    expect(find.text('結餘 -NT\$12,500'), findsOneWidget);
    expect(find.textContaining('餐飲 NT\$12,500'), findsWidgets);
    expect(find.textContaining('expense.food'), findsNothing);
    expect(find.textContaining('午餐'), findsOneWidget);
  });

  testWidgets('overview uses renamed category display path', (tester) async {
    final categories = TestCategoryRepository();
    await categories.rename(id: 'expense.food', name: '吃飯');
    final transactions = TestTransactionRepository();
    await transactions.save(
      BookkeepingTransaction.create(
        id: '00000000-0000-4000-8000-000000000714',
        type: TransactionType.expense,
        amountMinor: 12500,
        categoryId: 'expense.food',
        transactionDate: LocalDate(2026, 8, 16),
        note: '午餐',
        createdAtUtc: DateTime.utc(2026, 8, 16, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 16, 1),
      ),
    );
    final accounts = TestAccountRepository();
    final ledger = await _ledgerFromTransactions(transactions, accounts);

    await tester.pumpWidget(
      NetworthyApp(
        transactions: transactions,
        accounts: accounts,
        ledger: ledger,
        settings: TestSettingsRepository(
          const AppSettings(
            onboardingCompleted: true,
            biometricLockEnabled: false,
            currencyCode: 'TWD',
            lastExpenseCategoryId: null,
            lastIncomeCategoryId: null,
          ),
        ),
        categories: categories,
        clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000715']),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('吃飯 NT\$12,500'), findsWidgets);
    expect(find.textContaining('餐飲 NT\$12,500'), findsNothing);
  });

  testWidgets('overview renders monthly totals grouped by currency', (
    tester,
  ) async {
    final accounts = TestAccountRepository(seedDefault: false);
    final twd = await accounts.create(
      const CreateAccountRequest(
        id: '00000000-0000-4000-8000-000000000716',
        name: '台幣現金',
        currencyCode: CurrencyCode.twd,
        openingBalanceMinor: 0,
      ),
    );
    final usd = await accounts.create(
      const CreateAccountRequest(
        id: '00000000-0000-4000-8000-000000000717',
        name: '美金現金',
        currencyCode: CurrencyCode.usd,
        openingBalanceMinor: 0,
      ),
    );
    final ledger = TestLedgerRepository();
    await ledger.save(
      LedgerTransactionBuilder.expense(
        transactionId: '00000000-0000-4000-8000-000000000718',
        entryId: '00000000-0000-4000-8000-000000000719',
        account: twd,
        amountMinor: 1200,
        categoryId: 'expense.food',
        transactionDate: LocalDate(2026, 8, 16),
        note: null,
        createdAtUtc: DateTime.utc(2026, 8, 16, 1),
      ),
    );
    await ledger.save(
      LedgerTransactionBuilder.income(
        transactionId: '00000000-0000-4000-8000-000000000720',
        entryId: '00000000-0000-4000-8000-000000000729',
        account: usd,
        amountMinor: 50,
        categoryId: 'income.salary',
        transactionDate: LocalDate(2026, 8, 16),
        note: null,
        createdAtUtc: DateTime.utc(2026, 8, 16, 2),
      ),
    );

    await tester.pumpWidget(
      NetworthyApp(
        transactions: TestTransactionRepository(),
        accounts: accounts,
        ledger: ledger,
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
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000734']),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('支出 NT\$1,200'), findsOneWidget);
    expect(find.text('收入 US\$50'), findsOneWidget);
    expect(find.text('結餘 -NT\$1,200'), findsOneWidget);
    expect(find.text('結餘 US\$50'), findsOneWidget);
  });
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
