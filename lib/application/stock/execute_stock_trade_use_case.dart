import '../../domain/ledger/ledger_transaction_builder.dart';
import '../../domain/model/domain_validation.dart';
import '../../domain/model/stock_account.dart';
import '../../domain/model/stock_holding.dart';
import '../../domain/model/stock_trade.dart';
import '../../domain/repository/account_repository.dart';
import '../../domain/repository/ledger_repository.dart';
import '../../domain/repository/stock_account_repository.dart';
import '../../domain/repository/stock_holding_repository.dart';
import '../../domain/repository/stock_trade_repository.dart';
import '../common/application_failure.dart';
import '../common/application_ports.dart';
import 'stock_trade_command.dart';
import 'stock_trade_execution.dart';

class StockTradeCommandResult {
  const StockTradeCommandResult.success(this.trade) : failure = null;

  const StockTradeCommandResult.failure(this.failure) : trade = null;

  final StockTrade? trade;
  final ApplicationFailure? failure;
}

class ExecuteStockTradeUseCase {
  const ExecuteStockTradeUseCase({
    required StockAccountRepository stockAccounts,
    required AccountRepository cashAccounts,
    required StockHoldingRepository holdings,
    required LedgerRepository ledger,
    required StockTradeAtomicExecutor executor,
    required ApplicationClock clock,
    required TransactionIdGenerator idGenerator,
  }) : _stockAccounts = stockAccounts,
       _cashAccounts = cashAccounts,
       _holdings = holdings,
       _ledger = ledger,
       _executor = executor,
       _clock = clock,
       _idGenerator = idGenerator;

  final StockAccountRepository _stockAccounts;
  final AccountRepository _cashAccounts;
  final StockHoldingRepository _holdings;
  final LedgerRepository _ledger;
  final StockTradeAtomicExecutor _executor;
  final ApplicationClock _clock;
  final TransactionIdGenerator _idGenerator;

  Future<StockTradeCommandResult> execute(
    ExecuteStockTradeCommand command,
  ) async {
    try {
      final stockAccount = await _stockAccounts.findById(
        command.stockAccountId,
      );
      if (stockAccount == null || stockAccount.isArchived) {
        return _validation('股票帳戶不存在或已封存。');
      }
      final cashAccount = await _cashAccounts.findById(command.cashAccountId);
      if (cashAccount == null || cashAccount.isArchived) {
        return _validation('現金帳戶不存在或已封存。');
      }
      if (stockAccount.mode != command.accountMode) {
        return _validation('交易模式與股票帳戶不一致。');
      }
      if (cashAccount.currencyCode != stockAccount.currencyCode) {
        return _validation('股票帳戶與現金帳戶幣別必須相同。');
      }
      final existing = (await _holdings.listActiveByAccount(stockAccount.id))
          .where((holding) => holding.symbol == command.symbol.trim())
          .firstOrNull;
      final now = _clock.nowUtc();
      final trade = _buildTrade(command, now);
      final updated = _nextHolding(
        command: command,
        trade: trade,
        account: stockAccount,
        existing: existing,
        now: now,
      );
      final balances = await _ledger.accountBalances();
      final balance = balances
          .where((item) => item.accountId == cashAccount.id)
          .firstOrNull
          ?.balanceMinor;
      if (command.side == StockTradeSide.buy &&
          (balance ?? 0) < trade.cashAmountMinor) {
        return _validation('現金帳戶餘額不足。');
      }
      final ledgerId = _idGenerator.generate();
      final entryId = _idGenerator.generate();
      final ledgerAggregate = command.side == StockTradeSide.buy
          ? LedgerTransactionBuilder.expense(
              transactionId: ledgerId,
              entryId: entryId,
              account: cashAccount,
              amountMinor: trade.cashAmountMinor,
              categoryId: 'expense.investment',
              transactionDate: command.tradeDate,
              note: command.note,
              createdAtUtc: now,
            )
          : LedgerTransactionBuilder.income(
              transactionId: ledgerId,
              entryId: entryId,
              account: cashAccount,
              amountMinor: trade.cashAmountMinor,
              categoryId: 'income.investment',
              transactionDate: command.tradeDate,
              note: command.note,
              createdAtUtc: now,
            );
      await _executor.execute(
        trade: trade,
        updatedHolding: updated.holding,
        holdingToArchiveId: updated.archiveId,
        ledger: ledgerAggregate,
      );
      return StockTradeCommandResult.success(trade);
    } on DomainValidationException catch (error) {
      return _validation(error.message);
    } on Exception catch (error) {
      if (error is StockTradeRepositoryException ||
          error is StockAccountRepositoryException ||
          error is AccountRepositoryException ||
          error is StockHoldingRepositoryException) {
        return _validation(error.toString());
      }
      return StockTradeCommandResult.failure(
        ApplicationFailure.fromException(error),
      );
    }
  }

