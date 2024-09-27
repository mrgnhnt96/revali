# Env Vars

Your server will eventually need to interact with the outside world. This could be through a database, an external API, or even just to configure the server itself. Revali provides a way to configure your server using environment variables.

## Setting Environment Variables

### ENV File

The easiest way to set environment variables is to create a `.env` file in the root of your project. This file should contain the environment variables you want to set, in the format `KEY=VALUE`. For example:

```env
LOZ_OOT=1998
```

:::danger
Don't check your `.env` file into source control!
:::

:::info
The `.env` file can be named anything you want, but `.env` is the most common convention.
:::

To tell revali to use the `.env` file, you can use the `--dart-define-from-file` flag:

```shell
revali dev --dart-define-from-file=.env

revali build --dart-define-from-file=.env
```

### Command Line

You can also set environment variables directly from the command line:

```shell
revali dev --dart-define=LOZ_OOT=1998

revali build --dart-define=LOZ_OOT=1998
```
