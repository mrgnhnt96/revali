---
title: Fly.io
---

# [Fly.io][fly-io]

Check out Fly.io's [documentation][fly-io-docs] for more information on deploying Docker containers using a [Dockerfile][dockerfile-docs].

## Create a Fly.io Account

To get started with Fly.io, you need to create an account. You can sign up for a free account [here](https://fly.io/app/sign-up).

## Install the Fly CLI

If you're on Mac, you can install the Fly CLI by running the following command:

```bash
# Using Homebrew
brew install flyctl

# Using curl
curl -L https://fly.io/install.sh | sh
```

If you're on a different platform, you can download the Fly CLI from the [Fly.io documentation][install-cli].

## Create a Fly.io Application

Create a `fly.toml` file in the root of your project. An example of what that could look like is:

```toml
# fly.toml app configuration file generated for revali-server on 2024-10-12T15:50:46-07:00
#
# See https://fly.io/docs/reference/configuration/ for information about how to use this file.
#

app = 'revali-server'
primary_region = 'lax'

[build]

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = 'stop'
  auto_start_machines = true
  min_machines_running = 0
  processes = ['app']

[[vm]]
  memory = '1gb'
  cpu_kind = 'shared'
  cpus = 1
```

:::caution
This is an example, and you may need to adjust the configuration based on your application's requirements.
:::

## Move Dockerfile to the Root of Your Project

Move your `Dockerfile` to the root of your project.

```bash
mv ./.revali/build/Dockerfile .
```

::::tip
If you don't have a `Dockerfile`, you can create one with the following command:

```bash
dart run revali build
```

:::tip
Learn more about the [Build Command][build-command].
:::
::::

## Deploy Your Application

To deploy your application, run the following command:

```bash
fly deploy
```

## Open Your Application

To open your application in the browser, run the following command:

```bash
fly apps open
```

[fly-io]: https://fly.io/
[fly-io-docs]: https://fly.io/docs/
[dockerfile-docs]: https://fly.io/docs/languages-and-frameworks/dockerfile/
[install-cli]: https://fly.io/docs/flyctl/install/
[build-command]: ../../../revali/cli/10-build.md
