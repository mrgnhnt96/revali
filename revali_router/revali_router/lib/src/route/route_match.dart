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

    for (final (index, segment) in routeSegments.indexed) {
      if (segment.startsWith('*')) {
        final key = segment == '*' ? '*' : segment.substring(1);
        resolved[key] = pathSegments.skip(index).toList();
        break;
      }

      if (segment.startsWith(':') && index < pathSegments.length) {
        resolved[segment.substring(1)] = [pathSegments[index]];
      }
    }

    return RouteMatch(route, pathParameters: resolved);
  }
}
