---
title: Overview
---

# Constructs

## What is a Construct?

A construct is a Dart package that provides code generation capabilities to Revali. Constructs are standalone packages that are imported into your project, picked up by Revali, and used to generate code. This allows you to easily extend Revali's capabilities by creating your own constructs or using constructs created by the community.

## Server Constructs

A "Server Construct" is a construct that generates the code for the `.revali/server` directory. The server is the core of your Revali application and is responsible for handling incoming HTTP requests and returning responses.

:::tip
Check out Revali's default server ([`revali_server`](/constructs/revali_server)).
:::

:::important
You can only have **one** server construct in your project.
:::

## Build Constructs

A "Build Construct" is a construct that generates the code for the `.revali/build` directory. These constructs are run during the `revali build` command and are responsible for generating code, assets, or any other files that are needed for deployment.

:::info
You are not limited to the number of build constructs you can have in your project.
:::

:::caution
While you can have multiple build constructs, you'll need to ensure they do not conflict with each other.
:::
