import 'package:drift/drift.dart';

import '../../domain/model/stock_account.dart' as domain;
import '../../domain/repository/stock_account_repository.dart';
import '../database/networthy_database.dart';

class DriftStockAccountRepository implements StockAccountRepository {
  const DriftStockAccountRepository(this._database);

  final NetworthyDatabase _database;

  @override
  Future<void> archive(String id) async {
    final account = await findById(id);
    if (account == null) {
      throw const StockAccountRepositoryException('股票帳戶不存在。');
    }
    await (_database.update(
      _database.stockAccounts,
    )..where((table) => table.id.equals(id))).write(
      StockAccountsCompanion(
        isArchived: const Value(true),
        updatedAtUtc: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<domain.StockAccount> create(CreateStockAccountRequest request) async {
    if (await findById(request.id) != null) {
      throw const StockAccountRepositoryException('股票帳戶已存在。');
    }
    await _ensureUniqueActiveName(name: request.name, mode: request.mode);
    final now = DateTime.now().toUtc();
    final account = domain.StockAccount.create(
      id: request.id,
      name: request.name,
      mode: request.mode,
      currencyCode: request.mode.currencyCode,
      isArchived: false,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
    await _database.into(_database.stockAccounts).insert(_toCompanion(account));
    return account;
  }

  @override
  Future<domain.StockAccount?> findById(String id) async {
    final row = await (_database.select(
      _database.stockAccounts,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<domain.StockAccount>> listActive() async {
    final rows =
        await (_baseQuery()..where((table) => table.isArchived.equals(false)))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<domain.StockAccount>> listAll() async {
    final rows = await _baseQuery().get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<domain.StockAccount> rename({
    required String id,
    required String name,
  }) async {
    final account = await findById(id);
    if (account == null) {
      throw const StockAccountRepositoryException('股票帳戶不存在。');
    }
    await _ensureUniqueActiveName(
      name: name,
      mode: account.mode,
      excludingId: id,
    );
    final updated = domain.StockAccount.create(
      id: account.id,
      name: name,
      mode: account.mode,
      currencyCode: account.currencyCode,
      isArchived: account.isArchived,
      createdAtUtc: account.createdAtUtc,
      updatedAtUtc: DateTime.now().toUtc(),
    );
    await (_database.update(
      _database.stockAccounts,
    )..where((table) => table.id.equals(id))).write(_toCompanion(updated));
    return updated;
  }

  SimpleSelectStatement<$StockAccountsTable, StockAccount> _baseQuery() {
    return _database.select(_database.stockAccounts)..orderBy([
      (table) => OrderingTerm.asc(table.mode),
      (table) => OrderingTerm.asc(table.name),
    ]);
  }

  Future<void> _ensureUniqueActiveName({
    required String name,
    required domain.StockAccountMode mode,
    String? excludingId,
  }) async {
    final rows =
        await (_database.select(_database.stockAccounts)..where(
              (table) =>
                  table.name.equals(name.trim()) &
                  table.mode.equals(mode.wireValue) &
                  table.isArchived.equals(false),
            ))
            .get();
    if (rows.any((row) => row.id != excludingId)) {
      throw const StockAccountRepositoryException('同模式股票帳戶名稱已存在。');
    }
  }

  StockAccountsCompanion _toCompanion(domain.StockAccount account) {
    return StockAccountsCompanion.insert(
      id: account.id,
      name: account.name,
      mode: account.mode.wireValue,
      currencyCode: account.currencyCode.wireValue,
      isArchived: account.isArchived,
      createdAtUtc: account.createdAtUtc,
      updatedAtUtc: account.updatedAtUtc,
    );
  }

  domain.StockAccount _toDomain(StockAccount row) {
    final mode = domain.StockAccountMode.fromWireValue(row.mode);
    return domain.StockAccount.create(
      id: row.id,
      name: row.name,
      mode: mode,
      currencyCode: mode.currencyCode,
      isArchived: row.isArchived,
      createdAtUtc: row.createdAtUtc.toUtc(),
      updatedAtUtc: row.updatedAtUtc.toUtc(),
    );
  }
}
