import 'package:cloud_firestore/cloud_firestore.dart';

class Race {
  final String id;
  final int round;
  final String nameHu;
  final String nameEn;
  final String circuit;
  final String country;
  final String countryCode;
  final String flagEmoji;
  final DateTime raceDate;
  final bool sprintWeekend;

  const Race({
    required this.id,
    required this.round,
    required this.nameHu,
    required this.nameEn,
    required this.circuit,
    required this.country,
    required this.countryCode,
    required this.flagEmoji,
    required this.raceDate,
    required this.sprintWeekend,
  });

  bool get isPast => raceDate.isBefore(DateTime.now());

  bool get isLocked =>
      DateTime.now().isAfter(raceDate.subtract(const Duration(minutes: 30)));

  factory Race.fromFirestore(Map<String, dynamic> data, String id) {
    return Race(
      id: id,
      round: data['round'] as int,
      nameHu: data['nameHu'] as String,
      nameEn: data['nameEn'] as String,
      circuit: data['circuit'] as String,
      country: data['country'] as String,
      countryCode: data['countryCode'] as String,
      flagEmoji: data['flagEmoji'] as String,
      raceDate: (data['raceDate'] as Timestamp).toDate(),
      sprintWeekend: data['sprintWeekend'] as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'round': round,
      'nameHu': nameHu,
      'nameEn': nameEn,
      'circuit': circuit,
      'country': country,
      'countryCode': countryCode,
      'flagEmoji': flagEmoji,
      'raceDate': Timestamp.fromDate(raceDate),
      'sprintWeekend': sprintWeekend,
    };
  }
}
