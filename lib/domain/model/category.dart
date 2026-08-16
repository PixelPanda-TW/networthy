import 'transaction_type.dart';

class TransactionCategory {
  const TransactionCategory({required this.id, required this.type});

  final String id;
  final TransactionType type;
}

class CategoryCatalog {
  const CategoryCatalog._();

  static const List<TransactionCategory>
  expenseCategories = <TransactionCategory>[
    TransactionCategory(id: 'expense.food', type: TransactionType.expense),
    TransactionCategory(id: 'expense.transport', type: TransactionType.expense),
    TransactionCategory(id: 'expense.shopping', type: TransactionType.expense),
    TransactionCategory(id: 'expense.housing', type: TransactionType.expense),
    TransactionCategory(
      id: 'expense.entertainment',
      type: TransactionType.expense,
    ),
    TransactionCategory(id: 'expense.medical', type: TransactionType.expense),
    TransactionCategory(id: 'expense.education', type: TransactionType.expense),
    TransactionCategory(id: 'expense.other', type: TransactionType.expense),
  ];

  static const List<TransactionCategory> incomeCategories =
      <TransactionCategory>[
        TransactionCategory(id: 'income.salary', type: TransactionType.income),
        TransactionCategory(id: 'income.bonus', type: TransactionType.income),
        TransactionCategory(
          id: 'income.investment',
          type: TransactionType.income,
        ),
        TransactionCategory(id: 'income.other', type: TransactionType.income),
      ];

  static const List<TransactionCategory> allCategories = <TransactionCategory>[
    ...expenseCategories,
    ...incomeCategories,
  ];

  static bool isCompatible({
    required String categoryId,
    required TransactionType type,
  }) {
    return allCategories.any(
      (category) => category.id == categoryId && category.type == type,
    );
  }
}
