class Redirect {
  const Redirect(this.path, [this.code = 301]);

  final String path;
  final int code;
}
