import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:collection/collection.dart';
import 'package:revali/ast/checkers/checkers.dart';
import 'package:revali/ast/visitors/get_params.dart';
import 'package:revali_construct/revali_construct.dart';

class MethodVisitor extends RecursiveElementVisitor<void> {
  // Method name to method element
  Map<String, List<MetaMethod>> methods = {};

  @override
  void visitMethodElement(MethodElement element) {
    super.visitMethodElement(element);

    if (!methodChecker.hasAnnotationOf(element)) {
      return;
    }

    final annotation = methodChecker.annotationsOf(element);

    if (annotation.length > 1) {
      throw Exception('Only one method type per method is allowed');
    }

    final method = MethodAnnotation.fromAnnotation(annotation.first);

    // only one method type per method
    if (methods[method.name] case final parsed?) {
      for (final parsedMethod in parsed) {
        if (parsedMethod.path == method.path) {
          throw Exception('Conflicting paths ${parsedMethod.path}');
        }
      }
    }

    final params = getParams(element);

    final type = element.returnType.getDisplayString();

    final isFuture = element.returnType.isDartAsyncFuture ||
        element.returnType.isDartAsyncFutureOr;
    final isStream = element.returnType.isDartAsyncStream;
    Element? returnTypeElement;
    final typeArguments = <(String, DartType)>[];
    var isNullable = false;
    var isIterable = false;

    if (isFuture || isStream) {
      final returnType = element.returnType as InterfaceType;
      typeArguments.addAll([
        for (final type in returnType.typeArguments)
          (type.getDisplayString(), type),
      ]);

      final typeArg = returnType.typeArguments.first;

      returnTypeElement = typeArg.element;
      if (typeArg is InterfaceType) {
        isNullable = typeArg.nullabilitySuffix != NullabilitySuffix.none;
        if (typeFromIterable(typeArg) case final element?) {
          isIterable = true;
          returnTypeElement = element;
        }
      }
    } else {
      final returnType = element.returnType;
      returnTypeElement = returnType.element;

      isNullable = returnType.nullabilitySuffix != NullabilitySuffix.none;

      if (typeFromIterable(returnType) case final element?) {
        isIterable = true;
        returnTypeElement = element;
      }
    }

    (methods[method.name] ??= []).add(
      MetaMethod(
        name: element.name,
        method: method.name,
        path: method.path,
        params: params,
        isSse: method.isSse,
        returnType: MetaReturnType(
          isVoid: element.returnType is VoidType || type.contains('<void>'),
          isNullable: isNullable,
          type: type,
          typeArguments: typeArguments,
          resolvedElement: returnTypeElement,
          element: element,
          isFuture: isFuture,
          isStream: isStream,
          isIterable: isIterable,
        ),
        webSocketMethod: method.isWebSocket
            ? MetaWebSocketMethod.fromMeta(method.asWebSocket)
            : null,
        annotationsMapper: ({
          required List<OnMatch> onMatch,
          NonMatch? onNonMatch,
        }) =>
            getAnnotations(
          element: element,
          onNonMatch: onNonMatch,
          onMatch: onMatch,
        ),
      ),
    );
  }
}

Element? typeFromIterable(DartType type) {
  if (type is! InterfaceType) {
    return null;
  }

  final element = type.element;

  if (element is! ClassElement || type.typeArguments.isEmpty) {
    return null;
  }

  final iterableType = element.allSupertypes.firstWhereOrNull(
    (e) => e.getDisplayString().startsWith('Iterable'),
  );

  if (iterableType == null) {
    return null;
  }

  final iterableTypeArg = type.typeArguments.first;

  if (iterableTypeArg is! InterfaceType) {
    return null;
  }

  return iterableTypeArg.element;
}
