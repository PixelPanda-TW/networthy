import '../../presentation/test_app_harness.dart';
import 'stock_holding_repository_contract_test.dart';

void main() {
  stockHoldingRepositoryContract(
    createRepository: () async => TestStockHoldingRepository(),
  );
}
