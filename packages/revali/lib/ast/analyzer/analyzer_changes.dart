abstract interface class AnalyzerChanges {
  Future<void> refresh(String file);
  Future<void> remove(String file);
}
