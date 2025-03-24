import 'package:revali_server/converters/server_type.dart';

bool shouldNestJsonInData(ServerType type) {
  if (type case ServerType(typeArguments: [final type])) {
    return shouldNestJsonInData(type);
  }

  if (type case ServerType(isBytes: true)) {
    return false;
  }

  if (type.isStringContent) {
    return false;
  }

  return true;
}
