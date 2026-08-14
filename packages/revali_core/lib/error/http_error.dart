/// A failure that survives the hop.
///
/// A status code alone tells a caller that something went wrong, not *what*.
/// Two different 404s — an unknown user and an unknown organisation — are
/// indistinguishable to the service calling you, so its only options are to
/// give up or to match on a human-readable message that was never meant to be
/// an API. This carries a stable [code] alongside the status, so the caller
/// can branch on the thing that actually differs.
///
/// ```dart
/// throw const HttpError.notFound(
///   code: 'user_not_found',
///   message: 'No user with that id',
/// );
/// ```
///
/// Serialises to the envelope below, mirroring the `{"data": ...}` wrapper
/// that successful responses already use:
///
/// ```json
/// {"error": {"code": "user_not_found", "message": "No user with that id"}}
/// ```
///
/// Throwing this is **opt-in**. Nothing changes the framework's existing
/// plain-text default responses, so a client that reads them today keeps
/// working; a caller sees [code] only for handlers that chose to raise one.
class HttpError implements Exception {
  const HttpError({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details = const {},
  });

  const HttpError.badRequest({
    required this.code,
    required this.message,
    this.details = const {},
  }) : statusCode = 400;

  const HttpError.unauthorized({
    required this.code,
    required this.message,
    this.details = const {},
  }) : statusCode = 401;

  const HttpError.forbidden({
    required this.code,
    required this.message,
    this.details = const {},
  }) : statusCode = 403;

  const HttpError.notFound({
    required this.code,
    required this.message,
    this.details = const {},
  }) : statusCode = 404;

  const HttpError.conflict({
    required this.code,
    required this.message,
    this.details = const {},
  }) : statusCode = 409;

  const HttpError.unprocessable({
    required this.code,
    required this.message,
    this.details = const {},
  }) : statusCode = 422;

  const HttpError.internal({
    required this.code,
    required this.message,
    this.details = const {},
  }) : statusCode = 500;

  /// The HTTP status this failure responds with.
  final int statusCode;

  /// A stable, machine-readable identifier — `user_not_found`, not
  /// `User not found`.
  ///
  /// This is the part callers branch on, so treat it as API: renaming it
  /// breaks them exactly as renaming a route would. The contract check reports
  /// route drift, **not** error-code drift; a code you stop emitting is a
  /// silent break.
  final String code;

  /// A human-readable explanation, for logs and developers.
  ///
  /// Never parse this. It is free to change wording without notice, which is
  /// precisely why [code] exists.
  final String message;

  /// Extra machine-readable context — which field failed validation, how long
  /// to wait.
  ///
  /// Crosses the wire to whoever called you, so keep internals out of it.
  final Map<String, Object?> details;

  /// The wire form.
  Map<String, Object?> toEnvelope() => {
        'error': {
          'code': code,
          'message': message,
          if (details.isNotEmpty) 'details': details,
        },
      };

  @override
  String toString() => 'HttpError($statusCode $code): $message';
}
