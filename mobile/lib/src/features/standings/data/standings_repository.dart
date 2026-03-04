import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/standings/domain/user_standing.dart';

enum AIFilter { all, humanOnly, aiOnly }

final standingsRepositoryProvider = Provider<StandingsRepository>((ref) {
  return StandingsRepository(firestore: ref.watch(firestoreProvider));
});

final allStandingsProvider = StreamProvider<List<UserStanding>>((ref) {
  return ref.watch(standingsRepositoryProvider).watchStandings();
});

final filteredStandingsProvider =
    StreamProvider.family<List<UserStanding>, AIFilter>((ref, filter) {
  return ref.watch(standingsRepositoryProvider).watchStandings(aiFilter: filter);
});

final groupStandingsProvider =
    StreamProvider.family<List<UserStanding>, List<String>>((ref, memberUids) {
  return ref
      .watch(standingsRepositoryProvider)
      .watchStandings(groupMemberUids: memberUids);
});

class StandingsRepository {
  StandingsRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<List<UserStanding>> watchStandings({
    AIFilter aiFilter = AIFilter.all,
    List<String>? groupMemberUids,
  }) {
    return _firestore
        .collection('users')
        .orderBy('totalPoints', descending: true)
        .snapshots()
        .map((snap) {
      var standings = snap.docs
          .map((doc) => UserStanding.fromFirestore(doc.data(), doc.id))
          .toList();

      if (aiFilter == AIFilter.humanOnly) {
        standings = standings.where((s) => !s.isAI && !s.isAIAssisted).toList();
      } else if (aiFilter == AIFilter.aiOnly) {
        standings = standings.where((s) => s.isAI || s.isAIAssisted).toList();
      }

      if (groupMemberUids != null && groupMemberUids.isNotEmpty) {
        standings = standings
            .where((s) => groupMemberUids.contains(s.uid))
            .toList();
      }

      return standings;
    });
  }
}
