extension TypeX on Type {
  String get name => '$this'.split('<').first;
}
