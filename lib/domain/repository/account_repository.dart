import '../model/account.dart';
import '../model/currency_code.dart';

abstract interface class AccountRepository {
  Future<List<CashAccount>> listActive();

  Future<List<CashAccount>> listAll();

  Future<CashAccount?> findById(String id);

  Future<String> displayNameFor(String id);

  Future<CashAccount> create(CreateAccountRequest request);

  Future<CashAccount> rename({required String id, required String name});

  Future<void> archive(String id);

  Future<CashAccount> ensureDefaultAccountSeeded();
}

class CreateAccountRequest {
  const CreateAccountRequest({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.openingBalanceMinor,
  });

  final String id;
  final String name;
  final CurrencyCode currencyCode;
  final int openingBalanceMinor;
}

class AccountRepositoryException implements Exception {
  const AccountRepositoryException(this.safeMessage);

  final String safeMessage;

  @override
  String toString() => 'AccountRepositoryException: $safeMessage';
}
