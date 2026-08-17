import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/ledger/ledger_transaction_builder.dart';
import 'package:networthy/domain/model/account.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/repository/account_repository.dart';
import 'package:networthy/presentation/app/networthy_app.dart';

import '../test_app_harness.dart';

void main() {
  testWidgets('adds an expense through the fast path and refreshes overview', (
    tester,
  ) async {
    final transactions = TestTransactionRepository();
    final accounts = TestAccountRepository();
    final ledger = TestLedgerRepository();

    await tester.pumpWidget(
      NetworthyApp(
        transactions: transactions,
        accounts: accounts,
        ledger: ledger,
        settings: _completedSettings(),
        categories: TestCategoryRepository(),
        clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: TestIdGenerator([
          '00000000-0000-4000-8000-000000000721',
          '00000000-0000-4000-8000-000000000728',
        ]),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新增記帳'));
    await tester.pumpAndSettle();

    expect(find.text('新增記帳'), findsOneWidget);
    expect(find.text('現金 TWD'), findsOneWidget);
    expect(find.text('支出'), findsWidgets);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.enterText(find.byKey(const Key('amount-field')), '1200');
    await tester.enterText(find.byKey(const Key('note-field')), '午餐');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(ledger.values.values.single.entries.single.amountMinor, -1200);
    expect(find.text('支出 NT\$1,200'), findsOneWidget);
    expect(find.textContaining('午餐'), findsOneWidget);
  });

  testWidgets('edits a transaction from overview and refreshes totals', (
    tester,
  ) async {
    final transactions = TestTransactionRepository();
    final accounts = TestAccountRepository();
    final ledger = TestLedgerRepository();

    await tester.pumpWidget(
      NetworthyApp(
        transactions: transactions,
        accounts: accounts,
        ledger: ledger,
        settings: _completedSettings(),
        categories: TestCategoryRepository(),
        clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: TestIdGenerator([
          '00000000-0000-4000-8000-000000000722',
          '00000000-0000-4000-8000-000000000735',
        ]),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新增記帳'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amount-field')), '1200');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('餐飲 NT\$1,200').last);
    await tester.pumpAndSettle();

    expect(find.text('編輯記帳'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('amount-field')), '1500');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('支出 NT\$1,500'), findsOneWidget);
  });

  testWidgets('category dropdown displays localized category names', (
    tester,
  ) async {
    await tester.pumpWidget(
      NetworthyApp(
        transactions: TestTransactionRepository(),
        accounts: TestAccountRepository(),
        ledger: TestLedgerRepository(),
        settings: _completedSettings(),
        categories: TestCategoryRepository(),
        clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000725']),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新增記帳'));
    await tester.pumpAndSettle();

    expect(find.text('餐飲'), findsOneWidget);
    expect(find.text('expense.food'), findsNothing);

    await tester.tap(find.text('收入'));
    await tester.pumpAndSettle();

    expect(find.text('薪資'), findsOneWidget);
    expect(find.text('income.salary'), findsNothing);
  });

  testWidgets('archived selected category remains visible while editing', (
    tester,
  ) async {
    final categories = TestCategoryRepository();
    await categories.archive('expense.food');
    final transactions = TestTransactionRepository();
    final accounts = TestAccountRepository();
    final account = await accounts.ensureDefaultAccountSeeded();
    final ledger = TestLedgerRepository();
    await ledger.save(
      LedgerTransactionBuilder.expense(
        transactionId: '00000000-0000-4000-8000-000000000726',
        entryId: '00000000-0000-4000-8000-000000000736',
        account: account,
        amountMinor: 100,
        categoryId: 'expense.food',
        transactionDate: LocalDate(2026, 8, 16),
        note: 'old food',
        createdAtUtc: DateTime.utc(2026, 8, 16, 1),
      ),
    );

    await tester.pumpWidget(
      NetworthyApp(
        transactions: transactions,
        accounts: accounts,
        ledger: ledger,
        settings: _completedSettings(),
        categories: categories,
        clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000727']),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('old food'));
    await tester.pumpAndSettle();

    expect(find.text('餐飲（已封存）'), findsOneWidget);
  });

  testWidgets('archived selected account remains visible while editing', (
    tester,
  ) async {
    final accounts = TestAccountRepository(seedDefault: false);
    final account = await accounts.create(
      const CreateAccountRequest(
        id: '00000000-0000-4000-8000-000000000730',
        name: '現金 TWD',
        currencyCode: CurrencyCode.twd,
        openingBalanceMinor: 0,
      ),
    );
    await accounts.archive(account.id);
    final ledger = TestLedgerRepository();
    await ledger.save(
      LedgerTransactionBuilder.expense(
        transactionId: '00000000-0000-4000-8000-000000000731',
        entryId: '00000000-0000-4000-8000-000000000732',
        account: CashAccount.create(
          id: account.id,
          name: account.name,
          currencyCode: account.currencyCode,
          isArchived: false,
          createdAtUtc: account.createdAtUtc,
          updatedAtUtc: account.updatedAtUtc,
        ),
        amountMinor: 100,
        categoryId: 'expense.food',
        transactionDate: LocalDate(2026, 8, 16),
        note: 'old cash',
        createdAtUtc: DateTime.utc(2026, 8, 16, 1),
      ),
    );

    await tester.pumpWidget(
      NetworthyApp(
        transactions: TestTransactionRepository(),
        accounts: accounts,
        ledger: ledger,
        settings: _completedSettings(),
        categories: TestCategoryRepository(),
        clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000733']),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('old cash'));
    await tester.pumpAndSettle();

    expect(find.text('現金 TWD（已封存）'), findsOneWidget);
  });

  testWidgets('save failure keeps entered form data and shows safe error', (
    tester,
  ) async {
    await tester.pumpWidget(
      NetworthyApp(
        transactions: TestTransactionRepository(),
        accounts: TestAccountRepository(),
        ledger: TestLedgerRepository(throwOnSave: true),
        settings: _completedSettings(),
        categories: TestCategoryRepository(),
        clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: TestIdGenerator([
          '00000000-0000-4000-8000-000000000723',
          '00000000-0000-4000-8000-000000000737',
        ]),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新增記帳'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amount-field')), '1200');
    await tester.enterText(find.byKey(const Key('note-field')), '午餐');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('本機資料儲存失敗，請稍後再試。'), findsOneWidget);
    expect(find.text('1200'), findsOneWidget);
    expect(find.text('午餐'), findsOneWidget);
  });

  testWidgets('shows amount validation beside the amount field', (
    tester,
  ) async {
    await tester.pumpWidget(
      NetworthyApp(
        transactions: TestTransactionRepository(),
        accounts: TestAccountRepository(),
        ledger: TestLedgerRepository(),
        settings: _completedSettings(),
        categories: TestCategoryRepository(),
        clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000724']),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新增記帳'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('請輸入大於 0 的整數金額'), findsOneWidget);
  });
}

TestSettingsRepository _completedSettings() {
  return TestSettingsRepository(
    const AppSettings(
      onboardingCompleted: true,
      biometricLockEnabled: false,
      currencyCode: 'TWD',
      lastExpenseCategoryId: null,
      lastIncomeCategoryId: null,
    ),
  );
}
