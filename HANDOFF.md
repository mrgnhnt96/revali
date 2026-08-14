# Microservices work — handoff

Everything below came out of one item in `todo.md`: *"Think of ways to better
support micro services."* The worked-out analysis lives in
[MICROSERVICES_PLAN.md](./MICROSERVICES_PLAN.md); this document is for whoever
picks the work up next.

**State:** 56 commits, 303 tests added across 27 files, 46/46 packages green,
working tree clean, **nothing published**.

---

## Read this first

Three things will bite you before anything else does.

### 1. Nothing is published, and the release is staged

Eight packages are staged in `LATEST_CHANGELOG.md` and will publish the next
time someone runs `sip run publish`.

> **Updated 2026-08-13.** `prep_for_publish.dart` used to run
> `pub publish --force` with **no confirmation step**. It now prints a full
> release plan and asks before publishing, refusing outright when no terminal is
> attached. `--yes` is the deliberate opt-out for CI. The eight packages below
> are still staged and still unpublished.

| Package | Current | Staged | Note |
|---|---|---|---|
| `revali` | 3.2.0 | **3.3.0** | |
| `revali_annotations` | 3.1.0 | **3.2.0** | |
| `revali_construct` | 2.4.0 | **2.5.0** | |
| `revali_core` | 3.0.0 | **3.1.0** | |
| `revali_router` | 5.0.0 | **5.1.0** | |
| `revali_client` | 2.1.0 | **3.0.0** | **breaking** — see below |
| `revali_client_gen` | 2.4.0 | **2.5.0** | only to re-pin its `revali_client` floor |
| `revali_redis` | 0.0.0 | **0.1.0** | brand new package |

To hold the release, revert the version headings in `LATEST_CHANGELOG.md`. The
code is independent of them.

### 2. A publishing trap that hides in the skip path

> **Corrected 2026-08-13.** This section originally claimed `revali_test` and
> `revali_mcp` were "stuck" and needed a changelog bump. They are not: both are
> live on pub.dev at `0.1.0` (published `17:16Z`, hours before this handoff was
> written). Bumping them as originally instructed would have republished
> already-released packages. `todo.md` carried the same error and is fixed too.

`prep_for_publish.dart` publishes a package **only when its
`LATEST_CHANGELOG.md` version differs from its `pubspec.yaml` version.** Equal
versions mean *skipped*, and until now that happened silently.

Equal is the *normal* state: after a successful publish the pubspec is bumped to
match the changelog, so every package not being released sits equal. The defect
was never that equal-means-skip is wrong — it is that "correctly up to date" and
"someone forgot to bump the changelog, so this release did nothing" produced
identical output, namely none, while the run still exited 0.

A brand-new package is the sharp edge: its first version appears in both files,
so it is skipped forever and never reaches the registry. `revali_redis` works
around this by starting its pubspec at `0.0.0`.

**This is now fixed.** The script asks pub.dev what is actually published and
prints a plan covering *every* package, so "equal" splits into `current`
(registry has it) and a loud `MISSING` (registry does not). A new package no
longer depends on anyone remembering the `0.0.0` trick.

### 3. `sip test` and `dart test` disagree

`dart test` honours `dart_test.yaml` tag skips. **`sip test` does not** — and
the pre-commit hook runs `sip test`. The Redis integration tests were tagged
`integration` and skipped by `dart test`, but the hook ran them anyway and
failed without a server, blocking three commits.

They now check for a reachable server *inside each test body*, so they
self-skip under any runner. Keep that pattern for anything needing external
infrastructure.

`AGENTS.md` already warns not to verify with `sip test` because it under-reports
failures. This is a second, different way the two runners diverge.

---

## What shipped

Eight gaps, framed around one hop — what breaks when service A calls service B.

| # | Gap | Result |
|---|---|---|
| 1 | Context died at the hop | `TraceContext` — ambient request id, W3C `traceparent`/`tracestate`, baggage |
| 2 | No health or readiness | `/healthz` + `/readyz`, `drainDelay`, worker-isolate shutdown broadcast |
| 3 | Config couldn't come from env | `Env`, `AppConfig.fromEnv` (`0.0.0.0` + `$PORT`) |
| 4 | No client resilience | Timeouts, `RetryPolicy`, interceptors that can short-circuit |
| 5 | Contract drift undetectable | `revali routes --check` (**client generation dropped — see below**) |
| 6 | Errors didn't survive the hop | `HttpError` + `{"error": {...}}` envelope, parsed client-side |
| 7 | Multi-service repos | `revali services`, `revali compose`, `revali up` |
| 8 | HTTP/WebSocket only | `MessageBroker`, `@Consumes`, `revali_redis` |

