import 'dart:convert';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:revali/handlers/construct_entrypoint_handler.dart';
import 'package:revali/utils/extensions/directory_extensions.dart';
import 'package:revali/utils/kernel_cache.dart';

class DoctorCommand extends Command<int> {
  DoctorCommand({
    required this.logger,
    required this.fs,
    required ConstructEntrypointHandler generator,
  }) : _generator = generator {
    argParser.addFlag('json', help: 'Print structured JSON', negatable: false);
  }

  final Logger logger;
  final FileSystem fs;
  final ConstructEntrypointHandler _generator;

  @override
  String get name => 'doctor';

  @override
  String get description =>
      'Check SDK, constructs, kernel cache, and generated output freshness';

  @override
  Future<int> run() async {
    final checks = <Map<String, Object?>>[];
    var hardFail = false;

    void add(String id, String status, {String? detail, bool fail = false}) {
      checks.add({
        'id': id,
        'status': status,
        if (detail != null) 'detail': detail,
      });
      if (fail) hardFail = true;
    }

    add('sdk', 'ok', detail: io.Platform.version.split(' ').first);

    Directory root;
    try {
      root = await _generator.rootOf(_generator.initialDirectory);
      add('project_root', 'ok', detail: root.path);
    } catch (e) {
      add('project_root', 'error', detail: '$e', fail: true);
      return _emit(checks, hardFail: true);
    }

    final packageConfigFile = root
        .childDirectory('.dart_tool')
        .childFile('package_config.json');
    if (!packageConfigFile.existsSync()) {
      add(
        'package_config',
        'error',
        detail: 'Missing .dart_tool/package_config.json — run dart pub get',
        fail: true,
      );
      return _emit(checks, hardFail: true);
    }

    final packageConfig = await loadPackageConfigUri(packageConfigFile.uri);
    final revaliPkgs =
        packageConfig.packages
            .where((pkg) => pkg.name.startsWith('revali'))
            .map((pkg) => pkg.name)
            .toList()
          ..sort();
    add(
      'revali_packages',
      revaliPkgs.isEmpty ? 'warn' : 'ok',
      detail: revaliPkgs.isEmpty ? 'none found' : revaliPkgs.join(', '),
    );

    try {
      final constructs = await _generator.constructHandler.constructDepsFrom(
        root,
      );
      final names = [
        for (final yaml in constructs)
          for (final c in yaml.constructs) '${yaml.packageName}:${c.name}',
      ];
      add(
        'constructs',
        constructs.isEmpty ? 'warn' : 'ok',
        detail: names.isEmpty ? 'none resolved' : names.join(', '),
      );

      final fingerprint = constructSetFingerprint(constructs);
      final cacheDir = resolveKernelCacheDir(
        fs,
        root,
      ).childDirectory(fingerprint);
      final cachedKernel = cacheDir.childFile(
        ConstructEntrypointHandler.kernelFile,
      );
      add(
        'kernel_cache',
        cachedKernel.existsSync() ? 'ok' : 'warn',
        detail: cachedKernel.existsSync()
            ? 'hit $fingerprint'
            : 'miss $fingerprint (${cacheDir.path})',
      );

      final localKernel = await root.getInternalRevaliFile(
        ConstructEntrypointHandler.kernelFile,
      );
      final stale = await _generator.kernelIsStale(constructs, root);
      add(
        'local_kernel',
        !localKernel.existsSync()
            ? 'warn'
            : stale
            ? 'warn'
            : 'ok',
        detail: !localKernel.existsSync()
            ? 'missing'
            : stale
            ? 'stale vs revali_* / construct sources'
            : 'fresh',
      );
    } catch (e) {
      add('constructs', 'warn', detail: '$e');
    }

    final serverOut = root
        .childDirectory('.revali')
        .childDirectory('server')
        .childFile('server.dart');
    final routesDir = root.childDirectory('routes');
    final fresh = outputsAreFresh(
      fs: fs,
      outputs: [serverOut],
      inputDirs: [
        if (routesDir.existsSync()) routesDir,
        root.childDirectory('lib'),
      ],
    );
    add(
      'generated_outputs',
      !serverOut.existsSync()
          ? 'warn'
          : fresh
          ? 'ok'
          : 'warn',
      detail: !serverOut.existsSync()
          ? 'missing .revali/server/server.dart'
          : fresh
          ? 'up to date vs routes/ and lib/'
          : 'stale — run dart run revali dev --generate-only',
    );

    final manifest = root
        .childDirectory('.revali')
        .childDirectory('server')
        .childFile('routes.json');
    add(
      'routes_manifest',
      manifest.existsSync() ? 'ok' : 'warn',
      detail: manifest.existsSync()
          ? manifest.path
          : 'missing — regenerate server construct',
    );

    // Best-effort: warn if controllers throw but no @Catches / Catch-like
    // lifecycle types appear under routes/ or lib/components.
    final throwHints = <String>[];
    for (final dirName in ['routes', 'lib/components', 'lib']) {
      final dir = fs.directory(p.join(root.path, dirName));
      if (!dir.existsSync()) continue;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final text = await entity.readAsString();
        final throws = RegExp(r'throw\s+(?:const\s+)?(\w+)').allMatches(text);
        for (final m in throws) {
          final type = m.group(1)!;
          if (type == 'Exception' || type == 'Error' || type == 'StateError') {
            continue;
          }
          throwHints.add('$type (${p.relative(entity.path, from: root.path)})');
        }
      }
    }
    if (throwHints.isNotEmpty) {
      final sample = throwHints.first.split(' ').first;
      add(
        'exception_catchers',
        'info',
        detail:
            'Controllers/components throw: ${throwHints.take(8).join(', ')}'
            '${throwHints.length > 8 ? '…' : ''}. '
            'Ensure ExceptionCatcher<$sample> or a LifecycleComponent catcher '
            'is registered (warn only).',
      );
    } else {
      add('exception_catchers', 'ok', detail: 'no thrown types scanned');
    }

    return _emit(checks, hardFail: hardFail);
  }

  int _emit(List<Map<String, Object?>> checks, {required bool hardFail}) {
    final asJson = argResults?['json'] as bool? ?? false;
    if (asJson) {
      io.stdout.writeln(
        const JsonEncoder.withIndent(
          '  ',
        ).convert({'ok': !hardFail, 'checks': checks}),
      );
    } else {
      for (final check in checks) {
        final status = check['status'];
        final id = check['id'];
        final detail = check['detail'];
        final icon = switch (status) {
          'ok' => '✓',
          'warn' => '!',
          'error' => '✗',
          _ => '·',
        };
        logger.info('$icon [$status] $id${detail != null ? ': $detail' : ''}');
      }
    }
    return hardFail ? 1 : 0;
  }
}
