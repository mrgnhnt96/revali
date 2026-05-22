// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';
import 'package:revali_server/utils/substitute_type.dart';

class ServerLifecycleComponentMethod with ExtractImport {
  ServerLifecycleComponentMethod({
    required this.name,
    required this.isFuture,
    required this.returnType,
    required this.parameters,
    required this.exceptionType,
    required this.import,
  });

  static ServerLifecycleComponentMethod? fromElement(
    MethodElement object, {
    Map<String, DartType> typeSubstitutions = const {},
  }) {
    final name = object.name;

    final returnTypeAlias = object.returnType.alias?.element.name;
    String returnType;
    var isFuture = false;
    String? exceptionType;

    final importPaths = <String>{};

    final params = object.formalParameters
        .map(
          (param) => ServerParam.fromElement(
            param,
            typeSubstitutions: typeSubstitutions,
          ),
        )
        .toList();

    if (returnTypeAlias != null && aliasReturnTypes.contains(returnTypeAlias)) {
      returnType = returnTypeAlias;
    } else if (object.returnType case final InterfaceType type
        when type.isAnyFuture) {
      isFuture = true;
      final typeArg = type.typeArguments.first;

      final resolveReturnType = typeArg.getDisplayString();

      returnType = switch (typeArg) {
        InterfaceType() => typeArg.alias?.element.name ?? resolveReturnType,
        _ => resolveReturnType,
      };

      if (returnType.startsWith((ExceptionCatcherResult).name)) {
        throw ArgumentError('Exception types cannot be a Future type');
      }

      if (returnType == (Response).name && _hasNextResponseParam(params)) {
        returnType = wrapperResult;
      }
    } else {
      returnType = object.returnType.getDisplayString();

      if (object.returnType case final InterfaceType type
          when returnType.startsWith((ExceptionCatcherResult).name)) {
        returnType = (ExceptionCatcherResult).name;
        final exceptionElement = substituteType(
          type.typeArguments.single,
          typeSubstitutions,
        );
        exceptionType = exceptionElement.getDisplayString();
        if (exceptionElement.element?.library?.uri case final Uri uri) {
          importPaths.add(uri.toString());
        }
      }
    }

    if (!returnTypes.contains(returnType)) {
      return null;
    }

    if (name == null) {
      throw Exception('Method name is null');
    }

    return ServerLifecycleComponentMethod(
      name: name,
      isFuture: isFuture,
      returnType: returnType,
      parameters: params,
      exceptionType: exceptionType,
      import: ServerImports(importPaths),
    );
  }

  static bool _hasNextResponseParam(List<ServerParam> params) {
    return params.any((param) {
      if (param.type.name == nextResponse) {
        return true;
      }

      final normalized = param.type.name.replaceAll(' ', '');
      return normalized.startsWith('Future<Response>Function(');
    });
  }

  final String name;
  final String returnType;
  final bool isFuture;
  final List<ServerParam> parameters;
  final ServerImports import;

  /// The type of the exception that this method catches,
  /// If this method is not an exception catcher, this will be null
  final String? exceptionType;

  static const interceptorPre = 'InterceptorPreResult';
  static const interceptorPost = 'InterceptorPostResult';
  static const wrapperResult = 'WrapperResult';
  static const nextResponse = 'NextResponse';

  static final aliasReturnTypes = {
    interceptorPre,
    interceptorPost,
    wrapperResult,
  };

  static final returnTypes = {...coreReturnTypes, ...aliasReturnTypes};

  static final coreReturnTypes = {
    (GuardResult).name,
    (MiddlewareResult).name,
    (ExceptionCatcherResult).name,
  };

  bool get isGuard => returnType == (GuardResult).name;
  bool get isMiddleware => returnType == (MiddlewareResult).name;
  bool get isInterceptorPre => returnType == interceptorPre;
  bool get isInterceptorPost => returnType == interceptorPost;
  bool get isExceptionCatcher => returnType == (ExceptionCatcherResult).name;
  bool get isRequestWrapper =>
      returnType == wrapperResult && _hasNextResponseParam(parameters);

  @override
  List<ExtractImport?> get extractors => [...parameters];

  @override
  List<ServerImports?> get imports => [import];
}

extension _DartTypeX on DartType {
  bool get isAnyFuture => isDartAsyncFuture || isDartAsyncFutureOr;
}
