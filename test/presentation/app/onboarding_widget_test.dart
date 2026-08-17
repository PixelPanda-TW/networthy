import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/presentation/app/networthy_app.dart';

import '../test_app_harness.dart';

void main() {
  testWidgets('onboarding explains local storage risk and enters home', (
    tester,
  ) async {
    final settings = TestSettingsRepository();

    await tester.pumpWidget(
      NetworthyApp(
        transactions: TestTransactionRepository(),
        accounts: TestAccountRepository(),
        ledger: TestLedgerRepository(),
        settings: settings,
        categories: TestCategoryRepository(),
        clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000701']),
        initialDate: DateTime(2026, 8, 16),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('資料只存在這台裝置'), findsOneWidget);
    expect(find.textContaining('解除安裝或清除 App 資料'), findsOneWidget);

    await tester.tap(find.text('開始使用'));
    await tester.pumpAndSettle();

    expect(settings.value.onboardingCompleted, isTrue);
    expect(find.text('總覽'), findsWidgets);
    expect(find.text('紀錄'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
  });
}
