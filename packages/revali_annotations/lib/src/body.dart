class Body {
  const Body([this.access, this.pipe]);
  const Body.pipe(this.pipe) : access = null;

  final List<String>? access;
  final Type? pipe;
}
