# Tips and Tricks

## Debugging Constructs

Let's be honest, the Dart Analyzer's API is very extensive and can be quite overwhelming at first. Debugging your constructs can be very helpful in understanding how the Analyzer is interpreting your server project's codebase. Here are a few tips to help you debug your constructs:

### Don't use `revali dev` for debugging

This may seem counterintuitive, but the `revali dev` command is not the best way to debug your constructs. The `revali dev` command is designed to run your constructs in a production-like environment, which means that it will not output any debugging information to the console. To debug your constructs, you should leverage the Root Construct Entrypoint file that is generated when you run the `revali dev` command.

This file is located in the `.dart_tool` directory:

```tree
.
└── .dart_tool
    └── revali
        └── revali.dart
```

:::important
You're going to need to run the `revali dev` command at least once to generate the Root Construct Entrypoint file.
:::

Once you have the Root Construct Entrypoint file, you can debug your constructs using your IDE's debugger. This will allow you to set breakpoints, inspect variables, and step through your constructs line by line.

:::tip
In VSCode, add a new configuration to your `launch.json` file that points to the Root Construct Entrypoint file. It should look something like this:

```json title=".vscode/launch.json"
{
    "name": "Debug Constructs",
    "cwd": "examples/create_construct/app",
    "request": "launch",
    "type": "dart",
    "program": ".dart_tool/revali/revali.dart",
    "args": [ "dev" ]
}
```

:::important
You must pass the `dev` (or `build`) argument so that the Root Construct Entrypoint file knows which mode to run in. The arguments are the same as the ones you would pass to the [`revali dev`][revali-dev] or [`revali build`][revali-build] command.
:::

[revali-dev]: ../revali/cli/00-dev.md
[revali-build]: ../revali/cli/10-build.md
