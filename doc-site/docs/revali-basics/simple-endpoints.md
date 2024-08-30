---
sidebar_position: 2
---

# Simple Endpoints

Now that you've created your app, you're ready to create endpoints. In Revali, endpoints are created in classes annotated with `@Controller`. These controller annotations require a path segment and will either be the endpoint itself, or a prefix — depending on your method annotations.

## Keeping It Simple

Let's create the basic functionality for a CRUD app.

With CRUD, you want to have a way to create, read, update and delete from an endpoint. How would you do this in Revali?

Create the file `routes/user.controller.dart`.

** Note: the file name MUST end in `.controller.dart`**

```ts title="routes/user.controller.dart"
@Controller('user')
class UserController {
  const UserController();

  @Post()
  Future<void> create() async {}

  @Get()
  Future<void> read() async {}

  @Patch() // or @Put()
  Future<void> update() async {}

  @Delete()
  Future<void> delete() async {}
}
```

As you can see, method names can be decoupled from Revali router annotations. Running the server at this point would result in the following endpoints being created:

```sh
# POST http://localhost/user
# GET http://localhost/user
# PATCH http://localhost/user
# DELETE http://localhost/user
```

You would use the same endpoint for each one of these requests and only change the HTTP verb to gain access each method.

## Dependencies

This endpoint wouldn't be very useful at this point since nothing is happening in any of the methods. Let's fix that by importing a class to do some work for us.

### Create Your Delegate

Whatever you end up calling them — delegates, repositories, data sources, models, etc. — we'll want to import the class that handles the bulk of the work.

We'll use Revali's dependency injector to provide the actual instance, so all we have to do in the controller is require the appropriate class.

Update your controller as follows (triple dots refer to the code that already exists):

```ts
class UserController {
  const UserController({
    required this.userRepository,
  });

  final UserRepository userRepository;

  ...
}
```

Back inside of your class annotated with `@App`, we'll want to tell Revali how to resolve this requirement by registering a class to use.

```ts
  @override
  Future<void> configureDependencies(DI di) async {
    di
      ..register(UserRepository.new)
  }
```

You should now have access to your class instance inside of your controller! Use `register` when you only want the class to be created when it's first referenced (lazily), and use `registerInstance` when you want your class to be eagerly created.

**Revali's DI also supports injections of implemented classes by providing the base class when registering. Ex. `register<UserRepository>(UserRepositoryImpl.new)`**
