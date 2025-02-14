part of '../../implementations.dart';

final class UsersImpl implements Users {
  const UsersImpl({
    required this.client,
    required this.storage,
  });

  final HttpClient client;
  final Storage storage;

  @override
  Future<String> simple() async {
    final response = await client.request(
      method: 'GET',
      path: '/users',
    );

    final body = await response.transform(utf8.decoder).join();

    if (jsonDecode(body) case {'data': final String data}) {
      return data;
    }

    throw Exception('Invalid response');
  }

  @override
  Future<List<User>> users() async {
    final response =
        await client.request(method: 'GET', path: '/users/profiles');

    final body = await response.transform(utf8.decoder).join();

    if (jsonDecode(body) case {'data': final List<dynamic> data}) {
      return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('Invalid response');
  }

  @override
  Future<List<Map<String, dynamic>>> usersRaw() async {
    final response =
        await client.request(method: 'GET', path: '/users/profiles-raw');

    final body = await response.transform(utf8.decoder).join();

    if (jsonDecode(body) case {'data': final List<dynamic> data}) {
      return data.map((e) => e as Map<String, dynamic>).toList();
    }

    throw Exception('Invalid response');
  }
}
