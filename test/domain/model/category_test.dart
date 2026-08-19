import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/category.dart';
import 'package:networthy/domain/model/transaction_type.dart';

void main() {
  test('defines stable V1 expense category ids in product order', () {
    expect(
      CategoryCatalog.expenseCategories.map((category) => category.id),
      <String>[
        'expense.food',
        'expense.transport',
        'expense.shopping',
        'expense.housing',
        'expense.entertainment',
        'expense.medical',
        'expense.education',
        'expense.investment',
        'expense.other',
      ],
    );
  });

  test('defines stable V1 income category ids in product order', () {
    expect(
      CategoryCatalog.incomeCategories.map((category) => category.id),
      <String>[
        'income.salary',
        'income.bonus',
        'income.investment',
        'income.other',
      ],
    );
  });

  test('checks category compatibility by transaction type', () {
    expect(
      CategoryCatalog.isCompatible(
        categoryId: 'expense.food',
        type: TransactionType.expense,
      ),
      isTrue,
    );
    expect(
      CategoryCatalog.isCompatible(
        categoryId: 'expense.food',
        type: TransactionType.income,
      ),
      isFalse,
    );
    expect(
      CategoryCatalog.isCompatible(
        categoryId: 'income.salary',
        type: TransactionType.income,
      ),
      isTrue,
    );
    expect(
      CategoryCatalog.isCompatible(
        categoryId: 'unknown',
        type: TransactionType.expense,
      ),
      isFalse,
    );
  });

  test('provides Traditional Chinese display names for stable V1 ids', () {
    expect(CategoryCatalog.displayNameFor('expense.food'), '餐飲');
    expect(CategoryCatalog.displayNameFor('expense.transport'), '交通');
    expect(CategoryCatalog.displayNameFor('expense.shopping'), '購物');
    expect(CategoryCatalog.displayNameFor('expense.housing'), '居住');
    expect(CategoryCatalog.displayNameFor('expense.entertainment'), '娛樂');
    expect(CategoryCatalog.displayNameFor('expense.medical'), '醫療');
    expect(CategoryCatalog.displayNameFor('expense.education'), '教育');
    expect(CategoryCatalog.displayNameFor('expense.other'), '其他');
    expect(CategoryCatalog.displayNameFor('income.salary'), '薪資');
    expect(CategoryCatalog.displayNameFor('income.bonus'), '獎金');
    expect(CategoryCatalog.displayNameFor('income.investment'), '投資');
    expect(CategoryCatalog.displayNameFor('income.other'), '其他');
  });

  test('falls back to the raw id for unknown category ids', () {
    expect(CategoryCatalog.displayNameFor('custom.future'), 'custom.future');
  });

  test('exposes built-in seed definitions for migration', () {
    expect(
      CategoryCatalog.builtInDefinitions.map((category) => category.id),
      containsAll(<String>['expense.food', 'income.salary']),
    );
    expect(CategoryCatalog.builtInDisplayNameFor('expense.food'), '餐飲');
  });
}
