import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'networthy_database.g.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text()();
  TextColumn get categoryId => text()();
  IntColumn get transactionYear => integer()();
  IntColumn get transactionMonth => integer()();
  IntColumn get transactionDay => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettingsRows extends Table {
  IntColumn get id => integer()();
  BoolColumn get onboardingCompleted => boolean()();
  BoolColumn get biometricLockEnabled => boolean()();
  TextColumn get currencyCode => text()();
  TextColumn get lastExpenseCategoryId => text().nullable()();
  TextColumn get lastIncomeCategoryId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isArchived => boolean()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Transactions, AppSettingsRows, Categories])
class NetworthyDatabase extends _$NetworthyDatabase {
  NetworthyDatabase(super.executor);

  NetworthyDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(categories);
      }
    },
  );
}
