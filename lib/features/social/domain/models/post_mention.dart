class PostMention {
  final String id;
  final String? username;
  final String label;

  const PostMention({
    required this.id,
    this.username,
    required this.label,
  });
}

