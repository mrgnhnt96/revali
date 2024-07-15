# TODO

## 7.15.2024

- [ ] Find a way to support partial content requests

## 7.13.2024 (2)

- [ ] CORs for apps ([docs](https://github.com/lenniezelk/shelf-cors-headers/blob/main/lib/src/shelf_cors_headers_base.dart#L52))
- [ ] Handle range file requests
- [ ] Handle if modified since file requests
- [ ] Send back last modified header for files
- [ ] Set headers based on body data type (within the send request method only!)
  - Create headers getter on the body data type
- [ ] Update the content disposition header for files

## 7.13.2024

- [x] Update headers when status code changes
- [x] Update headers when body changes
- [x] Returning files
- [x] Public files
  - Routes will be automatically generated for these files
  - The files will be served from the `public` directory
- [x] Static files
  - Routes will _not_ be generated for these files
  - The idea is that the user will be able to return a "ServerFile" class with the path pointing to the file

## 7.10.2024

## Features

- [x] Dependency injection for apps
- ~~[ ] Wildcard paths~~
  - Maybe later...
- [x] Web sockets
- ~~[ ] Returning streams (not as web sockets)~~

## Try

- [ ] Attempt to create a variable for combine types as an annotation
  - This could allow me to get the values of the fields of the annotation

## 7.5.2024

- [x] Create "App" annotation
  - This will be used for configurations such as
    - [x] Server lambdas
    - [x] Server configurations
    - [ ] Dependency injection
    - [x] Global exception catchers
    - [x] Global guards
    - [x] Global prefix
    - [ ] CORS
    - (Nice To Haves):
      - Rate limiting
- [x] Add flavor flag to the annotation & to the CLI to determine what environment the app is running in

## 7.1.2024

- [x] Add `Pipe` class for annotations
  - This will be used to convert the annotated item to another type
- [x] Add `Guard` class for annotations
  - This will be used to stop or continue the execution of the method/endpoint
  - We could create a field for types where we could annotation like `@Guard([AuthGuard, RoleGuard])`
    - This wouldn't allow for _all_ edge cases, but could be useful
    - We could also add a different field coupled with a different constructor to allow for instances of guards
- [x] Create `Catch` class which will be used to catch errors thrown by the method/endpoint
  - The errors would need to implement the `ExceptionCatcher` interface
  - We could create a field for types where we could annotation like `@Catch([UnknownCatcher, ServerCatcher, BadRequestCatcher])`
- [x] Create `HttpCode` class which will be used to set the status code of the response
  - `@HttpCode(200)`
- [x] Create `SetHeader` class which will be used to set the headers of the response
  - `@SetHeader('Content-Type', 'application/json')`
- [x] Create `Redirect` class which will be used to redirect the user to another endpoint
  - `@Redirect('/home')`
- [x] Create `Body` class which will be used to get the body of the request as a parameter
  - `@Body()`
- [x] Create `Header` class which will be used to get the headers of the request as a parameter
  - `@Header('Content-Type')`

# Nice to have

- [ ] Create `RateLimit` class which will be used to limit the number of requests to an endpoint
  - `@RateLimit(10, Duration(minutes: 1))`

## > 7.1.2024

---

- [ ] ~~Combine revali and revali_server into a single package~~
  - ~~This is because shelf is really the only http server that we will be using, and we want consistency~~
  - ~~We also don't want constructs to run scripts, which is what we would have to do if the revali_server package was separate~~
  - This is fine actually, we will have a flag within the config file that will determine whether the dependency is a "router" generator or other
- [x] Create `revali_construct` package to hold the core functionality of revali
  - This way developers don't need to depend on the entire revali package, just the necessary parts

## Create entrypoint for constructs

So I just figured out how I can get the constructs that the dev is depending on implicitly

1. Ge the dev dependencies
2. Resolve their paths and look for a construct.yaml file
3. Parse the construct.yaml file to get the configuration

No that I have the construct configs, I need a way to generate the code that the constructs will provide. Thankfully [build_runner](https://github.dev/dart-lang/build/tree/master/build_runner) has already done the work for this and I can follow their footsteps.

I can do this by creating a file within `.dart_tool/revali/entrypoint/revali.dart`

The code within this file should look like

```dart
import 'dart:io' as io;
import 'dart:isolate';

import 'package:revali/revali.dart';
import 'package:revali_server/revali_server.dart';

final constructs = <Construct>[
  revaliShelfConstruct(),
];

const path = '/Users/morgan/Documents/develop.nosync/revali/examples/demo/routes';

void main(
  List<String> args, [
  SendPort? sendPort,
]) async {
  var result = await run(
    args,
    constructs: constructs,
    path: path,
  );
  sendPort?.send(result);
  io.exitCode = result;
}
```

Obviously this will need to be modified so that we don't have conflicts in the imports.

Once I have this file, I can execute it

```dart
await Isolate.spawnUri(Uri.file(p.absolute(scriptKernelLocation)), args,
messagePort.sendPort,
errorsAreFatal: true,
onExit: exitPort.sendPort,
onError: errorPort.sendPort);
```

In build_runner, they are compiling the code to a kernel file and then executing it. I will probably need to do the same thing.

Once the code is executed, it will run the code found within the `revali` package and generate the code provided by the constructs, provided by the generated `revali.dart` file.
