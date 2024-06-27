import 'package:zora_construct/models/construct.dart';
import 'package:zora_construct/models/construct_options.dart';

class ConstructMaker {
  const ConstructMaker({
    required this.package,
    required this.isRouter,
    required this.name,
    required this.maker,
  });

  final String package;
  final bool isRouter;
  final String name;
  final Construct Function(ConstructOptions) maker;
}
