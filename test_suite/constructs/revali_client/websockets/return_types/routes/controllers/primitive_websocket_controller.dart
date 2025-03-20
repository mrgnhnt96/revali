import 'dart:convert';

import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('websocket/primitive')
class PrimitiveWebsocketController {
  const PrimitiveWebsocketController();

  @WebSocket(
    'data-string',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  String dataString() {
    return 'Hello world!';
  }

  @WebSocket(
    'string',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  StringContent string() {
    return const StringContent('Hello world!');
  }

  @WebSocket('stream-data-string', triggerOnConnect: true)
  Stream<String> streamDataString() async* {
    yield 'Hello world!';

    throw const CloseWebSocketException();
  }

  @WebSocket('stream-string-content', triggerOnConnect: true)
  Stream<StringContent> streamStringContent() async* {
    yield const StringContent('Hello world!');

    throw const CloseWebSocketException();
  }

  @WebSocket(
    'future-string',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<String> futureString() async {
    return 'Hello world!';
  }

  @WebSocket(
    'bool',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  bool boolean() {
    return true;
  }

  @WebSocket(
    'int',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  int integer() {
    return 1;
  }

  @WebSocket(
    'double',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  double dub() {
    return 1;
  }

  @WebSocket(
    'record',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  (String, String) record() {
    return ('hello', 'world');
  }

  @WebSocket(
    'named-record',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  ({String first, String second}) namedRecord() {
    return (first: 'hello', second: 'world');
  }

  @WebSocket(
    'partial-record',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  (String, {String? second}) partialRecord() {
    return ('hello', second: 'world');
  }

  @WebSocket(
    'list-of-records',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  List<(String, String)> listOfRecords() {
    return [('hello', 'world')];
  }

  @WebSocket(
    'list-of-strings',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  List<String> listOfStrings() {
    return ['Hello world!'];
  }

  @WebSocket(
    'list-of-maps',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  List<Map<String, dynamic>> listOfMaps() {
    return [
      {'hello': 1},
    ];
  }

  @WebSocket(
    'map-string-dynamic',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Map<String, dynamic> map() {
    return {'hello': 1};
  }

  @WebSocket(
    'map-dynamic-dynamic',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Map<dynamic, dynamic> dynamicMap() {
    return {'true': true};
  }

  @WebSocket(
    'set',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Set<String> set() {
    return {'Hello world!'};
  }

  @WebSocket('iterable', triggerOnConnect: true)
  Iterable<String> iterable() sync* {
    yield 'Hello world!';

    throw const CloseWebSocketException();
  }

  @WebSocket(
    'bytes',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  List<List<int>> bytes() {
    return [utf8.encode('Hello world!')];
  }

  @WebSocket('stream-bytes', triggerOnConnect: true)
  Stream<List<int>> streamBytes() async* {
    yield utf8.encode('Hello world!');

    throw const CloseWebSocketException();
  }
}
