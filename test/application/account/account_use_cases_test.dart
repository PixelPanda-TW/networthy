import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/account/account_command.dart';
import 'package:networthy/application/account/account_use_cases.dart';
import 'package:networthy/application/common/application_failure.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/repository/account_repository.dart';

import '../../presentation/test_app_harness.dart';

void main() {
  test(
    'create account stores account and opening balance ledger entry',
    () async {
      final accounts = TestAccountRepository(seedDefault: false);
      final ledger = TestLedgerRepository();
      final result =
          await CreateAccountUseCase(
            accounts: accounts,
            ledger: ledger,
            clock: TestClock(DateTime.utc(2026, 8, 17, 1)),
            idGenerator: TestIdGenerator([
              '00000000-0000-4000-8000-000000034001',
              '00000000-0000-4000-8000-000000034002',
              '00000000-0000-4000-8000-000000034003',
            ]),
          ).execute(
            const CreateAccountCommand(
              name: '玉山台幣',
              currencyCode: CurrencyCode.twd,
              openingBalanceMinor: 1000,
            ),
          );

      expect(result.failure, isNull);
      expect(result.account?.name, '玉山台幣');
      expect((await accounts.listActive()).single.name, '玉山台幣');
      expect((await ledger.accountBalances()).single.balanceMinor, 1000);
    },
  );

  test(
    'rename rejects missing or archived account with validation failure',
    () async {
      final accounts = TestAccountRepository(seedDefault: false);
      final missing = await RenameAccountUseCase(accounts).execute(
        const RenameAccountCommand(
          id: '00000000-0000-4000-8000-000000034004',
          name: '不存在',
        ),
      );

      expect(missing.failure?.type, ApplicationFailureType.validation);

      final account = await accounts.create(
        const CreateAccountRequest(
          id: '00000000-0000-4000-8000-000000034005',
          name: '玉山台幣',
          currencyCode: CurrencyCode.twd,
          openingBalanceMinor: 0,
        ),
      );
      await accounts.archive(account.id);

      final archived = await RenameAccountUseCase(
        accounts,
      ).execute(RenameAccountCommand(id: account.id, name: '玉山薪轉'));

      expect(archived.failure?.type, ApplicationFailureType.validation);
      expect(await accounts.displayNameFor(account.id), '玉山台幣');
    },
  );

  test('archive rejects missing account and hides active account', () async {
    final accounts = TestAccountRepository(seedDefault: false);
    final missing = await ArchiveAccountUseCase(accounts).execute(
      const ArchiveAccountCommand(id: '00000000-0000-4000-8000-000000034006'),
    );

    expect(missing.failure?.type, ApplicationFailureType.validation);

    final account = await accounts.create(
      const CreateAccountRequest(
        id: '00000000-0000-4000-8000-000000034007',
        name: '玉山台幣',
        currencyCode: CurrencyCode.twd,
        openingBalanceMinor: 0,
      ),
    );

    final archived = await ArchiveAccountUseCase(
      accounts,
    ).execute(ArchiveAccountCommand(id: account.id));

    expect(archived.failure, isNull);
    expect((await accounts.listActive()).map((item) => item.id), isEmpty);
  });
}
