#!/usr/bin/env dart

/// Renders one social card per docs page into web/images/og/.
///
/// The card carries the page's own title, so a link to a docs page previews as
/// that page rather than as the site. Every card is a PNG because no social
/// platform renders an SVG og:image.
///
/// Routes and file names are derived here the same way `RevaliDocsLayout`
/// derives them in lib/main.server.dart -- `ogCardSlug` is the shared rule, and
/// `--check` fails if the two ever disagree about what exists.
///
/// Cards are cached by a hash of the inputs that can change their pixels, so a
/// rebuild that touches one page's title re-renders one card, not 97.
///
///     dart run tool/gen_og_cards.dart            # render what changed
///     dart run tool/gen_og_cards.dart --force    # ignore the cache
///     dart run tool/gen_og_cards.dart --check    # fail if anything is stale
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:og_card/og_card.dart';

import 'src/docs_card.dart';

/// The file name a route's card is written to.
///
/// Kept deliberately dumb: `/revali/cli/routes` becomes `revali-cli-routes`, so
/// the mapping can be reproduced in the layout without sharing code across the
/// tool/site boundary.
String ogCardSlug(String route) {
  final trimmed = route.replaceAll(RegExp(r'^/|/$'), '');
  if (trimmed.isEmpty) return 'index';
  return trimmed.replaceAll('/', '-');
}

class _Page {
  _Page(this.route, this.title, this.source);

  final String route;
  final String title;
  final String source;
}

void main(List<String> args) {
  final force = args.contains('--force');
  final check = args.contains('--check');

  final root = Directory.current;
  final contentDir = Directory('${root.path}/content');
  final outDir = Directory('${root.path}/web/images/og');
  final fontDir = '${root.path}/tool/fonts';

  if (!contentDir.existsSync()) {
    stderr.writeln('run this from doc-site/: no content/ here');
    exitCode = 1;
    return;
  }

  final bold = TypeFace.fromBytes(File('$fontDir/Nunito-Bold.ttf').readAsBytesSync());
  final semi = TypeFace.fromBytes(File('$fontDir/Nunito-SemiBold.ttf').readAsBytesSync());

  // The fonts are part of the output: swap the typeface and every card is
  // stale, even though no title moved.
  final fontFingerprint = md5
      .convert([
        ...File('$fontDir/Nunito-Bold.ttf').readAsBytesSync(),
        ...File('$fontDir/Nunito-SemiBold.ttf').readAsBytesSync(),
      ])
      .toString()
      .substring(0, 12);

  final pages = _collect(contentDir, root.path);
  pages.sort((a, b) => a.route.compareTo(b.route));

  final manifestFile = File('${outDir.path}/.manifest.json');
  final cached = <String, String>{};
  if (!force && manifestFile.existsSync()) {
    final decoded = jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
    for (final entry in decoded.entries) {
      cached[entry.key] = entry.value! as String;
    }
  }

  outDir.createSync(recursive: true);

  final manifest = <String, String>{};
  final stale = <String>[];
  var rendered = 0;
  final watch = Stopwatch()..start();

  for (final page in pages) {
    final slug = ogCardSlug(page.route);
    final key = '$slug.png';
    final fingerprint = md5
        .convert(utf8.encode('$templateVersion|$fontFingerprint|${page.title}'))
        .toString();
    manifest[key] = fingerprint;

    final target = File('${outDir.path}/$key');
    if (cached[key] == fingerprint && target.existsSync()) continue;

    stale.add('${page.route}  ->  web/images/og/$key');
    if (check) continue;

    target.writeAsBytesSync(renderDocsCard(title: page.title, bold: bold, semi: semi));
    rendered++;
  }

  // A page that was deleted or renamed leaves a card behind that nothing links
  // to; without this the directory only ever grows.
  final orphans = <File>[];
  if (outDir.existsSync()) {
    for (final entity in outDir.listSync()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name == '.manifest.json') continue;
      if (!manifest.containsKey(name)) orphans.add(entity);
    }
  }

  if (check) {
    if (stale.isEmpty && orphans.isEmpty) {
      stdout.writeln('${pages.length} cards up to date');
      return;
    }
    stderr.writeln('social cards are stale; run dart run tool/gen_og_cards.dart');
    for (final line in stale) {
      stderr.writeln('  stale   $line');
    }
    for (final file in orphans) {
      stderr.writeln('  orphan  ${file.uri.pathSegments.last}');
    }
    exitCode = 1;
    return;
  }

  for (final file in orphans) {
    file.deleteSync();
  }

  manifestFile.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');

  watch.stop();
  stdout
    ..writeln(
      'web/images/og/  $rendered rendered, '
      '${pages.length - rendered} cached'
      '${orphans.isEmpty ? '' : ', ${orphans.length} removed'}',
    )
    ..writeln('${watch.elapsedMilliseconds}ms');
}

/// Every markdown page under `content/`, with the route jaspr_content will
/// serve it at.
List<_Page> _collect(Directory contentDir, String root) {
  final pages = <_Page>[];
  for (final entity in contentDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.md')) continue;
    // `_data/` holds site.yaml and friends, not pages.
    if (entity.path.contains('/_')) continue;

    var relative = entity.path.substring('$root/content/'.length).replaceAll(RegExp(r'\.md$'), '');
    if (relative == 'index') {
      relative = '';
    } else if (relative.endsWith('/index')) {
      relative = relative.substring(0, relative.length - '/index'.length);
    }

    final route = '/$relative'.replaceAll(RegExp(r'/$'), '');
    final title = _title(entity) ?? _titleFromRoute(route);
    pages.add(_Page(route.isEmpty ? '/' : route, title, entity.path));
  }
  return pages;
}

/// Reads `title:` out of the YAML front matter.
///
/// Deliberately not a YAML parse: front matter here is flat, and pulling in a
/// parser to read one key would be the largest dependency in this tool.
String? _title(File file) {
  final lines = file.readAsLinesSync();
  if (lines.isEmpty || lines.first.trim() != '---') return null;
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim() == '---') break;
    final match = RegExp(r'^title\s*:\s*(.+)$').firstMatch(line);
    if (match == null) continue;
    var value = match.group(1)!.trim();
    if (value.length >= 2 &&
        (value.startsWith('"') && value.endsWith('"') ||
            value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    return value.isEmpty ? null : value;
  }
  return null;
}

String _titleFromRoute(String route) {
  if (route.isEmpty || route == '/') return 'Documentation';
  final last = route.split('/').last.replaceAll('-', ' ');
  return last
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
