import 'package:flutter/material.dart';
import 'package:networthy/application/common/application_ports.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/domain/model/account.dart';
import 'package:networthy/domain/model/category.dart';
import 'package:networthy/domain/model/category_definition.dart';
import 'package:networthy/domain/model/currency_code.dart';
import 'package:networthy/domain/model/ledger_transaction.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/domain/repository/account_repository.dart';
import 'package:networthy/domain/repository/category_repository.dart';
import 'package:networthy/domain/repository/ledger_repository.dart';
import 'package:networthy/domain/repository/settings_repository.dart';
import 'package:networthy/domain/repository/transaction_repository.dart';
import 'package:networthy/domain/ledger/ledger_transaction_builder.dart';
import 'package:networthy/domain/summary/monthly_summary.dart';

MaterialApp testMaterialApp(Widget home) {
  return MaterialApp(theme: ThemeData(useMaterial3: true), home: home);
}

class TestClock implements ApplicationClock {
  TestClock(this.current);

  DateTime current;

  @override
  DateTime nowUtc() {
    final value = current;
    current = current.add(const Duration(minutes: 1));
    return value;
  }
}

class TestIdGenerator implements TransactionIdGenerator {
  TestIdGenerator(this._ids);

  final List<String> _ids;

  @override
  String generate() {
    return _ids.removeAt(0);
  }
}

class TestSettingsRepository implements SettingsRepository {
  TestSettingsRepository([AppSettings? initial])
    : value = initial ?? const AppSettings.defaults();

  AppSettings value;

  @override
  Future<AppSettings> load() async => value;

  @override
  Future<void> save(AppSettings settings) async {
    value = settings;
  }
}

class TestTransactionRepository implements TransactionRepository {
  TestTransactionRepository({this.throwOnSave = false});

  final bool throwOnSave;
  final Map<String, BookkeepingTransaction> values =
      <String, BookkeepingTransaction>{};

  @override
  Future<void> delete(String id) async {
    values.remove(id);
  }

  @override
  Future<BookkeepingTransaction?> findById(String id) async {
    return values[id];
  }

  @override
  Future<List<BookkeepingTransaction>> latest({required int limit}) async {
    final rows = values.values.toList()
      ..sort((a, b) {
        final dateComparison = b.transactionDate.compareTo(a.transactionDate);
        if (dateComparison != 0) {
          return dateComparison;
        }
        return b.createdAtUtc.compareTo(a.createdAtUtc);
      });
    return rows.take(limit).toList(growable: false);
  }

  @override
  Future<List<BookkeepingTransaction>> list(TransactionQuery query) async {
    return values.values
        .where((transaction) {
          final matchesYear =
              query.year == null ||
              transaction.transactionDate.year == query.year;
          final matchesMonth =
              query.month == null ||
              transaction.transactionDate.month == query.month;
          final matchesType =
              query.type == null || transaction.type == query.type;
          return matchesYear && matchesMonth && matchesType;
        })
        .toList(growable: false);
  }

  @override
  Future<MonthlySummary> monthlySummary({
    required int year,
    required int month,
  }) async {
    return MonthlySummary.calculate(
      transactions: values.values,
      year: year,
      month: month,
    );
  }

  @override
  Future<void> save(BookkeepingTransaction transaction) async {
    if (throwOnSave) {
      throw Exception('save failed');
    }
    values[transaction.id] = transaction;
  }
}

class TestCategoryRepository implements CategoryRepository {
  TestCategoryRepository({bool seedBuiltIns = true}) {
    if (seedBuiltIns) {
      final now = DateTime.utc(2026, 8, 16);
      for (final entry in CategoryCatalog.builtInDefinitions.indexed) {
        final (index, category) = entry;
        values[category.id] = EditableCategory.create(
          id: category.id,
          type: category.type,
          name: category.displayName,
          parentId: null,
          sortOrder: index,
          isArchived: false,
          createdAtUtc: now,
          updatedAtUtc: now,
        );
      }
    }
  }

  final Map<String, EditableCategory> values = <String, EditableCategory>{};

