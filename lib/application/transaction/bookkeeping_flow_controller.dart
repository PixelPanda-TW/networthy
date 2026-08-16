import '../../domain/model/transaction.dart';
import '../../domain/repository/settings_repository.dart';
import '../../domain/repository/transaction_repository.dart';
import '../../domain/summary/monthly_summary.dart';
import '../common/application_failure.dart';
import '../common/application_ports.dart';
import 'add_transaction_use_case.dart';
import 'delete_transaction_use_case.dart';
import 'edit_transaction_use_case.dart';
import 'transaction_command.dart';

class DeleteFlowRequest {
  const DeleteFlowRequest({required this.id, required this.confirmed});

  final String id;
  final bool confirmed;
}

class BookkeepingFlowState {
  const BookkeepingFlowState({
    required this.year,
    required this.month,
    required this.summary,
    required this.recentTransactions,
    required this.saving,
    this.formCommand,
    this.failure,
  });

  factory BookkeepingFlowState.initial() {
    return BookkeepingFlowState(
      year: 0,
      month: 0,
      summary: const MonthlySummary(
        year: 0,
        month: 0,
        totalIncomeMinor: 0,
        totalExpenseMinor: 0,
        expenseCategoryTotals: <String, int>{},
        expenseCategoryPercentages: <String, double>{},
      ),
      recentTransactions: const <BookkeepingTransaction>[],
      saving: false,
    );
  }

  final int year;
  final int month;
  final MonthlySummary summary;
  final List<BookkeepingTransaction> recentTransactions;
  final bool saving;
  final TransactionCommand? formCommand;
  final ApplicationFailure? failure;

  BookkeepingFlowState copyWith({
    int? year,
    int? month,
    MonthlySummary? summary,
    List<BookkeepingTransaction>? recentTransactions,
    bool? saving,
    TransactionCommand? formCommand,
    bool clearFormCommand = false,
    ApplicationFailure? failure,
    bool clearFailure = false,
  }) {
    return BookkeepingFlowState(
      year: year ?? this.year,
      month: month ?? this.month,
      summary: summary ?? this.summary,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      saving: saving ?? this.saving,
      formCommand: clearFormCommand ? null : formCommand ?? this.formCommand,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

class BookkeepingFlowController {
  BookkeepingFlowController({
    required TransactionRepository transactions,
    required SettingsRepository settings,
    required ApplicationClock clock,
    required TransactionIdGenerator idGenerator,
  }) : _transactions = transactions,
       _settings = settings,
       _clock = clock,
       _idGenerator = idGenerator,
       state = BookkeepingFlowState.initial();

  final TransactionRepository _transactions;
  final SettingsRepository _settings;
  final ApplicationClock _clock;
  final TransactionIdGenerator _idGenerator;

  BookkeepingFlowState state;

  Future<void> loadMonth({required int year, required int month}) async {
    state = state.copyWith(year: year, month: month, clearFailure: true);
    await _refresh();
  }

  Future<void> add(TransactionCommand command) async {
    state = state.copyWith(
      saving: true,
      formCommand: command,
      clearFailure: true,
    );
    final result = await AddTransactionUseCase(
      transactions: _transactions,
      settings: _settings,
      clock: _clock,
      idGenerator: _idGenerator,
    ).execute(command);

    if (result.failure != null) {
      state = state.copyWith(saving: false, failure: result.failure);
      return;
    }

    await _refresh();
    state = state.copyWith(saving: false, clearFormCommand: true);
  }

  Future<void> edit({
    required String id,
    required TransactionCommand command,
  }) async {
    state = state.copyWith(
      saving: true,
      formCommand: command,
      clearFailure: true,
    );
    final result = await EditTransactionUseCase(
      transactions: _transactions,
      settings: _settings,
      clock: _clock,
    ).execute(id: id, command: command);

    if (result.failure != null) {
      state = state.copyWith(saving: false, failure: result.failure);
      return;
    }

    await _refresh();
    state = state.copyWith(saving: false, clearFormCommand: true);
  }

  Future<void> delete(DeleteFlowRequest request) async {
    final result = await DeleteTransactionUseCase(_transactions).execute(
      DeleteTransactionRequest(id: request.id, confirmed: request.confirmed),
    );
    if (result.failure != null) {
      state = state.copyWith(failure: result.failure);
      return;
    }

    await _refresh();
  }

  Future<void> _refresh() async {
    final summary = await _transactions.monthlySummary(
      year: state.year,
      month: state.month,
    );
    final recent = await _transactions.latest(limit: 5);
    state = state.copyWith(
      summary: summary,
      recentTransactions: recent,
      clearFailure: true,
    );
  }
}
