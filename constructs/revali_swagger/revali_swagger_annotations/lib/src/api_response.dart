class ApiResponse {
  const ApiResponse(this.statusCode, {required this.description});

  final int statusCode;
  final String description;
}
