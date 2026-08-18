import '../../presentation/test_app_harness.dart';
import 'stock_account_repository_contract_test.dart';

void main() {
  stockAccountRepositoryContract(
    createRepository: () async => TestStockAccountRepository(),
  );
}
