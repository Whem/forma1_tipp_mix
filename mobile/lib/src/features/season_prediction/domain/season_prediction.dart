import 'package:cloud_firestore/cloud_firestore.dart';

class SeasonPrediction {
  final String? id;
  final String driverChampion;
  final String constructorChampion;
  final int winnerPoints;
  final int pointDifference;
  final String lastConstructor;
  final String lastDriver;
  final DateTime submittedAt;

  const SeasonPrediction({
    this.id,
    required this.driverChampion,
    required this.constructorChampion,
    required this.winnerPoints,
    required this.pointDifference,
    required this.lastConstructor,
    required this.lastDriver,
    required this.submittedAt,
  });

  factory SeasonPrediction.fromFirestore(Map<String, dynamic> data, String id) {
    return SeasonPrediction(
      id: id,
      driverChampion: data['driverChampion'] as String,
      constructorChampion: data['constructorChampion'] as String,
      winnerPoints: data['winnerPoints'] as int,
      pointDifference: data['pointDifference'] as int,
      lastConstructor: data['lastConstructor'] as String,
      lastDriver: data['lastDriver'] as String,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'driverChampion': driverChampion,
      'constructorChampion': constructorChampion,
      'winnerPoints': winnerPoints,
      'pointDifference': pointDifference,
      'lastConstructor': lastConstructor,
      'lastDriver': lastDriver,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }
}
