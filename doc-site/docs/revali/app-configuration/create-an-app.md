---
sidebar_position: 1
description: Create an app and configure host & port
---

# Create an App

## Create a New App

To create a new app, create a Dart file within your project's `routes` directory. We'll create one called `my_app.dart`:

```tree
.
├── lib
│   └── <non-revali-files>
└── routes
    └── my_app.dart
```

::::important
The app file name must end in either `_app.dart` or `.app.dart`.
:::note
The app file needs to be within the `routes` directory, but can be nested within subdirectories.
:::
::::

### Define the App

The app file should contain a class that extends `AppConfig` and annotated with the `App` annotation from the `revali_annotations` package.

```dart title="routes/my_app.dart"
import 'package:revali_annotations/revali_annotations.dart';

@App()
class MyApp extends AppConfig {}
```

:::note
Typically, the `revali_annotations` package is imported with the server construct you're using
:::

The `AppConfig`'s constructor requires 2 parameters: `host` and `port`.

```dart title="routes/my_app.dart"
import 'package:revali_annotations/revali_annotations.dart';

@App()
class MyApp extends AppConfig {
    // highlight-next-line
   const MyApp() : super(host: 'localhost', port: 8080);
}
```
