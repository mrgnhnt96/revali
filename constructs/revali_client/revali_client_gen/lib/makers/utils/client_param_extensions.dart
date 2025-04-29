import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:revali_client_gen/enums/parameter_position.dart';
import 'package:revali_client_gen/models/client_param.dart';

extension IterableClientParamX on Iterable<ClientParam> {
  ({
    List<ClientParam> body,
    List<ClientParam> query,
    List<ClientParam> headers,
    List<ClientParam> cookies,
  }) get separate {
    final cookieParams = <ClientParam>[];
    final queryParams = <ClientParam>[];
    final bodyParams = <ClientParam>[];
    final headerParams = <ClientParam>[];

    for (final param in this) {
      switch (param.position) {
        case ParameterPosition.cookie:
          cookieParams.add(param);
        case ParameterPosition.query:
          queryParams.add(param);
        case ParameterPosition.body:
          bodyParams.add(param);
        case ParameterPosition.header:
          headerParams.add(param);
      }
    }

    return (
      cookies: cookieParams,
      body: bodyParams,
      query: queryParams,
      headers: headerParams,
    );
  }

  /// If a param is found within an existing map, it
  /// does not need to be assigned
  ///
  /// ```json
  /// // payload
  /// {
  ///   "data": {
  ///     "name": "John",
  ///     "email": "some@email.com"
  ///   }
  /// }
  /// ```
  ///
  /// If `access: [data, email]` were passed in to the [param]
  /// then it would not need to be assigned
  bool needsAssignment(ClientParam param, [RecursiveMap? existingRoots]) {
    final roots = existingRoots ?? this.roots();

    if (roots.isEmpty && isNotEmpty) {
      return param.access.isEmpty;
    }

    RecursiveMap? current = roots;
    for (final (index, segment) in param.access.indexed) {
      if (current?[segment] == null) {
        if (index == 0) {
          // this root does not exist, so it does not need to be assigned
          return false;
        }

        return current?.keys.isNotEmpty ?? false;
      }

      current = current?[segment];
    }

    return true;
  }

  RecursiveMap roots() {
    if (where((e) => e.access.isEmpty) case final items when items.isNotEmpty) {
      if (items.length == 1) {
        return RecursiveMap();
      }

      if (items.length > 1) {
        if (!items.every((e) => e.type == items.first.type)) {
          throw Exception('Cannot have multiple roots with different types');
        }

        return RecursiveMap();
      }
    }

    final uniquePathsToTypes = <String, String>{};
    for (final e in this) {
      if (e.access.isEmpty) {
        continue;
      }

      if (uniquePathsToTypes[e.access.join('.')] case final type?) {
        if (type != e.type.name) {
          throw Exception('Cannot have multiple roots with different types');
        }
      }

      uniquePathsToTypes[e.access.join('.')] = e.type.name;
    }

    final roots = RecursiveMap();
    if (isEmpty) return roots;

    final sorted = toList().sortedBy<num>((e) => e.access.length).toList();

    final maxLength = sorted.first.access.length;
    var skip = 0;
    for (final ClientParam(:access) in sorted) {
      if (access.length != maxLength) {
        break;
      }

      roots[access.first] = access.skip(1);

      skip++;
    }

    for (final ClientParam(:access) in sorted.skip(skip)) {
      RecursiveMap? current = roots;
      for (final (index, segment) in access.indexed) {
        if (current?[segment] == null) {
          if (index == 0) {
            current?[segment] = access.skip(1);
            break;
          } else {
            break;
          }
        }

        current?[segment] = null;
        current = current?[segment];
      }
    }

    return roots;
  }
}

class RecursiveMap with MapMixin<String, RecursiveMap?> {
  RecursiveMap([Map<String, RecursiveMap>? map]) {
    if (map != null) {
      _map.addAll(map);
    }
  }

  final _map = <String, RecursiveMap>{};

  @override
  void operator []=(String key, dynamic value) {
    _map[key] ??= RecursiveMap();

    switch (value) {
      case String():
        (_map[key] ??= RecursiveMap())[value] = null;
      case Iterable<String>():
        var k = key;
        for (final v in value) {
          (_map[k] ??= RecursiveMap())[v] = null;
          k = v;
        }
      case null:
        _map[key] ??= RecursiveMap();
      default:
        throw Exception('Invalid value type');
    }
  }

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;

  @override
  RecursiveMap? operator [](Object? key) {
    if (_map.containsKey(key)) {
      return _map[key] ?? RecursiveMap();
    }

    return null;
  }

  @override
  void clear() {
    _map.clear();
  }

  @override
  Iterable<String> get keys => _map.keys;

  @override
  RecursiveMap? remove(Object? key) {
    return _map.remove(key);
  }
}
