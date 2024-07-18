import 'package:revali_router_core/revali_router_core.dart';

class AllowedHeadersImpl implements AllowedHeaders {
  const AllowedHeadersImpl(this.headers, {this.inherit = true});

  @override
  final Set<String> headers;

  @override
  final bool inherit;
}
