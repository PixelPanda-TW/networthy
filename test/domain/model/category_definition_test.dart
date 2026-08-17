import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/category_definition.dart';
import 'package:networthy/domain/model/transaction_type.dart';

void main() {
  test('creates a valid top-level category', () {
    final category = EditableCategory.create(
      id: 'category.00000000-0000-4000-8000-000000000201',
      type: TransactionType.expense,
      name: '早餐',
      parentId: null,
      sortOrder: 10,
      isArchived: false,
      createdAtUtc: DateTime.utc(2026, 8, 16),
      updatedAtUtc: DateTime.utc(2026, 8, 16),
    );

    expect(category.name, '早餐');
    expect(category.displayPath(), '早餐');
  });

  test('child category display path includes parent name', () {
    final parent = _category(id: 'expense.food', name: '餐飲', parentId: null);
    final child = _category(
      id: 'category.00000000-0000-4000-8000-000000000202',
      name: '早餐',
      parentId: parent.id,
    );

    expect(child.displayPath(parent: parent), '餐飲 / 早餐');
  });

  test('rejects empty and overlong names', () {
    expect(
      () => _category(name: '   '),
      throwsA(isA<CategoryValidationException>()),
    );
    expect(
      () => _category(name: '一二三四五六七八九十一二三四五六七八九十一二三四五六七八九十一'),
      throwsA(isA<CategoryValidationException>()),
    );
  });

  test('requires UTC timestamps', () {
    expect(
      () => EditableCategory.create(
        id: 'category.00000000-0000-4000-8000-000000000203',
        type: TransactionType.expense,
        name: '早餐',
        parentId: null,
        sortOrder: 1,
        isArchived: false,
        createdAtUtc: DateTime(2026, 8, 16),
        updatedAtUtc: DateTime.utc(2026, 8, 16),
      ),
      throwsA(isA<CategoryValidationException>()),
    );
  });
}

EditableCategory _category({
  String id = 'category.00000000-0000-4000-8000-000000000200',
  TransactionType type = TransactionType.expense,
  String name = '早餐',
  String? parentId,
}) {
  return EditableCategory.create(
    id: id,
    type: type,
    name: name,
    parentId: parentId,
    sortOrder: 1,
    isArchived: false,
    createdAtUtc: DateTime.utc(2026, 8, 16),
    updatedAtUtc: DateTime.utc(2026, 8, 16),
  );
}
