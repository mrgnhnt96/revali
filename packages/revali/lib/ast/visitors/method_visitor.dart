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

  /// Methods annotated with `@Consumes`.
  ///
  /// Kept apart from [methods]: a consumer has no verb and no path, so it is
  /// not a route and must not be registered as one.
  final List<MetaConsumer> consumers = [];

  /// Dart method names already registered as routes.
  ///
  /// The controller's own methods are visited before its supertypes', so an
  /// override wins and the inherited annotation is skipped rather than
  /// registering a second route for the same method.
  ///
  /// Only *registered* names are recorded: an override that drops the
  /// annotation is not a route of its own, so the inherited one still
  /// applies and dispatches to the override at runtime.
  final Set<String> _registered = {};

  @override
  void visitMethodElement(MethodElement element) {
    super.visitMethodElement(element);

    if (consumesChecker.hasAnnotationOf(element)) {
      _visitConsumer(element);

      return;
    }

    if (!methodChecker.hasAnnotationOf(element)) {
      return;
    }

    if (element.name case final name? when _registered.contains(name)) {
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
    final name = element.name ?? (throw Exception('Method name is null'));

    _registered.add(name);

    (methods[method.name] ??= []).add(
      MetaMethod(
        name: name,
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

  void _visitConsumer(MethodElement element) {
    final name = element.name ?? (throw Exception('Method name is null'));

    if (_registered.contains(name)) {
      return;
    }

    if (methodChecker.hasAnnotationOf(element)) {
      throw Exception(
        'A method cannot be both a route and a consumer '
        '(controller $controllerName, method $name)',
      );
    }

    final annotations = consumesChecker.annotationsOf(element);

    if (annotations.length > 1) {
      // Several topics on one handler would each need their own group and
      // their own registration; two annotations is ambiguous rather than
      // additive.
      throw Exception(
        'Only one @Consumes per method is allowed '
        '(controller $controllerName, method $name)',
      );
    }

    final annotation = annotations.first;
    final topic = annotation.getField('topic')?.toStringValue();
    final group = annotation.getField('group')?.toStringValue();

    if (topic == null || topic.isEmpty || group == null || group.isEmpty) {
      throw Exception(
        '@Consumes needs a topic and a group '
        '(controller $controllerName, method $name)',
      );
    }

    final params = getParams(element).toList();

    if (params.length > 1) {
      // Rejected here rather than emitting code that will not compile: the
      // error names the method, which a build failure in generated output
      // would not.
      throw Exception(
        'A consumer takes at most one parameter, a BrokerMessage '
        '(controller $controllerName, method $name)',
      );
    }

    if (params.isNotEmpty && params.first.type.name != 'BrokerMessage') {
      throw Exception(
        'A consumer parameter must be a BrokerMessage, got '
        '${params.first.type.name} '
        '(controller $controllerName, method $name)',
      );
    }

    _registered.add(name);

    consumers.add(
      MetaConsumer(name: name, topic: topic, group: group, params: params),
    );
  }
}
