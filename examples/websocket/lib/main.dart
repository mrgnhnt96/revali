// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  // _websocket();
  // _json();
  // _list();
  // _multiPartForm();
  // _form();
  // _text();
  // _stream();
  _file();
}

Future<void> _websocket() async {
  try {
    // Connect to the remote WebSocket endpoint.
    final uri = Uri.parse('ws://localhost:8080/api/user/create?name=John');
    final channel = WebSocketChannel.connect(uri);

    // Subscribe to messages from the server.
    channel.stream.listen((message) {
      final decoded = jsonDecode(utf8.decode(message));
      print('SERVER: $decoded');
    }, onError: (e) {
      print(e);
    });

    // stdin to send messages to the server.
    final input = stdin.transform(utf8.decoder).transform(LineSplitter());

    await for (final line in input) {
      final data = utf8.encode(
        jsonEncode({
          'message': line,
        }),
      );
      channel.sink.add(data);
    }
  } catch (e) {
    print(e);
  }
}

Future<void> _json() async {
  final dio = Dio()..options.baseUrl = 'http://localhost:8080/api';
  try {
    // stdin to send messages to the server.
    final input = stdin.transform(utf8.decoder).transform(LineSplitter());
    final uri = Uri.parse('/user/123?name=morgan');

    final response = await dio.get(uri.toString());
    print(response.data);

    await for (final line in input) {
      final data = utf8.encode(
        jsonEncode({
          'name': line,
        }),
      );

      final response = await dio.get(
        uri.toString(),
        data: data,
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: 'application/_json',
          },
        ),
      );

      print(response.data);
    }
  } catch (e) {
    print(e);
  }
}

/// Sends list data to the server
Future<void> _list() async {
  final dio = Dio()..options.baseUrl = 'http://localhost:8080/api';

  try {
    final response = await dio.post(
      '/user/123',
      data: ['John', 'Doe'],
      options: Options(
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      ),
    );

    print(response.data);
  } catch (e) {
    print(e);
  }
}

Future<void> _multiPartForm() async {
  final file = File('file.txt');
  // send file to server
  final dio = Dio()..options.baseUrl = 'http://localhost:8080/api';

  try {
    final response = await dio.post(
      '/file',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'is_awesome': true,
        'count': 1,
        'meta': jsonEncode({
          'name': 'John',
          'age': 25,
        }),
      }),
      options: Options(
        headers: {
          HttpHeaders.contentTypeHeader: 'multipart/form-data',
        },
      ),
    );

    print(response.data);
  } catch (e) {
    print(e);
  }
}

/// Sends form data to the server
Future<void> _form() async {
  final dio = Dio()..options.baseUrl = 'http://localhost:8080/api';

  try {
    final response = await dio.post(
      '/user/123',
      data: {
        'name': 'John',
        'age': 25,
      },
      options: Options(
        headers: {
          HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
        },
      ),
    );

    print(response.data);
  } catch (e) {
    print(e);
  }
}

/// Sends text data to the server
Future<void> _text() async {
  final dio = Dio()..options.baseUrl = 'http://localhost:8080/api';

  try {
    final response = await dio.post(
      '/user/123',
      data: 'whats up dude?',
      options: Options(
        headers: {
          HttpHeaders.contentTypeHeader: 'text/plain',
        },
      ),
    );

    print(response.data);
  } catch (e) {
    print(e);
  }
}

/// Sends stream data to the server
Future<void> _stream() async {
  final dio = Dio()..options.baseUrl = 'http://localhost:8080/api';

  try {
    final response = await dio.post(
      '/user/123',
      data: Stream.fromIterable([
        utf8.encode('Hello'),
        utf8.encode('World'),
      ]),
      options: Options(
        headers: {
          HttpHeaders.contentTypeHeader: 'application/octet-stream',
          HttpHeaders.contentEncodingHeader: 'utf-8',
        },
      ),
    );

    print(response.data);
  } catch (e) {
    print(e);
  }
}

/// Sends file data to the server
Future<void> _file() async {
  final dio = Dio()..options.baseUrl = 'http://localhost:8080/api';

  try {
    final response = await dio.post(
      '/user/123',
      data: File('file.txt').openRead(),
      options: Options(
        headers: {
          HttpHeaders.contentTypeHeader: 'application/octet-stream',
          HttpHeaders.contentEncodingHeader: 'utf-8',
        },
      ),
    );

    print(response.data);
  } catch (e) {
    print(e);
  }
}
