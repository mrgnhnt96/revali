# Pending release

The actions outstanding for the **next** release. Read
[RELEASING.md](./RELEASING.md) first — it explains the mechanism these
actions work around, and none of the edits below make sense without it.

**All version edits are applied.** No package has been published yet.

> Every version below is edited in **`LATEST_CHANGELOG.md`**, never in a
> `pubspec.yaml` — with the one documented exception in §4, where a first
> release needs the pubspec lowered to a placeholder so the two differ. The
> release script writes the pubspec itself; editing it by hand otherwise makes
> the package look unchanged and it silently will not publish.

## State as of writing

| Package | pubspec | changelog | Ships? |
| --- | --- | --- | --- |
| `revali` | 3.1.0 | 3.2.0 | ✅ |
| `revali_core` | 2.0.1 | 3.0.0 | ✅ breaking |
| `revali_router` | 4.0.2 | 5.0.0 | ✅ breaking |
| `revali_client` | 2.0.5 | 2.1.0 | ✅ |
| `revali_swagger` | 1.1.0 | 1.2.0 | ✅ |
| `revali_annotations` | 3.0.0 | 3.1.0 | ✅ floor moved |
| `revali_client_gen` | 2.3.0 | 2.4.0 | ✅ floor moved |
| `revali_test` | 0.0.1 | 0.1.0 | ✅ first publish |
| `revali_mcp` | 0.0.1 | 0.1.0 | ✅ first publish |
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
  [ "$pv" = "$cv" ] && s=skip || s=PUBLISH
  printf '%-28s pubspec=%-8s changelog=%-8s %s\n' "$n" "$pv" "${cv:-MISSING}" "$s"
done
```

## 1. `revali_router` ships as a major — done

Was `4.1.0` in the changelog, which was wrong rather than merely stale. Now
`5.0.0`.

`revali_router.dart` re-exports `package:revali_core/revali_core.dart` hiding
only `AppConfig`, `Body` and `LifecycleComponents`, so **`Observer` is part of
revali_router's own public API** — `examples/hello/lib/observers/my_observer.dart`
imports it from there, not from `revali_core`.

`Observer.see` changed from `see(Request, Future<Response>)` to
`see(ObservedRequest)`. Shipping that as a minor breaks every dependent on
`dart pub upgrade`.

- [x] `revali_router` heading → `## 5.0.0`
- [x] Added a `### Breaking Changes` section stating the `Observer.see` change
      and the `revali_core: ^3.0.0` floor. The existing
      `ObservedRequest.summary` bullet stayed under `### Features` — it
      describes new router behaviour, not the break

## 2. Re-release `revali_annotations` and `revali_client_gen` — done

Neither changed, and both had to ship anyway. They were on:

```
revali_annotations   → revali_core: ^2.0.0
revali_client_gen    → revali_core: ^2.0.0, revali_router: ^4.0.2
```

A dependent's constraint is only rewritten if that dependent is itself in the
release. Publishing `revali_core` 3.0.0 and `revali_router` 5.0.0 while these
two stayed behind would leave them pinned to ranges that exclude the new
majors, and **the published set stops resolving**.

- [x] `revali_annotations` → `## 3.1.0`
- [x] `revali_client_gen` → `## 2.4.0`
- [x] Replaced both bodies with a `### Fixes` entry naming the moved floor.
      The previous bodies described the *already published* 3.0.0 and 2.3.0
      and would have been republished as the new versions' notes

### Why minor, and not the major this file first called for

An earlier draft of this file specified `revali_annotations` → `4.0.0` and
`revali_client_gen` → `3.0.0`. That reintroduces the exact failure it is meant
to prevent: **`revali_construct` depends on `revali_annotations: ^3.0.0` and is
not in this release** (2.4.0 == 2.4.0, genuinely unchanged). Annotations 4.0.0
would strand it — while `revali`, `revali_swagger` and `revali_client_gen` all
got rewritten to `^4.0.0` — and fixing that means dragging `revali_construct`
in, and then weighing whether `revali_docker` follows it.

A minor stops the cascade dead: `^3.0.0` still admits 3.1.0, so
`revali_construct` needs no re-release. This also matches the repo's own
precedent — the `revali_swagger` 1.1.0 and `revali_client_gen` 2.3.0 releases
cited below were both **minor** bumps for a moved floor.

**The rule to carry forward: when re-releasing a package solely to move a
dependency floor, prefer a minor.** A major there buys no safety and
propagates the same problem to that package's own dependents.

This has already happened twice in this repo. The `revali_swagger` 1.1.0 and
`revali_client_gen` 2.3.0 entries are both retroactive fixes for exactly this —
worth reading before deciding it is theoretical.

## 3. `revali_swagger` bumped for its unshipped fix — done

Its OpenAPI output is now emitted deterministically. Paths, per-path
operations and component schemas were previously written in filesystem-walk
order, so the same project produced `/complex` first on macOS and `/users`
first on Linux; CI caught it against a macOS-generated golden. The entry was
already written, but sat under `1.1.0`, which equalled the pubspec.

- [x] `revali_swagger` → `## 1.2.0`

## 4. First publish for `revali_test` and `revali_mcp` — done, at 0.1.0

Both are prepared — pub metadata, `README.md`, `CHANGELOG.md`, `LICENSE` —
and both validate: `dart pub publish --dry-run` passes for `revali_test` and
reports **0 warnings** for `revali_mcp`.

Neither would publish as-is, because the release only acts when the changelog
version *differs* from the pubspec version, and a first release naturally has
them equal. Both now use the placeholder-pubspec form, so `0.1.0` is what
lands on pub.dev:

- [x] `revali_test` — pubspec lowered `1.0.0` → `0.0.1`, changelog `## 1.0.0`
      → `## 0.1.0`. It also gained real fixes this round (binary and streamed
      request bodies, repeated-header handling), so this is not only a
      packaging release
- [x] `revali_mcp` — pubspec lowered `0.1.0` → `0.0.1`, changelog stays
      `## 0.1.0`

The `0.0.1` in each pubspec is a placeholder that is never published; the
release script overwrites it with the changelog version on the way out.

## Before running the release

- [x] `./scripts/run_all_tests.sh` passes — `packages run: 41  passed: 41
      failed: 0  skipped: 2`, run with these version edits in place. Do **not**
      substitute `sip test` — it exits 0 over a failing suite. Check the
      summary line, not just the exit code, for the same reason
- [x] Re-derive the version table above and confirm the nine packages marked
      ✅ show `PUBLISH` and the three marked ❌ show `skip`
- [ ] Remember `prep_for_publish.dart` runs `pub publish --force` with **no
      confirmation prompt**. The changelog is the only thing between a wrong
      version and pub.dev

## Deliberately excluded

`og_card` is `publish_to: none` and is not part of this release. See
[RELEASING.md](./RELEASING.md#deliberately-not-published).
