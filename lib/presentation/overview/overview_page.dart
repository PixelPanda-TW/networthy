import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../domain/model/currency_code.dart';
import '../../domain/model/ledger_transaction.dart';
import '../../domain/repository/account_repository.dart';
import '../../domain/repository/category_repository.dart';
import '../../domain/repository/ledger_repository.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/transaction_repository.dart';
import '../formatters/twd_formatter.dart';
import '../transaction/transaction_form_page.dart';
import '../transfer/transfer_form_page.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.ledger,
    required this.settings,
    required this.categories,
    required this.clock,
    required this.idGenerator,
    required this.initialDate,
  });

  final TransactionRepository transactions;
  final AccountRepository accounts;
  final LedgerRepository ledger;
  final SettingsRepository settings;
  final CategoryRepository categories;
  final ApplicationClock clock;
  final TransactionIdGenerator idGenerator;
  final DateTime initialDate;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late int _year;
  late int _month;
  late Future<_OverviewData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _dataFuture = _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('總覽'),
        actions: [
          Semantics(
            label: '切換到上一個月',
            button: true,
            child: IconButton(
              tooltip: '上一個月',
              onPressed: _previousMonth,
              icon: const Icon(Icons.chevron_left),
            ),
          ),
          Semantics(
            label: '切換到下一個月',
            button: true,
            child: IconButton(
              tooltip: '下一個月',
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ),
          TextButton(onPressed: _openTransferForm, child: const Text('轉帳')),
        ],
      ),
      body: FutureBuilder<_OverviewData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Text('載入中'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('資料載入失敗'));
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${data.year}年${data.month}月',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final MapEntry(key: currency, value: amount)
                      in data.summary.totalIncomeMinorByCurrency.entries)
                    _MetricChip(
                      label: '收入',
                      value: formatCurrency(amount, currency),
                    ),
                  if (data.summary.totalIncomeMinorByCurrency.isEmpty)
                    _MetricChip(
                      label: '收入',
                      value: formatCurrency(0, CurrencyCode.twd),
                    ),
                  for (final MapEntry(key: currency, value: amount)
                      in data.summary.totalExpenseMinorByCurrency.entries)
                    _MetricChip(
                      label: '支出',
                      value: formatCurrency(amount, currency),
                    ),
                  if (data.summary.totalExpenseMinorByCurrency.isEmpty)
                    _MetricChip(
                      label: '支出',
                      value: formatCurrency(0, CurrencyCode.twd),
                    ),
                  for (final MapEntry(key: currency, value: amount)
                      in data.summary.balanceMinorByCurrency.entries)
                    _MetricChip(
                      label: '結餘',
                      value: formatCurrency(amount, currency),
                    ),
                  if (data.summary.balanceMinorByCurrency.isEmpty)
                    _MetricChip(
                      label: '結餘',
                      value: formatCurrency(0, CurrencyCode.twd),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('分類支出', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (data.expenseCategoryTotals.isEmpty)
                const Text('目前沒有記帳紀錄')
              else
                for (final entry in data.expenseCategoryTotals.entries)
                  Text(
                    '${data.categoryDisplayPaths[entry.key] ?? entry.key} '
                    '${formatCurrency(entry.value, CurrencyCode.twd)}',
                  ),
              const SizedBox(height: 24),
              Text('最近五筆', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (data.recentRecords.isEmpty)
                const Text('目前沒有記帳紀錄')
              else
                for (final record in data.recentRecords)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _recentRecordTitle(record, data.categoryDisplayPaths),
                    ),
                    subtitle: Text(
                      record.transaction.note ?? record.transaction.type.label,
                    ),
                    onTap: () => _openForm(existing: record),
                  ),
            ],
          );
        },
      ),
      floatingActionButton: Semantics(
        label: '新增一筆記帳',
        button: true,
        child: FloatingActionButton(
          tooltip: '新增記帳',
          onPressed: () => _openForm(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<_OverviewData> _load() async {
    final summary = await widget.ledger.monthlySummary(
      year: _year,
      month: _month,
    );
    final recent = await widget.ledger.latest(limit: 5);
    final monthlyRecords = await widget.ledger.list(
      LedgerQuery(year: _year, month: _month),
    );
    final expenseCategoryTotals = <String, int>{};
    for (final record in monthlyRecords) {
      if (record.transaction.type != LedgerTransactionType.expense) {
        continue;
      }
      final categoryId = record.transaction.categoryId;
      if (categoryId == null) {
        continue;
      }
      expenseCategoryTotals.update(
        categoryId,
        (current) => current + record.entries.single.amountMinor.abs(),
        ifAbsent: () => record.entries.single.amountMinor.abs(),
      );
    }
    final categoryDisplayPaths = await _displayPathsFor({
      ...expenseCategoryTotals.keys,
      for (final record in recent)
        if (record.transaction.categoryId != null)
          record.transaction.categoryId!,
    });
    return _OverviewData(
      year: _year,
      month: _month,
      summary: summary,
      expenseCategoryTotals: expenseCategoryTotals,
      recentRecords: recent,
      categoryDisplayPaths: categoryDisplayPaths,
    );
  }

  Future<Map<String, String>> _displayPathsFor(Set<String> ids) async {
    final entries = await Future.wait(
      ids.map(
        (id) async => MapEntry(id, await widget.categories.displayPathFor(id)),
      ),
    );
    return Map<String, String>.fromEntries(entries);
  }

  void _previousMonth() {
    setState(() {
      if (_month == 1) {
        _year -= 1;
        _month = 12;
      } else {
        _month -= 1;
      }
      _dataFuture = _load();
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _year += 1;
        _month = 1;
      } else {
        _month += 1;
      }
      _dataFuture = _load();
    });
  }

  Future<void> _openForm({LedgerRecord? existing}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TransactionFormPage(
          transactions: widget.transactions,
          accounts: widget.accounts,
          ledger: widget.ledger,
          settings: widget.settings,
          categories: widget.categories,
          clock: widget.clock,
          idGenerator: widget.idGenerator,
          initialDate: DateTime(_year, _month),
          existing: existing,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() {
        _dataFuture = _load();
      });
    }
  }

  Future<void> _openTransferForm() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TransferFormPage(
          accounts: widget.accounts,
          ledger: widget.ledger,
          clock: widget.clock,
          idGenerator: widget.idGenerator,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() {
        _dataFuture = _load();
      });
    }
  }
}

