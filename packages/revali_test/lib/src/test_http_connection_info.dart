import 'dart:io';

class TestHttpConnectionInfo implements HttpConnectionInfo {
  const TestHttpConnectionInfo({
    String remoteAddress = '127.0.0.1',
    this.remotePort = 8080,
    this.localPort = 8080,
  }) : _remoteAddress = remoteAddress;

  final String _remoteAddress;

  @override
  InternetAddress get remoteAddress => InternetAddress(_remoteAddress);

  @override
  final int remotePort;

  @override
  final int localPort;
}
