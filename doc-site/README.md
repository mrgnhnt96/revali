# Revali docs

The documentation site at <https://docs.revali.dev>, built with
[jaspr_content](https://pub.dev/packages/jaspr_content) in static mode.

## Layout

```
content/            markdown pages — the URL of a page is its path here
  _data/site.yaml   title, description, canonical url, social image
lib/
  main.server.dart  ContentApp, the layout, and the component registry
  main.client.dart  hydration entrypoint (only @client components)
  src/
    navigation.dart THE information architecture — read this first
    search_index.dart  ranking (no DOM, so it is unit-testable)
    grammars.dart   TextMate grammars for non-Dart code fences
  components/
    docs_sidebar.dart  collapsible <details> sidebar, one section at a time
    section_tabs.dart  the Revali / Constructs / Create Constructs switcher
    search.dart        the @client ⌘K dialog
    callout.dart       <Callout type="tip">, seven kinds
    cards.dart         <Hero>, <CardGrid>, <Card>, <SectionCards />
    code_file.dart     <CodeFile name="…"> filename headers
    mermaid.dart       ```mermaid fences
tool/
  build_search_index.dart  content/ -> web/search-index.json + llms.txt
  verify_in_browser.py     headless-Chrome checks and screenshots
  migrate_docusaurus.py    the one-shot Docusaurus migration, kept as a record
web/
  search-index.json   generated, and committed
  CNAME               docs.revali.dev
```

## Commands

```sh
dart run tool/build_search_index.dart          # regenerate the index + llms.txt
dart run tool/build_search_index.dart --check  # fail if stale (CI, tests)
dart run jaspr_cli:jaspr serve                 # http://localhost:8080
dart run jaspr_cli:jaspr build                 # -> build/jaspr/
dart analyze --fatal-infos
dart test                                      # run AFTER a build for the anchor test
python3 tool/verify_in_browser.py              # -> build/verify/*.png
```

`jaspr serve` hot-reloads `content/`. It does **not** pick up a stale search
index (regenerate it by hand) or edits to `navigation.dart` (restart).

## Adding a page

1. Add `content/<section>/<page>.md` with `title` and `description` front
   matter. Name it `index.md` to own the directory's own route.
2. Add a `NavItem` for it in `lib/src/navigation.dart`.
3. `dart run tool/build_search_index.dart && dart test`.

Skipping step 2 is a build failure, not a silently unreachable page — that is
what `navigation.dart` is for.

## Things that fail silently

Each of these cost a debugging session once, and none of them produce an error:

- **Blank lines inside component tags are mandatory.** `package:markdown`
  treats an HTML block as literal text until a blank line, so `**bold**` on the
  line straight after `<Callout type="tip">` renders its asterisks. There is a
  test for this in `test/navigation_test.dart`.
- **A component's opening tag must be on one line**, and its attribute names
  must be lowercase or hyphenated — the HTML parser downcases them, so
  `primaryLabel` arrives as `primarylabel`.
- **A code fence language with no grammar fails the build**, because the
  highlighter looks it up with a null assertion. Add it to
  `lib/src/grammars.dart`; there is a test that checks `content/` against it.
- **A dot in a filename** makes Jaspr emit `page.name` instead of
  `page.name/index.html`, and Pages then serves it as a download. `fly.io.md`
  is `fly-io.md` for this reason.
- **Search anchors are a reimplementation** of `package:markdown`'s slug
  algorithm. `test/search_index_test.dart` checks every one of them against the
  built HTML rather than against itself, so run `dart test` after a build.

## Deployment

`.github/workflows/deploy-docs.yml` in the repository root builds this app on
every push to `main` that touches `doc-site/`, and force-pushes the output to
`mrgnhnt96/revali-docs`, whose GitHub Pages site serves `docs.revali.dev`. That
workflow's header comment records the one-time setup — the artifact repo, the
deploy key, and the DNS record — so it can be rebuilt from scratch.
