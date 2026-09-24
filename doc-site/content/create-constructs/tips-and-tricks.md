---
title: Debugging Constructs
description: Step through your construct with a debugger by launching Revali's generated construct runner directly
---

`revali dev` runs your construct inside a compiled runner, so breakpoints in your construct are not hit. To debug, launch the runner's source file, `.dart_tool/revali/revali.dart`, from your IDE instead. Run `dart run revali dev` once first so the file exists.

In VS Code, add a launch configuration in the **server** project:

<CodeFile name=".vscode/launch.json">

```json
{
  "configurations": [
    {
      "name": "Debug constructs",
      "request": "launch",
      "type": "dart",
      "cwd": "${workspaceFolder}",
      "program": ".dart_tool/revali/revali.dart",
      "args": ["dev"]
    }
  ]
}
```

</CodeFile>

- `args` selects the mode, exactly as on the command line: `["dev"]` or `["build"]`, plus any flags such as `--flavor`.
- Set `cwd` to the server project root, the directory holding its `pubspec.yaml`.
- Breakpoints in your construct package's `lib/` now work, and you can inspect the `MetaServer` that Revali built, which is the quickest way to learn what the analyzer exposes for your routes.

`revali.dart` is regenerated when the set of constructs changes. If you add or remove a construct, run `dart run revali dev` again before debugging.
