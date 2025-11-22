import 'package:revali_router_core/meta/meta.dart';

abstract interface class MetaScope implements Meta {
  const MetaScope();

  Meta get direct;
  Meta get inherited;
}
