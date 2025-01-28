part of 'base_body_data.dart';

final class ByteStreamBodyData extends StreamBodyData<List<int>> {
  ByteStreamBodyData(
    super.data, {
    super.contentLength,
    super.filename = 'file.txt',
  });

  @override
  Stream<List<int>> read() => data;
}
