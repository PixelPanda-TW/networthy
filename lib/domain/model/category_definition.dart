import 'category.dart';
import 'transaction_type.dart';

class CategoryValidationException implements Exception {
  const CategoryValidationException(this.message);

  final String message;

  @override
  String toString() => 'CategoryValidationException: $message';
}

class EditableCategory {
  const EditableCategory._({
    required this.id,
    required this.type,
    required this.name,
    required this.parentId,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  static const int maxNameCodePoints = 30;

  final String id;
  final TransactionType type;
  final String name;
  final String? parentId;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  factory EditableCategory.create({
    required String id,
    required TransactionType type,
    required String name,
    required String? parentId,
    required int sortOrder,
    required bool isArchived,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) {
    _validateId(id);
    final normalizedName = _validateName(name);
    _validateParentId(parentId);
    _validateUtcTimestamp(createdAtUtc, 'createdAtUtc');
    _validateUtcTimestamp(updatedAtUtc, 'updatedAtUtc');

    return EditableCategory._(
      id: id,
      type: type,
      name: normalizedName,
      parentId: parentId,
      sortOrder: sortOrder,
      isArchived: isArchived,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
    );
  }

  String displayPath({EditableCategory? parent}) {
    if (parentId == null) {
      return name;
    }
    if (parent == null) {
      return name;
    }
    return '${parent.name} / $name';
  }

  static void _validateId(String id) {
    final isBuiltIn = CategoryCatalog.allCategories.any(
      (category) => category.id == id,
    );
    if (isBuiltIn) {
      return;
    }
    final userCategoryPattern = RegExp(
      r'^category\.[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    if (!userCategoryPattern.hasMatch(id)) {
      throw const CategoryValidationException(
        'Category id must be a built-in id or category-prefixed UUID.',
      );
    }
  }

  static String _validateName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw const CategoryValidationException('Category name is required.');
    }
    if (normalized.runes.length > maxNameCodePoints) {
      throw const CategoryValidationException(
        'Category name exceeds 30 code points.',
      );
    }
    return normalized;
  }

  static void _validateParentId(String? parentId) {
    if (parentId == null) {
      return;
    }
    _validateId(parentId);
  }

  static void _validateUtcTimestamp(DateTime timestamp, String fieldName) {
    if (!timestamp.isUtc) {
      throw CategoryValidationException('$fieldName must be UTC.');
    }
  }
}
