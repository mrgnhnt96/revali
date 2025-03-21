import 'dart:convert';

import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('future-literals')
class FutureLiteralsController {
  const FutureLiteralsController();

  @Get('data-string')
  Future<String> dataString() async {
    return 'Hello world!';
  }

  @Get('string')
  Future<StringContent> string() async {
    return const StringContent('Hello world!');
  }

  @Get('bool')
  Future<bool> boolean() async {
    return true;
  }

  @Get('int')
  Future<int> integer() async {
    return 1;
  }

  @Get('double')
  Future<double> dub() async {
    return 1;
  }

  @Get('record')
  Future<(String, String)> record() async {
    return ('hello', 'world');
  }

  @Get('named-record')
  Future<({String first, String second})> namedRecord() async {
    return (first: 'hello', second: 'world');
  }

  @Get('partial-record')
  Future<(String, {String? second})> partialRecord() async {
    return ('hello', second: 'world');
  }

  @Get('list-of-records')
  Future<List<(String, String)>> listOfRecords() async {
    return [('hello', 'world')];
  }

  @Get('list-of-strings')
  Future<List<String>> listOfStrings() async {
    return ['Hello world!'];
  }

  @Get('list-of-maps')
  Future<List<Map<String, dynamic>>> listOfMaps() async {
    return [
      {'hello': 1},
    ];
  }

  @Get('map-string-dynamic')
  Future<Map<String, dynamic>> map() async {
    return {'hello': 1};
  }

  @Get('map-dynamic-dynamic')
  Future<Map<dynamic, dynamic>> dynamicMap() async {
    return {'true': true};
  }

  @Get('set')
  Future<Set<String>> set() async {
    return {'Hello world!'};
  }

  @Get('iterable')
  Future<Iterable<String>> iterable() async {
    return ['Hello world!'];
  }

  @Get('bytes')
  Future<List<List<int>>> bytes() async {
    return [utf8.encode('Hello world!')];
  }
}
