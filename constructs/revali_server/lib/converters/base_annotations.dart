abstract class BaseAnnotations<T> {
  List<T> get middlewares;
  List<T> get interceptors;
  List<T> get catchers;
  List<T> get guards;
  List<T> get combines;
}
