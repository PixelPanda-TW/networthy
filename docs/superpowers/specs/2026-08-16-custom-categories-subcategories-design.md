# Custom Categories and Subcategories Design

- Version: v0.2.0 design
- Date: 2026-08-16
- Status: Approved direction, pending implementation plan

## Goal

Replace V1's hardcoded category catalog with editable local categories while preserving existing transactions and keeping V1's offline-first, encrypted-local-storage model.

## Scope

This release adds:

- A local `categories` data model.
- Seeded built-in income and expense categories.
- User-created top-level categories.
- User-created child categories.
- Category rename.
- Category archive.
- Category management entry point in Settings.
- Category display in transaction forms, overview, and records using stored category metadata.

This release does not add:

- Multi-account support.
- Multi-currency support.
- Transfers.
- Stock, asset, or investment accounts.
- Category icons or colors.
- Drag-and-drop category ordering.
- Hard deletion for categories referenced by transactions.
- Import/export or cloud sync.

## Current behavior

The app currently stores `categoryId` on each transaction and uses fixed IDs such as:

- `expense.food`
- `expense.transport`
- `income.salary`

v0.1.1 added Traditional Chinese display names for those fixed IDs, but the catalog is still static code. Users cannot rename categories, add categories, or create subcategories.

## Product behavior

### Category management

Settings adds a "分類管理" entry.

The category management screen has two sections:

- 支出分類
- 收入分類

Each section shows active categories in sort order. Child categories are displayed beneath their parent. A child category is shown as:

```text
餐飲 / 早餐
```

Users can:

- Add a top-level category.
- Add a child category under a top-level category.
- Rename an existing category.
- Archive a category.

Users cannot:

- Archive a category that still has active child categories.
- Create a child under a child category. v0.2.0 supports one level of nesting only.
- Create two active sibling categories with the same name under the same parent and type.
- Change a category's income/expense type after creation.
- Hard-delete a category.

### Transaction form

The transaction form category dropdown reads from active categories.

- Expense transactions show active expense categories.
- Income transactions show active income categories.
- Child categories display as `Parent / Child`.
- Stored transaction data remains the category ID.

When editing an old transaction whose category has since been archived:

- The archived category remains visible as the selected option.
- The option is marked with `（已封存）`.
- Other archived categories are not offered for new selection.

### Overview and records

Overview category totals and record rows resolve category IDs through the repository-backed category catalog.

If a transaction references an unknown category ID, the UI falls back to the raw ID. This is a recovery path, not normal behavior.

### Clear all data

Clear-all-data removes categories along with transactions, settings, and database/key material. On first launch after reset, built-in categories are seeded again.

## Data model

Add a Drift table `categories`.

Fields:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | text | yes | Stable category ID. Built-ins keep existing IDs. User-created IDs are UUID strings prefixed with `category.` or another stable app-owned namespace. |
| `type` | text | yes | `income` or `expense`. |
| `name` | text | yes | Display name, 1–30 Unicode code points after trim. |
| `parentId` | text nullable | no | Parent category ID. `null` means top-level. One nesting level only. |
| `sortOrder` | integer | yes | Product order within siblings. |
| `isArchived` | boolean | yes | Archived categories are hidden for new transactions but retained for old records. |
| `createdAtUtc` | dateTime | yes | UTC timestamp. |
| `updatedAtUtc` | dateTime | yes | UTC timestamp. |

Indexes and constraints:

- Primary key: `id`.
- Index: `(type, parentId, sortOrder)`.
- Runtime validation enforces unique active sibling names by `(type, parentId, normalizedName)`.
- Runtime validation prevents a child category from having a parent that is itself a child.
- Runtime validation prevents parent/type mismatch.

## Built-in category seed

Seed existing V1 IDs as top-level categories:

Expense:

- `expense.food`: 餐飲
- `expense.transport`: 交通
- `expense.shopping`: 購物
- `expense.housing`: 居住
- `expense.entertainment`: 娛樂
- `expense.medical`: 醫療
- `expense.education`: 教育
- `expense.other`: 其他

Income:

- `income.salary`: 薪資
- `income.bonus`: 獎金
- `income.investment`: 投資
- `income.other`: 其他

The seed is idempotent:

- If a built-in category row does not exist, insert it.
- If a built-in row exists, do not overwrite user changes to `name`, `sortOrder`, or `isArchived`.

## Migration

Add a schema migration that creates the `categories` table and seeds built-in categories.

Existing transactions are preserved unchanged because their `categoryId` values already match the built-in seed IDs.

## Architecture

### Domain

Add domain model and validation for:

- `Category`
- `CategoryType`
- `CategoryTree`
- category name validation
- parent/child compatibility

Domain code remains pure Dart and must not import Flutter, Drift, sqlite3, secure storage, or platform packages.

### Repository

Add `CategoryRepository` with operations:

- `listActive(type)`
- `listAll(type)`
- `findById(id)`
- `create(request)`
- `rename(id, newName)`
- `archive(id)`

Transaction validation no longer depends only on a hardcoded category catalog. Application use cases validate category existence through `CategoryRepository` before saving a transaction.

### Data

Add Drift repository implementation:

- Maps category rows to domain categories.
- Seeds built-ins during database opening/migration.
- Enforces persistence-level lookup for old transaction display.

### Presentation

Presentation receives a `CategoryRepository` or application-level category use cases through app dependency injection.

Screens that display category names do not use raw `categoryId` directly:

- Overview
- Records
- Transaction form
- Settings category management

## Error handling

- Duplicate active sibling name: show `同層分類名稱已存在。`
- Empty category name: show `請輸入分類名稱。`
- Name over 30 Unicode code points: show `分類名稱最多 30 個字。`
- Archive category with active children: show `請先封存子分類。`
- Archive category already used by transactions: allow archive, keep historical display.
- Unknown category when saving a transaction: show `請選擇有效分類。`
- Repository failure: show a safe generic message without database paths or raw exception details.

## Testing

Automated tests must cover:

- Built-in category seed is idempotent.
- Existing transactions with V1 IDs still display category names after migration.
- Creating a top-level category.
- Creating a child category.
- Rejecting duplicate active sibling names.
- Rejecting child-under-child.
- Renaming a category updates future display.
- Archiving hides category from new transaction dropdown.
- Archived category remains visible when editing a transaction that already uses it.
- Clear-all-data removes category rows and reseeds built-ins after reset.
- Presentation does not show raw IDs for known categories.

Manual acceptance:

- Create an expense child category such as `餐飲 / 早餐`.
- Add a transaction with that child category.
- Confirm overview and records display `餐飲 / 早餐`.
- Rename `早餐` to `早午餐`.
- Confirm historical transaction display updates to `餐飲 / 早午餐`.
- Archive `早午餐`.
- Confirm new transaction form no longer offers it.
- Confirm old transaction still displays it.

## Rollout notes

This is a local schema change. Before distributing externally, run:

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flutter test
FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
FLUTTER_SUPPRESS_ANALYTICS=true flutter build apk --release
FLUTTER_SUPPRESS_ANALYTICS=true flutter build ios --simulator
```

The next major feature after this should be multi-account support. Multi-account design should consume this category model rather than reintroducing hardcoded category display logic.

