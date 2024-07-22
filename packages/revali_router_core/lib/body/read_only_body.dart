abstract class ReadOnlyBody {
  const ReadOnlyBody();

  dynamic get data;

  Stream<List<int>>? read();

  bool get isNull;

  @override
  String toString() => '$data';
}