  @override
  Future<void> archive(String id) async {
    final category = values[id];
    if (category == null) {
      throw const CategoryRepositoryException('分類不存在。');
    }
    final hasActiveChildren = values.values.any(
      (item) => item.parentId == id && !item.isArchived,
    );
    if (hasActiveChildren) {
      throw const CategoryRepositoryException('請先封存子分類。');
    }
    values[id] = EditableCategory.create(
      id: category.id,
      type: category.type,
      name: category.name,
      parentId: category.parentId,
      sortOrder: category.sortOrder,
      isArchived: true,
      createdAtUtc: category.createdAtUtc,
      updatedAtUtc: DateTime.utc(2026, 8, 16),
    );
  }

  @override
  Future<EditableCategory> create(CreateCategoryRequest request) async {
    if (values.containsKey(request.id)) {
      throw const CategoryRepositoryException('分類已存在。');
    }
    final parent = _parentForCreate(request);
    _ensureUniqueActiveSiblingName(
      type: request.type,
      parentId: request.parentId,
      name: request.name,
    );
    final now = DateTime.utc(2026, 8, 16);
    final category = EditableCategory.create(
      id: request.id,
      type: request.type,
      name: request.name,
      parentId: parent?.id,
      sortOrder: _nextSortOrder(type: request.type, parentId: request.parentId),
      isArchived: false,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
    values[category.id] = category;
    return category;
  }

  @override
  Future<String> displayPathFor(String id) async {
    final category = values[id];
    if (category == null) {
      return id;
    }
    final parent = category.parentId == null ? null : values[category.parentId];
    return category.displayPath(parent: parent);
  }

  @override
  Future<EditableCategory?> findById(String id) async {
    return values[id];
  }

  @override
  Future<List<EditableCategory>> listActive(TransactionType type) async {
    final rows = values.values
        .where((category) => category.type == type && !category.isArchived)
        .toList();
    _sortCategories(rows);
    return rows;
  }

  @override
  Future<List<EditableCategory>> listAll(TransactionType type) async {
    final rows = values.values
        .where((category) => category.type == type)
        .toList();
    _sortCategories(rows);
    return rows;
  }

  @override
  Future<EditableCategory> rename({
    required String id,
    required String name,
  }) async {
    final category = values[id];
    if (category == null) {
      throw const CategoryRepositoryException('分類不存在。');
    }
    _ensureUniqueActiveSiblingName(
      type: category.type,
      parentId: category.parentId,
      name: name,
      excludingId: id,
    );
    final updated = EditableCategory.create(
      id: category.id,
      type: category.type,
      name: name,
      parentId: category.parentId,
      sortOrder: category.sortOrder,
      isArchived: category.isArchived,
      createdAtUtc: category.createdAtUtc,
      updatedAtUtc: DateTime.utc(2026, 8, 16),
    );
    values[id] = updated;
    return updated;
  }

  EditableCategory? _parentForCreate(CreateCategoryRequest request) {
    final parentId = request.parentId;
    if (parentId == null) {
      return null;
    }
    final parent = values[parentId];
    if (parent == null) {
      throw const CategoryRepositoryException('父分類不存在。');
    }
    if (parent.type != request.type) {
      throw const CategoryRepositoryException('父分類類型不相容。');
    }
    if (parent.parentId != null) {
      throw const CategoryRepositoryException('子分類不能再建立子分類。');
    }
    if (parent.isArchived) {
      throw const CategoryRepositoryException('父分類已封存。');
    }
    return parent;
  }

  void _ensureUniqueActiveSiblingName({
    required TransactionType type,
    required String? parentId,
    required String name,
    String? excludingId,
  }) {
    final normalized = name.trim();
    final duplicate = values.values.any(
      (category) =>
          category.id != excludingId &&
          category.type == type &&
          category.parentId == parentId &&
          !category.isArchived &&
          category.name == normalized,
    );
    if (duplicate) {
      throw const CategoryRepositoryException('同層分類名稱已存在。');
    }
  }

  int _nextSortOrder({
    required TransactionType type,
    required String? parentId,
  }) {
    final siblingOrders = values.values
        .where(
          (category) => category.type == type && category.parentId == parentId,
        )
        .map((category) => category.sortOrder);
    if (siblingOrders.isEmpty) {
      return 0;
    }
    return siblingOrders.reduce((a, b) => a > b ? a : b) + 1;
  }

  void _sortCategories(List<EditableCategory> rows) {
    rows.sort((a, b) {
      final parentComparison = (a.parentId ?? '').compareTo(b.parentId ?? '');
      if (parentComparison != 0) {
        return parentComparison;
      }
      final sortComparison = a.sortOrder.compareTo(b.sortOrder);
      if (sortComparison != 0) {
        return sortComparison;
      }
      return a.name.compareTo(b.name);
    });
  }
}

class TestAccountRepository implements AccountRepository {
  TestAccountRepository({bool seedDefault = true}) {
    if (seedDefault) {
      ensureDefaultAccountSeeded();
    }
  }

