---
title: Overview
slug: /create-constructs
---

# Overview

Revali is built methodically to provide developers with an intuitive and flexible way to create extension and plugins for their applications. Whether that be a client-generated package, a swagger API, or a custom plugin, Revali provides a way to create and manage these constructs with ease.

:::tip
Read about [Server Constructs][server-constructs] and [Build Constructs][build-constructs]
:::

:::important 🚧 Under Construction 🚧
This documentation is still under construction. Please check back later for updates.
:::

## Construct Types

There are a few types of constructs with dedicated purposes: [Server Constructs][server-constructs] and [Build Constructs][build-constructs]. You can create your own server/build constructs or create a generic construct.

## Generic Constructs

A generic construct is a Dart package that provides code generation capabilities to Revali. These constructs are standalone packages that are imported into your project, picked up by Revali, and used to generate code. This allows you to easily extend Revali's capabilities by creating your own constructs or using constructs created by the community.

When a generic construct is imported into your project, Revali will automatically register the construct and start generating the code. The generated code will be placed in the `.revali` directory, under the name of the construct. For example, if you have a construct called `my_construct`, this is how the generated code will be placed:

```tree
.revali
└── my_construct
```

:::note
In the case that there is a name conflict between constructs, Revali will nest the conflicting constructs within a directory named after their respective package (the `name` field in the `pubspec.yaml` file).

For example, if you have two constructs called `my_construct`, one from the `package_a` package and another from the `package_b` package, this is how the generated code will be placed:

```tree
.revali
├── package_a
│   └── my_construct
└── package_b
    └── my_construct
```

:::

[server-constructs]: ../constructs/overview.md#server-constructs
[build-constructs]: ../constructs/overview.md#build-constructs
