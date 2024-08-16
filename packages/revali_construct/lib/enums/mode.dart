enum Mode {
  release,
  debug,
  profile;

  bool get isRelease => this == Mode.release;
  bool get isDebug => this == Mode.debug;
  bool get isProfile => this == Mode.profile;

  bool get isNotRelease => this != Mode.release;

  String get flag {
    return switch (this) {
      Mode.release => 'release',
      Mode.debug => 'debug',
      Mode.profile => 'profile',
    };
  }
}
