import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('literals')
class LiteralsController {
  const LiteralsController();

  @WebSocket(
    'data-string',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  String? dataString() {
    return null;
  }

  @WebSocket('string', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  StringContent? string() {
    return null;
  }

  @WebSocket('bool', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  bool? boolean() {
    return null;
  }

  @WebSocket('int', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  int? integer() {
    return null;
  }

  @WebSocket('double', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  double? dub() {
    return null;
  }

  @WebSocket('record', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  (String?, String?)? record() {
    return null;
  }

  @WebSocket(
    'named-record',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  ({String? first, String? second})? namedRecord() {
    return null;
  }

  @WebSocket(
    'partial-record',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  (String?, {String? second})? partialRecord() {
    return null;
  }

  @WebSocket(
    'list-of-records',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  List<(String?, String?)>? listOfRecords() {
    return null;
  }

  @WebSocket(
    'list-of-strings',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  List<String?>? listOfStrings() {
    return null;
  }

  @WebSocket(
    'list-of-maps',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  List<Map<String?, dynamic>?>? listOfMaps() {
    return null;
  }

  @WebSocket(
    'map-string-dynamic',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Map<String?, dynamic>? map() {
    return null;
  }

  @WebSocket(
    'map-dynamic-dynamic',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Map<dynamic, dynamic>? dynamicMap() {
    return null;
  }

  @WebSocket(
    'map-dynamic-dynamic-with-null',
    triggerOnConnect: true,
    mode: WebSocketMode.sendOnly,
  )
  Map<dynamic, dynamic>? dynamicMapWithNull() {
    return {'foo': null};
  }

  @WebSocket('set', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Set<String?>? set() {
    return null;
  }

  @WebSocket('iterable', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  Iterable<String?>? iterable() {
    return null;
  }

  @WebSocket('bytes', triggerOnConnect: true, mode: WebSocketMode.sendOnly)
  List<int>? bytes() {
    return null;
  }
}
