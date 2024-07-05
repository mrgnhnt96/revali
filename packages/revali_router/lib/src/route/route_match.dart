import 'package:equatable/equatable.dart';
import 'package:revali_router/src/route/route.dart';

part 'route_match.g.dart';

class RouteMatch extends Equatable {
  const RouteMatch({
    required this.route,
    required this.pathParameters,
  });

  final Route route;
  final Map<String, String> pathParameters;

  @override
  List<Object?> get props => _$props;
}
