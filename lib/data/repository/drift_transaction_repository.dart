import 'package:drift/drift.dart';

import '../../domain/model/local_date.dart';
import '../../domain/model/transaction.dart';
import '../../domain/model/transaction_type.dart';
import '../../domain/repository/transaction_repository.dart';
import '../../domain/summary/monthly_summary.dart';
import '../database/networthy_database.dart';

class DriftTransactionRepository implements TransactionRepository {
  const DriftTransactionRepository(this._database);

  final NetworthyDatabase _database;

  @override
  Future<void> save(BookkeepingTransaction transaction) async {
    await _database
        .into(_database.transactions)
        .insertOnConflictUpdate(_toCompanion(transaction));
  }

  @override
  Future<BookkeepingTransaction?> findById(String id) async {
    final row = await (_database.select(
      _database.transactions,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }

    return _toDomain(row);
  }

  @override
  Future<List<BookkeepingTransaction>> list(TransactionQuery query) async {
    final select = _database.select(_database.transactions);
    if (query.year != null) {
      select.where((table) => table.transactionYear.equals(query.year!));
    }
    if (query.month != null) {
      select.where((table) => table.transactionMonth.equals(query.month!));
    }
    if (query.type != null) {
      select.where((table) => table.type.equals(query.type!.storageValue));
    }
    select.orderBy([
      (table) => OrderingTerm.desc(table.transactionYear),
      (table) => OrderingTerm.desc(table.transactionMonth),
      (table) => OrderingTerm.desc(table.transactionDay),
      (table) => OrderingTerm.desc(table.createdAtUtc),
    ]);

    final rows = await select.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<BookkeepingTransaction>> latest({required int limit}) async {
    final rows =
        await (_database.select(_database.transactions)
              ..orderBy([
                (table) => OrderingTerm.desc(table.transactionYear),
                (table) => OrderingTerm.desc(table.transactionMonth),
                (table) => OrderingTerm.desc(table.transactionDay),
                (table) => OrderingTerm.desc(table.createdAtUtc),
              ])
              ..limit(limit))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<MonthlySummary> monthlySummary({
    required int year,
    required int month,
  }) async {
    final transactions = await list(TransactionQuery(year: year, month: month));
    return MonthlySummary.calculate(
      transactions: transactions,
      year: year,
      month: month,
    );
  }

  @override
  Future<void> delete(String id) async {
    await (_database.delete(
      _database.transactions,
    )..where((table) => table.id.equals(id))).go();
  }

  TransactionsCompanion _toCompanion(BookkeepingTransaction transaction) {
    return TransactionsCompanion.insert(
      id: transaction.id,
      type: transaction.type.storageValue,
      amountMinor: transaction.amountMinor,
      currencyCode: transaction.currencyCode,
      categoryId: transaction.categoryId,
      transactionYear: transaction.transactionDate.year,
      transactionMonth: transaction.transactionDate.month,
      transactionDay: transaction.transactionDate.day,
      note: Value(transaction.note),
      createdAtUtc: transaction.createdAtUtc,
      updatedAtUtc: transaction.updatedAtUtc,
    );
  }

  BookkeepingTransaction _toDomain(Transaction row) {
    return BookkeepingTransaction.create(
      id: row.id,
      type: _transactionTypeFromStorage(row.type),
      amountMinor: row.amountMinor,
      currencyCode: row.currencyCode,
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

  TransactionType _transactionTypeFromStorage(String value) {
    return switch (value) {
      'income' => TransactionType.income,
      'expense' => TransactionType.expense,
      _ => throw StateError('Unknown transaction type.'),
    };
  }
}

extension on TransactionType {
  String get storageValue {
    return switch (this) {
      TransactionType.income => 'income',
      TransactionType.expense => 'expense',
    };
  }
}
