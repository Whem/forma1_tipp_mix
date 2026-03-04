import 'package:forma1_tipp/src/features/race/domain/race_prediction.dart';
import 'package:forma1_tipp/src/features/race/domain/race_result.dart';

const _pointsP1Exact = 25;
const _pointsP2Exact = 18;
const _pointsP3Exact = 15;
const _pointsPoleExact = 10;
const _pointsFastestLapExact = 5;
const _pointsInPodium = 5;

class ScoringBreakdown {
  final int p1Points;
  final int p2Points;
  final int p3Points;
  final int polePoints;
  final int fastestLapPoints;
  final bool jokerActive;

  const ScoringBreakdown({
    required this.p1Points,
    required this.p2Points,
    required this.p3Points,
    required this.polePoints,
    required this.fastestLapPoints,
    required this.jokerActive,
  });

  int get subtotal =>
      p1Points + p2Points + p3Points + polePoints + fastestLapPoints;

  int get total => jokerActive ? subtotal * 2 : subtotal;
}

int calculateRacePoints(RacePrediction prediction, RaceResult result) {
  return calculateScoringBreakdown(prediction, result).total;
}

ScoringBreakdown calculateScoringBreakdown(
  RacePrediction prediction,
  RaceResult result,
) {
  final resultPodium = {result.p1, result.p2, result.p3};

  int p1 = 0;
  if (prediction.p1 == result.p1) {
    p1 = _pointsP1Exact;
  } else if (resultPodium.contains(prediction.p1)) {
    p1 = _pointsInPodium;
  }

  int p2 = 0;
  if (prediction.p2 == result.p2) {
    p2 = _pointsP2Exact;
  } else if (resultPodium.contains(prediction.p2)) {
    p2 = _pointsInPodium;
  }

  int p3 = 0;
  if (prediction.p3 == result.p3) {
    p3 = _pointsP3Exact;
  } else if (resultPodium.contains(prediction.p3)) {
    p3 = _pointsInPodium;
  }

  final pole = prediction.pole == result.pole ? _pointsPoleExact : 0;
  final fl =
      prediction.fastestLap == result.fastestLap ? _pointsFastestLapExact : 0;

  return ScoringBreakdown(
    p1Points: p1,
    p2Points: p2,
    p3Points: p3,
    polePoints: pole,
    fastestLapPoints: fl,
    jokerActive: prediction.isJoker,
  );
}
