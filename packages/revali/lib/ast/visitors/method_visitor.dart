import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor2.dart';
import 'package:revali/ast/checkers/checkers.dart';
import 'package:revali/ast/visitors/get_params.dart';
import 'package:revali_construct/revali_construct.dart';

class MethodVisitor extends RecursiveElementVisitor2<void> {
  MethodVisitor(this.controllerName);

  /// Display name of the enclosing controller class (for diagnostics).
  final String controllerName;

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
      throw Exception(
        'Only one method type per method is allowed '
        '(controller $controllerName, method ${element.name})',
      );
    }

    final method = MethodAnnotation.fromAnnotation(annotation.first);

    // only one method type per method
    if (methods[method.name] case final parsed?) {
      for (final parsedMethod in parsed) {
        if (parsedMethod.path == method.path) {
          final pathDesc = parsedMethod.path == null
              ? 'null'
              : '"${parsedMethod.path}"';
          throw Exception(
            'Conflicting paths in controller $controllerName: '
            '${method.name} routes ${parsedMethod.name} and '
            '${element.name} both use path $pathDesc',
          );
        }
      }
    }

    final params = getParams(element).toList();

    (methods[method.name] ??= []).add(
      MetaMethod(
        name: element.name ?? (throw Exception('Method name is null')),
        method: method.name,
        path: method.path,
        params: params,
        isSse: method.isSse,
        returnType: MetaType.fromType(element.returnType),
        webSocketMethod: method.isWebSocket
            ? MetaWebSocketMethod.fromMeta(method.asWebSocket)
            : null,
        annotationsFor:
            ({required List<OnMatch> onMatch, NonMatch? onNonMatch}) =>
                getAnnotations(
                  element: element,
                  onNonMatch: onNonMatch,
                  onMatch: onMatch,
                ),
      ),
    );
  }
}
