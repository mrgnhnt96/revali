# Create Entrypoint

The entrypoint is used by Revali to retrieve the code to be generated. This file should contain a single function that returns `Construct` object and accepts a `ConstructOptions` object as a parameter.

```dart title="lib/my_construct_entrypoint.dart"
import 'package:revali_construct/revali_construct.dart';

Construct myConstructEntrypoint([ConstructOptions? options]) {
    ...
}
```

:::note
The name of the function can be anything you want, but it must return a `Construct` object and accept a `ConstructOptions` object as a parameter.
:::

## Implement `Construct`

The `Construct` object is an abstract class that defines the structure of the code to be returned. You'll need to implement this class and return an instance of it in the entrypoint function.

```dart title="lib/my_construct.dart"
import 'package:revali_construct/revali_construct.dart';

class MyConstruct extends Construct {
  const MyConstruct();

  @override
  RevaliDirectory<AnyFile> generate(
    covariant RevaliContext context,
    MetaServer server,
  ) {
    return RevaliDirectory(
      files: [
        const AnyFile(
          basename: 'my-text-file',
          extension: 'txt',
          content: 'Hello, World!',
        ),
      ],
    );
  }
}
```

:::tip
Read more about `Construct` in the [API Reference][construct-api].
:::

## Return `MyConstruct` Instance

Finally, return an instance of the `MyConstruct` class in the entrypoint function.

```dart title="lib/my_construct_entrypoint.dart"
import 'package:revali_construct/revali_construct.dart';
import './my_construct.dart';

Construct myConstructEntrypoint([ConstructOptions? options]) {
    return const MyConstruct();
}
```

[construct-api]: ../core/construct.md
