---
title: Structure
description: Learn about the structure of the generated code
sidebar_position: 1
---

# Structure of the Generated Client Code

The Revali Client generates well-structured, idiomatic Dart code designed to interact with your Revali server. All generated code adheres to SOLID principles, promoting separation of concerns, testability, and long-term maintainability.

## Overview

At the heart of the client lies the `Server` class — the primary entry point for accessing backend functionality. For each server-side controller, a corresponding _data source_ is generated on the client side. This includes:

- An **interface** that defines the available methods and types
- An **implementation** that handles request construction, network calls, and response parsing

---

### Project Structure

Generated files are stored under the `.revali/revali_client/` directory and follow a clean modular structure:

```text
.revali/
└── revali_client/
    ├── lib/
    │   ├── client.dart           # all generated implementations
    │   ├── interfaces.dart       # all generated interfaces
    │   └── src/
    │       ├── server.dart       # The main Server class
    │       ├── impls/
    │       │   └── user_data_source_impl.dart
    │       └── interfaces/
    │           └── user_data_source.dart
    └── pubspec.yaml
```

You only need to import `client.dart` and `interfaces.dart` to use the generated code.

---

### Server Class

The `Server` class exposes a field for each data source, one per controller. Each field:

- Is typed using the interface (e.g., `UserDataSource`)
- Returns the implementation (e.g., `UserDataSourceImpl`)

This design inverts the dependency flow and enables client code to depend on abstractions — not implementations.

#### Example

```dart
import 'package:revali_client/client.dart';
import 'package:revali_client/interfaces.dart';

final server = Server();

// Type is the interface; implementation is hidden behind the abstraction
UserDataSource user = server.user;
```

This structure encourages testability and flexibility. For example, during testing, you can substitute the real `UserDataSource` implementation with a mock that implements the same interface.

---

### Interfaces and Implementations

For every controller:

- An interface is generated in `src/interfaces/`, defining method signatures
- A concrete implementation is generated in `src/impls/`, which:
  - Constructs the correct HTTP request for each method
  - Maps parameters to the expected format
  - Response deserialization

This split encourages mocking, testing, and adherence to clean architecture.
