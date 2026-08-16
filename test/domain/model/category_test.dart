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
}
