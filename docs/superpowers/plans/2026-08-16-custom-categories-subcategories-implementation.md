# Custom Categories and Subcategories Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add editable local income/expense categories with one level of subcategories while preserving existing transactions and V1 category IDs.

**Architecture:** Introduce category domain models and a `CategoryRepository`, persist categories in Drift with schema version 2, and pass category dependencies through the existing app composition root. UI resolves category names from repository-backed data and adds Settings category management; transaction storage continues to store stable category IDs.

**Tech Stack:** Flutter Material 3, pure Dart domain/application layers, Drift/sqlite3 encrypted local database, Flutter widget tests, Drift repository tests, checked-in generated Drift code.

## Global Constraints

- V1 is offline-first and does not require login, backend, or cloud sync.
- Local accounting database remains encrypted through the existing `EncryptedDatabaseOpener`.
- Existing transactions must be preserved unchanged; their `categoryId` values remain stable IDs.
- v0.2.0 supports one level of subcategories only.
- v0.2.0 does not add multi-account, multi-currency, transfers, stock accounts, category icons/colors, drag-and-drop sorting, hard deletion, import/export, or cloud sync.
- Domain code must not import Flutter, Drift, sqlite3, secure storage, platform packages, or data-layer packages.
- Presentation must not display raw category IDs for known categories.
- Completion requires `git add`, `git commit`, and `git push`.
- Do not include local Xcode signing changes from `ios/Runner.xcodeproj/project.pbxproj` unless the user explicitly asks for that.

---

## File structure

- Create `lib/domain/model/category_definition.dart`: editable category model, type aliases, display path rules, validation.
- Modify `lib/domain/model/category.dart`: keep V1 built-in category IDs/names as seed definitions and compatibility helpers.
- Create `lib/domain/repository/category_repository.dart`: category repository contract and request objects.
- Create `test/domain/model/category_definition_test.dart`: category validation and display path tests.
- Create `test/domain/repository/category_repository_contract_test.dart`: reusable repository behavior tests.
- Modify `lib/data/database/networthy_database.dart`: add `Categories` table and schema version 2 migration.
- Regenerate `lib/data/database/networthy_database.g.dart`.
- Create `lib/data/repository/drift_category_repository.dart`: Drift-backed category repository and seed behavior.
- Create `test/data/repository/drift_category_repository_test.dart`: repository + seed tests.
- Modify `test/data/database/networthy_database_migration_test.dart`: schema v1 to v2 preserves transactions and seeds categories.
- Modify `lib/application/transaction/add_transaction_use_case.dart`: validate category existence before add.
- Modify `lib/application/transaction/edit_transaction_use_case.dart`: validate category existence before edit.
- Modify `lib/application/transaction/transaction_command.dart`: keep command shape stable; category IDs remain strings.
- Create `test/application/transaction/category_validated_transaction_use_cases_test.dart`: add/edit category validation tests.
- Modify `lib/presentation/app/networthy_app.dart`: accept category repository dependency.
- Modify `lib/presentation/home/home_shell.dart`: pass category dependency to pages.
- Modify `lib/presentation/overview/overview_page.dart`: resolve category display paths from category repository.
- Modify `lib/presentation/records/records_page.dart`: resolve category display paths from category repository.
- Modify `lib/presentation/transaction/transaction_form_page.dart`: load active categories from repository and preserve archived selected category on edit.
- Modify `lib/presentation/settings/settings_page.dart`: add entry to category management.
- Create `lib/presentation/settings/category_management_page.dart`: category management screen.
- Modify `test/presentation/test_app_harness.dart`: add in-memory category repository for widget tests.
- Create `test/presentation/settings/category_management_widget_test.dart`: category management UI tests.
- Modify existing overview/records/transaction widget tests to pass category repository.
- Modify `lib/main.dart`: construct and inject `DriftCategoryRepository`.
- Modify `docs/problems/v0.1.0.md`: mark custom category/subcategory work as implemented after completion.
- Create `docs/verification/v0.2.0-custom-categories.md`: final verification evidence and manual script.

## Task 1: Domain category model and built-in seed definitions

