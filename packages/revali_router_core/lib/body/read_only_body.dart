import 'package:revali_router_core/headers/read_only_headers.dart';

abstract class ReadOnlyBody {
  const ReadOnlyBody();

  dynamic get data;

  String? get mimeType;
  int? get contentLength;
  Stream<List<int>>? read();

  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders);

  bool get isNull;
}
