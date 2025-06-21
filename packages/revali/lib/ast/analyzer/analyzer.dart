import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:platform/platform.dart';
import 'package:revali/ast/analyzer/analyzer_changes.dart';
import 'package:revali/ast/analyzer/units.dart';
import 'package:revali/ast/find/interfaces/find.dart';

class Analyzer implements AnalyzerChanges {
  Analyzer({
    required this.fs,
    required this.find,
    required this.platform,
    required this.logger,
  }) : _memoryProvider = MemoryResourceProvider();

  final FileSystem fs;
  final Find find;
  final Platform platform;
  final Logger logger;

  MemoryResourceProvider _memoryProvider;
  AnalysisContextCollection? _analysisCollection;
  AnalysisContextCollection get analysisCollection {
    if (_analysisCollection case final collection?) {
      return collection;
    }

    throw UnimplementedError('No analysis collection has not been initialized');
  }

  String? _sdkPath;
  Future<String> get sdkPath async {
    if (_sdkPath case final String path) {
      return path;
    }

    return _sdkPath = fs.file(platform.resolvedExecutable).parent.parent.path;
  }

  bool _isInitialized = false;

  Future<void> initialize({required String root}) async {
    if (_isInitialized) {
      return;
    }

    try {
      await _createVirtualWorkspace(root);

      _analysisCollection = AnalysisContextCollection(
        includedPaths: [root],
        resourceProvider: _memoryProvider,
        sdkPath: await sdkPath,
      );
    } catch (e) {
      logger
        ..err('Error initializing analyzer')
        ..detail('$e');
      rethrow;
    }

    _isInitialized = true;
  }

  @override
  Future<void> refresh(String file) async {
    AnalysisContext context;
    try {
      context = analysisCollection.contextFor(file);
    } catch (e) {
      // its likely this file does not need to be included within analysis
      // so we can just return
      return;
    }
    final bytes = await fs.file(file).readAsBytes();

    _memoryProvider.newFileWithBytes(file, bytes);

    context.changeFile(file);
  }

  @override
  Future<void> remove(String file) async {
    AnalysisContext context;
    try {
      context = analysisCollection.contextFor(file);
    } catch (e) {
      // its likely this file does not need to be included within analysis
      // so we can just return
      return;
    }

    _memoryProvider.deleteFile(file);

    context.changeFile(file);
  }

  /// Analyzes the given path and returns the resolved unit results.
  ///
  /// If the path is a file, it will be analyzed as a single file.
  /// If the path is a directory, it will be analyzed as a directory.
  Future<List<Units>> analyze(String path) async {
    final isFile = fs.isFileSync(path);
    final isDirectory = fs.isDirectorySync(path);

    if (!isFile && !isDirectory) {
      throw ArgumentError('Invalid path: $path');
    }

    if (isFile) {
      final context = analysisCollection.contextFor(path);
      await context.applyPendingFileChanges();

      return [await _analyzeFile(path)];
    }

    return await _analyzeDirectory(path);
  }

  Future<Units> _analyzeFile(String path) async {
    final context = analysisCollection.contextFor(path);

    return Units(context: context, path: path);
  }

  Future<List<Units>> _analyzeDirectory(String path) async {
    final results = <Units>[];
    final files = await find.file('*.dart', workingDirectory: path);

    var hasAwaited = false;
    AnalysisContext context;
    for (final file in files) {
      context = analysisCollection.contextFor(file);

      if (!hasAwaited) {
        await context.applyPendingFileChanges();
        hasAwaited = true;
      }

      final parsedUnit = context.currentSession.getParsedUnit(file);
      if (parsedUnit is! ParsedUnitResult) {
        throw ArgumentError('Could not parse file: $file');
      }

      results.add(Units(context: context, path: file));
    }

    return results;
  }

