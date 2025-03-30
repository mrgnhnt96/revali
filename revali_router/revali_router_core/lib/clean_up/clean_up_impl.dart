import 'package:revali_router_core/clean_up/clean_up.dart';

class CleanUpImpl implements CleanUp {
  CleanUpImpl() : _fns = [];

  final List<void Function()> _fns;

  @override
  void add(void Function() fn) {
    _fns.add(fn);
  }

  void clean() {
    for (final fn in _fns) {
      fn();
    }
  }

  @override
  void remove(void Function() fn) {
    _fns.remove(fn);
  }

  @override
  void merge(CleanUp other) {
    if (other is CleanUpImpl) {
      _fns.addAll(other._fns);
    }
  }
}
