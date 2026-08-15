/// A single phase of generation.
///
/// The two are mutually exclusive by construction: `_generateIntoStaging`
/// branches on [isBuild] and runs *either* the build makers *or* the server
/// and other makers, never both. A combined `buildAndConstructs` value used to
/// exist and could not honour its name — it reported `isBuild`, so it took the
/// build branch and silently skipped every construct, which is why
/// `revali build` never regenerated the client. Running both phases is now the
/// caller's job: `revali build` generates [constructs] and then [build], in
/// that order, because the build phase compiles the server that the constructs
/// phase writes.
enum GenerateConstructType {
  build,
  constructs;

  bool get isBuild => this == GenerateConstructType.build;
  bool get isNotBuild => !isBuild;

  bool get isConstructs => this == GenerateConstructType.constructs;
  bool get isNotConstructs => !isConstructs;

  String get description {
    switch (this) {
      case GenerateConstructType.build:
        return 'Generates all build constructs';
      case GenerateConstructType.constructs:
        return 'Generates constructs without building';
    }
  }
}
