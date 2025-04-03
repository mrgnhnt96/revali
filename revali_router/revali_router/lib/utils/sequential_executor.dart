import 'dart:async';
import 'dart:collection';

class SequentialExecutor<T> {
  final _taskQueue = Queue<_Task<T>>();
  bool _isRunning = false;
  bool _hasResult = false;
  T? _result;

  Future<T?> add(Future<T?> Function() taskFactory) async {
    if (_hasResult) {
      // Ignore if already short-circuited
      return _result;
    }

    final task = _Task(taskFactory);
    _taskQueue.add(task);
    _run().ignore();
    return task.completer.future;
  }

  Future<void> _run() async {
    if (_isRunning) return;
    _isRunning = true;

    while (_taskQueue.isNotEmpty && !_hasResult) {
      final task = _taskQueue.removeFirst();

      try {
        final result = await task.fn();
        if (!_hasResult && result != null) {
          _hasResult = true;
          _result = result;
          task.completer.complete(result);

          // Cancel remaining tasks
          while (_taskQueue.isNotEmpty) {
            _taskQueue.removeFirst().completer.complete(null);
          }
          break;
        } else {
          task.completer.complete(result);
        }
      } catch (e, st) {
        task.completer.completeError(e, st);
      }
    }

    _isRunning = false;
  }

  T? get result => _result;
}

class _Task<T> {
  _Task(this.fn) : completer = Completer<T?>();

  final Future<T?> Function() fn;
  final Completer<T?> completer;
}
