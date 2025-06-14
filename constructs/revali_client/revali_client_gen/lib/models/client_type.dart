// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/element/element.dart';
import 'package:revali_client_gen/makers/utils/extract_import.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_from_json.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_record_prop.dart';
import 'package:revali_client_gen/models/client_to_json.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';

class ClientType with ExtractImport {
  ClientType({
    required this.name,
    this.fromJson,
    this.import,
    this.isNullable = false,
    this.iterableType,
    this.isRecord = false,
    this.isStream = false,
    this.isFuture = false,
    List<ClientType> typeArguments = const [],
    this.recordProps,
    bool isVoid = false,
    this.isPrimitive = false,
    this.isDynamic = false,
    this.isMap = false,
    this.isStringContent = false,
    this.toJson,
    this.method,
    this.isEnum = false,
  })  : _typeArguments = typeArguments,
        _parent = null,
        _isVoid = isVoid;

  ClientType._required({
    required this.name,
    required this.fromJson,
    required this.import,
    required this.isNullable,
    required this.iterableType,
    required this.isRecord,
    required this.isStream,
    required this.isFuture,
    required List<ClientType> typeArguments,
    required this.recordProps,
    required bool isVoid,
    required this.isPrimitive,
    required this.isDynamic,
    required this.isMap,
    required this.isStringContent,
    required this.toJson,
    required this.isEnum,
    required this.method,
  })  : _typeArguments = typeArguments,
        _isVoid = isVoid;

  factory ClientType.fromMeta(MetaType type) {
    var import = ClientImports.fromElement(type.element);

    final (resolvedName, isStringContent) =
        switch (type.element?.name ?? type.name) {
      final e when e == (StringContent).name => ('String', true),
      final e => (e, false),
    };

    if (isStringContent) {
      import = ClientImports([]);
    }

    return ClientType._required(
      name: type.name,
      import: import,
      isVoid: type.isVoid,
      isStream: type.isStream,
      isFuture: type.isFuture,
      isStringContent: isStringContent,
      isPrimitive: type.isPrimitive,
      iterableType: type.iterableType,
      isRecord: type.isRecord,
      recordProps: type.recordProps?.map(ClientRecordProp.fromMeta).toList(),
      isDynamic: type.isDynamic,
      isMap: type.isMap,
      fromJson: ClientFromJson.fromMeta(type.fromJson),
      toJson: ClientToJson.fromMeta(type.toJson),
      isNullable: type.isNullable,
      typeArguments: type.typeArguments.map(ClientType.fromMeta).toList(),
      isEnum: type.isEnum,
      method: null,
    );
  }

  factory ClientType.fromElement(ParameterElement element) {
    return ClientType.fromMeta(MetaType.fromType(element.type));
  }

  final String name;
  final ClientFromJson? fromJson;
  final ClientToJson? toJson;
  final ClientImports? import;
  final bool isNullable;
  final IterableType? iterableType;
  final bool isRecord;
  final bool isStream;
  final bool isFuture;
  final bool isPrimitive;
  final bool isMap;
  final bool isDynamic;
  final bool isEnum;
  final bool isStringContent;
  final List<ClientType> _typeArguments;
  final List<ClientRecordProp>? recordProps;

  bool get hasFromJson => fromJson != null;
  bool get hasToJsonMember => toJson != null;

  final bool _isVoid;
  bool get isVoid {
    if (_isVoid) {
      return true;
    }

    return typeArguments.any((e) => e._isVoid);
  }

  List<ClientType> get typeArguments => List.unmodifiable([
        for (final arg in _typeArguments)
          arg
            .._parent = this
            ..method = method,
      ]);

  ClientMethod? method;

  ClientType? _parent;
  ClientType? get parent => _parent;
  bool get isRoot => root.name == name;
  bool get isIterable => iterableType != null;

  ClientType get root {
    if (parent == null) return this;

    var current = parent;
    while (true) {
      if (current == null) return this;

      if (current.parent == null) return current;

      current = current.parent;
    }
  }

  bool get isBytes {
    final pattern = RegExp(r'(?:List<){1,2}int(?:>\??){1,2}');
    bool isBytes(String name) {
      return pattern.hasMatch(name);
    }

    final root = this.root;

    if (root.name == name && isBytes(name)) {
      return true;
    }

    bool iterate(ClientType type) {
      if (isBytes(type.name)) {
        return true;
      }

      return type.typeArguments.any(iterate);
    }

    return iterate(root);
  }

  /// The Client's type can differ fromt the Server's type. For example,
  /// if the server is returning a `Stream<String>` the client will receive
  /// a `List<String>` because the stream is sent to the client as a list.
  ClientType get typeForClient {
    final method = this.method;
    if (!isRoot || method == null) {
      // ignore: avoid_returning_this
      return this;
    }

    if (method
        case ClientMethod(isWebsocket: true) || ClientMethod(isSse: true)) {
      if (isStream) {
        return this;
      }

      if (isVoid) {
        if (!isFuture) {
          return ClientType(
            name: 'Future<$name>',
            isFuture: true,
            method: method,
            typeArguments: [_copy()],
          );
        }

        return this;
      }

      var type = switch (this) {
        ClientType(isFuture: true, typeArguments: [final type]) => type,
        _ => this,
      };

      if (type
          case ClientType(
            iterableType: IterableType.list,
            typeArguments: [
              ClientType(
                iterableType: IterableType.list,
              )
            ]
          )) {
        type = type.typeArguments.first;
      }

      return ClientType(
        name: 'Stream<${type.name}>',
        isStream: true,
        method: method,
        typeArguments: [type._copy()],
      );
    }

    if (isBytes && isStream) {
      return this;
    }

    if (!isFuture && !isStream) {
      return ClientType(
        name: 'Future<$name>',
        isFuture: true,
        method: method,
        typeArguments: [_copy()],
      );
    }

    return this;
  }

  ClientType _copy() {
    return ClientType._required(
      name: name,
      fromJson: fromJson,
      import: import,
      isNullable: isNullable,
      iterableType: iterableType,
      isRecord: isRecord,
      isStream: isStream,
      isFuture: isFuture,
      typeArguments: _typeArguments,
      recordProps: recordProps,
      isVoid: isVoid,
      isPrimitive: isPrimitive,
      isDynamic: isDynamic,
      isMap: isMap,
      isStringContent: isStringContent,
      toJson: toJson,
      method: method,
      isEnum: isEnum,
    );
  }

  @override
  List<ExtractImport?> get extractors => [...typeArguments];

  @override
  List<ClientImports?> get imports {
    Iterable<ClientImports?> iterate(ClientType type) sync* {
      yield type.import;

      for (final type in type.typeArguments) {
        yield* iterate(type);
      }
    }

    return iterate(this).toList();
  }

  String get nonNullName => name.replaceAll(RegExp(r'\?$'), '');

  String get nullName {
    if (name.endsWith('?')) {
      return name;
    }

    return '$name?';
  }
}
