class CreatePostInput {
  const CreatePostInput({
    required this.title,
  });

  factory CreatePostInput.fromJson(Map<String, dynamic> json) {
    return CreatePostInput(
      title: json['title'] as String,
    );
  }

  final String title;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
    };
  }
}
