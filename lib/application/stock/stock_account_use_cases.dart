import '../../domain/model/domain_validation.dart';
import '../../domain/repository/stock_account_repository.dart';
import '../common/application_failure.dart';
import '../common/application_ports.dart';
import 'stock_account_command.dart';

class CreateStockAccountUseCase {
  const CreateStockAccountUseCase({
    required StockAccountRepository accounts,
    required ApplicationClock clock,
    required TransactionIdGenerator idGenerator,
  }) : _accounts = accounts,
       _clock = clock,
       _idGenerator = idGenerator;

  final StockAccountRepository _accounts;
  final ApplicationClock _clock;
  final TransactionIdGenerator _idGenerator;

  Future<StockAccountCommandResult> execute(
    CreateStockAccountCommand command,
  ) async {
    try {
      final id = _idGenerator.generate();
      _clock.nowUtc();
      final account = await _accounts.create(
        CreateStockAccountRequest(
          id: id,
          name: command.name,
          mode: command.mode,
        ),
      );
      return StockAccountCommandResult.success(account);
    } on StockAccountRepositoryException catch (exception) {
      return StockAccountCommandResult.failure(
        ApplicationFailure.validation(exception.safeMessage),
      );
    } on DomainValidationException catch (exception) {
      return StockAccountCommandResult.failure(
        ApplicationFailure.validation(exception.message),
      );
    } on Exception catch (exception) {
      return StockAccountCommandResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }
}

class RenameStockAccountUseCase {
  const RenameStockAccountUseCase(this._accounts);

  final StockAccountRepository _accounts;

  Future<StockAccountCommandResult> execute(
    RenameStockAccountCommand command,
  ) async {
    try {
      final existing = await _accounts.findById(command.id);
      if (existing == null) {
        return const StockAccountCommandResult.failure(
          ApplicationFailure(
            type: ApplicationFailureType.validation,
            safeMessage: '股票帳戶不存在。',
          ),
        );
      }
      if (existing.isArchived) {
        return const StockAccountCommandResult.failure(
          ApplicationFailure(
            type: ApplicationFailureType.validation,
            safeMessage: '股票帳戶已封存。',
          ),
        );
      }
      return StockAccountCommandResult.success(
        await _accounts.rename(id: command.id, name: command.name),
      );
    } on StockAccountRepositoryException catch (exception) {
      return StockAccountCommandResult.failure(
        ApplicationFailure.validation(exception.safeMessage),
      );
    } on DomainValidationException catch (exception) {
      return StockAccountCommandResult.failure(
        ApplicationFailure.validation(exception.message),
      );
    } on Exception catch (exception) {
      return StockAccountCommandResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }
}

class ArchiveStockAccountUseCase {
  const ArchiveStockAccountUseCase(this._accounts);

  final StockAccountRepository _accounts;

  Future<StockAccountCommandResult> execute(
    ArchiveStockAccountCommand command,
  ) async {
    try {
      if (await _accounts.findById(command.id) == null) {
        return const StockAccountCommandResult.failure(
          ApplicationFailure(
            type: ApplicationFailureType.validation,
            safeMessage: '股票帳戶不存在。',
          ),
        );
      }
      await _accounts.archive(command.id);
      return StockAccountCommandResult.success(
        await _accounts.findById(command.id),
      );
    } on StockAccountRepositoryException catch (exception) {
      return StockAccountCommandResult.failure(
        ApplicationFailure.validation(exception.safeMessage),
      );
    } on Exception catch (exception) {
      return StockAccountCommandResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }
}
