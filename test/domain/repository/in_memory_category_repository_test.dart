import '../../presentation/test_app_harness.dart';
import 'category_repository_contract_test.dart';

void main() {
  categoryRepositoryContract(
    createRepository: () async => TestCategoryRepository(seedBuiltIns: false),
  );
}
