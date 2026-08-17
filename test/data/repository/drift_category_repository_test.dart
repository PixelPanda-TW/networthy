import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/networthy_database.dart';
import 'package:networthy/data/repository/drift_category_repository.dart';
import 'package:networthy/domain/model/transaction_type.dart';

import '../../domain/repository/category_repository_contract_test.dart';

void main() {
  categoryRepositoryContract(
    createRepository: () async {
      final database = NetworthyDatabase.inMemory();
      addTearDown(database.close);
      return DriftCategoryRepository(database);
    },
  );

  test(
    'seeds built-in categories idempotently without overwriting names',
    () async {
      final database = NetworthyDatabase.inMemory();
      addTearDown(database.close);
      final repository = DriftCategoryRepository(database);

      await repository.ensureBuiltInCategoriesSeeded();
      await repository.rename(id: 'expense.food', name: '吃飯');
      await repository.ensureBuiltInCategoriesSeeded();

      expect(await repository.displayPathFor('expense.food'), '吃飯');
      expect(
        (await repository.listAll(
          TransactionType.expense,
        )).where((category) => category.id == 'expense.food'),
        hasLength(1),
      );
    },
  );

  test('renames and archives persisted category', () async {
    final database = NetworthyDatabase.inMemory();
    addTearDown(database.close);
    final repository = DriftCategoryRepository(database);
    await repository.ensureBuiltInCategoriesSeeded();

    await repository.rename(id: 'expense.food', name: '吃飯');
    await repository.archive('expense.food');

    expect(await repository.displayPathFor('expense.food'), '吃飯');
    expect(
      (await repository.listActive(
        TransactionType.expense,
      )).map((category) => category.id),
      isNot(contains('expense.food')),
    );
  });
}
