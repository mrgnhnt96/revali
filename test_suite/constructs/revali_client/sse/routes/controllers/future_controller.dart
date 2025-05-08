import 'dart:convert';

import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('future')
class FutureController {
  const FutureController();

  @SSE('void')
  Future<void> voidCall() async {}

  @SSE('data-string')
  Future<String> dataString() async {
    return 'Hello world!';
  }

  @SSE('string')
  Future<StringContent> string() async {
    return const StringContent('Hello world!');
  }

  @SSE('bool')
  Future<bool> boolean() async {
    return true;
  }

  @SSE('int')
  Future<int> integer() async {
    return 1;
  }

  @SSE('double')
  Future<double> dub() async {
    return 1;
  }

  @SSE('record')
  Future<(String, String)> record() async {
    return ('hello', 'world');
  }

  @SSE('named-record')
  Future<({String first, String second})> namedRecord() async {
    return (first: 'hello', second: 'world');
  }

  @SSE('partial-record')
  Future<(String, {String? second})> partialRecord() async {
    return ('hello', second: 'world');
  }

  @SSE('list-of-records')
  Future<List<(String, String)>> listOfRecords() async {
    return [('hello', 'world')];
  }

  @SSE('list-of-strings')
  Future<List<String>> listOfStrings() async {
    return ['Hello world!'];
  }

  @SSE('list-of-maps')
  Future<List<Map<String, dynamic>>> listOfMaps() async {
    return [
      {'hello': 1},
    ];
  }

  @SSE('map-string-dynamic')
  Future<Map<String, dynamic>> map() async {
    return {'hello': 1};
  }

  @SSE('map-dynamic-dynamic')
  Future<Map<dynamic, dynamic>> dynamicMap() async {
    return {'true': true};
  }

  @SSE('set')
  Future<Set<String>> set() async {
    return {'Hello world!'};
  }

  @SSE('iterable')
  Future<Iterable<String>> iterable() async {
    return ['Hello world!'];
  }

  @SSE('bytes')
  Future<List<int>> bytes() async {
    return utf8.encode('Hello world!');
  }
}
