class Header {
  const Header([this.name, this.pipe]) : all = false;
  const Header.pipe(this.pipe)
      : name = null,
        all = false;
  const Header.all([this.name, this.pipe]) : all = true;
  const Header.allPipe(this.pipe)
      : name = null,
        all = true;

  final String? name;
  final Type? pipe;
  final bool all;
}
