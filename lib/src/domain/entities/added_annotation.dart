class AddedAnnotation {
  final String annotationType;
  final String id;
  bool isActive;

  AddedAnnotation(this.annotationType, this.id, [this.isActive = true]);

  Map<String, dynamic> toJson() {
    return {'annotation_type': annotationType, 'id': id, 'is_active': isActive};
  }

  factory AddedAnnotation.fromJson(Map<String, dynamic> json) {
    return AddedAnnotation(json['annotation_type'] as String, json['id'] as String, json['is_active'] as bool);
  }

  @override
  String toString() => 'AddedAnnotation{annotationType: $annotationType, id: $id isActive: $isActive}';
}
