import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../application/security/device_authenticator.dart';
import '../../application/settings/local_data_clearer.dart';
import '../../domain/repository/category_repository.dart';
import '../../domain/repository/account_repository.dart';
import '../../domain/repository/ledger_repository.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/stock_account_repository.dart';
import '../../domain/repository/stock_holding_repository.dart';
import '../../application/stock/execute_stock_trade_use_case.dart';
import '../../application/stock/stock_trade_history_use_case.dart';
import '../assets/assets_page.dart';
import '../../domain/repository/transaction_repository.dart';
import '../overview/overview_page.dart';
import '../records/records_page.dart';
import '../settings/settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.ledger,
    this.stockAccounts,
    this.stockHoldings,
    this.stockTradeUseCase,
    this.stockTradeHistory,
    required this.settings,
    required this.categories,
    required this.clock,
    required this.idGenerator,
    required this.authenticator,
    required this.localDataClearer,
    required this.onResetToFirstUse,
    this.initialDate,
  });

  final TransactionRepository transactions;
  final AccountRepository accounts;
  final LedgerRepository ledger;
  final StockAccountRepository? stockAccounts;
  final StockHoldingRepository? stockHoldings;
  final ExecuteStockTradeUseCase? stockTradeUseCase;
  final StockTradeHistoryUseCase? stockTradeHistory;
  final SettingsRepository settings;
  final CategoryRepository categories;
  final ApplicationClock clock;
  final TransactionIdGenerator idGenerator;
  final DeviceAuthenticator authenticator;
  final LocalDataClearer localDataClearer;
  final VoidCallback onResetToFirstUse;
  final DateTime? initialDate;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;
  var _overviewRefreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      OverviewPage(
        key: ValueKey('overview-$_overviewRefreshKey'),
        transactions: widget.transactions,
        accounts: widget.accounts,
        ledger: widget.ledger,
        stockHoldings: widget.stockHoldings,
        settings: widget.settings,
        categories: widget.categories,
        clock: widget.clock,
        idGenerator: widget.idGenerator,
        initialDate: widget.initialDate ?? DateTime.now(),
      ),
      if (widget.stockAccounts != null && widget.stockHoldings != null)
        AssetsPage(
          accounts: widget.stockAccounts!,
          holdings: widget.stockHoldings!,
          cashAccounts: widget.accounts,
          tradeUseCase: widget.stockTradeUseCase,
          tradeHistory: widget.stockTradeHistory,
          clock: widget.clock,
          idGenerator: widget.idGenerator,
        )
      else
        const Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: _AssetsUnavailableAppBar(),
          ),
          body: Center(child: Text('資產功能尚未設定')),
        ),
      RecordsPage(
        transactions: widget.transactions,
        accounts: widget.accounts,
        ledger: widget.ledger,
        settings: widget.settings,
        categories: widget.categories,
        clock: widget.clock,
        idGenerator: widget.idGenerator,
        initialDate: widget.initialDate ?? DateTime.now(),
        onRecordsChanged: () {
          setState(() {
            _overviewRefreshKey += 1;
          });
        },
      ),
      SettingsPage(
        settings: widget.settings,
        accounts: widget.accounts,
        ledger: widget.ledger,
        categories: widget.categories,
        clock: widget.clock,
        idGenerator: widget.idGenerator,
        authenticator: widget.authenticator,
        localDataClearer: widget.localDataClearer,
        onResetToFirstUse: widget.onResetToFirstUse,
      ),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.pie_chart), label: '總覽'),
          NavigationDestination(
            icon: Semantics(
              label: '開啟資產頁',
              button: true,
              child: Icon(Icons.business_center),
            ),
            label: '資產',
            tooltip: '開啟資產頁',
          ),
          NavigationDestination(
            icon: Semantics(
              label: '開啟紀錄頁',
              button: true,
              child: Icon(Icons.list),
            ),
            label: '紀錄',
            tooltip: '開啟紀錄頁',
          ),
          NavigationDestination(
            icon: Semantics(
              label: '開啟設定頁',
              button: true,
              child: Icon(Icons.settings),
            ),
            label: '設定',
            tooltip: '開啟設定頁',
          ),
        ],
      ),
    );
  }
}

class _AssetsUnavailableAppBar extends StatelessWidget {
  const _AssetsUnavailableAppBar();

  @override
  Widget build(BuildContext context) => AppBar(title: const Text('資產'));
}
