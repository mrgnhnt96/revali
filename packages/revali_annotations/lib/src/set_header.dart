import 'dart:io';

class SetHeader {
  const SetHeader(this.name, this.value);

  /// The value of the header will be set to an empty string
  ///
  /// Useful for headers that don't have a value, or are dynamic
  const SetHeader.key(this.name) : value = '';

  /// the date header will be set at the time of the response
  const SetHeader.date() : this(HttpHeaders.dateHeader, '');

  final String name;
  final String value;
}
