import 'dart:convert';

import 'package:revali_router_core/revali_router_core.dart';

abstract base class BodyParser {
  const BodyParser(this.mimeType);

  final String mimeType;

  Future<BodyData> parse(
    Encoding encoding,
    Stream<List<int>> data,
    ReadOnlyHeaders headers,
  );
}
