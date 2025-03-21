// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/element/element.dart';
import 'package:revali_client_gen/makers/utils/extract_import.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_record_prop.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';

class ClientType with ExtractImport {
  ClientType({
    required this.name,
    this.hasFromJsonConstructor = false,
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
    this.hasToJsonMember = false,
    this.method,
  })  : _typeArguments = typeArguments,
        _parent = null,
        _isVoid = isVoid;

  ClientType._required({
    required this.name,
    required this.hasFromJsonConstructor,
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
    required this.hasToJsonMember,
    this.method,
  })  : _typeArguments = typeArguments,
        _isVoid = isVoid;

  factory ClientType.fromMeta(MetaType type) {
    var import =
        ClientImports([if (type.importPath case final String path) path]);

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
      hasFromJsonConstructor: type.hasFromJsonConstructor,
      hasToJsonMember: type.hasToJsonMember,
      isNullable: type.isNullable,
      typeArguments: type.typeArguments.map(ClientType.fromMeta).toList(),
    );
  }

  factory ClientType.fromElement(ParameterElement element) {
    return ClientType.fromMeta(MetaType.fromType(element.type));
  }

  final String name;
  final bool hasFromJsonConstructor;
  final bool hasToJsonMember;
  final ClientImports? import;
  final bool isNullable;
  final IterableType? iterableType;
  final bool isRecord;
  final bool isStream;
  final bool isFuture;
  final bool isPrimitive;
  final bool isMap;
  final bool isDynamic;
  final bool isStringContent;
  final List<ClientType> _typeArguments;
  final List<ClientRecordProp>? recordProps;
  final bool _isVoid;
  bool get isVoid {
    if (_isVoid) {
      return true;
    }

    return typeArguments.any((e) => e._isVoid);
  }

  List<ClientType> get typeArguments => List.unmodifiable([
        for (final arg in _typeArguments) arg.._parent = this,
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

    if ((method.isSse, method.isWebsocket) case (true, true)) {
      if (isStream || isVoid) {
        return this;
      }

      return ClientType(
        name: 'Stream<$name>',
        isStream: true,
        method: method,
        typeArguments: [_copy()],
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
      hasFromJsonConstructor: hasFromJsonConstructor,
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
      hasToJsonMember: hasToJsonMember,
      method: method,
    );
  }

  @override
  List<ExtractImport?> get extractors => [];

  @override
  List<ClientImports?> get imports => [import];
}
