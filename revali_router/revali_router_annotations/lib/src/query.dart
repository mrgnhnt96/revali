class Query {
  const Query([this.name, this.pipe]) : all = false;
  const Query.pipe(this.pipe)
      : name = null,
        all = false;
  const Query.all([this.name, this.pipe]) : all = true;
  const Query.allPipe(this.pipe)
      : name = null,
        all = true;

  final String? name;
  final Type? pipe;
  final bool all;
}
