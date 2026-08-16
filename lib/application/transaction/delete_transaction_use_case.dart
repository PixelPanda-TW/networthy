import '../../domain/repository/transaction_repository.dart';
import '../common/application_failure.dart';

class DeleteTransactionRequest {
  const DeleteTransactionRequest({required this.id, required this.confirmed});

  final String id;
  final bool confirmed;
}

class DeleteTransactionResult {
  const DeleteTransactionResult.success() : failure = null;

  const DeleteTransactionResult.failure(this.failure);

  final ApplicationFailure? failure;
}

class DeleteTransactionUseCase {
  const DeleteTransactionUseCase(this._transactions);

  final TransactionRepository _transactions;

  Future<DeleteTransactionResult> execute(
    DeleteTransactionRequest request,
  ) async {
    if (!request.confirmed) {
      return DeleteTransactionResult.failure(
        ApplicationFailure.validation('Delete must be confirmed.'),
      );
    }

    try {
      await _transactions.delete(request.id);
      return const DeleteTransactionResult.success();
    } on Exception catch (exception) {
      return DeleteTransactionResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }
}
