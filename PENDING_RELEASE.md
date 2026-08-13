# Pending release

The actions outstanding for the **next** release. Read
[RELEASING.md](./RELEASING.md) first — it explains the mechanism these
actions work around, and none of the edits below make sense without it.

Nothing here has been done. No package has been published.

> Every version below is edited in **`LATEST_CHANGELOG.md`**, never in a
> `pubspec.yaml`. The release script writes the pubspec itself; editing it by
> hand makes the package look unchanged and it silently will not publish.

## State as of writing

| Package | pubspec | changelog | Would ship? |
| --- | --- | --- | --- |
| `revali` | 3.1.0 | 3.2.0 | ✅ |
| `revali_core` | 2.0.1 | 3.0.0 | ✅ breaking |
| `revali_router` | 4.0.2 | 4.1.0 | ⚠️ ships at the **wrong** version |
| `revali_client` | 2.0.5 | 2.1.0 | ✅ |
| `revali_test` | 1.0.0 | 1.0.0 | ❌ |
| `revali_mcp` | 0.1.0 | 0.1.0 | ❌ |
| `revali_swagger` | 1.1.0 | 1.1.0 | ❌ |
| `revali_annotations` | 3.0.0 | 3.0.0 | ❌ |
| `revali_client_gen` | 2.3.0 | 2.3.0 | ❌ |
| `revali_construct` | 2.4.0 | 2.4.0 | ❌ genuinely unchanged |
| `revali_docker` | 1.1.0 | 1.1.0 | ❌ genuinely unchanged |
| `revali_swagger_annotations` | 1.0.0 | 1.0.0 | ❌ genuinely unchanged |

Re-derive it rather than trusting the table if time has passed:

```bash
for f in $(find packages constructs revali_router -name pubspec.yaml \
    -not -path '*/.dart_tool/*' -not -path '*/.revali/*' -not -path '*/test/*' | sort); do
  grep -q publish_to "$f" && continue
  n=$(grep -m1 '^name:' "$f" | cut -d' ' -f2)
  pv=$(grep -m1 '^version:' "$f" | cut -d' ' -f2)
  cv=$(awk -v p="# $n" '$0==p{f=1;next} f&&/^## /{print $2;exit}' LATEST_CHANGELOG.md)
  printf '%-28s pubspec=%-8s changelog=%s\n' "$n" "$pv" "${cv:-MISSING}"
done
```

## 1. Fix `revali_router`'s version — it is wrong, not just stale

Currently `4.1.0`. It must be **`5.0.0`**.

`revali_router.dart` re-exports `package:revali_core/revali_core.dart` hiding
only `AppConfig`, `Body` and `LifecycleComponents`, so **`Observer` is part of
revali_router's own public API** — `examples/hello/lib/observers/my_observer.dart`
imports it from there, not from `revali_core`.

`Observer.see` changed from `see(Request, Future<Response>)` to
`see(ObservedRequest)`. Shipping that as a minor breaks every dependent on
`dart pub upgrade`.

- [ ] Change the `revali_router` heading to `## 5.0.0`
- [ ] Move the `Observer` / `ObservedRequest` note under a
      `### Breaking Changes` heading (it currently sits under `### Features`)

## 2. Re-release `revali_annotations` and `revali_client_gen`

Neither changed, and both must ship anyway.

```
revali_annotations   → revali_core: ^2.0.0
revali_client_gen    → revali_core: ^2.0.0, revali_router: ^4.0.2
```

A dependent's constraint is only rewritten if that dependent is itself in the
release. Publishing `revali_core` 3.0.0 and `revali_router` 5.0.0 while these
two stay behind leaves them pinned to ranges that exclude the new majors, and
**the published set stops resolving**.

- [ ] `revali_annotations` → `## 4.0.0` (its floor moves to a new major)
- [ ] `revali_client_gen` → `## 3.0.0` (same, for both deps)
- [ ] Give each a `### Fixes` entry saying the dependency floor moved

This has already happened twice in this repo. The `revali_swagger` 1.1.0 and
`revali_client_gen` 2.3.0 entries currently in `LATEST_CHANGELOG.md` are both
retroactive fixes for exactly this — worth reading before deciding it is
theoretical.

## 3. Bump `revali_swagger` — it has an unshipped fix

Its OpenAPI output is now emitted deterministically. Paths, per-path
operations and component schemas were previously written in filesystem-walk
order, so the same project produced `/complex` first on macOS and `/users`
first on Linux; CI caught it against a macOS-generated golden. The entry is
already written, but sits under `1.1.0`, which equals the pubspec.

- [ ] `revali_swagger` → `## 1.2.0`

## 4. First publish for `revali_test` and `revali_mcp`

Both are prepared — pub metadata, `README.md`, `CHANGELOG.md`, `LICENSE` —
and both validate: `dart pub publish --dry-run` passes for `revali_test` and
reports **0 warnings** for `revali_mcp`.

Neither will publish as-is, because the release only acts when the changelog
version *differs* from the pubspec version, and a first release naturally has
them equal. Pick one:

- Set the changelog **above** the pubspec (`pubspec: 1.0.0` → changelog
  `1.0.1`), or
- Lower the pubspec to a placeholder (`0.0.1`) and publish `1.0.0` — better
  if `1.0.0` is wanted as the first published version.

- [ ] `revali_test` — decide and apply. It also gained real fixes this round
      (binary and streamed request bodies, repeated-header handling), so this
      is not only a packaging release
- [ ] `revali_mcp` — decide and apply

## Before running the release

- [ ] `./scripts/run_all_tests.sh` passes (41 packages at last run). Do **not**
      substitute `sip test` — it exits 0 over a failing suite
- [ ] Re-derive the version table above and confirm every package you expect
      to ship has changelog ≠ pubspec, and every one you do not, equal
- [ ] Remember `prep_for_publish.dart` runs `pub publish --force` with **no
      confirmation prompt**. The changelog is the only thing between a wrong
      version and pub.dev

## Deliberately excluded

`og_card` is `publish_to: none` and is not part of this release. See
[RELEASING.md](./RELEASING.md#deliberately-not-published).
