import 'dart:convert';

import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('stream')
class StreamController {
  const StreamController();

  @SSE('data-string')
  Stream<String> dataString() async* {
    yield 'Hello';
    yield 'world';
  }

  @SSE('string')
  Stream<StringContent> string() async* {
    yield const StringContent('Hello');
    yield const StringContent('world');
  }

  @SSE('bool')
  Stream<bool> boolean() async* {
    yield true;
    yield false;
  }

  @SSE('int')
  Stream<int> integer() async* {
    yield 1;
    yield 2;
  }

  @SSE('double')
  Stream<double> dub() async* {
    yield 1.0;
    yield 2.0;
  }

  @SSE('record')
  Stream<(String, String)> record() async* {
    yield ('hello', 'world');
    yield ('foo', 'bar');
  }

  @SSE('named-record')
  Stream<({String first, String second})> namedRecord() async* {
    yield (first: 'hello', second: 'world');
    yield (first: 'foo', second: 'bar');
  }

  @SSE('partial-record')
  Stream<(String, {String? second})> partialRecord() async* {
    yield ('hello', second: 'world');
    yield ('foo', second: 'bar');
  }

  @SSE('list-of-records')
  Stream<List<(String, String)>> listOfRecords() async* {
    yield [('hello', 'world')];
    yield [('foo', 'bar')];
  }

  @SSE('list-of-strings')
  Stream<List<String>> listOfStrings() async* {
    yield ['Hello'];
    yield ['world'];
  }

  @SSE('list-of-maps')
  Stream<List<Map<String, dynamic>>> listOfMaps() async* {
    yield [
      {'hello': 1},
    ];
    yield [
      {'foo': 2},
    ];
  }

  @SSE('map-string-dynamic')
  Stream<Map<String, dynamic>> map() async* {
    yield {'hello': 1};
    yield {'foo': 2};
  }

  @SSE('map-dynamic-dynamic')
  Stream<Map<dynamic, dynamic>> dynamicMap() async* {
    yield {'true': true};
    yield {'false': false};
  }

  @SSE('set')
  Stream<Set<String>> set() async* {
    yield {'Hello'};
    yield {'world'};
  }

  @SSE('iterable')
  Stream<Iterable<String>> iterable() async* {
    yield ['Hello'];
    yield ['world'];
  }

  @SSE('bytes')
  Stream<List<int>> bytes() async* {
    yield utf8.encode('Hello');
    yield utf8.encode('world');
  }
}
