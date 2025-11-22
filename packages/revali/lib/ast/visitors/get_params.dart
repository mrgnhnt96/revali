import 'package:analyzer/dart/element/element2.dart';
import 'package:revali_construct/revali_construct.dart';

Iterable<MetaParam> getParams(FunctionTypedElement element) {
  final params = <MetaParam>[];

  for (final param in element.formalParameters) {
    params.add(
      MetaParam(
        name: param.name ?? (throw Exception('Parameter name is null')),
        type: MetaType.fromType(param.type),
        literalValue: null,
        isRequired: param.isRequired,
        isNamed: param.isNamed,
        defaultValue: param.defaultValueCode,
        annotationsFor:
            ({required List<OnMatch> onMatch, NonMatch? onNonMatch}) =>
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
