// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/makers/creators/create_body_arg.dart';
import 'package:server_client_gen/makers/creators/create_cookie_header.dart';
import 'package:server_client_gen/makers/creators/create_query_arg.dart';
import 'package:server_client_gen/makers/utils/create_map.dart';
import 'package:server_client_gen/models/client_method.dart';

Code createRequest(ClientMethod method) {
  final headers = <String, Code>{};

  final (
    cookies: cookieParams,
    body: bodyParams,
    query: queryParams,
    headers: headerParams,
  ) = method.separateParams;

  if (cookieParams.isNotEmpty) {
    headers['cookie'] = createCookieHeader(cookieParams);
  }

  if (headerParams.isNotEmpty) {
    for (final param in headerParams) {
      final key = switch (param.access) {
        [final String access] => access,
        _ => param.name,
      };
      headers[key] = refer(param.name).code;
    }
  }

  return declareFinal('response')
      .assign(
        refer('_client').property('request').call([], {
          'method': refer("'${method.method}'"),
          'path': refer("'${method.resolvedPath}'"),
          if (headers.isNotEmpty) 'headers': createMap(headers),
          if (queryParams.isNotEmpty) 'query': createQueryArg(queryParams),
          if (bodyParams.isNotEmpty) 'body': createBodyArg(bodyParams),
        }).awaited,
      )
      .statement;
}
