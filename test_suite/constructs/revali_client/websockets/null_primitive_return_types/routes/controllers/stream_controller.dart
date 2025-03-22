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
  Stream<String?> dataString() async* {
    yield null;
    yield null;
  }

  @WebSocket('string', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<StringContent?> string() async* {
    yield null;
    yield null;
  }

  @WebSocket('bool', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<bool?> boolean() async* {
    yield null;
    yield null;
  }

  @WebSocket('int', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<int?> integer() async* {
    yield null;
    yield null;
  }

  @WebSocket('double', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<double?> dub() async* {
    yield null;
    yield null;
  }

  @WebSocket('record', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<(String?, String?)?> record() async* {
    yield null;
    yield null;
  }

  @WebSocket(
    'named-record',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<({String? first, String? second})?> namedRecord() async* {
    yield null;
    yield null;
  }

  @WebSocket(
    'partial-record',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<(String?, {String? second})?> partialRecord() async* {
    yield null;
    yield null;
  }

  @WebSocket(
    'list-of-records',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<List<(String?, String?)>?> listOfRecords() async* {
    yield null;
    yield null;
  }

  @WebSocket(
    'list-of-strings',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<List<String?>?> listOfStrings() async* {
    yield null;
    yield null;
  }

  @WebSocket(
    'list-of-maps',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<List<Map<String?, dynamic>?>?> listOfMaps() async* {
    yield null;
    yield null;
  }

  @WebSocket(
    'map-string-dynamic',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<Map<String?, dynamic>?> map() async* {
    yield null;
    yield null;
  }

  @WebSocket(
    'map-dynamic-dynamic',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<Map<dynamic, dynamic>?> dynamicMap() async* {
    yield null;
    yield null;
  }

  @WebSocket(
    'map-dynamic-dynamic-with-null',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Stream<Map<dynamic, dynamic>?> dynamicMapWithNull() async* {
    yield {'foo': null};
    yield {'bar': null};
  }

  @WebSocket('set', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<Set<String?>?> set() async* {
    yield null;
    yield null;
  }

  @WebSocket('iterable', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<Iterable<String?>?> iterable() async* {
    yield null;
    yield null;
  }

  @WebSocket('bytes', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Stream<List<int>?> bytes() async* {
    yield null;
    yield null;
  }
}
