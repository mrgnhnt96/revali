---
title: Installation
description: What a Revali project needs, and how to add it.
---

A Revali server is an ordinary Dart package with two dependencies and a
`routes/` directory. There is no project template to clone.

## Requirements

| Requirement | Why |
| --- | --- |
| [Dart SDK](https://dart.dev/get-dart) **3.8** or newer | `revali` declares `sdk: ">=3.8.0 <4.0.0"` |
| `revali` as a **dev** dependency | The CLI and the code generator. Server generation is built in. |
| `revali_router` as a **regular** dependency | The runtime your generated server runs on. It also re-exports every annotation (`@Controller`, `@Get`, `@Body`, …). |
| A `routes/` directory in the package root | Where Revali looks for controllers and apps. |

## Install

In an existing Dart package, or one made with `dart create -t console my_api`:

```bash
dart pub add revali_router
dart pub add --dev revali
```

The result in `pubspec.yaml`:

<CodeFile name="pubspec.yaml">

```yaml
environment:
  sdk: ">=3.8.0 <4.0.0"

dependencies:
  revali_router: ^5.1.0

dev_dependencies:
  revali: ^3.3.0
```

</CodeFile>

Import `package:revali_router/revali_router.dart` in every file that uses
Revali. You never need to depend on `revali_annotations` directly.

## Check the setup

```bash
dart run revali doctor
```

`doctor` reports the SDK version, the constructs it found, and whether
generated output is stale. See [`revali doctor`](/revali/cli/doctor).

## Optional constructs

Server generation needs nothing beyond the two packages above. Add a construct
only for the extra output you want:

| Construct | Generates | Install |
| --- | --- | --- |
| [revali_client](/constructs/revali_client) | A typed Dart client for your API | [Installation](/constructs/revali_client#installation) |
| [revali_swagger](/constructs/revali_swagger) | An OpenAPI document | [Installation](/constructs/revali_swagger#installation) |
| [revali_docker](/constructs/revali_docker) | A Dockerfile for the server | [Installation](/constructs/revali_docker#installation) |

Next: [Create your first endpoint](/revali/getting-started/create-your-first-endpoint).
