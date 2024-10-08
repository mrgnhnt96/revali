import 'package:revali_construct/models/construct.dart';
import 'package:revali_construct/models/construct_options.dart';

class ConstructMaker {
  const ConstructMaker({
    required this.package,
    required this.isServer,
    required this.isBuild,
    required this.name,
    required this.maker,
  });

  final String package;
  final bool isServer;
  final bool isBuild;
  final String name;
  final Construct<dynamic> Function(ConstructOptions) maker;
}
