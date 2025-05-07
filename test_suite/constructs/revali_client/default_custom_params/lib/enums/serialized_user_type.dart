enum SerializedUserType {
  admin,
  user,
  guest;

  const SerializedUserType();

  static SerializedUserType fromJson(String json) {
    return SerializedUserType.values.byName(json);
  }

  String toJson() {
    return name;
  }
}
