import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../application/transaction/add_transaction_use_case.dart';
import '../../application/transaction/edit_transaction_use_case.dart';
import '../../application/transaction/transaction_command.dart';
import '../../domain/model/category.dart';
import '../../domain/model/local_date.dart';
import '../../domain/model/transaction.dart';
import '../../domain/model/transaction_type.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/transaction_repository.dart';

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({
    super.key,
    required this.transactions,
    required this.settings,
    required this.clock,
    required this.idGenerator,
    required this.initialDate,
    this.existing,
  });

  final TransactionRepository transactions;
  final SettingsRepository settings;
  final ApplicationClock clock;
  final TransactionIdGenerator idGenerator;
  final DateTime initialDate;
  final BookkeepingTransaction? existing;

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocusNode = FocusNode();
  late TransactionType _type;
  late String _categoryId;
  String? _safeError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? TransactionType.expense;
    _categoryId = existing?.categoryId ?? 'expense.food';
    if (existing != null) {
      _amountController.text = existing.amountMinor.toString();
      _noteController.text = existing.note ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _amountFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? '新增記帳' : '編輯記帳')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('支出'),
                ),
                ButtonSegment(value: TransactionType.income, label: Text('收入')),
              ],
              selected: {_type},
              onSelectionChanged: (values) {
                setState(() {
                  _type = values.single;
                  _categoryId = _type == TransactionType.expense
                      ? 'expense.food'
                      : 'income.salary';
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('amount-field'),
              controller: _amountController,
              focusNode: _amountFocusNode,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '金額',
                prefixText: 'NT\$',
              ),
              validator: (value) {
                final amount = int.tryParse(value ?? '');
                if (amount == null || amount <= 0) {
                  return '請輸入大於 0 的整數金額';
                }
                if (amount > BookkeepingTransaction.maxAmountMinor) {
                  return '金額超過上限';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: '分類'),
              items: _categoryIdsForType(_type)
                  .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _categoryId = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('note-field'),
              controller: _noteController,
              decoration: const InputDecoration(labelText: '備註'),
              maxLength: BookkeepingTransaction.maxNoteCodePoints,
            ),
            if (_safeError != null) ...[
              const SizedBox(height: 8),
              Text(
                _safeError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('儲存')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final command = TransactionCommand(
      type: _type,
      amountMinor: int.parse(_amountController.text),
      categoryId: _categoryId,
      transactionDate:
          widget.existing?.transactionDate ??
          LocalDate.fromLocalDateTime(widget.initialDate),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    final result = widget.existing == null
        ? await AddTransactionUseCase(
            transactions: widget.transactions,
            settings: widget.settings,
            clock: widget.clock,
            idGenerator: widget.idGenerator,
          ).execute(command)
        : await EditTransactionUseCase(
            transactions: widget.transactions,
            settings: widget.settings,
            clock: widget.clock,
          ).execute(id: widget.existing!.id, command: command);

    if (!mounted) {
      return;
    }
    if (result.failure != null) {
      setState(() {
        _safeError = '本機資料儲存失敗，請稍後再試。';
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  List<String> _categoryIdsForType(TransactionType type) {
    final categories = type == TransactionType.expense
        ? CategoryCatalog.expenseCategories
        : CategoryCatalog.incomeCategories;
    return categories.map((category) => category.id).toList(growable: false);
  }
}
