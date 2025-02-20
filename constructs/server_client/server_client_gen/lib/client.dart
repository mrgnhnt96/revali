import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/models/settings.dart';
import 'package:server_client_gen/src/client_construct.dart';

Construct clientConstruct([ConstructOptions? options]) {
  final settings = Settings.fromJson(options?.values ?? {});
  return ServerClient(settings);
}
