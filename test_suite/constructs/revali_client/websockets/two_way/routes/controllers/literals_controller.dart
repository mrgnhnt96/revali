import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('literals')
class LiteralsController {
  const LiteralsController();

  @WebSocket('data-string')
  String dataString(@Body() String data) {
    return data;
  }

  @WebSocket('string')
  StringContent string(@Body() String data) {
    return StringContent(data);
  }

  @WebSocket('bool')
  bool boolean({@Body(['data']) required bool data}) {
    return data;
  }

  @WebSocket('int')
  int integer(@Body() int data) {
    return data;
  }

  @WebSocket('double')
  double dub(@Body() double data) {
    return data;
  }

  @WebSocket('record')
  (String, String) record(@Body() (String, String) data) {
    return data;
  }

  @WebSocket('named-record')
  ({String first, String second}) namedRecord(
    @Body() ({String first, String second}) data,
  ) {
    return data;
  }

  @WebSocket('partial-record')
  (String, {String? second}) partialRecord(
    @Body() (String, {String? second}) data,
  ) {
    return data;
  }

  @WebSocket('list-of-records')
  List<(String, String)> listOfRecords(@Body() List<(String, String)> data) {
    return data;
  }

  @WebSocket('list-of-strings')
  List<String> listOfStrings(@Body() List<String> data) {
    return data;
  }

  @WebSocket('list-of-maps')
  List<Map<String, dynamic>> listOfMaps(
    @Body() List<Map<String, dynamic>> data,
  ) {
    return data;
  }

  @WebSocket('map-string-dynamic')
  Map<String, dynamic> map(@Body() Map<String, dynamic> data) {
    return data;
  }

  @WebSocket('map-dynamic-dynamic')
  Map<dynamic, dynamic> dynamicMap(@Body() Map<dynamic, dynamic> data) {
    return data;
  }

  @WebSocket('set')
  Set<String> set(@Body() Set<String> data) {
    return data;
  }

  @WebSocket('iterable')
  Iterable<String> iterable(@Body() Iterable<String> data) sync* {
    yield* data;
  }

  @WebSocket('bytes')
  List<List<int>> bytes(@Body(['data']) List<List<int>> data) {
    return data;
  }
}
