import 'dart:convert';

import 'package:revali/server/converters/server_child_route.dart';
import 'package:revali/server/converters/server_param.dart';
import 'package:revali/server/converters/server_parent_route.dart';
import 'package:revali/server/converters/server_server.dart';
import 'package:revali_construct/revali_construct.dart';

/// Emits a machine-readable route table for CLI / MCP / agents.
AnyFile routesManifestFile(ServerServer server, {String prefix = 'api'}) {
  final routes = <Map<String, Object?>>[];

  for (final parent in server.routes) {
    for (final child in parent.routes) {
      routes.add(_routeEntry(parent, child, prefix: prefix));
    }
  }

  // Version 2 adds `returns`. A consumer pinned against version 1 has no
  // return types to compare, so the contract check reports that rather than
  // silently treating "absent" as "unchanged".
  final payload = {'version': 2, 'prefix': prefix, 'routes': routes};

  return AnyFile(
    basename: 'routes',
    extension: 'json',
    content: '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
  );
}

Map<String, Object?> _routeEntry(
  ServerParentRoute parent,
  ServerChildRoute child, {
  required String prefix,
}) {
  final segments = <String>[
    if (prefix.isNotEmpty) prefix,
    if (parent.routePath.isNotEmpty) parent.routePath,
    if (child.path.isNotEmpty) child.path,
  ];
  final fullPath = '/${segments.join('/')}'.replaceAll(RegExp('/+'), '/');

  final lifecycle = <String>{
    for (final c in parent.annotations.lifecycleComponents) c.name,
    for (final c in child.annotations.lifecycleComponents) c.name,
  }.toList()..sort();

  return {
    'method': child.method,
    'path': fullPath,
    'controller': parent.className,
    'handler': child.handlerName,
    'sse': child.isSse,
    'webSocket': child.webSocket != null,
    // The name only. This manifest describes a route *surface*, not a type
    // model: it carries no fields, no nested types and no serialisation
    // strategy, so it can tell a consumer that a response changed shape at
    // the top level and cannot generate a client. See MICROSERVICES_PLAN.md.
    //
    // Reported unwrapped: what a caller receives is the awaited value, so
    // `Future<String>` and `String` are the same contract. Leaving the wrapper
    // on would flag a breaking change the moment a handler became async, and
    // would read the nullability off `Future` rather than off what is
    // actually returned.
    'returns': child.returnType.nonAsyncType.nonNullName,
    'returnsNullable': child.returnType.nonAsyncType.isNullable,
    'params': [for (final param in child.params) _paramEntry(param)],
    'lifecycle': lifecycle,
  };
}

Map<String, Object?> _paramEntry(ServerParam param) {
  final annotation = param.annotations.baseAnnotation;
  return {
    'name': param.name,
    'type': param.type.nonNullName,
    'required': param.isRequired && !param.hasDefaultValue,
    'location': annotation?.type.location,
    'binding': annotation?.name ?? param.name,
  };
}
