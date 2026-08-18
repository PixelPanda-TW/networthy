import '../../domain/model/stock_account.dart';
import '../common/application_failure.dart';

class CreateStockAccountCommand {
  const CreateStockAccountCommand({required this.name, required this.mode});

  final String name;
  final StockAccountMode mode;
}

class RenameStockAccountCommand {
  const RenameStockAccountCommand({required this.id, required this.name});

  final String id;
  final String name;
}

class ArchiveStockAccountCommand {
  const ArchiveStockAccountCommand({required this.id});

  final String id;
}

class StockAccountCommandResult {
  const StockAccountCommandResult.success(this.account) : failure = null;

  const StockAccountCommandResult.failure(this.failure) : account = null;

  final StockAccount? account;
  final ApplicationFailure? failure;
}
