---
title: Getting Started
description: Create a construct package, register it with construct.yaml, add it to a server and run it
---

This walks through a complete generic construct, `route_list`, that writes every route of the server to `.revali/route_list/routes.txt`. You need an existing Revali server project. If you do not have one, see [Installation](/revali/getting-started/installation).

## 1. Create the package

```bash
dart create -t package route_list
cd route_list
dart pub add revali_construct
```

Only `lib/` and `pubspec.yaml` matter. The rest of the template can go. Add `revali_annotations` or `revali_router` as well if your construct needs to match their annotation types.

## 2. Implement the construct

A generic construct extends `Construct` and returns a `RevaliDirectory` of files. `MetaServer` describes the analyzed server: `routes` (controllers, each with `methods`), `apps` and `public` files.

<CodeFile name="route_list/lib/src/route_list_construct.dart">

```dart
import 'package:revali_construct/revali_construct.dart';

class RouteListConstruct extends Construct {
  const RouteListConstruct();

  @override
  RevaliDirectory generate(RevaliContext context, MetaServer server) {
    final lines = [
      for (final route in server.routes)
        for (final method in route.methods)
          '${method.method} /${_join(route.path, method.path)}',
    ];

    return RevaliDirectory(
      files: [
        AnyFile(basename: 'routes', extension: 'txt', content: lines.join('\n')),
      ],
    );
  }

  String _join(String controller, String? method) =>
      [controller, method ?? ''].where((p) => p.isNotEmpty).join('/');
}
```

</CodeFile>

- `AnyFile` takes `basename`, `extension`, `content` (or `bytes` for binary files) and `segments` for subdirectories. `DartFile` and `PartFile` are `AnyFile` subclasses that write `part` / `part of` directives for you.
- A `RevaliDirectory` must contain at least one file.
- `context.mode` (debug, profile or release) and `context.flavor` describe the current run.

## 3. Add the entrypoint

Revali calls a **top-level** function that takes an optional `ConstructOptions` and returns the construct. `options.values` holds the `options:` map from the user's `revali.yaml`.

<CodeFile name="route_list/lib/route_list.dart">

```dart
import 'package:revali_construct/revali_construct.dart';
import 'package:route_list/src/route_list_construct.dart';

Construct routeListConstruct([ConstructOptions? options]) {
  return const RouteListConstruct();
}
```

</CodeFile>

## 4. Register it in `construct.yaml`

`construct.yaml` sits at the package root, next to `pubspec.yaml`. Its presence is what makes the package a construct.

<CodeFile name="route_list/construct.yaml">

```yaml
constructs:
  - name: route_list
    path: route_list.dart
    method: routeListConstruct
```

</CodeFile>

| Key | Type | Default | Meaning |
| --- | --- | --- | --- |
| `name` | `String` | required | Identifies the construct in `revali.yaml` and names its output directory, `.revali/<name>/`. |
| `path` | `String` | required | Entrypoint file, relative to `lib/`. |
| `method` | `String` | required | Top-level function in that file that returns the construct. |
| `is_build` | `bool` | `false` | Makes it a [build construct](/create-constructs/core/build-construct): runs only on `revali build`, writes to `.revali/build/`, and `method` must return a `BuildConstruct`. |
| `opt_in` | `bool` | `false` | Skip the construct until the user sets `enabled: true` for it in `revali.yaml`. |

A package can list several constructs under `constructs:`. Server generation is built into `revali` and cannot be provided by a construct package.

## 5. Add it to a server

Constructs must be **dev dependencies** of the server. Revali ignores packages under `dependencies`.

<CodeFile name="my_server/pubspec.yaml">

```yaml
dev_dependencies:
  route_list:
    path: ../route_list
```

</CodeFile>

The path is relative to the server's `pubspec.yaml`. Run `dart pub get`.

## 6. Run it

From the server project:

```bash
dart run revali dev --recompile
```

```tree
.revali/
├── server/
└── route_list/
    └── routes.txt
```

<CodeFile name=".revali/route_list/routes.txt">

```text
GET /users
POST /users
GET /users/:id
```

</CodeFile>

`--recompile` forces Revali to rebuild its cached copy of your construct. Revali detects most edits by itself, but pass the flag whenever a change to your construct does not show up. See [Construct Lifecycle](/create-constructs/core/construct-lifecycle).

## Reading options

Users configure your construct in their `revali.yaml`:

<CodeFile name="my_server/revali.yaml">

```yaml
constructs:
  - name: route_list
    options:
      file_name: endpoints
```

</CodeFile>

```dart
Construct routeListConstruct([ConstructOptions? options]) {
  final fileName = options?.values['file_name'] as String? ?? 'routes';

  return RouteListConstruct(fileName: fileName); // pass it to the construct
}
```

Document every key you read. The other keys of a `revali.yaml` entry (`enabled`, `package`) are handled by Revali. See [Configuring constructs](/constructs#configuring-constructs).