**Files:**
- Create: `lib/domain/model/category_definition.dart`
- Modify: `lib/domain/model/category.dart`
- Test: `test/domain/model/category_definition_test.dart`
- Test: `test/domain/model/category_test.dart`

**Interfaces:**
- Produces `EditableCategory`
- Produces `EditableCategory.create(...)`
- Produces `EditableCategory.displayPath({EditableCategory? parent})`
- Produces `CategoryValidationException`
- Produces `CategoryCatalog.builtInDefinitions`
- Produces `CategoryCatalog.builtInDisplayNameFor(String categoryId)`

- [ ] **Step 1: Write failing domain tests**

Create `test/domain/model/category_definition_test.dart`:

```dart
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
    final parent = _category(
      id: 'expense.food',
      name: '餐飲',
      parentId: null,
    );
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
```

Extend `test/domain/model/category_test.dart`:

```dart
test('exposes built-in seed definitions for migration', () {
  expect(
    CategoryCatalog.builtInDefinitions.map((category) => category.id),
    containsAll(<String>['expense.food', 'income.salary']),
  );
  expect(CategoryCatalog.builtInDisplayNameFor('expense.food'), '餐飲');
});
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test test/domain/model/category_definition_test.dart test/domain/model/category_test.dart
```

Expected: fail because `category_definition.dart`, `EditableCategory`, and new seed APIs do not exist.

- [ ] **Step 3: Implement domain model**

Create `lib/domain/model/category_definition.dart` with:

- immutable `EditableCategory`
- `CategoryValidationException`
- `maxNameCodePoints = 30`
- UUID-or-built-in ID validation
- `displayPath({EditableCategory? parent})`

Modify `lib/domain/model/category.dart` so `CategoryCatalog` remains backward-compatible and exposes:

```dart
static const List<TransactionCategory> builtInDefinitions = allCategories;

static String builtInDisplayNameFor(String categoryId) {
  return displayNameFor(categoryId);
}
```

- [ ] **Step 4: Run tests to verify pass**

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test test/domain/model/category_definition_test.dart test/domain/model/category_test.dart
```

Expected: pass.

- [ ] **Step 5: Commit**

```sh
git add lib/domain/model/category_definition.dart lib/domain/model/category.dart test/domain/model/category_definition_test.dart test/domain/model/category_test.dart
git commit -m "feat: add editable category domain model"
git push
```

## Task 2: Category repository contract and in-memory test implementation

**Files:**
- Create: `lib/domain/repository/category_repository.dart`
- Create: `test/domain/repository/category_repository_contract_test.dart`
- Modify: `test/presentation/test_app_harness.dart`

**Interfaces:**
- Consumes `EditableCategory`
- Produces `CategoryRepository`
- Produces `CreateCategoryRequest`
- Produces `RenameCategoryRequest`
- Produces `ArchiveCategoryRequest`
- Produces `CategoryRepositoryException`
- Produces `TestCategoryRepository`

- [ ] **Step 1: Write failing repository contract tests**

Create `test/domain/repository/category_repository_contract_test.dart` with reusable tests that accept a repository factory:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/domain/repository/category_repository.dart';

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
      (await repository.listActive(TransactionType.expense))
          .map((item) => item.id),
      isNot(contains(category.id)),
    );
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test test/domain/repository/category_repository_contract_test.dart
```

Expected: fail because repository interfaces do not exist.

- [ ] **Step 3: Implement repository contract and test harness repository**

Create `lib/domain/repository/category_repository.dart` with:

```dart
abstract interface class CategoryRepository {
  Future<List<EditableCategory>> listActive(TransactionType type);
  Future<List<EditableCategory>> listAll(TransactionType type);
  Future<EditableCategory?> findById(String id);
  Future<String> displayPathFor(String id);
  Future<EditableCategory> create(CreateCategoryRequest request);
  Future<EditableCategory> rename({
    required String id,
    required String name,
  });
  Future<void> archive(String id);
}
```

Add immutable request classes and `CategoryRepositoryException`.

Modify `test/presentation/test_app_harness.dart` to add `TestCategoryRepository` implementing the contract in memory. Seed built-ins by default for existing widget tests.

