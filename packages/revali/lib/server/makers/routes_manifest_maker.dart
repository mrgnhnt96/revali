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

  final payload = {'version': 1, 'prefix': prefix, 'routes': routes};

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
