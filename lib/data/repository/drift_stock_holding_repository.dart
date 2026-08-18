import 'package:drift/drift.dart';

import '../../domain/model/stock_account.dart' as account_domain;
import '../../domain/model/stock_holding.dart' as holding_domain;
import '../../domain/repository/stock_holding_repository.dart';
import '../database/networthy_database.dart';

class DriftStockHoldingRepository implements StockHoldingRepository {
  const DriftStockHoldingRepository(this._database);

  final NetworthyDatabase _database;

  @override
  Future<void> archive(String id) async {
    if (await findById(id) == null) {
      throw const StockHoldingRepositoryException('股票持倉不存在。');
    }
    await (_database.update(
      _database.stockHoldings,
    )..where((table) => table.id.equals(id))).write(
      StockHoldingsCompanion(
        isArchived: const Value(true),
        updatedAtUtc: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<holding_domain.StockHolding?> findById(String id) async {
    final row = await (_database.select(
      _database.stockHoldings,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<holding_domain.StockHolding>> listActiveByAccount(
    String accountId,
  ) async {
    final rows =
        await (_baseQuery()..where(
              (table) =>
                  table.accountId.equals(accountId) &
                  table.isArchived.equals(false),
            ))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<holding_domain.StockHolding>> listAllActive() async {
    final rows =
        await (_baseQuery()..where((table) => table.isArchived.equals(false)))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<holding_domain.StockHolding>> listAllByAccount(
    String accountId,
  ) async {
    final rows =
        await (_baseQuery()
              ..where((table) => table.accountId.equals(accountId)))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<holding_domain.StockHolding> savePrincipal(
    SavePrincipalHoldingRequest request,
  ) async {
    final existing = await findById(request.id);
    final holding = holding_domain.StockHolding.principal(
      id: request.id,
      accountId: request.accountId,
      symbol: request.symbol,
      name: request.name,
      accountMode: request.accountMode,
      principalMinor: request.principalMinor,
      isArchived: existing?.isArchived ?? false,
      createdAtUtc: existing?.createdAtUtc ?? DateTime.now().toUtc(),
      updatedAtUtc: DateTime.now().toUtc(),
    );
    await _database
        .into(_database.stockHoldings)
        .insert(_toCompanion(holding), mode: InsertMode.insertOrReplace);
    return holding;
  }

  @override
  Future<holding_domain.StockHolding> saveValuation(
    SaveValuationHoldingRequest request,
  ) async {
    final existing = await findById(request.id);
    final holding = holding_domain.StockHolding.valuation(
      id: request.id,
      accountId: request.accountId,
      symbol: request.symbol,
      name: request.name,
      accountMode: request.accountMode,
      quantityMicro: request.quantityMicro,
      averageCostMinor: request.averageCostMinor,
      currentPriceMinor: request.currentPriceMinor,
      isArchived: existing?.isArchived ?? false,
      createdAtUtc: existing?.createdAtUtc ?? DateTime.now().toUtc(),
      updatedAtUtc: DateTime.now().toUtc(),
    );
    await _database
        .into(_database.stockHoldings)
        .insert(_toCompanion(holding), mode: InsertMode.insertOrReplace);
    return holding;
  }

  SimpleSelectStatement<$StockHoldingsTable, StockHolding> _baseQuery() {
    return _database.select(_database.stockHoldings)
      ..orderBy([(table) => OrderingTerm.asc(table.symbol)]);
  }

  StockHoldingsCompanion _toCompanion(holding_domain.StockHolding holding) {
    return StockHoldingsCompanion.insert(
      id: holding.id,
      accountId: holding.accountId,
      symbol: holding.symbol,
      name: holding.name,
      mode: holding.accountMode.wireValue,
      currencyCode: holding.accountMode.currencyCode.wireValue,
      quantityMicro: Value(holding.quantityMicro),
      averageCostMinor: Value(holding.averageCostMinor),
      currentPriceMinor: Value(holding.currentPriceMinor),
      principalMinor: Value(holding.principalMinor),
      isArchived: holding.isArchived,
      createdAtUtc: holding.createdAtUtc,
      updatedAtUtc: holding.updatedAtUtc,
    );
  }

  holding_domain.StockHolding _toDomain(StockHolding row) {
    final mode = account_domain.StockAccountMode.fromWireValue(row.mode);
    if (row.quantityMicro != null) {
      return holding_domain.StockHolding.valuation(
        id: row.id,
        accountId: row.accountId,
        symbol: row.symbol,
        name: row.name,
        accountMode: mode,
        quantityMicro: row.quantityMicro!,
        averageCostMinor: row.averageCostMinor!,
        currentPriceMinor: row.currentPriceMinor!,
        isArchived: row.isArchived,
        createdAtUtc: row.createdAtUtc.toUtc(),
        updatedAtUtc: row.updatedAtUtc.toUtc(),
      );
    }
    return holding_domain.StockHolding.principal(
      id: row.id,
      accountId: row.accountId,
      symbol: row.symbol,
      name: row.name,
      accountMode: mode,
      principalMinor: row.principalMinor!,
      isArchived: row.isArchived,
      createdAtUtc: row.createdAtUtc.toUtc(),
      updatedAtUtc: row.updatedAtUtc.toUtc(),
    );
  }
}
