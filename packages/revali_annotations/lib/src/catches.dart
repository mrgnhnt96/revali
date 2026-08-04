/// Defines a list of catchers that will be used to
/// catch exceptions thrown by the route handler.
class Catches {
  const Catches(this.types);

  final List<Type> types;
}
