class Param {
  const Param([this.name, this.pipe]);
  const Param.pipe(this.pipe) : name = null;

  final String? name;
  final Type? pipe;
}
