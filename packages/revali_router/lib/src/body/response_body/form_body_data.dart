part of 'base_body_data.dart';

final class FormDataBodyData extends JsonBodyData {
  FormDataBodyData(super.data);

  FormDataBodyData.fromString(String data)
      : super(jsonDecode(data) as Map<String, dynamic>);

  @override
  String get mimeType => 'application/x-www-form-urlencoded';

  @override
  int get contentLength {
    return data.keys.fold<int>(0, (previousValue, element) {
      return previousValue + element.length + data[element].toString().length;
    });
  }

  @override
  Stream<List<int>> read() {
    final encoded = data.keys.map((key) {
      return '${Uri.encodeQueryComponent(key)}'
          '='
          '${Uri.encodeQueryComponent(data[key].toString())}';
    }).join('&');

    return Stream.value(encoding.encode(encoded));
  }
}
