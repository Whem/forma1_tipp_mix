import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/race/domain/race.dart';
import 'package:forma1_tipp/src/features/standings/domain/user_standing.dart';

final nextRaceProvider = StreamProvider<Race?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('races')
      .where('raceDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
      .orderBy('raceDate')
      .limit(1)
      .snapshots()
      .map((snap) {
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return Race.fromFirestore(doc.data(), doc.id);
  });
});

final topStandingsProvider = StreamProvider<List<UserStanding>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .orderBy('totalPoints', descending: true)
      .limit(3)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => UserStanding.fromFirestore(doc.data(), doc.id))
          .toList());
});
