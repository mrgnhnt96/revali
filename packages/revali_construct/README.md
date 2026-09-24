# Revali Construct

The base package for writing [Revali](https://pub.dev/packages/revali) constructs: `Construct`, `BuildConstruct`, the file types (`AnyFile`, `DartFile`, `PartFile`, `RevaliDirectory`, `BuildDirectory`), and the `MetaServer` model of an analyzed server.

## Installation

In your construct package:

```bash
dart pub add revali_construct
```

## Usage

`lib/my_construct.dart`:

```dart
import 'package:revali_construct/revali_construct.dart';

Construct myConstruct([ConstructOptions? options]) => const MyConstruct();

class MyConstruct extends Construct {
  const MyConstruct();

  @override
  RevaliDirectory generate(RevaliContext context, MetaServer server) {
    return RevaliDirectory(
      files: [
        AnyFile(
          basename: 'routes',
          extension: 'txt',
          content: server.routes.map((r) => r.path).join('\n'),
        ),
      ],
    );
  }
}
```

```yaml
# construct.yaml (package root)
constructs:
  - name: my_construct
    path: my_construct.dart
    method: myConstruct
```

## Documentation

[docs.revali.dev/create-constructs](https://docs.revali.dev/create-constructs)
