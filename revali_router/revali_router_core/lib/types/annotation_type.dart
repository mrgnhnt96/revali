enum AnnotationType {
  body,
  query,
  queryAll,
  cookie,
  param,
  header,
  headerAll,
  binds,
  data;

  String get location => switch (this) {
        body => '@body',
        query => '@query',
        queryAll => '@query (all)',
        cookie => '@cookie',
        param => '@param',
        header => '@header',
        headerAll => '@header (all)',
        binds => '@binds',
        data => '@data',
      };
}
