class Driver {
  final String id;
  final String firstName;
  final String lastName;
  final int number;
  final String teamId;
  final String nationality;
  final String shortCode;
  final String? imageUrl;
  final String? flagEmoji;

  const Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.number,
    required this.teamId,
    required this.nationality,
    required this.shortCode,
    this.imageUrl,
    this.flagEmoji,
  });

  String get fullName => '$firstName $lastName';

  factory Driver.fromFirestore(Map<String, dynamic> data, String id) {
    return Driver(
      id: id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      number: (data['number'] as num?)?.toInt() ?? 0,
      teamId: data['teamId'] as String? ?? '',
      nationality: data['nationality'] as String? ??
          data['country'] as String? ??
          '',
      shortCode: data['shortCode'] as String? ??
          data['abbr'] as String? ??
          '',
      imageUrl: data['imageUrl'] as String?,
      flagEmoji: data['flagEmoji'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'number': number,
      'teamId': teamId,
      'nationality': nationality,
      'shortCode': shortCode,
      'imageUrl': imageUrl,
      'flagEmoji': flagEmoji,
    };
  }
}
