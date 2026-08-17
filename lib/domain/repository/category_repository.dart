import '../model/category_definition.dart';
import '../model/transaction_type.dart';

abstract interface class CategoryRepository {
  Future<List<EditableCategory>> listActive(TransactionType type);

  Future<List<EditableCategory>> listAll(TransactionType type);

  Future<EditableCategory?> findById(String id);

  Future<String> displayPathFor(String id);

  Future<EditableCategory> create(CreateCategoryRequest request);

  Future<EditableCategory> rename({required String id, required String name});

  Future<void> archive(String id);
}

class CreateCategoryRequest {
  const CreateCategoryRequest({
    required this.id,
    required this.type,
    required this.name,
    required this.parentId,
  });

  final String id;
  final TransactionType type;
  final String name;
  final String? parentId;
}

class RenameCategoryRequest {
  const RenameCategoryRequest({required this.id, required this.name});

  final String id;
  final String name;
}

class ArchiveCategoryRequest {
  const ArchiveCategoryRequest({required this.id});

  final String id;
}

class CategoryRepositoryException implements Exception {
  const CategoryRepositoryException(this.safeMessage);

  final String safeMessage;

  @override
  String toString() => 'CategoryRepositoryException: $safeMessage';
}
