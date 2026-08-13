# TODO

# 8.12.26 — Gap audit

Findings from a read-through of the repo, grouped by how much they hurt. Each
item carries the evidence that produced it so it can be re-checked rather than
re-discovered.

## Tier 1 — Adoption blockers

- [x] Make `revali_test` publishable (was `publish_to: none`, no `version:`)
  - It is the documented way to test a Revali app (`AGENTS.md` → `TestServer()` / `await createServer(server)`) and all 27 `test_suite` packages depend on it by relative path, but no external user could get it
  - `TestServer` is not re-exported from any published package either, so there was no workaround
  - Done: pub metadata, `README.md`, `CHANGELOG.md`, `LICENSE`, and a `1.0.0` entry in `LATEST_CHANGELOG.md`. `dart pub publish --dry-run` passes
  - [ ] **Still to do — actually publish it.** The pubspec version equals the changelog version, so `checkForChanges` treats it as unchanged and `prep_for_publish` (which runs `pub publish --force`) skips it. Bump the `LATEST_CHANGELOG` entry above the pubspec version when ready to cut the first release
- [x] Write a testing documentation page
  - Of the 98 pages under `doc-site/content/`, **zero** covered testing; `TestServer` appeared nowhere in the docs
  - Done: `content/revali/testing.md`, linked as a top-level `Testing` nav item. Covers the `TestServer` pattern, why `createServer` must be awaited, the `/api` prefix and `{"data": ...}` wrapper, header assertions with `expectRecentHttpDate`, streaming via `connect`, and when to bind a real socket instead
  - Verified: site builds, `build/jaspr/revali/testing/index.html` exists, nav link renders on sibling pages, all 35 doc-site tests pass
- [x] Make `revali_mcp` publishable (also `publish_to: none`)
  - `README.md` shipped a Cursor config telling users to run `dart run revali_mcp`; that could not resolve outside this repo
  - Done: pub metadata, `CHANGELOG.md`, `LICENSE`, a `0.1.0` entry in `LATEST_CHANGELOG.md`, and install instructions for both a dev dependency and `dart pub global activate`. `dart pub publish --dry-run` reports **0 warnings**
  - [ ] **Still to do — actually publish it.** Same as `revali_test`: pubspec version equals the changelog version, so the release script skips it. Bump the changelog entry when ready
- [x] **Bug found while prepping it: stdio framing counted characters, not bytes**
  - `Content-Length` is a byte count, but the server buffered `stdin.transform(utf8.decoder)` output and compared decoded character counts against it. `é` is two bytes and one code unit, so *any* non-ASCII message body left the server waiting on data that had already arrived — it never replied
  - The write side had the mirror fault: the header announced `utf8.encode(payload).length` while the body went out via `stdout.write`, which re-encodes using `Stdout.encoding`
  - Fixed by buffering raw bytes and slicing by byte offset; responses are written as UTF-8 bytes
  - Package went from **0 tests** to 6, including an stdio client harness and a regression test for the non-ASCII body that used to hang (it reproduced as a timeout before the fix)

## Tier 2 — Production correctness

- [x] Graceful shutdown in the generated server
  - Generated `main` was just `hotReload(() => createServer(null, args))` — no signal handling. Signals were only handled in the dev CLI (`vm_service_handler.dart`), to kill the child process
  - `handle_requests.dart` detached every request with `unawaited(...)`, so there was no in-flight set to drain even if a handler had existed
  - `revali_docker` generates Dockerfiles → container platforms stop with SIGTERM → in-flight responses were truncated on every deploy and scale-down
  - Done: `InFlightRequests` + `shutdownServer` + `listenForShutdown` in `revali_router`; `AppConfig` gains `handleShutdownSignals`, `shutdownTimeout` (15s) and `onServerStopped`; the generated server wires them up, but only for a server Revali created itself (never a provided `TestServer`, never a worker isolate)
  - Verified end-to-end against a real process: SIGTERM sent 1s into a 3s handler, client still received `HTTP 200 {"data":"drained"}`, port released, exit 0. Confirmed non-vacuous — the same scenario without tracking throws `HttpException` at the client
  - 9 new tests in `revali_router/test/e2e/graceful_shutdown_test.dart`
- [x] **Bug found while building it: `Router.close()` threw `Concurrent modification during iteration`**
  - Each registered cleanup removes itself from `_cleanUp` as it runs, so iterating the live list is unsafe. Unreachable before, because `close()` only ever ran once every request had drained and self-removed — draining made it reachable immediately
  - Also required ordering care: closing the server ends the accept loop at once, so the loop now skips its own teardown while a drain is under way, leaving it to the shutdown path. Otherwise cleanup runs *under* the requests still being served
