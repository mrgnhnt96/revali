enum Mode {
  release,
  debug;

  bool get isRelease => this == Mode.release;
  bool get isDebug => this == Mode.debug;
}
