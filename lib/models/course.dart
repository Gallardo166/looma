class Course {
  final String id;
  final String name;

  Course({
    required this.id,
    required this.name,
  });

  @override
  String toString() {
    return 'Course(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
