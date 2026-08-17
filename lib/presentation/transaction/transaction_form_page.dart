import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../application/ledger/ledger_command.dart';
import '../../application/ledger/ledger_use_cases.dart';
import '../../domain/model/account.dart';
import '../../domain/model/category_definition.dart';
import '../../domain/model/local_date.dart';
import '../../domain/model/ledger_transaction.dart';
import '../../domain/model/transaction.dart';
import '../../domain/model/transaction_type.dart';
import '../../domain/repository/account_repository.dart';
import '../../domain/repository/category_repository.dart';
import '../../domain/repository/ledger_repository.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/transaction_repository.dart';

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.ledger,
    required this.settings,
    required this.categories,
    required this.clock,
    required this.idGenerator,
    required this.initialDate,
    this.existing,
  });

  final TransactionRepository transactions;
  final AccountRepository accounts;
  final LedgerRepository ledger;
  final SettingsRepository settings;
  final CategoryRepository categories;
  final ApplicationClock clock;
  final TransactionIdGenerator idGenerator;
  final DateTime initialDate;
  final LedgerRecord? existing;

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
  late Future<List<_AccountOption>> _accountOptionsFuture;
  String? _accountId;
  String? _safeError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = _transactionTypeFor(existing) ?? TransactionType.expense;
    _categoryId = existing?.transaction.categoryId ?? 'expense.food';
    _categoryOptionsFuture = _loadCategoryOptions(_type);
    _accountId = existing?.entries.single.accountId;
    _accountOptionsFuture = _loadAccountOptions();
    if (existing != null) {
      _amountController.text = existing.entries.single.amountMinor
          .abs()
          .toString();
      _noteController.text = existing.transaction.note ?? '';
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
            FutureBuilder<List<_AccountOption>>(
              future: _accountOptionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Text('帳戶載入中');
                }
                if (snapshot.hasError) {
                  return const Text('帳戶載入失敗');
                }
                final options = snapshot.data!;
                if (_accountId == null && options.isNotEmpty) {
                  _accountId = options.first.id;
                }
                final selectedValue =
                    options.any((option) => option.id == _accountId)
                    ? _accountId
                    : null;
                return DropdownButtonFormField<String>(
                  initialValue: selectedValue,
                  decoration: const InputDecoration(labelText: '帳戶'),
                  items: options
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Text(account.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _accountId = value);
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return '請選擇帳戶';
                    }
                    return null;
                  },
                );
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

    final accountId = _accountId;
    if (accountId == null) {
      setState(() {
        _safeError = '請選擇帳戶';
      });
      return;
    }

    final command = LedgerIncomeExpenseCommand(
      type: _type,
      accountId: accountId,
      amountMinor: int.parse(_amountController.text),
      categoryId: _categoryId,
      transactionDate:
          widget.existing?.transaction.transactionDate ??
          LocalDate.fromLocalDateTime(widget.initialDate),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    final result = widget.existing == null
        ? await AddLedgerIncomeExpenseUseCase(
            accounts: widget.accounts,
            ledger: widget.ledger,
            categories: widget.categories,
            clock: widget.clock,
            idGenerator: widget.idGenerator,
          ).execute(command)
        : await EditLedgerIncomeExpenseUseCase(
            accounts: widget.accounts,
            ledger: widget.ledger,
            categories: widget.categories,
            clock: widget.clock,
          ).execute(
            EditLedgerIncomeExpenseCommand(
              id: widget.existing!.transaction.id,
              type: command.type,
              accountId: command.accountId,
              amountMinor: command.amountMinor,
              categoryId: command.categoryId,
              transactionDate: command.transactionDate,
              note: command.note,
            ),
          );

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

  Future<List<_AccountOption>> _loadAccountOptions() async {
    final accounts = await widget.accounts.listActive();
    final selectedArchived = await _selectedArchivedAccount(accounts);
    return [
      for (final account in [...accounts, ?selectedArchived])
        _AccountOption(
          id: account.id,
          label: account.isArchived ? '${account.name}（已封存）' : account.name,
        ),
    ];
  }

  Future<CashAccount?> _selectedArchivedAccount(
    List<CashAccount> activeAccounts,
  ) async {
    final selectedAccountId = widget.existing?.entries.single.accountId;
    if (selectedAccountId == null || selectedAccountId != _accountId) {
      return null;
    }
    final alreadyActive = activeAccounts.any(
      (account) => account.id == selectedAccountId,
    );
    if (alreadyActive) {
      return null;
    }
    final account = await widget.accounts.findById(selectedAccountId);
    if (account == null || !account.isArchived) {
      return null;
    }
    return account;
  }

  Future<EditableCategory?> _selectedArchivedCategory(
    TransactionType type,
    List<EditableCategory> activeCategories,
  ) async {
    if (widget.existing?.transaction.categoryId != _categoryId) {
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

class _AccountOption {
  const _AccountOption({required this.id, required this.label});

  final String id;
  final String label;
}

TransactionType? _transactionTypeFor(LedgerRecord? record) {
  return switch (record?.transaction.type) {
    LedgerTransactionType.income => TransactionType.income,
    LedgerTransactionType.expense => TransactionType.expense,
    LedgerTransactionType.transfer ||
    LedgerTransactionType.openingBalance => null,
    null => null,
  };
}