- [x] Finish request-scoped DI
  - The **read** side was already fully generated: `createGetFromDi()` emits `RequestScopedDI.getFrom(di)` and is used by guard/middleware/interceptor/exception/wrapper content, plus `create_param_arg.dart:100,119` and `create_class.dart:9`
  - But nothing ever installed a `RequestScopedDI` into a zone, so `maybeCurrent` was always `null` and every lookup fell through to the app container. The feature was dead code
  - `RequestScopedDI.onError` and `.dispose` were empty stubs, so per-request resources were never cleaned up
  - Done: `DI.registerRequestScoped<T>` + a `Disposable` interface in `revali_core`; `RequestScopedDI` now caches what it builds, tracks it for disposal, and finds registrations through the `DIHandler` wrapper via a new `RequestScopedRegistry` interface. `Router` takes an optional `di` and installs a scope for the whole pipeline; the generated server passes it
  - Rather than the wrapper-kit approach originally sketched, the scope is installed by the router itself — a kit would have been opt-in, and `registerRequestScoped` silently behaving like a factory when someone forgot the annotation is exactly the bug this exists to prevent
  - Disposal waits until the response is fully written (so streaming/SSE keep their resources) and is awaited on the production path, so a graceful shutdown drains it too
  - `onError` was removed rather than implemented: it had no semantics, no callers, and the failure path is already covered by disposal running whether the request succeeded or threw
  - Verified against a real server: two `@Dep()` params in one handler resolved to the same instance, three sequential requests got `uow=1/2/3`, and each was disposed before the next was built. 30 tests in `revali_core`

## Tier 3 — Feature gaps

- [x] Support controller inheritance (supersedes "Get super methods from classes" under 1.22.25)
  - `ControllerVisitor` collected methods via `element.accept(MethodVisitor(...))`, and `MethodVisitor.visitMethodElement` only sees **declared** methods — endpoints inherited from a base class were silently dropped, with no error. A controller whose only endpoints came from its base produced **zero** routes
  - Done: supertypes are visited after the controller's own methods, so an override wins. `MethodVisitor` records only the names it actually registered, which distinguishes the two override cases — annotated override replaces the inherited route; unannotated override keeps it and dispatches to the override at runtime
  - Generic bases throw an explanatory error instead of generating wrong bindings (the inherited signatures still refer to the type parameters). Worth revisiting with the `substitute_type.dart` machinery the lifecycle components already use
  - Verified live: a controller extending a base and mixing in a mixin served all four routes, and `DELETE /purge` returned `override-purge`, proving the inherited annotation dispatches to the override
- [x] Response compression (gzip negotiated via `Accept-Encoding`)
  - Was entirely absent: the only match for `gzip|deflate|content-encoding` across the router and packages was a doc comment
  - Done: `CompressionSettings` in `revali_core`, exposed as `AppConfig.compression` and `Router.compression`, applied by `DefaultResponseHandler`. On by default, 1 KB threshold, text-shaped mime types only, `Vary: Accept-Encoding` set
  - Only bodies of a **known length** are compressed, which leaves streaming/SSE untouched — gzip buffers, so compressing a stream would hold back chunks the handler meant to flush
  - [ ] Not done: `deflate` and `br`. Gzip is universally supported and the others need content negotiation with q-value ranking to pick between them
- [x] Implement streaming request bodies in the client
  - `revali_client.dart` threw `UnimplementedError('Stream body not implemented')`
  - ⚠ **An earlier note here claimed the server could not receive a streamed body either. That was wrong.** It reasoned from `PayloadImpl`'s `String`/`Json`/`FormData`/`Binary` body-data resolution and from `StreamBodyData` being response-side. The generator has a **separate** path: `@Body() Stream<List<int>>` emits `context.request.originalPayload.read()`, bypassing body data entirely. A live server consumed 100 000 bytes incrementally over both chunked and `Content-Length` POSTs before any client work was done
  - So only the client half was missing. Done: `HttpRequest.bodyStream`, a `BaseRequest` subclass that hands the stream to the transport whole (rather than `StreamedRequest`, which needs the caller to pump its sink and so breaks backpressure), and `Stream<List<int>>` / `Stream<String>` cases in the body switch
  - Other `Stream<T>` throws an `ArgumentError` naming the two supported types, rather than inventing a framing format (NDJSON, length-prefixing) the server has no binding for
  - Verified end to end: `revali_client` streamed 307 200 bytes as 300 lazily-produced 1 KiB chunks into a live server, which counted 307 200. 5 new client tests
  - [x] Checked `revali_client_gen`: it already emits the right thing — `Future<String> upload({required Stream<List<int>> chunks})` passing `body: chunks` straight through. No generator change needed
  - [x] But the **test** transports dropped it silently. `TestClient` sent only `request.body`, so a streamed *or binary* body arrived as an empty string, and `TestRequest` `jsonEncode`d any non-String body while treating a `Stream` body as WebSocket input. A streaming endpoint tested through `TestServer` saw 0 bytes while the same call worked over real HTTP. Both fixed, with regression tests