- [ ] **Step 4: Add harness contract invocation and verify pass**

Create `test/domain/repository/in_memory_category_repository_test.dart`:

```dart
import '../repository/category_repository_contract_test.dart';
import '../../presentation/test_app_harness.dart';

void main() {
  categoryRepositoryContract(
    createRepository: () async => TestCategoryRepository(seedBuiltIns: false),
  );
}
```

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test test/domain/repository/category_repository_contract_test.dart test/domain/repository/in_memory_category_repository_test.dart
```

Expected: pass.

- [ ] **Step 5: Commit**

```sh
git add lib/domain/repository/category_repository.dart test/domain/repository/category_repository_contract_test.dart test/domain/repository/in_memory_category_repository_test.dart test/presentation/test_app_harness.dart
git commit -m "feat: add category repository contract"
git push
```

## Task 3: Drift categories table, migration, seed, and repository

**Files:**
- Modify: `lib/data/database/networthy_database.dart`
- Regenerate: `lib/data/database/networthy_database.g.dart`
- Create: `lib/data/repository/drift_category_repository.dart`
- Create: `test/data/repository/drift_category_repository_test.dart`
- Modify: `test/data/database/networthy_database_migration_test.dart`

**Interfaces:**
- Consumes `CategoryRepository`
- Produces `Categories` Drift table
- Produces schema version 2
- Produces `DriftCategoryRepository`
- Produces idempotent `ensureBuiltInCategoriesSeeded()`

- [ ] **Step 1: Write failing Drift repository tests**

Create `test/data/repository/drift_category_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/data/database/networthy_database.dart';
import 'package:networthy/data/repository/drift_category_repository.dart';
import 'package:networthy/domain/model/transaction_type.dart';
import 'package:networthy/domain/repository/category_repository.dart';

import '../../domain/repository/category_repository_contract_test.dart';

void main() {
  categoryRepositoryContract(
    createRepository: () async {
      final database = NetworthyDatabase.inMemory();
      addTearDown(database.close);
      final repository = DriftCategoryRepository(database);
      return repository;
    },
  );

  test('seeds built-in categories idempotently without overwriting names', () async {
    final database = NetworthyDatabase.inMemory();
    addTearDown(database.close);
    final repository = DriftCategoryRepository(database);

    await repository.ensureBuiltInCategoriesSeeded();
    await repository.rename(id: 'expense.food', name: '吃飯');
    await repository.ensureBuiltInCategoriesSeeded();

    expect(await repository.displayPathFor('expense.food'), '吃飯');
    expect(
      (await repository.listAll(TransactionType.expense))
          .where((category) => category.id == 'expense.food'),
      hasLength(1),
    );
  });

  test('renames and archives persisted category', () async {
    final database = NetworthyDatabase.inMemory();
    addTearDown(database.close);
    final repository = DriftCategoryRepository(database);
    await repository.ensureBuiltInCategoriesSeeded();

    await repository.rename(id: 'expense.food', name: '吃飯');
    await repository.archive('expense.food');

    expect(await repository.displayPathFor('expense.food'), '吃飯');
    expect(
      (await repository.listActive(TransactionType.expense))
          .map((category) => category.id),
      isNot(contains('expense.food')),
    );
  });
}
```

Extend `test/data/database/networthy_database_migration_test.dart`:

```dart
test('migration to schema 2 seeds categories and preserves transactions', () async {
  final tempDir = await Directory.systemTemp.createTemp(
    'networthy-category-migration-',
  );
  addTearDown(() => tempDir.delete(recursive: true));
  final databaseFile = File('${tempDir.path}/networthy.db');

  final originalDatabase = NetworthyDatabase(NativeDatabase(databaseFile));
  addTearDown(originalDatabase.close);
  await DriftTransactionRepository(originalDatabase).save(
    BookkeepingTransaction.create(
      id: '00000000-0000-4000-8000-000000000309',
      type: TransactionType.expense,
      amountMinor: 777,
      categoryId: 'expense.food',
      transactionDate: LocalDate(2026, 8, 16),
      createdAtUtc: DateTime.utc(2026, 8, 16, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 16, 1),
    ),
  );
  await originalDatabase.close();

  final reopenedDatabase = NetworthyDatabase(NativeDatabase(databaseFile));
  addTearDown(reopenedDatabase.close);
  final transactions = DriftTransactionRepository(reopenedDatabase);
  final categories = DriftCategoryRepository(reopenedDatabase);
  await categories.ensureBuiltInCategoriesSeeded();

  final transaction = await transactions.findById(
    '00000000-0000-4000-8000-000000000309',
  );
  expect(transaction?.amountMinor, 777);
  expect(await categories.displayPathFor('expense.food'), '餐飲');
});
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test test/data/repository/drift_category_repository_test.dart test/data/database/networthy_database_migration_test.dart
```

Expected: fail because categories table/repository do not exist.

- [ ] **Step 3: Add Drift table and migration**

Modify `lib/data/database/networthy_database.dart`:

- Add `Categories extends Table`.
- Include `Categories` in `@DriftDatabase`.
- Increment `schemaVersion` from 1 to 2.
- In `onCreate`, call `migrator.createAll()`; seeding remains in repository/bootstrap.
- In `onUpgrade`, if `from < 2`, call `migrator.createTable(categories)`.

Run generated code:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Implement DriftCategoryRepository**

Create `lib/data/repository/drift_category_repository.dart`:

- map storage `type` strings to/from `TransactionType`
- implement repository contract
- enforce duplicate active sibling name
- enforce parent existence
- enforce parent type match
- enforce one-level nesting
- seed built-ins idempotently
- compute display path with parent lookup
- mark archived categories, never hard-delete

- [ ] **Step 5: Run tests to verify pass**

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test test/data/repository/drift_category_repository_test.dart test/data/database/networthy_database_migration_test.dart
```

