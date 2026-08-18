import 'transaction_type.dart';

class TransactionCategory {
  const TransactionCategory({
    required this.id,
    required this.type,
    required this.displayName,
  });

  final String id;
  final TransactionType type;
  final String displayName;
}

class CategoryCatalog {
  const CategoryCatalog._();

  static const List<TransactionCategory> expenseCategories =
      <TransactionCategory>[
        TransactionCategory(
          id: 'expense.food',
          type: TransactionType.expense,
          displayName: '餐飲',
        ),
        TransactionCategory(
          id: 'expense.transport',
          type: TransactionType.expense,
          displayName: '交通',
        ),
        TransactionCategory(
          id: 'expense.shopping',
          type: TransactionType.expense,
          displayName: '購物',
        ),
        TransactionCategory(
          id: 'expense.housing',
          type: TransactionType.expense,
          displayName: '居住',
        ),
        TransactionCategory(
          id: 'expense.entertainment',
          type: TransactionType.expense,
          displayName: '娛樂',
        ),
        TransactionCategory(
          id: 'expense.medical',
          type: TransactionType.expense,
          displayName: '醫療',
        ),
        TransactionCategory(
          id: 'expense.education',
          type: TransactionType.expense,
          displayName: '教育',
        ),
        TransactionCategory(
          id: 'expense.investment',
          type: TransactionType.expense,
          displayName: '投資',
        ),
        TransactionCategory(
          id: 'expense.other',
          type: TransactionType.expense,
          displayName: '其他',
        ),
      ];

  static const List<TransactionCategory> incomeCategories =
      <TransactionCategory>[
        TransactionCategory(
          id: 'income.salary',
          type: TransactionType.income,
          displayName: '薪資',
        ),
        TransactionCategory(
          id: 'income.bonus',
          type: TransactionType.income,
          displayName: '獎金',
        ),
        TransactionCategory(
          id: 'income.investment',
          type: TransactionType.income,
          displayName: '投資',
        ),
        TransactionCategory(
          id: 'income.other',
          type: TransactionType.income,
          displayName: '其他',
        ),
      ];

  static const List<TransactionCategory> allCategories = <TransactionCategory>[
    ...expenseCategories,
    ...incomeCategories,
  ];

  static const List<TransactionCategory> builtInDefinitions = allCategories;

  static bool isCompatible({
    required String categoryId,
    required TransactionType type,
  }) {
    return allCategories.any(
      (category) => category.id == categoryId && category.type == type,
    );
  }

  static String displayNameFor(String categoryId) {
    for (final category in allCategories) {
      if (category.id == categoryId) {
        return category.displayName;
      }
    }
    return categoryId;
  }

  static String builtInDisplayNameFor(String categoryId) {
    return displayNameFor(categoryId);
  }
}
