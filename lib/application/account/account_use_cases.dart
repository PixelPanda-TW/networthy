import '../../domain/ledger/ledger_transaction_builder.dart';
import '../../domain/model/domain_validation.dart';
import '../../domain/model/local_date.dart';
import '../../domain/repository/account_repository.dart';
import '../../domain/repository/ledger_repository.dart';
import '../common/application_failure.dart';
import '../common/application_ports.dart';
import 'account_command.dart';

class CreateAccountUseCase {
  const CreateAccountUseCase({
    required AccountRepository accounts,
    required LedgerRepository ledger,
    required ApplicationClock clock,
    required TransactionIdGenerator idGenerator,
  }) : _accounts = accounts,
       _ledger = ledger,
       _clock = clock,
       _idGenerator = idGenerator;

  final AccountRepository _accounts;
  final LedgerRepository _ledger;
  final ApplicationClock _clock;
  final TransactionIdGenerator _idGenerator;

  Future<AccountCommandResult> execute(CreateAccountCommand command) async {
    try {
      final accountId = _idGenerator.generate();
      final openingTransactionId = _idGenerator.generate();
      final openingEntryId = _idGenerator.generate();
      final account = await _accounts.create(
        CreateAccountRequest(
          id: accountId,
          name: command.name,
          currencyCode: command.currencyCode,
          openingBalanceMinor: command.openingBalanceMinor,
        ),
      );
      final now = _clock.nowUtc();
      await _ledger.save(
        LedgerTransactionBuilder.openingBalance(
          transactionId: openingTransactionId,
          entryId: openingEntryId,
          account: account,
          amountMinor: command.openingBalanceMinor,
          transactionDate: _localDateFromUtc(now),
          createdAtUtc: now,
        ),
      );
      return AccountCommandResult.success(account);
    } on AccountRepositoryException catch (exception) {
      return AccountCommandResult.failure(
        ApplicationFailure.validation(exception.safeMessage),
      );
    } on DomainValidationException catch (exception) {
      return AccountCommandResult.failure(
        ApplicationFailure.validation(exception.message),
      );
    } on Exception catch (exception) {
      return AccountCommandResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }
}

class RenameAccountUseCase {
  const RenameAccountUseCase(this._accounts);

  final AccountRepository _accounts;

  Future<AccountCommandResult> execute(RenameAccountCommand command) async {
    try {
      final existing = await _accounts.findById(command.id);
      if (existing == null) {
        return AccountCommandResult.failure(
          ApplicationFailure.validation('帳戶不存在。'),
        );
      }
      if (existing.isArchived) {
        return AccountCommandResult.failure(
          ApplicationFailure.validation('帳戶已封存。'),
        );
      }
      final account = await _accounts.rename(
        id: command.id,
        name: command.name,
      );
      return AccountCommandResult.success(account);
    } on AccountRepositoryException catch (exception) {
      return AccountCommandResult.failure(
        ApplicationFailure.validation(exception.safeMessage),
      );
    } on DomainValidationException catch (exception) {
      return AccountCommandResult.failure(
        ApplicationFailure.validation(exception.message),
      );
    } on Exception catch (exception) {
      return AccountCommandResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }
}

class ArchiveAccountUseCase {
  const ArchiveAccountUseCase(this._accounts);

  final AccountRepository _accounts;

  Future<AccountCommandResult> execute(ArchiveAccountCommand command) async {
    try {
      final existing = await _accounts.findById(command.id);
      if (existing == null) {
        return AccountCommandResult.failure(
          ApplicationFailure.validation('帳戶不存在。'),
        );
      }
      await _accounts.archive(command.id);
      final archived = await _accounts.findById(command.id);
      return AccountCommandResult.success(archived);
    } on AccountRepositoryException catch (exception) {
      return AccountCommandResult.failure(
        ApplicationFailure.validation(exception.safeMessage),
      );
    } on DomainValidationException catch (exception) {
      return AccountCommandResult.failure(
        ApplicationFailure.validation(exception.message),
      );
    } on Exception catch (exception) {
      return AccountCommandResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }
}

LocalDate _localDateFromUtc(DateTime timestamp) {
  return LocalDate(timestamp.year, timestamp.month, timestamp.day);
}
