# Installation

## Depend on Revali

First, you will need to add `revali` to your project's dev dependencies. Open your `pubspec.yaml` and include the following line in the `dev_dependencies` section:

```yaml title="pubspec.yaml"
dev_dependencies:
    revali: <latest version>
```

:::tip
Replace `<latest version>` with the actual latest version found on [pub.dev](https://pub.dev/packages/revali).
:::

## Depend on Constructs

Next, you will need to add a construct to your project's dependencies. Constructs are packages that contain the code generation logic for Revali. You can find a list of available constructs on [pub.dev](https://pub.dev/packages?q=dependency%3Arevali_construct).

There are a few constructs that are commonly used with Revali:

- [revali_server](https://pub.dev/packages/revali_server): A construct that generates server-side code for Revali applications.

To install the constructs, add them to your `dev_dependencies` in your `pubspec.yaml`:

```yaml title="pubspec.yaml"
dev_dependencies:
    revali_server: <latest version>
```

:::tip
Replace `<latest version>` with the actual latest version found on [pub.dev](https://pub.dev/packages/revali_server).
:::