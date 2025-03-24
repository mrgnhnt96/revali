import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('literals')
class LiteralsController {
  const LiteralsController();

  @Get('data-string')
  String? dataString() {
    return null;
  }

  @Get('string')
  StringContent? string() {
    return null;
  }

  @Get('bool')
  bool? boolean() {
    return null;
  }

  @Get('int')
  int? integer() {
    return null;
  }

  @Get('double')
  double? dub() {
    return null;
  }

  @Get('record')
  (String?, String?)? record() {
    return null;
  }

  @Get('named-record')
  ({String? first, String? second})? namedRecord() {
    return null;
  }

  @Get('partial-record')
  (String?, {String? second})? partialRecord() {
    return null;
  }

  @Get('list-of-records')
  List<(String?, String?)>? listOfRecords() {
    return null;
  }

  @Get('list-of-strings')
  List<String?>? listOfStrings() {
    return null;
  }

  @Get('list-of-maps')
  List<Map<String?, dynamic>?>? listOfMaps() {
    return null;
  }

  @Get('map-string-dynamic')
  Map<String?, dynamic>? map() {
    return null;
  }

  @Get('map-dynamic-dynamic')
  Map<dynamic, dynamic>? dynamicMap() {
    return null;
  }

  @Get('map-dynamic-dynamic-with-null')
  Map<dynamic, dynamic>? dynamicMapWithNull() {
    return {'foo': null};
  }

  @Get('set')
  Set<String?>? set() {
    return null;
  }

  @Get('iterable')
  Iterable<String?>? iterable() {
    return null;
  }

  @Get('bytes')
  List<int>? bytes() {
    return null;
  }
}
