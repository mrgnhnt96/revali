import 'package:revali_construct/revali_construct.dart';
import 'package:revali_swagger/builders/schema_registry.dart';
import 'package:revali_swagger/models/swagger_method.dart';
import 'package:revali_swagger_annotations/revali_swagger_annotations.dart';

class SwaggerController {
  SwaggerController({
    required this.name,
    required this.path,
    required this.methods,
    required this.isHidden,
    required this.tag,
  });

  factory SwaggerController.fromMeta(MetaRoute route, SchemaRegistry registry) {
    var isHidden = false;
    String? tagOverride;

    route.annotationsFor(
      onMatch: [
        OnMatch(
          classType: ApiHidden,
          package: 'revali_swagger_annotations',
          convert: (object, annotation) {
            isHidden = true;
          },
        ),
        OnMatch(
          classType: ApiTag,
          package: 'revali_swagger_annotations',
          convert: (object, annotation) {
            tagOverride = object.getField('name')?.toStringValue();
          },
        ),
      ],
    );

    final simpleName = _simplifyControllerName(route.className);

    return SwaggerController(
      name: route.className,
      path: route.path,
      tag: tagOverride ?? simpleName,
      isHidden: isHidden,
      methods: route.methods
          .map((m) => SwaggerMethod.fromMeta(m, simpleName, registry))
          .toList(),
    );
  }

  final String name;
  final String path;
  final List<SwaggerMethod> methods;
  final bool isHidden;
  final String tag;

  bool get hasVisibleMethods => methods.any((m) => !m.isHidden);

  static String _simplifyControllerName(String className) {
    final stripped = className.endsWith('Controller')
        ? className.substring(0, className.length - 'Controller'.length)
        : className;
    return stripped.toLowerCase();
  }
}
