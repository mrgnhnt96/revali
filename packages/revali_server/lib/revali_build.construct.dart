import 'package:revali_construct/models/files/any_file.dart';
import 'package:revali_construct/models/revali_build_context.dart';
import 'package:revali_construct/revali_construct.dart';

class RevaliBuildConstruct extends BuildConstruct {
  const RevaliBuildConstruct();

  @override
  BuildDirectory generate(RevaliBuildContext context, MetaServer server) {
    final defines = <String>[];
    for (final MapEntry(:key, :value) in context.defines.entries) {
      defines.add('$key=$value');
    }

    return BuildDirectory(
      files: [
        AnyFile(
          basename: 'Dockerfile',
          content: '''
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .

# delete pubspec_overrides.yaml
RUN rm pubspec_overrides.yaml

RUN dart pub get --offline

RUN dart compile exe .revali/server/server.dart -o /app/server -D${defines.join(',')}
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/bin/server

EXPOSE 1234
CMD ["/app/bin/server"]''',
        ),
      ],
    );
  }
}
