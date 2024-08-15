import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/models/options.dart';
import 'package:revali_server/revali_server.construct.dart';

Construct serverConstruct([ConstructOptions? option]) {
  final options = Options.fromJson(option?.values);

  return RevaliServerConstruct(options);
}