- [x] Rate limiting (promotes the long-standing "Nice to have" `RateLimit` entry)
  - Done as **`@Throttle`**, not `@RateLimit`. ⚠ **This deviates from the name written in the older todo entry** — worth an explicit yes/no
    - `revali_router` is imported wholesale, so a new export lands in every app's scope. `RateLimit` is a name apps take: this repo's own `generic_lifecycle` fixture defines one, and exporting `RateLimit` broke that package with `ambiguous_import` immediately. `Throttle` is also the idiomatic name elsewhere (Laravel `throttle`, NestJS `@Throttle`)
    - Rename it back if you prefer `RateLimit` and would rather users `hide` it
  - Caller = client IP via `trustedProxy`; bucket = the matched route's registered path, with an optional `bucket` to pool endpoints. Returns `429` with `Retry-After`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`
  - Fixed window, in memory, **per process** — documented rather than implied to be cluster-wide. A caller can send `2 × max` across a boundary, and `workers > 1` multiplies the effective limit
  - Verified live through codegen: `@Throttle(max: 2)` gave 200, 200, 429 with `retry-after=299`, while a sibling endpoint stayed 200. 6 tests
- [x] Widen the `Observer` interface for metrics/tracing
  - It was only `see(Request request, Future<Response> response)` — no timing, no error hook, no route metadata
  - Done via a **second** interface, `RequestObserver`, receiving a `RequestSummary` (method, path, matched route path, status, duration, error) once the request completes. Not a change to `Observer`, so nothing implementing it today breaks; discovered from the same `observers` list, so neither `AppConfig` nor the generator learns a new component kind — implement both
  - Fires in **every** mode. The `RequestTrace` ring buffer stays gated on `debug`/`inspect` because it is debug tooling; telemetry is not
  - `routePath` is the field that matters: labelling metrics with `path` gives one time series per id. 6 tests, including that `/users/1` and `/users/2` share `/users/:id`
  - [x] Resolved by collapsing the two interfaces into one. `Observer.see` now takes a single `ObservedRequest` carrying the request plus futures for the response and the summary — so an observer wanting only the finished picture awaits `observed.summary` instead of implementing a second type. `RequestObserver` and the `RequestListener` marker are gone
  - [x] Also fixed `revali create observer`, whose template still generated `ReadOnlyRequest`/`ReadOnlyResponse` — removed in the context consolidation — so scaffolded observers did not compile

## Tier 4 — Internal quality

- [ ] Close the worst test-coverage gaps (`revali_router` is fine at 39 tests / 93 lib files; these are not)
  - [ ] `revali_annotations` — **0** tests, 42 lib files
  - [ ] `revali_client` runtime — 1 test, 14 lib files; this is the HTTP client every consumer app depends on
  - [ ] `revali_core` — 3 tests, 64 lib files
  - [ ] `revali_mcp` — 0 tests
- [ ] Filter before resolving in `Analyzer._analyzeDirectory` (the last open item from 7.31.26)
  - `analyzer.dart:369-382` fully resolves **every** `.dart` file it walks via `await units.resolved()`, with no pre-filter
  - It already calls `getParsedUnit` first, so the parsed AST can be checked for `@Controller` / `@App` before paying for resolution — which is exactly the deferral `import_ozempic` does

## Tier 5 — Cleanup / redundancy

### CLI: flags are declared twice and stripped by hand

There are three command trees. Two of them are a deliberate outer/inner split —
`clis/revali_runner/` is the user-facing CLI, `clis/construct_runner/` runs
*inside* the generated entrypoint isolate, and `server/cli/commands/create/` is
mounted into the former. The split is fine; the flag duplication is not.

- [x] Declare each command's flags once and derive both parsers from it
  - `dev`: the inner command's 8 flags (`flavor, release, profile, debug, generate-only, dart-vm-service-port, dart-define, dart-define-from-file`) were an **exact subset** of the outer's 13. Outer-only: `recompile, skip-if-fresh, inspect, cert, key`
  - `build`: the inner's 6 flags were an **exact subset** of the outer's 7. Outer-only: `recompile`
  - `ConstructRunnerArgs.constructRunnerArgs` then hand-maintained a strip list to remove the outer-only ones before forwarding — so every new flag was a three-place edit: declare inner, declare outer, update the strip list. Miss the third and the flag leaked into the inner parser
  - Done: `clis/shared/commands/construct_flags.dart` holds `sharedDevFlags` / `sharedBuildFlags`; both parsers call `declareAll`, and the forwarder emits from parsed results. Outer-only flags are absent from the list, so they cannot leak by construction
- [x] **Bug: equals-form flags leak through the forwarder** (found while auditing the above)
  - The forwarder matched whole tokens (`entry == '--cert'`) and then skipped the next token as the value. `--cert=a.pem` is a **single** token, so it matched nothing and was forwarded verbatim to the inner runner, which has no `cert` option → parse failure
  - `dart run revali dev --cert cert.pem --key key.pem` worked; `dart run revali dev --cert=cert.pem --key=key.pem` did not
  - Same shape for `--flavor=x`: it leaked through *in addition to* the explicit `--flavor <value>` the mixin prepended. Inner does declare `flavor`, so it was last-wins and benign — but the same latent fault
  - Fixed by the consolidation above. Covered by `test/clis/shared/commands/construct_flags_test.dart` (10 tests, including both leak shapes) and verified end-to-end with `revali dev --generate-only --cert=… --key=…`
