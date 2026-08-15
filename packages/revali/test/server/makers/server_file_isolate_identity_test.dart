import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:revali/server/converters/server_server.dart';
import 'package:revali/server/makers/server_file_maker.dart';
import 'package:revali/server/models/options.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:test/test.dart';

/// The generated server is the only thing that knows which isolate it is: the
/// parent spawns the workers, so nothing else can tell them apart. These
/// assert that it publishes that fact through `IsolateIdentity`, and -- the
/// part that silently does nothing if it regresses -- that it publishes it
/// *before* `runStartup`, which is where `createBroker()` runs.
void main() {
  String generate() {
    final server = ServerServer.fromMeta(
      const RevaliContext(flavor: null, mode: Mode.release),
      MetaServer(
        apps: [MetaAppConfig.defaultConfig()],
        public: const [],
        routes: const [],
      ),
    );

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;
    final emitter = DartEmitter.scoped(useNullSafetySyntax: true);

    return serverFile(
      server,
      (spec) => formatter(spec.accept(emitter).toString()),
      options: const Options(ignoreLints: []),
    );
  }

  /// Collapses whitespace so an assertion describes the emitted *code* rather
  /// than however the formatter chose to wrap it that day.
  String squash(String source) =>
      source.replaceAll(RegExp(r'\s+'), ' ').replaceAll(', ]', ' ]');

  // Same convention as sequential_content_golden_test.dart: set `GOLDEN_OUT`
  // to a directory to dump the generated server instead of asserting on it,
  // which is how you diff this output across a change to the maker.
  test('dump', () {
    if (Platform.environment['GOLDEN_OUT'] case final dir?) {
      Directory(dir).createSync(recursive: true);
      File('$dir/server.dart').writeAsStringSync(generate());
    }
  });

  test('declares the isolate index as a top-level, defaulting to the '
      'parent', () {
    expect(squash(generate()), contains('int _revaliIsolateIndex = 0;'));
  });

  test('the parent hands each worker the index it spawned it under', () {
    expect(
      squash(generate()),
      contains(
        'Isolate.spawn(_revaliWorkerMain, '
        '<Object>[ rawArgs, registration, i ])',
      ),
    );
  });

  test('the worker entrypoint unpacks that index', () {
    expect(
      squash(generate()),
      contains('_revaliIsolateIndex = boot[2] as int;'),
    );
  });

  test('createServer reads the index and resets it, so a hot reload does '
      'not inherit it', () {
    expect(
      squash(generate()),
      contains(
        'final isolateIndex = _revaliIsolateIndex; _revaliIsolateIndex = 0;',
      ),
    );
  });

  test('publishes the identity from the index and app.workers', () {
    expect(
      squash(generate()),
      contains(
        'IsolateIdentity.setCurrentForGeneratedCode( '
        'IsolateIdentity(index: isolateIndex, workerCount: app.workers), );',
      ),
    );
  });

  test('publishes the identity before runStartup, where createBroker '
      'runs', () {
    final content = generate();

    final identity = content.indexOf(
      'IsolateIdentity.setCurrentForGeneratedCode(',
    );
    final startup = content.indexOf('app.runStartup(');

    expect(identity, isNonNegative);
    expect(startup, isNonNegative);
    expect(
      identity,
      lessThan(startup),
      reason:
          'a broker built before the identity is set reads the default, '
          'and every worker would name itself isolate 0',
    );
  });

  test('publishes the identity even for an app with no consumers', () {
    // The whole point of emitting it outside the `hasConsumers` gate: which
    // isolate this is, is a general fact about the isolate, and messaging is
    // only its first consumer.
    final content = generate();

    expect(content, isNot(contains('ConsumerRegistry')));
    expect(content, contains('IsolateIdentity.setCurrentForGeneratedCode('));
  });
}
