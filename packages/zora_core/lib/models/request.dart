sealed class Request {
  const Request();
}

class BaseRequest implements Request {
  const BaseRequest();
}

class Method {
  const Method(this.name);

  final String name;
}

class Get extends Method {
  const Get() : super('GET');
}

class Post extends Method {
  const Post() : super('POST');
}

class Put extends Method {
  const Put() : super('PUT');
}

class Delete extends Method {
  const Delete() : super('DELETE');
}

class Patch extends Method {
  const Patch() : super('PATCH');
}
