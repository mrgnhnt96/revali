import 'dart:convert';

import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('future')
class FutureController {
  const FutureController();

  @WebSocket('void', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<void> voidCall() async {}

  @WebSocket(
    'data-string',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<String> dataString() async {
    return 'Hello world!';
  }

  @WebSocket('string', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<StringContent> string() async {
    return const StringContent('Hello world!');
  }

  @WebSocket('bool', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<bool> boolean() async {
    return true;
  }

  @WebSocket('int', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<int> integer() async {
    return 1;
  }

  @WebSocket('double', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<double> dub() async {
    return 1;
  }

  @WebSocket('record', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<(String, String)> record() async {
    return ('hello', 'world');
  }

  @WebSocket(
    'named-record',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<({String first, String second})> namedRecord() async {
    return (first: 'hello', second: 'world');
  }

  @WebSocket(
    'partial-record',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<(String, {String? second})> partialRecord() async {
    return ('hello', second: 'world');
  }

  @WebSocket(
    'list-of-records',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<List<(String, String)>> listOfRecords() async {
    return [('hello', 'world')];
  }

  @WebSocket(
    'list-of-strings',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<List<String>> listOfStrings() async {
    return ['Hello world!'];
  }

  @WebSocket(
    'list-of-maps',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<List<Map<String, dynamic>>> listOfMaps() async {
    return [
      {'hello': 1},
    ];
  }

  @WebSocket(
    'map-string-dynamic',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<Map<String, dynamic>> map() async {
    return {'hello': 1};
  }

  @WebSocket(
    'map-dynamic-dynamic',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<Map<dynamic, dynamic>> dynamicMap() async {
    return {'true': true};
  }

  @WebSocket('set', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<Set<String>> set() async {
    return {'Hello world!'};
  }

  @WebSocket('iterable', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<Iterable<String>> iterable() async {
    return ['Hello world!'];
  }

  @WebSocket('bytes', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<List<List<int>>> bytes() async {
    return [utf8.encode('Hello world!')];
  }
}
