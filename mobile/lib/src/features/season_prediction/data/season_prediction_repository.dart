import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/season_prediction/domain/season_prediction.dart';

final seasonPredictionRepoProvider = Provider<SeasonPredictionRepository>(
  (ref) => SeasonPredictionRepository(ref.watch(firestoreProvider)),
);

final currentSeasonPredictionProvider =
    FutureProvider.family<SeasonPrediction?, String>((ref, uid) {
  final repo = ref.watch(seasonPredictionRepoProvider);
  return repo.getSeasonPrediction(uid, DateTime.now().year);
});

final seasonResultsProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, year) {
  final repo = ref.watch(seasonPredictionRepoProvider);
  return repo.getSeasonResults(year);
});

class SeasonPredictionRepository {
  SeasonPredictionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _predictionsCol(int year) =>
      _firestore
          .collection('seasons')
          .doc('$year')
          .collection('seasonPredictions');

  Future<SeasonPrediction?> getSeasonPrediction(String uid, int year) async {
    final snap =
        await _predictionsCol(year).where('uid', isEqualTo: uid).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return SeasonPrediction.fromFirestore(doc.data(), doc.id);
  }

  Future<Map<String, dynamic>?> getSeasonResults(int year) async {
    final doc = await _firestore.collection('seasons').doc('$year').get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null || data['results'] == null) return null;
    return data['results'] as Map<String, dynamic>;
  }

  Future<void> submitSeasonPrediction(
    String uid,
    int year,
    SeasonPrediction prediction,
  ) {
    final data = prediction.toFirestore();
    data['uid'] = uid;
    return _predictionsCol(year).doc(uid).set(data);
  }
}
