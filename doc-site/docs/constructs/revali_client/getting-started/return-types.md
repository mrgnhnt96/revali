---
title: Return Types
description: Support for custom return types
sidebar_position: 3
---

# Return Types

Revali Client can generate many different return types, such as `Future`, `Stream`, `Record`s, custom classes, and more. Out of the box, Revali Client supports most of the types that you would need without any additional configuration. There are however cases where you need to customize the return types.

## Custom Return Types

When you create a data class, this class _should_ be shared between the server and the client. This is important because the generated code will use this class to serialize and deserialize the response.

In order to share custom return types between the server and the client, you'll need to create a new Dart package containing the data class and add it as a dependency to both the server and the client.

Let's say we have the following folder structure in your server project:

```text
.
├── lib
│   └── models
│       └── user.dart
└── routes
    └── controllers
        └── user_controller.dart
```

Here are the contents of the `lib/models/user.dart` file:

```dart title="lib/models/user.dart"
class User {
  const User({required this.name});

  final String name;

  factory User.fromJson(Map<String, dynamic> json) => User(name: json['name']);

  Map<String, dynamic> toJson() => {'name': name};
}
```

Here are the (simplified) contents of the `lib/routes/controllers/user_controller.dart` file:

```dart title="lib/routes/controllers/user_controller.dart"
@Controller()
class UserController {
  @Get('/user')
  User getUser() {
    return User(name: 'John Doe');
  }
}
```

When the client is generated, you'll see something like the following:

```dart title="lib/src/interfaces/user_data_source.dart"
class UserDataSource {
    const UserDataSource();

    Future<User> getUser();
}
```

This is expected, however, the `User` class doesn't exist in the client project and will cause a compile error.

To fix this, you'll need to create a new Dart package containing the `User` class and add it as a dependency to the server project.

:::tip
You can create a new Dart package by running `dart create <package_name> --template package`.
:::

Your new package should look something like the following:

```text
.
├── lib
│   └── user.dart
└── pubspec.yaml # name: models
```

:::note
The new dart package can have any structure you want, as long as the `User` class is in the `lib` directory.
:::

Now you can add the new package as a dependency to the server project.

```yaml title="pubspec.yaml"
dependencies:
  models:
    path: ../user_package
```

Now that the `User` class is in a different package, the generated client code will pick up the new package automatically and add it to the client's pubspec.yaml file. Resulting in a valid client!

---

# Return Types

Revali Client supports a wide range of return types out of the box, including `Future`, `Stream`, `Record`s, custom classes, and more. In most cases, no additional configuration is required. However, there are situations where you may need to define and use custom return types.

## Custom Return Types

When using custom data classes as return types, those classes should be shared between the server and the client. This is important, as the generated code relies on those classes for proper serialization and deserialization.

To share a custom return type between the server and client, you'll need to extract the class into a separate Dart package and add it as a dependency to both projects.

### Example Setup

Suppose your server project has the following structure:

```text
.
├── lib
│   └── models
│       └── user.dart
└── routes
    └── controllers
        └── user_controller.dart
```

Your `User` model might look like this:

```dart title="lib/models/user.dart"
class User {
  const User({required this.name});

  final String name;

  factory User.fromJson(Map<String, dynamic> json) => User(name: json['name']);

  Map<String, dynamic> toJson() => {'name': name};
}
```

And your controller might look like this:

```dart title="lib/routes/controllers/user_controller.dart"
@Controller('user')
class UserController {

  @Get()
  User getUser() {
    return User(name: 'John Doe');
  }
}
```

Once the client is generated, you’ll get code like this:

```dart title="lib/src/interfaces/user_data_source.dart"
class UserDataSource {
  const UserDataSource();

  Future<User> getUser();
}
```

At this point, the client expects a `User` class to exist—but since it doesn’t exist in the client project (it's in the server's package), you'll get a compile error.

### Fixing the Issue

To resolve this, move the `User` class into its own Dart package and share it between the server and the client.

:::tip
You can create a new Dart package with the command:
`dart create models --template package`

This will create a new package with the name `models`, you can change it to whatever you want.
:::

Your package might look like this:

```text
.
├── lib
│   └── user.dart
└── pubspec.yaml # name: models
```

:::note
You’re free to structure the package however you like, as long as the `User` class is somewhere within the `lib` directory.
:::

Then, add the new package as a dependency in your server’s `pubspec.yaml`:

```yaml title="pubspec.yaml"
dependencies:
  models:
    path: ../user_package
```

When Revali Client generates the client code, it will automatically recognize and include the shared package in the client’s `pubspec.yaml`, resulting in a valid, working client.
