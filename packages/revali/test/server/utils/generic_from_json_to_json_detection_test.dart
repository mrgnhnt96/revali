import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:test/test.dart';

import '../helpers/analysis_helper.dart';

void main() {
  late AnalysisHelper helper;

  setUpAll(() async {
    helper = await AnalysisHelper.create();
  });

  group('generic-argument-factories fromJson/toJson detection', () {
    test(
      'ApiResponse<T>.fromJson(Map, T Function(Object?)) is detected',
      () async {
        final element = await helper.classElement(
          unitPath: 'lib/models/api_response.dart',
          className: 'ApiResponse',
        );

        expect(element.hasFromJsonConstructor, isTrue);
        final ctor = element.fromJsonElement;
        expect(ctor, isA<ConstructorElement>());
        expect((ctor! as ConstructorElement).formalParameters, hasLength(2));
      },
    );

    test('ApiResponse<T>.toJson(Object? Function(T)) is detected', () async {
      final element = await helper.classElement(
        unitPath: 'lib/models/api_response.dart',
        className: 'ApiResponse',
      );

      expect(element.hasToJsonMember, isTrue);
      final method = element.toJsonElement;
      expect(method, isA<MethodElement>());
      expect((method! as MethodElement).formalParameters, hasLength(1));
    });

    test(
      'a plain non-generic fromJson/toJson is still detected unchanged',
      () async {
        final element = await helper.classElement(
          unitPath: 'lib/models/bodies.dart',
          className: 'UserBody',
        );

        expect(element.hasFromJsonConstructor, isTrue);
        final ctor = element.fromJsonElement! as ConstructorElement;
        expect(ctor.formalParameters, hasLength(1));
      },
    );
  });
}
