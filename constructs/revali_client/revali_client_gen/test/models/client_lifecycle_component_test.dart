import 'package:revali_client_gen/enums/parameter_position.dart';
import 'package:revali_client_gen/models/client_lifecycle_component.dart';
import 'package:revali_client_gen/models/client_param.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:test/test.dart';

import '../helpers/analysis_helper.dart';

void main() {
  group('ClientLifecycleComponent generic type arguments', () {
    late AnalysisHelper helper;

    setUpAll(() async {
      helper = await AnalysisHelper.create();
    });

    test('substitutes @Body() type from @RateLimit<BodyType>()', () async {
      final (:object, :annotation) = await helper.lifecycleComponentAnnotation(
        functionName: 'createUser',
        annotationName: 'RateLimit',
      );

      final component = ClientLifecycleComponent.fromDartObject(
        object,
        annotation,
      );

      expect(component.shouldSubstituteTypeArguments, isTrue);
      expect(component.guards.single.parameters.single.type.name, 'UserBody');
      expect(component.genericTypeParameterNames, ['T']);
    });

    test('substitutes @Body() type from '
        '@LifecycleComponents([RateLimit<BodyType>])', () async {
      final (:object, :annotation) = await helper.lifecycleComponentsAnnotation(
        functionName: 'createOrder',
      );

      final component = ClientLifecycleComponent.fromTypeReference(
        object,
        annotation,
      ).single;

      expect(component.guards.single.parameters.single.type.name, 'OrderBody');
    });
  });

  group('ClientLifecycleComponent', () {
    ClientParam bodyParam({required String type}) {
      return ClientParam(
        name: 'body',
        position: ParameterPosition.body,
        type: ClientType(name: type),
        access: [],
        acceptMultiple: false,
        hasDefaultValue: false,
      );
    }

    group('#shouldExcludeParamFromClient', () {
      test('excludes unsubstituted generic body params', () {
        final component = ClientLifecycleComponent(
          guards: [],
          middlewares: [],
          interceptors: (pre: [], post: []),
          instantiatedTypeArguments: [ClientType(name: 'GetBody')],
          genericTypeParameterNames: const ['T'],
        );

        expect(
          component.shouldExcludeParamFromClient(
            bodyParam(type: 'T'),
            const [],
          ),
          isTrue,
        );
      });

      test('excludes substituted body params covered by the endpoint', () {
        final component = ClientLifecycleComponent(
          guards: [],
          middlewares: [],
          interceptors: (pre: [], post: []),
          instantiatedTypeArguments: [ClientType(name: 'GetBody')],
          genericTypeParameterNames: const ['T'],
        );
        final endpointBody = bodyParam(type: 'GetBody');

        expect(
          component.shouldExcludeParamFromClient(bodyParam(type: 'GetBody'), [
            endpointBody,
          ]),
          isTrue,
        );
      });

      test('keeps substituted body params when endpoint has no body', () {
        final component = ClientLifecycleComponent(
          guards: [],
          middlewares: [],
          interceptors: (pre: [], post: []),
          instantiatedTypeArguments: [ClientType(name: 'GetBody')],
          genericTypeParameterNames: const ['T'],
        );

        expect(
          component.shouldExcludeParamFromClient(
            bodyParam(type: 'GetBody'),
            const [],
          ),
          isTrue,
        );
      });

      test(
        'excludes body params matching endpoint even without generic args',
        () {
          final component = ClientLifecycleComponent(
            guards: [],
            middlewares: [],
            interceptors: (pre: [], post: []),
            instantiatedTypeArguments: const [],
            genericTypeParameterNames: const [],
          );
          final endpointBody = bodyParam(type: 'GetBody');

          expect(
            component.shouldExcludeParamFromClient(bodyParam(type: 'GetBody'), [
              endpointBody,
            ]),
            isTrue,
          );
        },
      );
    });
  });
}
