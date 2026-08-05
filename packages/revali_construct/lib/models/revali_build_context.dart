import 'package:revali_construct/models/compiled_executable.dart';
import 'package:revali_construct/models/revali_context.dart';

class RevaliBuildContext extends RevaliContext {
  const RevaliBuildContext({
    required super.flavor,
    required super.mode,
    required this.defines,
    this.compiledExecutables = const [],
  });

  final Map<String, String> defines;

  /// Executables `revali build` already compiled for this build, if any
  /// `target_os`/`target_arch` was requested via the `build:` section of
  /// `revali.yaml`. Empty when no compilation was requested.
  final List<CompiledExecutable> compiledExecutables;
}
