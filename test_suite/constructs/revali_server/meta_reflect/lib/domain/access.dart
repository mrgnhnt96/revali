import 'package:revali_router/revali_router.dart';

class Access implements MetaData {
  const Access(this.type);

  final AccessType type;
}

enum AccessType { public, private }
