import 'package:http/http.dart' as http;

/// No browser cookie jar exists outside the web platform -- cross-origin
/// cookies are handled by the app itself (see `SessionStorage`), so there's
/// nothing to enable here.
void enableCredentials(http.Client client) {}
