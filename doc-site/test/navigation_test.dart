/// Checks that `lib/src/navigation.dart` and `content/` describe the same site.
///
/// These are the failures that are otherwise invisible: a page nobody linked is
/// still built and still served, it just cannot be reached, and a sidebar link
/// to a page that was renamed is a 404 that only a reader finds.
library;

import 'dart:io';

import 'package:revali_docs/src/navigation.dart';
import 'package:test/test.dart';

import 'support/docs_root.dart';

void main() {
  final routes = contentRoutes();

  group('navigation', () {
    test('every sidebar link resolves to a page under content/', () {
      final missing = [
        for (final item in flatNavigation)
          if (!routes.contains(item.href)) item.href,
      ];
      expect(missing, isEmpty, reason: 'sidebar links with no markdown file behind them');
    });

    test('every page under content/ is reachable from a sidebar', () {
      final linked = {for (final item in flatNavigation) item.href};
      final orphans = routes.difference(linked).difference(unlistedRoutes).toList()..sort();
      expect(
        orphans,
        isEmpty,
        reason: 'add these to lib/src/navigation.dart, or to unlistedRoutes if that is deliberate',
      );
    });

    test('no page is listed twice', () {
      final seen = <String, int>{};
      for (final item in flatNavigation) {
        seen.update(item.href, (count) => count + 1, ifAbsent: () => 1);
      }
      final duplicates = seen.entries.where((entry) => entry.value > 1).map((e) => e.key).toList();
      expect(duplicates, isEmpty, reason: 'a link listed twice reads as noise, not emphasis');
    });

    test('every section id is the first segment of its own pages', () {
      for (final section in sections) {
        expect(section.href, anyOf('/${section.id}', '/'), reason: '${section.title} tab');
        for (final item in itemsOf(section.entries)) {
          expect(
            item.href,
            anyOf(equals('/${section.id}'), startsWith('/${section.id}/')),
            reason:
                '${item.title} is listed under ${section.title} but does not live there, '
                'so sectionFor() would show the wrong sidebar',
          );
        }
      }
    });

    test('walking next from the first page visits every page exactly once', () {
      final flat = flatNavigation;
      final visited = <String>[];
      var current = flat.first;
      while (true) {
        visited.add(current.href);
        final next = neighborsOf(current.href).next;
        if (next == null) break;
        current = next;
      }
      expect(visited, hasLength(flat.length));
      expect(visited.toSet(), hasLength(flat.length));
    });

    test('prev and next are inverses', () {
      for (final item in flatNavigation) {
        if (neighborsOf(item.href).next case final next?) {
          expect(neighborsOf(next.href).previous?.href, item.href);
        }
      }
    });

    test('groupFor and sectionFor agree with the tree', () {
      for (final section in sections) {
        for (final item in itemsOf(section.entries)) {
          expect(sectionFor(item.href)?.id, section.id, reason: item.href);
        }
      }
      // A page listed directly under a section, not inside a group, has no
      // group — the breadcrumb renders just the section for those.
      expect(groupFor('/revali'), isNull);
      expect(groupFor('/revali/cli/dev')?.title, 'CLI');
      expect(groupFor('/constructs/revali_server/core/pipes')?.title, 'Core');
    });

    test('sidebar labels are short enough for the column', () {
      for (final item in flatNavigation) {
        expect(
          item.title.length,
          lessThanOrEqualTo(30),
          reason: '"${item.title}" will be ellipsised in a 17rem sidebar',
        );
      }
    });
  });

  group('content', () {
    test('every page has a title in its front matter', () {
      final untitled = <String>[];
      for (final file in contentFiles()) {
        final raw = file.readAsStringSync();
        if (!RegExp('^---\n(.*\n)*?title: ', multiLine: false).hasMatch(raw)) {
          untitled.add(file.path);
        }
      }
      expect(untitled, isEmpty, reason: 'the layout renders the <h1> from the title');
    });

    test('no page still contains a Docusaurus admonition fence', () {
      final leftovers = <String>[];
      for (final file in contentFiles()) {
        for (final line in file.readAsLinesSync()) {
          if (RegExp(r'^\s*:{3,}').hasMatch(line)) leftovers.add(file.path);
        }
      }
      expect(leftovers.toSet(), isEmpty, reason: 'these render as literal colons');
    });

    test('component tags are followed by a blank line', () {
      // `package:markdown` treats an HTML block as literal text until a blank
      // line, so `**bold**` on the line after `<Callout>` renders its asterisks.
      // The failure is silent, which is exactly why it is worth a test.
      final offenders = <String>[];
      for (final file in contentFiles()) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length - 1; i++) {
          final opens = RegExp(r'^<(Callout|CodeFile|Card|CardGrid|Hero)\b[^>]*>$');
          final closes = RegExp(r'^</(Callout|CodeFile|Card|CardGrid|Hero)>$');
          if (opens.hasMatch(lines[i]) && lines[i + 1].trim().isNotEmpty) {
            offenders.add('${file.path}:${i + 1} (after ${lines[i]})');
          }
          if (closes.hasMatch(lines[i + 1]) && lines[i].trim().isNotEmpty) {
            offenders.add('${file.path}:${i + 2} (before ${lines[i + 1]})');
          }
        }
      }
      expect(offenders, isEmpty);
    });

    test('internal links point at routes that exist', () {
      final problems = <String>[];
      final linkPattern = RegExp(r'\]\((/[^)\s]*)\)|^\[[^\]]+\]:\s*(/\S*)$', multiLine: true);

      for (final file in contentFiles()) {
        for (final match in linkPattern.allMatches(file.readAsStringSync())) {
          final target = (match.group(1) ?? match.group(2))!.split('#').first;
          if (target.isEmpty) continue;
          if (!routes.contains(target)) {
            problems.add('${file.path} -> $target');
          }
        }
      }
      expect(problems, isEmpty, reason: 'these are 404s the moment someone clicks them');
    });

    test('every code fence language has a registered grammar', () {
      // An unregistered language is not an unstyled block: the highlighter
      // looks the grammar up with a null assertion, so it fails the build.
      final languages = <String>{};
      for (final file in contentFiles()) {
        for (final line in file.readAsLinesSync()) {
          final match = RegExp(r'^```([a-zA-Z0-9_+-]+)\s*$').firstMatch(line);
          if (match != null) languages.add(match.group(1)!);
        }
      }
      // `dart` is bundled with the highlighter; `mermaid` is intercepted before
      // the code block component ever sees it.
      final handled = {...grammarLanguages, 'dart', 'mermaid'};
      expect(
        languages.difference(handled),
        isEmpty,
        reason: 'add a grammar in lib/src/grammars.dart',
      );
    });
  });
}

/// Kept in the test rather than imported so the check fails if `grammars` is
/// changed without anyone thinking about the fences in `content/`.
Set<String> get grammarLanguages => {
  'bash',
  'console',
  'sh',
  'powershell',
  'yaml',
  'json',
  'toml',
  'dockerfile',
  'http',
  'env',
  'text',
  'txt',
  'plaintext',
  'tree',
};

Iterable<File> contentFiles() => Directory(
  '${docsRoot()}/content',
).listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.md'));

Set<String> contentRoutes() {
  final base = '${docsRoot()}/content';
  return {
    for (final file in contentFiles())
      () {
        final segments = file.path
            .substring(base.length + 1)
            .replaceFirst(RegExp(r'\.md$'), '')
            .split('/');
        if (segments.last == 'index') segments.removeLast();
        return segments.isEmpty ? '/' : '/${segments.join('/')}';
      }(),
  };
}
