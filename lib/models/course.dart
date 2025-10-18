class Course {
  final String id;
  final String name;
  final String? pdfPath;

  Course({
    required this.id,
    required this.name,
    this.pdfPath,
  });

  @override
  String toString() {
    return 'Course(id: $id, name: $name, pdfPath: $pdfPath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && 
           other.id == id && 
           other.name == name && 
           other.pdfPath == pdfPath;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ (pdfPath?.hashCode ?? 0);
}
