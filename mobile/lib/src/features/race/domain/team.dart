class Team {
  final String id;
  final String name;
  final String shortName;
  final String color;
  final String engineSupplier;
  final String principal;
  final String? logoUrl;
  final String nameHu;
  final String nameEn;

  const Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
    required this.engineSupplier,
    required this.principal,
    this.logoUrl,
    required this.nameHu,
    required this.nameEn,
  });

  factory Team.fromFirestore(Map<String, dynamic> data, String id) {
    final name = data['name'] as String? ??
        data['nameFull'] as String? ??
        '';
    final shortName = data['shortName'] as String? ??
        data['nameShort'] as String? ??
        '';
    return Team(
      id: id,
      name: name,
      shortName: shortName,
      color: data['color'] as String? ?? '#FFFFFF',
      engineSupplier: data['engineSupplier'] as String? ??
          data['engine'] as String? ??
          '',
      principal: data['principal'] as String? ??
          data['company'] as String? ??
          '',
      logoUrl: data['logoUrl'] as String?,
      nameHu: data['nameHu'] as String? ?? name,
      nameEn: data['nameEn'] as String? ?? name,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'shortName': shortName,
      'color': color,
      'engineSupplier': engineSupplier,
      'principal': principal,
      'logoUrl': logoUrl,
      'nameHu': nameHu,
      'nameEn': nameEn,
    };
  }
}
