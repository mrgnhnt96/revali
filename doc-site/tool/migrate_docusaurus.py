#!/usr/bin/env python3
"""One-shot migration of the Docusaurus `docs/` tree into jaspr_content `content/`.

Kept in the repo after the fact as the record of what was mechanically changed,
because the diff itself is 115 files wide and unreviewable. Everything this does
is checked afterwards by `test/navigation_test.dart` (every route reachable) and
`test/links_test.dart` (every internal link resolves).

Transformations, in order:

1.  `<dir>/overview.md` -> `<dir>/index.md`, so `/constructs/revali_server` is a
    page rather than a 404. Docusaurus synthesised those directory routes with
    `_category_.yml`'s `generated-index`; jaspr_content derives routes from paths,
    so the overview has to actually live at the directory route.
2.  Front matter is reduced to `title`/`description`. `sidebar_position` and
    `slug` move into `lib/src/navigation.dart`, which is the only place ordering
    lives now.
3.  The leading `# Heading` is removed — `DocsLayout` renders the `<h1>` from the
    front matter title, so leaving it produces two.
4.  Docusaurus admonitions (`:::tip`) become `<Callout type="tip">` blocks. The
    blank lines inside the tags are mandatory: `package:markdown` treats an HTML
    block as literal text until a blank line, so `**bold**` immediately after an
    opening tag renders as visible asterisks.
5.  Fence titles (```dart title="x.dart") become a `<CodeFile name="x.dart">`
    wrapper — `package:markdown` keeps only the first word of an info string, so
    the title is otherwise silently dropped.
6.  Every internal link is rewritten to the new routes, including reference-style
    definitions (`[key]: ../path.md#anchor`), which are half of them.

Usage:  python3 tool/migrate_docusaurus.py <docs-dir> <content-dir>
"""

from __future__ import annotations

import os
import re
import sys
from dataclasses import dataclass, field

# Docusaurus admonition -> the `type` attribute on our Callout component.
# All seven are kept rather than collapsed onto jaspr_content's four
# (Info/Warning/Error/Success): "tip" and "important" carry different weight
# from "note", and 145 of the 187 callouts on this site are one of those two.
ADMONITIONS = {
    'note', 'tip', 'info', 'important', 'warning', 'caution', 'danger',
}

FENCE = re.compile(r'^(\s*)(`{3,})(.*)$')
ADMONITION_OPEN = re.compile(r'^\s*(:{3,})(' + '|'.join(ADMONITIONS) + r')\s*(.*)$')
# Leading whitespace is allowed: five of these pages close with an indented
# `  :::` (it trails a bullet list), which Docusaurus accepted.
ADMONITION_CLOSE = re.compile(r'^\s*(:{3,})\s*$')
H1 = re.compile(r'^#\s+(.+?)\s*$')

# `](target)` — inline links and images.
INLINE_LINK = re.compile(r'(!?\[[^\]]*\])\(([^)\s]+)(\s+"[^"]*")?\)')
# `[key]: target` — reference definitions, at the start of a line.
REF_LINK = re.compile(r'^(\[[^\]]+\]:\s*)(\S+)\s*$')


@dataclass
class Doc:
    """One source page and where it ends up."""

    source: str  # posix path relative to docs/, e.g. revali/cli/build.md
    out: str  # posix path relative to content/, e.g. revali/cli/build.md
    route: str  # site route, e.g. /revali/cli/build
    title: str = ''
    description: str = ''
    position: int | None = None
    body: str = ''
    warnings: list[str] = field(default_factory=list)


def route_for(source: str) -> str:
    """`constructs/revali_server/overview.md` -> `/constructs/revali_server`."""
    stem = source[: -len('.md')]
    segments = stem.split('/')
    if segments[-1] == 'overview':
        segments.pop()
    return '/' + '/'.join(segments)


def out_for(source: str) -> str:
    stem = source[: -len('.md')]
    segments = stem.split('/')
    if segments[-1] == 'overview':
        segments[-1] = 'index'
    return '/'.join(segments) + '.md'


