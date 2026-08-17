import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../application/security/device_authenticator.dart';
import '../../application/settings/local_data_clearer.dart';
import '../../domain/repository/category_repository.dart';
import '../../domain/repository/account_repository.dart';
import '../../domain/repository/ledger_repository.dart';
import '../../domain/repository/settings_repository.dart';
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
        settings: widget.settings,
        categories: widget.categories,
        clock: widget.clock,
        idGenerator: widget.idGenerator,
        initialDate: widget.initialDate ?? DateTime.now(),
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
