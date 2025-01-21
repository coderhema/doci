class Document {
  final String name;
  final String path;
  final DateTime modified;
  final String? size;
  final String? fileType;

  Document({
    required this.name,
    required this.path,
    required this.modified,
    this.size,
    this.fileType,
  });
}
