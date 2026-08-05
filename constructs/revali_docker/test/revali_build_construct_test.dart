import 'dart:io';

import 'package:revali_construct/revali_construct.dart';
import 'package:revali_docker/revali_build.construct.dart';
import 'package:test/test.dart';

RevaliBuildContext _context({
  String? flavor,
  Mode mode = Mode.release,
  Map<String, String> defines = const {},
  List<CompiledExecutable> compiledExecutables = const [],
}) => RevaliBuildContext(
  flavor: flavor,
  mode: mode,
  defines: defines,
  compiledExecutables: compiledExecutables,
);

AnyFile _fileNamed(List<AnyFile> files, String basename) =>
    files.firstWhere((f) => f.basename == basename);

void main() {
  group(RevaliBuildConstruct, () {
    group("without compiled executables (today's Docker-native build)", () {
      const construct = RevaliBuildConstruct();

      test('generates the multi-stage Dockerfile', () {
        final result = construct.generate(
          _context(),
          const MetaServer(apps: [], public: [], routes: []),
        );

        expect(result.files, hasLength(1));
        final dockerfile = result.files.single;
        expect(dockerfile.basename, 'Dockerfile');
        expect(dockerfile.bytes, isNull);
        expect(dockerfile.content, contains('FROM dart:stable AS build'));
        expect(dockerfile.content, contains('FROM alpine:latest'));
        expect(
          dockerfile.content,
          contains(
            'RUN dart run revali build  --release '
            '--type constructs --recompile',
          ),
        );
        expect(
          dockerfile.content,
          contains(
            'RUN dart compile exe .revali/server/server.dart -o /app/server',
          ),
        );
        expect(
          dockerfile.content,
          contains('COPY --from=build /app/server /app/bin/server'),
        );
      });

      test('includes the flavor flag when a flavor is set', () {
        final result = construct.generate(
          _context(flavor: 'prod'),
          const MetaServer(apps: [], public: [], routes: []),
        );

        expect(result.files.single.content, contains('--flavor prod'));
      });

      test('adds ARG declarations for dart-defines', () {
        final result = construct.generate(
          _context(defines: const {'API_KEY': 'secret'}),
          const MetaServer(apps: [], public: [], routes: []),
        );

        final content = result.files.single.content;
        expect(content, contains('ARG API_KEY'));
        expect(content, contains(r'-DAPI_KEY=$API_KEY'));
      });
    });

    group('with compiled executables', () {
      const construct = RevaliBuildConstruct();
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('revali_docker_test');
      });

      tearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      test('single arch: plain COPY, no ARG TARGETARCH', () {
        final binary = File('${tempDir.path}/server')
          ..writeAsBytesSync([0x7f, 0x45, 0x4c, 0x46]);

        final result = construct.generate(
          _context(
            compiledExecutables: [
              CompiledExecutable(
                targetOs: TargetOs.linux,
                targetArch: Arch.x64,
                path: binary.path,
              ),
            ],
          ),
          const MetaServer(apps: [], public: [], routes: []),
        );

        expect(result.files, hasLength(2));

        final server = _fileNamed(result.files, 'server-amd64');
        expect(server.bytes, [0x7f, 0x45, 0x4c, 0x46]);

        final dockerfile = _fileNamed(result.files, 'Dockerfile');
        expect(dockerfile.content, contains('FROM alpine:latest'));
        expect(dockerfile.content, isNot(contains('dart:stable')));
        expect(dockerfile.content, isNot(contains('ARG TARGETARCH')));
        expect(
          dockerfile.content,
          contains('COPY .revali/build/server-amd64 /app/bin/server'),
        );
        expect(dockerfile.content, contains('RUN chmod +x /app/bin/server'));
      });

      test('multi arch: ARG TARGETARCH picks the binary at runtime', () {
        final x64Binary = File('${tempDir.path}/server-x64')
          ..writeAsBytesSync([1, 2, 3]);
        final arm64Binary = File('${tempDir.path}/server-arm64')
          ..writeAsBytesSync([4, 5, 6]);

        final result = construct.generate(
          _context(
            compiledExecutables: [
              CompiledExecutable(
                targetOs: TargetOs.linux,
                targetArch: Arch.x64,
                path: x64Binary.path,
              ),
              CompiledExecutable(
                targetOs: TargetOs.linux,
                targetArch: Arch.arm64,
                path: arm64Binary.path,
              ),
            ],
          ),
          const MetaServer(apps: [], public: [], routes: []),
        );

        expect(result.files, hasLength(3));
        expect(_fileNamed(result.files, 'server-amd64').bytes, [1, 2, 3]);
        expect(_fileNamed(result.files, 'server-arm64').bytes, [4, 5, 6]);

        final dockerfile = _fileNamed(result.files, 'Dockerfile');
        expect(dockerfile.content, contains('ARG TARGETARCH'));
        expect(
          dockerfile.content,
          contains(r'COPY .revali/build/server-${TARGETARCH} /app/bin/server'),
        );
      });

      test('includes a sibling .debug file without referencing it', () {
        final binary = File('${tempDir.path}/server')..writeAsBytesSync([1]);
        final debugInfo = File('${tempDir.path}/server.debug')
          ..writeAsBytesSync([2]);

        final result = construct.generate(
          _context(
            compiledExecutables: [
              CompiledExecutable(
                targetOs: TargetOs.linux,
                targetArch: Arch.x64,
                path: binary.path,
                debugInfoPath: debugInfo.path,
              ),
            ],
          ),
          const MetaServer(apps: [], public: [], routes: []),
        );

        expect(result.files, hasLength(3));
        expect(_fileNamed(result.files, 'server-amd64.debug').bytes, [2]);

        final dockerfile = _fileNamed(result.files, 'Dockerfile');
        expect(dockerfile.content, isNot(contains('.debug')));
      });
    });
  });
}
