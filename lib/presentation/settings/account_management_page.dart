import 'package:flutter/material.dart';

import '../../application/account/account_command.dart';
import '../../application/account/account_use_cases.dart';
import '../../application/common/application_ports.dart';
import '../../domain/model/account.dart';
import '../../domain/model/currency_code.dart';
import '../../domain/repository/account_repository.dart';
import '../../domain/repository/ledger_repository.dart';
import '../formatters/twd_formatter.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({
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
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  late Future<_AccountManagementData> _dataFuture;
  String? _safeMessage;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('帳戶管理')),
      body: FutureBuilder<_AccountManagementData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Text('載入中'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('帳戶載入失敗'));
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.tonal(onPressed: _create, child: const Text('新增帳戶')),
              const SizedBox(height: 16),
              if (data.accounts.isEmpty)
                const Text('目前沒有帳戶')
              else
                for (final account in data.accounts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(account.name),
                    subtitle: Text(account.currencyCode.wireValue),
                    trailing: Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          formatCurrency(
                            data.balances[account.id] ?? 0,
                            account.currencyCode,
                          ),
                        ),
                        IconButton(
                          tooltip: '重新命名 ${account.name}',
                          onPressed: () => _rename(account),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          tooltip: '封存 ${account.name}',
                          onPressed: () => _confirmArchive(account),
                          icon: const Icon(Icons.archive_outlined),
                        ),
                      ],
                    ),
                  ),
              if (_safeMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _safeMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<_AccountManagementData> _load() async {
    final accounts = await widget.accounts.listActive();
    final balances = await widget.ledger.accountBalances();
    return _AccountManagementData(
      accounts: accounts,
      balances: {
        for (final balance in balances) balance.accountId: balance.balanceMinor,
      },
    );
  }

  Future<void> _create() async {
    final command = await showDialog<CreateAccountCommand>(
      context: context,
      builder: (context) => const _AccountDialog(title: '新增帳戶'),
    );
    if (command == null) {
      return;
    }
    final result = await CreateAccountUseCase(
      accounts: widget.accounts,
      ledger: widget.ledger,
      clock: widget.clock,
      idGenerator: widget.idGenerator,
    ).execute(command);
    _handleResult(result.failure?.safeMessage);
  }

  Future<void> _rename(CashAccount account) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          _AccountNameDialog(title: '重新命名帳戶', initialName: account.name),
    );
    if (name == null) {
      return;
    }
    final result = await RenameAccountUseCase(
      widget.accounts,
    ).execute(RenameAccountCommand(id: account.id, name: name));
    _handleResult(result.failure?.safeMessage);
  }

  Future<void> _confirmArchive(CashAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('封存帳戶'),
        content: Text('確定要封存「${account.name}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('封存'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final result = await ArchiveAccountUseCase(
      widget.accounts,
    ).execute(ArchiveAccountCommand(id: account.id));
    _handleResult(result.failure?.safeMessage);
  }

  void _handleResult(String? failureMessage) {
    if (!mounted) {
      return;
    }
    setState(() {
      _safeMessage = failureMessage;
      _dataFuture = _load();
    });
  }
}

class _AccountDialog extends StatefulWidget {
  const _AccountDialog({required this.title});

  final String title;

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _openingBalanceController = TextEditingController(text: '0');
  var _currencyCode = CurrencyCode.twd;

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('account-name-field'),
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '帳戶名稱'),
              validator: _validateName,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CurrencyCode>(
              initialValue: _currencyCode,
              decoration: const InputDecoration(labelText: '幣別'),
              items: CurrencyCode.values
                  .map(
                    (currencyCode) => DropdownMenuItem(
                      value: currencyCode,
                      child: Text(currencyCode.wireValue),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _currencyCode = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('opening-balance-field'),
              controller: _openingBalanceController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(labelText: '初始餘額'),
              validator: (value) {
                if (int.tryParse(value ?? '') == null) {
                  return '請輸入整數金額';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              CreateAccountCommand(
                name: _nameController.text.trim(),
                currencyCode: _currencyCode,
                openingBalanceMinor: int.parse(_openingBalanceController.text),
              ),
            );
          },
          child: const Text('儲存'),
        ),
      ],
    );
  }
}

class _AccountNameDialog extends StatefulWidget {
  const _AccountNameDialog({required this.title, required this.initialName});

  final String title;
  final String initialName;

  @override
  State<_AccountNameDialog> createState() => _AccountNameDialogState();
}

class _AccountNameDialogState extends State<_AccountNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('account-name-field'),
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '帳戶名稱'),
          validator: _validateName,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: const Text('儲存'),
        ),
      ],
    );
  }
}

String? _validateName(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) {
    return '請輸入帳戶名稱';
  }
  if (normalized.runes.length > CashAccount.maxNameCodePoints) {
    return '帳戶名稱不可超過 30 個字';
  }
  return null;
}

class _AccountManagementData {
  const _AccountManagementData({
    required this.accounts,
    required this.balances,
  });

  final List<CashAccount> accounts;
  final Map<String, int> balances;
}