- [x] Extract a shared base for `RevaliRunner` / `ConstructRunner`
  - Both were `CommandRunner<int>` with byte-identical `--loud`/`--quiet` blocks and byte-identical `run()` / `runCommand()` overrides → now `clis/shared/commands/revali_command_runner.dart`

### Codegen: collapse the near-duplicate lifecycle content makers

- [x] Merge `guard_content.dart` and `middleware_content.dart` into one parameterized builder
  - 130 and 131 lines; normalizing the naming left only **29 diff lines**, and just 3 were semantic: method name `protect` vs `use`, short-circuit getter `isBlock` vs `isStop`, terminal call `pass` vs `next`
  - The rest was copy-paste drift — a local named `parameters` in one and `parameter` in the other, differently formatted `literalList` calls — which is exactly the maintenance hazard
  - Done: `.../lifecycle_components/utils/sequential_component_content.dart`; both makers are now ~24-line wrappers. Generated output verified **byte-identical** before/after via a golden capture, and re-verified end-to-end by regenerating `test_suite/constructs/revali_server/middleware`
  - The other three (`interceptor`, `exception`, `wrapper`) genuinely diverge (guard vs wrapper is 122 diff lines) and were deliberately left alone

### Remove deprecated APIs

- [x] Drop the 8 deprecated DI members
  - `registerInstance` → `registerSingleton` and `register` → `registerFactory`/`registerLazySingleton`, each redeclared across all four of `di.dart`, `di_impl.dart`, `di_handler.dart`, `request_scoped_di.dart`
  - No internal callers existed, so removal was clean. `Factory<T>` was left in place — it is a public typedef and not deprecated, though nothing in the repo uses it now
  - `LATEST_CHANGELOG.md` moves `revali_core` from `2.0.1` → `3.0.0` with a Breaking Changes entry. `prep_for_publish.dart` derives pubspec versions and rewrites dependents' constraints from that file, so the four `revali_core: ^2.0.0` pins are **not** hand-edited
  - ⚠ **Release decision still open**: `revali_router` re-exports `package:revali_core/revali_core.dart`, so this removal is visible through its public API and it arguably needs `4.0.2` → `5.0.0` rather than a patch. Same question for `revali` (`3.1.0`). Constraints only auto-update for packages included in the same release
- [ ] Two stragglers elsewhere: `meta_type.dart:86` (`hasFromJson`) and `server_param.dart:124` (`type.importPath`) — left alone for now, different packages and different release cadence

### Repo hygiene

- [x] Delete ~59 MB of stale local logs
  - `logs/` (28 MB) and `log_failures/` (31 MB), last written 2026-05-24, plus the empty leftover `test/` and `web/` directories at the repo root
  - They never appeared in `git status`: the directories were not ignored, but all 34 files were `*.log`, which `.gitignore:3` covers — invisible clutter rather than obvious clutter
  - Verified before deleting: 0 tracked files, and no non-`.log` file anywhere in them
- [x] Remove the stale `.gitignore` entry `constructs/revali_server/bin/tester.dart` — that path no longer existed after the `revali_server` consolidation
- [ ] Keep `small_test/` and `playground/` — both checked, both real. `small_test/` is a fixture used by `packages/revali/test/utils/directory_extensions_test.dart:41,52`; `playground/` is the benchmark harness with its own README/BENCHMARKS

### Found while fixing the gate

- [x] **CI ran no tests either.** The only test workflow was `CI Smoke`, which generates code for `small_test` and runs nothing. Combined with the vacuous pre-push hook, **nothing had ever run the suite automatically** — every green check this repo has shown was one or the other of those
  - Added `.github/workflows/tests.yaml`, which uses the same `scripts/run_all_tests.sh` and so inherits its floor. Verified by watching the run: `packages run: 41  passed: 41  failed: 0`
- [x] **Test-suite generation only ever worked on macOS.** The pubspec comment-out/uncomment steps used `sed -i ''`, which is BSD-only; GNU sed takes the empty string as its script and the real script as a filename, so on Linux every call failed with `can't read 12s/^#*//g`. Replaced with `perl -i`, identical on both. This is why CI could not generate
- [x] **`sip run publish` verified with the vacuous runner too** — `sip test --recursive --bail`, which exits 0 having run nothing. It would have published against no verification at all. Now uses the real gate
- [x] **The OpenAPI spec was not deterministic.** Paths, per-path operations and component schemas were emitted in filesystem-walk order, so the same project produced `/complex` first on macOS and `/users` first on Linux — caught by CI against a macOS-generated golden. All three are now sorted, goldens regenerated

### Found while asking "what's next" — read these first

