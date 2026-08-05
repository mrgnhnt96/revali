import 'dart:io';

import 'package:revali_construct/revali_construct.dart';

base class RevaliBuildConstruct extends BuildConstruct {
  const RevaliBuildConstruct();

  @override
  BuildDirectory generate(RevaliBuildContext context, MetaServer server) {
    if (context.compiledExecutables.isEmpty) {
      return _generateMultiStage(context);
    }

    return _generateFromCompiled(context.compiledExecutables);
  }

  /// Today's default: the whole build (regenerate constructs, compile)
  /// happens inside Docker via a `dart:stable` build stage. Used whenever
  /// `revali build` didn't already compile a native executable (i.e. no
  /// `build:` section in `revali.yaml`).
  BuildDirectory _generateMultiStage(RevaliBuildContext context) {
    final defines = <String>[];
    final args = <String>[];
    for (final MapEntry(:key) in context.defines.entries) {
      args.add('ARG $key');
      defines.add('$key=\$$key');
    }

    var flavor = '';
    if (context.flavor case final value?) {
      flavor = '--flavor $value';
    }

    var dartDefines = '';
    var defineArguments = '';
    if (defines.isNotEmpty) {
      dartDefines = ' -D${defines.join(' \\\n\t-D')}';
      defineArguments =
          '''

# Define build arguments
${args.join('\n')}
''';
    }

    return BuildDirectory(
      files: [
        AnyFile(
          basename: 'Dockerfile',
          content:
              '''
FROM dart:stable AS build

WORKDIR /app
COPY . .
RUN rm pubspec_overrides.yaml || true

# Get dependencies
RUN dart pub get
$defineArguments
# Build the server
RUN dart run revali build $flavor --${context.mode.flag} --type constructs --recompile

# Compile the server
RUN dart compile exe .revali/server/server.dart -o /app/server$dartDefines

FROM alpine:latest

# Install necessary dependencies for the Dart binary
RUN apk add --no-cache libc6-compat ca-certificates

# Copy the compiled server to the image
COPY --from=build /app/server /app/bin/server

# Run the server
CMD ["/app/bin/server"]''',
        ),
      ],
    );
  }

  /// `revali build` already compiled a native executable per the `build:`
  /// section of `revali.yaml` (see [RevaliBuildContext.compiledExecutables]).
  /// Package it into a minimal single-stage image instead of compiling
  /// anything ourselves — this construct only reacts to what the core
  /// already decided and produced.
  BuildDirectory _generateFromCompiled(
    List<CompiledExecutable> compiledExecutables,
  ) {
    final files = <AnyFile>[];

    for (final executable in compiledExecutables) {
      files.add(
        AnyFile(
          basename: 'server-${executable.targetArch.dockerArg}',
          bytes: File(executable.path).readAsBytesSync(),
        ),
      );

      if (executable.debugInfoPath case final debugInfoPath?) {
        files.add(
          AnyFile(
            basename: 'server-${executable.targetArch.dockerArg}.debug',
            bytes: File(debugInfoPath).readAsBytesSync(),
          ),
        );
      }
    }

    final copySection = compiledExecutables.length == 1
        ? 'COPY .revali/build/server-'
              '${compiledExecutables.single.targetArch.dockerArg} '
              '/app/bin/server'
        : 'ARG TARGETARCH\n'
              r'COPY .revali/build/server-${TARGETARCH} /app/bin/server';

    files.add(
      AnyFile(
        basename: 'Dockerfile',
        content:
            '''
FROM alpine:latest

# Install necessary dependencies for the Dart binary
RUN apk add --no-cache libc6-compat ca-certificates

$copySection
RUN chmod +x /app/bin/server

# Run the server
CMD ["/app/bin/server"]''',
      ),
    );

    return BuildDirectory(files: files);
  }
}

/// Maps a Dart `--target-arch` value to the `$TARGETARCH` name Docker/buildx
/// uses, so the generated Dockerfile needs no shell logic to pick the right
/// binary.
extension on Arch {
  String get dockerArg => switch (this) {
    Arch.x64 => 'amd64',
    Arch.arm64 => 'arm64',
    Arch.arm => 'arm',
    Arch.ia32 => '386',
    Arch.riscv32 || Arch.riscv64 => 'riscv64',
  };
}
