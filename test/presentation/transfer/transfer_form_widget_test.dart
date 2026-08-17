import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/repository/account_repository.dart';
import 'package:networthy/presentation/transfer/transfer_form_page.dart';

import '../test_app_harness.dart';

void main() {
  testWidgets('transfer form creates one transfer record', (tester) async {
    final accounts = TestAccountRepository(seedDefault: false);
    await _account(
      accounts,
      id: '00000000-0000-4000-8000-000000037001',
      name: '玉山台幣',
    );
    await _account(
      accounts,
      id: '00000000-0000-4000-8000-000000037002',
      name: '現金 TWD',
    );
    final ledger = TestLedgerRepository();

    await tester.pumpWidget(
      testMaterialApp(
        TransferFormPage(
          accounts: accounts,
          ledger: ledger,
          clock: TestClock(DateTime.utc(2026, 8, 17, 1)),
          idGenerator: TestIdGenerator([
            '00000000-0000-4000-8000-000000037003',
            '00000000-0000-4000-8000-000000037004',
            '00000000-0000-4000-8000-000000037005',
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('transfer-amount-field')),
      '1000',
    );
    await tester.enterText(find.byKey(const Key('transfer-note-field')), '領現');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    final record = ledger.values.values.single;
    expect(record.entries.map((entry) => entry.amountMinor), [-1000, 1000]);
  });

  testWidgets('transfer form rejects same account transfer', (tester) async {
    final accounts = TestAccountRepository(seedDefault: false);
    await _account(
      accounts,
      id: '00000000-0000-4000-8000-000000037006',
      name: '玉山台幣',
    );

    await tester.pumpWidget(
      testMaterialApp(
        TransferFormPage(
          accounts: accounts,
          ledger: TestLedgerRepository(),
          clock: TestClock(DateTime.utc(2026, 8, 17, 1)),
          idGenerator: TestIdGenerator([
            '00000000-0000-4000-8000-000000037007',
            '00000000-0000-4000-8000-000000037008',
            '00000000-0000-4000-8000-000000037009',
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('transfer-amount-field')),
      '1000',
    );
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('來源與目標帳戶不能相同'), findsOneWidget);
  });

  testWidgets('transfer form rejects cross-currency transfer', (tester) async {
    final accounts = TestAccountRepository(seedDefault: false);
    await _account(
      accounts,
      id: '00000000-0000-4000-8000-000000037010',
      name: '玉山台幣',
    );
    await _account(
      accounts,
      id: '00000000-0000-4000-8000-000000037011',
      name: '美金現金',
      currency: CurrencyCode.usd,
    );

    await tester.pumpWidget(
      testMaterialApp(
        TransferFormPage(
          accounts: accounts,
          ledger: TestLedgerRepository(),
          clock: TestClock(DateTime.utc(2026, 8, 17, 1)),
          idGenerator: TestIdGenerator([
            '00000000-0000-4000-8000-000000037012',
            '00000000-0000-4000-8000-000000037013',
            '00000000-0000-4000-8000-000000037014',
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('transfer-amount-field')),
      '1000',
    );
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('v0.3.0 僅支援同幣別轉帳'), findsOneWidget);
  });
}

Future<void> _account(
  AccountRepository accounts, {
  required String id,
  required String name,
  CurrencyCode currency = CurrencyCode.twd,
}) async {
  await accounts.create(
    CreateAccountRequest(
      id: id,
      name: name,
      currencyCode: currency,
      openingBalanceMinor: 0,
    ),
  );
}
