import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../application/stock/stock_account_command.dart';
import '../../application/stock/stock_account_use_cases.dart';
import '../../application/stock/stock_holding_command.dart';
import '../../application/stock/stock_holding_use_cases.dart';
import '../../domain/model/stock_account.dart';
import '../../domain/model/stock_holding.dart';
import '../../domain/repository/stock_account_repository.dart';
import '../../domain/repository/stock_holding_repository.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({
    super.key,
    required this.accounts,
    required this.holdings,
    required this.clock,
    required this.idGenerator,
  });

  final StockAccountRepository accounts;
  final StockHoldingRepository holdings;
  final ApplicationClock clock;
  final TransactionIdGenerator idGenerator;

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  List<StockAccount> _accounts = const [];
  final Map<String, List<StockHolding>> _holdings =
      <String, List<StockHolding>>{};
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final accounts = await widget.accounts.listActive();
    final holdings = <String, List<StockHolding>>{};
    for (final account in accounts) {
      holdings[account.id] = await widget.holdings.listActiveByAccount(
        account.id,
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _accounts = accounts;
      _holdings
        ..clear()
        ..addAll(holdings);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('資產'),
        actions: [
          IconButton(
            onPressed: () => _showAccountDialog(),
            tooltip: '新增股票帳戶',
            icon: const Icon(Icons.add_business),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
          ? const Center(child: Text('目前沒有股票帳戶'))
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _accounts.map(_accountCard).toList(),
              ),
            ),
    );
  }

  Widget _accountCard(StockAccount account) {
    final rows = _holdings[account.id] ?? const <StockHolding>[];
    return Card(
      key: ValueKey('stock-account-${account.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name, style: const TextStyle(fontSize: 18)),
                      Text(
                        '${account.mode.displayName} · ${account.currencyCode.wireValue}',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showAccountDialog(account: account),
                  tooltip: '重新命名 ${account.name}',
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () => _archiveAccount(account),
                  tooltip: '封存 ${account.name}',
                  icon: const Icon(Icons.archive_outlined),
                ),
              ],
            ),
            const Divider(),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('目前沒有持倉'),
              )
            else
              ...rows.map(_holdingRow),
            Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: '新增持倉 ${account.mode.displayName}',
                child: TextButton.icon(
                  onPressed: () => _showHoldingDialog(account),
                  icon: const Icon(Icons.add),
                  label: const Text('新增持倉'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _holdingRow(StockHolding holding) {
    final detail = holding.trackingMode == StockHoldingTrackingMode.valuation
        ? '${holding.quantityDisplay} 股 · 市值 ${holding.marketValueMinor}'
        : '本金 ${holding.principalMinor}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${holding.symbol} · ${holding.name}'),
      subtitle: Text(detail),
      trailing: IconButton(
        onPressed: () => _archiveHolding(holding),
        tooltip: '封存 ${holding.symbol}',
        icon: const Icon(Icons.archive_outlined),
      ),
    );
  }

  Future<void> _showAccountDialog({StockAccount? account}) async {
    final nameController = TextEditingController(text: account?.name ?? '');
    var mode = account?.mode ?? StockAccountMode.taiwanStock;
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(account == null ? '新增股票帳戶' : '重新命名股票帳戶'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const Key('stock-account-name-field'),
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: '帳戶名稱'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? '請輸入帳戶名稱'
                        : null,
                  ),
                  if (account == null)
                    DropdownButtonFormField<StockAccountMode>(
                      initialValue: mode,
                      decoration: const InputDecoration(labelText: '帳戶模式'),
                      items: StockAccountMode.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => mode = value);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                final result = account == null
                    ? await CreateStockAccountUseCase(
                        accounts: widget.accounts,
                        clock: widget.clock,
                        idGenerator: widget.idGenerator,
                      ).execute(
                        CreateStockAccountCommand(
                          name: nameController.text,
                          mode: mode,
                        ),
                      )
                    : await RenameStockAccountUseCase(widget.accounts).execute(
                        RenameStockAccountCommand(
                          id: account.id,
                          name: nameController.text,
                        ),
                      );
                if (!context.mounted) {
                  return;
                }
                if (result.failure != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.failure!.safeMessage)),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('儲存'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      await _reload();
    }
  }

  Future<void> _showHoldingDialog(StockAccount account) async {
    final symbolController = TextEditingController();
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final averageCostController = TextEditingController();
    final currentPriceController = TextEditingController();
    final principalController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新增持倉 · ${account.name}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _textField(symbolController, '股票代號', 'stock-symbol-field'),
                _textField(nameController, '股票名稱', 'stock-name-field'),
                if (account.mode == StockAccountMode.taiwanStock) ...[
                  _textField(
                    quantityController,
                    '數量（微股）',
                    'stock-quantity-field',
                  ),
                  _textField(
                    averageCostController,
                    '平均成本（分）',
                    'stock-average-cost-field',
                  ),
                  _textField(
                    currentPriceController,
                    '現價（分）',
                    'stock-current-price-field',
                  ),
                ] else
                  _textField(
                    principalController,
                    '本金（最小貨幣單位）',
                    'stock-principal-field',
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }
              final result = account.mode == StockAccountMode.taiwanStock
                  ? await SaveValuationStockHoldingUseCase(
                      accounts: widget.accounts,
                      holdings: widget.holdings,
                      clock: widget.clock,
                      idGenerator: widget.idGenerator,
                    ).execute(
                      SaveValuationStockHoldingCommand(
                        accountId: account.id,
                        symbol: symbolController.text,
                        name: nameController.text,
                        quantityMicro: int.parse(quantityController.text),
                        averageCostMinor: int.parse(averageCostController.text),
                        currentPriceMinor: int.parse(
                          currentPriceController.text,
                        ),
                      ),
                    )
                  : await SavePrincipalStockHoldingUseCase(
                      accounts: widget.accounts,
                      holdings: widget.holdings,
                      clock: widget.clock,
                      idGenerator: widget.idGenerator,
                    ).execute(
                      SavePrincipalStockHoldingCommand(
                        accountId: account.id,
                        symbol: symbolController.text,
                        name: nameController.text,
                        principalMinor: int.parse(principalController.text),
                      ),
                    );
              if (!context.mounted) {
                return;
              }
              if (result.failure != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.failure!.safeMessage)),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    if (saved == true) {
      await _reload();
    }
  }

  TextFormField _textField(
    TextEditingController controller,
    String label,
    String keyValue,
  ) {
    return TextFormField(
      key: Key(keyValue),
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '請輸入$label' : null,
    );
  }

  Future<void> _archiveAccount(StockAccount account) async {
    final result = await ArchiveStockAccountUseCase(
      widget.accounts,
    ).execute(ArchiveStockAccountCommand(id: account.id));
    if (result.failure != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.failure!.safeMessage)));
      return;
    }
    await _reload();
  }

  Future<void> _archiveHolding(StockHolding holding) async {
    final result = await ArchiveStockHoldingUseCase(
      widget.holdings,
    ).execute(ArchiveStockHoldingCommand(id: holding.id));
    if (result.failure != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.failure!.safeMessage)));
      return;
    }
    await _reload();
  }
}
