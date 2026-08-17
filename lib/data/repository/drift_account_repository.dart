import 'package:drift/drift.dart';

import '../../domain/model/account.dart' as domain;
import '../../domain/model/currency_code.dart';
import '../../domain/repository/account_repository.dart';
import '../database/networthy_database.dart';

class DriftAccountRepository implements AccountRepository {
  const DriftAccountRepository(this._database);

  static const defaultAccountId = '00000000-0000-4000-8000-000000030000';

  final NetworthyDatabase _database;

  @override
  Future<void> archive(String id) async {
    final account = await findById(id);
    if (account == null) {
      throw const AccountRepositoryException('帳戶不存在。');
    }
    await (_database.update(
      _database.accounts,
    )..where((table) => table.id.equals(id))).write(
      AccountsCompanion(
        isArchived: const Value(true),
        updatedAtUtc: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<domain.CashAccount> create(CreateAccountRequest request) async {
    final existing = await findById(request.id);
    if (existing != null) {
      throw const AccountRepositoryException('帳戶已存在。');
    }
    await _ensureUniqueActiveName(
      name: request.name,
      currencyCode: request.currencyCode,
    );
    final now = DateTime.now().toUtc();
    final account = domain.CashAccount.create(
      id: request.id,
      name: request.name,
      currencyCode: request.currencyCode,
      isArchived: false,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
    await _database.into(_database.accounts).insert(_toCompanion(account));
    return account;
  }

  @override
  Future<String> displayNameFor(String id) async {
    return (await findById(id))?.name ?? id;
  }

  @override
  Future<domain.CashAccount> ensureDefaultAccountSeeded() async {
    final existing = await findById(defaultAccountId);
    if (existing != null) {
      return existing;
    }
    final now = DateTime.now().toUtc();
    final account = domain.CashAccount.create(
      id: defaultAccountId,
      name: '現金 TWD',
      currencyCode: CurrencyCode.twd,
      isArchived: false,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
    await _database
        .into(_database.accounts)
        .insert(_toCompanion(account), mode: InsertMode.insertOrIgnore);
    return (await findById(defaultAccountId)) ?? account;
  }

  @override
  Future<domain.CashAccount?> findById(String id) async {
    final row = await (_database.select(
      _database.accounts,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _toDomain(row);
  }

  @override
  Future<List<domain.CashAccount>> listActive() async {
    final rows =
        await (_baseQuery()..where((table) => table.isArchived.equals(false)))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<domain.CashAccount>> listAll() async {
    final rows = await _baseQuery().get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<domain.CashAccount> rename({
    required String id,
    required String name,
  }) async {
    final account = await findById(id);
    if (account == null) {
      throw const AccountRepositoryException('帳戶不存在。');
    }
    await _ensureUniqueActiveName(
      name: name,
      currencyCode: account.currencyCode,
      excludingId: id,
    );
    final updated = domain.CashAccount.create(
      id: account.id,
      name: name,
      currencyCode: account.currencyCode,
      isArchived: account.isArchived,
      createdAtUtc: account.createdAtUtc,
      updatedAtUtc: DateTime.now().toUtc(),
    );
    await (_database.update(
      _database.accounts,
    )..where((table) => table.id.equals(id))).write(_toCompanion(updated));
    return updated;
  }

  SimpleSelectStatement<$AccountsTable, Account> _baseQuery() {
    return _database.select(_database.accounts)..orderBy([
      (table) => OrderingTerm.asc(table.currencyCode),
      (table) => OrderingTerm.asc(table.name),
    ]);
  }

  Future<void> _ensureUniqueActiveName({
    required String name,
    required CurrencyCode currencyCode,
    String? excludingId,
  }) async {
    final normalizedName = name.trim();
    final rows =
        await (_database.select(_database.accounts)..where(
              (table) =>
                  table.name.equals(normalizedName) &
                  table.currencyCode.equals(currencyCode.wireValue) &
                  table.isArchived.equals(false),
            ))
            .get();
    final duplicate = rows.any((row) => row.id != excludingId);
    if (duplicate) {
      throw const AccountRepositoryException('同幣別帳戶名稱已存在。');
    }
  }

  AccountsCompanion _toCompanion(domain.CashAccount account) {
    return AccountsCompanion.insert(
      id: account.id,
      name: account.name,
      currencyCode: account.currencyCode.wireValue,
      isArchived: account.isArchived,
      createdAtUtc: account.createdAtUtc,
      updatedAtUtc: account.updatedAtUtc,
    );
  }

  domain.CashAccount _toDomain(Account row) {
    return domain.CashAccount.create(
      id: row.id,
      name: row.name,
      currencyCode: CurrencyCode.fromWireValue(row.currencyCode),
      isArchived: row.isArchived,
      createdAtUtc: row.createdAtUtc.toUtc(),
      updatedAtUtc: row.updatedAtUtc.toUtc(),
    );
  }
}
