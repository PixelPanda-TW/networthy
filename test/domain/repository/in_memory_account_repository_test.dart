import '../../presentation/test_app_harness.dart';
import 'account_repository_contract_test.dart';

void main() {
  accountRepositoryContract(
    createRepository: () async => TestAccountRepository(seedDefault: false),
  );
}
