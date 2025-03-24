---
title: Overview
sidebar_position: 0
description: Create Client-Side Code with Revali Client
---

# Revali Client

Revali Client is a [Construct][construct] that generates client-side code for Revali applications. By generating client-side code, you can use the generated client to make requests to your Revali Server.

The generated code is a Dart package that can be used in any Dart project.

The package is separated into "Interfaces" and "Implementations". The "Interfaces" are used to define the client's API, while the "Implementations" are used to define the client's implementation. This allows you to follow SOLID principles and keep your codebase clean and maintainable.

If you prefer to use a singleton instance of the client, there's the ability to do that too!

:::note
Revali Client is intended (but not required) to be used with [Revali Server][revali-server].
:::

[construct]: ../../constructs/overview.md#constructs
[revali-server]: ../revali_server/overview.md
