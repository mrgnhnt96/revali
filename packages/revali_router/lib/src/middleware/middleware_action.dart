class MiddlewareResult {
  const MiddlewareResult();

  bool get isNext => this is _Next;
  bool get isCancel => this is _Stop;
  _Stop get asCancel => this as _Stop;
}

class _Next extends MiddlewareResult {
  const _Next(this.action);

  final MiddlewareAction action;
}

class _Stop extends MiddlewareResult {
  const _Stop(this.action);

  final MiddlewareAction action;
}

class MiddlewareAction {
  const MiddlewareAction();

  _Next next() => _Next(this);

  _Stop stop() => _Stop(this);
}
