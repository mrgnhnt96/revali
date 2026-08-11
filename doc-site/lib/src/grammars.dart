/// TextMate grammars for the code fences on this site.
///
/// `jaspr_content`'s [CodeBlock] delegates to `syntax_highlight_lite`, which
/// bundles **Dart only**. Two consequences:
///
/// 1.  Every other language has to be registered here or it renders unstyled —
///     and 200 of the 700 code blocks on this site are shell, YAML or JSON.
/// 2.  A language that is *not* registered is not a missing style, it is a
///     crash: the highlighter looks the grammar up with a null assertion, so an
///     unknown fence language fails the build. [grammars] therefore also covers
///     the plain-text ones (`text`, `tree`, `console`) with an empty grammar.
///     `test/code_fences_test.dart` fails if `content/` grows a fence language
///     this map does not have.
///
/// These are hand-written and deliberately shallow — comments, strings,
/// numbers, keywords and structure. A full grammar per language would be tens
/// of kilobytes of vendored JSON for code samples that are ten lines long. The
/// scope names are the standard VS Code ones, which is what the bundled themes
/// key off.
library;

/// Every fence language used under `content/`, mapped to its grammar JSON.
///
/// Registered with `Highlighter.addLanguage` in `main.server.dart`.
Map<String, String> get grammars => {
  'bash': _shell,
  // `console` and `sh` are the same thing wearing different fence labels.
  'console': _shell,
  'sh': _shell,
  'powershell': _shell,
  'yaml': _yaml,
  'json': _json,
  'toml': _toml,
  'dockerfile': _dockerfile,
  'http': _http,
  'env': _env,
  // Prose and ASCII art. Registered so the fence label survives without the
  // highlighter trying to find meaning in a directory tree.
  'text': _plain('text'),
  'txt': _plain('txt'),
  'plaintext': _plain('plaintext'),
  'tree': _plain('tree'),
};

/// An empty grammar: valid, matches nothing, styles nothing.
String _plain(String name) => '{"name":"$name","scopeName":"source.$name","patterns":[]}';

const _shell = r'''
{
  "name": "shell",
  "scopeName": "source.shell",
  "patterns": [
    { "match": "#.*$", "name": "comment.line.number-sign" },
    { "begin": "'", "end": "'", "name": "string.quoted.single" },
    { "begin": "\"", "end": "\"", "name": "string.quoted.double", "patterns": [
      { "match": "\\$\\{[^}]*\\}|\\$[A-Za-z_][A-Za-z0-9_]*", "name": "variable.other" }
    ]},
    { "match": "\\$\\{[^}]*\\}|\\$[A-Za-z_][A-Za-z0-9_]*", "name": "variable.other" },
    { "match": "\\b(if|then|else|elif|fi|for|while|do|done|case|esac|in|function|return|exit|export|source|local|set)\\b", "name": "keyword.control" },
    { "match": "\\b(dart|flutter|revali|git|docker|cd|ls|mkdir|rm|cp|mv|echo|cat|curl|sudo|apt|brew|npm|pnpm|yarn)\\b", "name": "entity.name.function" },
    { "match": "(^|\\s)(--?[A-Za-z][\\w-]*)", "name": "variable.parameter" },
    { "match": "[|&;><]", "name": "keyword.operator" }
  ]
}
''';

const _yaml = r'''
{
  "name": "yaml",
  "scopeName": "source.yaml",
  "patterns": [
    { "match": "#.*$", "name": "comment.line.number-sign" },
    { "match": "^\\s*-?\\s*([A-Za-z_][\\w.-]*)\\s*:", "captures": { "1": { "name": "entity.name.tag" } } },
    { "begin": "'", "end": "'", "name": "string.quoted.single" },
    { "begin": "\"", "end": "\"", "name": "string.quoted.double" },
    { "match": "\\b(true|false|null|yes|no|on|off)\\b", "name": "constant.language" },
    { "match": "\\b\\d+(\\.\\d+)*\\b", "name": "constant.numeric" },
    { "match": "^\\s*-\\s", "name": "keyword.operator" },
    { "match": "[&*]\\w+|<<:", "name": "keyword.control" }
  ]
}
''';

const _json = r'''
{
  "name": "json",
  "scopeName": "source.json",
  "patterns": [
    { "match": "//.*$", "name": "comment.line.double-slash" },
    { "match": "(\"(?:[^\"\\\\]|\\\\.)*\")\\s*:", "captures": { "1": { "name": "support.type.property-name" } } },
    { "match": "\"(?:[^\"\\\\]|\\\\.)*\"", "name": "string.quoted.double" },
    { "match": "\\b(true|false|null)\\b", "name": "constant.language" },
    { "match": "-?\\b\\d+(\\.\\d+)?([eE][-+]?\\d+)?\\b", "name": "constant.numeric" }
  ]
}
''';

const _toml = r'''
{
  "name": "toml",
  "scopeName": "source.toml",
  "patterns": [
    { "match": "#.*$", "name": "comment.line.number-sign" },
    { "match": "^\\s*(\\[\\[?[^\\]]+\\]\\]?)", "captures": { "1": { "name": "entity.name.tag" } } },
    { "match": "^\\s*([A-Za-z_][\\w.-]*)\\s*=", "captures": { "1": { "name": "support.type.property-name" } } },
    { "begin": "\"", "end": "\"", "name": "string.quoted.double" },
    { "begin": "'", "end": "'", "name": "string.quoted.single" },
    { "match": "\\b(true|false)\\b", "name": "constant.language" },
    { "match": "\\b\\d+(\\.\\d+)?\\b", "name": "constant.numeric" }
  ]
}
''';

const _dockerfile = r'''
{
  "name": "dockerfile",
  "scopeName": "source.dockerfile",
  "patterns": [
    { "match": "#.*$", "name": "comment.line.number-sign" },
    { "match": "^\\s*(FROM|RUN|CMD|LABEL|MAINTAINER|EXPOSE|ENV|ADD|COPY|ENTRYPOINT|VOLUME|USER|WORKDIR|ARG|ONBUILD|STOPSIGNAL|HEALTHCHECK|SHELL)\\b", "captures": { "1": { "name": "keyword.control" } } },
    { "match": "\\b(AS|as)\\b", "name": "keyword.operator" },
    { "begin": "\"", "end": "\"", "name": "string.quoted.double" },
    { "match": "\\$\\{?[A-Za-z_][A-Za-z0-9_]*\\}?", "name": "variable.other" }
  ]
}
''';

const _http = r'''
{
  "name": "http",
  "scopeName": "source.http",
  "patterns": [
    { "match": "^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS|TRACE)\\b", "name": "keyword.control" },
    { "match": "^(HTTP/[\\d.]+)\\s+(\\d{3})", "captures": { "1": { "name": "keyword.control" }, "2": { "name": "constant.numeric" } } },
    { "match": "^([A-Za-z][\\w-]*)\\s*:", "captures": { "1": { "name": "support.type.property-name" } } },
    { "match": "\\bhttps?://\\S+", "name": "string.other.link" },
    { "match": "\"(?:[^\"\\\\]|\\\\.)*\"", "name": "string.quoted.double" }
  ]
}
''';

const _env = r'''
{
  "name": "env",
  "scopeName": "source.env",
  "patterns": [
    { "match": "#.*$", "name": "comment.line.number-sign" },
    { "match": "^\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*=", "captures": { "1": { "name": "entity.name.tag" } } },
    { "begin": "\"", "end": "\"", "name": "string.quoted.double" },
    { "begin": "'", "end": "'", "name": "string.quoted.single" }
  ]
}
''';
