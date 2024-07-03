class MiddlewareResult {
  const MiddlewareResult();

  bool get isNext => this is _Next;
  bool get isCancel => this is _Cancel;
  _Cancel get asCancel => this as _Cancel;
}

class _Next extends MiddlewareResult {
  const _Next(this.action);

  final MiddlewareAction action;
}

class _Cancel extends MiddlewareResult {
  const _Cancel(this.action);

  final MiddlewareAction action;
}

class MiddlewareAction {
  const MiddlewareAction();

  _Next next() => _Next(this);

  _Cancel cancel() => _Cancel(this);
}
