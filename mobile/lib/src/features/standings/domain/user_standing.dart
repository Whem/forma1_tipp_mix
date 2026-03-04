class UserStanding {
  final String uid;
  final String displayName;
  final String? avatarUrl;
  final int totalPoints;
  final int seasonPoints;
  final int racePoints;
  final int racesParticipated;
  final int correctP1Count;
  final int streakBest;
  final Map<String, int> racePointsMap;
  final bool isAI;
  final bool isAIAssisted;

  const UserStanding({
    required this.uid,
    required this.displayName,
    this.avatarUrl,
    required this.totalPoints,
    required this.seasonPoints,
    required this.racePoints,
    required this.racesParticipated,
    required this.correctP1Count,
    required this.streakBest,
    required this.racePointsMap,
    this.isAI = false,
    this.isAIAssisted = false,
  });

  factory UserStanding.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserStanding(
      uid: uid,
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      totalPoints: data['totalPoints'] as int? ?? 0,
      seasonPoints: data['seasonPoints'] as int? ?? 0,
      racePoints: data['racePoints'] as int? ?? 0,
      racesParticipated: data['racesParticipated'] as int? ?? 0,
      correctP1Count: data['correctP1Count'] as int? ?? 0,
      streakBest: data['streakBest'] as int? ?? 0,
      racePointsMap: data['racePointsMap'] != null
          ? Map<String, int>.from(data['racePointsMap'] as Map)
          : {},
      isAI: data['isAI'] as bool? ?? false,
      isAIAssisted: data['isAIAssisted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'totalPoints': totalPoints,
      'seasonPoints': seasonPoints,
      'racePoints': racePoints,
      'racesParticipated': racesParticipated,
      'correctP1Count': correctP1Count,
      'streakBest': streakBest,
      'racePointsMap': racePointsMap,
    };
  }
}
