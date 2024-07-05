class Redirect {
  const Redirect(this.path, {this.statusCode = 301});

  final String path;
  final int statusCode;
}