def split_front_matter(raw: str) -> tuple[dict[str, str], str]:
    if not raw.startswith('---\n'):
        return {}, raw
    end = raw.find('\n---', 3)
    if end < 0:
        return {}, raw
    block = raw[4:end]
    body = raw[raw.index('\n', end + 1) + 1:]

    data: dict[str, str] = {}
    for line in block.split('\n'):
        match = re.match(r'^([A-Za-z_][\w-]*):\s*(.*)$', line)
        if not match:
            continue
        value = match.group(2).strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in '"\'':
            value = value[1:-1]
        data[match.group(1)] = value
    return data, body


def convert_admonitions(body: str, doc: Doc) -> str:
    """`:::tip` -> `<Callout type="tip">`, tracking fences and nesting depth.

    Docusaurus uses extra colons purely to nest (`::::tip` wraps a `:::note`), so
    the colon count is matched on close rather than assumed to be three.
    """
    lines = body.split('\n')
    out: list[str] = []
    open_markers: list[str] = []
    fence: str | None = None

    for line in lines:
        fence_match = FENCE.match(line)
        if fence_match:
            ticks = fence_match.group(2)
            if fence is None:
                fence = ticks
            elif line.strip().startswith(fence) and not fence_match.group(3).strip():
                fence = None
            out.append(line)
            continue
        if fence is not None:
            out.append(line)
            continue

        open_match = ADMONITION_OPEN.match(line)
        if open_match:
            marker, kind, title = open_match.groups()
            open_markers.append(marker)
            attributes = f'type="{kind}"'
            if title.strip():
                attributes += f' title="{title.strip()}"'
            # A blank line after the opening tag and before the closing one is
            # what makes the contents parse as markdown instead of literal text.
            out.append(f'<Callout {attributes}>')
            out.append('')
            continue

        close_match = ADMONITION_CLOSE.match(line)
        if close_match and not open_markers:
            # A close with nothing open. Docusaurus rendered these literally, so
            # the page had a stray `:::` visible in the prose — drop it.
            doc.warnings.append(f'dropped stray {close_match.group(1)!r} with nothing open')
            continue
        if close_match:
            if close_match.group(1) != open_markers[-1]:
                doc.warnings.append(
                    f'admonition closed with {close_match.group(1)!r} but opened with '
                    f'{open_markers[-1]!r}'
                )
            open_markers.pop()
            out.append('')
            out.append('</Callout>')
            continue

        out.append(line)

    if open_markers:
        doc.warnings.append(f'{len(open_markers)} unclosed admonition(s), closed at end of file')
        for _ in open_markers:
            out.extend(('', '</Callout>'))

    return '\n'.join(out)


def convert_fence_titles(body: str, doc: Doc) -> str:
    """```dart title="x" -> a `<CodeFile name="x">`-wrapped plain fence."""
    lines = body.split('\n')
    out: list[str] = []
    closing_for: dict[int, str] = {}
    fence: str | None = None
    pending_close = False

    for line in lines:
        fence_match = FENCE.match(line)
        if fence_match and fence is None:
            indent, ticks, info = fence_match.groups()
            language, _, meta = info.strip().partition(' ')
            title_match = re.search(r'title="([^"]*)"', meta)
            fence = ticks
            if title_match:
                out.append(f'<CodeFile name="{title_match.group(1)}">')
                out.append('')
                pending_close = True
            out.append(f'{indent}{ticks}{language}')
            continue

        if fence is not None and fence_match and line.strip().startswith(fence):
            fence = None
            out.append(line)
            if pending_close:
                out.append('')
                out.append('</CodeFile>')
                pending_close = False
            continue

        out.append(line)

    if fence is not None:
        doc.warnings.append('unclosed code fence')
    del closing_for
    return '\n'.join(out)