Expected: pass.

- [ ] **Step 6: Commit**

```sh
git add lib/data/database/networthy_database.dart lib/data/database/networthy_database.g.dart lib/data/repository/drift_category_repository.dart test/data/repository/drift_category_repository_test.dart test/data/database/networthy_database_migration_test.dart
git commit -m "feat: persist editable categories"
git push
```

## Task 4: Application category validation for add/edit transactions

**Files:**
- Modify: `lib/application/transaction/add_transaction_use_case.dart`
- Modify: `lib/application/transaction/edit_transaction_use_case.dart`
- Modify: `lib/application/transaction/bookkeeping_flow_controller.dart` if it constructs `AddTransactionUseCase` or `EditTransactionUseCase`; pass the same `CategoryRepository` dependency through its constructor.
- Test: `test/application/transaction/category_validated_transaction_use_cases_test.dart`
- Modify existing transaction use case tests for new category repository dependency.

**Interfaces:**
- Consumes `CategoryRepository.findById`
- Existing transaction command remains unchanged.
- Add/edit rejects missing or archived category with safe validation failure.

- [ ] **Step 1: Write failing application tests**

Create `test/application/transaction/category_validated_transaction_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/application/transaction/add_transaction_use_case.dart';
import 'package:networthy/application/transaction/edit_transaction_use_case.dart';
import 'package:networthy/application/transaction/transaction_command.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';

import '../../presentation/test_app_harness.dart';

void main() {
  test('add rejects unknown category', () async {
    final categories = TestCategoryRepository(seedBuiltIns: false);
    final transactions = TestTransactionRepository();

    final result = await AddTransactionUseCase(
      transactions: transactions,
      settings: TestSettingsRepository(),
      categories: categories,
      clock: TestClock(DateTime.utc(2026, 8, 16, 1)),
      idGenerator: TestIdGenerator(['00000000-0000-4000-8000-000000000401']),
    ).execute(_command(categoryId: 'missing'));

    expect(result.failure?.safeMessage, '請選擇有效分類。');
    expect(transactions.values, isEmpty);
  });

  test('edit rejects archived category', () async {
    final categories = TestCategoryRepository();
    await categories.archive('expense.food');
    final transactions = TestTransactionRepository();
    await transactions.save(
      BookkeepingTransaction.create(
        id: '00000000-0000-4000-8000-000000000402',
        type: TransactionType.expense,
        amountMinor: 100,
        categoryId: 'expense.transport',
        transactionDate: LocalDate(2026, 8, 16),
        createdAtUtc: DateTime.utc(2026, 8, 16, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 16, 1),
      ),
    );

    final result = await EditTransactionUseCase(
      transactions: transactions,
      settings: TestSettingsRepository(),
      categories: categories,
      clock: TestClock(DateTime.utc(2026, 8, 16, 2)),
    ).execute(
      id: '00000000-0000-4000-8000-000000000402',
      command: _command(categoryId: 'expense.food'),
    );

    expect(result.failure?.safeMessage, '請選擇有效分類。');
  });
}

TransactionCommand _command({required String categoryId}) {
  return TransactionCommand(
    type: TransactionType.expense,
    amountMinor: 100,
    categoryId: categoryId,
    transactionDate: LocalDate(2026, 8, 16),
    note: null,
  );
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test test/application/transaction/category_validated_transaction_use_cases_test.dart test/application/transaction/transaction_command_use_cases_test.dart
```

