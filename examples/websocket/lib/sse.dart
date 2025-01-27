// ignore_for_file: inference_failure_on_function_invocation

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io show stdin;
import 'dart:io' hide stdin;
import 'dart:typed_data';

const port = 1213;
const url = 'http://localhost:$port';

void main([List<String> args = const []]) {
  if (args.contains('--listen')) {
    listen();
  } else if (args.contains('--start')) {
    startUp();
  } else {
    print('Usage: dart run lib/sse.dart --listen | --start');
  }

  if (args.contains('--start')) {
    print('Type anything and press enter to send data, type "exit" to stop');
  }
}

Future<void> startUp() async {
  final server = await HttpServer.bind('localhost', port);
  server.asBroadcastStream().listen(onHttpRequest);
}

Future<void> onHttpRequest(HttpRequest request) async {
  final identifier = '${request.hashCode}'.substring(0, 4);

  print('request (#$identifier): ${request.uri}');

  final socket = await request.response.detachSocket();

  StreamSubscription<Uint8List>? listener;
  listener = socket.listen(
    (event) {
      final msg = utf8.decode(event).trim();

      print('MSG (#$identifier): $msg');
    },
    onDone: () {
      print('done (#$identifier)');
      listener?.cancel().ignore();
      socket.close().ignore();
    },
  );

  try {
    await for (final event in constantSource()) {
      print('Sending (#$identifier)');

      socket
        ..add(utf8.encode(event.length.toRadixString(16)))
        ..add([13, 10]) // CRLF
        ..add(event)
        ..add([13, 10]); // CRLF
      await socket.flush();
    }

    socket.add([48, 13, 10, 13, 10]); // 0 CRLF CRLF
    await socket.close();
  } catch (e) {
    print('Error (#$identifier): $e');

    await socket.close();
  }

  listener.cancel().ignore();
  print('done (#$identifier)');
}

Stream<List<int>>? stdin;

Stream<List<int>> constantSource() async* {
  final std = stdin ??= io.stdin.asBroadcastStream();
  // listen to stdin
  await for (final event in std) {
    final string = utf8.decode(event).trim();

    if (string == 'exit') {
      break;
    }

    final data = {
      'trigger': string,
      'time': DateTime.now().toIso8601String(),
    };

    yield utf8.encode(jsonEncode(data));
  }
}

Future<void> listen() async {
  final http = HttpClient();

  final request = await http.getUrl(Uri.parse(url));

  final response = await request.close();

  print('made request');

  final stream = response.transform(utf8.decoder);

  StreamSubscription<String>? listener;
  StreamSubscription<List<int>>? stdinListener;
  listener = stream.listen(
    (event) {
      final data = jsonDecode(event);

      print('Received: $data');
    },
    onDone: () {
      print('done');
      listener?.cancel().ignore();
      stdinListener?.cancel().ignore();
    },
  );

  stdinListener = io.stdin.listen((event) {
    final msg = utf8.decode(event).trim();
    print('MSG: $msg');
    if (msg == 'exit') {
      listener?.cancel().ignore();
      stdinListener?.cancel().ignore();
    }
  });

  await listener.asFuture();

  print('done');
  stdinListener.cancel().ignore();
}
