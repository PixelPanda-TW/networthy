import '../../domain/model/domain_validation.dart';
import '../../domain/model/stock_account.dart';
import '../../domain/repository/stock_account_repository.dart';
import '../../domain/repository/stock_holding_repository.dart';
import '../common/application_failure.dart';
import '../common/application_ports.dart';
import 'stock_holding_command.dart';

class SaveValuationStockHoldingUseCase {
  const SaveValuationStockHoldingUseCase({
    required StockAccountRepository accounts,
    required StockHoldingRepository holdings,
    required ApplicationClock clock,
    required TransactionIdGenerator idGenerator,
  }) : _accounts = accounts,
       _holdings = holdings,
       _clock = clock,
       _idGenerator = idGenerator;

  final StockAccountRepository _accounts;
  final StockHoldingRepository _holdings;
  final ApplicationClock _clock;
  final TransactionIdGenerator _idGenerator;

  Future<StockHoldingCommandResult> execute(
    SaveValuationStockHoldingCommand command,
  ) async {
    try {
      final account = await _activeAccount(command.accountId);
      if (account == null) {
        return _validation('股票帳戶不存在或已封存。');
      }
      if (account.mode != StockAccountMode.taiwanStock) {
        return _validation('估值持倉只能建立在台股個股帳戶。');
      }
      _clock.nowUtc();
      final holding = await _holdings.saveValuation(
        SaveValuationHoldingRequest(
          id: _idGenerator.generate(),
          accountId: account.id,
          symbol: command.symbol,
          name: command.name,
          accountMode: account.mode,
          quantityMicro: command.quantityMicro,
          averageCostMinor: command.averageCostMinor,
          currentPriceMinor: command.currentPriceMinor,
        ),
      );
      return StockHoldingCommandResult.success(holding);
    } on StockHoldingRepositoryException catch (exception) {
      return _validation(exception.safeMessage);
    } on DomainValidationException catch (exception) {
      return _validation(exception.message);
    } on Exception catch (exception) {
      return StockHoldingCommandResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }

  Future<StockAccount?> _activeAccount(String id) async {
    final account = await _accounts.findById(id);
    return account == null || account.isArchived ? null : account;
  }
}

class SavePrincipalStockHoldingUseCase {
  const SavePrincipalStockHoldingUseCase({
    required StockAccountRepository accounts,
    required StockHoldingRepository holdings,
    required ApplicationClock clock,
    required TransactionIdGenerator idGenerator,
  }) : _accounts = accounts,
       _holdings = holdings,
       _clock = clock,
       _idGenerator = idGenerator;

  final StockAccountRepository _accounts;
  final StockHoldingRepository _holdings;
  final ApplicationClock _clock;
  final TransactionIdGenerator _idGenerator;

  Future<StockHoldingCommandResult> execute(
    SavePrincipalStockHoldingCommand command,
  ) async {
    try {
      final account = await _accounts.findById(command.accountId);
      if (account == null || account.isArchived) {
        return _validation('股票帳戶不存在或已封存。');
      }
      if (account.mode == StockAccountMode.taiwanStock) {
        return _validation('本金持倉只能建立在台股 ETF 或美股帳戶。');
      }
      _clock.nowUtc();
      final holding = await _holdings.savePrincipal(
        SavePrincipalHoldingRequest(
          id: _idGenerator.generate(),
          accountId: account.id,
          symbol: command.symbol,
          name: command.name,
          accountMode: account.mode,
          principalMinor: command.principalMinor,
        ),
      );
      return StockHoldingCommandResult.success(holding);
    } on StockHoldingRepositoryException catch (exception) {
      return _validation(exception.safeMessage);
    } on DomainValidationException catch (exception) {
      return _validation(exception.message);
    } on Exception catch (exception) {
      return StockHoldingCommandResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }
}

class ArchiveStockHoldingUseCase {
  const ArchiveStockHoldingUseCase(this._holdings);

  final StockHoldingRepository _holdings;

  Future<StockHoldingCommandResult> execute(
    ArchiveStockHoldingCommand command,
  ) async {
    try {
      if (await _holdings.findById(command.id) == null) {
        return _validation('股票持倉不存在。');
      }
      await _holdings.archive(command.id);
      return StockHoldingCommandResult.success(
        await _holdings.findById(command.id),
      );
    } on StockHoldingRepositoryException catch (exception) {
      return _validation(exception.safeMessage);
    } on Exception catch (exception) {
      return StockHoldingCommandResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }
}

StockHoldingCommandResult _validation(String message) {
  return StockHoldingCommandResult.failure(
    ApplicationFailure.validation(message),
  );
}
