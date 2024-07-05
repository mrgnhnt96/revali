import 'package:revali_router/src/meta/meta_handler.dart';
import 'package:revali_router/src/meta/read_only_meta_arg.dart';

class MetaArg implements ReadOnlyMetaArg {
  const MetaArg({
    required MetaHandler direct,
    required MetaHandler inherited,
  })  : _direct = direct,
        _inherited = inherited;

  final MetaHandler _direct;
  final MetaHandler _inherited;

  /// {@macro ReadOnlyMetaArg_get}
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

  /// {@macro ReadOnlyMetaArg_has}
  @override
  bool has<T>() => _inherited.has<T>() || _direct.has<T>();

  /// {@macro ReadOnlyMetaArg_getDirect}
  @override
  List<T>? getDirect<T>() => _direct.get<T>();

  /// {@macro ReadOnlyMetaArg_hasDirect}
  @override
  bool hasDirect<T>() => _direct.has<T>();

  /// {@macro ReadOnlyMetaArg_getInherited}
  @override
  List<T>? getInherited<T>() => _inherited.get<T>();

  /// {@macro ReadOnlyMetaArg_hasInherited}
  @override
  bool hasInherited<T>() => _inherited.has<T>();

  /// Add metadata to the directly associated route.
  void add<T>(T metadata) {
    _direct.add(metadata);
  }
}
