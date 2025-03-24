---
title: Usage
description: Import and use the generated client
sidebar_position: 2
---

# Usage

Since the generated code is a Dart package, you can use it just like any other Dart package.

## Add the Dependency

Add the generated package as a dependency to your project.

```yaml title="pubspec.yaml"
dependencies:
  client:
    path: .revali/revali_client # Relative path to the generated code
```

## Import the Client

Import the client in your Dart file.

```dart
import 'package:client/client.dart';
```

## Use the Client

Use the client to make requests to your server.

```dart
final client = Server();

final user = await client.getUser();
```
