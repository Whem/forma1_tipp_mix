import 'package:cloud_firestore/cloud_firestore.dart';

class RacePrediction {
  final String? id;
  final String raceId;
  final String uid;
  final String p1;
  final String p2;
  final String p3;
  final String pole;
  final String fastestLap;
  final bool isJoker;
  final DateTime submittedAt;

  const RacePrediction({
    this.id,
    required this.raceId,
    required this.uid,
    required this.p1,
    required this.p2,
    required this.p3,
    required this.pole,
    required this.fastestLap,
    required this.isJoker,
    required this.submittedAt,
  });

  factory RacePrediction.fromFirestore(Map<String, dynamic> data, String id) {
    return RacePrediction(
      id: id,
      raceId: data['raceId'] as String,
      uid: data['uid'] as String,
      p1: data['p1'] as String,
      p2: data['p2'] as String,
      p3: data['p3'] as String,
      pole: data['pole'] as String,
      fastestLap: data['fastestLap'] as String,
      isJoker: data['isJoker'] as bool,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'raceId': raceId,
      'uid': uid,
      'p1': p1,
      'p2': p2,
      'p3': p3,
      'pole': pole,
      'fastestLap': fastestLap,
      'isJoker': isJoker,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }
}