Expected: fail because use cases do not accept category repository.

- [ ] **Step 3: Implement category validation**

Modify add/edit use case constructors to require `CategoryRepository categories`.

Before creating/saving a transaction:

- `findById(command.categoryId)` must return category.
- category must not be archived for new selected category.
- category type must match command type.
- on failure return `ApplicationFailure.persistence('請選擇有效分類。')` if `ApplicationFailure` still has only typed persistence/decryption constructors; if a validation constructor already exists when executing this task, use that exact validation constructor.

Update `BookkeepingFlowController` when it directly constructs add/edit use cases; otherwise leave it unchanged and note that add/edit dependencies are provided elsewhere.

- [ ] **Step 4: Update existing tests and verify pass**

Update existing application tests to pass `TestCategoryRepository()`.

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test test/application/transaction
```

Expected: pass.

- [ ] **Step 5: Commit**

```sh
git add lib/application/transaction/add_transaction_use_case.dart lib/application/transaction/edit_transaction_use_case.dart lib/application/transaction/bookkeeping_flow_controller.dart test/application/transaction/category_validated_transaction_use_cases_test.dart test/application/transaction
git commit -m "feat: validate transaction categories"
git push
```

## Task 5: App dependency injection and repository-backed category display

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/presentation/app/networthy_app.dart`
- Modify: `lib/presentation/home/home_shell.dart`
- Modify: `lib/presentation/overview/overview_page.dart`
- Modify: `lib/presentation/records/records_page.dart`
- Modify: `lib/presentation/transaction/transaction_form_page.dart`
- Modify: `test/presentation/test_app_harness.dart`
- Modify: `test/presentation/overview/overview_widget_test.dart`
- Modify: `test/presentation/records/records_page_widget_test.dart`
- Modify: `test/presentation/transaction/transaction_form_widget_test.dart`

**Interfaces:**
- Consumes `CategoryRepository`.
- Presentation pages resolve display paths through repository.
- Transaction form loads active categories.
- Transaction form includes archived selected category only when editing an existing transaction.

- [ ] **Step 1: Write failing presentation tests**

Extend existing widget tests:

`test/presentation/transaction/transaction_form_widget_test.dart`:

```dart
testWidgets('archived selected category remains visible while editing', (tester) async {
  final categories = TestCategoryRepository();
  await categories.archive('expense.food');
  final transactions = TestTransactionRepository();
  await transactions.save(
    BookkeepingTransaction.create(
      id: '00000000-0000-4000-8000-000000000501',
      type: TransactionType.expense,
      amountMinor: 100,
      categoryId: 'expense.food',
      transactionDate: LocalDate(2026, 8, 16),
      note: 'old food',
      createdAtUtc: DateTime.utc(2026, 8, 16, 1),
      updatedAtUtc: DateTime.utc(2026, 8, 16, 1),
    ),
  );

  await tester.pumpWidget(_app(transactions: transactions, categories: categories));
  await tester.pumpAndSettle();
  await tester.tap(find.text('old food'));
  await tester.pumpAndSettle();

  expect(find.text('餐飲（已封存）'), findsOneWidget);
});
```

