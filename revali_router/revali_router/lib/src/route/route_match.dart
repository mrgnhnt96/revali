import 'package:equatable/equatable.dart';
import 'package:revali_router/src/route/base_route.dart';

part 'route_match.g.dart';

class RouteMatch extends Equatable {
  const RouteMatch({
    required this.route,
    required this.pathParameters,
  });

  final BaseRoute route;
  final Map<String, String> pathParameters;

  @override
  List<Object?> get props => _$props;
}