- [x] 🔴 **The pre-push test gate runs zero tests and exits 0.**
  - `hooks/pre_push.dart` runs `sip test --recursive --bail` from the **repo root**. Observed directly: it prints `Results: ✅ 0 ❌ 0 ⚠️ 0`, emits `LoadSuite.forLoadException` errors and `Could not find package `test``, and **exits 0**
  - So the green `✓ Test Suite` on every push means nothing was run, not that anything passed. The four genuinely failing `test_suite` tests below have been sailing past it
  - The `Generate Test Suite` step before it *does* work — it is only the run that is empty
  - Worse than first reported: `sip test` under-reports even where it *does* run. In `test_suite/constructs/revali_server/access_control`, `dart test` exits 1 with 3 failures while `sip test` exits 0 reporting "40 passed, 0 failed" — the failures vanish from both the count and the exit code. So `sip run ts` was never a safe replacement either
  - Done: `scripts/run_all_tests.sh` runs `dart test` per package, fails if any package fails, and **fails if fewer packages ran than expected** so "discovered nothing" cannot look like "everything passed". Packages that cannot run tests are skipped and reported as skipped
  - Verified in all three directions: red with 4 failing packages, red with `--min 500` against 41 discovered, green at 41/41
- [x] **Fixed the 4 packages the old gate had been hiding** — and only one was a stale test
  - `middleware` — stale assertion: pinned the whole debug body as an exact prefix, broken by a richer `MissingArgumentException` message
  - `access_control` — stale assertions: still expected `403` for a request with no `Origin`, which `3a3b7b92` deliberately changed without updating the tests
  - `revali_client/cookies` — **real bug**: `CookieParser` could not parse a comma-joined multi-cookie header at all, and stored `Path`/`Expires` as cookies. `TestHeaders.add` also overwrote instead of appending, so only the last cookie survived
  - `revali_client/default_custom_params` — **real bug**: generated code did not compile for a parameter whose wire form is a string but whose type is a custom class. Any app with such a parameter failed to build
- [ ] 🔴 **`revali_router` is versioned `4.1.0` for a breaking change.**
  - `revali_router.dart` re-exports `package:revali_core/revali_core.dart` hiding only `AppConfig`, `Body` and `LifecycleComponents` — so `Observer` is part of **revali_router's** public API, and `examples/hello` imports it from there
  - `Observer.see`'s signature changed, which is breaking for revali_router consumers. Shipping it as a minor breaks every dependent on `dart pub upgrade`
  - Same question for `revali` (`3.2.0`), which re-exports less but should be checked
  - One-line changelog edit, but it has to happen before any release

### Found while working Tier 3

- [ ] **Pre-existing failures: `test_suite/constructs/revali_server/access_control` → `allow_origin_controller_test.dart`**
  - Three tests expect `403` for a missing `Origin` and get `200`: "combined returns an error response when child nor parent origin are not present", and the "inherited" / "not-inherited" equivalents
  - Confirmed **not** caused by the Tier 3 work: stashed all local changes, regenerated on clean `main`, and it fails identically (`+40 -3`)
  - Like the `pre_interceptor_test` failure below, it only surfaces after a regenerate — which raises a separate question, since the pre-push hook runs the suite and passed. Worth checking whether the hook's suite run is testing stale `.revali` output

### Found while working Tier 1

- [x] **`sip run publish` was broken.** `findPackages()` discovers `packages/og_card` (no `publish_to: none`, full pub metadata), but it had no `LATEST_CHANGELOG.md` entry, and `checkForChanges` calls `exit(1)` on the first package missing one. Broken since og_card landed in `b22baf4c`
  - Fixed with an entry at its current `0.1.0` (found → unchanged → skipped) plus the `LICENSE` pub validation requires
  - [ ] og_card still has no `README.md` or `CHANGELOG.md` — pub warnings, not errors, so it can publish without them
- [x] **The docs spell check checked nothing.** Both `scripts.yaml` and `.github/workflows/spell_check_docs.yaml` globbed `doc-site/docs/**`, a path that stopped existing when the docs moved to `content/` in the Jaspr migration. Both passed vacuously
  - Repointed at `content/`, which surfaced 25 unknown words across 17 files — all legitimate technical terms, now in `allowed_words.txt`. Also split `mrgnhnt`/`Ashburn`, which had merged into one entry because the file had no trailing newline
  - cspell now reports 0 issues across 99 files, locally and CI-style

### Found while cleaning up

- [ ] **Pre-existing failure: `test_suite/constructs/revali_server/middleware` → `pre_interceptor_test.dart`**
  - "should throw if user is not added to the request" expects the debug body to *start with* `Error: MissingArgumentException: key: data, location: @data\n`, but the actual message now continues `, expected: User, actual: null` and is followed by a `Stack Trace:` block
  - `missing_argument_exception.dart:28,31` append `expected:` / `actual:` when known. Both the exception and the test were last touched by the same commit (`2630ff46`, 2026-07-31), so the expectation looks like it was written against output from before those fields were populated
  - Confirmed **not** caused by the cleanup: stashed all local changes, regenerated the package on clean `main`, and the test fails identically
  - Only surfaces after a regenerate — `test_suite/**/.revali` is gitignored, so a stale local tree hides it