`test/presentation/overview/overview_widget_test.dart`:

```dart
testWidgets('overview uses renamed category display path', (tester) async {
  final categories = TestCategoryRepository();
  await categories.rename(id: 'expense.food', name: '吃飯');
  // Save expense.food transaction and expect 吃飯 NT$...
});
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test test/presentation/overview/overview_widget_test.dart test/presentation/records/records_page_widget_test.dart test/presentation/transaction/transaction_form_widget_test.dart
```

Expected: fail because app/pages do not accept category repository and still use static catalog display.

- [ ] **Step 3: Inject category repository**

Modify constructors:

- `NetworthyApp(categories: CategoryRepository)`
- `_AppGate(categories: ...)`
- `HomeShell(categories: ...)`
- `OverviewPage(categories: ...)`
- `RecordsPage(categories: ...)`
- `TransactionFormPage(categories: ...)`

Modify `lib/main.dart`:

- create `final categories = DriftCategoryRepository(database);`
- call `await categories.ensureBuiltInCategoriesSeeded();`
- pass categories into `_AppDependencies` and `NetworthyApp`.

- [ ] **Step 4: Update display and form loading**

Overview:

- Load monthly summary, latest transactions, and category display paths.
- For category totals, display repository-backed names.

Records:

- Load records and category display paths.
- Delete fallback uses display path.

Transaction form:

- `FutureBuilder` active category list.
- For add mode, only active categories.
- For edit mode, include selected archived category with label `（已封存）`.
- Save still passes selected category ID.

- [ ] **Step 5: Run presentation tests**

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test test/presentation
```

Expected: pass.

- [ ] **Step 6: Commit**

```sh
git add lib/main.dart lib/presentation/app/networthy_app.dart lib/presentation/home/home_shell.dart lib/presentation/overview/overview_page.dart lib/presentation/records/records_page.dart lib/presentation/transaction/transaction_form_page.dart test/presentation
git commit -m "feat: use repository-backed category display"
git push
```

## Task 6: Category management settings UI

**Files:**
- Modify: `lib/presentation/settings/settings_page.dart`
- Create: `lib/presentation/settings/category_management_page.dart`
- Create: `test/presentation/settings/category_management_widget_test.dart`
- Modify: `test/presentation/settings/settings_page_widget_test.dart`

**Interfaces:**
- Consumes `CategoryRepository`.
- Produces `CategoryManagementPage`.
- Settings page opens category management.

- [ ] **Step 1: Write failing widget tests**

Create `test/presentation/settings/category_management_widget_test.dart`:

```dart
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
      (await categories.listAll(TransactionType.expense))
          .map((category) => category.name),
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
```

Add a test in `settings_page_widget_test.dart`:

```dart
testWidgets('settings opens category management', (tester) async {
  await tester.pumpWidget(_settingsApp(categories: TestCategoryRepository()));
  await tester.pumpAndSettle();
  await tester.tap(find.text('分類管理'));
  await tester.pumpAndSettle();
  expect(find.text('支出分類'), findsOneWidget);
});
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test test/presentation/settings/category_management_widget_test.dart test/presentation/settings/settings_page_widget_test.dart
```

Expected: fail because category management page does not exist.

- [ ] **Step 3: Implement category management page**

Create `CategoryManagementPage`:

- AppBar title `分類管理`
- tabs or sections for `支出分類` and `收入分類`
- list active categories
- display child categories as `Parent / Child`
- buttons:
  - `新增支出分類`
  - `新增收入分類`
  - tooltip `新增 <name> 的子分類`
  - tooltip `重新命名 <name>`
  - tooltip `封存 <name>`
- dialog with `Key('category-name-field')`
- safe validation messages from spec

Modify `SettingsPage`:

- accept `CategoryRepository categories`
- add ListTile `分類管理`
- navigate to `CategoryManagementPage(categories: categories)`

- [ ] **Step 4: Run settings tests**

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test test/presentation/settings
```

Expected: pass.

- [ ] **Step 5: Commit**

```sh
git add lib/presentation/settings/settings_page.dart lib/presentation/settings/category_management_page.dart test/presentation/settings/category_management_widget_test.dart test/presentation/settings/settings_page_widget_test.dart
git commit -m "feat: add category management UI"
git push
```

