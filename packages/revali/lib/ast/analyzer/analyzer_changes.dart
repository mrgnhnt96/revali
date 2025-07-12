abstract interface class AnalyzerChanges {
  Future<void> refresh(List<String> files);
  Future<void> remove(String file);
}
