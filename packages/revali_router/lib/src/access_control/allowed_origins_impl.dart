import 'package:revali_router_core/revali_router_core.dart';

class AllowedOriginsImpl implements AllowedOrigins {
  const AllowedOriginsImpl(this.origins, {this.inherit = true});
  const AllowedOriginsImpl.all() : this(const {'*'}, inherit: false);

  @override
  final Set<String> origins;

  @override
  final bool inherit;
}
