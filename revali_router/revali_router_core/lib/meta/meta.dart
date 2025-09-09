import 'package:revali_router_core/meta/meta_handler.dart';

abstract interface class Meta {
  const Meta();

  MetaHandler get direct;
  MetaHandler get inherited;
  MetaHandler get all;
}