def rewrite_links(body: str, doc: Doc, routes: dict[str, str], docs_dir: str) -> str:
    """Point every internal link at its new route."""

    def resolve(target: str) -> str:
        if re.match(r'^(https?:|mailto:|#)', target):
            return target

        path, _, anchor = target.partition('#')
        anchor = f'#{anchor}' if anchor else ''
        if not path:
            return target

        if path.endswith('.md'):
            base = os.path.dirname(doc.source) if not path.startswith('/') else ''
            relative = os.path.normpath(os.path.join(base, path)).replace(os.sep, '/')
            route = routes.get(relative)
            if route is None:
                doc.warnings.append(f'link to missing page: {target}')
                return target
            return route + anchor

        if path.startswith('/'):
            # Already a route. Only `.../overview` moved.
            if path.endswith('/overview'):
                path = path[: -len('/overview')]
            if path not in routes.values():
                doc.warnings.append(f'link to unknown route: {target}')
            return path + anchor

        return target

    def inline(match: re.Match[str]) -> str:
        label, target, title = match.groups()
        return f'{label}({resolve(target)}{title or ""})'

    lines = body.split('\n')
    fence: str | None = None
    for index, line in enumerate(lines):
        fence_match = FENCE.match(line)
        if fence_match:
            ticks = fence_match.group(2)
            fence = None if fence and line.strip().startswith(fence) else (fence or ticks)
            continue
        if fence is not None:
            continue

        ref_match = REF_LINK.match(line)
        if ref_match:
            lines[index] = f'{ref_match.group(1)}{resolve(ref_match.group(2).rstrip("#"))}'
            continue
        lines[index] = INLINE_LINK.sub(inline, line)

    return '\n'.join(lines)


def main() -> int:
    docs_dir, content_dir = sys.argv[1], sys.argv[2]

    sources: list[str] = []
    for root, _, files in os.walk(docs_dir):
        for name in sorted(files):
            if name.endswith('.md'):
                path = os.path.relpath(os.path.join(root, name), docs_dir)
                sources.append(path.replace(os.sep, '/'))
    sources.sort()

    docs = [Doc(source=source, out=out_for(source), route=route_for(source)) for source in sources]
    routes = {doc.source: doc.route for doc in docs}

    for doc in docs:
        with open(os.path.join(docs_dir, doc.source), encoding='utf-8') as handle:
            raw = handle.read().replace('\r\n', '\n')

        front_matter, body = split_front_matter(raw)
        doc.description = front_matter.get('description', '')
        if front_matter.get('sidebar_position'):
            doc.position = int(front_matter['sidebar_position'])

        body = body.lstrip('\n')
        h1 = H1.match(body.split('\n', 1)[0]) if body else None
        if h1:
            doc.title = h1.group(1)
            body = body.split('\n', 1)[1] if '\n' in body else ''
        doc.title = front_matter.get('title') or doc.title
        if not doc.title:
            doc.warnings.append('no title (front matter or h1)')

        body = convert_admonitions(body, doc)
        body = convert_fence_titles(body, doc)
        body = rewrite_links(body, doc, routes, docs_dir)
        doc.body = re.sub(r'\n{3,}', '\n\n', body).strip() + '\n'

    for doc in docs:
        destination = os.path.join(content_dir, doc.out)
        os.makedirs(os.path.dirname(destination), exist_ok=True)
        front_matter = [f'title: {yaml_scalar(doc.title)}']
        if doc.description:
            front_matter.append(f'description: {yaml_scalar(doc.description)}')
        with open(destination, 'w', encoding='utf-8') as handle:
            handle.write('---\n' + '\n'.join(front_matter) + '\n---\n\n' + doc.body)

    print(f'Wrote {len(docs)} pages to {content_dir}/')
    for doc in docs:
        for warning in doc.warnings:
            print(f'  ! {doc.source}: {warning}')

    # A machine-readable dump of the ordering Docusaurus encoded in
    # `sidebar_position`, so navigation.dart can be built from it rather than
    # from a reading of 115 files.
    with open(os.path.join(content_dir, '..', 'tool', 'migration_report.tsv'), 'w') as handle:
        handle.write('route\tposition\ttitle\tdescription\n')
        for doc in docs:
            position = '' if doc.position is None else str(doc.position)
            handle.write(f'{doc.route}\t{position}\t{doc.title}\t{doc.description}\n')

    return 0


def yaml_scalar(value: str) -> str:
    if re.search(r'^[\s>|&*!%@`\-?{}\[\],#]|:\s|\s#|["\']|:$', value):
        return '"' + value.replace('\\', '\\\\').replace('"', '\\"') + '"'
    return value


if __name__ == '__main__':
    raise SystemExit(main())