String _recentRecordTitle(
  LedgerRecord record,
  Map<String, String> categoryDisplayPaths,
) {
  if (record.transaction.type == LedgerTransactionType.transfer) {
    final amount = record.entries
        .where((entry) => entry.amountMinor > 0)
        .first
        .amountMinor;
    return '轉帳 ${formatCurrency(amount, record.entries.first.currencyCode)}';
  }
  final entry = record.entries.single;
  return '${categoryDisplayPaths[record.transaction.categoryId] ?? record.transaction.categoryId} '
      '${formatCurrency(entry.amountMinor.abs(), entry.currencyCode)}';
}

class _OverviewData {
  const _OverviewData({
    required this.year,
    required this.month,
    required this.summary,
    required this.expenseCategoryTotals,
    required this.recentRecords,
    required this.categoryDisplayPaths,
  });

  final int year;
  final int month;
  final CurrencyMonthlySummary summary;
  final Map<String, int> expenseCategoryTotals;
  final List<LedgerRecord> recentRecords;
  final Map<String, String> categoryDisplayPaths;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label $value'));
  }
}

extension on LedgerTransactionType {
  String get label {
    return switch (this) {
      LedgerTransactionType.income => '收入',
      LedgerTransactionType.expense => '支出',
      LedgerTransactionType.transfer => '轉帳',
      LedgerTransactionType.openingBalance => '初始餘額',
    };
  }
}
