import 'dart:convert';

import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('stream')
class StreamController {
  const StreamController();

  @WebSocket(
    'data-string',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<String> dataString() async* {
    yield 'Hello';
    yield 'world';

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket('string', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<StringContent> string() async* {
    yield const StringContent('Hello');
    yield const StringContent('world');

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket('bool', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<bool> boolean() async* {
    yield true;
    yield false;

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket('int', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<int> integer() async* {
    yield 1;
    yield 2;

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket('double', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<double> dub() async* {
    yield 1.0;
    yield 2.0;

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket('record', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<(String, String)> record() async* {
    yield ('hello', 'world');
    yield ('foo', 'bar');

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket(
    'named-record',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<({String first, String second})> namedRecord() async* {
    yield (first: 'hello', second: 'world');
    yield (first: 'foo', second: 'bar');

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket(
    'partial-record',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<(String, {String? second})> partialRecord() async* {
    yield ('hello', second: 'world');
    yield ('foo', second: 'bar');

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket(
    'list-of-records',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<List<(String, String)>> listOfRecords() async* {
    yield [('hello', 'world')];
    yield [('foo', 'bar')];

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket(
    'list-of-strings',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<List<String>> listOfStrings() async* {
    yield ['Hello'];
    yield ['world'];

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket(
    'list-of-maps',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<List<Map<String, dynamic>>> listOfMaps() async* {
    yield [
      {'hello': 1},
    ];
    yield [
      {'foo': 2},
    ];

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket(
    'map-string-dynamic',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<Map<String, dynamic>> map() async* {
    yield {'hello': 1};
    yield {'foo': 2};

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket(
    'map-dynamic-dynamic',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<Map<dynamic, dynamic>> dynamicMap() async* {
    yield {'true': true};
    yield {'false': false};

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket('set', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<Set<String>> set() async* {
    yield {'Hello'};
    yield {'world'};

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket('iterable', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<Iterable<String>> iterable() async* {
    yield ['Hello'];
    yield ['world'];

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }

  @WebSocket('bytes', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<List<int>> bytes() async* {
    yield utf8.encode('Hello');
    yield utf8.encode('world');

    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      throw const CloseWebSocketException();
    }).ignore();
  }
}
