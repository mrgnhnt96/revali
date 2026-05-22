import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:revali_server/utils/substitute_type.dart';
import 'package:test/test.dart';

import '../helpers/analysis_helper.dart';

void main() {
  late AnalysisHelper helper;

  setUpAll(() async {
    helper = await AnalysisHelper.create();
  });

  group('buildTypeSubstitutionMap', () {
    test('maps class type parameters to instantiated type arguments', () async {
      final element = await helper.classElement(
        unitPath: 'lib/components/rate_limit.dart',
        className: 'RateLimit',
      );
      final userBody = await helper.classElement(
        unitPath: 'lib/models/bodies.dart',
        className: 'UserBody',
      );

      final map = buildTypeSubstitutionMap(element, [userBody.thisType]);

      expect(map.keys, ['T']);
      expect(map['T']!.getDisplayString(), 'UserBody');
    });

    test('returns empty map when a type argument is dynamic', () async {
      final element = await helper.classElement(
        unitPath: 'lib/components/rate_limit.dart',
        className: 'RateLimit',
      );
      final dynamicType = element.library.typeProvider.dynamicType;

      expect(buildTypeSubstitutionMap(element, [dynamicType]), isEmpty);
    });

    test('returns empty map when argument count does not match', () async {
      final element = await helper.classElement(
        unitPath: 'lib/components/rate_limit.dart',
        className: 'RateLimit',
      );

      expect(buildTypeSubstitutionMap(element, const []), isEmpty);
    });
  });

  group('substituteType', () {
    test('replaces a type parameter with a concrete type', () async {
      final rateLimit = await helper.classElement(
        unitPath: 'lib/components/rate_limit.dart',
        className: 'RateLimit',
      );
      final userBody = await helper.classElement(
        unitPath: 'lib/models/bodies.dart',
        className: 'UserBody',
      );
      final checkMethod = rateLimit.methods.firstWhere(
        (method) => method.name == 'check',
      );
      final bodyParam = checkMethod.formalParameters.first;
      final substitutions = buildTypeSubstitutionMap(rateLimit, [
        userBody.thisType,
      ]);

      final substituted = substituteType(bodyParam.type, substitutions);

      expect(substituted.getDisplayString(), 'UserBody');
    });

    test('replaces nested type parameters', () async {
      final rateLimit = await helper.classElement(
        unitPath: 'lib/components/rate_limit.dart',
        className: 'RateLimit',
      );
      final userBody = await helper.classElement(
        unitPath: 'lib/models/bodies.dart',
        className: 'UserBody',
      );
      final typeParameter = rateLimit.typeParameters.single.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
      final listOfT = rateLimit.library.typeProvider.listType(typeParameter);
      final substitutions = buildTypeSubstitutionMap(rateLimit, [
        userBody.thisType,
      ]);

      final substituted = substituteType(listOfT, substitutions);

      expect(substituted.getDisplayString(), 'List<UserBody>');
    });
  });
}
