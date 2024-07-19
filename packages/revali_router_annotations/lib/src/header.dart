class Header {
  const Header([this.name, this.pipe]);
  const Header.pipe(this.pipe) : name = null;

  final String? name;
  final Type? pipe;
}
