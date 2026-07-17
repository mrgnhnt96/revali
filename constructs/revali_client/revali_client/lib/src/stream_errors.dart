import 'package:http/http.dart' show ClientException;

/// Whether [error] means *the connection went away*, rather than *your data is
/// wrong*.
///
/// Generated stream clients swallow disconnect noise so a peer hanging up does
/// not throw into user code. That suppression must be narrow: an error raised
/// because the socket closed is not the same as an error raised because the
/// payload could not be decoded, and only the first is safe to ignore.
///
/// Errors arriving on a response stream from the default `http`-backed client
/// are [ClientException]s -- `package:http` rewraps the SDK's `HttpException`
/// on the body stream in `io_client.dart`, which itself narrows with
/// `test: (error) => error is HttpException`.
///
/// Deliberately type-based, never message-matching.
///
/// Limitation: a custom `HttpClient` that does not go through `package:http`
/// will not raise [ClientException], so its transport errors surface to the
/// consumer instead of being swallowed. That is arguably correct, but it is a
/// real behavioural difference worth knowing.
bool isDisconnectError(Object error) => error is ClientException;
