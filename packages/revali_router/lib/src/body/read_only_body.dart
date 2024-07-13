import 'dart:io';

abstract class ReadOnlyBody {
  const ReadOnlyBody();

  String? get mimeType;
  int? get contentLength;
  Stream<List<int>>? read();

  bool get isFile;
  bool get isString;
  bool get isJson;
  bool get isList;
  bool get isNull;

  Map<String, dynamic> get asJson;
  String get asString;
  List<dynamic> get asList;
  File get asFile;

  Map<String, dynamic>? get maybeJson;
  String? get maybeString;
  List<dynamic>? get maybeList;
  File? get maybeFile;
}
