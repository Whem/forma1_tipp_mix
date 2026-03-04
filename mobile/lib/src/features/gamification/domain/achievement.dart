class Achievement {
  final String id;
  final String nameHu;
  final String nameEn;
  final String descriptionHu;
  final String descriptionEn;
  final String icon;
  final int threshold;
  final String type;

  const Achievement({
    required this.id,
    required this.nameHu,
    required this.nameEn,
    required this.descriptionHu,
    required this.descriptionEn,
    required this.icon,
    required this.threshold,
    required this.type,
  });

  factory Achievement.fromFirestore(Map<String, dynamic> data, String id) {
    return Achievement(
      id: id,
      nameHu: data['nameHu'] as String,
      nameEn: data['nameEn'] as String,
      descriptionHu: data['descriptionHu'] as String,
      descriptionEn: data['descriptionEn'] as String,
      icon: data['icon'] as String,
      threshold: data['threshold'] as int,
      type: data['type'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nameHu': nameHu,
      'nameEn': nameEn,
      'descriptionHu': descriptionHu,
      'descriptionEn': descriptionEn,
      'icon': icon,
      'threshold': threshold,
      'type': type,
    };
  }
}
