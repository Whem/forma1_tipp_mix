import 'package:flutter_test/flutter_test.dart';
import 'package:forma1_tipp/src/core/utils/scoring.dart';
import 'package:forma1_tipp/src/features/race/domain/race_prediction.dart';
import 'package:forma1_tipp/src/features/race/domain/race_result.dart';

RacePrediction _prediction({
  String p1 = 'VER',
  String p2 = 'HAM',
  String p3 = 'NOR',
  String pole = 'VER',
  String fastestLap = 'VER',
  bool isJoker = false,
}) {
  return RacePrediction(
    id: 'pred1',
    raceId: 'race1',
    uid: 'user1',
    p1: p1,
    p2: p2,
    p3: p3,
    pole: pole,
    fastestLap: fastestLap,
    isJoker: isJoker,
    submittedAt: DateTime(2026, 3, 1),
  );
}

RaceResult _result({
  String p1 = 'VER',
  String p2 = 'HAM',
  String p3 = 'NOR',
  String pole = 'VER',
  String fastestLap = 'VER',
}) {
  return RaceResult(
    id: 'res1',
    raceId: 'race1',
    p1: p1,
    p2: p2,
    p3: p3,
    pole: pole,
    fastestLap: fastestLap,
    dnfs: [],
    safetyCarCount: 0,
    isProcessed: true,
  );
}

void main() {
  group('calculateRacePoints', () {
    test('perfect prediction scores 73 points', () {
      final prediction = _prediction();
      final result = _result();

      expect(calculateRacePoints(prediction, result), 73);
    });

    test('only P1 exact correct + predicted P2 in podium = 30 pts', () {
      final prediction = _prediction(
        p1: 'VER',
        p2: 'NOR',
        p3: 'LEC',
        pole: 'SAI',
        fastestLap: 'SAI',
      );
      final result = _result(
        p1: 'VER',
        p2: 'HAM',
        p3: 'NOR',
        pole: 'HAM',
        fastestLap: 'HAM',
      );

      // P1 exact = 25, P2 (NOR) in podium but wrong pos = 5
      expect(calculateRacePoints(prediction, result), 30);
    });

    test('only P2 exact correct + predicted P1 in podium = 23 pts', () {
      final prediction = _prediction(
        p1: 'HAM',
        p2: 'NOR',
        p3: 'LEC',
        pole: 'SAI',
        fastestLap: 'SAI',
      );
      final result = _result(
        p1: 'VER',
        p2: 'NOR',
        p3: 'HAM',
        pole: 'VER',
        fastestLap: 'VER',
      );

      // P1 (HAM) in podium = 5, P2 exact = 18
      expect(calculateRacePoints(prediction, result), 23);
    });

    test('only P3 exact correct + predicted P1 in podium = 20 pts', () {
      final prediction = _prediction(
        p1: 'HAM',
        p2: 'LEC',
        p3: 'NOR',
        pole: 'SAI',
        fastestLap: 'SAI',
      );
      final result = _result(
        p1: 'VER',
        p2: 'HAM',
        p3: 'NOR',
        pole: 'VER',
        fastestLap: 'VER',
      );

      // P1 (HAM) in podium = 5, P3 exact = 15
      expect(calculateRacePoints(prediction, result), 20);
    });

    test('all podium drivers correct but wrong positions = 15 pts', () {
      final prediction = _prediction(
        p1: 'HAM',
        p2: 'NOR',
        p3: 'VER',
        pole: 'SAI',
        fastestLap: 'SAI',
      );
      final result = _result(
        p1: 'VER',
        p2: 'HAM',
        p3: 'NOR',
        pole: 'VER',
        fastestLap: 'VER',
      );

      // Each driver in podium but wrong slot: 3 x 5 = 15
      expect(calculateRacePoints(prediction, result), 15);
    });

    test('only pole correct = 10 pts', () {
      final prediction = _prediction(
        p1: 'SAI',
        p2: 'ALO',
        p3: 'STR',
        pole: 'VER',
        fastestLap: 'ALO',
      );
      final result = _result(
        p1: 'VER',
        p2: 'HAM',
        p3: 'NOR',
        pole: 'VER',
        fastestLap: 'NOR',
      );

      expect(calculateRacePoints(prediction, result), 10);
    });

    test('only fastest lap correct = 5 pts', () {
      final prediction = _prediction(
        p1: 'SAI',
        p2: 'ALO',
        p3: 'STR',
        pole: 'ALO',
        fastestLap: 'NOR',
      );
      final result = _result(
        p1: 'VER',
        p2: 'HAM',
        p3: 'LEC',
        pole: 'VER',
        fastestLap: 'NOR',
      );

      expect(calculateRacePoints(prediction, result), 5);
    });

    test('nothing correct = 0 pts', () {
      final prediction = _prediction(
        p1: 'SAI',
        p2: 'ALO',
        p3: 'STR',
        pole: 'SAI',
        fastestLap: 'ALO',
      );
      final result = _result(
        p1: 'VER',
        p2: 'HAM',
        p3: 'NOR',
        pole: 'VER',
        fastestLap: 'NOR',
      );

      expect(calculateRacePoints(prediction, result), 0);
    });

    test('joker doubles the total', () {
      final prediction = _prediction(
        p1: 'SAI',
        p2: 'ALO',
        p3: 'STR',
        pole: 'VER',
        fastestLap: 'ALO',
        isJoker: true,
      );
      final result = _result(
        p1: 'VER',
        p2: 'HAM',
        p3: 'NOR',
        pole: 'VER',
        fastestLap: 'NOR',
      );

      // Only pole correct = 10, joker doubles → 20
      expect(calculateRacePoints(prediction, result), 20);
    });

    test('perfect prediction with joker = 146 pts', () {
      final prediction = _prediction(isJoker: true);
      final result = _result();

      expect(calculateRacePoints(prediction, result), 146);
    });
  });

  group('ScoringBreakdown', () {
    test('subtotal sums individual components', () {
      final prediction = _prediction();
      final result = _result();
      final breakdown = calculateScoringBreakdown(prediction, result);

      expect(breakdown.p1Points, 25);
      expect(breakdown.p2Points, 18);
      expect(breakdown.p3Points, 15);
      expect(breakdown.polePoints, 10);
      expect(breakdown.fastestLapPoints, 5);
      expect(breakdown.subtotal, 73);
      expect(breakdown.jokerActive, false);
      expect(breakdown.total, 73);
    });

    test('joker flag reflected in breakdown', () {
      final prediction = _prediction(isJoker: true);
      final result = _result();
      final breakdown = calculateScoringBreakdown(prediction, result);

      expect(breakdown.jokerActive, true);
      expect(breakdown.subtotal, 73);
      expect(breakdown.total, 146);
    });
  });
}
