import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/presentation/settings/category_management_page.dart';

import '../test_app_harness.dart';

void main() {
  testWidgets('creates top-level and child expense categories', (tester) async {
    final categories = TestCategoryRepository();
    await tester.pumpWidget(
      testMaterialApp(CategoryManagementPage(categories: categories)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('新增支出分類'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name-field')), '飲料');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('飲料'), findsOneWidget);

    await tester.tap(find.byTooltip('新增 飲料 的子分類'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name-field')), '咖啡');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('飲料 / 咖啡'), findsOneWidget);
    expect(
      (await categories.listAll(
        TransactionType.expense,
      )).map((category) => category.name),
      contains('咖啡'),
    );
  });

  testWidgets('renames and archives a category', (tester) async {
    final categories = TestCategoryRepository();
    await tester.pumpWidget(
      testMaterialApp(CategoryManagementPage(categories: categories)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('重新命名 餐飲'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name-field')), '吃飯');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('吃飯'), findsOneWidget);

    await tester.tap(find.byTooltip('封存 吃飯'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('封存'));
    await tester.pumpAndSettle();

    expect(find.text('吃飯'), findsNothing);
  });
}
