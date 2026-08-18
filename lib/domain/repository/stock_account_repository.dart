import '../model/stock_account.dart';

abstract interface class StockAccountRepository {
  Future<List<StockAccount>> listActive();

  Future<List<StockAccount>> listAll();

  Future<StockAccount?> findById(String id);

  Future<StockAccount> create(CreateStockAccountRequest request);

  Future<StockAccount> rename({required String id, required String name});

  Future<void> archive(String id);
}

class CreateStockAccountRequest {
  const CreateStockAccountRequest({
    required this.id,
    required this.name,
    required this.mode,
  });

  final String id;
  final String name;
  final StockAccountMode mode;
}

class StockAccountRepositoryException implements Exception {
  const StockAccountRepositoryException(this.safeMessage);

  final String safeMessage;

  @override
  String toString() => 'StockAccountRepositoryException: $safeMessage';
}
