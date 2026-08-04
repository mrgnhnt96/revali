enum SameSiteCookie {
  strict,
  lax,
  none;

  const SameSiteCookie();

  String get value {
    return switch (this) {
      SameSiteCookie.strict => 'Strict',
      SameSiteCookie.lax => 'Lax',
      SameSiteCookie.none => 'None',
    };
  }

  static SameSiteCookie? tryParse(String value) {
    try {
      return SameSiteCookie.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}
