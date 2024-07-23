part of 'base_body_data.dart';

final class UnknownBodyData extends BinaryBodyData {
  UnknownBodyData(super.data, {required this.mimeType});

  @override
  final String? mimeType;
}
