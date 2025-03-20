import 'package:revali_server/converters/server_type.dart';

bool shouldNestJsonInData(ServerType returnType) {
  final type = switch (returnType) {
    ServerType(typeArguments: [final type]) => type,
    _ => returnType,
  };

  if (type case ServerType(isBytes: true)) {
    return false;
  }

  if (type.isStringContent) {
    return false;
  }

  return true;
}
