---
title: Overview
slug: /constructs
---

# Constructs

## What is a Construct?

A construct is a Dart package that provides code generation capabilities to Revali. Constructs are standalone packages that are imported into your project, picked up by Revali, and used to generate code. This allows you to easily extend Revali's capabilities by creating your own constructs or using constructs created by the community.

Generally, constructs are used when the `dev` command is run. Generating new code, assets, or files based on the apps & routes you've defined. Each construct will generate their content within their own directory.

```tree
.revali
└── <construct-name>
    └── ...
```

:::tip
Check out the `dev` command in the [CLI Commands][dev-command].
:::

## Types of Constructs

There are a few types of constructs with dedicated purposes: [Server Constructs](#server-constructs) and [Build Constructs](#build-constructs).

### Server Constructs

A "Server Construct" is a construct that generates the code for the `.revali/server` directory. The server is the core of your Revali application and is responsible for handling incoming HTTP requests and returning responses.

:::important
You can only have **one** server construct in your project.
:::

:::tip
Check out Revali's default Server Construct ([`revali_server`][revali-server]).
:::

### Build Constructs

A "Build Construct" is a construct that generates the code for the `.revali/build` directory. These constructs are run during the `build` command and are responsible for generating code, assets, or any other files that are needed for deployment.

:::info
You are not limited to the number of build constructs you can have in your project.
:::

:::caution
While you can have multiple build constructs, be careful that they do not conflict with each other's outputs.
:::

:::tip
Check out the [Build Command][build-command] for more information.
:::

[dev-command]: ../revali/cli/00-dev.md
[build-command]: ../revali/cli/10-build.md
[revali-server]: ../constructs/revali_server/overview.md
