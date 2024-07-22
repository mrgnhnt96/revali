part of './base_body_data.dart';

class NullBodyData extends BaseBodyData<Null> {
  NullBodyData() : super(null);

  @override
  bool get isNull => true;

  @override
  String? get mimeType => null;

  @override
  int get contentLength => 0;

  @override
  Stream<List<int>> read() async* {}

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) {
    return MutableHeadersImpl();
  }
}
