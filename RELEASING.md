# Releasing

Everything pending for the next release, and the mechanics that decide what
actually ships.

## How the release decides what to publish

`scripts/lib/prep_for_publish.dart` is the release. It:

1. Discovers every package **without** `publish_to: none`, ignoring
   `examples/`, `.revali/`, `test/` and `small_test/`.
2. **Exits 1 if any discovered package has no `LATEST_CHANGELOG.md` entry.**
3. Publishes only the packages whose `LATEST_CHANGELOG.md` version **differs
   from** their `pubspec.yaml` version, then writes that version into the
   pubspec and rewrites every dependent's constraint to `^<new version>`.

Two consequences worth holding onto:

- **Equal versions mean skipped.** A package with real changes whose changelog
  version still matches its pubspec is silently not published.
- **A dependent's constraint is only rewritten if that dependent is itself
  in the release.** Publishing a major without re-releasing its dependents
  leaves them pinned to the old range, and the published set stops resolving.

## Current state

| Package | pubspec | changelog | Ships? | Notes |
| --- | --- | --- | --- | --- |
| `revali` | 3.1.0 | 3.2.0 | ✅ | additive |
| `revali_core` | 2.0.1 | 3.0.0 | ✅ | **breaking** |
| `revali_router` | 4.0.2 | 4.1.0 | ⚠️ | version is **wrong** — see below |
| `revali_client` | 2.0.5 | 2.1.0 | ✅ | additive |
| `revali_test` | 1.0.0 | 1.0.0 | ❌ | never published, **has changes** |
| `revali_mcp` | 0.1.0 | 0.1.0 | ❌ | never published |
| `revali_swagger` | 1.1.0 | 1.1.0 | ❌ | **has changes** |
| `og_card` | 0.1.0 | 0.1.0 | ❌ | never published |
| `revali_annotations` | 3.0.0 | 3.0.0 | ❌ | **must re-release** — see below |
| `revali_client_gen` | 2.3.0 | 2.3.0 | ❌ | **must re-release** — see below |
| `revali_construct` | 2.4.0 | 2.4.0 | ❌ | unchanged |
| `revali_docker` | 1.1.0 | 1.1.0 | ❌ | unchanged |
| `revali_swagger_annotations` | 1.0.0 | 1.0.0 | ❌ | unchanged |

## Must be decided before releasing

### 1. `revali_router` needs a major, not `4.1.0`

`revali_router.dart` re-exports `package:revali_core/revali_core.dart` hiding
only `AppConfig`, `Body` and `LifecycleComponents` — so **`Observer` is part
of revali_router's public API**, and `examples/hello` imports it from there.

`Observer.see` changed from `see(Request, Future<Response>)` to
`see(ObservedRequest)`. Shipping that as a minor breaks every dependent on
`dart pub upgrade`.

→ Change the `revali_router` entry to **`5.0.0`** and move the `Observer`
note under a `### Breaking Changes` heading.

### 2. `revali_annotations` and `revali_client_gen` must be re-released

Both depend on `revali_core: ^2.0.0`, and `revali_client_gen` also on
`revali_router: ^4.0.2`. Neither is in the release as things stand, so their
constraints will not be rewritten and the published set will not resolve
against `revali_core` 3.0.0 / `revali_router` 5.0.0.

→ Give both a version bump in `LATEST_CHANGELOG.md`, even if the only change
is the dependency floor. (This is the same failure that produced the
`revali_swagger` 1.1.0 and `revali_client_gen` 2.3.0 entries already in the
changelog — worth reading those, they describe it happening before.)

### 3. `revali_swagger` has changes that will not ship

Its OpenAPI output is now emitted in a deterministic order — paths,
per-path operations and component schemas were previously written in
filesystem-walk order, so the same project produced different specs on macOS
and Linux. That fix is in the changelog under `1.1.0`, which equals the
pubspec, so it would be skipped.

→ Bump to **`1.2.0`**.

### 4. Three packages have never been published

- **`revali_test`** — the documented way to test a Revali app, and a
  dependency of all 27 `test_suite` packages. It also gained fixes this
  round (binary and streamed bodies, repeated-header handling).
- **`revali_mcp`** — the README hands users a Cursor config that cannot
  resolve until this is on pub.dev.
- **`og_card`** — carries full pub metadata and a `LICENSE`, so it looks
  intended for publication. Still missing a `README.md` and `CHANGELOG.md`
  (pub warnings, not errors).

Each is currently at "changelog == pubspec", so each is skipped. To cut a
first release, the changelog entry has to be **above** the pubspec version —
e.g. leave `pubspec: 1.0.0` and set the changelog to `1.0.1`, or lower the
pubspec to `0.0.1` and publish `1.0.0`.

## Before running it

- `./scripts/run_all_tests.sh` must pass. `sip run publish` now calls it;
  it previously used `sip test --recursive`, which exits 0 having run
  nothing.
- `dart pub publish --dry-run` passes for `revali_test` and reports **0
  warnings** for `revali_mcp`.
- `prep_for_publish.dart` runs `pub publish --force`. There is no
  confirmation step, so the changelog is the only thing standing between a
  wrong version and pub.dev.
