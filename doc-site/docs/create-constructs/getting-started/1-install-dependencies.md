# Install Dependencies

There are a few dependencies that you'll need to install in order to create a new construct. These dependencies are required to build and run your construct.

## Installation

### Command Line

```bash
dart pub add revali_annotations revali_construct revali_core
```

### pubspec.yaml

```yaml
dependencies:
    revali_annotations: <latest-version>
    revali_construct: <latest-version>
    revali_core: <latest-version>
```

:::tip
Make sure to replace `<latest-version>` with the latest version of the package.

- [revali_annotations][revali-annotations]
- [revali_construct][revali-construct]
- [revali_core][revali-core]

:::

## Packages

### revali_annotations

This package contains the annotations that are used to define controllers, apps, and routes. Such as `@Controller`, `@App`, and `@Get`.

### revali_construct

This package contains the classes and utilities to help you create and manage your constructs. Revali analyzes the project's dart files and prepares them into consumable classes for you to generate your constructs.

### revali_core

This package contains classes that are used as both annotations and utilities during runtime. Such as `DI` and `AppConfig`

[revali-annotations]: https://pub.dev/packages/revali_annotations
[revali-construct]: https://pub.dev/packages/revali_construct
[revali-core]: https://pub.dev/packages/revali_core
