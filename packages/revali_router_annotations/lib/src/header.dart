class Header {
  const Header([this.access, this.pipe]);
  const Header.pipe(this.pipe) : access = null;

  final String? access;
  final Type? pipe;
}
