import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/domain/model/domain_validation.dart';
import 'package:networthy/domain/model/local_date.dart';
import 'package:networthy/domain/model/transaction.dart';
import 'package:networthy/domain/model/transaction_type.dart';

void main() {
  group('BookkeepingTransaction validation', () {
    test('accepts a valid expense transaction', () {
      final transaction = BookkeepingTransaction.create(
        id: '00000000-0000-4000-8000-000000000001',
        type: TransactionType.expense,
        amountMinor: 12500,
        categoryId: 'expense.food',
        transactionDate: LocalDate(2026, 8, 14),
        createdAtUtc: DateTime.utc(2026, 8, 14, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 14, 1),
      );

      expect(transaction.amountMinor, 12500);
      expect(transaction.currencyCode, 'TWD');
    });

    test('requires id to be a UUID string', () {
      expect(
        () => BookkeepingTransaction.create(
          id: 'not-a-uuid',
          type: TransactionType.expense,
          amountMinor: 100,
          categoryId: 'expense.food',
          transactionDate: LocalDate(2026, 8, 14),
          createdAtUtc: DateTime.utc(2026, 8, 14, 1),
          updatedAtUtc: DateTime.utc(2026, 8, 14, 1),
        ),
        throwsA(isA<DomainValidationException>()),
      );
    });

    test('rejects zero negative and over-limit amounts', () {
      for (final amount in <int>[0, -1, 1000000000]) {
        expect(
          () => BookkeepingTransaction.create(
            id: 'txn-$amount',
            type: TransactionType.expense,
            amountMinor: amount,
            categoryId: 'expense.food',
            transactionDate: LocalDate(2026, 8, 14),
            createdAtUtc: DateTime.utc(2026, 8, 14, 1),
            updatedAtUtc: DateTime.utc(2026, 8, 14, 1),
          ),
          throwsA(isA<DomainValidationException>()),
        );
      }
    });

    test('accepts maximum allowed amount', () {
      final transaction = BookkeepingTransaction.create(
        id: '00000000-0000-4000-8000-000000000002',
        type: TransactionType.income,
        amountMinor: 999999999,
        categoryId: 'income.salary',
        transactionDate: LocalDate(2026, 8, 14),
        createdAtUtc: DateTime.utc(2026, 8, 14, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 14, 1),
      );

      expect(transaction.amountMinor, 999999999);
    });

    test('rejects category that does not match transaction type', () {
      expect(
        () => BookkeepingTransaction.create(
          id: '00000000-0000-4000-8000-000000000003',
          type: TransactionType.income,
          amountMinor: 100,
          categoryId: 'expense.food',
          transactionDate: LocalDate(2026, 8, 14),
          createdAtUtc: DateTime.utc(2026, 8, 14, 1),
          updatedAtUtc: DateTime.utc(2026, 8, 14, 1),
        ),
        throwsA(isA<DomainValidationException>()),
      );
    });

    test('rejects notes longer than 100 Unicode code points', () {
      expect(
        () => BookkeepingTransaction.create(
          id: '00000000-0000-4000-8000-000000000004',
          type: TransactionType.expense,
          amountMinor: 100,
          categoryId: 'expense.food',
          transactionDate: LocalDate(2026, 8, 14),
          note: '備' * 101,
          createdAtUtc: DateTime.utc(2026, 8, 14, 1),
          updatedAtUtc: DateTime.utc(2026, 8, 14, 1),
        ),
        throwsA(isA<DomainValidationException>()),
      );
    });

    test('requires UTC created and updated timestamps', () {
      expect(
        () => BookkeepingTransaction.create(
          id: '00000000-0000-4000-8000-000000000005',
          type: TransactionType.expense,
          amountMinor: 100,
          categoryId: 'expense.food',
          transactionDate: LocalDate(2026, 8, 14),
          createdAtUtc: DateTime(2026, 8, 14, 1),
          updatedAtUtc: DateTime.utc(2026, 8, 14, 1),
        ),
        throwsA(isA<DomainValidationException>()),
      );
    });
  });

  group('LocalDate', () {
    test('stores calendar date without UTC instant conversion', () {
      final date = LocalDate.fromLocalDateTime(DateTime(2024, 2, 29, 23, 30));

      expect(date, LocalDate(2024, 2, 29));
    });

    test('matches month boundaries including leap day', () {
      expect(LocalDate(2024, 2, 1).isInMonth(2024, 2), isTrue);
      expect(LocalDate(2024, 2, 29).isInMonth(2024, 2), isTrue);
      expect(LocalDate(2024, 3, 1).isInMonth(2024, 2), isFalse);
    });
  });
}
