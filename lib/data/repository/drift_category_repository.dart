import 'package:drift/drift.dart';

import '../../domain/model/category.dart';
import '../../domain/model/category_definition.dart';
import '../../domain/model/transaction_type.dart';
import '../../domain/repository/category_repository.dart';
import '../database/networthy_database.dart';

class DriftCategoryRepository implements CategoryRepository {
  const DriftCategoryRepository(this._database);

  final NetworthyDatabase _database;

  Future<void> ensureBuiltInCategoriesSeeded() async {
    final now = DateTime.now().toUtc();
    for (final entry in CategoryCatalog.builtInDefinitions.indexed) {
      final (index, category) = entry;
      final existing = await findById(category.id);
      if (existing != null) {
        continue;
      }
      await _database
          .into(_database.categories)
          .insert(
            CategoriesCompanion.insert(
              id: category.id,
              type: _storageValue(category.type),
              name: category.displayName,
              parentId: const Value(null),
              sortOrder: index,
              isArchived: false,
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
    }
  }

  @override
  Future<void> archive(String id) async {
    final category = await findById(id);
    if (category == null) {
      throw const CategoryRepositoryException('分類不存在。');
    }
    final activeChildren =
        await (_database.select(_database.categories)..where(
              (table) =>
                  table.parentId.equals(id) & table.isArchived.equals(false),
            ))
            .get();
    if (activeChildren.isNotEmpty) {
      throw const CategoryRepositoryException('請先封存子分類。');
    }

    await (_database.update(
      _database.categories,
    )..where((table) => table.id.equals(id))).write(
      CategoriesCompanion(
        isArchived: const Value(true),
        updatedAtUtc: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<EditableCategory> create(CreateCategoryRequest request) async {
    final existing = await findById(request.id);
    if (existing != null) {
      throw const CategoryRepositoryException('分類已存在。');
    }
    final parent = await _parentForCreate(request);
    await _ensureUniqueActiveSiblingName(
      type: request.type,
      parentId: request.parentId,
      name: request.name,
    );
    final now = DateTime.now().toUtc();
    final category = EditableCategory.create(
      id: request.id,
      type: request.type,
      name: request.name,
      parentId: parent?.id,
      sortOrder: await _nextSortOrder(
        type: request.type,
        parentId: request.parentId,
      ),
      isArchived: false,
      createdAtUtc: now,
      updatedAtUtc: now,
    );

    await _database.into(_database.categories).insert(_toCompanion(category));
    return category;
  }

  @override
  Future<String> displayPathFor(String id) async {
    final category = await findById(id);
    if (category == null) {
      return id;
    }
    final parent = category.parentId == null
        ? null
        : await findById(category.parentId!);
    return category.displayPath(parent: parent);
  }

  @override
  Future<EditableCategory?> findById(String id) async {
    final row = await (_database.select(
      _database.categories,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _toDomain(row);
  }

  @override
  Future<List<EditableCategory>> listActive(TransactionType type) async {
    final rows = await (_baseTypeQuery(
      type,
    )..where((table) => table.isArchived.equals(false))).get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<EditableCategory>> listAll(TransactionType type) async {
    final rows = await _baseTypeQuery(type).get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<EditableCategory> rename({
    required String id,
    required String name,
  }) async {
    final category = await findById(id);
    if (category == null) {
      throw const CategoryRepositoryException('分類不存在。');
    }
    await _ensureUniqueActiveSiblingName(
      type: category.type,
      parentId: category.parentId,
      name: name,
      excludingId: id,
    );
    final updated = EditableCategory.create(
      id: category.id,
      type: category.type,
      name: name,
      parentId: category.parentId,
      sortOrder: category.sortOrder,
      isArchived: category.isArchived,
      createdAtUtc: category.createdAtUtc,
      updatedAtUtc: DateTime.now().toUtc(),
    );

    await (_database.update(
      _database.categories,
    )..where((table) => table.id.equals(id))).write(_toCompanion(updated));
    return updated;
  }

  SimpleSelectStatement<$CategoriesTable, Category> _baseTypeQuery(
    TransactionType type,
  ) {
    return _database.select(_database.categories)
      ..where((table) => table.type.equals(_storageValue(type)))
      ..orderBy([
        (table) => OrderingTerm.asc(table.parentId),
        (table) => OrderingTerm.asc(table.sortOrder),
        (table) => OrderingTerm.asc(table.name),
      ]);
  }

  Future<EditableCategory?> _parentForCreate(
    CreateCategoryRequest request,
  ) async {
    final parentId = request.parentId;
    if (parentId == null) {
      return null;
    }
    final parent = await findById(parentId);
    if (parent == null) {
      throw const CategoryRepositoryException('父分類不存在。');
    }
    if (parent.type != request.type) {
      throw const CategoryRepositoryException('父分類類型不相容。');
    }
    if (parent.parentId != null) {
      throw const CategoryRepositoryException('子分類不能再建立子分類。');
    }
    if (parent.isArchived) {
      throw const CategoryRepositoryException('父分類已封存。');
    }
    return parent;
  }

  Future<void> _ensureUniqueActiveSiblingName({
    required TransactionType type,
    required String? parentId,
    required String name,
    String? excludingId,
  }) async {
    final normalized = name.trim();
    final rows =
        await (_database.select(_database.categories)..where(
              (table) =>
                  table.type.equals(_storageValue(type)) &
                  table.parentId.equalsNullable(parentId) &
                  table.isArchived.equals(false) &
                  table.name.equals(normalized),
            ))
            .get();
    final duplicate = rows.any((row) => row.id != excludingId);
    if (duplicate) {
      throw const CategoryRepositoryException('同層分類名稱已存在。');
    }
  }

  Future<int> _nextSortOrder({
    required TransactionType type,
    required String? parentId,
  }) async {
    final rows =
        await (_database.select(_database.categories)..where(
              (table) =>
                  table.type.equals(_storageValue(type)) &
                  table.parentId.equalsNullable(parentId),
            ))
            .get();
    if (rows.isEmpty) {
      return 0;
    }
    return rows.map((row) => row.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }

  CategoriesCompanion _toCompanion(EditableCategory category) {
    return CategoriesCompanion.insert(
      id: category.id,
      type: _storageValue(category.type),
      name: category.name,
      parentId: Value(category.parentId),
      sortOrder: category.sortOrder,
      isArchived: category.isArchived,
      createdAtUtc: category.createdAtUtc,
      updatedAtUtc: category.updatedAtUtc,
    );
  }

  EditableCategory _toDomain(Category row) {
    return EditableCategory.create(
      id: row.id,
      type: _typeFromStorage(row.type),
      name: row.name,
      parentId: row.parentId,
      sortOrder: row.sortOrder,
      isArchived: row.isArchived,
      createdAtUtc: row.createdAtUtc.toUtc(),
      updatedAtUtc: row.updatedAtUtc.toUtc(),
    );
  }

  String _storageValue(TransactionType type) {
    return switch (type) {
      TransactionType.income => 'income',
      TransactionType.expense => 'expense',
    };
  }

  TransactionType _typeFromStorage(String value) {
    return switch (value) {
      'income' => TransactionType.income,
      'expense' => TransactionType.expense,
      _ => throw StateError('Unknown category type.'),
    };
  }
}
