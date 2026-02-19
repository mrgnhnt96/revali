import 'package:revali_construct/revali_construct.dart';

base class RevaliBuildConstruct extends BuildConstruct {
  const RevaliBuildConstruct();

  @override
  BuildDirectory generate(RevaliBuildContext context, MetaServer server) {
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
}
