import '../../domain/ledger/ledger_transaction_builder.dart';
import '../../domain/model/account.dart';
import '../../domain/model/domain_validation.dart';
import '../../domain/model/ledger_entry.dart';
import '../../domain/model/ledger_transaction.dart';
import '../../domain/model/transaction_type.dart';
import '../../domain/repository/account_repository.dart';
import '../../domain/repository/category_repository.dart';
import '../../domain/repository/ledger_repository.dart';
import '../common/application_failure.dart';
import '../common/application_ports.dart';
import 'ledger_command.dart';

class AddLedgerIncomeExpenseUseCase {
  const AddLedgerIncomeExpenseUseCase({
    required AccountRepository accounts,
    required LedgerRepository ledger,
    required CategoryRepository categories,
    required ApplicationClock clock,
    required TransactionIdGenerator idGenerator,
  }) : _accounts = accounts,
       _ledger = ledger,
       _categories = categories,
       _clock = clock,
       _idGenerator = idGenerator;

  final AccountRepository _accounts;
  final LedgerRepository _ledger;
  final CategoryRepository _categories;
  final ApplicationClock _clock;
  final TransactionIdGenerator _idGenerator;

  Future<LedgerCommandResult> execute(
    LedgerIncomeExpenseCommand command,
  ) async {
    try {
      final accountFailure = await _lookupActiveAccount(
        command.accountId,
        _accounts,
      );
      if (accountFailure.failure != null) {
        return LedgerCommandResult.failure(accountFailure.failure!);
      }
      final categoryFailure = await _validateCategory(command);
      if (categoryFailure != null) {
        return LedgerCommandResult.failure(categoryFailure);
      }
      final now = _clock.nowUtc();
      final aggregate = switch (command.type) {
        TransactionType.expense => LedgerTransactionBuilder.expense(
          transactionId: _idGenerator.generate(),
          entryId: _idGenerator.generate(),
          account: accountFailure.account!,
          amountMinor: command.amountMinor,
          categoryId: command.categoryId,
          transactionDate: command.transactionDate,
          note: command.note,
          createdAtUtc: now,
        ),
        TransactionType.income => LedgerTransactionBuilder.income(
          transactionId: _idGenerator.generate(),
          entryId: _idGenerator.generate(),
          account: accountFailure.account!,
          amountMinor: command.amountMinor,
          categoryId: command.categoryId,
          transactionDate: command.transactionDate,
          note: command.note,
          createdAtUtc: now,
        ),
      };
      await _ledger.save(aggregate);
      return LedgerCommandResult.success(
        LedgerRecord(
          transaction: aggregate.transaction,
          entries: List.unmodifiable(aggregate.entries),
        ),
      );
    } on CategoryRepositoryException catch (exception) {
      return LedgerCommandResult.failure(
        ApplicationFailure.validation(exception.safeMessage),
      );
    } on AccountRepositoryException catch (exception) {
      return LedgerCommandResult.failure(
        ApplicationFailure.validation(exception.safeMessage),
      );
    } on DomainValidationException catch (exception) {
      return LedgerCommandResult.failure(
        ApplicationFailure.validation(exception.message),
      );
    } on Exception catch (exception) {
      return LedgerCommandResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }

  Future<ApplicationFailure?> _validateCategory(
    LedgerIncomeExpenseCommand command,
  ) async {
    final category = await _categories.findById(command.categoryId);
    if (category == null ||
        category.isArchived ||
        category.type != command.type) {
      return ApplicationFailure.validation('請選擇有效分類。');
    }
    return null;
  }
}

class AddTransferUseCase {
  const AddTransferUseCase({
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

  Future<LedgerCommandResult> execute(TransferCommand command) async {
    try {
      final sourceResult = await _lookupActiveAccount(
        command.sourceAccountId,
        _accounts,
      );
      if (sourceResult.failure != null) {
        return LedgerCommandResult.failure(sourceResult.failure!);
      }
      final targetResult = await _lookupActiveAccount(
        command.targetAccountId,
        _accounts,
      );
      if (targetResult.failure != null) {
        return LedgerCommandResult.failure(targetResult.failure!);
      }
      final now = _clock.nowUtc();
      final aggregate = LedgerTransactionBuilder.transfer(
        transactionId: _idGenerator.generate(),
        sourceEntryId: _idGenerator.generate(),
        targetEntryId: _idGenerator.generate(),
        source: sourceResult.account!,
        target: targetResult.account!,
        amountMinor: command.amountMinor,
        transactionDate: command.transactionDate,
        note: command.note,
        createdAtUtc: now,
      );
      await _ledger.save(aggregate);
      return LedgerCommandResult.success(
        LedgerRecord(
          transaction: aggregate.transaction,
          entries: List.unmodifiable(aggregate.entries),
        ),
      );
    } on AccountRepositoryException catch (exception) {
      return LedgerCommandResult.failure(
        ApplicationFailure.validation(exception.safeMessage),
      );
    } on DomainValidationException catch (exception) {
      return LedgerCommandResult.failure(
        ApplicationFailure.validation(exception.message),
      );
    } on Exception catch (exception) {
      return LedgerCommandResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }
}

class EditLedgerIncomeExpenseUseCase {
  const EditLedgerIncomeExpenseUseCase({
    required AccountRepository accounts,
    required LedgerRepository ledger,
    required CategoryRepository categories,
    required ApplicationClock clock,
  }) : _accounts = accounts,
       _ledger = ledger,
       _categories = categories,
       _clock = clock;

  final AccountRepository _accounts;
  final LedgerRepository _ledger;
  final CategoryRepository _categories;
  final ApplicationClock _clock;

  Future<LedgerCommandResult> execute(
    EditLedgerIncomeExpenseCommand command,
  ) async {
    try {
      final existing = await _ledger.findRecordById(command.id);
      if (existing == null) {
        return LedgerCommandResult.failure(
          ApplicationFailure.validation('記錄不存在。'),
        );
      }
      if (existing.transaction.type == LedgerTransactionType.openingBalance) {
        return LedgerCommandResult.failure(
          ApplicationFailure.validation('初始餘額不可編輯。'),
        );
      }
      if (existing.transaction.type == LedgerTransactionType.transfer) {
        return LedgerCommandResult.failure(
          ApplicationFailure.validation('轉帳記錄請使用轉帳編輯。'),
        );
      }
      if (existing.entries.length != 1) {
        return LedgerCommandResult.failure(
          ApplicationFailure.validation('記錄格式不正確。'),
        );
      }
      final accountResult = await _lookupActiveAccount(
        command.accountId,
        _accounts,
      );
      if (accountResult.failure != null) {
        return LedgerCommandResult.failure(accountResult.failure!);
      }
      final categoryFailure = await _validateCategory(command);
      if (categoryFailure != null) {
        return LedgerCommandResult.failure(categoryFailure);
      }

      final account = accountResult.account!;
      final amountMinor = switch (command.type) {
        TransactionType.expense => -command.amountMinor,
        TransactionType.income => command.amountMinor,
      };
      final updated = LedgerTransactionAggregate(
        transaction: LedgerTransaction.create(
          id: existing.transaction.id,
          type: command.type.ledgerType,
          categoryId: command.categoryId,
          transactionDate: command.transactionDate,
          note: command.note,
          createdAtUtc: existing.transaction.createdAtUtc,
          updatedAtUtc: _clock.nowUtc(),
        ),
        entries: [
          LedgerEntry.create(
            id: existing.entries.single.id,
            transactionId: existing.transaction.id,
            accountId: account.id,
            amountMinor: amountMinor,
            currencyCode: account.currencyCode,
            createdAtUtc: existing.entries.single.createdAtUtc,
          ),
        ],
      );
      await _ledger.save(updated);
      return LedgerCommandResult.success(
        LedgerRecord(
          transaction: updated.transaction,
          entries: List.unmodifiable(updated.entries),
        ),
      );
    } on CategoryRepositoryException catch (exception) {
      return LedgerCommandResult.failure(
        ApplicationFailure.validation(exception.safeMessage),
      );
    } on AccountRepositoryException catch (exception) {
      return LedgerCommandResult.failure(
        ApplicationFailure.validation(exception.safeMessage),
      );
    } on DomainValidationException catch (exception) {
      return LedgerCommandResult.failure(
        ApplicationFailure.validation(exception.message),
      );
    } on Exception catch (exception) {
      return LedgerCommandResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }

  Future<ApplicationFailure?> _validateCategory(
    EditLedgerIncomeExpenseCommand command,
  ) async {
    final category = await _categories.findById(command.categoryId);
    if (category == null ||
        category.isArchived ||
        category.type != command.type) {
      return ApplicationFailure.validation('請選擇有效分類。');
    }
    return null;
  }
}

class DeleteLedgerRecordUseCase {
  const DeleteLedgerRecordUseCase(this._ledger);

  final LedgerRepository _ledger;

  Future<DeleteLedgerRecordResult> execute(
    DeleteLedgerRecordCommand command,
  ) async {
    if (!command.confirmed) {
      return DeleteLedgerRecordResult.failure(
        ApplicationFailure.validation('Delete must be confirmed.'),
      );
    }

    try {
      final record = await _ledger.findRecordById(command.id);
      if (record == null) {
        return DeleteLedgerRecordResult.failure(
          ApplicationFailure.validation('記錄不存在。'),
        );
      }
      if (record.transaction.type == LedgerTransactionType.openingBalance) {
        return DeleteLedgerRecordResult.failure(
          ApplicationFailure.validation('初始餘額不可刪除。'),
        );
      }
      await _ledger.delete(command.id);
      return const DeleteLedgerRecordResult.success();
    } on Exception catch (exception) {
      return DeleteLedgerRecordResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }
}

class _AccountLookupResult {
  const _AccountLookupResult.success(this.account) : failure = null;

  const _AccountLookupResult.failure(this.failure) : account = null;

  final CashAccount? account;
  final ApplicationFailure? failure;
}

Future<_AccountLookupResult> _lookupActiveAccount(
  String accountId,
  AccountRepository accounts,
) async {
  final account = await accounts.findById(accountId);
  if (account == null) {
    return _AccountLookupResult.failure(
      ApplicationFailure.validation('帳戶不存在。'),
    );
  }
  if (account.isArchived) {
    return _AccountLookupResult.failure(
      ApplicationFailure.validation('帳戶已封存。'),
    );
  }
  return _AccountLookupResult.success(account);
}
