class Season {
  final String id;
  final int year;
  final bool isActive;

  const Season({
    required this.id,
    required this.year,
    required this.isActive,
  });

  factory Season.fromFirestore(Map<String, dynamic> data, String id) {
    return Season(
      id: id,
      year: data['year'] as int,
      isActive: data['isActive'] as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'year': year,
      'isActive': isActive,
    };
  }
}
