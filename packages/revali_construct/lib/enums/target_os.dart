import 'dart:io';

/// A `dart compile exe` target operating system.
enum TargetOs {
  linux,
  macos,
  windows;

  static TargetOs current() {
    return switch (Platform.operatingSystem) {
      'linux' => TargetOs.linux,
      'macos' => TargetOs.macos,
      'windows' => TargetOs.windows,
      _ => throw UnsupportedError(
        'Unsupported platform: ${Platform.operatingSystem}',
      ),
    };
  }

  static TargetOs? fromName(String? name) {
    for (final value in TargetOs.values) {
      if (value.name == name) return value;
    }

    return null;
  }

  /// Whether the current host can compile for [targetOs] via
  /// `dart compile exe --target-os`. Linux is compilable from any host;
  /// macOS and Windows targets require running natively on that OS.
  bool canCompile(TargetOs targetOs) {
    return switch ((targetOs, this)) {
      (TargetOs.linux, _) => true,
      (TargetOs.macos, TargetOs.macos) => true,
      (TargetOs.windows, TargetOs.windows) => true,
      _ => false,
    };
  }
}
