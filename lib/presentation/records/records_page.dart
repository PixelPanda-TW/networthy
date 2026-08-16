import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../application/transaction/delete_transaction_use_case.dart';
import '../../domain/model/category.dart';
import '../../domain/model/transaction.dart';
import '../../domain/model/transaction_type.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/transaction_repository.dart';
import '../formatters/twd_formatter.dart';
import '../transaction/transaction_form_page.dart';

enum RecordsTypeFilter { all, income, expense }

class RecordsPage extends StatefulWidget {
  const RecordsPage({
    super.key,
    required this.transactions,
    required this.settings,
    required this.clock,
    required this.idGenerator,
    required this.initialDate,
    required this.onRecordsChanged,
  });

  final TransactionRepository transactions;
  final SettingsRepository settings;
  final ApplicationClock clock;
  final TransactionIdGenerator idGenerator;
  final DateTime initialDate;
  final VoidCallback onRecordsChanged;

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  late int _year;
  late int _month;
  var _typeFilter = RecordsTypeFilter.all;
  late Future<List<BookkeepingTransaction>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _recordsFuture = _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('紀錄'),
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
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$_year年$_month月',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<RecordsTypeFilter>(
                  segments: const [
                    ButtonSegment(
                      value: RecordsTypeFilter.all,
                      label: Text('全部'),
                    ),
                    ButtonSegment(
                      value: RecordsTypeFilter.income,
                      label: Text('收入'),
                    ),
                    ButtonSegment(
                      value: RecordsTypeFilter.expense,
                      label: Text('支出'),
                    ),
                  ],
                  selected: {_typeFilter},
                  onSelectionChanged: (values) {
                    setState(() {
                      _typeFilter = values.single;
                      _recordsFuture = _load();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<BookkeepingTransaction>>(
              future: _recordsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: Text('載入中'));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('紀錄載入失敗'));
                }
                final records = snapshot.data!;
                if (records.isEmpty) {
                  return const Center(child: Text('目前沒有記帳紀錄'));
                }
                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final categoryName = CategoryCatalog.displayNameFor(
                      record.categoryId,
                    );
                    final deleteLabel = record.note ?? categoryName;
                    return ListTile(
                      title: Text(record.note ?? record.type.label),
                      subtitle: Text('${record.transactionDate} $categoryName'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(formatTwd(record.amountMinor)),
                          Semantics(
                            label: '刪除 $deleteLabel',
                            button: true,
                            child: IconButton(
                              tooltip: '刪除 $deleteLabel',
                              onPressed: () => _confirmDelete(record),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _openEditForm(record),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<BookkeepingTransaction>> _load() async {
    final records = await widget.transactions.list(
      TransactionQuery(
        year: _year,
        month: _month,
        type: switch (_typeFilter) {
          RecordsTypeFilter.all => null,
          RecordsTypeFilter.income => TransactionType.income,
          RecordsTypeFilter.expense => TransactionType.expense,
        },
      ),
    );
    final sorted = records.toList()
      ..sort((a, b) {
        final dateComparison = b.transactionDate.compareTo(a.transactionDate);
        if (dateComparison != 0) {
          return dateComparison;
        }
        return b.createdAtUtc.compareTo(a.createdAtUtc);
      });
    return sorted;
  }

  void _previousMonth() {
    setState(() {
      if (_month == 1) {
        _year -= 1;
        _month = 12;
      } else {
        _month -= 1;
      }
      _recordsFuture = _load();
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
      _recordsFuture = _load();
    });
  }

  Future<void> _openEditForm(BookkeepingTransaction record) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TransactionFormPage(
          transactions: widget.transactions,
          settings: widget.settings,
          clock: widget.clock,
          idGenerator: widget.idGenerator,
          initialDate: DateTime(_year, _month),
          existing: record,
        ),
      ),
    );
    if (changed == true && mounted) {
      widget.onRecordsChanged();
      setState(() {
        _recordsFuture = _load();
      });
    }
  }

  Future<void> _confirmDelete(BookkeepingTransaction record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('刪除後無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    final result = await DeleteTransactionUseCase(
      widget.transactions,
    ).execute(DeleteTransactionRequest(id: record.id, confirmed: true));
    if (!mounted) {
      return;
    }
    if (result.failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('刪除失敗，請稍後再試。')));
      return;
    }

    widget.onRecordsChanged();
    setState(() {
      _recordsFuture = _load();
    });
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
