String? wildcardParamKey(String routePath, String paramName) {
  for (final segment in routePath.split('/')) {
    if (segment == '*') {
      return '*';
    }

    if (segment.startsWith('*')) {
      final name = segment.substring(1);
      if (name == paramName) {
        return name;
      }
    }
  }

  return null;
}
