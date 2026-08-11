---
title: Add as Dependency
description: Add the construct to your server project
---

<Callout type="info">

This step assumes that you have already created a server project. If you haven't, you can create one by following the [Revali docs][create-server-project].

</Callout>

To use the construct package in your server project, you will need to add it as a dependency to your server's `pubspec.yaml` file.

<CodeFile name="pubspec.yaml">

```yaml
dev_dependencies:
    my_construct:
        path: ./my_construct
```

</CodeFile>

<Callout type="tip">

The `path` property can either be an absolute path, or a relative path to the construct package from the server project's root directory.

For example, if your file structure looks like this:

```tree
.
├── constructs
│   └── my_construct
│       ├── lib
│       │   └── my_construct.dart
│       └── pubspec.yaml
└── my_server
    ├── .revali
    │   └── server
    │       └── ...
    └── pubspec.yaml
```

Then the `path` property should be set to `../constructs/my_construct`.

</Callout>

[create-server-project]: /revali/getting-started/installation
