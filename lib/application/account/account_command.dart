import '../../domain/model/account.dart';
import '../../domain/model/currency_code.dart';
import '../common/application_failure.dart';

class CreateAccountCommand {
  const CreateAccountCommand({
    required this.name,
    required this.currencyCode,
    required this.openingBalanceMinor,
  });

  final String name;
  final CurrencyCode currencyCode;
  final int openingBalanceMinor;
}

class RenameAccountCommand {
  const RenameAccountCommand({required this.id, required this.name});

  final String id;
  final String name;
}

class ArchiveAccountCommand {
  const ArchiveAccountCommand({required this.id});

  final String id;
}

class AccountCommandResult {
  const AccountCommandResult.success(this.account) : failure = null;

  const AccountCommandResult.failure(this.failure) : account = null;

  final CashAccount? account;
  final ApplicationFailure? failure;
}
