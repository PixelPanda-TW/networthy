import '../ledger/ledger_transaction_builder.dart';
import '../model/currency_code.dart';
import '../model/ledger_entry.dart';
import '../model/ledger_transaction.dart';

class LedgerQuery {
  const LedgerQuery({
    this.year,
    this.month,
    this.type,
    this.includeOpeningBalances = false,
  });

  final int? year;
  final int? month;
  final LedgerTransactionType? type;
  final bool includeOpeningBalances;
}

class LedgerRecord {
  const LedgerRecord({required this.transaction, required this.entries});

  final LedgerTransaction transaction;
  final List<LedgerEntry> entries;
}

class AccountBalance {
  const AccountBalance({
    required this.accountId,
    required this.currencyCode,
    required this.balanceMinor,
  });

  final String accountId;
  final CurrencyCode currencyCode;
  final int balanceMinor;
}

class CurrencyMonthlySummary {
  const CurrencyMonthlySummary({
    required this.totalIncomeMinorByCurrency,
    required this.totalExpenseMinorByCurrency,
  });

  final Map<CurrencyCode, int> totalIncomeMinorByCurrency;
  final Map<CurrencyCode, int> totalExpenseMinorByCurrency;

  Map<CurrencyCode, int> get balanceMinorByCurrency {
    final currencies = {
      ...totalIncomeMinorByCurrency.keys,
      ...totalExpenseMinorByCurrency.keys,
    };
    return {
      for (final currency in currencies)
        currency:
            (totalIncomeMinorByCurrency[currency] ?? 0) -
            (totalExpenseMinorByCurrency[currency] ?? 0),
    };
  }
}

abstract interface class LedgerRepository {
  Future<void> save(LedgerTransactionAggregate aggregate);

  Future<LedgerRecord?> findRecordById(String id);

  Future<List<LedgerRecord>> list(LedgerQuery query);

  Future<List<LedgerRecord>> latest({required int limit});

  Future<CurrencyMonthlySummary> monthlySummary({
    required int year,
    required int month,
  });

  Future<List<AccountBalance>> accountBalances();

  Future<void> delete(String id);
}
