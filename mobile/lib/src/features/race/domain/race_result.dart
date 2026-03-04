class RaceResult {
  final String id;
  final String raceId;
  final String p1;
  final String p2;
  final String p3;
  final String pole;
  final String fastestLap;
  final List<String> dnfs;
  final int safetyCarCount;
  final bool isProcessed;

  const RaceResult({
    required this.id,
    required this.raceId,
    required this.p1,
    required this.p2,
    required this.p3,
    required this.pole,
    required this.fastestLap,
    required this.dnfs,
    required this.safetyCarCount,
    required this.isProcessed,
  });

  factory RaceResult.fromFirestore(Map<String, dynamic> data, String id) {
    return RaceResult(
      id: id,
      raceId: data['raceId'] as String,
      p1: data['p1'] as String,
      p2: data['p2'] as String,
      p3: data['p3'] as String,
      pole: data['pole'] as String,
      fastestLap: data['fastestLap'] as String,
      dnfs: List<String>.from(data['dnfs'] as List),
      safetyCarCount: data['safetyCarCount'] as int,
      isProcessed: data['isProcessed'] as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'raceId': raceId,
      'p1': p1,
      'p2': p2,
      'p3': p3,
      'pole': pole,
      'fastestLap': fastestLap,
      'dnfs': dnfs,
      'safetyCarCount': safetyCarCount,
      'isProcessed': isProcessed,
    };
  }
}
