import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../application/transaction/add_transaction_use_case.dart';
import '../../application/transaction/edit_transaction_use_case.dart';
import '../../application/transaction/transaction_command.dart';
import '../../domain/model/category_definition.dart';
import '../../domain/model/local_date.dart';
import '../../domain/model/transaction.dart';
import '../../domain/model/transaction_type.dart';
import '../../domain/repository/category_repository.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/transaction_repository.dart';

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({
    super.key,
    required this.transactions,
    required this.settings,
    required this.categories,
    required this.clock,
    required this.idGenerator,
    required this.initialDate,
    this.existing,
  });

  final TransactionRepository transactions;
  final SettingsRepository settings;
  final CategoryRepository categories;
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
  late Future<List<_CategoryOption>> _categoryOptionsFuture;
  String? _safeError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? TransactionType.expense;
    _categoryId = existing?.categoryId ?? 'expense.food';
    _categoryOptionsFuture = _loadCategoryOptions(_type);
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
                  _categoryOptionsFuture = _loadCategoryOptions(_type);
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
            FutureBuilder<List<_CategoryOption>>(
              future: _categoryOptionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Text('分類載入中');
                }
                if (snapshot.hasError) {
                  return const Text('分類載入失敗');
                }
                final options = snapshot.data!;
                final selectedValue =
                    options.any((option) => option.id == _categoryId)
                    ? _categoryId
                    : null;
                return DropdownButtonFormField<String>(
                  initialValue: selectedValue,
                  decoration: const InputDecoration(labelText: '分類'),
                  items: options
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _categoryId = value);
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return '請選擇分類';
                    }
                    return null;
                  },
                );
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
            categories: widget.categories,
            clock: widget.clock,
            idGenerator: widget.idGenerator,
          ).execute(command)
        : await EditTransactionUseCase(
            transactions: widget.transactions,
            settings: widget.settings,
            categories: widget.categories,
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

  Future<List<_CategoryOption>> _loadCategoryOptions(
    TransactionType type,
  ) async {
    final categories = await widget.categories.listActive(type);
    final selectedCategory = await _selectedArchivedCategory(type, categories);
    final categoryOptions = [...categories, ?selectedCategory];
    return Future.wait(
      categoryOptions.map((category) async {
        final displayPath = await widget.categories.displayPathFor(category.id);
        return _CategoryOption(
          id: category.id,
          label: category.isArchived ? '$displayPath（已封存）' : displayPath,
        );
      }),
    );
  }

  Future<EditableCategory?> _selectedArchivedCategory(
    TransactionType type,
    List<EditableCategory> activeCategories,
  ) async {
    if (widget.existing?.categoryId != _categoryId) {
      return null;
    }
    final alreadyActive = activeCategories.any(
      (category) => category.id == _categoryId,
    );
    if (alreadyActive) {
      return null;
    }
    final category = await widget.categories.findById(_categoryId);
    if (category == null || category.type != type || !category.isArchived) {
      return null;
    }
    return category;
  }
}

class _CategoryOption {
  const _CategoryOption({required this.id, required this.label});

  final String id;
  final String label;
}
