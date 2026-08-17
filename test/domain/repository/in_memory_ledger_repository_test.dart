import '../../presentation/test_app_harness.dart';
import 'ledger_repository_contract_test.dart';

void main() {
  ledgerRepositoryContract(
    createRepository: () async => TestLedgerRepository(),
  );
}
