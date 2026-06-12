class ApiType {
  const ApiType(this.type, {this.format});

  /// The JSON Schema type string (e.g. 'string', 'integer',
  /// 'number', 'boolean', 'object', 'array').
  final String type;

  /// Optional JSON Schema format hint
  /// (e.g. 'date-time', 'int64', 'uri', 'byte').
  final String? format;
}
