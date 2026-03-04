import 'package:cloud_firestore/cloud_firestore.dart';

class BonusRound {
  final String id;
  final String type;
  final String questionHu;
  final String questionEn;
  final List<String> options;
  final String? correctAnswer;
  final DateTime activeFrom;
  final DateTime activeTo;
  final int bonusPoints;

  const BonusRound({
    required this.id,
    required this.type,
    required this.questionHu,
    required this.questionEn,
    required this.options,
    this.correctAnswer,
    required this.activeFrom,
    required this.activeTo,
    required this.bonusPoints,
  });

  factory BonusRound.fromFirestore(Map<String, dynamic> data, String id) {
    return BonusRound(
      id: id,
      type: data['type'] as String,
      questionHu: data['questionHu'] as String,
      questionEn: data['questionEn'] as String,
      options: List<String>.from(data['options'] as List),
      correctAnswer: data['correctAnswer'] as String?,
      activeFrom: (data['activeFrom'] as Timestamp).toDate(),
      activeTo: (data['activeTo'] as Timestamp).toDate(),
      bonusPoints: data['bonusPoints'] as int,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'questionHu': questionHu,
      'questionEn': questionEn,
      'options': options,
      'correctAnswer': correctAnswer,
      'activeFrom': Timestamp.fromDate(activeFrom),
      'activeTo': Timestamp.fromDate(activeTo),
      'bonusPoints': bonusPoints,
    };
  }
}
