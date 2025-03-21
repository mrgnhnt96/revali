import 'dart:convert';

import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('stream')
class StreamController {
  const StreamController();

  @Get('data-string')
  Stream<String> dataString() async* {
    yield 'Hello world!';
  }

  @Get('string')
  Stream<StringContent> string() async* {
    yield const StringContent('Hello world!');
  }

  @Get('bool')
  Stream<bool> boolean() async* {
    yield true;
  }

  @Get('int')
  Stream<int> integer() async* {
    yield 1;
  }

  @Get('double')
  Stream<double> dub() async* {
    yield 1;
  }

  @Get('record')
  Stream<(String, String)> record() async* {
    yield ('hello', 'world');
  }

  @Get('named-record')
  Stream<({String first, String second})> namedRecord() async* {
    yield (first: 'hello', second: 'world');
  }

  @Get('partial-record')
  Stream<(String, {String? second})> partialRecord() async* {
    yield ('hello', second: 'world');
  }

  @Get('list-of-records')
  Stream<List<(String, String)>> listOfRecords() async* {
    yield [('hello', 'world')];
  }

  @Get('list-of-strings')
  Stream<List<String>> listOfStrings() async* {
    yield ['Hello world!'];
  }

  @Get('list-of-maps')
  Stream<List<Map<String, dynamic>>> listOfMaps() async* {
    yield [
      {'hello': 1},
    ];
  }

  @Get('map-string-dynamic')
  Stream<Map<String, dynamic>> map() async* {
    yield {'hello': 1};
  }

  @Get('map-dynamic-dynamic')
  Stream<Map<dynamic, dynamic>> dynamicMap() async* {
    yield {'true': true};
  }

  @Get('set')
  Stream<Set<String>> set() async* {
    yield {'Hello world!'};
  }

  @Get('iterable')
  Stream<Iterable<String>> iterable() async* {
    yield ['Hello world!'];
  }

  @Get('bytes')
  Stream<List<int>> bytes() async* {
    yield utf8.encode('Hello world!');
  }
}
