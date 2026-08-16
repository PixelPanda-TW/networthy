import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../domain/model/transaction.dart';
import '../../domain/model/transaction_type.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/transaction_repository.dart';
import '../../domain/summary/monthly_summary.dart';
import '../formatters/twd_formatter.dart';
import '../transaction/transaction_form_page.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({
    super.key,
    required this.transactions,
    required this.settings,
    required this.clock,
    required this.idGenerator,
    required this.initialDate,
  });

  final TransactionRepository transactions;
  final SettingsRepository settings;
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
          IconButton(
            tooltip: '上一個月',
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: '下一個月',
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
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
                '${data.summary.year}年${data.summary.month}月',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    label: '收入',
                    value: formatTwd(data.summary.totalIncomeMinor),
                  ),
                  _MetricChip(
                    label: '支出',
                    value: formatTwd(data.summary.totalExpenseMinor),
                  ),
                  _MetricChip(
                    label: '結餘',
                    value: formatTwd(data.summary.balanceMinor),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('分類支出', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (data.summary.expenseCategoryTotals.isEmpty)
                const Text('目前沒有記帳紀錄')
              else
                for (final entry in data.summary.expenseCategoryTotals.entries)
                  Text('${entry.key} ${formatTwd(entry.value)}'),
              const SizedBox(height: 24),
              Text('最近五筆', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (data.recentTransactions.isEmpty)
                const Text('目前沒有記帳紀錄')
              else
                for (final transaction in data.recentTransactions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${transaction.categoryId} ${formatTwd(transaction.amountMinor)}',
                    ),
                    subtitle: Text(transaction.note ?? transaction.type.label),
                    onTap: () => _openForm(existing: transaction),
                  ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '新增記帳',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<_OverviewData> _load() async {
    final summary = await widget.transactions.monthlySummary(
      year: _year,
      month: _month,
    );
    final recent = await widget.transactions.latest(limit: 5);
    return _OverviewData(summary: summary, recentTransactions: recent);
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

  Future<void> _openForm({BookkeepingTransaction? existing}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TransactionFormPage(
          transactions: widget.transactions,
          settings: widget.settings,
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
}

class _OverviewData {
  const _OverviewData({
    required this.summary,
    required this.recentTransactions,
  });

  final MonthlySummary summary;
  final List<BookkeepingTransaction> recentTransactions;
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

extension on TransactionType {
  String get label {
    return switch (this) {
      TransactionType.income => '收入',
      TransactionType.expense => '支出',
    };
  }
}
