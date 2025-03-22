// ignore_for_file: strict_raw_type

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:async/async.dart';
import 'package:revali_client/revali_client.dart';
import 'package:revali_test/revali_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TestWebSocket implements WebSocketChannel {
  TestWebSocket(this.server, [this.onRequest])
      : _sending = StreamController<List<int>>.broadcast(),
        _receiving = StreamController<dynamic>.broadcast();
  final TestServer server;
  final void Function(HttpRequest)? onRequest;

  final StreamController<List<int>> _sending;
  final StreamController<dynamic> _receiving;
  Completer<bool>? _ready;

  TestWebSocket connect(Uri uri, {Iterable<String>? protocols}) {
    _ready
        ?.completeError('Started new connection before previous one completed');
    _ready = Completer<bool>();

    _startConnection(uri, protocols: protocols);

    // ignore: avoid_returning_this
    return this;
  }

  Future<void> _startConnection(Uri uri, {Iterable<String>? protocols}) async {
    StreamSubscription<List<int>>? receivingListener;

    final stream = server.connect(
      method: 'GET',
      path: uri.path,
      body: _sending.stream.map(createWebSocketFrame),
      headers: {
        'connection': ['Upgrade'],
        'upgrade': ['websocket'],
        'Sec-WebSocket-Version': ['13'],
        'Sec-WebSocket-Key': ['123'],
      },
      onRequest: (request) {
        final headers = <String, String>{};
        request.headers.forEach((key, value) {
          headers[key] = value.toList().join(', ');
        });

        onRequest?.call(
          HttpRequest(
            method: request.method,
            url: request.uri,
            headers: headers,
            contentLength: request.contentLength,
          ),
        );
      },
      onClose: () {
        receivingListener?.cancel();
        _receiving.close();
        _sending.close();
      },
    );

    _ready?.complete(true);

    receivingListener = stream.listen(_receiving.add);
  }

  List<int> createWebSocketFrame(dynamic payload) {
    final data = switch (payload) {
      String() => utf8.encode(payload),
      List<int>() => payload,
      _ => utf8.encode(jsonEncode(payload)),
    };

    final payloadLength = data.length;

    // Create header
    final header = <int>[0x81]; // FIN + Text Frame

    // Mask bit set (1) + payload length
    if (payloadLength <= 125) {
      header.add(0x80 | payloadLength);
    } else if (payloadLength <= 65535) {
      header
        ..add(0x80 | 126)
        ..addAll([(payloadLength >> 8) & 0xFF, payloadLength & 0xFF]);
    } else {
      header
        ..add(0x80 | 127)
        ..addAll([0, 0, 0, 0]) // 32-bit high
        ..addAll([
          (payloadLength >> 24) & 0xFF,
          (payloadLength >> 16) & 0xFF,
          (payloadLength >> 8) & 0xFF,
          payloadLength & 0xFF,
        ]);
    }

    // Generate a random 4-byte masking key
    final random = Random();
    final maskingKey = List<int>.generate(4, (_) => random.nextInt(256));
    header.addAll(maskingKey);

    // Apply XOR masking
    final maskedPayload = List<int>.generate(
      payloadLength,
      (i) => data[i] ^ maskingKey[i % 4],
    );

    // Return as a list
    return header.followedBy(maskedPayload).toList();
  }

  @override
  StreamChannel<S> cast<S>() {
    throw UnimplementedError('cast');
  }

  @override
  StreamChannel changeSink(StreamSink Function(StreamSink p1) change) {
    throw UnimplementedError('changeSink');
  }

  @override
  StreamChannel changeStream(Stream Function(Stream p1) change) {
    throw UnimplementedError('changeStream');
  }

  @override
  int? closeCode;

  @override
  String? closeReason;

  @override
  void pipe(StreamChannel other) {
    throw UnimplementedError('pipe');
  }

  @override
  String? protocol;

  @override
  Future<void> get ready async {
    if (_ready case final ready?) {
      await ready.future;
      return;
    }

    throw Exception('Websocket has not been properly initialized');
  }

  @override
  WebSocketSink get sink => _sink ??= TestSink(this);
  WebSocketSink? _sink;

  @override
  Stream get stream => _receiving.stream;

  @override
  StreamChannel<S> transform<S>(
    StreamChannelTransformer<S, dynamic> transformer,
  ) {
    throw UnimplementedError('transform');
  }

  @override
  StreamChannel transformSink(StreamSinkTransformer transformer) {
    throw UnimplementedError('transformSink');
  }

  @override
  StreamChannel transformStream(StreamTransformer transformer) {
    throw UnimplementedError('transformStream');
  }
}

class TestSink implements WebSocketSink {
  TestSink(this.webSocket);

  final TestWebSocket webSocket;

  bool _hasWaitedInitial = false;

  @override
  Future<void> add(dynamic d) async {
    final data = switch (d) {
      final String string => utf8.encode(string),
      final List<int> list => list,
      final List<dynamic> list => utf8.encode(jsonEncode(list)),
      _ => d,
    };

    if (data case final List<int> data) {
      if (!_hasWaitedInitial) {
        // needed to allow event loop to process the connection
        await Future<void>.delayed(Duration.zero);
        _hasWaitedInitial = true;
      }

      webSocket._sending.add(data);
    } else {
      throw Exception('Invalid data $data');
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    webSocket._sending.addError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream stream) async {
    await for (final data in stream) {
      webSocket._receiving.add(data);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    webSocket
      ..closeCode = closeCode
      ..closeReason = closeReason;
  }

  @override
  Future<void> get done => webSocket._sending.close();
}
