import '../../domain/model/app_settings.dart';
import '../../domain/model/transaction.dart';
import '../../domain/model/transaction_type.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/transaction_repository.dart';
import '../common/application_failure.dart';
import '../common/application_ports.dart';
import 'transaction_command.dart';

class EditTransactionUseCase {
  const EditTransactionUseCase({
    required TransactionRepository transactions,
    required SettingsRepository settings,
    required ApplicationClock clock,
  }) : _transactions = transactions,
       _settings = settings,
       _clock = clock;

  final TransactionRepository _transactions;
  final SettingsRepository _settings;
  final ApplicationClock _clock;

  Future<TransactionCommandResult> execute({
    required String id,
    required TransactionCommand command,
  }) async {
    try {
      final existing = await _transactions.findById(id);
      if (existing == null) {
        return TransactionCommandResult.failure(
          ApplicationFailure.validation('Transaction does not exist.'),
        );
      }

      final transaction = BookkeepingTransaction.create(
        id: id,
        type: command.type,
        amountMinor: command.amountMinor,
        categoryId: command.categoryId,
        transactionDate: command.transactionDate,
        note: command.note,
        createdAtUtc: existing.createdAtUtc,
        updatedAtUtc: _clock.nowUtc(),
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
