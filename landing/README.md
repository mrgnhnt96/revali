# Revali landing page

The marketing site at **revali.dev**. Built with [Jaspr](https://jaspr.site) in
static mode — the same toolchain as `doc-site/`, so the whole web presence is
Dart and there is no Node toolchain in this repo.

This is deliberately *not* part of `doc-site/`. They are separate sites on
separate domains with separate deploys:

| | `landing/` | `doc-site/` |
| --- | --- | --- |
| Domain | `revali.dev` | `docs.revali.dev` |
| Pages site | this repo | `mrgnhnt96/revali-docs` |
| Workflow | `.github/workflows/deploy-landing.yml` | `.github/workflows/deploy-docs.yml` |

## Running it

```bash
dart pub get
dart run jaspr_cli:jaspr serve      # http://localhost:8080, hot reload
dart run jaspr_cli:jaspr build      # -> build/jaspr
```

> [!NOTE]
> `jaspr build` binds port **5567** for its static-render proxy, and that port
> is hard-coded — only `jaspr serve` takes `--proxy-port`. If a `jaspr serve`
> from any other project is running, the build fails with
> `Address already in use`. Stop it, or check with `lsof -i :5567`.

## How it is put together

```
lib/
  main.server.dart      the whole page: <head>, meta, section order
  sections/             one file per section, top to bottom
  src/
    snippets.dart       every code sample, each tagged with its doc source
    highlight.dart      build-time syntax highlighter
    icons.dart          the icon set, as inline SVG
    ui.dart             shared primitives (window chrome, reveal, copy button)
web/
  styles.css            the design system — read the header comment first
  motion.js             ~4KB, five behaviours, no dependencies
```

### Three rules worth knowing before editing

**1. Amber is yours, indigo is generated.** The page has one idea — you write
annotations, Revali writes everything else — and the palette carries it. Amber
(`--amber`, from the logo's wing) marks hand-written code; indigo
(`--indigo`, from the letterform) marks generated output. Do not use them
decoratively; if you tint something amber you are claiming a human wrote it.

**2. Nothing is hidden unless JavaScript can un-hide it.** `motion.js` adds
`.js` to `<html>` as its first act, and every reveal rule is scoped under
`.js`. So if the script fails to load, is blocked, or throws, the page is
simply fully visible. Never write a bare `opacity: 0` that waits for a script.

**3. The code samples are real.** Every snippet in `src/snippets.dart` carries
a comment naming the file under `doc-site/content/` it came from. A fabricated
API on a framework's landing page is the fastest way to lose a developer, since
they will paste it within the minute. If the framework changes, that file is
what goes stale — the doc path in each comment makes the check a diff.

## Verifying

`dart analyze` only proves it compiles. The DOM lies about whether a page
*works*, so there is a headless-Chrome harness that asserts and screenshots:

```bash
# In one terminal — render the single route and serve it:
PORT=8099 dart run lib/main.server.dart
mkdir -p /tmp/rvprev && cp -r web/* /tmp/rvprev/
curl -s http://localhost:8099/ > /tmp/rvprev/index.html
(cd /tmp/rvprev && python3 -m http.server 8777)

# In another:
python3 tool/verify_in_browser.py http://localhost:8777
```

Screenshots land in `build/verify/`. **Look at them** — every assertion in that
file can pass while the thing it asserts on is invisible.

What it covers, and why each one is there rather than being a DOM check:

- **all reveals fired** — the worst failure this page can have is an
  IntersectionObserver that never fires, leaving the page permanently blank.
  That is invisible to any HTML-level check.
- **no sideways scroll** — tested as `scrollWidth > clientWidth` on the root,
  *not* "is any element wider than the viewport". This page is full of elements
  that deliberately overflow their container (ambient glows, the tab strip,
  every code block) and scroll or clip internally.
- **reduced motion / no JS** — both must show the complete page.
