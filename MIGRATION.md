# Migrating to revali 3.0.0 / revali_router 4.0.0 / revali_core 2.0.0 / revali_annotations 3.0.0

This release consolidates several packages that existed mostly for internal architectural
reasons, not because anyone needed to swap them out. Three packages are retired, one new
one is added, and four existing packages take a major-version bump. Nothing about how you
*write* a Revali app changes — routes, controllers, annotations, and the generated server
all work the same way. What changes is which package a given type lives in, and how the
server gets generated in the first place.

## Why

- Route-declaring annotations were split across `revali_annotations` and
  `revali_router_annotations` for no real benefit — writing one controller method needed
  imports from both.
- `revali_router_core` and `revali_router` were split so a would-be alternate router
  implementation could reuse the contracts. Nobody ever built one.
- `revali_server` was a separately-installed, externally-discovered "server construct"
  plugin, but exactly one has ever existed, every project needs it, and the plugin
  architecture only added a devDependency + kernel-discovery indirection with no payoff.

Server generation is now built into `revali` itself. The genuinely pluggable constructs
(`revali_swagger`, `revali_client_gen`, `revali_docker`, and anything you author yourself)
are untouched and still work exactly as before.

## Package changes at a glance

| Package | Status | What happened |
|---|---|---|
| `revali_router_core` | **Removed** | Merged into `revali_core` 2.0.0 |
| `revali_router_annotations` | **Removed** | Merged into `revali_annotations` 3.0.0 |
| `revali_server` | **Removed** | Merged into `revali` 3.0.0 |
| `revali_docker` | **New** (1.0.0) | Extracted out of `revali_server` — it was bundled there, now it's its own optional construct |
| `revali` | 2.x → **3.0.0** | Absorbed `revali_server`; server generation is now built in |
| `revali_router` | 3.x → **4.0.0** | Absorbed `revali_router_core`; re-exports from `revali_core`/`revali_annotations` now |
| `revali_core` | 1.x → **2.0.0** | Absorbed `revali_router_core`'s runtime contracts (Request/Response/Guard/Middleware/etc.) plus `AllowOrigins`/`PreventHeaders`/`ExpectHeaders` (moved from `revali_annotations`, still re-exported there) |
| `revali_annotations` | 2.x → **3.0.0** | Absorbed `revali_router_annotations`'s annotations (`@Query`, `@Guards`, `@Middlewares`, `@Cookie`, `Bind`, `Pipe`, `RequestHeaders`/`ResponseHeaders`, etc.) |
| `revali_client`, `revali_client_gen`, `revali_swagger`, `revali_swagger_annotations` | Unchanged | No API changes; only their own internal dependency constraints moved |

12 published packages → 10.

## Step-by-step migration

### 1. Update your `pubspec.yaml`

**Remove** `revali_server` from `dev_dependencies` entirely — there is nothing to replace
it with, `revali` covers it.

**If you use Docker generation** (you had a `.revali/build/Dockerfile` being generated),
add the new construct explicitly — it used to ride along with `revali_server`, now it's
opt-in on its own:

```yaml
dev_dependencies:
  revali_docker: ^1.0.0
```

**Bump versions** on whatever you already depend on:

```yaml
dependencies:
  revali_router: ^4.0.0

dev_dependencies:
  revali: ^3.0.0
```

`revali_client`, `revali_client_gen`, and `revali_swagger` don't need version changes
unless you were already behind.

### 2. Fix direct imports of the removed packages

If your own code imports `revali_router_core` or `revali_router_annotations` directly
(most apps only ever import `package:revali_router/revali_router.dart`, which re-exports
everything — check for direct imports specifically):

```dart
// Before
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_router_core/trusted_proxy/trusted_proxy.dart';
import 'package:revali_router_core/method_mutations/headers/headers.dart';

// After
import 'package:revali_core/revali_core.dart';
import 'package:revali_core/trusted_proxy/trusted_proxy.dart';
import 'package:revali_core/method_mutations/headers/headers.dart';
```

`revali_router_annotations` imports become `revali_annotations` the same way. If you
depend on either package directly in a `pubspec.yaml` (not just import it), swap the
dependency line for `revali_core`/`revali_annotations` at the versions above.

### 3. Rename the `revali.yaml` server-options key, if you use it

If you pass CLI scaffold-path options for `create` via `revali.yaml`, the top-level key
changed from `revali_server` to `server`:

```yaml
# Before
revali_server:
  create_path:
    controller: ["routes", "controllers"]

# After
server:
  create_path:
    controller: ["routes", "controllers"]
```

If you don't customize scaffold paths, there's nothing here to change.

### 4. Remove any `revali_server` construct entry from `revali.yaml`

If you had:

```yaml
constructs:
  - name: revali_server
    package: revali_server
    options:
      ...
```

Server generation no longer needs to be declared — it's always on. You can drop the
`package:` line (it's now ignored, `revali` provides the construct internally) or remove
the entry entirely; either an `enabled: true`/absent entry works the same. `options:` (if
you had any) still gets picked up by name.

### 5. `revali create` no longer shells out

If any tooling of yours specifically invoked `dart run revali_server create ...`, switch it
to `dart run revali create ...` — same subcommands (`controller`, `app`,
`lifecycle-component`, `pipe`, `observer`), now run in-process instead of as a subprocess.

### 6. Custom constructs: the "author your own server construct" path is gone

If you had (or were experimenting with) a custom `is_server: true` construct in your own
`construct.yaml`, that's no longer supported — `revali` always contributes its own server
construct, so registering a second one now hits the existing "only one Server Construct is
allowed per project" error. Generic (`Construct`) and build (`BuildConstruct`) constructs
are unaffected; you can still author those exactly as before.

### 7. Verify

```bash
dart pub get
dart run revali dev --generate-only --recompile   # regenerate the server from scratch
dart analyze
dart test
```

If Docker generation is part of your pipeline, confirm the exact command your Dockerfile
invokes still works: `dart run revali build --release --type constructs --recompile`.

## Deprecation status

`revali_router_core`, `revali_router_annotations`, and `revali_server` are being marked
discontinued on pub.dev, pointing at their replacements. They will not receive further
releases.

## Worked example

This migration was verified against a real downstream consumer (an internal monorepo with
a Revali-generated server, a shared schema library, and a stress-test harness). The concrete
changes needed there:

- `pubspec.yaml`: `revali_router: ^3.4.0 → ^4.0.0`, `revali: ^2.2.0 → ^3.0.0`, removed
  `revali_server: ^2.4.1`, added `revali_docker: ^1.0.0` (Docker generation was in use).
- One handler file directly imported `package:revali_router_core/revali_router_core.dart`
  → changed to `package:revali_core/revali_core.dart`.
- A shared schema library depended on `revali_router_core` directly in `dependencies:` →
  changed to `revali_core`, plus its own `revali_router` dev dependency bumped to `^4.0.0`.
- A test file imported two specific `revali_router_core` files directly (`trusted_proxy`,
  `method_mutations/headers/headers.dart`) → same files, `revali_core` prefix.
- A stress-test harness generated a `pubspec_overrides.yaml` with explicit path overrides
  for `revali_router_annotations`, `revali_router_core`, and `revali_server` → those three
  entries were removed (the paths no longer exist); its existing `revali_core`/
  `revali_annotations`/`revali_router`/`revali` entries needed no change.
- Its `revali.yaml` had no `constructs:` section and no `revali_server:` key, so nothing to
  change there — a reminder that most of this migration is a non-event unless you were
  depending on the removed packages directly.
