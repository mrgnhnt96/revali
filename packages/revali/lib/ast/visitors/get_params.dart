import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:revali_construct/revali_construct.dart';

Iterable<MetaParam> getParams(FunctionTypedElement element) {
  final params = <MetaParam>[];

  for (final param in element.parameters) {
    final type = param.type.getDisplayString(withNullability: false);

    final element = param.type.element;
    if (element == null) {
      throw Exception('Element not found for type $type');
    }

    String? typeImport;
    if (element.library?.isInSdk == false) {
      typeImport = element.librarySource?.uri.toString();
    }

    params.add(
      MetaParam(
        name: param.name,
        type: type,
        typeImport: typeImport,
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
