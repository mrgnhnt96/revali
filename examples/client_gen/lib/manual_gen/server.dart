part of 'implementations.dart';

final class Server {
  Server({
    HttpClient? client,
    Storage? storage,
    Uri? baseUrl,
  })  : client = client ?? HttpClient(),
        storage = storage ?? SessionStorage() {
    final url = switch (baseUrl) {
      final uri? => uri.toString(),
      // Will be replaced with app config
      _ => 'http://localhost:8080/api',
    };

    this.storage.save('__BASE_URL__', url);
  }

  final HttpClient client;
  final Storage storage;

  late final Users users = UsersImpl(client: client, storage: storage);
}
