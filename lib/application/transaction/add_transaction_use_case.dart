import '../../domain/model/app_settings.dart';
import '../../domain/model/transaction.dart';
import '../../domain/model/transaction_type.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/transaction_repository.dart';
import '../common/application_failure.dart';
import '../common/application_ports.dart';
import 'transaction_command.dart';

class AddTransactionUseCase {
  const AddTransactionUseCase({
    required TransactionRepository transactions,
    required SettingsRepository settings,
    required ApplicationClock clock,
    required TransactionIdGenerator idGenerator,
  }) : _transactions = transactions,
       _settings = settings,
       _clock = clock,
       _idGenerator = idGenerator;

  final TransactionRepository _transactions;
  final SettingsRepository _settings;
  final ApplicationClock _clock;
  final TransactionIdGenerator _idGenerator;

  Future<TransactionCommandResult> execute(TransactionCommand command) async {
    try {
      final now = _clock.nowUtc();
      final transaction = BookkeepingTransaction.create(
        id: _idGenerator.generate(),
        type: command.type,
        amountMinor: command.amountMinor,
        categoryId: command.categoryId,
        transactionDate: command.transactionDate,
        note: command.note,
        createdAtUtc: now,
        updatedAtUtc: now,
      );
      await _transactions.save(transaction);
      await _saveLastCategory(command);
      return TransactionCommandResult.success(transaction);
    } on Exception catch (exception) {
      return TransactionCommandResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }

  Future<void> _saveLastCategory(TransactionCommand command) async {
    final current = await _settings.load();
    await _settings.save(
      AppSettings(
        onboardingCompleted: current.onboardingCompleted,
        biometricLockEnabled: current.biometricLockEnabled,
        currencyCode: current.currencyCode,
        lastExpenseCategoryId: command.type == TransactionType.expense
            ? command.categoryId
            : current.lastExpenseCategoryId,
        lastIncomeCategoryId: command.type == TransactionType.income
            ? command.categoryId
            : current.lastIncomeCategoryId,
      ),
    );
  }
}
