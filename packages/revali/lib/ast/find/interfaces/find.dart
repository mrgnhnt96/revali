abstract interface class Find {
  Future<List<String>> file(
    String name, {
    required String workingDirectory,
    List<String> ignoreDirs,
  });

  Future<List<String>> filesInDirectory(
    String directory, {
    required String workingDirectory,
    List<String> ignoreDirs,
    bool recursive = true,
  });
}
