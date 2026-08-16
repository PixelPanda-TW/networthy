import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/common/application_failure.dart';
import 'package:networthy/application/common/application_ports.dart';
import 'package:networthy/application/transaction/bookkeeping_flow_controller.dart';
import 'package:networthy/application/transaction/transaction_command.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/domain/repository/settings_repository.dart';
import 'package:networthy/domain/repository/transaction_repository.dart';
import 'package:networthy/domain/summary/monthly_summary.dart';

void main() {
  group('BookkeepingFlowController', () {
    test('refreshes summary immediately after add edit and delete', () async {
      final transactions = MutableTransactionRepository();
      final controller = BookkeepingFlowController(
        transactions: transactions,
        settings: FakeSettingsRepository(),
        clock: IncrementingClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: QueueIdGenerator(['00000000-0000-4000-8000-000000000601']),
      );
      await controller.loadMonth(year: 2026, month: 8);

      await controller.add(
        TransactionCommand(
          type: TransactionType.expense,
          amountMinor: 100,
          categoryId: 'expense.food',
          transactionDate: LocalDate(2026, 8, 16),
        ),
      );
      expect(controller.state.summary.totalExpenseMinor, 100);

      await controller.edit(
        id: '00000000-0000-4000-8000-000000000601',
        command: TransactionCommand(
          type: TransactionType.expense,
          amountMinor: 250,
          categoryId: 'expense.transport',
          transactionDate: LocalDate(2026, 8, 16),
        ),
      );
      expect(controller.state.summary.totalExpenseMinor, 250);

      await controller.delete(
        const DeleteFlowRequest(
          id: '00000000-0000-4000-8000-000000000601',
          confirmed: true,
        ),
      );
      expect(controller.state.summary.totalExpenseMinor, 0);
    });

    test('preserves submitted form command when save fails', () async {
      final command = TransactionCommand(
        type: TransactionType.expense,
        amountMinor: 100,
        categoryId: 'expense.food',
        transactionDate: LocalDate(2026, 8, 16),
      );
      final controller = BookkeepingFlowController(
        transactions: MutableTransactionRepository(throwOnSave: true),
        settings: FakeSettingsRepository(),
        clock: IncrementingClock(DateTime.utc(2026, 8, 16, 1)),
        idGenerator: QueueIdGenerator(['00000000-0000-4000-8000-000000000602']),
      );

      await controller.add(command);

      expect(controller.state.formCommand, same(command));
      expect(
        controller.state.failure?.type,
        ApplicationFailureType.persistence,
      );
    });

    test(
      'distinguishes decryption failure from general save failure',
      () async {
        final controller = BookkeepingFlowController(
          transactions: MutableTransactionRepository(
            throwDecryptionOnSave: true,
          ),
          settings: FakeSettingsRepository(),
          clock: IncrementingClock(DateTime.utc(2026, 8, 16, 1)),
          idGenerator: QueueIdGenerator([
            '00000000-0000-4000-8000-000000000603',
          ]),
        );

        await controller.add(
          TransactionCommand(
            type: TransactionType.expense,
            amountMinor: 100,
            categoryId: 'expense.food',
            transactionDate: LocalDate(2026, 8, 16),
          ),
        );

        expect(
          controller.state.failure?.type,
          ApplicationFailureType.decryption,
        );
      },
    );
  });
}

class IncrementingClock implements ApplicationClock {
  IncrementingClock(this._next);

  DateTime _next;

  @override
  DateTime nowUtc() {
    final current = _next;
    _next = _next.add(const Duration(minutes: 1));
    return current;
  }
}

class QueueIdGenerator implements TransactionIdGenerator {
  QueueIdGenerator(this._ids);

  final List<String> _ids;

  @override
  String generate() => _ids.removeAt(0);
}

class FakeSettingsRepository implements SettingsRepository {
  AppSettings saved = const AppSettings.defaults();

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings settings) async {
    saved = settings;
  }
}

class MutableTransactionRepository implements TransactionRepository {
  MutableTransactionRepository({
    this.throwOnSave = false,
    this.throwDecryptionOnSave = false,
  });

  final bool throwOnSave;
  final bool throwDecryptionOnSave;
  final Map<String, BookkeepingTransaction> values =
      <String, BookkeepingTransaction>{};

  @override
  Future<void> delete(String id) async {
    values.remove(id);
  }

  @override
  Future<BookkeepingTransaction?> findById(String id) async => values[id];

  @override
  Future<List<BookkeepingTransaction>> latest({required int limit}) async {
    return values.values.take(limit).toList(growable: false);
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
    if (throwDecryptionOnSave) {
      throw const ApplicationDecryptionException();
    }
    if (throwOnSave) {
      throw Exception('write failed');
    }
    values[transaction.id] = transaction;
  }
}
