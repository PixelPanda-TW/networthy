import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../application/ledger/ledger_command.dart';
import '../../application/ledger/ledger_use_cases.dart';
import '../../domain/model/ledger_transaction.dart';
import '../../domain/repository/account_repository.dart';
import '../../domain/repository/category_repository.dart';
import '../../domain/repository/ledger_repository.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/transaction_repository.dart';
import '../formatters/twd_formatter.dart';
import '../transaction/transaction_form_page.dart';

enum RecordsTypeFilter { all, income, expense }

class RecordsPage extends StatefulWidget {
  const RecordsPage({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.ledger,
    required this.settings,
    required this.categories,
    required this.clock,
    required this.idGenerator,
    required this.initialDate,
    required this.onRecordsChanged,
  });

  final TransactionRepository transactions;
  final AccountRepository accounts;
  final LedgerRepository ledger;
  final SettingsRepository settings;
  final CategoryRepository categories;
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
  late Future<List<_RecordRow>> _recordsFuture;

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
            child: FutureBuilder<List<_RecordRow>>(
              future: _recordsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: Text('載入中'));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('紀錄載入失敗'));
                }
                final rows = snapshot.data!;
                if (rows.isEmpty) {
                  return const Center(child: Text('目前沒有記帳紀錄'));
                }
                return ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final record = row.record;
                    final categoryName = row.categoryDisplayPath;
                    final deleteLabel = record.transaction.note ?? categoryName;
                    final entry = record.entries.single;
                    return ListTile(
                      title: Text(
                        record.transaction.note ??
                            record.transaction.type.label,
                      ),
                      subtitle: Text(
                        '${record.transaction.transactionDate} '
                        '$categoryName · ${row.accountDisplayName}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatCurrency(
                              entry.amountMinor.abs(),
                              entry.currencyCode,
                            ),
                          ),
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

  Future<List<_RecordRow>> _load() async {
    final records = await widget.ledger.list(
      LedgerQuery(
        year: _year,
        month: _month,
        type: switch (_typeFilter) {
          RecordsTypeFilter.all => null,
          RecordsTypeFilter.income => LedgerTransactionType.income,
          RecordsTypeFilter.expense => LedgerTransactionType.expense,
        },
      ),
    );
    return Future.wait(
      records.map((record) async {
        final categoryId = record.transaction.categoryId;
        return _RecordRow(
          record: record,
          categoryDisplayPath: categoryId == null
              ? record.transaction.type.label
              : await widget.categories.displayPathFor(categoryId),
          accountDisplayName: await widget.accounts.displayNameFor(
            record.entries.single.accountId,
          ),
        );
      }),
    );
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

  Future<void> _openEditForm(LedgerRecord record) async {
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

  Future<void> _confirmDelete(LedgerRecord record) async {
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

    final result = await DeleteLedgerRecordUseCase(widget.ledger).execute(
      DeleteLedgerRecordCommand(id: record.transaction.id, confirmed: true),
    );
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

class _RecordRow {
  const _RecordRow({
    required this.record,
    required this.categoryDisplayPath,
    required this.accountDisplayName,
  });

  final LedgerRecord record;
  final String categoryDisplayPath;
  final String accountDisplayName;
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
