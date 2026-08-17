import 'package:drift/drift.dart';

import '../../domain/ledger/ledger_transaction_builder.dart';
import '../../domain/model/currency_code.dart';
import '../../domain/model/ledger_entry.dart' as domain;
import '../../domain/model/ledger_transaction.dart' as domain;
import '../../domain/model/local_date.dart';
import '../../domain/repository/ledger_repository.dart';
import '../database/networthy_database.dart';

class DriftLedgerRepository implements LedgerRepository {
  const DriftLedgerRepository(this._database);

  final NetworthyDatabase _database;

  @override
  Future<List<AccountBalance>> accountBalances() async {
    final rows = await _database.select(_database.ledgerEntries).get();
    final totals = <String, ({CurrencyCode currencyCode, int balanceMinor})>{};
    for (final row in rows) {
      final currencyCode = CurrencyCode.fromWireValue(row.currencyCode);
      final current = totals[row.accountId];
      totals[row.accountId] = (
        currencyCode: currencyCode,
        balanceMinor: (current?.balanceMinor ?? 0) + row.amountMinor,
      );
    }
    final balances = totals.entries
        .map(
          (entry) => AccountBalance(
            accountId: entry.key,
            currencyCode: entry.value.currencyCode,
            balanceMinor: entry.value.balanceMinor,
          ),
        )
        .toList();
    balances.sort((a, b) => a.accountId.compareTo(b.accountId));
    return balances;
  }

