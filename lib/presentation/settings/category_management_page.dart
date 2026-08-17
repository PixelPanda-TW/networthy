import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/model/category_definition.dart';
import '../../domain/model/transaction_type.dart';
import '../../domain/repository/category_repository.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key, required this.categories});

  final CategoryRepository categories;

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  late Future<_CategoryManagementData> _dataFuture;
  String? _safeMessage;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分類管理')),
      body: FutureBuilder<_CategoryManagementData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Text('載入中'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('分類載入失敗'));
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CategorySection(
                title: '支出分類',
                addButtonLabel: '新增支出分類',
                categories: data.expenses,
                displayPaths: data.displayPaths,
                onAdd: () => _create(type: TransactionType.expense),
                onAddChild: (category) => _create(
                  type: category.type,
                  parentId: category.id,
                  parentName: category.name,
                ),
                onRename: _rename,
                onArchive: _confirmArchive,
              ),
              const SizedBox(height: 24),
              _CategorySection(
                title: '收入分類',
                addButtonLabel: '新增收入分類',
                categories: data.incomes,
                displayPaths: data.displayPaths,
                onAdd: () => _create(type: TransactionType.income),
                onAddChild: (category) => _create(
                  type: category.type,
                  parentId: category.id,
                  parentName: category.name,
                ),
                onRename: _rename,
                onArchive: _confirmArchive,
              ),
              if (_safeMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _safeMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<_CategoryManagementData> _load() async {
    final expenses = await widget.categories.listActive(
      TransactionType.expense,
    );
    final incomes = await widget.categories.listActive(TransactionType.income);
    final all = [...expenses, ...incomes];
    final displayPathEntries = await Future.wait(
      all.map(
        (category) async => MapEntry(
          category.id,
          await widget.categories.displayPathFor(category.id),
        ),
      ),
    );
    return _CategoryManagementData(
      expenses: expenses,
      incomes: incomes,
      displayPaths: Map<String, String>.fromEntries(displayPathEntries),
    );
  }

  Future<void> _create({
    required TransactionType type,
    String? parentId,
    String? parentName,
  }) async {
    final name = await _showNameDialog(
      title: parentName == null ? '新增分類' : '新增 $parentName 的子分類',
    );
    if (name == null) {
      return;
    }
    await _runRepositoryAction(
      () => widget.categories.create(
        CreateCategoryRequest(
          id: 'category.${_CategoryIdGenerator().generateUuidV4()}',
          type: type,
          name: name,
          parentId: parentId,
        ),
      ),
    );
  }

  Future<void> _rename(EditableCategory category) async {
    final name = await _showNameDialog(
      title: '重新命名分類',
      initialName: category.name,
    );
    if (name == null) {
      return;
    }
    await _runRepositoryAction(
      () => widget.categories.rename(id: category.id, name: name),
    );
  }

  Future<void> _confirmArchive(EditableCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('封存分類'),
        content: Text('確定要封存「${category.name}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('封存'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await _runRepositoryAction(() => widget.categories.archive(category.id));
  }

  Future<String?> _showNameDialog({
    required String title,
    String? initialName,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) =>
          _CategoryNameDialog(title: title, initialName: initialName),
    );
  }

  Future<void> _runRepositoryAction(Future<Object?> Function() action) async {
    try {
      await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _safeMessage = null;
        _dataFuture = _load();
      });
    } on CategoryRepositoryException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _safeMessage = error.safeMessage);
    } on CategoryValidationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _safeMessage = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _safeMessage = '分類操作失敗，請稍後再試。');
    }
  }
}

class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({required this.title, this.initialName});

  final String title;
  final String? initialName;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('category-name-field'),
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '分類名稱'),
          validator: (value) {
            final normalized = value?.trim() ?? '';
            if (normalized.isEmpty) {
              return '請輸入分類名稱';
            }
            if (normalized.runes.length > EditableCategory.maxNameCodePoints) {
              return '分類名稱不可超過 30 個字';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: const Text('儲存'),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.addButtonLabel,
    required this.categories,
    required this.displayPaths,
    required this.onAdd,
    required this.onAddChild,
    required this.onRename,
    required this.onArchive,
  });

  final String title;
  final String addButtonLabel;
  final List<EditableCategory> categories;
  final Map<String, String> displayPaths;
  final VoidCallback onAdd;
  final ValueChanged<EditableCategory> onAddChild;
  final ValueChanged<EditableCategory> onRename;
  final ValueChanged<EditableCategory> onArchive;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = _categoriesForDisplay(categories);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FilledButton.tonal(onPressed: onAdd, child: Text(addButtonLabel)),
        const SizedBox(height: 8),
        if (visibleCategories.isEmpty)
          const Text('目前沒有分類')
        else
          for (final category in visibleCategories)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(displayPaths[category.id] ?? category.name),
              trailing: Wrap(
                spacing: 4,
                children: [
                  if (category.parentId == null)
                    IconButton(
                      tooltip: '新增 ${category.name} 的子分類',
                      onPressed: () => onAddChild(category),
                      icon: const Icon(Icons.add),
                    ),
                  IconButton(
                    tooltip: '重新命名 ${category.name}',
                    onPressed: () => onRename(category),
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    tooltip: '封存 ${category.name}',
                    onPressed: () => onArchive(category),
                    icon: const Icon(Icons.archive_outlined),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  List<EditableCategory> _categoriesForDisplay(
    List<EditableCategory> categories,
  ) {
    final childrenByParentId = <String, List<EditableCategory>>{};
    final topLevel = <EditableCategory>[];
    for (final category in categories) {
      final parentId = category.parentId;
      if (parentId == null) {
        topLevel.add(category);
      } else {
        childrenByParentId.putIfAbsent(parentId, () => []).add(category);
      }
    }

    int compareCategory(EditableCategory a, EditableCategory b) {
      final customComparison = _displayPriority(
        a,
      ).compareTo(_displayPriority(b));
      if (customComparison != 0) {
        return customComparison;
      }
      final sortComparison = a.sortOrder.compareTo(b.sortOrder);
      if (sortComparison != 0) {
        return sortComparison;
      }
      return a.name.compareTo(b.name);
    }

    topLevel.sort(compareCategory);
    for (final children in childrenByParentId.values) {
      children.sort(compareCategory);
    }

    return [
      for (final parent in topLevel) ...[
        parent,
        ...?childrenByParentId[parent.id],
      ],
    ];
  }

  int _displayPriority(EditableCategory category) {
    return category.id.startsWith('category.') ? 0 : 1;
  }
}

class _CategoryManagementData {
  const _CategoryManagementData({
    required this.expenses,
    required this.incomes,
    required this.displayPaths,
  });

  final List<EditableCategory> expenses;
  final List<EditableCategory> incomes;
  final Map<String, String> displayPaths;
}

class _CategoryIdGenerator {
  _CategoryIdGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  String generateUuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
