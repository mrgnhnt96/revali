import 'dart:convert';

import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('websocket/primitive')
class PrimitiveWebsocketController {
  const PrimitiveWebsocketController();

  @WebSocket('data-string')
  String dataString() {
    return 'Hello world!';
  }

  @WebSocket('string')
  StringContent string() {
    return const StringContent('Hello world!');
  }

  @WebSocket('stream-string')
  Stream<String> streamString() async* {
    yield 'Hello world!';
  }

  @WebSocket('stream-string-content')
  Stream<StringContent> streamStringContent() async* {
    yield const StringContent('Hello world!');
  }

  @WebSocket('future-string')
  Future<String> futureString() async {
    return 'Hello world!';
  }

  @WebSocket('bool')
  bool boolean() {
    return true;
  }

  @WebSocket('int')
  int integer() {
    return 1;
  }

  @WebSocket('double')
  double dub() {
    return 1;
  }

  @WebSocket('record')
  (String, String) record() {
    return ('hello', 'world');
  }

  @WebSocket('named-record')
  ({String first, String second}) namedRecord() {
    return (first: 'hello', second: 'world');
  }

  @WebSocket('partial-record')
  (String, {String? second}) partialRecord() {
    return ('hello', second: 'world');
  }

  @WebSocket('list-of-records')
  List<(String, String)> listOfRecords() {
    return [('hello', 'world')];
  }

  @WebSocket('list-of-strings')
  List<String> listOfStrings() {
    return ['Hello world!'];
  }

  @WebSocket('list-of-maps')
  List<Map<String, dynamic>> listOfMaps() {
    return [
      {'hello': 1},
    ];
  }

  @WebSocket('map-string-dynamic')
  Map<String, dynamic> map() {
    return {'hello': 1};
  }

  @WebSocket('map-dynamic-dynamic')
  Map<dynamic, dynamic> dynamicMap() {
    return {'true': true};
  }

  @WebSocket('set')
  Set<String> set() {
    return {'Hello world!'};
  }

  @WebSocket('iterable')
  Iterable<String> iterable() sync* {
    yield 'Hello world!';
  }

  @WebSocket('stream-data-string')
  Stream<String> stream() async* {
    yield 'Hello world!';
  }

  @WebSocket('bytes')
  List<List<int>> bytes() {
    return [utf8.encode('Hello world!')];
  }

  @WebSocket('stream-bytes')
  Stream<List<int>> streamBytes() async* {
    yield utf8.encode('Hello world!');
  }
}
