# Construct Lifecycle

It's helpful to understand the lifecycle of a construct and how it fits into the Revali's code generation process. This section will walk you through the lifecycle of a construct and how it interacts with the Revali CLI.

## Running a Construct

When you run a construct using the Revali CLI, the following steps are executed:

### Package Discovery

The Revali CLI consumes your server project's `pubspec.yaml` file to peek into the project's `dev_dependencies` and discover the Revali Construct packages that are being used. It can determine the constructs that are available by looking for the `construct.yaml` file in the package's root directory. If the package is not a Revali Construct package, it will be ignored. The Revali CLI will then check the `construct.yaml` file to retrieve the construct's configuration: name, method, etc.

### Cache Check

If this is the first time you are running the Revali CLI, the Revali CLI will create a file to save the Construct's configuration. This file is located in the `.dart_tool` directory

```tree
.
└── .dart_tool
    └── revali
        └── revali.assets.json
```

If the `revali.assets.json` file already exists, then the Revali CLI will check if the construct's configuration has changed. If the configuration has changed, the Revali CLI will re-cache the construct's configuration.

This caching step is important because it allows the Revali CLI to skip compiling the root construct's entrypoint file if the configuration has not changed. This has the potential to save a lot of time when running the Revali CLI.

### Root Construct Compilation

The root construct's entrypoint file is where all the constructs are imported and prepared for execution. This file will contain a list of all the constructs that are being used in the server project, along with their configurations from their `construct.yaml` file. This file is located within the `.dart_tool` directory

```tree
.
└── .dart_tool
    └── revali
        └── revali.dart
```

When the Revali CLI compiles the root construct's entrypoint file, it will generate a `revali.dart.dill` file. This file is an executable file that contains the compiled code of the root construct's entrypoint file. This step is important because it allows the Revali CLI to spin up a VM isolate and execute the root construct's entrypoint file without having to recompile the code every time. In addition, this step also allows for you to tap into the Dart VM's debugging capabilities.

:::important
When you make modifications to your constructs, the `revali.assets.json` file will not be updated automatically, since there are no apparent changes to the construct's configuration or package dependencies. When this happens, you **_WILL NOT_** see the changes reflected in the generated code.

To force the Revali CLI to re-cache and therefore recompile the root construct's entrypoint file, you can pass the `--recompile` flag to the [`revali dev`][revali-dev] and [`revali build`][revali-build] commands.

```bash
dart run revali dev --recompile
```

:::

[revali-dev]: ../../revali/cli/00-dev.md
[revali-build]: ../../revali/cli/10-build.md