  @override
  Future<void> delete(String id) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.ledgerEntries,
      )..where((table) => table.transactionId.equals(id))).go();
      await (_database.delete(
        _database.ledgerTransactions,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  @override
  Future<LedgerRecord?> findRecordById(String id) async {
    final transactionRow = await (_database.select(
      _database.ledgerTransactions,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (transactionRow == null) {
      return null;
    }
    final entryRows =
        await (_database.select(_database.ledgerEntries)
              ..where((table) => table.transactionId.equals(id))
              ..orderBy([(table) => OrderingTerm.asc(table.amountMinor)]))
            .get();
    return LedgerRecord(
      transaction: _transactionToDomain(transactionRow),
      entries: entryRows.map(_entryToDomain).toList(growable: false),
    );
  }

  @override
  Future<List<LedgerRecord>> latest({required int limit}) async {
    final records = await list(const LedgerQuery());
    return records.take(limit).toList(growable: false);
  }

  @override
  Future<List<LedgerRecord>> list(LedgerQuery query) async {
    final select = _database.select(_database.ledgerTransactions);
    if (!query.includeOpeningBalances) {
      select.where(
        (table) => table.type
            .equals(_storageValue(domain.LedgerTransactionType.openingBalance))
            .not(),
      );
    }
    if (query.year != null) {
      select.where((table) => table.transactionYear.equals(query.year!));
    }
    if (query.month != null) {
      select.where((table) => table.transactionMonth.equals(query.month!));
    }
    if (query.type != null) {
      select.where((table) => table.type.equals(_storageValue(query.type!)));
    }
    select.orderBy([
      (table) => OrderingTerm.desc(table.transactionYear),
      (table) => OrderingTerm.desc(table.transactionMonth),
      (table) => OrderingTerm.desc(table.transactionDay),
      (table) => OrderingTerm.desc(table.createdAtUtc),
    ]);
    final transactionRows = await select.get();
    final records = <LedgerRecord>[];
    for (final row in transactionRows) {
      final record = await findRecordById(row.id);
      if (record != null) {
        records.add(record);
      }
    }
    return records;
  }

  @override
  Future<CurrencyMonthlySummary> monthlySummary({
    required int year,
    required int month,
  }) async {
    final records = await list(
      LedgerQuery(year: year, month: month, includeOpeningBalances: true),
    );
    final income = <CurrencyCode, int>{};
    final expense = <CurrencyCode, int>{};
    for (final record in records) {
      switch (record.transaction.type) {
        case domain.LedgerTransactionType.income:
          for (final entry in record.entries) {
            income.update(
              entry.currencyCode,
              (current) => current + entry.amountMinor,
              ifAbsent: () => entry.amountMinor,
            );
          }
        case domain.LedgerTransactionType.expense:
          for (final entry in record.entries) {
            expense.update(
              entry.currencyCode,
              (current) => current + entry.amountMinor.abs(),
              ifAbsent: () => entry.amountMinor.abs(),
            );
          }
        case domain.LedgerTransactionType.transfer:
        case domain.LedgerTransactionType.openingBalance:
          break;
      }
    }
    return CurrencyMonthlySummary(
      totalIncomeMinorByCurrency: Map<CurrencyCode, int>.unmodifiable(income),
      totalExpenseMinorByCurrency: Map<CurrencyCode, int>.unmodifiable(expense),
    );
  }

  @override
  Future<void> save(LedgerTransactionAggregate aggregate) async {
    await _database.transaction(() async {
      await _database
          .into(_database.ledgerTransactions)
          .insertOnConflictUpdate(
            _transactionToCompanion(aggregate.transaction),
          );
      await (_database.delete(_database.ledgerEntries)..where(
            (table) => table.transactionId.equals(aggregate.transaction.id),
          ))
          .go();
      for (final entry in aggregate.entries) {
        await _database
            .into(_database.ledgerEntries)
            .insert(_entryToCompanion(entry));
      }
    });
  }

  LedgerTransactionsCompanion _transactionToCompanion(
    domain.LedgerTransaction transaction,
  ) {
    return LedgerTransactionsCompanion.insert(
      id: transaction.id,
      type: _storageValue(transaction.type),
      categoryId: Value(transaction.categoryId),
      transactionYear: transaction.transactionDate.year,
      transactionMonth: transaction.transactionDate.month,
      transactionDay: transaction.transactionDate.day,
      note: Value(transaction.note),
      createdAtUtc: transaction.createdAtUtc,
      updatedAtUtc: transaction.updatedAtUtc,
    );
  }

  LedgerEntriesCompanion _entryToCompanion(domain.LedgerEntry entry) {
    return LedgerEntriesCompanion.insert(
      id: entry.id,
      transactionId: entry.transactionId,
      accountId: entry.accountId,
      amountMinor: entry.amountMinor,
      currencyCode: entry.currencyCode.wireValue,
      createdAtUtc: entry.createdAtUtc,
    );
  }

  domain.LedgerTransaction _transactionToDomain(LedgerTransaction row) {
    return domain.LedgerTransaction.create(
      id: row.id,
      type: _typeFromStorage(row.type),
      categoryId: row.categoryId,
      transactionDate: LocalDate(
        row.transactionYear,
        row.transactionMonth,
        row.transactionDay,
      ),
      note: row.note,
      createdAtUtc: row.createdAtUtc.toUtc(),
      updatedAtUtc: row.updatedAtUtc.toUtc(),
    );
  }

  domain.LedgerEntry _entryToDomain(LedgerEntry row) {
    return domain.LedgerEntry.create(
      id: row.id,
      transactionId: row.transactionId,
      accountId: row.accountId,
      amountMinor: row.amountMinor,
      currencyCode: CurrencyCode.fromWireValue(row.currencyCode),
      createdAtUtc: row.createdAtUtc.toUtc(),
      allowZeroAmount: true,
    );
  }

  String _storageValue(domain.LedgerTransactionType type) {
    return switch (type) {
      domain.LedgerTransactionType.income => 'income',
      domain.LedgerTransactionType.expense => 'expense',
      domain.LedgerTransactionType.transfer => 'transfer',
      domain.LedgerTransactionType.openingBalance => 'opening_balance',
    };
  }

  domain.LedgerTransactionType _typeFromStorage(String value) {
    return switch (value) {
      'income' => domain.LedgerTransactionType.income,
      'expense' => domain.LedgerTransactionType.expense,
      'transfer' => domain.LedgerTransactionType.transfer,
      'opening_balance' => domain.LedgerTransactionType.openingBalance,
      _ => throw StateError('Unknown ledger transaction type.'),
    };
  }
}
