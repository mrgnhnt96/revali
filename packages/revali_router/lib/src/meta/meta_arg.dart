import 'package:revali_router/src/meta/meta_handler.dart';

class MetaArg {
  const MetaArg({
    required MetaHandler direct,
    required MetaHandler inherited,
  })  : _direct = direct,
        _inherited = inherited;

  final MetaHandler _direct;
  final MetaHandler _inherited;

  /// Get the metadata of type [T] if it exists.
  ///
  /// Traverses the metadata hierarchy to find the metadata of type [T]. Meaning that
  /// that parent metadata is also considered.
  ///
  /// If [T] is not found, returns `null`.
  List<T>? get<T>() {
    final inherited = _inherited.get<T>();
    final direct = _direct.get<T>();

    if (inherited == null && direct == null) {
      return null;
    }

    return [
      ...?inherited,
      ...?direct,
    ];
  }

  /// Check if the metadata of type [T] exists.
  ///
  /// Traverses the metadata hierarchy to find the metadata of type [T]. Meaning that
  /// that parent metadata is also considered.
  ///
  /// Returns `true` if the metadata of type [T] exists, otherwise `false`.
  bool has<T>() => _inherited.has<T>() || _direct.has<T>();

  /// Get the metadata of type [T] if it exists.
  ///
  /// Only checks the direct metadata of the route.
  ///
  /// If [T] is not found, returns `null`.
  List<T>? getDirect<T>() => _direct.get<T>();

  /// Check if the metadata of type [T] exists.
  ///
  /// Only checks the direct metadata of the route.
  ///
  /// Returns `true` if the metadata of type [T] exists, otherwise `false`.
  bool hasDirect<T>() => _direct.has<T>();

  /// Get the metadata of type [T] if it exists.
  ///
  /// Only checks the inherited metadata of the route.
  ///
  /// If [T] is not found, returns `null`.
  List<T>? getInherited<T>() => _inherited.get<T>();

  /// Check if the metadata of type [T] exists.
  ///
  /// Only checks the inherited metadata of the route.
  ///
  /// Returns `true` if the metadata of type [T] exists, otherwise `false`.
  bool hasInherited<T>() => _inherited.has<T>();

  /// Add metadata to the directly associated route.
  void add<T>(T metadata) {
    _direct.register(metadata);
  }
}
