part of '../../interfaces.dart';

abstract interface class Users {
  const Users();

  Future<String> simple();

  Future<List<User>> users();

  Future<List<Map<String, dynamic>>> usersRaw();
}
