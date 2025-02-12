part of 'implementations.dart';

final class Server {
  Server({
    HttpClient? client,
    Storage? storage,
    Uri? baseUrl,
  }) : storage = storage ?? SessionStorage() {
    final url = baseUrl?.toString() ?? 'http://localhost:8080/api';

    this.client = Client(
      client: client ?? HttpClient(),
      baseUrl: url,
      storage: this.storage,
    );

    this.storage.save('__BASE_URL__', url);
  }

  late final Client client;
  final Storage storage;

  late final Users users = UsersImpl(client: client, storage: storage);
}
