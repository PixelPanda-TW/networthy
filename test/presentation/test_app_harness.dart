import 'package:networthy/application/common/application_ports.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/repository/settings_repository.dart';
import 'package:networthy/domain/repository/transaction_repository.dart';
import 'package:networthy/domain/summary/monthly_summary.dart';

class TestClock implements ApplicationClock {
  TestClock(this._next);

  DateTime _next;

  @override
  DateTime nowUtc() {
    final current = _next;
    _next = _next.add(const Duration(minutes: 1));
    return current;
  }
}

class TestIdGenerator implements TransactionIdGenerator {
  TestIdGenerator(this._ids);

  final List<String> _ids;

  @override
  String generate() {
    return _ids.removeAt(0);
  }
}

class TestSettingsRepository implements SettingsRepository {
  TestSettingsRepository([AppSettings? initial])
    : value = initial ?? const AppSettings.defaults();

  AppSettings value;

  @override
  Future<AppSettings> load() async => value;

  @override
  Future<void> save(AppSettings settings) async {
    value = settings;
  }
}

class TestTransactionRepository implements TransactionRepository {
  TestTransactionRepository({this.throwOnSave = false});

  final bool throwOnSave;
  final Map<String, BookkeepingTransaction> values =
      <String, BookkeepingTransaction>{};

  @override
  Future<void> delete(String id) async {
    values.remove(id);
  }

  @override
  Future<BookkeepingTransaction?> findById(String id) async {
    return values[id];
  }

  @override
  Future<List<BookkeepingTransaction>> latest({required int limit}) async {
    final rows = values.values.toList()
      ..sort((a, b) {
        final dateComparison = b.transactionDate.compareTo(a.transactionDate);
        if (dateComparison != 0) {
          return dateComparison;
        }
        return b.createdAtUtc.compareTo(a.createdAtUtc);
      });
    return rows.take(limit).toList(growable: false);
  }

  @override
  Future<List<BookkeepingTransaction>> list(TransactionQuery query) async {
    return values.values
        .where((transaction) {
          final matchesYear =
              query.year == null ||
              transaction.transactionDate.year == query.year;
          final matchesMonth =
              query.month == null ||
              transaction.transactionDate.month == query.month;
          final matchesType =
              query.type == null || transaction.type == query.type;
          return matchesYear && matchesMonth && matchesType;
        })
        .toList(growable: false);
  }

  @override
  Future<MonthlySummary> monthlySummary({
    required int year,
    required int month,
  }) async {
    return MonthlySummary.calculate(
      transactions: values.values,
      year: year,
      month: month,
    );
  }

  @override
  Future<void> save(BookkeepingTransaction transaction) async {
    if (throwOnSave) {
      throw Exception('save failed');
    }
    values[transaction.id] = transaction;
  }
}
