# CHANGELOG

## 1.3.0 | 08.15.26

### Fixes

- Raise the `revali_construct` floor to `^3.0.0`. Nothing in this package changed; it is re-released so the published set still resolves. `revali_construct` is a new major this round, and a dependent's constraint is only rewritten if that dependent is itself part of the release — leaving 1.2.0 behind on `^2.4.0` would make it unresolvable alongside it.

## 1.2.0 | 08.13.26

### Fixes

- Emit the spec deterministically. Paths, the operations within each path, and component schemas were written in whatever order the filesystem walk discovered controllers, so the same project produced `/complex` first on macOS and `/users` first on Linux. A spec that reorders itself per platform cannot be diffed, committed, or compared against a golden. All three are now sorted.

- Depend on `revali_annotations ^3.0.0` (previously `revali_router_annotations ^2.2.0`). The router/annotations consolidation refactor already dropped this dependency in source, but the package version was never bumped, so pub.dev's 1.0.0 stayed pinned to `revali_router_annotations`, which pulls in `revali_router_core ^2.3.0` -> `revali_core ^1.6.0`, conflicting with `revali ^3.0.0`'s `revali_core ^2.0.0` requirement.

## 1.1.0 | 08.07.26

### Fix

- Depend on `revali_annotations ^3.0.0` (previously `revali_router_annotations ^2.2.0`). The router/annotations consolidation refactor already dropped this dependency in source, but the package version was never bumped, so pub.dev's 1.0.0 stayed pinned to `revali_router_annotations`, which pulls in `revali_router_core ^2.3.0` -> `revali_core ^1.6.0`, conflicting with `revali ^3.0.0`'s `revali_core ^2.0.0` requirement.

## 1.0.0 | 06.17.26

### Features

- Initial release: generate OpenAPI 3.0.3 specs from Revali routes, parameters, and return types.
- Write both `swagger.yaml` and `swagger.json` on every run.
- Automatic JSON Schema for Dart primitives, collections, records, enums, and user-defined classes.
- Optional annotation overrides for summaries, tags, responses, and custom schema types.
