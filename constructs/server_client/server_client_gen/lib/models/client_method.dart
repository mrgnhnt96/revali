import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/makers/utils/extract_import.dart';
import 'package:server_client_gen/models/client_imports.dart';
import 'package:server_client_gen/models/client_param.dart';
import 'package:server_client_gen/models/client_return_type.dart';

class ClientMethod with ExtractImport {
  ClientMethod({
    required this.name,
    required this.parameters,
    required this.returnType,
    required this.isSse,
    required this.isWebsocket,
    required this.path,
    required this.parentPath,
    required this.method,
  });

  factory ClientMethod.fromMeta(MetaMethod route, String parentPath) {
    return ClientMethod(
      name: route.name,
      parentPath: parentPath,
      method: route.method,
      returnType: ClientReturnType.fromMeta(route.returnType),
      parameters: route.params.map(ClientParam.fromMeta).toList(),
      isWebsocket: route.isWebSocket,
      isSse: route.isSse,
      path: route.path,
    );
  }

  final String name;
  final String? path;
  final String parentPath;
  final String? method;
  final ClientReturnType returnType;
  final List<ClientParam> parameters;
  final bool isWebsocket;
  final bool isSse;

  String get fullPath =>
      ['', parentPath, if (path case final String p) p].join('/');

  String get resolvedPath {
    final allParts = paramsFor(fullPath);

    if (allParts.isEmpty) {
      return fullPath;
    }

    final expandedParts = <String, List<int>>{
      for (final MapEntry(:key, value: count) in allParts.entries)
        key: switch (count) {
          1 => [],
          _ => List.generate(count, (index) => index + 1),
        },
    };

    Iterable<String> resolve() sync* {
      Iterable<String> replace(String path) sync* {
        final params = paramsFor(path);

        if (params.isEmpty) {
          yield path;
          return;
        }

        for (final key in params.keys) {
          final count = expandedParts[key];
          assert(count != null, 'Param $key not found in $allParts');

          final replacement = switch (count) {
            [final int index, ...] => '$key$index',
            _ => key,
          };

          if (count case final List<int> count when count.isNotEmpty) {
            expandedParts[key] = count.sublist(1);
          }

          yield path.replaceAll(':$key', '\${$replacement}');
        }
      }

      yield* replace(parentPath);
      if (path case final String path) {
        yield* replace(path);
      }
    }

    final resolved = resolve().join('/');

    return '/$resolved';
  }

  Map<String, int> paramsFor(String path) {
    final parts = path.split('/');

    final allParams = <String, int>{};
    void add(String param) {
      final count = allParams[param] ??= 0;
      allParams[param] = count + 1;
    }

    for (final part in parts) {
      if (!part.startsWith(':')) {
        continue;
      }

      final param = part.substring(1);
      add(param);
    }

    return allParams;
  }

  List<String> get params {
    final params = <String>[];
    for (final MapEntry(:key, value: count) in paramsFor(fullPath).entries) {
      if (count == 1) {
        params.add(key);
      } else {
        for (var i = 1; i <= count; i++) {
          params.add('$key$i');
        }
      }
    }

    return params;
  }

  @override
  List<ExtractImport?> get extractors => [returnType, ...parameters];

  @override
  List<ClientImports?> get imports => [];
}