  Future<void> _createVirtualWorkspace(String workspace) async {
    final dartFiles = await find.file('*.dart', workingDirectory: workspace);

    final dartToolFiles = [
      ...await find.filesInDirectory('.dart_tool', workingDirectory: workspace),
    ];

    String? workspaceRef;
    for (final file in dartToolFiles) {
      if (fs.path.basename(file) == 'workspace_ref.json') {
        workspaceRef = file;
        break;
      }
    }

    if (workspaceRef case final String file) {
      if (jsonDecode(await fs.file(file).readAsString())
          case {
            'workspaceRoot': final String root,
          }) {
        final rootPath = fs.path.normalize(
          fs.path.join(fs.file(file).parent.path, root),
        );

        final moreDartToolFiles = await find.filesInDirectory(
          '.dart_tool',
          workingDirectory: rootPath,
          recursive: false,
          ignoreDirs: ['bin'],
        );

        dartToolFiles.addAll(moreDartToolFiles);
      }
    }

    String? packageConfig;
    for (final file in dartToolFiles) {
      if (fs.path.basename(file) == 'package_config.json') {
        packageConfig = file;
      }
    }

    if (packageConfig == null) {
      throw Exception('No package config found, run `dart pub get` first');
    }

    final dependencies = await _getDependencyFiles(packageConfig);

    final files = [...dartFiles, ...dartToolFiles, ...dependencies];

    _memoryProvider = MemoryResourceProvider();

    final futures = <Future<(String, Uint8List)>>[];

    for (final file in files) {
      futures.add(
        fs.file(file).readAsBytes().then((content) => (file, content)),
      );
    }

    final sdkFiles = await find.file('*', workingDirectory: await sdkPath);

    for (final file in sdkFiles) {
      futures.add(fs.file(file).readAsBytes().then((bytes) => (file, bytes)));
    }

    final results = await Future.wait(futures);
    for (final (path, bytes) in results) {
      _memoryProvider.newFileWithBytes(path, bytes);
    }
  }

  Future<List<String>> _getDependencyFiles(String packageConfig) async {
    final json = jsonDecode(await fs.file(packageConfig).readAsString());

    final dependencies = switch (json) {
      {'packages': final List<dynamic> packages} => packages
          .map((e) => Dependency.fromJson(e as Map<String, dynamic>))
          .toList(),
      _ => throw Exception('Invalid package config: $packageConfig'),
    };

    final directories = <String>[];
    for (final dependency in dependencies) {
      final rootUri = Uri.parse(dependency.rootUri);
      final packageUri = Uri.parse(dependency.packageUri);

      final rootPath = switch (rootUri.isAbsolute) {
        true => fs.path.normalize(fs.path.join(rootUri.path, packageUri.path)),
        false => fs.path.normalize(
            fs.path.join(
              fs.file(packageConfig).parent.path,
              rootUri.path,
              packageUri.path,
            ),
          ),
      };

      directories.add(rootPath);
    }

    final futures = <Future<List<String>>>[];
    for (final directory in directories) {
      futures.add(
        find.filesInDirectory(
          '',
          workingDirectory: directory,
          recursive: false,
        ),
      );
    }

    final results = await Future.wait(futures);

    return results.expand((e) => e).toList();
  }

  Future<List<AnalysisError>> errors(
    String root, {
    Severity? severity = Severity.error,
  }) async {
    final libFiles = await find.filesInDirectory(
      'lib',
      workingDirectory: root,
      recursive: false,
    );
    final routesFiles = await find.filesInDirectory(
      'routes',
      workingDirectory: root,
      recursive: false,
    );

    final files = [...libFiles, ...routesFiles];

    final futures = <Future<SomeErrorsResult>>[];
    AnalysisContext context;
    for (final file in files) {
      if (!fs.path.basename(file).endsWith('.dart')) {
        continue;
      }

      try {
        context = analysisCollection.contextFor(file);
      } catch (_) {
        continue;
      }
      futures.add(context.currentSession.getErrors(file));
    }

    final errors = <AnalysisError>[];
    for (final error in await Future.wait(futures)) {
      if (error case ErrorsResult(errors: final found)) {
        errors.addAll(
          switch (severity) {
            null => found,
            final sev => found.where((e) => e.severity == sev),
          },
        );
      }
    }

    return errors;
  }
}

class Dependency {
  const Dependency({
    required this.name,
    required this.rootUri,
    required this.packageUri,
  });

  factory Dependency.fromJson(Map<String, dynamic> json) {
    return Dependency(
      name: json['name'] as String,
      rootUri: json['rootUri'] as String,
      packageUri: json['packageUri'] as String,
    );
  }

  final String name;
  final String rootUri;
  final String packageUri;
}
