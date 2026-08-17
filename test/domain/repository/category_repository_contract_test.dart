import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/domain/repository/category_repository.dart';

void main() {}

void categoryRepositoryContract({
  required Future<CategoryRepository> Function() createRepository,
}) {
  test('creates top-level and child categories', () async {
    final repository = await createRepository();
    final parent = await repository.create(
      CreateCategoryRequest(
        id: 'category.00000000-0000-4000-8000-000000000301',
        type: TransactionType.expense,
        name: '餐飲',
        parentId: null,
      ),
    );
    final child = await repository.create(
      CreateCategoryRequest(
        id: 'category.00000000-0000-4000-8000-000000000302',
        type: TransactionType.expense,
        name: '早餐',
        parentId: parent.id,
      ),
    );

    expect(child.parentId, parent.id);
    expect(await repository.displayPathFor(child.id), '餐飲 / 早餐');
  });

  test('rejects duplicate active sibling names', () async {
    final repository = await createRepository();
    await repository.create(
      CreateCategoryRequest(
        id: 'category.00000000-0000-4000-8000-000000000303',
        type: TransactionType.expense,
        name: '餐飲',
        parentId: null,
      ),
    );

    expect(
      () => repository.create(
        CreateCategoryRequest(
          id: 'category.00000000-0000-4000-8000-000000000304',
          type: TransactionType.expense,
          name: '餐飲',
          parentId: null,
        ),
      ),
      throwsA(isA<CategoryRepositoryException>()),
    );
  });

  test('rejects child under child', () async {
    final repository = await createRepository();
    final parent = await repository.create(
      CreateCategoryRequest(
        id: 'category.00000000-0000-4000-8000-000000000305',
        type: TransactionType.expense,
        name: '餐飲',
        parentId: null,
      ),
    );
    final child = await repository.create(
      CreateCategoryRequest(
        id: 'category.00000000-0000-4000-8000-000000000306',
        type: TransactionType.expense,
        name: '早餐',
        parentId: parent.id,
      ),
    );

    expect(
      () => repository.create(
        CreateCategoryRequest(
          id: 'category.00000000-0000-4000-8000-000000000307',
          type: TransactionType.expense,
          name: '甜點',
          parentId: child.id,
        ),
      ),
      throwsA(isA<CategoryRepositoryException>()),
    );
  });

  test('archive hides from active list but keeps lookup', () async {
    final repository = await createRepository();
    final category = await repository.create(
      CreateCategoryRequest(
        id: 'category.00000000-0000-4000-8000-000000000308',
        type: TransactionType.expense,
        name: '早餐',
        parentId: null,
      ),
    );

    await repository.archive(category.id);

    expect(await repository.findById(category.id), isNotNull);
    expect(
      (await repository.listActive(
        TransactionType.expense,
      )).map((item) => item.id),
      isNot(contains(category.id)),
    );
  });
}
