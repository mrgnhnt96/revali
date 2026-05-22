import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:revali_server/converters/server_lifecycle_component.dart';
import 'package:revali_server/makers/part_files/lifecycle_components/guard_content.dart';
import 'package:revali_server/utils/substitute_type.dart';
import 'package:test/test.dart';

import '../helpers/analysis_helper.dart';

void main() {
  late AnalysisHelper helper;

  setUpAll(() async {
    helper = await AnalysisHelper.create();
  });

  group('ServerLifecycleComponent generic type arguments', () {
    test('substitutes @Body() type from @RateLimit<BodyType>()', () async {
      final (:object, :annotation) = await helper.lifecycleComponentAnnotation(
        functionName: 'createUser',
        annotationName: 'RateLimit',
      );

      final component = ServerLifecycleComponent.fromDartObject(
        object,
        annotation,
      );

      expect(component.shouldSubstituteTypeArguments, isTrue);
      expect(component.cacheKey, 'RateLimit<UserBody>');
      expect(component.guardClass.className, 'RateLimitUserBodyGuard');
      expect(component.wrapperGenericTypes, isEmpty);
      expect(component.guards, hasLength(1));
      expect(component.guards.single.parameters.single.type.name, 'UserBody');
      expect(
        component.guards.single.parameters.single.type.hasFromJson,
        isTrue,
      );
      expect(component.params.single.name, 'maxRequests');
    });

    test('substitutes @Body() type from '
        '@LifecycleComponents([RateLimit<BodyType>])', () async {
      final (:object, :annotation) = await helper.lifecycleComponentsAnnotation(
        functionName: 'createOrder',
      );

      final components = ServerLifecycleComponent.fromTypeReference(
        object,
        annotation,
      );

      expect(components, hasLength(1));

      final component = components.single;

      expect(component.shouldSubstituteTypeArguments, isTrue);
      expect(component.cacheKey, 'RateLimit<OrderBody>');
      expect(component.guardClass.className, 'RateLimitOrderBodyGuard');
      expect(component.guards.single.parameters.single.type.name, 'OrderBody');
    });

    test('does not substitute when no type argument is provided', () async {
      final (:object, :annotation) = await helper.lifecycleComponentsAnnotation(
        functionName: 'genericRateLimit',
      );

      final components = ServerLifecycleComponent.fromTypeReference(
        object,
        annotation,
      );

      expect(components, hasLength(1));

      final component = components.single;

      expect(component.shouldSubstituteTypeArguments, isFalse);
      expect(component.cacheKey, 'RateLimit');
      expect(component.guardClass.className, 'RateLimitGuard');
      expect(component.guards.single.parameters.single.type.name, 'T');
    });

    test('uses distinct cache keys for distinct type arguments', () async {
      final user = ServerLifecycleComponent.fromDartObject(
        (await helper.lifecycleComponentAnnotation(
          functionName: 'createUser',
          annotationName: 'RateLimit',
        )).object,
        (await helper.lifecycleComponentAnnotation(
          functionName: 'createUser',
          annotationName: 'RateLimit',
        )).annotation,
      );
      final order = ServerLifecycleComponent.fromTypeReference(
        (await helper.lifecycleComponentsAnnotation(
          functionName: 'createOrder',
        )).object,
        (await helper.lifecycleComponentsAnnotation(
          functionName: 'createOrder',
        )).annotation,
      ).single;

      expect(user.cacheKey, isNot(order.cacheKey));
    });

    test('reads instantiated type arguments from annotation type', () async {
      final (:object, :annotation) = await helper.lifecycleComponentAnnotation(
        functionName: 'createUser',
        annotationName: 'RateLimit',
      );

      expect(object.type, isA<InterfaceType>());
      expect(typeArgumentsFrom(object.type!), [isA<InterfaceType>()]);
      expect(
        typeArgumentsFrom(object.type!).single.getDisplayString(),
        'UserBody',
      );

      expect(annotation, isNotNull);
    });
  });

  group('guardContent', () {
    test('generates fromJson binding for substituted @Body() type', () async {
      final (:object, :annotation) = await helper.lifecycleComponentAnnotation(
        functionName: 'createUser',
        annotationName: 'RateLimit',
      );

      final component = ServerLifecycleComponent.fromDartObject(
        object,
        annotation,
      );

      final formatter = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;
      final emitter = DartEmitter.scoped(useNullSafetySyntax: true);
      String format(Spec spec) => formatter(spec.accept(emitter).toString());

      final content = guardContent(component, format);

      expect(content, contains('class RateLimitUserBodyGuard'));
      expect(content, isNot(contains('class RateLimitUserBodyGuard<T>')));
      expect(content, contains('final component = RateLimit<UserBody>('));
      expect(content, contains('UserBody.fromJson'));
      expect(content, contains('resolvePayload'));
    });
  });
}
