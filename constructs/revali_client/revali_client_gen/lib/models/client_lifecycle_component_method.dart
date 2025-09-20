// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_client_gen/makers/utils/extract_import.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_client_gen/models/client_param.dart';
import 'package:revali_router/revali_router.dart';

class ClientLifecycleComponentMethod with ExtractImport {
  ClientLifecycleComponentMethod({
    required this.parameters,
    required String returnType,
  }) : _returnType = returnType;

  static ClientLifecycleComponentMethod? fromElement(MethodElement object) {
    final returnTypeAlias = object.returnType.alias?.element.name;

    String returnType;
    if (returnTypeAlias != null && aliasReturnTypes.contains(returnTypeAlias)) {
      returnType = returnTypeAlias;
    } else if (object.returnType case final InterfaceType type
        when type.isAnyFuture) {
      final typeArg = type.typeArguments.first;

      final resolveReturnType = typeArg.getDisplayString();

      returnType = switch (typeArg) {
        InterfaceType() => typeArg.alias?.element.name ?? resolveReturnType,
        _ => resolveReturnType,
      };

      if (returnType.startsWith((ExceptionCatcherResult).name)) {
        return null;
      }
    } else {
      returnType = object.returnType.getDisplayString();

      if (returnType.startsWith((ExceptionCatcherResult).name)) {
        return null;
      }
    }

    if (!returnTypes.contains(returnType)) {
      return null;
    }

    final params = object.formalParameters
        .map(ClientParam.fromElement)
        .whereType<ClientParam>()
        .toList();

    return ClientLifecycleComponentMethod(
      parameters: params,
      returnType: returnType,
    );
  }

  final List<ClientParam> parameters;
  final String _returnType;

  static const interceptorPre = 'InterceptorPreResult';
  static const interceptorPost = 'InterceptorPostResult';

  static final aliasReturnTypes = {interceptorPre, interceptorPost};

  static final returnTypes = {...coreReturnTypes, ...aliasReturnTypes};

  static final coreReturnTypes = {
    (GuardResult).name,
    (MiddlewareResult).name,
    (ExceptionCatcherResult).name,
  };

  bool get isGuard => _returnType == (GuardResult).name;
  bool get isMiddleware => _returnType == (MiddlewareResult).name;
  bool get isInterceptorPre => _returnType == interceptorPre;
  bool get isInterceptorPost => _returnType == interceptorPost;

  @override
  List<ExtractImport?> get extractors => [...parameters];

  @override
  List<ClientImports?> get imports => [];
}

extension _DartTypeX on DartType {
  bool get isAnyFuture => isDartAsyncFuture || isDartAsyncFutureOr;
}
