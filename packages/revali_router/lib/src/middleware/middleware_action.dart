import 'package:shelf/shelf.dart';

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
  const _Cancel(this.response, this.action);

  final Response response;

  final MiddlewareAction action;
}

class MiddlewareAction {
  const MiddlewareAction();

  _Next next() => _Next(this);

  _Cancel cancel(Response response) => _Cancel(response, this);
}
