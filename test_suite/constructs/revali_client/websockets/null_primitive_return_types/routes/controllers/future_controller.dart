import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('future')
class FutureController {
  const FutureController();

  @WebSocket(
    'data-string',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<String?> dataString() async {
    return null;
  }

  @WebSocket('string', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<StringContent?> string() async {
    return null;
  }

  @WebSocket('bool', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<bool?> boolean() async {
    return null;
  }

  @WebSocket('int', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<int?> integer() async {
    return null;
  }

  @WebSocket('double', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<double?> dub() async {
    return null;
  }

  @WebSocket('record', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<(String?, String?)?> record() async {
    return null;
  }

  @WebSocket(
    'named-record',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<({String? first, String? second})?> namedRecord() async {
    return null;
  }

  @WebSocket(
    'partial-record',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<(String?, {String? second})?> partialRecord() async {
    return null;
  }

  @WebSocket(
    'list-of-records',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<List<(String?, String?)?>?> listOfRecords() async {
    return null;
  }

  @WebSocket(
    'list-of-strings',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<List<String?>?> listOfStrings() async {
    return null;
  }

  @WebSocket(
    'list-of-maps',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<List<Map<String?, dynamic>?>?> listOfMaps() async {
    return null;
  }

  @WebSocket(
    'map-string-dynamic',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<Map<String?, dynamic>?> map() async {
    return null;
  }

  @WebSocket(
    'map-dynamic-dynamic',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<Map<dynamic, dynamic>?> dynamicMap() async {
    return null;
  }

  @WebSocket(
    'map-dynamic-dynamic-with-null',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Future<Map<dynamic, dynamic>?> dynamicMapWithNull() async {
    return {'foo': null};
  }

  @WebSocket('set', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<Set<String?>?> set() async {
    return null;
  }

  @WebSocket('iterable', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<Iterable<String?>?> iterable() async {
    return null;
  }

  @WebSocket('bytes', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Future<List<int>?> bytes() async {
    return null;
  }
}
