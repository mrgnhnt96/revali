---
sidebar_position: 0
description: Learn how to install Revali and its constructs
---

# Installation

## Depend on Revali

First, you will need to add `revali` to your project's dev dependencies. Open your `pubspec.yaml` and include the following line in the `dev_dependencies` section:

Run the following command to add `revali` to your project.

```bash
dart pub add revali --dev
```

Or manually add the following to your `pubspec.yaml` file.

```yaml title="pubspec.yaml"
dev_dependencies:
  revali: <latest-version>
```

:::note
Make sure to replace `<latest-version>` with the latest version of [Revali][revali-pub].
:::

## Depend on Constructs

Next, you will need to add a construct to your project's dependencies. Constructs are packages that contain the code generation logic for Revali. You can find a list of available constructs on [pub.dev][pub-constructs].

There are a few constructs that are commonly used with Revali:

- [revali_server][revali-server-pub]: A construct that generates server-side code for Revali applications.

To install the constructs, add them to your `dev_dependencies` in your `pubspec.yaml`:

```bash
dart pub add revali_server --dev
```

Or manually add the following to your `pubspec.yaml` file.

```yaml title="pubspec.yaml"
dev_dependencies:
  revali_server: <latest-version>
```

:::note
Make sure to replace `<latest-version>` with the latest version of [Revali Server][revali-server-pub].
:::

[revali-pub]: https://pub.dev/packages/revali
[revali-server-pub]: https://pub.dev/packages/revali_server
[pub-constructs]: https://pub.dev/packages?q=dependency%3Arevali_construct
