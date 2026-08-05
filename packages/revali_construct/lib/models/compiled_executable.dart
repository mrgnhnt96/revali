import 'package:revali_construct/enums/arch.dart';
import 'package:revali_construct/enums/target_os.dart';

/// A native executable that `revali build` already compiled via
/// `dart compile exe --target-os --target-arch`, made available to
/// build-type constructs (e.g. `revali_docker`) so they can package it
/// without compiling anything themselves.
class CompiledExecutable {
  const CompiledExecutable({
    required this.targetOs,
    required this.targetArch,
    required this.path,
    this.debugInfoPath,
  });

  final TargetOs targetOs;
  final Arch targetArch;

  /// Absolute path to the compiled executable on disk.
  final String path;

  /// Absolute path to the split debug info file (`dart compile exe -S`),
  /// when `strip_debug_info` was requested. Never `null` unless stripping
  /// wasn't enabled for this build.
  final String? debugInfoPath;
}
