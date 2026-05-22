import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:revali_server/converters/server_lifecycle_component.dart';
import 'package:revali_server/converters/server_lifecycle_component_method.dart';
import 'package:revali_server/utils/annotation_arguments.dart';
import 'package:test/test.dart';

void main() {
  test('detects Trace wrap from zonai project', () async {
    const path =
        '/Users/morgan/Documents/develop.nosync/dart_projects/zonai/apps/server/lib/components/lifecycle_components/trace_id.dart';
    final collection = AnalysisContextCollection(
      includedPaths: [
        '/Users/morgan/Documents/develop.nosync/dart_projects/zonai/apps/server',
      ],
    );
    final result = await collection
        .contextFor(path)
        .currentSession
        .getResolvedUnit(path);

    if (result is! ResolvedUnitResult) {
      fail('Failed to resolve $path');
    }

    for (final cls in result.libraryElement.classes) {
      if (cls.name != 'Trace') continue;

      for (final method in cls.methods) {
        if (method.name != 'wrap') continue;

        // ignore: avoid_print
        print(
          'return=${method.returnType.getDisplayString()} '
          'alias=${method.returnType.alias?.element.name}',
        );
        for (final p in method.formalParameters) {
          // ignore: avoid_print
          print('  param ${p.name}: ${p.type.getDisplayString()}');
        }

        final parsed = ServerLifecycleComponentMethod.fromElement(method);
        // ignore: avoid_print
        print('parsed=$parsed isWrapper=${parsed?.isRequestWrapper}');
        expect(parsed, isNotNull);
        expect(parsed!.isRequestWrapper, isTrue);
      }

      final component = ServerLifecycleComponent.fromClassElement(
        cls,
        AnnotationArguments.none(),
      );
      expect(component.hasRequestWrappers, isTrue);
    }
  });
}
