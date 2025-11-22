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

  String? _packageConfig;
  DateTime? _retrievedDependenciesAt;
  String? _root;

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

  /// Reloads the analyzer.
  ///
  /// This is only needed to be called when a dependency has changed. The
  /// analyzer groups packages into their own contexts. Because of this,
  /// dependencies are only resolved and cached when the analyzer is
  /// initialized.
  ///
  /// This is relatively expensive, so it should only be called when necessary.
  Future<void> reload() async {
    final dependencies = switch (_packageConfig) {
      final String packageConfig => await _getDependencyFiles(
        packageConfig,
        pathDependenciesOnly: true,
        directoryOnly: true,
      ),
      null => <String>[],
    };

    final root = _root;
    if (root == null) {
      throw Exception('No root found');
    }

    await refreshDependencies();

    final old = _analysisCollection;

    _analysisCollection = AnalysisContextCollection(
      includedPaths: [root, ...dependencies],
      resourceProvider: _memoryProvider,
      sdkPath: await sdkPath,
    );

    await old?.dispose();
  }

  Future<void> initialize({required String root}) async {
    if (_isInitialized) {
      return;
    }

    _root = root;

    try {
      await _createVirtualWorkspace(root);

      final dependencies = switch (_packageConfig) {
        final String packageConfig => await _getDependencyFiles(
          packageConfig,
          pathDependenciesOnly: true,
          directoryOnly: true,
        ),
        null => <String>[],
      };

      _analysisCollection = AnalysisContextCollection(
        includedPaths: [root, ...dependencies],
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
  Future<void> refresh(List<String> files) async {
    var requiresDependencyRefresh = false;

    AnalysisContext? context;
    for (final file in files) {
      if (!fs.file(file).existsSync()) {
        continue;
      }

      final bytes = await fs.file(file).readAsBytes();
      _memoryProvider.newFileWithBytes(file, bytes);

      if (requiresDependencyRefresh case false) {
        requiresDependencyRefresh = switch (_root) {
          final String root => !fs.path.isWithin(root, file),
          null => false,
        };
      }

      try {
        context = analysisCollection.contextFor(file)..changeFile(file);
        await context.applyPendingFileChanges();
      } catch (e) {
        // its likely this file does not need to be included within analysis
      }
    }

    if (requiresDependencyRefresh) {
      await reload();
    }
  }

  Future<void> refreshDependencies() async {
    final packageConfig = _packageConfig;

    if (packageConfig == null) {
      return;
    }

    final dependencies = await _getDependencyFiles(
      packageConfig,
      lastModified: _retrievedDependenciesAt,
      pathDependenciesOnly: true,
    );
    _retrievedDependenciesAt = DateTime.now();

    final pendingChanges = <Future<void>>[];

    AnalysisContext? context;
    for (final path in dependencies) {
      final file = fs.file(path);
      final bytes = switch (await file.exists()) {
        true => await file.readAsBytes(),
        false => null,
      };

      if (bytes == null) {
        _memoryProvider.deleteFile(path);
      } else {
        _memoryProvider.newFileWithBytes(path, bytes);
      }

      try {
        context = analysisCollection.contextFor(path)..changeFile(path);

        pendingChanges.add(context.applyPendingFileChanges());
      } catch (e) {
        continue;
      }
    }

    await Future.wait(pendingChanges);
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

    await refreshDependencies();
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

    AnalysisContext context;
    for (final file in files) {
      context = analysisCollection.contextFor(file);

      final parsedUnit = context.currentSession.getParsedUnit(file);
      if (parsedUnit is! ParsedUnitResult) {
        throw ArgumentError('Could not parse file: $file');
      }

      results.add(Units(context: context, path: file));
    }

    return results;
  }

  Future<String?> _getPackageConfig(List<String> dartToolFiles) async {
    String? workspaceRef;
    for (final file in dartToolFiles) {
      if (fs.path.basename(file) == 'workspace_ref.json') {
        workspaceRef = file;
        break;
      }
    }

    if (workspaceRef case final String file) {
      if (jsonDecode(await fs.file(file).readAsString()) case {
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

    return packageConfig;
  }

  Future<void> _createVirtualWorkspace(String workspace) async {
    // Reset the last retrieved dependencies at to null
    // so that we can retrieve ALL the dependencies again
    // if the dependencies have changed
    _retrievedDependenciesAt = null;

    final dartFiles = await find.file('*.dart', workingDirectory: workspace);

    final dartToolFiles = [
      ...await find.filesInDirectory('.dart_tool', workingDirectory: workspace),
    ];

    final packageConfig = _packageConfig ??= await _getPackageConfig(
      dartToolFiles,
    );

    if (packageConfig == null) {
      throw Exception('No package config found, run `dart pub get` first');
    }

    final dependencies = await _getDependencyFiles(
      packageConfig,
      lastModified: _retrievedDependenciesAt,
    );
    _retrievedDependenciesAt = DateTime.now();

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

  Future<List<String>> _getDependencyFiles(
    String packageConfig, {
    bool directoryOnly = false,
    bool pathDependenciesOnly = false,
    DateTime? lastModified,
  }) async {
    final json = jsonDecode(await fs.file(packageConfig).readAsString());

    final dependencies = switch (json) {
      {'packages': final List<dynamic> packages} =>
        packages
            .map((e) => Dependency.fromJson(e as Map<String, dynamic>))
            .toList(),
      _ => throw Exception('Invalid package config: $packageConfig'),
    };

    final directories = <String>[];
    for (final dependency in dependencies) {
      final rootUri = Uri.parse(dependency.rootUri);
      final packageUri = Uri.parse(dependency.packageUri);

      if (pathDependenciesOnly) {
        if (fs.path.split(rootUri.path) case final segments
            when segments.contains('hosted') ||
                segments.contains('git') ||
                segments.contains('pkg')) {
          continue;
        }
      }

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

    if (directoryOnly) {
      return directories.map((e) => fs.directory(e).parent.path).toList();
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

    final errors = await _errorsFor(files);

    return errors;
  }

  Future<List<AnalysisError>> _errorsFor(
    List<String> files, {
    Severity? severity = Severity.error,
  }) async {
    final futures = <Future<SomeErrorsResult?>>[];
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
      futures.add(() async {
        try {
          return await context.currentSession.getErrors(file);
        } catch (_) {
          return null;
        }
      }());
    }

    final errors = <AnalysisError>[];
    for (final error in await Future.wait(futures)) {
      if (error case ErrorsResult(errors: final found)) {
        errors.addAll(switch (severity) {
          null => found,
          final sev => found.where((e) => e.severity == sev),
        });
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
