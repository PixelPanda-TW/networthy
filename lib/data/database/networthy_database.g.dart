// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'networthy_database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionYearMeta = const VerificationMeta(
    'transactionYear',
  );
  @override
  late final GeneratedColumn<int> transactionYear = GeneratedColumn<int>(
    'transaction_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionMonthMeta = const VerificationMeta(
    'transactionMonth',
  );
  @override
  late final GeneratedColumn<int> transactionMonth = GeneratedColumn<int>(
    'transaction_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionDayMeta = const VerificationMeta(
    'transactionDay',
  );
  @override
  late final GeneratedColumn<int> transactionDay = GeneratedColumn<int>(
    'transaction_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amountMinor,
    currencyCode,
    categoryId,
    transactionYear,
    transactionMonth,
    transactionDay,
    note,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('transaction_year')) {
      context.handle(
        _transactionYearMeta,
        transactionYear.isAcceptableOrUnknown(
          data['transaction_year']!,
          _transactionYearMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionYearMeta);
    }
    if (data.containsKey('transaction_month')) {
      context.handle(
        _transactionMonthMeta,
        transactionMonth.isAcceptableOrUnknown(
          data['transaction_month']!,
          _transactionMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionMonthMeta);
    }
    if (data.containsKey('transaction_day')) {
      context.handle(
        _transactionDayMeta,
        transactionDay.isAcceptableOrUnknown(
          data['transaction_day']!,
          _transactionDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionDayMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      transactionYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_year'],
      )!,
      transactionMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_month'],
      )!,
      transactionDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_day'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String type;
  final int amountMinor;
  final String currencyCode;
  final String categoryId;
  final int transactionYear;
  final int transactionMonth;
  final int transactionDay;
  final String? note;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const Transaction({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.currencyCode,
    required this.categoryId,
    required this.transactionYear,
    required this.transactionMonth,
    required this.transactionDay,
    this.note,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    map['category_id'] = Variable<String>(categoryId);
    map['transaction_year'] = Variable<int>(transactionYear);
    map['transaction_month'] = Variable<int>(transactionMonth);
    map['transaction_day'] = Variable<int>(transactionDay);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      type: Value(type),
      amountMinor: Value(amountMinor),
      currencyCode: Value(currencyCode),
      categoryId: Value(categoryId),
      transactionYear: Value(transactionYear),
      transactionMonth: Value(transactionMonth),
      transactionDay: Value(transactionDay),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      transactionYear: serializer.fromJson<int>(json['transactionYear']),
      transactionMonth: serializer.fromJson<int>(json['transactionMonth']),
      transactionDay: serializer.fromJson<int>(json['transactionDay']),
      note: serializer.fromJson<String?>(json['note']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'categoryId': serializer.toJson<String>(categoryId),
      'transactionYear': serializer.toJson<int>(transactionYear),
      'transactionMonth': serializer.toJson<int>(transactionMonth),
      'transactionDay': serializer.toJson<int>(transactionDay),
      'note': serializer.toJson<String?>(note),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  Transaction copyWith({
    String? id,
    String? type,
    int? amountMinor,
    String? currencyCode,
    String? categoryId,
    int? transactionYear,
    int? transactionMonth,
    int? transactionDay,
    Value<String?> note = const Value.absent(),
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => Transaction(
    id: id ?? this.id,
    type: type ?? this.type,
    amountMinor: amountMinor ?? this.amountMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    categoryId: categoryId ?? this.categoryId,
    transactionYear: transactionYear ?? this.transactionYear,
    transactionMonth: transactionMonth ?? this.transactionMonth,
    transactionDay: transactionDay ?? this.transactionDay,
    note: note.present ? note.value : this.note,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      transactionYear: data.transactionYear.present
          ? data.transactionYear.value
          : this.transactionYear,
      transactionMonth: data.transactionMonth.present
          ? data.transactionMonth.value
          : this.transactionMonth,
      transactionDay: data.transactionDay.present
          ? data.transactionDay.value
          : this.transactionDay,
      note: data.note.present ? data.note.value : this.note,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('categoryId: $categoryId, ')
          ..write('transactionYear: $transactionYear, ')
          ..write('transactionMonth: $transactionMonth, ')
          ..write('transactionDay: $transactionDay, ')
          ..write('note: $note, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amountMinor,
    currencyCode,
    categoryId,
    transactionYear,
    transactionMonth,
    transactionDay,
    note,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.type == this.type &&
          other.amountMinor == this.amountMinor &&
          other.currencyCode == this.currencyCode &&
          other.categoryId == this.categoryId &&
          other.transactionYear == this.transactionYear &&
          other.transactionMonth == this.transactionMonth &&
          other.transactionDay == this.transactionDay &&
          other.note == this.note &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> type;
  final Value<int> amountMinor;
  final Value<String> currencyCode;
  final Value<String> categoryId;
  final Value<int> transactionYear;
  final Value<int> transactionMonth;
  final Value<int> transactionDay;
  final Value<String?> note;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.transactionYear = const Value.absent(),
    this.transactionMonth = const Value.absent(),
    this.transactionDay = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String type,
    required int amountMinor,
    required String currencyCode,
    required String categoryId,
    required int transactionYear,
    required int transactionMonth,
    required int transactionDay,
    this.note = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       amountMinor = Value(amountMinor),
       currencyCode = Value(currencyCode),
       categoryId = Value(categoryId),
       transactionYear = Value(transactionYear),
       transactionMonth = Value(transactionMonth),
       transactionDay = Value(transactionDay),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<int>? amountMinor,
    Expression<String>? currencyCode,
    Expression<String>? categoryId,
    Expression<int>? transactionYear,
    Expression<int>? transactionMonth,
    Expression<int>? transactionDay,
    Expression<String>? note,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (categoryId != null) 'category_id': categoryId,
      if (transactionYear != null) 'transaction_year': transactionYear,
      if (transactionMonth != null) 'transaction_month': transactionMonth,
      if (transactionDay != null) 'transaction_day': transactionDay,
      if (note != null) 'note': note,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<int>? amountMinor,
    Value<String>? currencyCode,
    Value<String>? categoryId,
    Value<int>? transactionYear,
    Value<int>? transactionMonth,
    Value<int>? transactionDay,
    Value<String?>? note,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amountMinor: amountMinor ?? this.amountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      categoryId: categoryId ?? this.categoryId,
      transactionYear: transactionYear ?? this.transactionYear,
      transactionMonth: transactionMonth ?? this.transactionMonth,
      transactionDay: transactionDay ?? this.transactionDay,
      note: note ?? this.note,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (transactionYear.present) {
      map['transaction_year'] = Variable<int>(transactionYear.value);
    }
    if (transactionMonth.present) {
      map['transaction_month'] = Variable<int>(transactionMonth.value);
    }
    if (transactionDay.present) {
      map['transaction_day'] = Variable<int>(transactionDay.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('categoryId: $categoryId, ')
          ..write('transactionYear: $transactionYear, ')
          ..write('transactionMonth: $transactionMonth, ')
          ..write('transactionDay: $transactionDay, ')
          ..write('note: $note, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsRowsTable extends AppSettingsRows
    with TableInfo<$AppSettingsRowsTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _biometricLockEnabledMeta =
      const VerificationMeta('biometricLockEnabled');
  @override
  late final GeneratedColumn<bool> biometricLockEnabled = GeneratedColumn<bool>(
    'biometric_lock_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("biometric_lock_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastExpenseCategoryIdMeta =
      const VerificationMeta('lastExpenseCategoryId');
  @override
  late final GeneratedColumn<String> lastExpenseCategoryId =
      GeneratedColumn<String>(
        'last_expense_category_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastIncomeCategoryIdMeta =
      const VerificationMeta('lastIncomeCategoryId');
  @override
  late final GeneratedColumn<String> lastIncomeCategoryId =
      GeneratedColumn<String>(
        'last_income_category_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    onboardingCompleted,
    biometricLockEnabled,
    currencyCode,
    lastExpenseCategoryId,
    lastIncomeCategoryId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_onboardingCompletedMeta);
    }
    if (data.containsKey('biometric_lock_enabled')) {
      context.handle(
        _biometricLockEnabledMeta,
        biometricLockEnabled.isAcceptableOrUnknown(
          data['biometric_lock_enabled']!,
          _biometricLockEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_biometricLockEnabledMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('last_expense_category_id')) {
      context.handle(
        _lastExpenseCategoryIdMeta,
        lastExpenseCategoryId.isAcceptableOrUnknown(
          data['last_expense_category_id']!,
          _lastExpenseCategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('last_income_category_id')) {
      context.handle(
        _lastIncomeCategoryIdMeta,
        lastIncomeCategoryId.isAcceptableOrUnknown(
          data['last_income_category_id']!,
          _lastIncomeCategoryIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_completed'],
      )!,
      biometricLockEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}biometric_lock_enabled'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      lastExpenseCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_expense_category_id'],
      ),
      lastIncomeCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_income_category_id'],
      ),
    );
  }

  @override
  $AppSettingsRowsTable createAlias(String alias) {
    return $AppSettingsRowsTable(attachedDatabase, alias);
  }
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;
  final bool onboardingCompleted;
  final bool biometricLockEnabled;
  final String currencyCode;
  final String? lastExpenseCategoryId;
  final String? lastIncomeCategoryId;
  const AppSettingsRow({
    required this.id,
    required this.onboardingCompleted,
    required this.biometricLockEnabled,
    required this.currencyCode,
    this.lastExpenseCategoryId,
    this.lastIncomeCategoryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    map['biometric_lock_enabled'] = Variable<bool>(biometricLockEnabled);
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || lastExpenseCategoryId != null) {
      map['last_expense_category_id'] = Variable<String>(lastExpenseCategoryId);
    }
    if (!nullToAbsent || lastIncomeCategoryId != null) {
      map['last_income_category_id'] = Variable<String>(lastIncomeCategoryId);
    }
    return map;
  }

  AppSettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsRowsCompanion(
      id: Value(id),
      onboardingCompleted: Value(onboardingCompleted),
      biometricLockEnabled: Value(biometricLockEnabled),
      currencyCode: Value(currencyCode),
      lastExpenseCategoryId: lastExpenseCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastExpenseCategoryId),
      lastIncomeCategoryId: lastIncomeCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastIncomeCategoryId),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
      biometricLockEnabled: serializer.fromJson<bool>(
        json['biometricLockEnabled'],
      ),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      lastExpenseCategoryId: serializer.fromJson<String?>(
        json['lastExpenseCategoryId'],
      ),
      lastIncomeCategoryId: serializer.fromJson<String?>(
        json['lastIncomeCategoryId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'biometricLockEnabled': serializer.toJson<bool>(biometricLockEnabled),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'lastExpenseCategoryId': serializer.toJson<String?>(
        lastExpenseCategoryId,
      ),
      'lastIncomeCategoryId': serializer.toJson<String?>(lastIncomeCategoryId),
    };
  }

  AppSettingsRow copyWith({
    int? id,
    bool? onboardingCompleted,
    bool? biometricLockEnabled,
    String? currencyCode,
    Value<String?> lastExpenseCategoryId = const Value.absent(),
    Value<String?> lastIncomeCategoryId = const Value.absent(),
  }) => AppSettingsRow(
    id: id ?? this.id,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
    currencyCode: currencyCode ?? this.currencyCode,
    lastExpenseCategoryId: lastExpenseCategoryId.present
        ? lastExpenseCategoryId.value
        : this.lastExpenseCategoryId,
    lastIncomeCategoryId: lastIncomeCategoryId.present
        ? lastIncomeCategoryId.value
        : this.lastIncomeCategoryId,
  );
  AppSettingsRow copyWithCompanion(AppSettingsRowsCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      biometricLockEnabled: data.biometricLockEnabled.present
          ? data.biometricLockEnabled.value
          : this.biometricLockEnabled,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      lastExpenseCategoryId: data.lastExpenseCategoryId.present
          ? data.lastExpenseCategoryId.value
          : this.lastExpenseCategoryId,
      lastIncomeCategoryId: data.lastIncomeCategoryId.present
          ? data.lastIncomeCategoryId.value
          : this.lastIncomeCategoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('biometricLockEnabled: $biometricLockEnabled, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('lastExpenseCategoryId: $lastExpenseCategoryId, ')
          ..write('lastIncomeCategoryId: $lastIncomeCategoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    onboardingCompleted,
    biometricLockEnabled,
    currencyCode,
    lastExpenseCategoryId,
    lastIncomeCategoryId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.biometricLockEnabled == this.biometricLockEnabled &&
          other.currencyCode == this.currencyCode &&
          other.lastExpenseCategoryId == this.lastExpenseCategoryId &&
          other.lastIncomeCategoryId == this.lastIncomeCategoryId);
}

class AppSettingsRowsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<bool> onboardingCompleted;
  final Value<bool> biometricLockEnabled;
  final Value<String> currencyCode;
  final Value<String?> lastExpenseCategoryId;
  final Value<String?> lastIncomeCategoryId;
  const AppSettingsRowsCompanion({
    this.id = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.biometricLockEnabled = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.lastExpenseCategoryId = const Value.absent(),
    this.lastIncomeCategoryId = const Value.absent(),
  });
  AppSettingsRowsCompanion.insert({
    this.id = const Value.absent(),
    required bool onboardingCompleted,
    required bool biometricLockEnabled,
    required String currencyCode,
    this.lastExpenseCategoryId = const Value.absent(),
    this.lastIncomeCategoryId = const Value.absent(),
  }) : onboardingCompleted = Value(onboardingCompleted),
       biometricLockEnabled = Value(biometricLockEnabled),
       currencyCode = Value(currencyCode);
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<bool>? onboardingCompleted,
    Expression<bool>? biometricLockEnabled,
    Expression<String>? currencyCode,
    Expression<String>? lastExpenseCategoryId,
    Expression<String>? lastIncomeCategoryId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (biometricLockEnabled != null)
        'biometric_lock_enabled': biometricLockEnabled,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (lastExpenseCategoryId != null)
        'last_expense_category_id': lastExpenseCategoryId,
      if (lastIncomeCategoryId != null)
        'last_income_category_id': lastIncomeCategoryId,
    });
  }

  AppSettingsRowsCompanion copyWith({
    Value<int>? id,
    Value<bool>? onboardingCompleted,
    Value<bool>? biometricLockEnabled,
    Value<String>? currencyCode,
    Value<String?>? lastExpenseCategoryId,
    Value<String?>? lastIncomeCategoryId,
  }) {
    return AppSettingsRowsCompanion(
      id: id ?? this.id,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      currencyCode: currencyCode ?? this.currencyCode,
      lastExpenseCategoryId:
          lastExpenseCategoryId ?? this.lastExpenseCategoryId,
      lastIncomeCategoryId: lastIncomeCategoryId ?? this.lastIncomeCategoryId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (biometricLockEnabled.present) {
      map['biometric_lock_enabled'] = Variable<bool>(
        biometricLockEnabled.value,
      );
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (lastExpenseCategoryId.present) {
      map['last_expense_category_id'] = Variable<String>(
        lastExpenseCategoryId.value,
      );
    }
    if (lastIncomeCategoryId.present) {
      map['last_income_category_id'] = Variable<String>(
        lastIncomeCategoryId.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('biometricLockEnabled: $biometricLockEnabled, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('lastExpenseCategoryId: $lastExpenseCategoryId, ')
          ..write('lastIncomeCategoryId: $lastIncomeCategoryId')
          ..write(')'))
        .toString();
  }
}

abstract class _$NetworthyDatabase extends GeneratedDatabase {
  _$NetworthyDatabase(QueryExecutor e) : super(e);
  $NetworthyDatabaseManager get managers => $NetworthyDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $AppSettingsRowsTable appSettingsRows = $AppSettingsRowsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactions,
    appSettingsRows,
  ];
}

typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String type,
      required int amountMinor,
      required String currencyCode,
      required String categoryId,
      required int transactionYear,
      required int transactionMonth,
      required int transactionDay,
      Value<String?> note,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<int> amountMinor,
      Value<String> currencyCode,
      Value<String> categoryId,
      Value<int> transactionYear,
      Value<int> transactionMonth,
      Value<int> transactionDay,
      Value<String?> note,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$NetworthyDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionYear => $composableBuilder(
    column: $table.transactionYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionMonth => $composableBuilder(
    column: $table.transactionMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionDay => $composableBuilder(
    column: $table.transactionDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$NetworthyDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionYear => $composableBuilder(
    column: $table.transactionYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionMonth => $composableBuilder(
    column: $table.transactionMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionDay => $composableBuilder(
    column: $table.transactionDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$NetworthyDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transactionYear => $composableBuilder(
    column: $table.transactionYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transactionMonth => $composableBuilder(
    column: $table.transactionMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transactionDay => $composableBuilder(
    column: $table.transactionDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$NetworthyDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<
              _$NetworthyDatabase,
              $TransactionsTable,
              Transaction
            >,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(
    _$NetworthyDatabase db,
    $TransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> transactionYear = const Value.absent(),
                Value<int> transactionMonth = const Value.absent(),
                Value<int> transactionDay = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                type: type,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                categoryId: categoryId,
                transactionYear: transactionYear,
                transactionMonth: transactionMonth,
                transactionDay: transactionDay,
                note: note,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required int amountMinor,
                required String currencyCode,
                required String categoryId,
                required int transactionYear,
                required int transactionMonth,
                required int transactionDay,
                Value<String?> note = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                type: type,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                categoryId: categoryId,
                transactionYear: transactionYear,
                transactionMonth: transactionMonth,
                transactionDay: transactionDay,
                note: note,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$NetworthyDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        Transaction,
        BaseReferences<_$NetworthyDatabase, $TransactionsTable, Transaction>,
      ),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsRowsTableCreateCompanionBuilder =
    AppSettingsRowsCompanion Function({
      Value<int> id,
      required bool onboardingCompleted,
      required bool biometricLockEnabled,
      required String currencyCode,
      Value<String?> lastExpenseCategoryId,
      Value<String?> lastIncomeCategoryId,
    });
typedef $$AppSettingsRowsTableUpdateCompanionBuilder =
    AppSettingsRowsCompanion Function({
      Value<int> id,
      Value<bool> onboardingCompleted,
      Value<bool> biometricLockEnabled,
      Value<String> currencyCode,
      Value<String?> lastExpenseCategoryId,
      Value<String?> lastIncomeCategoryId,
    });

class $$AppSettingsRowsTableFilterComposer
    extends Composer<_$NetworthyDatabase, $AppSettingsRowsTable> {
  $$AppSettingsRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get biometricLockEnabled => $composableBuilder(
    column: $table.biometricLockEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastExpenseCategoryId => $composableBuilder(
    column: $table.lastExpenseCategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastIncomeCategoryId => $composableBuilder(
    column: $table.lastIncomeCategoryId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsRowsTableOrderingComposer
    extends Composer<_$NetworthyDatabase, $AppSettingsRowsTable> {
  $$AppSettingsRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get biometricLockEnabled => $composableBuilder(
    column: $table.biometricLockEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastExpenseCategoryId => $composableBuilder(
    column: $table.lastExpenseCategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastIncomeCategoryId => $composableBuilder(
    column: $table.lastIncomeCategoryId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsRowsTableAnnotationComposer
    extends Composer<_$NetworthyDatabase, $AppSettingsRowsTable> {
  $$AppSettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get biometricLockEnabled => $composableBuilder(
    column: $table.biometricLockEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastExpenseCategoryId => $composableBuilder(
    column: $table.lastExpenseCategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastIncomeCategoryId => $composableBuilder(
    column: $table.lastIncomeCategoryId,
    builder: (column) => column,
  );
}

class $$AppSettingsRowsTableTableManager
    extends
        RootTableManager<
          _$NetworthyDatabase,
          $AppSettingsRowsTable,
          AppSettingsRow,
          $$AppSettingsRowsTableFilterComposer,
          $$AppSettingsRowsTableOrderingComposer,
          $$AppSettingsRowsTableAnnotationComposer,
          $$AppSettingsRowsTableCreateCompanionBuilder,
          $$AppSettingsRowsTableUpdateCompanionBuilder,
          (
            AppSettingsRow,
            BaseReferences<
              _$NetworthyDatabase,
              $AppSettingsRowsTable,
              AppSettingsRow
            >,
          ),
          AppSettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsRowsTableTableManager(
    _$NetworthyDatabase db,
    $AppSettingsRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<bool> biometricLockEnabled = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String?> lastExpenseCategoryId = const Value.absent(),
                Value<String?> lastIncomeCategoryId = const Value.absent(),
              }) => AppSettingsRowsCompanion(
                id: id,
                onboardingCompleted: onboardingCompleted,
                biometricLockEnabled: biometricLockEnabled,
                currencyCode: currencyCode,
                lastExpenseCategoryId: lastExpenseCategoryId,
                lastIncomeCategoryId: lastIncomeCategoryId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required bool onboardingCompleted,
                required bool biometricLockEnabled,
                required String currencyCode,
                Value<String?> lastExpenseCategoryId = const Value.absent(),
                Value<String?> lastIncomeCategoryId = const Value.absent(),
              }) => AppSettingsRowsCompanion.insert(
                id: id,
                onboardingCompleted: onboardingCompleted,
                biometricLockEnabled: biometricLockEnabled,
                currencyCode: currencyCode,
                lastExpenseCategoryId: lastExpenseCategoryId,
                lastIncomeCategoryId: lastIncomeCategoryId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$NetworthyDatabase,
      $AppSettingsRowsTable,
      AppSettingsRow,
      $$AppSettingsRowsTableFilterComposer,
      $$AppSettingsRowsTableOrderingComposer,
      $$AppSettingsRowsTableAnnotationComposer,
      $$AppSettingsRowsTableCreateCompanionBuilder,
      $$AppSettingsRowsTableUpdateCompanionBuilder,
      (
        AppSettingsRow,
        BaseReferences<
          _$NetworthyDatabase,
          $AppSettingsRowsTable,
          AppSettingsRow
        >,
      ),
      AppSettingsRow,
      PrefetchHooks Function()
    >;

class $NetworthyDatabaseManager {
  final _$NetworthyDatabase _db;
  $NetworthyDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$AppSettingsRowsTableTableManager get appSettingsRows =>
      $$AppSettingsRowsTableTableManager(_db, _db.appSettingsRows);
}
