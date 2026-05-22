import 'package:analyzer/dart/element/element.dart';
import 'package:revali_client_gen/makers/creators/create_signature.dart';
import 'package:revali_client_gen/models/client_lifecycle_component.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_param.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_client_gen/models/websocket_type.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:test/test.dart';

import '../helpers/analysis_helper.dart';

void main() {
  group('ClientMethod integration', () {
    late AnalysisHelper helper;

    setUpAll(() async {
      helper = await AnalysisHelper.create();
    });

    Future<ClientMethod> methodFromAnalyzer({
      required String className,
      required String methodName,
      List<ClientLifecycleComponent> parentComponents = const [],
    }) async {
      final element = await helper.methodElement(
        unitPath: 'lib/controllers/get_controller.dart',
        className: className,
        methodName: methodName,
      );

      final lifecycleComponents = <ClientLifecycleComponent>[
        ...parentComponents,
      ];

      void collectLifecycle(Element annotatedElement) {
        getAnnotations(
          element: annotatedElement,
          onMatch: [
            OnMatch(
              classType: LifecycleComponent,
              package: 'revali_router_annotations',
              convert: (object, annotation) {
                lifecycleComponents.add(
                  ClientLifecycleComponent.fromDartObject(object, annotation),
                );
              },
            ),
            OnMatch(
              classType: LifecycleComponents,
              package: 'revali_router_annotations',
              convert: (object, annotation) {
                lifecycleComponents.addAll(
                  ClientLifecycleComponent.fromTypeReference(
                    object,
                    annotation,
                  ),
                );
              },
            ),
          ],
        );
      }

      collectLifecycle(element.enclosingElement!);
      collectLifecycle(element);

      return ClientMethod(
        name: element.name ?? methodName,
        parentPath: 'api',
        method: 'GET',
        path: '',
        returnType: ClientType.fromMeta(MetaType.fromType(element.returnType)),
        parameters: element.formalParameters
            .map(MetaParam.fromParam)
            .map(ClientParam.fromMeta)
            .whereType<ClientParam>()
            .toList(),
        lifecycleComponents: lifecycleComponents,
        isSse: false,
        websocketType: WebsocketType.none,
        isExcluded: false,
      );
    }

    int bodyParamCount(ClientMethod method) {
      return createSignature(
        method,
      ).optionalParameters.where((param) => param.name == 'body').length;
    }

    test(
      'emits one body param for @RateLimit<GetBody>() with endpoint body',
      () async {
        final method = await methodFromAnalyzer(
          className: 'GetController',
          methodName: 'get',
        );

        expect(bodyParamCount(method), 1);
        expect(
          method.allParams.where((param) => param.name == 'body').length,
          1,
        );
      },
    );

    test(
      'emits one body param when lifecycle is registered twice on a route',
      () async {
        final method = await methodFromAnalyzer(
          className: 'LifecycleComponentsGetController',
          methodName: 'get',
        );

        expect(bodyParamCount(method), 1);
        expect(
          method.allParams.where((param) => param.name == 'body').length,
          1,
        );
      },
    );

    test('generated signature exposes body only once', () async {
      final method = await methodFromAnalyzer(
        className: 'LifecycleComponentsGetController',
        methodName: 'get',
      );

      expect(bodyParamCount(method), 1);
    });
  });
}
