import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:revali/server/converters/server_lifecycle_component.dart';
import 'package:revali/server/makers/part_files/lifecycle_components/guard_content.dart';
import 'package:revali/server/makers/part_files/lifecycle_components/middleware_content.dart';
import 'package:revali/server/utils/annotation_arguments.dart';
import 'package:test/test.dart';

import '../helpers/analysis_helper.dart';

/// Set `GOLDEN_OUT` to a directory to dump the generated sources instead of
/// asserting -- used to diff output across a refactor of the makers.
void main() {
  late AnalysisHelper helper;

  setUpAll(() async {
    helper = await AnalysisHelper.create();
  });

  Future<({String guard, String middleware})> generate() async {
    final element = await helper.classElement(
      unitPath: 'lib/components/sequential_component.dart',
      className: 'SequentialComponent',
    );

    final component = ServerLifecycleComponent.fromClassElement(
      element,
      AnnotationArguments.none(),
    );

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;
    final emitter = DartEmitter.scoped(useNullSafetySyntax: true);
    String format(Spec spec) => formatter(spec.accept(emitter).toString());

    return (
      guard: guardContent(component, format),
      middleware: middlewareContent(component, format),
    );
  }

  test('guard and middleware content', () async {
    final content = await generate();

    if (Platform.environment['GOLDEN_OUT'] case final dir?) {
      Directory(dir).createSync(recursive: true);
      File('$dir/guard.dart').writeAsStringSync(content.guard);
      File('$dir/middleware.dart').writeAsStringSync(content.middleware);

      return;
    }

    expect(content.guard, contains('class SequentialComponentGuard'));
    expect(content.guard, contains('implements Guard'));
    expect(content.guard, contains('Future<GuardResult> protect('));
    expect(content.guard, contains('component.protect'));
    expect(content.guard, contains('result.isBlock'));
    expect(content.guard, contains('return const GuardResult.pass();'));

    expect(content.middleware, contains('class SequentialComponentMiddleware'));
    expect(content.middleware, contains('implements Middleware'));
    expect(content.middleware, contains('Future<MiddlewareResult> use('));
    expect(content.middleware, contains('component.handle'));
    expect(content.middleware, contains('result.isStop'));
    expect(
      content.middleware,
      contains('return const MiddlewareResult.next();'),
    );
  });
}
