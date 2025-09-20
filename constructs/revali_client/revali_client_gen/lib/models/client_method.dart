import 'package:change_case/change_case.dart';
import 'package:revali_client/revali_client.dart';
import 'package:revali_client_gen/enums/parameter_position.dart';
import 'package:revali_client_gen/makers/utils/client_param_extensions.dart';
import 'package:revali_client_gen/makers/utils/extract_import.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_client_gen/models/client_lifecycle_component.dart';
import 'package:revali_client_gen/models/client_param.dart';
import 'package:revali_client_gen/models/client_record_prop.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_client_gen/models/websocket_type.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';

class ClientMethod with ExtractImport {
  ClientMethod({
    required this.name,
    required this.parameters,
    required ClientType returnType,
    required this.isSse,
    required this.websocketType,
    required this.path,
    required this.parentPath,
    required this.method,
    required this.lifecycleComponents,
    required this.isExcluded,
  }) : _returnType = returnType;

  factory ClientMethod.fromMeta(
    MetaMethod route,
    String parentPath,
    List<ClientLifecycleComponent> parentComponents,
  ) {
    final lifecycleComponents = <ClientLifecycleComponent>[...parentComponents];
    var isExcluded = false;

    route.annotationsFor(
      onMatch: [
        OnMatch(
          classType: LifecycleComponent,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            final component = ClientLifecycleComponent.fromDartObject(
              annotation,
            );

            lifecycleComponents.add(component);
          },
        ),
        OnMatch(
          classType: ExcludeFromClient,
          package: 'revali_client',
          convert: (object, annotation) {
            isExcluded = true;
          },
        ),
      ],
    );

    return ClientMethod(
      name: route.name,
      parentPath: parentPath,
      method: route.method,
      returnType: ClientType.fromMeta(route.returnType),
      parameters: ClientParam.fromMetas(route.params),
      websocketType: switch (route.webSocketMethod) {
        null => WebsocketType.none,
        final w when w.mode.isReceiveOnly => WebsocketType.canSendOnly,
        final w when w.mode.isSendOnly => WebsocketType.canReceiveOnly,
        final w when w.mode.isTwoWay => WebsocketType.canSendAndReceive,
        _ => WebsocketType.none,
      },
      isSse: route.isSse,
      path: route.path,
      lifecycleComponents: lifecycleComponents,
      isExcluded: isExcluded,
    );
  }

  final String name;
  final String? path;
  final String parentPath;
  final String? method;
  final ClientType _returnType;
  ClientType get returnType => _returnType..method = this;
  final List<ClientParam> parameters;
  final WebsocketType websocketType;
  final bool isSse;
  final List<ClientLifecycleComponent> lifecycleComponents;
  final bool isExcluded;

  ClientParam? get websocketBody {
    if (!websocketType.canSendAny) {
      return null;
    }

    final body = parameters.separate.body;
    if (body.isEmpty) {
      return null;
    }

    if (body case [final part] when part.access.isEmpty) {
      return switch (part.type) {
        ClientType(isStream: true) => part,
        ClientType(isFuture: true, typeArguments: [final type]) ||
        final type => part.changeType(
          ClientType(
            name: 'Stream<${type.name}>',
            isStream: true,
            typeArguments: [type],
            method: this,
          ),
        ),
      };
    }

    final params = StringBuffer();

    for (final param in body) {
      params.write('${param.type.name} ${param.name}, ');
    }

    return ClientParam(
      name: 'body',
      position: ParameterPosition.body,
      access: [],
      acceptMultiple: false,
      hasDefaultValue: false,
      type: ClientType(
        name: 'Stream<({$params})>',
        isStream: true,
        recordProps: [],
        method: this,
        typeArguments: [
          ClientType(
            name: '({$params})',
            typeArguments: [],
            isRecord: true,
            recordProps: [
              for (final param in body)
                ClientRecordProp(
                  name: param.name,
                  isNamed: true,
                  type: param.type..method = this,
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool get isWebsocket => websocketType != WebsocketType.none;

  List<ClientParam> get allParams => [
    ...lifecycleComponents.expand((e) => e.allParams),
    ...parameters,
  ];

  String get fullPath => [
    '',
    if (parentPath.isNotEmpty) parentPath,
    if (path case final String p) p,
  ].join('/');

  String get resolvedPath {
    final allParts = paramsFor(fullPath);

    if (allParts.isEmpty) {
      return fullPath.replaceFirst(RegExp(r'/$'), '');
    }

    final expandedParts = <String, List<int>>{
      for (final MapEntry(:key, value: count) in allParts.entries)
        key: switch (count) {
          1 => [],
          _ => List.generate(count, (index) => index + 1),
        },
    };

    Iterable<String> resolve() sync* {
      String replace(String path) {
        final params = paramsFor(path);

        if (params.isEmpty) {
          return path;
        }

        var updatedPath = path;

        for (final key in params.keys) {
          final count = expandedParts[key];
          assert(count != null, 'Param $key not found in $allParts');

          final replacement = switch (count) {
            [final int index, ...] => '$key$index',
            _ => key,
          }.toCamelCase();

          if (count case final List<int> count when count.isNotEmpty) {
            expandedParts[key] = count.sublist(1);
          }

          updatedPath = updatedPath.replaceAll(':$key', '\${$replacement}');
        }

        return updatedPath;
      }

      yield replace(parentPath);
      if (path case final String path) {
        yield replace(path);
      }
    }

    final resolved = resolve().join('/').replaceFirst(RegExp(r'/$'), '');

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
    Iterable<String> resolve() sync* {
      for (final MapEntry(:key, value: count) in paramsFor(fullPath).entries) {
        if (count == 1) {
          yield key.toCamelCase();
        } else {
          for (var i = 1; i <= count; i++) {
            yield '$key$i'.toCamelCase();
          }
        }
      }
    }

    return resolve().toList();
  }

  ({
    List<ClientParam> body,
    List<ClientParam> query,
    List<ClientParam> headers,
    List<ClientParam> cookies,
  })
  get separateParams {
    return allParams.separate;
  }

  @override
  List<ExtractImport?> get extractors => [returnType, ...parameters];

  @override
  List<ClientImports?> get imports => [];
}
