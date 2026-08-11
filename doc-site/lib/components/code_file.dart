/// `<CodeFile name="routes/main_app.dart">` — a filename header above a code
/// block.
///
/// The Docusaurus source wrote these as fence metadata:
///
/// ```md
/// ```dart title="routes/main_app.dart"
/// ```
///
/// `package:markdown` keeps only the first word of a fence's info string, so
/// the title is dropped without a warning — 163 code blocks on this site would
/// have silently lost the one line saying which file they belong in. The
/// migration rewrote them into this wrapper instead.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

/// Wraps a code block with a header naming the file it belongs to.
final class CodeFile extends CustomComponentBase {
  const CodeFile();

  @override
  Pattern get pattern => RegExp(r'^CodeFile$');

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    final fileName = attributes['name'] ?? '';
    return Component.fragment([
      Document.head(children: [Style(styles: _styles)]),
      div(classes: 'code-file', [
        div(classes: 'code-file-name', [
          span(classes: 'code-file-icon', [RawText(_iconFor(fileName))]),
          Component.text(fileName),
        ]),
        ?child,
      ]),
    ]);
  }
}

/// Picks a glyph from the extension, so the header reads at a glance.
///
/// Deliberately three shapes rather than a per-language icon set: the filename
/// is right there, and a wall of tiny brand marks is noisier than it is useful.
String _iconFor(String fileName) {
  final name = fileName.toLowerCase();
  if (name.endsWith('.yaml') ||
      name.endsWith('.yml') ||
      name.endsWith('.json') ||
      name.endsWith('.toml') ||
      name.endsWith('.env')) {
    return _settingsIcon;
  }
  if (name.contains('dockerfile')) return _boxIcon;
  return _fileIcon;
}

const _iconOpen =
    '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" '
    'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">';

const _fileIcon =
    '$_iconOpen<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/>'
    '<path d="M14 2v4a2 2 0 0 0 2 2h4"/></svg>';

const _settingsIcon =
    '$_iconOpen<path d="M20 7h-9"/><path d="M14 17H5"/>'
    '<circle cx="17" cy="17" r="3"/><circle cx="7" cy="7" r="3"/></svg>';

const _boxIcon =
    '$_iconOpen<path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 '
    '0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/></svg>';

List<StyleRule> get _styles => [
  css('.code-file', [
    css('&').styles(margin: Margin.symmetric(vertical: 1.25.rem)),

    css('.code-file-name', [
      css('&').styles(
        display: Display.flex,
        padding: Padding.symmetric(horizontal: .875.rem, vertical: .5.rem),
        radius: BorderRadius.only(
          topLeft: Radius.circular(.5.rem),
          topRight: Radius.circular(.5.rem),
        ),
        opacity: .85,
        alignItems: AlignItems.center,
        gap: Gap.column(.5.rem),
        fontFamily: FontFamily.list([FontFamilies.monospace]),
        fontSize: .75.rem,
        // The code block below is dark in both themes (jaspr_content ships a
        // dark highlighter theme only), so the header has to be dark too or it
        // reads as a detached white strip in light mode.
        color: Color('#c9d1d9'),
        backgroundColor: Color('#161b22'),
      ),
      css('.code-file-icon').styles(display: Display.flex, opacity: .7),
    ]),

    // Square off the top of the code block so it meets the header cleanly, and
    // undo the margin it would otherwise put between the two.
    css('.code-block', [
      css('&').styles(margin: Margin.zero),
      css('pre').styles(
        margin: Margin.zero,
        radius: BorderRadius.only(
          bottomLeft: Radius.circular(.5.rem),
          bottomRight: Radius.circular(.5.rem),
        ),
      ),
    ]),
  ]),
];
