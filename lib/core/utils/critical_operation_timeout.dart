import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

const Duration criticalOperationTimeout = Duration(seconds: 8);

/// First launch on Android can be slow (Play Services + Auth + Firestore).
const Duration onboardingOperationTimeout = Duration(seconds: 25);

const String offlineSessionSyncSnackbarMessage =
    'Sem internet. Sua sessão será sincronizada automaticamente quando a conexão voltar.';

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

Future<T> withOnboardingOperationTimeout<T>(Future<T> future) {
  return future.timeout(
    onboardingOperationTimeout,
    onTimeout: () {
      throw TimeoutException(
        'Sem resposta do servidor. Verifique sua internet e tente novamente.',
        onboardingOperationTimeout,
      );
    },
  );
}

bool isCriticalOperationOfflineError(Object error) {
  if (error is TimeoutException) return true;
  if (error is FirebaseException) {
    return error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        error.code == 'network-request-failed';
  }
  return false;
}

String criticalOperationErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'Sem conexão ou servidor lento. Tente novamente.';
  }
  return 'Não foi possível concluir. Tente novamente.';
}
