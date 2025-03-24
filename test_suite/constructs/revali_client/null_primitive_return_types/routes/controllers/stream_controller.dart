import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('stream')
class StreamController {
  const StreamController();

  @Get('data-string')
  Stream<String?> dataString() async* {
    yield null;
    yield null;
  }

  @Get('string')
  Stream<StringContent?> string() async* {
    yield null;
    yield null;
  }

  @Get('bool')
  Stream<bool?> boolean() async* {
    yield null;
    yield null;
  }

  @Get('int')
  Stream<int?> integer() async* {
    yield null;
    yield null;
  }

  @Get('double')
  Stream<double?> dub() async* {
    yield null;
    yield null;
  }

  @Get('record')
  Stream<(String?, String?)?> record() async* {
    yield null;
    yield null;
  }

  @Get('named-record')
  Stream<({String? first, String? second})?> namedRecord() async* {
    yield null;
    yield null;
  }

  @Get('partial-record')
  Stream<(String?, {String? second})?> partialRecord() async* {
    yield null;
    yield null;
  }

  @Get('list-of-records')
  Stream<List<(String?, String?)>?> listOfRecords() async* {
    yield null;
    yield null;
  }

  @Get('list-of-strings')
  Stream<List<String?>?> listOfStrings() async* {
    yield null;
    yield null;
  }

  @Get('list-of-maps')
  Stream<List<Map<String?, dynamic>?>?> listOfMaps() async* {
    yield null;
    yield null;
  }

  @Get('map-string-dynamic')
  Stream<Map<String?, dynamic>?> map() async* {
    yield null;
    yield null;
  }

  @Get('map-dynamic-dynamic')
  Stream<Map<dynamic, dynamic>?> dynamicMap() async* {
    yield null;
    yield null;
  }

  @Get('map-dynamic-dynamic-with-null')
  Stream<Map<dynamic, dynamic>?> dynamicMapWithNull() async* {
    yield {'foo': null};
    yield {'bar': null};
  }

  @Get('set')
  Stream<Set<String?>?> set() async* {
    yield null;
    yield null;
  }

  @Get('iterable')
  Stream<Iterable<String?>?> iterable() async* {
    yield null;
    yield null;
  }

  @Get('bytes')
  Stream<List<int>?> bytes() async* {
    yield null;
    yield null;
  }
}
