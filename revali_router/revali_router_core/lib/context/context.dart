import 'package:revali_router_core/data/data.dart';
import 'package:revali_router_core/meta/meta_scope.dart';
import 'package:revali_router_core/method_mutations/reflect/reflect_handler.dart';
import 'package:revali_router_core/request/mutable_request.dart';
import 'package:revali_router_core/response/mutable_response.dart';
import 'package:revali_router_core/route/route_entry.dart';

abstract interface class Context {
  const Context();

  Data get data;
  MetaScope get meta;
  RouteEntry get route;
  MutableRequest get request;
  MutableResponse get response;
  ReflectHandler get reflect;
}
