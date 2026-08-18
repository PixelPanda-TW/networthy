import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/stock_account.dart';
import 'package:networthy/domain/repository/stock_account_repository.dart';

void main() {}

void stockAccountRepositoryContract({
  required Future<StockAccountRepository> Function() createRepository,
}) {
  test('creates renames and archives stock accounts', () async {
    final repository = await createRepository();
    final account = await repository.create(
      const CreateStockAccountRequest(
        id: '00000000-0000-4000-8000-000000041001',
        name: '富邦證券',
        mode: StockAccountMode.taiwanStock,
      ),
    );

    expect(account.currencyCode, CurrencyCode.twd);
    expect(account.isArchived, isFalse);

    final renamed = await repository.rename(id: account.id, name: '富邦台股');
    expect(renamed.name, '富邦台股');
    expect(
      (await repository.listActive()).map((item) => item.id),
      contains(account.id),
    );

    await repository.archive(account.id);

    expect(await repository.findById(account.id), isNotNull);
    expect(
      (await repository.listActive()).map((item) => item.id),
      isNot(contains(account.id)),
    );
    expect(
      (await repository.listAll()).map((item) => item.id),
      contains(account.id),
    );
  });

  test('rejects duplicate active names within the same mode', () async {
    final repository = await createRepository();
    await repository.create(
      const CreateStockAccountRequest(
        id: '00000000-0000-4000-8000-000000041002',
        name: '投資帳戶',
        mode: StockAccountMode.taiwanStock,
      ),
    );

    expect(
      () => repository.create(
        const CreateStockAccountRequest(
          id: '00000000-0000-4000-8000-000000041003',
          name: '投資帳戶',
          mode: StockAccountMode.taiwanStock,
        ),
      ),
      throwsA(isA<StockAccountRepositoryException>()),
    );

    final etf = await repository.create(
      const CreateStockAccountRequest(
        id: '00000000-0000-4000-8000-000000041004',
        name: '投資帳戶',
        mode: StockAccountMode.taiwanEtf,
      ),
    );
    expect(etf.mode, StockAccountMode.taiwanEtf);
  });
}
