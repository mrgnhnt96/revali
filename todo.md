# TODO

- [ ] ~~Combine zora and zora_shelf into a single package~~
  - ~~This is because shelf is really the only http server that we will be using, and we want consistency~~
  - ~~We also don't want constructs to run scripts, which is what we would have to do if the zora_shelf package was separate~~
  - This is fine actually, we will have a flag within the config file that will determine whether the dependency is a "router" generator or other
- [x] Create `zora_construct` package to hold the core functionality of zora
  - This way developers don't need to depend on the entire zora package, just the necessary parts

## Create entrypoint for constructs

So I just figured out how I can get the constructs that the dev is depending on implicitly

1. Ge the dev dependencies
2. Resolve their paths and look for a construct.yaml file
3. Parse the construct.yaml file to get the configuration

No that I have the construct configs, I need a way to generate the code that the constructs will provide. Thankfully [build_runner](https://github.dev/dart-lang/build/tree/master/build_runner) has already done the work for this and I can follow their footsteps.

I can do this by creating a file within `.dart_tool/zora/entrypoint/zora.dart`

The code within this file should look like

```dart
import 'dart:io' as io;
import 'dart:isolate';

import 'package:zora/zora.dart';
import 'package:zora_shelf/zora_shelf.dart';

final constructs = <Construct>[
  ZoraShelfConstruct(),
];

const path = '/Users/morgan/Documents/develop.nosync/zora/examples/demo/routes';

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

Once the code is executed, it will run the code found within the `zora` package and generate the code provided by the constructs, provided by the generated `zora.dart` file.