  StockTrade _buildTrade(ExecuteStockTradeCommand command, DateTime now) {
    if (command.accountMode == StockAccountMode.taiwanStock) {
      if (command.quantityMicro == null ||
          command.priceMinor == null ||
          command.principalMinor != null) {
        throw const DomainValidationException('台股個股交易需要股數與價格。');
      }
      return StockTrade.valuation(
        id: _idGenerator.generate(),
        stockAccountId: command.stockAccountId,
        cashAccountId: command.cashAccountId,
        side: command.side,
        symbol: command.symbol,
        name: command.name,
        quantityMicro: command.quantityMicro!,
        priceMinor: command.priceMinor!,
        tradeDate: command.tradeDate,
        note: command.note,
        createdAtUtc: now,
        updatedAtUtc: now,
      );
    }
    if (command.principalMinor == null ||
        command.quantityMicro != null ||
        command.priceMinor != null) {
      throw const DomainValidationException('ETF/美股交易只需要本金。');
    }
    return StockTrade.principal(
      id: _idGenerator.generate(),
      stockAccountId: command.stockAccountId,
      cashAccountId: command.cashAccountId,
      side: command.side,
      accountMode: command.accountMode,
      symbol: command.symbol,
      name: command.name,
      principalMinor: command.principalMinor!,
      tradeDate: command.tradeDate,
      note: command.note,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }

  _HoldingUpdate _nextHolding({
    required ExecuteStockTradeCommand command,
    required StockTrade trade,
    required StockAccount account,
    required StockHolding? existing,
    required DateTime now,
  }) {
    if (command.side == StockTradeSide.sell && existing == null) {
      throw const DomainValidationException('找不到可賣出的持倉。');
    }
    if (account.mode == StockAccountMode.taiwanStock) {
      final quantity = existing?.quantityMicro ?? 0;
      final delta = trade.quantityMicro!;
      if (command.side == StockTradeSide.sell && delta > quantity) {
        throw const DomainValidationException('賣出股數不可超過持倉。');
      }
      final nextQuantity = command.side == StockTradeSide.buy
          ? quantity + delta
          : quantity - delta;
      if (nextQuantity == 0) {
        return _HoldingUpdate(holding: null, archiveId: existing!.id);
      }
      final averageCost = command.side == StockTradeSide.buy
          ? ((quantity * (existing?.averageCostMinor ?? trade.priceMinor!) +
                        delta * trade.priceMinor!) /
                    nextQuantity)
                .round()
          : existing!.averageCostMinor!;
      final id = existing?.id ?? _idGenerator.generate();
      return _HoldingUpdate(
        holding: StockHolding.valuation(
          id: id,
          accountId: account.id,
          symbol: trade.symbol,
          name: trade.name,
          accountMode: account.mode,
          quantityMicro: nextQuantity,
          averageCostMinor: averageCost,
          currentPriceMinor: trade.priceMinor!,
          isArchived: false,
          createdAtUtc: existing?.createdAtUtc ?? now,
          updatedAtUtc: now,
        ),
      );
    }
    final principal = existing?.principalMinor ?? 0;
    final delta = trade.principalMinor!;
    if (command.side == StockTradeSide.sell && delta > principal) {
      throw const DomainValidationException('賣出本金不可超過持倉。');
    }
    final nextPrincipal = command.side == StockTradeSide.buy
        ? principal + delta
        : principal - delta;
    if (nextPrincipal == 0) {
      return _HoldingUpdate(holding: null, archiveId: existing!.id);
    }
    return _HoldingUpdate(
      holding: StockHolding.principal(
        id: existing?.id ?? _idGenerator.generate(),
        accountId: account.id,
        symbol: trade.symbol,
        name: trade.name,
        accountMode: account.mode,
        principalMinor: nextPrincipal,
        isArchived: false,
        createdAtUtc: existing?.createdAtUtc ?? now,
        updatedAtUtc: now,
      ),
    );
  }
}

class _HoldingUpdate {
  const _HoldingUpdate({required this.holding, this.archiveId});

  final StockHolding? holding;
  final String? archiveId;
}

StockTradeCommandResult _validation(String message) {
  return StockTradeCommandResult.failure(
    ApplicationFailure.validation(message),
  );
}
