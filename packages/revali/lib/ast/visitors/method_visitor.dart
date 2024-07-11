import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
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

    final type = element.returnType.getDisplayString(withNullability: false);

    final isFuture = element.returnType.isDartAsyncFuture ||
        element.returnType.isDartAsyncFutureOr;
    final isStream = element.returnType.isDartAsyncStream;
    Element? returnTypeElement;

    if (isFuture || isStream) {
      returnTypeElement =
          (element.returnType as InterfaceType).typeArguments.first.element;
    } else {
      returnTypeElement = element.returnType.element;
    }

    (methods[method.name] ??= []).add(
      MetaMethod(
        name: element.name,
        method: method.name,
        path: method.path,
        params: params,
        returnType: MetaReturnType(
          isVoid:
              element.returnType is VoidType ? true : type.contains('<void>'),
          isNullable:
              element.returnType.nullabilitySuffix != NullabilitySuffix.none,
          type: type,
          element: returnTypeElement,
          isFuture: isFuture,
          isStream: isStream,
        ),
        isWebSocket: method.isWebSocket,
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
