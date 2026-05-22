import 'package:revali_server/converters/server_lifecycle_component.dart';
import 'package:revali_server/converters/server_lifecycle_component_method.dart';
import 'package:revali_server/utils/annotation_arguments.dart';
import 'package:test/test.dart';

import '../helpers/analysis_helper.dart';

void main() {
  late AnalysisHelper helper;

  setUpAll(() async {
    helper = await AnalysisHelper.create();
  });

  test('detects WrapperResult method with NextResponse parameter', () async {
    final element = await helper.classElement(
      unitPath: 'lib/wrapper_component.dart',
      className: 'RequestScope',
    );

    final component = ServerLifecycleComponent.fromClassElement(
      element,
      AnnotationArguments.none(),
    );

    for (final method in element.methods) {
      final returnTypeAlias = method.returnType.alias?.element.name;
      final returnDisplay = method.returnType.getDisplayString();
      final paramNames = [
        for (final p in method.formalParameters) p.type.getDisplayString(),
      ];
      // ignore: avoid_print
      print(
        'method ${method.name}: alias=$returnTypeAlias display=$returnDisplay '
        'params=$paramNames',
      );
      final parsed = ServerLifecycleComponentMethod.fromElement(method);
      // ignore: avoid_print
      print(
        'parsed=$parsed returnType=${parsed?.returnType} '
        'isWrapper=${parsed?.isRequestWrapper}',
      );
    }

    expect(component.hasRequestWrappers, isTrue);
    expect(component.requestWrappers, hasLength(1));
    expect(component.requestWrappers.single.name, 'wrap');
    expect(
      component.requestWrapperClass.className,
      'RequestScopeRequestWrapper',
    );
  });
}
