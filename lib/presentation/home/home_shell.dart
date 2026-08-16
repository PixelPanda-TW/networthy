import 'package:flutter/material.dart';

import '../../application/common/application_ports.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/transaction_repository.dart';
import '../overview/overview_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.transactions,
    required this.settings,
    required this.clock,
    required this.idGenerator,
    this.initialDate,
  });

  final TransactionRepository transactions;
  final SettingsRepository settings;
  final ApplicationClock clock;
  final TransactionIdGenerator idGenerator;
  final DateTime? initialDate;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      OverviewPage(
        transactions: widget.transactions,
        settings: widget.settings,
        clock: widget.clock,
        idGenerator: widget.idGenerator,
        initialDate: widget.initialDate ?? DateTime.now(),
      ),
      const Center(child: Text('紀錄')),
      const Center(child: Text('設定')),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pie_chart), label: '總覽'),
          NavigationDestination(icon: Icon(Icons.list), label: '紀錄'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
