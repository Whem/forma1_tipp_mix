import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/race/domain/driver.dart';
import 'package:forma1_tipp/src/features/race/domain/live_race_data.dart';
import 'package:forma1_tipp/src/features/race/domain/race.dart';
import 'package:forma1_tipp/src/features/race/domain/race_prediction.dart';
import 'package:forma1_tipp/src/features/race/domain/race_result.dart';
import 'package:forma1_tipp/src/features/race/domain/team.dart';

class RaceRepository {
  RaceRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _racesCol =>
      _firestore.collection('races');

  CollectionReference<Map<String, dynamic>> get _driversCol =>
      _firestore.collection('drivers');

  CollectionReference<Map<String, dynamic>> get _teamsCol =>
      _firestore.collection('teams');

  CollectionReference<Map<String, dynamic>> get _predictionsCol =>
      _firestore.collection('race_predictions');

  CollectionReference<Map<String, dynamic>> get _resultsCol =>
      _firestore.collection('race_results');

  CollectionReference<Map<String, dynamic>> get _liveCol =>
      _firestore.collection('live_races');

  Future<Race?> getRace(String raceId) async {
    final doc = await _racesCol.doc(raceId).get();
    if (!doc.exists) return null;
    return Race.fromFirestore(doc.data()!, doc.id);
  }

  Stream<Race?> watchRace(String raceId) {
    return _racesCol.doc(raceId).snapshots().map(
          (doc) =>
              doc.exists ? Race.fromFirestore(doc.data()!, doc.id) : null,
        );
  }

  Future<List<Driver>> getAllDrivers() async {
    final snap = await _driversCol.get();
    return snap.docs
        .map((doc) => Driver.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<List<Team>> getAllTeams() async {
    final snap = await _teamsCol.get();
    return snap.docs
        .map((doc) => Team.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Stream<RacePrediction?> watchUserPrediction(String raceId, String uid) {
    return _predictionsCol
        .where('raceId', isEqualTo: raceId)
        .where('uid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return RacePrediction.fromFirestore(doc.data(), doc.id);
    });
  }

  Future<void> submitPrediction(RacePrediction prediction) async {
    final existing = await _predictionsCol
        .where('raceId', isEqualTo: prediction.raceId)
        .where('uid', isEqualTo: prediction.uid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await _predictionsCol
          .doc(existing.docs.first.id)
          .update(prediction.toFirestore());
    } else {
      await _predictionsCol.add(prediction.toFirestore());
    }
  }

  Stream<RaceResult?> watchRaceResult(String raceId) {
    return _resultsCol
        .where('raceId', isEqualTo: raceId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return RaceResult.fromFirestore(doc.data(), doc.id);
    });
  }

  Stream<List<Race>> watchAllRaces() {
    return _racesCol.orderBy('round').snapshots().map(
          (snap) => snap.docs
              .map((doc) => Race.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<LiveRaceData?> watchLiveRace(String raceId) {
    return _liveCol.doc(raceId).snapshots().map(
          (doc) => doc.exists
              ? LiveRaceData.fromFirestore(doc.data()!, doc.id)
              : null,
        );
  }
}

final raceRepositoryProvider = Provider<RaceRepository>((ref) {
  return RaceRepository(firestore: ref.watch(firestoreProvider));
});

final allRacesProvider = StreamProvider<List<Race>>((ref) {
  return ref.watch(raceRepositoryProvider).watchAllRaces();
});

final raceProvider = StreamProvider.family<Race?, String>((ref, raceId) {
  return ref.watch(raceRepositoryProvider).watchRace(raceId);
});

final allDriversProvider = FutureProvider<List<Driver>>((ref) {
  return ref.watch(raceRepositoryProvider).getAllDrivers();
});

final allTeamsProvider = FutureProvider<List<Team>>((ref) {
  return ref.watch(raceRepositoryProvider).getAllTeams();
});

final userPredictionProvider =
    StreamProvider.family<RacePrediction?, ({String raceId, String uid})>(
        (ref, params) {
  return ref
      .watch(raceRepositoryProvider)
      .watchUserPrediction(params.raceId, params.uid);
});

final raceResultProvider =
    StreamProvider.family<RaceResult?, String>((ref, raceId) {
  return ref.watch(raceRepositoryProvider).watchRaceResult(raceId);
});

final liveRaceProvider =
    StreamProvider.family<LiveRaceData?, String>((ref, raceId) {
  return ref.watch(raceRepositoryProvider).watchLiveRace(raceId);
});
