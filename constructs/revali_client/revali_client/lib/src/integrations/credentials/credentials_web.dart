import 'package:http/browser_client.dart' show BrowserClient;
import 'package:http/http.dart' as http;

/// Enables sending/receiving cookies on cross-origin requests. This is a
/// `fetch()`-level option (`credentials: 'include'`), not an HTTP header --
/// setting a literal `credentials` header does nothing for the browser.
void enableCredentials(http.Client client) {
  if (client is BrowserClient) {
    client.withCredentials = true;
  }
}
