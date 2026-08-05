import 'dart:ffi';

/// A `dart compile exe --target-arch` value.
enum Arch {
  arm,
  arm64,
  ia32,
  riscv32,
  riscv64,
  x64;

  static Arch current() {
    return switch (Abi.current()) {
      Abi.macosX64 => Arch.x64,
      Abi.macosArm64 => Arch.arm64,
      Abi.windowsX64 => Arch.x64,
      Abi.windowsArm64 => Arch.arm64,
      Abi.linuxX64 => Arch.x64,
      Abi.linuxArm64 => Arch.arm64,
      Abi.linuxArm => Arch.arm,
      Abi.linuxRiscv32 => Arch.riscv32,
      Abi.linuxRiscv64 => Arch.riscv64,
      _ => throw UnsupportedError('Unsupported architecture: ${Abi.current()}'),
    };
  }

  static Arch? fromName(String? name) {
    for (final value in Arch.values) {
      if (value.name == name) return value;
    }

    return null;
  }
}