### Worth auditing (lower confidence)

- [ ] The `package:revali/revali.dart` barrel exports 43 entries, including internals like `ast/analyzer/…`, `handlers/vm_service_handler.dart` and `utils/kernel_cache.dart`
  - Partly forced: `construct_entrypoint_handler.dart:612` writes an import of that barrel into the generated entrypoint, so it must expose the construct-running surface
  - But it currently makes every internal a public API, so any refactor is technically breaking. Worth splitting a narrow `revali_entrypoint.dart` from the general barrel

# 7.31.26 — Analyzer performance (ByteStore cache)

`import_ozempic` now uses the same on-disk analyzer cache DAS / `build_runner` rely on. We should do the same in `packages/revali/lib/ast/analyzer/analyzer.dart`.

## What landed in import_ozempic

Public `AnalysisContextCollection` always uses an ephemeral `MemoryByteStore`, so every process start (and every full re-init) re-links from scratch. Switch to the impl and inject a persistent store:

```dart
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';

_analysisCollection = AnalysisContextCollectionImpl(
  includedPaths: [...],
  resourceProvider: _memoryProvider, // keep our MemoryResourceProvider
  sdkPath: await sdkPath,
  byteStore: MemoryCachingByteStore(
    EvictingFileByteStore(
      // e.g. <project>/.dart_tool/revali/analysis-cache
      cachePath,
      256 * 1024 * 1024, // on-disk budget
    ),
    64 * 1024 * 1024, // in-process LRU
  ),
  fileContentCache: FileContentCache(_memoryProvider),
);
```

Reference implementation: `import_ozempic` → `lib/domain/analyzer.dart`.

In practice the second analysis pass on the same project dropped from ~85s → ~10s there once the byte store was warm.

## Why this matters for Revali specifically

- We already keep sources in a `MemoryResourceProvider` and refresh them on file watch — that is **file content**, not **analysis results**.
- Linked element models / errors still get recomputed unless a `ByteStore` is provided.
- `dev` keeps the process alive, so the in-memory LRU helps hot reload; the on-disk `EvictingFileByteStore` helps across CLI restarts and full `initialize()` rebuilds (we currently recreate `_memoryProvider` + ACC).
- Private `analyzer/src/...` APIs — same class of dependency we already accept elsewhere; pin/test on analyzer bumps.

## Suggested follow-ups while touching this

- [x] Wire `AnalysisContextCollectionImpl` + `MemoryCachingByteStore(EvictingFileByteStore(...))` + `FileContentCache` in `Analyzer.initialize`
- [x] Persist cache under `.dart_tool/revali/analysis-cache` (gitignore already covers `.dart_tool`)
- [x] Confirm byte-store hits still work with our memory FS + `changeFile` / `applyPendingFileChanges` refresh path (invalidate correctly on content hash change — analyzer does this via content hashes)
- [x] Consider `withFineDependencies: true` later for incremental `dev` re-analysis (more experimental; bigger win for long-lived sessions than cold one-shots)
- [ ] Optional: stop resolving every file in a directory walk up front if we can filter first (import_ozempic deferred `getResolvedUnit` until after filters) — less critical for routes-only analysis

## Background / links

