// ignore_for_file: avoid_print

import 'dart:async';

import 'package:revali_core/revali_core.dart';

/// Hands [observed] to every observer.
///
/// Never awaited: an observer that waits on [ObservedRequest.summary] would
/// otherwise deadlock the request it is waiting for. Errors — thrown
/// synchronously or from the returned future — are logged and go no further,
/// so a broken exporter cannot take the response with it, nor stop the
/// observers after it in the list.
void notifyObservers(List<Observer> observers, ObservedRequest observed) {
  for (final observer in observers) {
    try {
      final result = observer.see(observed);

      if (result is Future<void>) {
        result.catchError(reportObserverError);
      }
    } catch (e, st) {
      reportObserverError(e, st);
    }
  }
}

void reportObserverError(Object error, [StackTrace? stackTrace]) {
  print('Observer failed: $error\n${stackTrace ?? ''}');
}
