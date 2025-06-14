import 'dart:convert';

import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('literals')
class LiteralsController {
  const LiteralsController();

  @Get('void')
  void voidCall() {}

  @Get('data-string')
  String dataString() {
    return 'Hello world!';
  }

  @Get('string')
  StringContent string() {
    return const StringContent('Hello world!');
  }

  @Get('bool')
  bool boolean() {
    return true;
  }

  @Get('int')
  int integer() {
    return 1;
  }

  @Get('double')
  double dub() {
    return 1;
  }

  @Get('record')
  (String, String) record() {
    return ('hello', 'world');
  }

  @Get('named-record')
  ({String first, String second}) namedRecord() {
    return (first: 'hello', second: 'world');
  }

  @Get('partial-record')
  (String, {String? second}) partialRecord() {
    return ('hello', second: 'world');
  }

  @Get('list-of-records')
  List<(String, String)> listOfRecords() {
    return [('hello', 'world')];
  }

  @Get('list-of-strings')
  List<String> listOfStrings() {
    return ['Hello world!'];
  }

  @Get('list-of-maps')
  List<Map<String, dynamic>> listOfMaps() {
    return [
      {'hello': 1},
    ];
  }

  @Get('map-string-dynamic')
  Map<String, dynamic> map() {
    return {'hello': 1};
  }

  @Get('map-dynamic-dynamic')
  Map<dynamic, dynamic> dynamicMap() {
    return {'true': true};
  }

  @Get('set')
  Set<String> set() {
    return {'Hello world!'};
  }

  @Get('iterable')
  Iterable<String> iterable() sync* {
    yield 'Hello world!';
  }

  @Get('bytes')
  List<int> bytes() {
    return utf8.encode('Hello world!');
  }
}
