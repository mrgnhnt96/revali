// ignore_for_file: avoid_returning_this

import 'package:equatable/equatable.dart';
import 'package:revali_router/src/route/base_route.dart';

part 'route_match.g.dart';

class RouteMatch extends Equatable {
  const RouteMatch(
    this.route, {
    this.pathParameters = const {},
  });

  final BaseRoute route;
  final Map<String, List<String>> pathParameters;

  @override
  List<Object?> get props => _$props;

  RouteMatch resolvePathParameters(List<String> pathSegments) {
    if (route.isStatic) {
      return this;
    }

    final routeSegments = route.fullSegments;

    final resolved = <String, List<String>>{};

    final paramPositions = <int, (String, {bool isWildcard})>{};
    for (final (index, segment) in routeSegments.indexed) {
      if (!segment.startsWith(RegExp('[:*]'))) {
        continue;
      }

      final isWildcard = segment.startsWith('*');

      final key = segment.substring(1);
      paramPositions[index] = (
        key,
        isWildcard: isWildcard,
      );

      if (isWildcard) {
        break;
      }
    }

    for (var i = 0; i < pathSegments.length; i++) {
      final segment = pathSegments[i];

      if (paramPositions[i] case (final key, :final isWildcard)) {
        if (isWildcard) {
          resolved[key] = pathSegments.skip(i).toList();
          break;
        }

        resolved[key] = [segment];
      }
    }

    return RouteMatch(route, pathParameters: resolved);
  }
}
