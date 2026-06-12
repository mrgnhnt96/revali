import 'package:revali_swagger/builders/schema_registry.dart';
import 'package:revali_swagger/enums/param_location.dart';
import 'package:revali_swagger/models/swagger_controller.dart';
import 'package:revali_swagger/models/swagger_method.dart';
import 'package:revali_swagger/models/swagger_param.dart';
import 'package:revali_swagger/models/swagger_server.dart';

Map<String, dynamic> buildOpenApiSpec(
  SwaggerServer server,
  SchemaRegistry registry,
) {
  final paths = <String, dynamic>{};

  for (final controller in server.visibleControllers) {
    for (final method in controller.methods) {
      if (method.isHidden) continue;

      final fullPath = _buildFullPath(controller.path, method.path);
      final pathItem =
          paths.putIfAbsent(fullPath, () => <String, dynamic>{})
              as Map<String, dynamic>;

      pathItem[method.httpMethod] = _buildOperation(
        controller,
        method,
        registry,
        fullPath,
      );
    }
  }

  final schemasMap = registry.schemasMap;

  if (schemasMap.isEmpty) {
    return {
      'openapi': '3.0.3',
      'info': {
        'title': server.info.title,
        'version': server.info.version,
        if (server.info.description case final String d) 'description': d,
      },
      'paths': paths,
    };
  }

  // Prune schemas that are never $ref'd from paths or other reachable schemas.
  final referenced = <String>{};
  _collectRefs(paths, referenced);
  // Also collect refs within schemas themselves (transitive reachability).
  var changed = true;
  while (changed) {
    changed = false;
    for (final entry in schemasMap.entries) {
      if (referenced.contains(entry.key)) {
        final before = referenced.length;
        _collectRefs(entry.value, referenced);
        if (referenced.length > before) changed = true;
      }
    }
  }
  final prunedSchemas = {
    for (final entry in schemasMap.entries)
      if (referenced.contains(entry.key)) entry.key: entry.value,
  };

  return {
    'openapi': '3.0.3',
    'info': {
      'title': server.info.title,
      'version': server.info.version,
      if (server.info.description case final String d) 'description': d,
    },
    'paths': paths,
    if (prunedSchemas.isNotEmpty) 'components': {'schemas': prunedSchemas},
  };
}

void _collectRefs(dynamic node, Set<String> refs) {
  if (node is Map) {
    final ref = node[r'$ref'];
    if (ref is String && ref.startsWith('#/components/schemas/')) {
      refs.add(ref.substring('#/components/schemas/'.length));
    }
    for (final value in node.values) {
      _collectRefs(value, refs);
    }
  } else if (node is List) {
    for (final item in node) {
      _collectRefs(item, refs);
    }
  }
}

Map<String, dynamic> _buildOperation(
  SwaggerController controller,
  SwaggerMethod method,
  SchemaRegistry registry,
  String fullPath,
) {
  // Path param names declared in the template, e.g. /users/{id} → {'id'}.
  final templateParams = RegExp(
    r'\{(\w+)\}',
  ).allMatches(fullPath).map((m) => m.group(1)!).toSet();

  // requestBody has no defined semantics for GET, HEAD, and DELETE (RFC 7231).
  const noBodyMethods = {'get', 'head', 'delete'};
  final bodyAsQuery =
      method.bodyParam != null && noBodyMethods.contains(method.httpMethod);
  final emitBody = method.bodyParam != null && !bodyAsQuery;

  final parameters = [
    for (final param in method.parameters)
      // Skip path params that have no matching {segment} in the template.
      if (param.location != ParamLocation.path ||
          templateParams.contains(param.effectiveName))
        _buildParameter(param),
    if (bodyAsQuery)
      _buildParameter(method.bodyParam!, locationOverride: 'query'),
  ];

  final effectiveTags = method.tags.isNotEmpty ? method.tags : [controller.tag];

  return {
    'operationId': method.operationId,
    'tags': effectiveTags,
    if (method.summary case final String s) 'summary': s,
    if (method.description case final String d) 'description': d,
    if (parameters.isNotEmpty) 'parameters': parameters,
    if (emitBody) 'requestBody': _buildRequestBody(method.bodyParam!),
    'responses': _buildResponses(method),
  };
}

Map<String, dynamic> _buildParameter(
  SwaggerParam param, {
  String? locationOverride,
}) {
  final location =
      locationOverride ??
      switch (param.location) {
        ParamLocation.path => 'path',
        ParamLocation.query => 'query',
        ParamLocation.header => 'header',
        ParamLocation.cookie => 'cookie',
        // unreachable — body params are handled separately
        ParamLocation.body => 'query',
      };

  return {
    'name': param.effectiveName,
    'in': location,
    'required': param.location == ParamLocation.path || param.isRequired,
    'schema': param.type.schema,
  };
}

Map<String, dynamic> _buildRequestBody(SwaggerParam body) {
  return {
    'required': body.isRequired,
    'content': {
      'application/json': {'schema': body.type.schema},
    },
  };
}

Map<String, dynamic> _buildResponses(SwaggerMethod method) {
  if (method.explicitResponses.isNotEmpty) {
    return {
      for (final r in method.explicitResponses)
        '${r.statusCode}': {'description': r.description},
    };
  }

  final statusCode = '${method.defaultStatusCode}';

  if (method.returnType.isVoid) {
    return {
      statusCode: {'description': 'No content'},
    };
  }

  return {
    statusCode: {
      'description': 'Success',
      'content': {
        'application/json': {'schema': method.returnType.schema},
      },
    },
  };
}

String _buildFullPath(String controllerPath, String methodPath) {
  final segments = [
    if (controllerPath.isNotEmpty && controllerPath != '/') controllerPath,
    if (methodPath.isNotEmpty && methodPath != '/') methodPath,
  ];

  var combined = segments.join('/');
  if (!combined.startsWith('/')) {
    combined = '/$combined';
  }

  return combined.replaceAllMapped(RegExp(r':(\w+)'), (m) => '{${m[1]}}');
}
