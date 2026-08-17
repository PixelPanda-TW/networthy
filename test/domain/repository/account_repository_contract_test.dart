import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/repository/account_repository.dart';

void main() {}

void accountRepositoryContract({
  required Future<AccountRepository> Function() createRepository,
}) {
  test('default account seed creates cash TWD exactly once', () async {
    final repository = await createRepository();

    final first = await repository.ensureDefaultAccountSeeded();
    final second = await repository.ensureDefaultAccountSeeded();

    expect(first.id, second.id);
    expect(first.name, '現金 TWD');
    expect(first.currencyCode, CurrencyCode.twd);
    expect(await repository.listAll(), hasLength(1));
  });

  test('creates renames archives and resolves display names', () async {
    final repository = await createRepository();
    final account = await repository.create(
      const CreateAccountRequest(
        id: '00000000-0000-4000-8000-000000031001',
        name: '玉山台幣',
        currencyCode: CurrencyCode.twd,
        openingBalanceMinor: 1000,
      ),
    );

    expect(account.name, '玉山台幣');
    expect(account.currencyCode, CurrencyCode.twd);
    expect(account.isArchived, isFalse);

    final renamed = await repository.rename(id: account.id, name: '玉山薪轉');
    expect(renamed.name, '玉山薪轉');
    expect(await repository.displayNameFor(account.id), '玉山薪轉');

    await repository.archive(account.id);

    expect(await repository.findById(account.id), isNotNull);
    expect(
      (await repository.listActive()).map((item) => item.id),
      isNot(contains(account.id)),
    );
    expect(await repository.displayNameFor(account.id), '玉山薪轉');
    expect(
      await repository.displayNameFor('missing-account'),
      'missing-account',
    );
  });

  test(
    'rejects duplicate active account names within the same currency',
    () async {
      final repository = await createRepository();
      await repository.create(
        const CreateAccountRequest(
          id: '00000000-0000-4000-8000-000000031002',
          name: '現金',
          currencyCode: CurrencyCode.twd,
          openingBalanceMinor: 0,
        ),
      );

      expect(
        () => repository.create(
          const CreateAccountRequest(
            id: '00000000-0000-4000-8000-000000031003',
            name: '現金',
            currencyCode: CurrencyCode.twd,
            openingBalanceMinor: 0,
          ),
        ),
        throwsA(isA<AccountRepositoryException>()),
      );

      final usd = await repository.create(
        const CreateAccountRequest(
          id: '00000000-0000-4000-8000-000000031004',
          name: '現金',
          currencyCode: CurrencyCode.usd,
          openingBalanceMinor: 0,
        ),
      );
      expect(usd.currencyCode, CurrencyCode.usd);
    },
  );
}