## Task 7: Clear-all-data category reset and verification docs

**Files:**
- Modify: `lib/data/repository/clear_local_data.dart` only if implementation stores category metadata outside the encrypted database file; otherwise leave it unchanged.
- Modify: `test/data/repository/clear_local_data_test.dart`
- Modify: `docs/problems/v0.1.0.md`
- Create: `docs/verification/v0.2.0-custom-categories.md`

**Interfaces:**
- Database file deletion continues to remove persisted category rows.
- Built-ins reseed on next app start through bootstrap/repository seed.

- [ ] **Step 1: Write/adjust clear-data test**

If categories live only in the encrypted database, keep `test/data/repository/clear_local_data_test.dart` unchanged and record in `docs/verification/v0.2.0-custom-categories.md` that database-file deletion removes category rows. If implementation stores category metadata outside the encrypted database, extend the test to create that metadata and assert it is removed by `ClearLocalData.clear()`.

- [ ] **Step 2: Add verification doc**

Create `docs/verification/v0.2.0-custom-categories.md`:

````markdown
# v0.2.0 Verification: Custom Categories and Subcategories

## Automated commands

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test
FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
```

## Manual script

1. Open Settings → 分類管理.
2. Add expense category `飲料`.
3. Add child category `咖啡` under `飲料`.
4. Add a transaction with `飲料 / 咖啡`.
5. Confirm overview and records show `飲料 / 咖啡`.
6. Rename `咖啡` to `拿鐵`.
7. Confirm historical transaction display updates to `飲料 / 拿鐵`.
8. Archive `拿鐵`.
9. Confirm new transaction form no longer offers `飲料 / 拿鐵`.
10. Confirm old transaction still displays `飲料 / 拿鐵（已封存）` when editing.
11. Clear all data and restart.
12. Confirm built-in categories appear again.
````

Update `docs/problems/v0.1.0.md` status for problem 3.

- [ ] **Step 3: Run final tests**

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test
FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
```

Expected: both pass.

- [ ] **Step 4: Commit**

```sh
git add docs/problems/v0.1.0.md docs/verification/v0.2.0-custom-categories.md test/data/repository/clear_local_data_test.dart lib/data/repository/clear_local_data.dart
git commit -m "docs: verify custom categories"
git push
```

## Task 8: Release acceptance builds

**Files:**
- Modify: `docs/verification/v0.2.0-custom-categories.md`

**Interfaces:**
- Produces Android release APK.
- Produces iOS simulator app bundle.

- [ ] **Step 1: Run release build gates**

Run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter build apk --release
FLUTTER_SUPPRESS_ANALYTICS=true flutter build ios --simulator
```

Expected:

- Android builds `build/app/outputs/flutter-apk/app-release.apk`
- iOS builds `build/ios/iphonesimulator/Runner.app`

- [ ] **Step 2: Record build results**

Append observed command results and artifact paths to `docs/verification/v0.2.0-custom-categories.md`.

- [ ] **Step 3: Final status and commit**

Run:

```sh
git diff --check
git status --short --branch
```

Expected: only intended v0.2.0 files staged/modified; `ios/Runner.xcodeproj/project.pbxproj` remains unstaged if it is still a local signing-only change.

Commit:

```sh
git add docs/verification/v0.2.0-custom-categories.md
git commit -m "docs: record custom category release acceptance"
git push
```

## Full final verification checklist

Run before declaring v0.2.0 complete:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test
FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
FLUTTER_SUPPRESS_ANALYTICS=true flutter build apk --release
FLUTTER_SUPPRESS_ANALYTICS=true flutter build ios --simulator
git diff --check
```

Expected final state:

- All tests pass.
- Analyzer reports no issues.
- Android release APK builds.
- iOS simulator build succeeds.
- Category management supports add, child add, rename, archive.
- Archived categories are hidden for new transactions but retained for historical display.
- Existing transactions with V1 IDs still display correctly after migration.
- Built-in categories seed idempotently and are not duplicated.
- Work is committed and pushed.
