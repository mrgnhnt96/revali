import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('future')
class FutureController {
  const FutureController();

  @Get('data-string')
  Future<String?> dataString() async {
    return null;
  }

  @Get('string')
  Future<StringContent?> string() async {
    return null;
  }

  @Get('bool')
  Future<bool?> boolean() async {
    return null;
  }

  @Get('int')
  Future<int?> integer() async {
    return null;
  }

  @Get('double')
  Future<double?> dub() async {
    return null;
  }

  @Get('record')
  Future<(String?, String?)?> record() async {
    return null;
  }

  @Get('named-record')
  Future<({String? first, String? second})?> namedRecord() async {
    return null;
  }

  @Get('partial-record')
  Future<(String?, {String? second})?> partialRecord() async {
    return null;
  }

  @Get('list-of-records')
  Future<List<(String?, String?)?>?> listOfRecords() async {
    return null;
  }

  @Get('list-of-strings')
  Future<List<String?>?> listOfStrings() async {
    return null;
  }

  @Get('list-of-maps')
  Future<List<Map<String?, dynamic>?>?> listOfMaps() async {
    return null;
  }

  @Get('map-string-dynamic')
  Future<Map<String?, dynamic>?> map() async {
    return null;
  }

  @Get('map-dynamic-dynamic')
  Future<Map<dynamic, dynamic>?> dynamicMap() async {
    return null;
  }

  @Get('map-dynamic-dynamic-with-null')
  Future<Map<dynamic, dynamic>?> dynamicMapWithNull() async {
    return {'foo': null};
  }

  @Get('set')
  Future<Set<String?>?> set() async {
    return null;
  }

  @Get('iterable')
  Future<Iterable<String?>?> iterable() async {
    return null;
  }

  @Get('bytes')
  Future<List<int>?> bytes() async {
    return null;
  }
}
