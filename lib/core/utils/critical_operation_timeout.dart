import 'dart:async';

const Duration criticalOperationTimeout = Duration(seconds: 8);

/// Wraps network-critical Firestore/Auth calls so offline users do not spin forever.
Future<T> withCriticalOperationTimeout<T>(Future<T> future) {
  return future.timeout(
    criticalOperationTimeout,
    onTimeout: () {
      throw TimeoutException(
        'Sem resposta do servidor em 8 segundos. Verifique sua internet.',
        criticalOperationTimeout,
      );
    },
  );
}

String criticalOperationErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'Sem conexão ou servidor lento. Tente novamente.';
  }
  return 'Não foi possível concluir. Tente novamente.';
}