  static const defaultAccountId = '00000000-0000-4000-8000-000000030000';

  final Map<String, CashAccount> values = <String, CashAccount>{};

  @override
  Future<void> archive(String id) async {
    final account = values[id];
    if (account == null) {
      throw const AccountRepositoryException('帳戶不存在。');
    }
    values[id] = CashAccount.create(
      id: account.id,
      name: account.name,
      currencyCode: account.currencyCode,
      isArchived: true,
      createdAtUtc: account.createdAtUtc,
      updatedAtUtc: DateTime.utc(2026, 8, 17),
    );
  }

  @override
  Future<CashAccount> create(CreateAccountRequest request) async {
    if (values.containsKey(request.id)) {
      throw const AccountRepositoryException('帳戶已存在。');
    }
    _ensureUniqueActiveName(
      name: request.name,
      currencyCode: request.currencyCode,
    );
    final now = DateTime.utc(2026, 8, 17);
    final account = CashAccount.create(
      id: request.id,
      name: request.name,
      currencyCode: request.currencyCode,
      isArchived: false,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
    values[account.id] = account;
    return account;
  }

  @override
  Future<String> displayNameFor(String id) async {
    return values[id]?.name ?? id;
  }

  @override
  Future<CashAccount> ensureDefaultAccountSeeded() async {
    final existing = values[defaultAccountId];
    if (existing != null) {
      return existing;
    }
    final now = DateTime.utc(2026, 8, 17);
    final account = CashAccount.create(
      id: defaultAccountId,
      name: '現金 TWD',
      currencyCode: CurrencyCode.twd,
      isArchived: false,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
    values[account.id] = account;
    return account;
  }

  @override
  Future<CashAccount?> findById(String id) async {
    return values[id];
  }

  @override
  Future<List<CashAccount>> listActive() async {
    final rows = values.values.where((account) => !account.isArchived).toList();
    _sortAccounts(rows);
    return rows;
  }

  @override
  Future<List<CashAccount>> listAll() async {
    final rows = values.values.toList();
    _sortAccounts(rows);
    return rows;
  }

  @override
  Future<CashAccount> rename({required String id, required String name}) async {
    final account = values[id];
    if (account == null) {
      throw const AccountRepositoryException('帳戶不存在。');
    }
    _ensureUniqueActiveName(
      name: name,
      currencyCode: account.currencyCode,
      excludingId: id,
    );
    final updated = CashAccount.create(
      id: account.id,
      name: name,
      currencyCode: account.currencyCode,
      isArchived: account.isArchived,
      createdAtUtc: account.createdAtUtc,
      updatedAtUtc: DateTime.utc(2026, 8, 17),
    );
    values[id] = updated;
    return updated;
  }

  void _ensureUniqueActiveName({
    required String name,
    required CurrencyCode currencyCode,
    String? excludingId,
  }) {
    final normalizedName = name.trim();
    final duplicate = values.values.any(
      (account) =>
          account.id != excludingId &&
          !account.isArchived &&
          account.currencyCode == currencyCode &&
          account.name == normalizedName,
    );
    if (duplicate) {
      throw const AccountRepositoryException('同幣別帳戶名稱已存在。');
    }
  }

  void _sortAccounts(List<CashAccount> rows) {
    rows.sort((a, b) {
      final currencyComparison = a.currencyCode.wireValue.compareTo(
        b.currencyCode.wireValue,
      );
      if (currencyComparison != 0) {
        return currencyComparison;
      }
      return a.name.compareTo(b.name);
    });
  }
}

class TestLedgerRepository implements LedgerRepository {
  final Map<String, LedgerRecord> values = <String, LedgerRecord>{};

  @override
  Future<List<AccountBalance>> accountBalances() async {
    final totals = <String, ({CurrencyCode currencyCode, int balanceMinor})>{};
    for (final record in values.values) {
      for (final entry in record.entries) {
        final current = totals[entry.accountId];
        totals[entry.accountId] = (
          currencyCode: entry.currencyCode,
          balanceMinor: (current?.balanceMinor ?? 0) + entry.amountMinor,
        );
      }
    }
    final rows = totals.entries
        .map(
          (entry) => AccountBalance(
            accountId: entry.key,
            currencyCode: entry.value.currencyCode,
            balanceMinor: entry.value.balanceMinor,
          ),
        )
        .toList();
    rows.sort((a, b) => a.accountId.compareTo(b.accountId));
    return rows;
  }

  @override
  Future<void> delete(String id) async {
    values.remove(id);
  }

  @override
  Future<LedgerRecord?> findRecordById(String id) async {
    return values[id];
  }

  @override
  Future<List<LedgerRecord>> latest({required int limit}) async {
    final rows = values.values
        .where(
          (record) =>
              record.transaction.type != LedgerTransactionType.openingBalance,
        )
        .toList();
    _sortRecords(rows);
    return rows.take(limit).toList(growable: false);
  }

  @override
  Future<List<LedgerRecord>> list(LedgerQuery query) async {
    final rows = values.values.where((record) {
      final transaction = record.transaction;
      if (!query.includeOpeningBalances &&
          transaction.type == LedgerTransactionType.openingBalance) {
        return false;
      }
      final matchesYear =
          query.year == null || transaction.transactionDate.year == query.year;
      final matchesMonth =
          query.month == null ||
          transaction.transactionDate.month == query.month;
      final matchesType = query.type == null || transaction.type == query.type;
      return matchesYear && matchesMonth && matchesType;
    }).toList();
    _sortRecords(rows);
    return rows;
  }

  @override
  Future<CurrencyMonthlySummary> monthlySummary({
    required int year,
    required int month,
  }) async {
    final income = <CurrencyCode, int>{};
    final expense = <CurrencyCode, int>{};
    for (final record in values.values) {
      final transaction = record.transaction;
      if (!transaction.transactionDate.isInMonth(year, month)) {
        continue;
      }
      switch (transaction.type) {
        case LedgerTransactionType.income:
          for (final entry in record.entries) {
            income.update(
              entry.currencyCode,
              (current) => current + entry.amountMinor,
              ifAbsent: () => entry.amountMinor,
            );
          }
        case LedgerTransactionType.expense:
          for (final entry in record.entries) {
            expense.update(
              entry.currencyCode,
              (current) => current + entry.amountMinor.abs(),
              ifAbsent: () => entry.amountMinor.abs(),
            );
          }
        case LedgerTransactionType.transfer:
        case LedgerTransactionType.openingBalance:
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
    _validateAggregate(aggregate);
    values[aggregate.transaction.id] = LedgerRecord(
      transaction: aggregate.transaction,
      entries: List.unmodifiable(aggregate.entries),
    );
  }

  void _validateAggregate(LedgerTransactionAggregate aggregate) {
    final transaction = aggregate.transaction;
    final entries = aggregate.entries;
    switch (transaction.type) {
      case LedgerTransactionType.income:
      case LedgerTransactionType.expense:
      case LedgerTransactionType.openingBalance:
        if (entries.length != 1) {
          throw StateError('${transaction.type} requires exactly one entry.');
        }
      case LedgerTransactionType.transfer:
        if (entries.length != 2) {
          throw StateError('Transfer requires exactly two entries.');
        }
        final total = entries.fold<int>(
          0,
          (sum, entry) => sum + entry.amountMinor,
        );
        final currencies = entries.map((entry) => entry.currencyCode).toSet();
        if (total != 0 || currencies.length != 1) {
          throw StateError('Transfer entries must balance in one currency.');
        }
    }
    if (entries.any((entry) => entry.transactionId != transaction.id)) {
      throw StateError('Ledger entry transaction id mismatch.');
    }
  }

  void _sortRecords(List<LedgerRecord> rows) {
    rows.sort((a, b) {
      final dateComparison = b.transaction.transactionDate.compareTo(
        a.transaction.transactionDate,
      );
      if (dateComparison != 0) {
        return dateComparison;
      }
      return b.transaction.createdAtUtc.compareTo(a.transaction.createdAtUtc);
    });
  }
}
