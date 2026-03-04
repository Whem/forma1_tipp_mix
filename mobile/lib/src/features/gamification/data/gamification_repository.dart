import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/gamification/domain/achievement.dart';
import 'package:forma1_tipp/src/features/gamification/domain/bonus_round.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(firestore: ref.watch(firestoreProvider));
});

final allAchievementDefsProvider = StreamProvider<List<Achievement>>((ref) {
  return ref.watch(gamificationRepositoryProvider).watchAchievementDefs();
});

final activeBonusRoundsProvider = StreamProvider<List<BonusRound>>((ref) {
  return ref.watch(gamificationRepositoryProvider).watchActiveBonusRounds();
});

final userAchievementsProvider =
    FutureProvider.family<List<Achievement>, String>((ref, uid) {
  return ref.watch(gamificationRepositoryProvider).getUserAchievements(uid);
});

class GamificationRepository {
  GamificationRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<List<Achievement>> watchAchievementDefs() {
    return _firestore.collection('achievements').snapshots().map(
          (snap) => snap.docs
              .map((doc) => Achievement.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<BonusRound>> watchActiveBonusRounds() {
    final now = Timestamp.fromDate(DateTime.now());
    return _firestore
        .collection('bonusRounds')
        .where('activeFrom', isLessThanOrEqualTo: now)
        .where('activeTo', isGreaterThanOrEqualTo: now)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BonusRound.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<List<Achievement>> getUserAchievements(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final data = userDoc.data();
    if (data == null) return [];

    final ids = List<String>.from(data['achievementIds'] as List? ?? []);
    if (ids.isEmpty) return [];

    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }

    final results = <Achievement>[];
    for (final chunk in chunks) {
      final snap = await _firestore
          .collection('achievements')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(
        snap.docs.map((doc) => Achievement.fromFirestore(doc.data(), doc.id)),
      );
    }
    return results;
  }

  Future<void> submitBonusRoundAnswer(
    String bonusRoundId,
    String uid,
    String answer,
  ) {
    return _firestore
        .collection('bonusRounds')
        .doc(bonusRoundId)
        .collection('answers')
        .doc(uid)
        .set({
      'answer': answer,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> useJoker(String uid, String raceId) {
    final batch = _firestore.batch();

    batch.update(_firestore.collection('users').doc(uid), {
      'jokersRemaining': FieldValue.increment(-1),
    });

    batch.update(
      _firestore
          .collection('users')
          .doc(uid)
          .collection('predictions')
          .doc(raceId),
      {'jokerUsed': true},
    );

    return batch.commit();
  }

  Future<void> checkAndAwardAchievements(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final data = userDoc.data();
    if (data == null) return;

    final currentIds =
        List<String>.from(data['achievementIds'] as List? ?? []);
    final totalPoints = data['totalPoints'] as int? ?? 0;
    final streak = data['streak'] as int? ?? 0;
    final racesParticipated = data['racesParticipated'] as int? ?? 0;

    final allDefs = await _firestore.collection('achievements').get();
    final newIds = <String>[];

    for (final doc in allDefs.docs) {
      if (currentIds.contains(doc.id)) continue;
      final def = Achievement.fromFirestore(doc.data(), doc.id);

      int currentValue;
      switch (def.type) {
        case 'points':
          currentValue = totalPoints;
        case 'streak':
          currentValue = streak;
        case 'races':
          currentValue = racesParticipated;
        default:
          continue;
      }

      if (currentValue >= def.threshold) {
        newIds.add(doc.id);
      }
    }

    if (newIds.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update({
        'achievementIds': FieldValue.arrayUnion(newIds),
      });
    }
  }
}
