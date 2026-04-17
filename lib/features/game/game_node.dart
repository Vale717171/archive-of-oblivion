class NodeDef {
  final String title;
  final String description;
  final Map<String, String> exits;
  final Map<String, String> examines;
  final Set<String> takeable;

  const NodeDef({
    required this.title,
    required this.description,
    required this.exits,
    this.examines = const <String, String>{},
    this.takeable = const <String>{},
  });
}
