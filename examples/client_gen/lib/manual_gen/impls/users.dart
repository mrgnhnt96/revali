part of '../implementations.dart';

final class UsersImpl implements Users {
  const UsersImpl({
    required this.client,
    required this.storage,
  });

  final HttpClient client;
  final Storage storage;

  @override
  Future<String> simple() async {
    final baseUrl = switch (await storage['__BASE_URL__']) {
      final String url => url,
      _ => throw Exception('Base URL not set'),
    };

    final uri = Uri.parse('$baseUrl/users');

    final request = await client.openUrl('GET', uri);
    final response = await request.close();

    final hasException = switch (response.statusCode) {
      >= 200 && < 300 => false,
      _ => true,
    };

    final body = await response.transform(utf8.decoder).join();

    if (hasException) {
      throw ServerException(
        message: response.reasonPhrase,
        statusCode: response.statusCode,
        body: body,
      );
    }

    if (jsonDecode(body) case {'data': final String data}) {
      return data;
    }

    throw Exception('Invalid response');
  }
}
