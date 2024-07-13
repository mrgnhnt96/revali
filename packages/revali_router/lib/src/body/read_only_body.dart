import 'package:revali_router/utils/types.dart';

abstract class ReadOnlyBody {
  const ReadOnlyBody();

  String? get mimeType;
  int? get contentLength;
  Stream<List<int>>? read();

  bool get isBinary;
  bool get isString;
  bool get isJson;
  bool get isList;
  bool get isNull;

  Map<String, dynamic> get asJson;
  String get asString;
  List<dynamic> get asList;
  Binary get asBinary;

  Map<String, dynamic>? get maybeJson;
  String? get maybeString;
  List<dynamic>? get maybeList;
  Binary? get maybeBinary;
}
