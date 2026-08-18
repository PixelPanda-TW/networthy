import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/common/application_failure.dart';
import 'package:networthy/application/stock/stock_account_command.dart';
import 'package:networthy/application/stock/stock_account_use_cases.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/repository/stock_account_repository.dart';

import '../../presentation/test_app_harness.dart';

void main() {
  test('create account generates id and stores mode-fixed currency', () async {
    final accounts = TestStockAccountRepository();
    final result =
        await CreateStockAccountUseCase(
          accounts: accounts,
          clock: TestClock(DateTime.utc(2026, 8, 18, 1)),
          idGenerator: TestIdGenerator([
            '00000000-0000-4000-8000-000000044001',
          ]),
        ).execute(
          const CreateStockAccountCommand(
            name: '美股券商',
            mode: StockAccountMode.usStock,
          ),
        );

    expect(result.failure, isNull);
    expect(result.account?.currencyCode.wireValue, 'USD');
    expect(result.account?.id, '00000000-0000-4000-8000-000000044001');
  });

  test('rename rejects missing or archived account', () async {
    final accounts = TestStockAccountRepository();
    final missing = await RenameStockAccountUseCase(accounts).execute(
      const RenameStockAccountCommand(
        id: '00000000-0000-4000-8000-000000044002',
        name: '不存在',
      ),
    );
    expect(missing.failure?.type, ApplicationFailureType.validation);

    final account = await accounts.create(
      const CreateStockAccountRequest(
        id: '00000000-0000-4000-8000-000000044003',
        name: '台股券商',
        mode: StockAccountMode.taiwanStock,
      ),
    );
    await accounts.archive(account.id);
    final archived = await RenameStockAccountUseCase(
      accounts,
    ).execute(RenameStockAccountCommand(id: account.id, name: '新名稱'));

    expect(archived.failure?.type, ApplicationFailureType.validation);
  });

  test('archive rejects missing account and hides active account', () async {
    final accounts = TestStockAccountRepository();
    final missing = await ArchiveStockAccountUseCase(accounts).execute(
      const ArchiveStockAccountCommand(
        id: '00000000-0000-4000-8000-000000044004',
      ),
    );
    expect(missing.failure?.type, ApplicationFailureType.validation);

    final account = await accounts.create(
      const CreateStockAccountRequest(
        id: '00000000-0000-4000-8000-000000044005',
        name: '台股券商',
        mode: StockAccountMode.taiwanStock,
      ),
    );
    final archived = await ArchiveStockAccountUseCase(
      accounts,
    ).execute(ArchiveStockAccountCommand(id: account.id));

    expect(archived.failure, isNull);
    expect(await accounts.listActive(), isEmpty);
  });
}
