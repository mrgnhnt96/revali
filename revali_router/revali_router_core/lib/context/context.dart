import 'package:revali_router_core/data/data.dart';
import 'package:revali_router_core/meta/meta_scope.dart';
import 'package:revali_router_core/method_mutations/reflect/reflect_handler.dart';
import 'package:revali_router_core/request/request.dart';
import 'package:revali_router_core/response/response.dart';
import 'package:revali_router_core/route/route_entry.dart';

abstract interface class Context {
  const Context();

  Data get data;
  MetaScope get meta;
  RouteEntry get route;
  Request get request;
  Response get response;
  ReflectHandler get reflect;
}
