class CookieParser {
  const CookieParser(this.cookies);

  final List<dynamic> cookies;

  Map<String, String> parse() {
    final cookies = this.cookies.join(';');

    final cookieMap = <String, String>{};
    final cookieList = cookies.split(';');

    for (final cookie in cookieList) {
      final parts = cookie.split('=');
      final result = switch (parts) {
        [final String key, final String value] => (key.trim(), value.trim()),
        _ => null
      };

      if (result == null) continue;

      final (key, value) = result;

      cookieMap[key] = value;
    }

    return cookieMap;
  }
}
