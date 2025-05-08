import 'dart:convert';

import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('literals')
class LiteralsController {
  const LiteralsController();

  @SSE('void')
  void voidCall() {}

  @SSE('data-string')
  String dataString() {
    return 'Hello world!';
  }

  @SSE('string')
  StringContent string() {
    return const StringContent('Hello world!');
  }

  @SSE('bool')
  bool boolean() {
    return true;
  }

  @SSE('int')
  int integer() {
    return 1;
  }

  @SSE('double')
  double dub() {
    return 1;
  }

  @SSE('record')
  (String, String) record() {
    return ('hello', 'world');
  }

  @SSE('named-record')
  ({String first, String second}) namedRecord() {
    return (first: 'hello', second: 'world');
  }

  @SSE('partial-record')
  (String, {String? second}) partialRecord() {
    return ('hello', second: 'world');
  }

  @SSE('list-of-records')
  List<(String, String)> listOfRecords() {
    return [('hello', 'world')];
  }

  @SSE('list-of-strings')
  List<String> listOfStrings() {
    return ['Hello world!'];
  }

  @SSE('list-of-maps')
  List<Map<String, dynamic>> listOfMaps() {
    return [
      {'hello': 1},
    ];
  }

  @SSE('map-string-dynamic')
  Map<String, dynamic> map() {
    return {'hello': 1};
  }

  @SSE('map-dynamic-dynamic')
  Map<dynamic, dynamic> dynamicMap() {
    return {'true': true};
  }

  @SSE('set')
  Set<String> set() {
    return {'Hello world!'};
  }

  @SSE('iterable')
  Iterable<String> iterable() sync* {
    yield 'Hello world!';
  }

  @SSE('bytes')
  List<int> bytes() {
    return utf8.encode('Hello world!');
  }
}