- DAS uses `ByteStore` this way; public ACC does not expose it ([analyzer#46914](https://github.com/dart-lang/sdk/issues/46914))
- `build_runner` 2.12–2.14 performance work (file content cache, triggers, AOT) — [dart-lang/build#4405](https://github.com/dart-lang/build/pull/4405), [triggers docs](https://pub.dev/packages/build_config#triggers)

---

- [x] Add support for generics in `fromJson` factories
  - Supports `json_serializable`'s `genericArgumentFactories: true` shape: `factory Foo.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT)` and `Map<String, dynamic> toJson(Object? Function(T) toJsonT)`, recursing per type argument
- [x] Support multi path set-cookie headers
  - Each cookie now gets its own `Set-Cookie` header line (`SetCookies.headerValues()`) instead of being joined into one invalid line
- [x] Add documentation on how to use `mkcert` to run the server with HTTPS
  - Also added real `--cert`/`--key` flags to `revali dev` so no `AppConfig.secure` code is needed for local HTTPS testing
- [x] Update documentation to reflect the new `headers.set(expose: true)` param
- [x] Add optional param to `headers.set(expose: true)` to expose the header to the client
  - [x] This is required because browsers will block headers that are not exposed to the client

- [x] Add tutorials for the following features:
  - [x] **Middleware** - Add request/response processing
  - [x] **Error handling** - Create custom error responses
  - [x] **Authentication** - Secure your endpoints
  - [x] **Database integration** - Connect to your data layer
- [ ] Add "request" scoped dependencies
  - [ ] App scoped (global and don't get refreshed)
  - [ ] Request scoped (get refreshed for each request)
    - This would mean that we need to create a new DI instance for each request, to avoid sharing data between requests, since we are following the DI singleton pattern
- [ ] Remove websocket 1 way modes
- [x] Improve "Deleting precompiled script and retrying..." failure
  - Compile a revali app on using an older version of the dart sdk
  - Upgrade the dart sdk
  - Restart the revali app without recompiling
  - Fixed: the retry path now recompiles the kernel before the second `Isolate.spawnUri` attempt instead of just deleting it and failing again
- [ ] Figure out a way to handle sending streams from the client to the server
- [x] Fix issue where revali client is add multiple same cookies
- [x] Fix issue where if 2 paths match, the order should be
  - No path ids first
  - longest paths first
    - This solves the issue where `places/near-me` would match `places/near-me/123`

  - The following code should only add the cookie once, but it is adding it multiple times

  ```dart
    class Auth implements LifecycleComponent {
      const Auth();

      GuardResult guard(Data data, @Cookie('Auth') String? auth, Meta meta) {
        if (meta.has<Public>()) return const GuardResult.pass();
        if (auth == null) return const GuardResult.block();

        return const GuardResult.pass();
      }

      MiddlewareResult middleware(Data data, @Cookie('Auth') String? auth) {
        if (auth case final token?) {
          data.add(AuthToken(token));
        }

        return const MiddlewareResult.next();
      }
    }
  ```

- [ ] Think of ways to better support micro services

# 12.17.25

- [x] Consolidate `context` into a single class, no more multiple context types
- [x] Remove `ReadOnly` and `Mutable` classes
- [x] Deprecate `allowed headers`, replace with `prevent headers`, allow all headers by default

# 6.21.25

- [x] Print out syntax errors preventing a hot reload

## 4.26.25

### Revali Server

- [x] If binding type is an enum, then update the switch statement to use `String` instead of `Map` and parse the value via `Enum.values.fromName(value)`
- [x] If enum has `fromJson` and `toJson` methods, support them

### Revali Clientg

- [x] Support enum conversion
  - [x] Call `toJson` if available, otherwise call `name`

## 4.3.25

- [x] Get default arg from method param and supply to server handler instead of throwing
- [x] Check for null values before piping
  - Unless the pipe can handle nulls
  - If default value is available, and the body is null and the pipe can't handle nulls, provide the default value (without piping)
  - If default value is not available, proceed as normal
- [x] Add a switch before piping to determine if body is correct type then throw custom error or proceed as normal

## 3.29.25

- [x] Create a new type to asynchronously send websocket messages
  - The current setup allows for reactive responses, but doesn't allow for sending messages _whenever_ we want
- [x] I think that websockets might need to be handled differently. Instead of `yield null` I think that we need to be yielding the response of the handler
  - When creating L.K., the message was getting sent immediately, causing the client to receive an empty message, causing the client to re-request the message

## 1.22.25

### Revali

#### Fix

- [x] It seems like SSE blocks the further requests from coming in..

- [ ] Get super methods from classes to allow for inheritance and better community support

## 10.3.2024

### CLI

- [x] Add `create` command to the revali cli to create new
  - [ ] Constructs
  - [ ] Routes
  - [x] Controllers
  - [x] Guards
  - [x] Exception Catchers
  - [x] Pipes
  - [x] Interceptors
  - [x] Middlewares
  - [x] Apps
  - [x] (etc)

## 7.17.2024

## Feedback

- [x] Figure out why we got an error when calling `body['data'] = value.toJson()
- [x] Delete "old" files within .revali directory on hot reload
  - Create a Set of paths, remove a path when the file is updated/created. Delete any remaining paths
- [x] When a value is provided to 'arg', the `paramName` also gets that value, instead of the name of the parameter
- [x] Think of new names (?) for `arg` and `paramName`
- [x] Change `transform` to a `FutureOr` type to allow for async methods
- [x] Remove check to force only one app in `*.app.dart`
- [x] Create general package for revali server that exports all annotations and core functionality
- [x] Ensure we can return streams from endpoints
- [x] Handle streams in websocket responses

## Features

- [x] revali build
  - Compiles the server code and prepares the "out-going" directory with any Public files
    - We may need to have a configuration file to handle what to ignore/include
  - Shipped: `packages/revali/lib/clis/revali_runner/commands/build_command.dart`, documented at `doc-site/content/revali/cli/build.md` (`--release`/`--profile`, `--flavor`, `--recompile`, `--dart-define`)
- [ ] revali upload
  - Uploads the "out-going" directory to a server
- [x] Catch errors thrown by the generator
  - Clear the console, then print the error
  - We want to avoid exiting the process at all costs!
  - Maybe we can handle this with the Isolate?

## 7.15.2024

- [ ] ~~Find a way to support partial content requests~~
  - Maybe later
- [x] CORs for apps ([docs](https://github.com/lenniezelk/shelf-cors-headers/blob/main/lib/src/shelf_cors_headers_base.dart#L52))

## 7.13.2024 (2)

- [x] Handle range file requests
- [x] Handle if modified since file requests
- [x] Send back last modified header for files
- [x] Set headers based on body data type (within the send request method only!)
  - Create headers getter on the body data type
- [x] Update the content disposition header for files

## 7.13.2024

- [x] Update headers when status code changes
- [x] Update headers when body changes
- [x] Returning files
- [x] Public files
  - Routes will be automatically generated for these files
  - The files will be served from the `public` directory
- [x] Static files
  - Routes will _not_ be generated for these files
  - The idea is that the user will be able to return a "ServerFile" class with the path pointing to the file

## 7.10.2024

## Features

- [x] Dependency injection for apps
- ~~[ ] Wildcard paths~~
  - Maybe later...
- [x] Web sockets
- ~~[ ] Returning streams (not as web sockets)~~

## Try

- [ ] Attempt to create a variable for combine types as an annotation
  - This could allow me to get the values of the fields of the annotation

## 7.5.2024

- [x] Create "App" annotation
  - This will be used for configurations such as
    - [x] Server lambdas
    - [x] Server configurations
    - [ ] Dependency injection
    - [x] Global exception catchers
    - [x] Global guards
    - [x] Global prefix
    - [ ] CORS
    - (Nice To Haves):
      - Rate limiting
- [x] Add flavor flag to the annotation & to the CLI to determine what environment the app is running in

## 7.1.2024

- [x] Add `Pipe` class for annotations
  - This will be used to convert the annotated item to another type
- [x] Add `Guard` class for annotations
  - This will be used to stop or continue the execution of the method/endpoint
  - We could create a field for types where we could annotation like `@Guard([AuthGuard, RoleGuard])`
    - This wouldn't allow for _all_ edge cases, but could be useful
    - We could also add a different field coupled with a different constructor to allow for instances of guards
- [x] Create `Catch` class which will be used to catch errors thrown by the method/endpoint
  - The errors would need to implement the `ExceptionCatcher` interface
  - We could create a field for types where we could annotation like `@Catch([UnknownCatcher, ServerCatcher, BadRequestCatcher])`
- [x] Create `HttpCode` class which will be used to set the status code of the response
  - `@HttpCode(200)`
- [x] Create `SetHeader` class which will be used to set the headers of the response
  - `@SetHeader('Content-Type', 'application/json')`
- [x] Create `Redirect` class which will be used to redirect the user to another endpoint
  - `@Redirect('/home')`
- [x] Create `Body` class which will be used to get the body of the request as a parameter
  - `@Body()`
- [x] Create `Header` class which will be used to get the headers of the request as a parameter
  - `@Header('Content-Type')`

# Nice to have

- [ ] Create `RateLimit` class which will be used to limit the number of requests to an endpoint
  - `@RateLimit(10, Duration(minutes: 1))`

## > 7.1.2024

---

- [ ] ~~Combine revali and revali_server into a single package~~
  - ~~This is because shelf is really the only http server that we will be using, and we want consistency~~
  - ~~We also don't want constructs to run scripts, which is what we would have to do if the revali_server package was separate~~
  - This is fine actually, we will have a flag within the config file that will determine whether the dependency is a "router" generator or other
- [x] Create `revali_construct` package to hold the core functionality of revali
  - This way developers don't need to depend on the entire revali package, just the necessary parts

## Create entrypoint for constructs

So I just figured out how I can get the constructs that the dev is depending on implicitly

1. Ge the dev dependencies
2. Resolve their paths and look for a construct.yaml file
3. Parse the construct.yaml file to get the configuration

No that I have the construct configs, I need a way to generate the code that the constructs will provide. Thankfully [build_runner](https://github.dev/dart-lang/build/tree/master/build_runner) has already done the work for this and I can follow their footsteps.

I can do this by creating a file within `.dart_tool/revali/entrypoint/revali.dart`

The code within this file should look like

```dart
import 'dart:io' as io;
import 'dart:isolate';

import 'package:revali/revali.dart';
import 'package:revali_server/revali_server.dart';

final constructs = <Construct>[
  revaliShelfConstruct(),
];

const path = '/Users/morgan/Documents/develop.nosync/revali/examples/demo/routes';

void main(
  List<String> args, [
  SendPort? sendPort,
]) async {
  var result = await run(
    args,
    constructs: constructs,
    path: path,
  );
  sendPort?.send(result);
  io.exitCode = result;
}
```

Obviously this will need to be modified so that we don't have conflicts in the imports.

Once I have this file, I can execute it

```dart
await Isolate.spawnUri(Uri.file(p.absolute(scriptKernelLocation)), args,
messagePort.sendPort,
errorsAreFatal: true,
onExit: exitPort.sendPort,
onError: errorPort.sendPort);
```

In build_runner, they are compiling the code to a kernel file and then executing it. I will probably need to do the same thing.

Once the code is executed, it will run the code found within the `revali` package and generate the code provided by the constructs, provided by the generated `revali.dart` file.
