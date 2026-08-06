/// Mirrors `json_serializable`'s `genericArgumentFactories: true` shape:
/// the json map is followed by one `T Function(Object?)` closure per type
/// parameter, in declaration order.
class ApiResponse<T> {
  const ApiResponse(this.data);

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse(fromJsonT(json['data']));
  }

  final T data;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return {'data': toJsonT(data)};
  }
}
