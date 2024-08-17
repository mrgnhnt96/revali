import 'package:revali_construct/revali_construct.dart';

class RevaliBuildConstruct extends BuildConstruct {
  const RevaliBuildConstruct();

  @override
  BuildDirectory generate(RevaliBuildContext context, MetaServer server) {
    final defines = <String>[];
    for (final MapEntry(:key, :value) in context.defines.entries) {
      defines.add('$key=$value');
    }

    var flavor = '';
    if (context.flavor case final value?) {
      flavor = '--flavor $value';
    }

    return BuildDirectory(
      files: [
        AnyFile(
          basename: 'Dockerfile',
          content: '''
FROM dart:stable AS build

WORKDIR /app
COPY . .
RUN rm pubspec_overrides.yaml

RUN dart pub get

RUN dart run revali build $flavor --${context.mode.flag} --type constructs

RUN dart compile exe .revali/server/server.dart -o /app/server -D${defines.join(',')}
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/bin/server

CMD ["/app/bin/server"]''',
        ),
      ],
    );
  }
}
