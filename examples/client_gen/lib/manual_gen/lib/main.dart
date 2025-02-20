import 'package:client/client.dart';

void main() async {
  final server = Server();

  try {
    final response = await server.shop.product(
      shopId: 'shopId',
      productId: 'productId',
    );

    print(response);
  } catch (e) {
    print(e);
  }
}
