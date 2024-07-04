abstract class ReadOnlyMetaArg {
  const ReadOnlyMetaArg();

  /// {@template ReadOnlyMetaArg_get}
  /// Get the metadata of type [T] if it exists.
  ///
  /// Traverses the metadata hierarchy to find the metadata of type [T]. Meaning that
  /// that parent metadata is also considered.
  ///
  /// If [T] is not found, returns `null`.
  /// {@endtemplate}
  List<T>? get<T>();

  /// {@template ReadOnlyMetaArg_has}
  /// Check if the metadata of type [T] exists.
  ///
  /// Traverses the metadata hierarchy to find the metadata of type [T]. Meaning that
  /// that parent metadata is also considered.
  ///
  /// Returns `true` if the metadata of type [T] exists, otherwise `false`.
  /// {@endtemplate}
  bool has<T>();

  /// {@template ReadOnlyMetaArg_getDirect}
  /// Get the metadata of type [T] if it exists.
  ///
  /// Only checks the direct metadata of the route.
  ///
  /// If [T] is not found, returns `null`.
  /// {@endtemplate}
  List<T>? getDirect<T>();

  /// {@template ReadOnlyMetaArg_hasDirect}
  /// Check if the metadata of type [T] exists.
  ///
  /// Only checks the direct metadata of the route.
  ///
  /// Returns `true` if the metadata of type [T] exists, otherwise `false`.
  /// {@endtemplate}
  bool hasDirect<T>();

  /// {@template ReadOnlyMetaArg_getInherited}
  /// Get the metadata of type [T] if it exists.
  ///
  /// Only checks the inherited metadata of the route.
  ///
  /// If [T] is not found, returns `null`.
  /// {@endtemplate}
  List<T>? getInherited<T>();

  /// {@template ReadOnlyMetaArg_hasInherited}
  /// Check if the metadata of type [T] exists.
  ///
  /// Only checks the inherited metadata of the route.
  ///
  /// Returns `true` if the metadata of type [T] exists, otherwise `false`.
  /// {@endtemplate}
  bool hasInherited<T>();
}
