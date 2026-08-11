---
title: Run New Construct
description: Run the new construct to generate the code
---

Now that you've created your construct, it's time to run it and see the generated code.

## Run Construct

To run the construct, use the [`revali dev`][revali-dev] command in the server project's root directory.

```bash
dart run revali dev
```

This command will run the construct and generate the code in the server project's `.revali` directory. Since the construct we created is named `my_construct`, the generated code will be in the `.revali/my_construct` directory. Your generated code should look something like this:

```tree
.
└── .revali
    └── my_construct
        └── my-text-file.txt
```

Opening the `my-text-file.txt` file should show the text content we defined in the construct.

<CodeFile name=".revali/my_construct/my-text-file.txt">

```plaintext
Hello, World!
```

</CodeFile>

[revali-dev]: /revali/cli/dev
