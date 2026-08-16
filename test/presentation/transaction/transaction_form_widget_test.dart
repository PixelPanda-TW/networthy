import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/presentation/app/networthy_app.dart';

import '../test_app_harness.dart';

void main() {
  testWidgets('adds an expense through the fast path and refreshes overview', (
    tester,
  ) async {
    final transactions = TestTransactionRepository();

    await tester.pumpWidget(
      NetworthyApp(
        transactions: transactions,
        settings: _completedSettings(),
        clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000721']),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新增記帳'));
    await tester.pumpAndSettle();

    expect(find.text('新增記帳'), findsOneWidget);
    expect(find.text('支出'), findsWidgets);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.enterText(find.byKey(const Key('amount-field')), '1200');
    await tester.enterText(find.byKey(const Key('note-field')), '午餐');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(transactions.values.values.single.amountMinor, 1200);
    expect(find.text('支出 NT\$1,200'), findsOneWidget);
    expect(find.textContaining('午餐'), findsOneWidget);
  });

  testWidgets('edits a transaction from overview and refreshes totals', (
    tester,
  ) async {
    final transactions = TestTransactionRepository();

    await tester.pumpWidget(
      NetworthyApp(
        transactions: transactions,
        settings: _completedSettings(),
        clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000722']),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('新增記帳'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amount-field')), '1200');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('expense.food NT\$1,200').last);
    await tester.pumpAndSettle();

    expect(find.text('編輯記帳'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('amount-field')), '1500');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('支出 NT\$1,500'), findsOneWidget);
  });

  testWidgets('save failure keeps entered form data and shows safe error', (
    tester,
  ) async {
    await tester.pumpWidget(
      NetworthyApp(
        transactions: TestTransactionRepository(throwOnSave: true),
        settings: _completedSettings(),
        clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000723']),
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
        settings: _completedSettings(),
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
