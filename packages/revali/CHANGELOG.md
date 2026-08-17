# CHANGELOG

## 3.3.2 | 08.16.26

### Fixes

- **A file the analyzer could not read was recorded as a file that did not exist.** Setting up the analysis workspace mirrored every file in the project, its dependencies and the whole Dart SDK through a single unbounded `Future.wait`, each branch ending in `catch (_) { return null }`, and a null was then skipped when populating the overlay. Every in-flight read holds a file descriptor, so on a default limit — 256 on macOS, 1024 on most Linux distributions — the fan-out exhausted it and every read that lost was silently dropped: measured against this repository's own test suite, 2772 of 3787 files at a 1024 limit, among them every SDK source and the `libraries.dart` that tells the analyzer what `dart:core` is. The SDK is mirrored last, so it does not lose a coin toss, it loses every time — which is why the symptom presented as a corrupt SDK or an inexplicable `Target of URI doesn't exist` rather than as an I/O limit, and why it followed the machine rather than the project. Reads are now bounded, so descriptor use no longer scales with the size of the workspace. A path that genuinely does not exist is still skipped, since these lists come from a filesystem walk that races with ordinary edits; every other failure is reported, and a failed **SDK** read now aborts initialization outright instead of proceeding against a partial SDK and blaming the result on your code.
- Mirror only the part of the SDK the analyzer can read — `lib/` and `version`, excluding `*.dill`, which is kernel for the VM and the web compilers rather than an analyzer summary. The previous walk pulled in `bin/` as well: the VM itself, the AOT snapshots and the bundled DevTools assets, none of which any analysis has ever opened. That is 610 files and 550.4 MiB reduced to 459 and 8.1 MiB, and because the overlay never evicts, the difference was resident for the entire life of a `revali dev` session rather than momentary. Initializing against this repository's test suite now peaks at roughly 4.5 GB where it previously peaked at roughly 6.7 GB.
- Say so when a file cannot be checked for analysis errors. The same `catch (_)` sat on the error scan, whose empty result is what gates code generation — so a file that could not be analyzed was indistinguishable from a file with nothing wrong with it, and a run that had checked almost nothing reported a clean project and generated against it.

## 3.3.1 | 08.15.26

### Fixes

- The `revali ai` reference now describes `revali_redis`'s retry behaviour — `retryAfter`, and `maxDeliveries` counting the first delivery — and tells anyone writing their own `MessageBroker` to put its consumer name through `IsolateIdentity.scopeName`. The reference is what an assistant reads to answer "how do I make this retry", so a version of it that predates the options is a confidently wrong answer rather than a missing one. Nothing else in the CLI changed; this ships so the text lands with the `revali_core` 3.2.0 and `revali_redis` 0.2.0 it describes.

## 3.3.0 | 08.15.26

### Features

- The generated server serves liveness and readiness probes. `healthRoutes` is registered alongside the `public` routes — **outside** the app prefix, so they answer on the bare paths an orchestrator is configured with rather than under `/api`. Readiness closes over the server's `InFlightRequests`, so it reports `503` as soon as a shutdown begins.
- The generated shutdown honours `AppConfig.drainDelay`, but only on `SIGTERM`. `SIGINT` is a human at a terminal who wants the process gone now; `SIGTERM` is an orchestrator, which is who the delay exists for.
- The generated shutdown reaches worker isolates. Workers are spawned with a registration port and drain on the parent's command instead of watching signals themselves, and the parent drains its own isolate concurrently with theirs before exiting — so probes report `503` across the whole fleet at once, and `exit(0)` no longer truncates requests still running in a worker. Verified against a running three-worker server: with uneven request durations, the longest request on a worker returns `200` where it previously died with no response at all.
- `routes.json` gains `returns` and `returnsNullable`, and its `version` moves to `2`. It previously carried **no return type at all**, which is why the manifest could describe a route table but not a contract.
- Add `revali routes --check <pinned.json>`, which compares the current manifest against one a consumer pinned and exits non-zero on a breaking change, so it works as a CI gate. Severity is judged from the caller's side: a removed route, a new required parameter, a parameter that became required, a changed type or location, a changed or newly-nullable return, and a changed transport all break callers; an added route, a new optional parameter and a relaxed requirement do not. A removed parameter is reported as compatible rather than breaking — the server still accepts callers that send it, it just ignores the value now. Parameters are matched on their **wire** name, so renaming a Dart argument while keeping `@Query('id')` reports nothing. Comparing against a version 1 pin says return types were not compared rather than silently treating absent as unchanged.
- `routes.json` reports return types **unwrapped**: what a caller receives is the awaited value, so `Future<String>` and `String` are the same contract. Leaving the wrapper on flagged a breaking change the moment a handler became async, and read `returnsNullable` off `Future` rather than off what is actually returned — so `Future<String?>` claimed to be non-nullable and the nullability check could never fire for an async handler.
- Generate consumer registration for methods annotated with `@Consumes(topic, group:)`. A `registerConsumers` function is emitted beside `routes`, constructing controllers the same way so a singleton controller is shared with its routes rather than rebuilt for messages. Handlers take a `BrokerMessage` or nothing; anything else is rejected at generation time, naming the method, rather than emitting code that will not compile. A method that is both a route and a consumer, or carries two `@Consumes`, is rejected for the same reason. Nothing at all is emitted when no handler is annotated — a server generated for an app without messaging is byte-identical to one generated before this existed.
- Consumers drain **before** HTTP during shutdown: they pull *new* work, so leaving them running while requests drain means the process keeps taking on messages it is about to abandon.
- The generated server publishes which isolate it is, as `IsolateIdentity`. Only it can know: the parent is what spawns the workers, so nothing else is in a position to tell them apart, and consumers register in *every* isolate — meaning an app with `AppConfig.workers` above 1 ran the same `createBroker()` override everywhere and got the same consumer name in each, which is the collision a consumer name exists to prevent, reached without the app doing anything wrong. The parent already handed each worker a boot payload; it now carries the loop index it spawned that worker under, and `createServer` republishes it once `app` exists, since `workerCount` is `app.workers`. Two orderings are load-bearing, and both are covered by tests because getting either wrong still compiles and silently does nothing: it is published **before** `runStartup`, which is where `createBroker()` runs and where a broker would otherwise read the unset default and name itself isolate 0; and it is read-and-reset like the other per-isolate flags, so a hot reload re-entering `createServer` does not inherit the previous index. Emitted for every app rather than behind the consumers gate — which isolate this is, is a general fact about the isolate, and messaging is only its first consumer.
- Add `revali services`, which lists every Revali service in a repository — a package with a `routes/` directory that depends on the framework. The dependency check matters: `routes/` alone is a common enough directory name that a frontend router or a docs folder would otherwise be reported as a service. `--paths` prints one path per line for scripting.
- Add `revali compose`, generating a `docker-compose.yaml` for every service found. `revali_docker` produces a Dockerfile per service, which is enough to ship one and not enough to *run the system* — and starting five services by hand is the point at which people stop running the whole thing locally and start testing one service against staging, which hides exactly the mismatches that splitting into services creates. Ports are assigned sequentially from `--base-port` and passed as `PORT`, which `AppConfig.fromEnv` reads. Services that share a package name — several examples can legitimately be called `hello` — are keyed by path instead, because a duplicate compose key does not error: the later entry silently replaces the earlier one and a service vanishes from the file meant to describe it. A service with no Dockerfile yet is emitted with a comment saying so rather than omitted, since a silent absence is harder to notice than a build that fails and explains why.
- Add `revali up`, which runs every service in the repository at once. Five services is otherwise five `revali dev` processes in five terminals, which is the point at which people stop running the whole system locally and start developing one service against staging or mocks — and a system you cannot run is one you cannot trust to work deployed. Each service gets a port assigned from `--base-port` and passed as `PORT`, output is merged with a stable colour and an aligned per-service prefix, and `--only` runs a subset by name or path (an unknown name is refused rather than silently ignored, since a typo would otherwise look like a service that starts and does nothing). `Ctrl-C` sends `SIGTERM` to every child, so each drains through the graceful-shutdown path rather than being killed. A service that fails to start is reported and the rest carry on — the usual cause is a compile error the developer is about to fix, and losing the whole fleet for it makes the loop worse.
- `revali up` draws a terminal UI when it has a terminal to draw in: a roster of services showing the port each was assigned and its live state, a log pane for whichever service is focused, and `↑↓`, `1`-`9` or a click to move between them. The flat prefixed stream it replaces had three faults, only one of them cosmetic. A spinner cannot render in a shared stream **at all** — a prefix has to go in front of every line, which makes redrawing one in place impossible, so every frame of a child's `⠋ Retrieving…` became a permanent line until they were dropped instead; a pane owns its region, so those frames animate again rather than being thrown away. There was no way to address **one** service. And a service's state was something you inferred from scrollback: a row now reads `starting`, `generating`, `serving`, `needs fix`, `crashed` or `stopped`, derived from what the child itself prints rather than from a status protocol between the two, which would be one more thing to keep in step with the thing it describes. A service that dies keeps its row, with the reason in its own pane, while the rest of the fleet keeps running — dropping it would read as everything going down, and a crash is nearly always a compile error the developer is about to fix, so the row is where they look to see it come back.
- The roster shows three rows at a time however big the fleet is, windowed on the focused service and captioned `▲▼ showing 4-6 of 9 services`. The fleet `revali up` exists for is the case an unbounded roster broke: ten services left the log pane four lines on an 80x24 terminal, and the pane is the reason the command exists — the roster is only how you choose what it shows. Only the view is capped; selection is still over the whole fleet, so `↑↓` and `1`-`9` reach a service that is scrolled out of sight and bring it into view. The window is derived from the focused row on every build rather than tracked as scroll state, which makes "the focused row is visible" an invariant of the render instead of a post-condition of a scroll that has to have happened — nocterm's own `ListView` and `AutoScrollController` do not hold it, opening a nine-service fleet on `golf, hotel, india` with the marker on `alpha`, off-screen, before a key is pressed. The caption is a range rather than a scrollbar or bare `▲`/`▼`, because this list is selected by number and the reader whose `1`-`9` press is about to jump somewhere needs to know which positions are under their eyes: arrows alone leave "3 of 4" and "3 of 40" looking identical, and a one-column scrollbar beside three rows is close to invisible.
- A service can be down in two ways, and the row now says which. `revali dev` outlives its own server on purpose — a port collision leaves the wrapper up so the developer can free the port and press `r` — so nothing exits, `crashed` cannot catch it, and the row went on reading `generating` for as long as the service stayed broken, with the `Starting server` progress animating over the top of the error and re-asserting `generating` on every frame. `ServiceState.failed` catches it, read off the child's own `Failed to bind server:`, `Server process terminated unexpectedly with exit code:` and `Dev server is still running` as substrings, since all three arrive coloured, prefixed, or replayed two spaces in. In the row it reads `needs fix` rather than `failed`: beside `crashed` the word "failed" says nothing anyone can act on, and the whole point of the state is that the two are not interchangeable — `needs fix` is recoverable with `r`, where `crashed` and `stopped` mean the process is gone. It is as loud as `crashed` because it costs the same to ignore while announcing itself far less: a crash announces itself, a service sitting on a taken port does not, and it is the one thing on the screen that will not resolve on its own. `Serving at ` is the way out, so a reload that comes back up reaches `serving`; an actual exit goes on to `crashed`.
- The panes have colour, and control codes are no longer painted into them as characters. The child was never sending colour to begin with: `revali up` spawns each service with `Process.start`, so its stdout is a **pipe**, and `mason_logger` colours through `ansiOutputEnabled`, which is false on a pipe — `lightGreen.wrap` was a no-op and the child emitted plain text, so there was nothing for a pane to render however well it rendered. Both ends are ours, so this needs no PTY: `up` sets `REVALI_FORCE_ANSI` on a child it is drawing a pane for, and the child runs under `overrideAnsiOutput` when it sees it. The flat path deliberately does not set it — that pipe is what CI reads, and escape sequences in a build log are a regression, so the parent decides and the child only obeys. Both of `revali dev`'s entrypoints make the call, because `revali dev` is two programs: the CLI compiles a constructs entrypoint and starts it with `Isolate.spawnUri`, and the status board, the `Press: r reload…` legend, the route table and every progress line are printed from over there, where a zone value cannot follow. An environment variable can, which is why the handshake is one. The other half was broken before any of this: `revali dev` clears its screen with a raw `ESC[2J ESC[0;0H` and `mason_logger` brackets every spinner frame with `ESC[?7l` / `ESC[2K` whether colour is on or not, and the pane painted those bytes as text — which is why `[2J[0;0H` was on screen. It parses SGR into styled spans now and drops every sequence that is not colour, and the child's own choices are kept: `mason_logger` already says which part of a line is the result and which is the elapsed time, and re-deciding here would flatten the line back to one colour.
- `revali dev`'s progress spinner is driven from a **sidecar isolate**, so it keeps turning through generation. `mason_logger`'s `Progress` animates with a `Timer.periodic` on the isolate that created it, and generation saturates that isolate — `RoutesHandler.parse` resolves every unit through the analyzer synchronously between awaits — so the timer never fired and the line stopped on whatever frame it last drew. The work was progressing; the only thing that had stalled was the thing telling the user so. The sidecar does nothing but paint, so it paints whatever main is stuck in. Its non-animated fallback reproduces `mason_logger`'s output byte for byte rather than printing a plain line, which `revali up` depends on: a row reads `generating` because a braille glyph sits at the head of an unterminated line, and a plain `Generating server code...` would leave every row stuck on `starting`. Whether to animate and whether to emit colour are kept as separate questions — a pane redraws frames in place whether or not they are coloured — and CI is neither, so nothing moves there.
- The TUI is not mandatory and it is not available everywhere. Without a terminal — CI, a pipe — `revali up` produces the flat prefixed stream exactly as before, which is the whole of what a pipeline should get. Raw mode is probed rather than assumed, because a pseudo-TTY can report a terminal and then refuse it, and that refusal is swallowed a layer down: the alternative is a screen that is drawn and cannot read a key, discovered by whoever is sitting in front of it.
- `revali up` forwards `r` / `c` / `q` to the **focused** service, and the shifted `R` / `C` / `Q` to every service at once. Reloading the one service being worked on should not restart the other four as collateral, which is the half a broadcast cannot express. The channel underneath did not change, which is why this was a small change to make: the keys could not simply be piped through, because a child's stdin is a pipe rather than a terminal, so `revali dev` inside it takes its headless path and never reads keystrokes — the keys did nothing, while file-watching reload kept working and made reload look fine. The parent writes each service's `.revali_cmd`, which `revali dev` already watches when it has no TTY, so this reuses that channel rather than adding a second one. One file per service in its own directory: a single shared file would be read and truncated by whichever service noticed first. What the TUI changes is who is addressed, not the mechanism. `Q` also stops the fleet, so a child wedged badly enough to ignore its command file cannot leave `revali up` waiting forever; both it and `Ctrl-C` hand the screen over to the shutdown view below for as long as the children take to drain, and bring it down once they are gone, restoring the terminal rather than leaving it in raw mode. A second `Ctrl-C` is the way out when one of them does not go.
- `s` starts a service whose process is gone, which is the half `r` cannot do. Reload travels by writing `.revali_cmd`, and that works only while the `revali dev` wrapper is alive to be watching it; once the wrapper itself is gone the key writes into the void — and the legend went on advertising it, which is how a developer concludes a key is broken rather than inapplicable. `s` is a fresh process rather than a message, and it declines in three cases: at a service that is still running, because a second process would take the first one's place and leave it with no handle, so `Ctrl-C` could not reach it and it would sit on the port until killed by hand; at `needs fix`, where the wrapper is alive and `r` is what it wants; and once the fleet is draining, since that would be starting a service into a shutdown. Restarting empties that service's pane, deliberately: the output explaining why it died is worth keeping right up to the moment someone asks for the service back, and the key that asks for it back is the point at which they are done with it — carrying it over would leave a stack trace from the dead process sitting above the boot of the live one. "The fleet is gone" also had to stop being a fact about a fixed set of processes. `Future.wait` iterates its argument once, when it is called, so the exit future a restart appends was never waited on at all, and the screen came down over a service someone had just asked for.
- The footer offers only what can be pressed right now, so a key on screen is a key that works. `r` and `q` need a service whose `.revali_cmd` still reaches something; `s` needs one that is gone; `↑↓` needs a second service to move to. The keys that apply whatever the focused service is doing stay unconditional — the scroll keys, which address the log pane rather than the process and work at a corpse as well as at a live server, plus `c`, the fleet-wide `R`/`C`/`Q`, and `^C`, especially `^C`, since it is the way out. An inapplicable hint is **omitted rather than dimmed**. This line went the other way first, on the reasoning that a legend whose items move under the reader's eye is harder to use than a static one; that is overruled, because dim is not a state most readers can distinguish from "available" at a glance in a terminal whose palette they chose themselves, so a dim `r reload` beside a bright `s start` went on reading as an offer. Advertising a key that does nothing is the worse failure of the two, and it is the complaint the line exists to answer. It also fits: the widest reachable state is 68 of the 78 columns the frame leaves on an 80-column terminal, where an earlier version ran off the right border and clipped `^C exit` to `^C e`.
- The focused log pane scrolls — by wheel, and by `j`/`k`, `PageUp`/`PageDown` and `g` for back to live. A pane that only ever showed the tail meant a stack trace that scrolled past was gone until you went looking for the log file. The behaviour that decides whether scrolling is usable at all is the sticking: the pane follows the live end until you scroll off it and then holds still, because `revali up` runs a noisy fleet and a pane that yanked you back to the newest line on every write would be worse than not scrolling at all. Scrolling back down to the last row re-sticks rather than stopping one short, since someone who scrolls to the newest line has said they want the newest line. A pane that has stopped following says so on its last row — `↓ 42 more`, and where the way back is — because a silently frozen pane and a hung service look identical from the outside, and the number is the difference between being one line from the end and four hundred. The position lives on the session rather than on the screen, so each service keeps its own and switching away and back lands where you left it. The keys are in the footer because nothing on screen implies a pane can be scrolled until it has been; the wheel is not, because it needs no discovering.
- A child clearing its screen is no longer taken as a request to destroy the history in its pane. `revali dev` writes `ESC[2J` on a reload, on every status board and on `c`, and all three are the same two bytes, so the pane cannot tell them apart by looking — and obeying it cost a developer the one thing they needed: a service showing `needs fix`, reloaded with `r`, lost the bind error that explained the row to the reload's own first act. A child's clear now settles a `── redraw ──` rule and the lines stay. Scrollback is what settles that argument: keeping them is not hoarding them off-screen, it is leaving them where `k` and `PageUp` reach. `c` still empties a pane, and the parent is the one side that can tell a clear someone asked for from a redraw nobody did, because `c` is a keystroke it handles — so it empties on this side before forwarding anything, which also means it does something visible at a service that will never answer. That leaves exactly three things that empty a pane, kept apart on purpose: the child's own `ESC[2J` (a rule, history kept), `c` (the shown lines go, each stream's half-written tail stays), and `s` on a dead service (everything goes).
- Roster rows, URLs and `GET` route paths are clickable. A row lands exactly where `↑↓` and `1`-`9` land, so a click cannot drift from a keypress. A route path opens the service's announced base plus that path, and the base is read off the child's own `Serving at http://0.0.0.0:8080/api` line rather than rebuilt from the assigned port, because that line is the only place the app **prefix** appears — `revali up` hands out the port and has no idea the app mounts itself under `/api`, and a base missing it sends every route click to a 404. A wildcard bind address is rewritten to `localhost` on the way out and left exactly as written on screen: `0.0.0.0` is the truth about what the service bound and a lie to a browser. Only `GET` rows, because a browser navigation is a GET whatever the row says — a clickable `POST` would offer to do the thing the line describes and then do something else to the same path — and a `:param` path is a template rather than an address. A path clicked before its service has announced anything opens nothing rather than a guess. The click resolves against what is **rendered** rather than against an index into the buffer: each clickable run is its own widget and nocterm hit-tests by position, so scrolled up, cleared, or with a `── redraw ──` rule part way through the buffer, there is no index to be off by. A link's only mark is an underline — a cell attribute, so it costs no columns, where a `[…]` or a trailing icon would shift every route path in the table sideways from the one above it.
- The screen says what it is doing while the fleet drains. `Ctrl-C` sends every child a SIGTERM and each drains through its own graceful path, which takes as long as that service's in-flight work takes — seconds, on a fleet with real drain delays. For the whole of it the running screen went on advertising `r`, `c` and `q` while they did nothing, over a log pane that had stopped moving and rows that changed too slowly to read as progress, and there is nothing about that a developer can tell apart from a hang. So it is replaced rather than annotated, since every part of it had stopped being true: a sentence saying what is happening, one row per service whose state keeps moving as it actually goes down, and the `^C again to stop waiting` escape hatch — which has to be on the screen that makes you want it, because a child that ignores SIGTERM never exits. Only a service genuinely on its way down reads as `draining`: a `crashed` one exited before the signal was ever sent, and a `needs fix` one has had no server since it could not take its port, so calling either "draining" would claim `revali up` is waiting on something it is not, and would bury the compile error that is usually the reason for quitting. `Q` gets the same screen, since it is the same drain to sit through; unshifted `q` is untouched and the fleet carries on. The non-TTY path has no screen to replace and still gets the plain prefixed stream and its `Stopping N service(s)...` line.

### Fixes

- `revali build` regenerates constructs. It ran only the **build** phase, so the generated client — and every other non-build construct — was left at whatever `revali dev` last wrote, and a build in a clean checkout produced none at all. The consequence worth naming is not the stale file: a CI-shaped `build` could not reproduce a client-generation defect **of any kind**, because the artifact under test was never produced. That is how `revali_client_gen`'s `@Query()` collapse reached a published release and was found by a human noticing a parameter had gone missing. `build` now runs both phases, constructs first — the order is load-bearing, since the build phase compiles the `server/server.dart` that the constructs phase writes.
- `--type` no longer defaults to a phase, and is no longer hidden. Defaulting to `build` is what skipped the constructs, and hiding it meant the value that sounded like a fix — `--type buildAndConstructs`, which did not work either — was undiscoverable. Omitting it now means both phases. Passing it still selects exactly one, which has to keep working: `revali_docker` writes `--type constructs` into the Dockerfiles it generates, and those live in users' repositories long after they are emitted. It is visible for that same reason — it appears in a file people read. Reported from two consuming repositories in the same afternoon.

## 3.2.0 | 08.13.26

### Features

- Fix generated code failing to compile for a parameter whose wire form is a string but whose type is a custom class — `StringUser.fromJson(String)`, an enum with `fromJson`. The coercion arms for numbers and booleans returned `data.toString()` while the others returned the custom type, so the switch inferred `Object` and the file did not compile. They now apply the same `fromJson`.
- Controllers inherit endpoints. Annotated methods on a superclass or mixin now become routes on the controller that extends it, instead of being silently dropped with no error. An override with its own annotation replaces the inherited route; an override *without* one keeps the inherited route and dispatches to the override at runtime. Inheriting endpoints from a **generic** base is rejected with an explanatory error rather than generating wrong bindings, since the inherited signatures still refer to the type parameters.
- The generated server passes its DI container to the `Router`, so every request gets its own scope and `registerRequestScoped` dependencies work end to end.
- The generated server now shuts down gracefully. On `SIGTERM`/`SIGINT` it stops accepting connections, waits for in-flight requests up to `AppConfig.shutdownTimeout`, runs `AppConfig.onServerStopped`, and exits `0` — so a deploy or scale-down no longer truncates responses that were mid-flight. Handlers are installed only for a server Revali created itself, never when one is provided (as `TestServer` does) and never in worker isolates.
- Add a `build:` section to `revali.yaml`. Its presence tells `revali build` to compile the server via `dart compile exe --target-os --target-arch`, cross-compiling to Linux from any host OS. Compiled executables are exposed to build-type constructs (e.g. `revali_docker`) via `RevaliBuildContext.compiledExecutables`, so they can package what was already compiled instead of compiling anything themselves. Supports `strip_debug_info` to split AOT debug info out of the executable for a smaller binary.

## 3.1.0 | 08.05.26

### Features

- Add a `build:` section to `revali.yaml`. Its presence tells `revali build` to compile the server via `dart compile exe --target-os --target-arch`, cross-compiling to Linux from any host OS. Compiled executables are exposed to build-type constructs (e.g. `revali_docker`) via `RevaliBuildContext.compiledExecutables`, so they can package what was already compiled instead of compiling anything themselves. Supports `strip_debug_info` to split AOT debug info out of the executable for a smaller binary.

## 3.0.0 | 08.04.26

### Breaking Changes

- Server code generation is now built into `revali` — `revali_server` no longer exists as a separate package. Remove it from your `dev_dependencies`; `revali` alone is sufficient.
- `revali create` scaffolds in-process; it no longer shells out to `revali_server create`.
- Depend on `revali_router: ^4.0.0`, `revali_annotations: ^3.0.0`, and `revali_core: ^2.0.0`.
- The `revali.yaml` key for customizing `create` scaffold paths is now `server:` (was `revali_server:`).

### Features

- Add `routes`, `doctor`, and `create` CLI commands for route inspection, diagnostics, and scaffolding.
- Add `--inspect` on `dev` to record recent requests to `.revali/inspect/requests.jsonl`.
- Add headless `.revali_cmd` channel for reload/recovery without a TTY.
- Emit `.revali/server/routes.json` route manifest on generate.
- Spawn shared `HttpServer` worker isolates when `AppConfig.workers` > 1.
- Wire request-inspect hooks into generated server startup.

### Enhancements

- Share construct kernels across packages and persist the analyzer byte store for faster rebuilds.
- Harden hot reload: atomic promote, kernel invalidation on package changes, analyzer overlay for new routes, and rapid-churn recovery.
- Discover `app.dart` and warn when falling back to the default app.
- Exclude `bin` / `test` / `tool` from hot-reload watches.
- Stabilize the `revali dev` status board: `[READY]`/`[RELOAD]` tags, preserve Serving at after clear/reload, and respect loud mode on `c`.
- Pass `AppConfig.backlog` into server bind.
- Serve with a single route `Find` on the hot path.

### Fixes

- Tolerate stdin mode errors on non-TTY terminals.
- Pick up local path-dependency edits during `revali dev` by notifying every analysis context (app context no longer keeps a stale copy).
- Return HTTP 400 for missing/invalid parameter bindings (`MissingArgumentException`).
- Bind `Set` and coerced query parameters correctly (including coerced values to `String` params).

## 2.2.0 | 06.17.26

### Features

- Resolve package dependencies via `package_config` for more reliable workspace resolution.

### Enhancements

- Normalize file paths on Windows so analyzer, construct runner, and VM service handlers work cross-platform.
- Handle uncaught errors during dev server startup and hot reload with stack traces.
- Improve workspace root detection and failure diagnostics.

## 2.1.1 | 05.21.26

### Enhancements

- Improve logging when conflicting routes are detected.
- Preserve the "Serving at" message in the console after hot reload and screen clear.

### Enhancements

- Generate into `.revali.staging` and only replace `.revali` after generation succeeds, so an interrupted rebuild no longer removes `revali_client/pubspec.yaml` and breaks workspace `dart pub get`.

## 2.1.0 | 05.18.26

### Chore

- Bump `analyzer` / `dart_style` and migrate to the analyzer 10 element APIs.

## 2.0.9 | 03.05.26

### Features

- Add `hot_reload.exclude` in `revali.yaml` to ignore custom paths on reload (paths can be absolute or relative to revali.yaml)

### Enhancements

- Preserve terminal content when running with `--loud` (verbose) mode instead of clearing screen on reload

## 2.0.8 | 03.03.26

### Enhancements

- Add retry logic to analyzer updates to prevent inconsistent analysis errors

## 2.0.7 | 03.02.26

### Enhancements

- Added attempt recover when file watcher throws an error
- Added queueing of analyzer updates to prevent race-y updates

### Enhancements

- Improved error logging for file watcher errors (now includes stack trace)
- More informative shutdown and signal logging

## 2.0.6 | 02.16.26

### Fixes

- Handle `deleteFile` errors gracefully when path doesn't exist in memory provider
- Buffer server stdout/stderr for reliable diagnostics when process exits unexpectedly
- Log diagnostics before server crashes

### Enhancements

- Improved error logging for file watcher errors (now includes stack trace)
- More informative shutdown and signal logging

## 2.0.5 | 02.04.26

### Fixes

- Fixed stale dependency files in virtual analysis context when local path dependencies change
- Added file watching for dependency directories to detect changes in monorepo setups
- Fixed `lastModified` filtering bug that prevented efficient dependency file refresh

## 2.0.4 | 01.28.26

### Fixes

- Issue where stdin would error when trying to listen for input during hot reload
- Issue where if exception were thrown on the first server creation, revali would exit
- Prints error messages when exceptions are thrown during server creation

## 2.0.3 | 12.18.25

### Fixes

- Issue where parsing dart define a base64 encoded string would fail

## 2.0.2 | 11.22.25

### Chore

- Sync package versions

## 2.0.2-dev | 10.15.25

### Fix

- Dependencies

## 2.0.0-dev | 09.19.25

### Breaking Changes

- Update `analyzer` dependency to `^8.0.0`

## 1.5.0 | 08.16.25

### Features

- Add `c` keyboard action to clear console during `dart run revali dev`

### Enhancements

- Significantly reduce hot reload time
- Print out error message during hot reload when compilation fails, without requiring a full restart

## 1.4.2 | 04.15.25

### Enhancements

- Add support for extracting `InstanceType` from `@Controller`
- Get next available port for `dart-vm-service-port` instead of using a set port
- Support `kDebugMode`, `kProfileMode`, and `kReleaseMode`
  - Corresponds to `--debug`, `--profile`, and `--release` flags

### Features

- Support passing arguments to `dart run revali dev`
  - Example: `dart run revali dev -- --some-flag`

## 1.4.1 | 04.07.25

### Enhancements

- Print `GET (SSE)` when using `@SSE` methods

## 1.4.0 | 03.24.25

### Enhancements

- Improve and clean up `MetaType` resolution
- Safely retrieve constructor from the controller

### Features

- Add (hidden) `--generate-only` flag to `dev` command
- Support for `workspace`s in `pubspec.yaml`

### Fixes

- Add `--profile` flag to `dev` (runner) command

## 1.3.3 | 02.08.25

### Chores

- Upgrade dependencies
- Fix breaking changes

## 1.3.2 | 02.08.25

### Chores

- Upgrade dependencies

## 1.3.1 | 02.08.25

### Chores

- Upgrade dependencies

## 1.3.0 | 01.27.25

### Features

- Create new class for `Type`s on method parameters
  - Add property `hasFromJsonConstructor`

### Enhancements

- Clean up import path retrieval

## 1.2.0 | 12.11.24

### Features

- Add abbreviation for dart define (`-D`) to match dart's CLI for `build` and `dev` commands
- Safely close the server when `CTRL+C` is pressed
- Watch `components` directory within the `lib` directory for changes to reload the server

### Enhancements

- Lower min bound for Dart SDK to `3.4.0`
- Improve error handling and logs for server startup

## 1.1.1 | 11.20.24

### Chores

- Upgrade dependencies
- Clean up lint warnings

## 1.1.0 | 11.18.24

### Features

- Support `SSE` methods

### Chores

- Upgrade dependencies

## 1.0.0 | 11.14.24

- Initial Release
