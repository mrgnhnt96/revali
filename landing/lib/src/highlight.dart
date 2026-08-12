/// A very small, dependency-free syntax highlighter.
///
/// The page shows a dozen code samples in four languages, and a real
/// highlighter (or a client-side one like Prism) would mean either a build-time
/// dependency or shipping JavaScript to colour text that never changes. Both
/// are a poor trade for a static page, so the tokens are found here at build
/// time and emitted as `<span class="tok-*">`.
///
/// This is deliberately *not* a parser. It is a single ordered alternation of
/// regexes, and it is only ever pointed at the hand-written snippets in
/// `snippets.dart` — so the failure mode of a mis-tokenised construct is a
/// word in the wrong colour, on a sample that a human already eyeballed.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// One lexical rule: the token name — which is also its CSS class suffix — and
/// the pattern that finds it.
typedef _Rule = (String name, String pattern);

/// An ordered set of [_Rule]s compiled into one alternation.
///
/// Order is significant, and is the whole mechanism: alternation is tried
/// left-to-right at each position, so `comment` has to precede `str` (a `//`
/// inside a URL would otherwise open a string) and `fn` has to precede `ident`
/// (or every call would just be an identifier).
class Grammar {
  Grammar(this._rules)
    : _pattern = RegExp(
        _rules.map((rule) => '(?<${rule.$1}>${rule.$2})').join('|'),
        multiLine: true,
      );

  final List<_Rule> _rules;
  final RegExp _pattern;

  /// [source] as a list of spans, with the text between matches left bare so
  /// it inherits the block's base colour.
  List<Component> call(String source) {
    final out = <Component>[];
    var cursor = 0;

    for (final match in _pattern.allMatches(source)) {
      // A zero-width match would emit an empty span and never advance; no rule
      // below can produce one, but a future rule with an all-optional tail
      // could, and the symptom would be baffling.
      if (match.end == match.start) continue;

      if (match.start > cursor) {
        out.add(Component.text(source.substring(cursor, match.start)));
      }

      // `namedGroup` returns null for a group that did not participate, so the
      // first non-null name is the rule that matched.
      final name = _rules
          .map((rule) => rule.$1)
          .firstWhere((name) => match.namedGroup(name) != null);

      out.add(span(classes: 'tok-$name', [Component.text(match[0]!)]));
      cursor = match.end;
    }

    if (cursor < source.length) {
      out.add(Component.text(source.substring(cursor)));
    }
    return out;
  }
}

const _dartKeywords =
    'abstract|as|async|await|base|break|case|catch|class|const|continue|covariant|'
    'default|deferred|do|else|enum|export|extends|extension|external|factory|final|'
    'finally|for|get|hide|if|implements|import|in|interface|is|late|library|mixin|'
    'new|on|operator|part|required|rethrow|return|sealed|set|show|static|super|'
    'switch|sync|this|throw|try|typedef|var|void|while|with|yield';

/// Dart, plus the annotations that are the whole point of the samples — `ann`
/// sits above `type` so `@Controller` stays one amber token instead of an `@`
/// followed by a class name in a different colour.
final dart = Grammar([
  ('comment', r'//[^\n]*'),
  ('str', "'(?:[^'\\\\\\n]|\\\\.)*'"),
  ('ann', r'@[A-Za-z_]\w*'),
  ('kw', '\\b(?:$_dartKeywords)\\b'),
  ('lit', r'\b(?:true|false|null)\b'),
  ('type', r'\b[A-Z]\w*'),
  ('fn', r'\b[a-z_]\w*(?=\s*\()'),
  ('num', r'\b\d+(?:\.\d+)?\b'),
  ('ident', r'\b[a-z_]\w*\b'),
]);

/// YAML. `key` anchors to the start of a line so a `:` inside a value — a URL,
/// most often — does not turn the value into a key.
final yaml = Grammar([
  ('comment', r'#[^\n]*'),
  ('key', r'^[ \t]*(?:- )?[A-Za-z_][\w.\-]*(?=\s*:)'),
  ('str', '\'(?:[^\'\\\\\\n]|\\\\.)*\'|"(?:[^"\\\\\\n]|\\\\.)*"'),
  ('lit', r'\b(?:true|false|null)\b'),
  ('num', r'\b\d+(?:\.\d+)?\b'),
  ('dash', r'^[ \t]*-(?=\s)'),
]);

final dockerfile = Grammar([
  ('comment', r'#[^\n]*'),
  (
    'instr',
    r'^\s*(?:FROM|RUN|COPY|ADD|WORKDIR|ENV|ARG|CMD|ENTRYPOINT|EXPOSE|USER|LABEL|VOLUME|HEALTHCHECK|SHELL)\b',
  ),
  ('kw', r'\bAS\b'),
  ('str', '"(?:[^"\\\\\\n]|\\\\.)*"'),
  ('flag', r'(?<=\s)--[\w-]+'),
]);

/// Shell. `cmd` only matches at the start of a line, so `dart` in
/// `dart run revali dev` is highlighted but `revali` after it is not — which
/// is the distinction a reader is actually scanning for.
final shell = Grammar([
  ('comment', r'#[^\n]*'),
  ('cmd', r'^[ \t]*[a-z][\w.-]*'),
  ('flag', r'(?<=\s)--?[\w-]+'),
  ('str', '\'(?:[^\'\\\\\\n])*\'|"(?:[^"\\\\\\n])*"'),
  ('num', r'\b\d+\b'),
]);
