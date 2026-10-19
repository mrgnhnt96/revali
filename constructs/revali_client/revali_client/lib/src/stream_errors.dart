import 'package:http/http.dart' show ClientException;

/// Whether [error] came from the transport rather than from the payload.
///
/// Generated stream clients swallow transport noise so a peer hanging up does
/// not throw into user code. That suppression must be narrow: an error raised
/// because the connection went away is not the same as an error raised because
/// the payload could not be decoded, and only the first is safe to ignore.
///
/// Errors surfacing on a response stream from the default `http`-backed client
/// are [ClientException]s: `io_client.dart` rewraps the SDK's `HttpException`
/// on the body stream, and `browser_client.dart` funnels its errors through
/// `_rethrowAsClientException`.
///
/// Type-based, never message-matching.
///
/// The parameter is [Object]-nullable because `Stream.handleError`'s `test:` is
/// declared `bool test(error)` -- i.e. `bool Function(dynamic)`. Function
/// parameters are contravariant, so `bool Function(Object)` will not bind.
///
/// Known breadth: [ClientException] is package:http's general error type, so
/// this also matches "Client is already closed" and a malformed content-length
/// -- neither is a disconnect. Named `isTransportError` rather than
/// `isDisconnectError` so the name does not promise more than it delivers.
///
/// Known limitation: a custom `HttpClient` that does not go through
/// `package:http` raises its own types, which this will not match -- so its
/// transport errors surface to the consumer instead of being swallowed.
bool isTransportError(Object? error) => error is ClientException;
