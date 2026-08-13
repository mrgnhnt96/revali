/// Reads cookie names and values out of `Set-Cookie` header content.
///
/// A response may set several cookies, and the HTTP client surfaces them as
/// one comma-joined string. Splitting that on every comma is wrong — an
/// `Expires` attribute contains one ("Wed, 09 Jun 2021 …") — so the split
/// only happens at a comma that begins a new `name=` pair.
///
/// Attributes are dropped. Everything after the first `;` of a cookie is
/// metadata (`Path`, `Expires`, `HttpOnly`, `SameSite`), and treating those
/// as cookies of their own put `Path` and `Expires` into storage.
class CookieParser {
  CookieParser(String cookies) : cookies = [cookies];
  const CookieParser.all(this.cookies);

  final List<dynamic> cookies;

  /// A comma that starts the next cookie: followed by a cookie name and `=`.
  ///
  /// Cookie names cannot contain a comma, space, semicolon or `=`, so this
  /// cannot match inside an `Expires` date.
  static final _nextCookie = RegExp(r',\s*(?=[^\s,;=]+=)');

  Map<String, String> parse() {
    final parsed = <String, String>{};

    for (final entry in cookies) {
      if (entry is! String || entry.isEmpty) {
        continue;
      }

      for (final cookie in entry.split(_nextCookie)) {
        // Only the first pair is the cookie; the rest are its attributes.
        final pair = cookie.split(';').first.trim();
        if (pair.isEmpty) {
          continue;
        }

        final separator = pair.indexOf('=');
        if (separator <= 0) {
          continue;
        }

        final name = pair.substring(0, separator).trim();
        final value = pair.substring(separator + 1).trim();

        if (name.isEmpty) {
          continue;
        }

        parsed[name] = value;
      }
    }

    return parsed;
  }
}
