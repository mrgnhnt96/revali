import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:revali/utils/extensions/class_element_extensions.dart';
import 'package:revali/utils/extensions/element_extensions.dart';
import 'package:revali_construct/revali_construct.dart';

Iterable<MetaParam> getParams(FunctionTypedElement element) {
  final params = <MetaParam>[];

  for (final param in element.parameters) {
    final type = param.type.getDisplayString();

    final element = param.type.element;
    if (element == null) {
      throw Exception('Element not found for type $type');
    }

    final hasFromJsonConstructor = switch (element) {
      final ClassElement element => element.hasFromJsonMember,
      _ => false,
    };

    params.add(
      MetaParam(
        name: param.name,
        type: MetaType(
          name: type,
          hasFromJsonConstructor: hasFromJsonConstructor,
          importPath: element.importPath,
        ),
        typeElement: element,
        nullable: param.type.nullabilitySuffix != NullabilitySuffix.none,
        isRequired: param.isRequired,
        isNamed: param.isNamed,
        defaultValue: param.defaultValueCode,
        annotationsFor: ({
          required List<OnMatch> onMatch,
          NonMatch? onNonMatch,
        }) =>
            getAnnotations(
          element: param,
          onMatch: onMatch,
          onNonMatch: onNonMatch,
        ),
      ),
    );
  }

  return params;
}
