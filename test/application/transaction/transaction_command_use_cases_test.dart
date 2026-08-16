import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/common/application_ports.dart';
import 'package:networthy/application/transaction/add_transaction_use_case.dart';
import 'package:networthy/application/transaction/edit_transaction_use_case.dart';
import 'package:networthy/application/transaction/transaction_command.dart';
import 'package:networthy/domain/model/app_settings.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/domain/repository/settings_repository.dart';
import 'package:networthy/domain/repository/transaction_repository.dart';
import 'package:networthy/domain/summary/monthly_summary.dart';

void main() {
  group('transaction command use cases', () {
    test(
      'add saves a new expense and updates only last expense category',
      () async {
        final transactions = FakeTransactionRepository();
        final settings = FakeSettingsRepository();

        final result =
            await AddTransactionUseCase(
              transactions: transactions,
              settings: settings,
              clock: FixedClock(DateTime.utc(2026, 8, 16, 2)),
              idGenerator: FixedIdGenerator(
                '00000000-0000-4000-8000-000000000401',
              ),
            ).execute(
              TransactionCommand(
                type: TransactionType.expense,
                amountMinor: 1200,
                categoryId: 'expense.food',
                transactionDate: LocalDate(2026, 8, 16),
                note: '午餐',
              ),
            );

        expect(result.failure, isNull);
        expect(
          transactions.saved.single.id,
          '00000000-0000-4000-8000-000000000401',
        );
        expect(
          transactions.saved.single.createdAtUtc,
          DateTime.utc(2026, 8, 16, 2),
        );
        expect(settings.saved.lastExpenseCategoryId, 'expense.food');
        expect(settings.saved.lastIncomeCategoryId, isNull);
      },
    );

    test(
      'add saves a new income and updates only last income category',
      () async {
        final settings = FakeSettingsRepository(
          initial: const AppSettings(
            onboardingCompleted: false,
            biometricLockEnabled: false,
            currencyCode: 'TWD',
            lastExpenseCategoryId: 'expense.food',
            lastIncomeCategoryId: null,
          ),
        );

        await AddTransactionUseCase(
          transactions: FakeTransactionRepository(),
          settings: settings,
          clock: FixedClock(DateTime.utc(2026, 8, 16, 2)),
          idGenerator: FixedIdGenerator('00000000-0000-4000-8000-000000000402'),
        ).execute(
          TransactionCommand(
            type: TransactionType.income,
            amountMinor: 50000,
            categoryId: 'income.salary',
            transactionDate: LocalDate(2026, 8, 16),
          ),
        );

        expect(settings.saved.lastExpenseCategoryId, 'expense.food');
        expect(settings.saved.lastIncomeCategoryId, 'income.salary');
      },
    );

    test(
      'edit preserves created time and updates transaction fields',
      () async {
        final existing = BookkeepingTransaction.create(
          id: '00000000-0000-4000-8000-000000000403',
          type: TransactionType.expense,
          amountMinor: 100,
          categoryId: 'expense.food',
          transactionDate: LocalDate(2026, 8, 1),
          createdAtUtc: DateTime.utc(2026, 8, 1, 1),
          updatedAtUtc: DateTime.utc(2026, 8, 1, 1),
        );
        final transactions = FakeTransactionRepository(existing: existing);

        final result =
            await EditTransactionUseCase(
              transactions: transactions,
              settings: FakeSettingsRepository(),
              clock: FixedClock(DateTime.utc(2026, 8, 20, 3)),
            ).execute(
              id: existing.id,
              command: TransactionCommand(
                type: TransactionType.expense,
                amountMinor: 990,
                categoryId: 'expense.transport',
                transactionDate: LocalDate(2026, 8, 20),
              ),
            );

        expect(result.failure, isNull);
        expect(
          transactions.saved.single.createdAtUtc,
          DateTime.utc(2026, 8, 1, 1),
        );
        expect(
          transactions.saved.single.updatedAtUtc,
          DateTime.utc(2026, 8, 20, 3),
        );
        expect(transactions.saved.single.amountMinor, 990);
        expect(transactions.saved.single.categoryId, 'expense.transport');
      },
    );
  });
}

class FixedClock implements ApplicationClock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value;
}

class FixedIdGenerator implements TransactionIdGenerator {
  const FixedIdGenerator(this.value);

  final String value;

  @override
  String generate() => value;
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({AppSettings? initial})
    : saved = initial ?? const AppSettings.defaults();

  AppSettings saved;

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings settings) async {
    saved = settings;
  }
}

class FakeTransactionRepository implements TransactionRepository {
  FakeTransactionRepository({BookkeepingTransaction? existing})
    : _existing = existing;

  final BookkeepingTransaction? _existing;
  final List<BookkeepingTransaction> saved = <BookkeepingTransaction>[];

  @override
  Future<void> delete(String id) async {}

  @override
  Future<BookkeepingTransaction?> findById(String id) async => _existing;

  @override
  Future<List<BookkeepingTransaction>> latest({required int limit}) async =>
      saved;

  @override
  Future<List<BookkeepingTransaction>> list(TransactionQuery query) async =>
      saved;

  @override
  Future<MonthlySummary> monthlySummary({
    required int year,
    required int month,
  }) async {
    return MonthlySummary.calculate(
      transactions: saved,
      year: year,
      month: month,
    );
  }

  @override
  Future<void> save(BookkeepingTransaction transaction) async {
    saved.add(transaction);
  }
}
