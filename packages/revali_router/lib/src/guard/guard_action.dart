class GuardResult {
  const GuardResult();

  bool get isYes => this is _Yes;
  bool get isNo => this is _No;
  _No get asNo => this as _No;
}

class _Yes extends GuardResult {
  const _Yes(this.action);

  final GuardAction action;
}

class _No extends GuardResult {
  const _No(this.action);

  final GuardAction action;
}

class GuardAction {
  const GuardAction();

  _Yes yes() => _Yes(this);

  _No no() => _No(this);
}
