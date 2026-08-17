import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../application/ledger/ledger_command.dart';
import '../../application/ledger/ledger_use_cases.dart';
import '../../domain/model/account.dart';
import '../../domain/model/local_date.dart';
import '../../domain/model/transaction.dart';
import '../../domain/repository/account_repository.dart';
import '../../domain/repository/ledger_repository.dart';

class TransferFormPage extends StatefulWidget {
  const TransferFormPage({
    super.key,
    required this.accounts,
    required this.ledger,
    required this.clock,
    required this.idGenerator,
  });

  final AccountRepository accounts;
  final LedgerRepository ledger;
  final ApplicationClock clock;
  final TransactionIdGenerator idGenerator;

  @override
  State<TransferFormPage> createState() => _TransferFormPageState();
}

class _TransferFormPageState extends State<TransferFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late Future<List<CashAccount>> _accountsFuture;
  String? _sourceAccountId;
  String? _targetAccountId;
  String? _safeError;

  @override
  void initState() {
    super.initState();
    _accountsFuture = widget.accounts.listActive();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增轉帳')),
      body: FutureBuilder<List<CashAccount>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Text('帳戶載入中'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('帳戶載入失敗'));
          }
          final accounts = snapshot.data!;
          _applyDefaultSelection(accounts);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AccountDropdown(
                  label: '來源帳戶',
                  value: _sourceAccountId,
                  accounts: accounts,
                  onChanged: (value) =>
                      setState(() => _sourceAccountId = value),
                ),
                const SizedBox(height: 16),
                _AccountDropdown(
                  label: '目標帳戶',
                  value: _targetAccountId,
                  accounts: accounts,
                  onChanged: (value) =>
                      setState(() => _targetAccountId = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('transfer-amount-field'),
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '金額'),
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
                TextFormField(
                  key: const Key('transfer-note-field'),
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: '備註'),
                  maxLength: BookkeepingTransaction.maxNoteCodePoints,
                ),
                if (_safeError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _safeError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _save(accounts),
                  child: const Text('儲存'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _applyDefaultSelection(List<CashAccount> accounts) {
    if (accounts.isEmpty) {
      return;
    }
    _sourceAccountId ??= accounts.first.id;
    _targetAccountId ??= accounts.length > 1
        ? accounts[1].id
        : accounts.first.id;
  }

  Future<void> _save(List<CashAccount> accounts) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final source = accounts
        .where((account) => account.id == _sourceAccountId)
        .firstOrNull;
    final target = accounts
        .where((account) => account.id == _targetAccountId)
        .firstOrNull;
    if (source == null || target == null) {
      setState(() => _safeError = '請選擇帳戶');
      return;
    }
    if (source.id == target.id) {
      setState(() => _safeError = '來源與目標帳戶不能相同');
      return;
    }
    if (source.currencyCode != target.currencyCode) {
      setState(() => _safeError = 'v0.3.0 僅支援同幣別轉帳');
      return;
    }

    final result =
        await AddTransferUseCase(
          accounts: widget.accounts,
          ledger: widget.ledger,
          clock: widget.clock,
          idGenerator: widget.idGenerator,
        ).execute(
          TransferCommand(
            sourceAccountId: source.id,
            targetAccountId: target.id,
            amountMinor: int.parse(_amountController.text),
            transactionDate: _todayFromClock(),
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          ),
        );
    if (!mounted) {
      return;
    }
    if (result.failure != null) {
      setState(() => _safeError = result.failure!.safeMessage);
      return;
    }
    Navigator.of(context).pop(true);
  }

  LocalDate _todayFromClock() {
    final now = widget.clock.nowUtc();
    return LocalDate(now.year, now.month, now.day);
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.label,
    required this.value,
    required this.accounts,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<CashAccount> accounts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: accounts
          .map(
            (account) =>
                DropdownMenuItem(value: account.id, child: Text(account.name)),
          )
          .toList(growable: false),
      onChanged: onChanged,
      validator: (value) => value == null ? '請選擇帳戶' : null,
    );
  }
}
