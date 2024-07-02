class Query {
  const Query([this.name, this.pipe]);
  const Query.pipe(this.pipe) : name = null;

  final String? name;
  final Type? pipe;
}
