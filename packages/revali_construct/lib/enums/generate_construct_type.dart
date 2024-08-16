enum GenerateConstructType {
  build,
  constructs,
  buildAndConstructs;

  bool get isBuild =>
      this == GenerateConstructType.build ||
      this == GenerateConstructType.buildAndConstructs;
  bool get isNotBuild => !isBuild;

  bool get isConstructs =>
      this == GenerateConstructType.constructs ||
      this == GenerateConstructType.buildAndConstructs;
  bool get isNotConstructs => !isConstructs;

  String get description {
    switch (this) {
      case GenerateConstructType.build:
        return 'Generates all build constructs';
      case GenerateConstructType.constructs:
        return 'Generates constructs without building';
      case GenerateConstructType.buildAndConstructs:
        return 'Generates all, including build, constructs';
    }
  }
}
