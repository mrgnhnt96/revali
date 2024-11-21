import 'package:revali_router_core/revali_router_core.dart';

class ExpectedHeadersImpl implements ExpectedHeaders {
  const ExpectedHeadersImpl(this.headers);

  @override
  final Set<String> headers;
}
