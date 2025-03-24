import 'dart:convert';

import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('stream')
class StreamController {
  const StreamController();

  @Get('data-string')
  Stream<String> dataString() async* {
    yield 'Hello';
    yield 'world';
  }

  @Get('string')
  Stream<StringContent> string() async* {
    yield const StringContent('Hello');
    yield const StringContent('world');
  }

  @Get('bool')
  Stream<bool> boolean() async* {
    yield true;
    yield false;
  }

  @Get('int')
  Stream<int> integer() async* {
    yield 1;
    yield 2;
  }

  @Get('double')
  Stream<double> dub() async* {
    yield 1.0;
    yield 2.0;
  }

  @Get('record')
  Stream<(String, String)> record() async* {
    yield ('hello', 'world');
    yield ('foo', 'bar');
  }

  @Get('named-record')
  Stream<({String first, String second})> namedRecord() async* {
    yield (first: 'hello', second: 'world');
    yield (first: 'foo', second: 'bar');
  }

  @Get('partial-record')
  Stream<(String, {String? second})> partialRecord() async* {
    yield ('hello', second: 'world');
    yield ('foo', second: 'bar');
  }

  @Get('list-of-records')
  Stream<List<(String, String)>> listOfRecords() async* {
    yield [('hello', 'world')];
    yield [('foo', 'bar')];
  }

  @Get('list-of-strings')
  Stream<List<String>> listOfStrings() async* {
    yield ['Hello'];
    yield ['world'];
  }

  @Get('list-of-maps')
  Stream<List<Map<String, dynamic>>> listOfMaps() async* {
    yield [
      {'hello': 1},
    ];
    yield [
      {'foo': 2},
    ];
  }

  @Get('map-string-dynamic')
  Stream<Map<String, dynamic>> map() async* {
    yield {'hello': 1};
    yield {'foo': 2};
  }

  @Get('map-dynamic-dynamic')
  Stream<Map<dynamic, dynamic>> dynamicMap() async* {
    yield {'true': true};
    yield {'false': false};
  }

  @Get('set')
  Stream<Set<String>> set() async* {
    yield {'Hello'};
    yield {'world'};
  }

  @Get('iterable')
  Stream<Iterable<String>> iterable() async* {
    yield ['Hello'];
    yield ['world'];
  }

  @Get('bytes')
  Stream<List<int>> bytes() async* {
    yield utf8.encode('Hello');
    yield utf8.encode('world');
  }
}
