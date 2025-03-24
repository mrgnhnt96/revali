import 'package:client/client.dart';

void main() async {
  final client = Server(); // Generated client

  final user = await client.getUser(id: 1);
}