### The one design that was wrong

**Gap 5 proposed generating a typed client from `routes.json`. That was
impossible and the plan flagged the premise as unverified.** When checked, the
manifest carried *no return types at all* and only bare type-name strings — no
fields, no nested types, no serialisation strategy. It is a route *table*, not a
type model.

What shipped instead is drift *detection*, which is where the value was:
`revali routes --check <pinned.json>` exits non-zero on a breaking change.
Generating clients from a manifest is **dropped, not deferred**. If you want
cross-repo typed clients, the remaining path is publishing the generated client
package to a registry — the generator already emits a whole package with a
pubspec, so the gap is distribution, not description.

### Breaking changes in `revali_client` 3.0.0

1. `HttpInterceptor.onRequest` / `onResponse` return `FutureOr<HttpResponse?>`
   instead of `void`. Return `null` to continue. Migration is mechanical.
2. Interceptor errors now propagate instead of being swallowed.

Both were done early *because* the blast radius is currently one class. It only
grows.

---

## Verifying it

```bash
./scripts/run_all_tests.sh        # 46 packages, the way CI does it
```

Redis integration tests are skipped unless a server is reachable:

```bash
redis-server --port 6399 --save '' --daemonize yes
cd packages/revali_redis
REDIS_TEST_PORT=6399 dart test --run-skipped --tags integration
```

Codegen changes need `--recompile`, since the kernel embeds the makers:

```bash
cd <app> && dart run revali dev --generate-only --recompile
```

---

## What is deliberately not done

Not oversights — decisions, with reasons.

- **Circuit breaking.** Needs shared state across calls and a re-close policy.
  The new interceptor signature makes it buildable outside the framework.
- **Generated typed exceptions per endpoint.** Needs handlers to declare which
  errors they can raise — an annotation plus a contract to carry it. `HttpError`'s
  `code` gets most of the value and doesn't foreclose it.
- **Auth forwarding in `TraceContext`.** Forwarding a caller's bearer token to
  an arbitrary host is a credential leak; the client can't know the target is a
  trusted peer.
- **Guards and middleware on consumers.** A guard exists to reject a caller, and
  a queue message has none. Consumers get DI scoping, tracing and shutdown.
- **Client generation from `routes.json`.** See above.

## What is genuinely unfinished

- **Hot-reload keystrokes under `revali up`.** `r`/`c`/`q` don't reach children,
  because their stdin isn't a terminal. File-watching reload works. Fix is
  either forwarding stdin to a selected child or having the runner write
  `.revali_cmd` per service.
- **Redis reconnection depth.** A dropped *client* connection backs off and
  retries. A *server* restart is not handled — the consumer group isn't
  re-established.
- **Retry/timeout against a real socket.** Tested against fake transports only.
- **The SIGTERM drain under multiple workers** is verified only by a manual
  three-worker run, not automated. Probably the most valuable remaining hole.

---

## The habit that mattered most

**Six bugs this session were found by running things for real, after unit tests
passed.** Every one lived in a place tests were happy with:

1. `TraceContext` installed only on `Router.handle` — but the generated server
   uses `handleRequest`. Would have been null in *every real app* while unit
   tests passed.
2. `AppConfig.fromEnv` added only to the core `AppConfig` — but `revali_router`
   hides it behind its own subclass, which is what apps extend. 21 core tests
   passed; every real app failed to compile.
3. Three services in `examples/` are all named `hello`. Compose keys are YAML
   mapping keys, so duplicates *silently* drop a service.
4. Child processes redraw with a bare `\r`, which overwrote the very prefix
   saying which service a line came from — corrupting output exactly when
   several services start at once.
5. `routes.json` reported `Future<String?>` unwrapped, so a handler becoming
   async read as a breaking change and nullability was read off `Future`.
6. `RevaliClient` decoded error bodies with `transform(utf8.decoder)`, which
   throws on the `Stream<Uint8List>` `package:http` returns — *every* structured
   failure surfaced as a `TypeError`.

Two claims I made and had to retract after checking: that an app without
messaging would generate identically (it didn't — an empty `drainConsumers()`
stub leaked in), and that the first multi-worker drain test proved anything (it
passed against the broken build too, because every request took the same 3s).

**Diff generated output. Run the thing. Force the feature off and confirm the
test fails.** That last one caught a vacuous test twice.

---

## If you want a recommendation

Publish. Every priority here was derived by reading source, not from anyone
reporting a problem — accurate about the code, unvalidated about what people
actually hit. The queue is eight packages deep and the next feature is a guess
until someone uses this.
