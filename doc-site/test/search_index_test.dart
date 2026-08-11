/// Exercises the committed search index and the ranking that reads it.
///
/// The ranking tests are the ones worth reading: each names a query someone
/// would actually type and the page they meant. Search that returns *a* result
/// is easy; search that returns the right one first is what these pin down.
library;

import 'dart:convert';
import 'dart:io';

import 'package:revali_docs/src/search_index.dart';
import 'package:test/test.dart';

import 'support/docs_root.dart';

void main() {
  final root = docsRoot();
  final index = [
    for (final doc
        in (jsonDecode(File('$root/web/search-index.json').readAsStringSync())
                as Map<String, Object?>)['docs']!
            as List)
      SearchDoc.fromJson(doc as Map<String, Object?>),
  ];

  group('index', () {
    test('is current with content/', () {
      // Shells out rather than reimplementing the generator, so this cannot
      // pass against a bug the generator and the test share.
      final result = Process.runSync(Platform.resolvedExecutable, [
        'run',
        'tool/build_search_index.dart',
        '--check',
      ], workingDirectory: root);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    });

    test('covers every page', () {
      expect(index.length, greaterThanOrEqualTo(96));
      for (final doc in index) {
        expect(doc.url, startsWith('/'));
        expect(doc.title, isNotEmpty);
        expect(doc.sections, isNotEmpty, reason: '${doc.url} indexed no text at all');
      }
    });

    test('labels every page with its section', () {
      for (final doc in index.where((doc) => doc.url != '/')) {
        expect(doc.group, anyOf('Revali', 'Constructs', 'Create Constructs'), reason: doc.url);
      }
    });

    test('keeps identifiers intact through markdown stripping', () {
      // A naive `replaceAll(RegExp(r'[`*_#]'), '')` turns `revali_server` into
      // `revaliserver` — exactly the token people search for.
      for (final term in ['revali_server', 'revali_client', 'implied_binding', 'revali.yaml']) {
        expect(
          searchIndex(index, term),
          isNotEmpty,
          reason: '"$term" survives nowhere in the index',
        );
      }
    });

    test('keeps code block contents', () {
      // `@Controller` and `GuardResult` appear only inside fenced code.
      for (final term in ['@Controller', 'GuardResult', 'AppConfig']) {
        expect(searchIndex(index, term), isNotEmpty, reason: term);
      }
    });

    test('requires every token to match', () {
      expect(searchIndex(index, 'middleware kubernetes'), isEmpty);
      expect(searchIndex(index, 'middleware'), isNotEmpty);
    });

    test('empty and whitespace queries return nothing', () {
      expect(searchIndex(index, ''), isEmpty);
      expect(searchIndex(index, '   '), isEmpty);
    });
  });

  group('ranking', () {
    /// The page a query should land on, first result.
    const expectations = {
      'guards': '/constructs/revali_server/lifecycle-components/advanced/guards',
      'exception catcher':
          '/constructs/revali_server/lifecycle-components/advanced/exception-catchers',
      'websockets': '/constructs/revali_server/response/websockets',
      'hot reload': '/revali/getting-started/hot-reload',
      'flavors': '/revali/app-configuration/flavors',
      'revali doctor': '/revali/cli/doctor',
      'pipes': '/constructs/revali_server/core/pipes',
      'server sent events': '/constructs/revali_server/response/server-sent-events',
      'environment variables': '/revali/app-configuration/env-vars',
      'type inference': '/constructs/revali_swagger/type-inference',
      'get_it': '/constructs/revali_client/integrations/get_it',
      'construct lifecycle': '/create-constructs/core/construct-lifecycle',
    };

    for (final MapEntry(key: query, value: expected) in expectations.entries) {
      test('"$query" ranks $expected first', () {
        final hits = searchIndex(index, query);
        expect(hits, isNotEmpty, reason: 'no results at all');
        expect(
          hits.first.href.split('#').first,
          expected,
          reason: 'got: ${hits.take(3).map((hit) => '${hit.href} (${hit.score})').join(', ')}',
        );
      });
    }

    test('caps results so one page cannot crowd out the rest', () {
      final hits = searchIndex(index, 'the');
      expect(hits.length, lessThanOrEqualTo(24));
      final perPage = <String, int>{};
      for (final hit in hits) {
        final page = hit.href.split('#').first;
        perPage.update(page, (count) => count + 1, ifAbsent: () => 1);
      }
      expect(perPage.values, everyElement(lessThanOrEqualTo(3)));
    });

    test('snippets are windowed around the match', () {
      final hits = searchIndex(index, 'websockets');
      expect(hits.first.snippet.length, lessThanOrEqualTo(200));
    });
  });

  group('anchors', () {
    // Runs against the built site, so it validates a hand-rolled
    // reimplementation of `package:markdown`'s slug algorithm against every
    // real heading rather than against itself. Skipped when there is no build.
    final buildDir = Directory('$root/build/jaspr');

    test(
      'every deep link in the index exists as an id in the built HTML',
      () {
        final missing = <String>[];

        for (final doc in index) {
          final path = doc.url == '/' ? 'index.html' : '${doc.url.substring(1)}/index.html';
          final file = File('${buildDir.path}/$path');
          if (!file.existsSync()) {
            missing.add('${doc.url}: no built page at $path');
            continue;
          }
          final html = file.readAsStringSync();
          for (final section in doc.sections) {
            if (section.anchor case final anchor?) {
              if (!html.contains('id="$anchor"')) {
                missing.add('${doc.url}#$anchor');
              }
            }
          }
        }

        expect(missing, isEmpty, reason: 'search results that deep-link to nothing');
      },
      skip: buildDir.existsSync() ? null : 'run `jaspr build` first',
    );
  });
}
