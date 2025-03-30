abstract class CleanUp {
  CleanUp();

  void add(void Function() fn);

  void remove(void Function() fn);

  void merge(CleanUp other);
}
