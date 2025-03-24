# Revali Client

A Revali Client Construct to generate client code using [`revali`][revali].

## Usage

```dart
import 'package:client/client.dart';

void main() async {
  final client = Server(); // Generated client

  final user = await client.getUser(id: 1);
}
```

## Documentation

Check out the [documentation](https://www.revali.dev/constructs/revali_client/overview) for more information on how to use Revali Client.

[revali]: https://pub.dev/packages/revali
