import 'dart:math';

import 'package:collection/collection.dart';
import 'package:server_client_gen/enums/parameter_position.dart';
import 'package:server_client_gen/models/client_param.dart';

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
  bool needsAssignment(ClientParam param, [List<List<String>>? existingRoots]) {
    final roots = existingRoots ?? this.roots();

    if (roots.isEmpty && isNotEmpty) {
      return param.access.isEmpty;
    }

    bool isWithin(Iterable<String> roots, Iterable<String> access) {
      if (roots.isEmpty && access.isEmpty) {
        return true;
      }

      if (roots.isEmpty) {
        return false;
      }

      if (access.isEmpty) {
        return true;
      }

      if (roots.first == access.first) {
        return isWithin(roots.skip(1), access.skip(1));
      }

      return false;
    }

    for (final r in roots) {
      if (isWithin(r, param.access)) {
        return true;
      }
    }

    return false;
  }

  List<List<String>> roots() {
    final paths = <String, Iterable<String>>{};

    if (where((e) => e.access.isEmpty) case final items when items.isNotEmpty) {
      if (items.length == 1) {
        return [];
      }

      if (items.length > 1) {
        if (!items.every((e) => e.type == items.first.type)) {
          throw Exception('Cannot have multiple roots with different types');
        }

        return [];
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

    final sorted = toList().sortedBy<num>((e) => e.access.length).toList();

    for (final e in sorted) {
      final access = e.access;
      if (access.isEmpty) {
        continue;
      }

      if (paths.isEmpty) {
        paths[access.first] = access.skip(1);
        continue;
      }

      if (paths[access.first] case final segments?) {
        if (segments.isEmpty) {
          continue;
        }

        var shouldAdd = true;
        for (final (index, segment) in segments.indexed) {
          if (access.length <= index) {
            shouldAdd = false;
            break;
          }

          if (access[index] != segment) {
            shouldAdd = false;
            break;
          }
        }

        if (!shouldAdd) {
          continue;
        }
      }

      paths[access.first] = access.skip(1);
    }

    Iterable<List<String>> roots() sync* {
      for (final MapEntry(:key, :value) in paths.entries) {
        yield [key, ...value];
      }
    }

    return roots().toList();
  }
}
