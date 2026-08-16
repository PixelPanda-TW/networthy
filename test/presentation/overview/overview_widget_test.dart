import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/presentation/app/networthy_app.dart';

import '../test_app_harness.dart';

void main() {
  testWidgets('overview shows empty state and month switching', (tester) async {
    await tester.pumpWidget(
      NetworthyApp(
        transactions: TestTransactionRepository(),
        settings: TestSettingsRepository(
          const AppSettings(
            onboardingCompleted: true,
            biometricLockEnabled: false,
            currencyCode: 'TWD',
            lastExpenseCategoryId: null,
            lastIncomeCategoryId: null,
          ),
        ),
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

    await tester.pumpWidget(
      NetworthyApp(
        transactions: transactions,
        settings: TestSettingsRepository(
          const AppSettings(
            onboardingCompleted: true,
            biometricLockEnabled: false,
            currencyCode: 'TWD',
            lastExpenseCategoryId: null,
            lastIncomeCategoryId: null,
          ),
        ),
        clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000713']),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('支出 NT\$12,500'), findsOneWidget);
    expect(find.text('結餘 -NT\$12,500'), findsOneWidget);
    expect(find.textContaining('expense.food NT\$12,500'), findsWidgets);
    expect(find.textContaining('午餐'), findsOneWidget);
  });
}
