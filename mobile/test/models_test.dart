import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma1_tipp/src/features/gamification/domain/achievement.dart';
import 'package:forma1_tipp/src/features/race/domain/driver.dart';
import 'package:forma1_tipp/src/features/race/domain/race.dart';
import 'package:forma1_tipp/src/features/race/domain/race_prediction.dart';
import 'package:forma1_tipp/src/features/race/domain/race_result.dart';
import 'package:forma1_tipp/src/features/season_prediction/domain/season_prediction.dart';
import 'package:forma1_tipp/src/features/standings/domain/user_standing.dart';
import 'package:forma1_tipp/src/features/race/domain/team.dart';

void main() {
  group('Team', () {
    final data = <String, dynamic>{
      'name': 'Red Bull Racing',
      'shortName': 'RBR',
      'color': '#0600EF',
      'engineSupplier': 'Honda',
      'principal': 'Christian Horner',
      'logoUrl': 'https://example.com/rbr.png',
      'nameHu': 'Red Bull Racing',
      'nameEn': 'Red Bull Racing',
    };

    test('fromFirestore parses all fields', () {
      final team = Team.fromFirestore(data, 'team_rbr');

      expect(team.id, 'team_rbr');
      expect(team.name, 'Red Bull Racing');
      expect(team.shortName, 'RBR');
      expect(team.color, '#0600EF');
      expect(team.engineSupplier, 'Honda');
      expect(team.principal, 'Christian Horner');
      expect(team.logoUrl, 'https://example.com/rbr.png');
      expect(team.nameHu, 'Red Bull Racing');
      expect(team.nameEn, 'Red Bull Racing');
    });

    test('toFirestore produces correct map (excludes id)', () {
      final team = Team.fromFirestore(data, 'team_rbr');
      final map = team.toFirestore();

      expect(map, data);
      expect(map.containsKey('id'), false);
    });

    test('fromFirestore handles null logoUrl', () {
      final noLogo = Map<String, dynamic>.from(data)..['logoUrl'] = null;
      final team = Team.fromFirestore(noLogo, 'team_rbr');

      expect(team.logoUrl, isNull);
    });
  });

  group('Driver', () {
    final data = <String, dynamic>{
      'firstName': 'Max',
      'lastName': 'Verstappen',
      'number': 1,
      'teamId': 'team_rbr',
      'nationality': 'Dutch',
      'shortCode': 'VER',
      'imageUrl': 'https://example.com/ver.png',
    };

    test('fromFirestore parses all fields', () {
      final driver = Driver.fromFirestore(data, 'driver_ver');

      expect(driver.id, 'driver_ver');
      expect(driver.firstName, 'Max');
      expect(driver.lastName, 'Verstappen');
      expect(driver.number, 1);
      expect(driver.teamId, 'team_rbr');
      expect(driver.nationality, 'Dutch');
      expect(driver.shortCode, 'VER');
      expect(driver.imageUrl, 'https://example.com/ver.png');
      expect(driver.fullName, 'Max Verstappen');
    });

    test('toFirestore produces correct map', () {
      final driver = Driver.fromFirestore(data, 'driver_ver');
      final map = driver.toFirestore();

      expect(map, data);
      expect(map.containsKey('id'), false);
    });

    test('fromFirestore handles null imageUrl', () {
      final noImg = Map<String, dynamic>.from(data)..['imageUrl'] = null;
      final driver = Driver.fromFirestore(noImg, 'driver_ver');

      expect(driver.imageUrl, isNull);
    });
  });

  group('Race', () {
    final raceDate = DateTime(2026, 3, 15, 14, 0);
    final data = <String, dynamic>{
      'round': 1,
      'nameHu': 'Bahreini Nagydíj',
      'nameEn': 'Bahrain Grand Prix',
      'circuit': 'Bahrain International Circuit',
      'country': 'Bahrain',
      'countryCode': 'BH',
      'flagEmoji': '🇧🇭',
      'raceDate': Timestamp.fromDate(raceDate),
      'sprintWeekend': false,
    };

    test('fromFirestore converts Timestamp to DateTime', () {
      final race = Race.fromFirestore(data, 'race_bah');

      expect(race.id, 'race_bah');
      expect(race.round, 1);
      expect(race.nameHu, 'Bahreini Nagydíj');
      expect(race.nameEn, 'Bahrain Grand Prix');
      expect(race.circuit, 'Bahrain International Circuit');
      expect(race.country, 'Bahrain');
      expect(race.countryCode, 'BH');
      expect(race.flagEmoji, '🇧🇭');
      expect(race.raceDate, raceDate);
      expect(race.sprintWeekend, false);
    });

    test('toFirestore converts DateTime back to Timestamp', () {
      final race = Race.fromFirestore(data, 'race_bah');
      final map = race.toFirestore();

      expect(map['raceDate'], isA<Timestamp>());
      expect((map['raceDate'] as Timestamp).toDate(), raceDate);
      expect(map['round'], 1);
      expect(map.containsKey('id'), false);
    });
  });

  group('SeasonPrediction', () {
    final submittedAt = DateTime(2026, 2, 28, 10, 0);
    final data = <String, dynamic>{
      'driverChampion': 'VER',
      'constructorChampion': 'RBR',
      'winnerPoints': 450,
      'pointDifference': 100,
      'lastConstructor': 'WIL',
      'lastDriver': 'SAR',
      'submittedAt': Timestamp.fromDate(submittedAt),
    };

    test('fromFirestore parses all fields', () {
      final sp = SeasonPrediction.fromFirestore(data, 'sp1');

      expect(sp.id, 'sp1');
      expect(sp.driverChampion, 'VER');
      expect(sp.constructorChampion, 'RBR');
      expect(sp.winnerPoints, 450);
      expect(sp.pointDifference, 100);
      expect(sp.lastConstructor, 'WIL');
      expect(sp.lastDriver, 'SAR');
      expect(sp.submittedAt, submittedAt);
    });

    test('toFirestore roundtrips Timestamp correctly', () {
      final sp = SeasonPrediction.fromFirestore(data, 'sp1');
      final map = sp.toFirestore();

      expect(map['submittedAt'], isA<Timestamp>());
      expect((map['submittedAt'] as Timestamp).toDate(), submittedAt);
      expect(map['driverChampion'], 'VER');
      expect(map.containsKey('id'), false);
    });
  });

  group('RacePrediction', () {
    final submittedAt = DateTime(2026, 3, 14, 12, 0);
    final data = <String, dynamic>{
      'raceId': 'race_bah',
      'uid': 'user1',
      'p1': 'VER',
      'p2': 'HAM',
      'p3': 'NOR',
      'pole': 'VER',
      'fastestLap': 'HAM',
      'isJoker': true,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };

    test('fromFirestore parses all fields', () {
      final rp = RacePrediction.fromFirestore(data, 'rp1');

      expect(rp.id, 'rp1');
      expect(rp.raceId, 'race_bah');
      expect(rp.uid, 'user1');
      expect(rp.p1, 'VER');
      expect(rp.p2, 'HAM');
      expect(rp.p3, 'NOR');
      expect(rp.pole, 'VER');
      expect(rp.fastestLap, 'HAM');
      expect(rp.isJoker, true);
      expect(rp.submittedAt, submittedAt);
    });

    test('toFirestore roundtrips correctly', () {
      final rp = RacePrediction.fromFirestore(data, 'rp1');
      final map = rp.toFirestore();

      expect(map['raceId'], 'race_bah');
      expect(map['isJoker'], true);
      expect(map['submittedAt'], isA<Timestamp>());
      expect((map['submittedAt'] as Timestamp).toDate(), submittedAt);
      expect(map.containsKey('id'), false);
    });
  });

  group('RaceResult', () {
    final data = <String, dynamic>{
      'raceId': 'race_bah',
      'p1': 'VER',
      'p2': 'HAM',
      'p3': 'NOR',
      'pole': 'VER',
      'fastestLap': 'VER',
      'dnfs': ['SAI', 'ALO'],
      'safetyCarCount': 2,
      'isProcessed': true,
    };

    test('fromFirestore parses all fields including list', () {
      final rr = RaceResult.fromFirestore(data, 'rr1');

      expect(rr.id, 'rr1');
      expect(rr.raceId, 'race_bah');
      expect(rr.p1, 'VER');
      expect(rr.p2, 'HAM');
      expect(rr.p3, 'NOR');
      expect(rr.pole, 'VER');
      expect(rr.fastestLap, 'VER');
      expect(rr.dnfs, ['SAI', 'ALO']);
      expect(rr.safetyCarCount, 2);
      expect(rr.isProcessed, true);
    });

    test('toFirestore produces correct map', () {
      final rr = RaceResult.fromFirestore(data, 'rr1');
      final map = rr.toFirestore();

      expect(map, data);
      expect(map.containsKey('id'), false);
    });

    test('empty dnfs list roundtrips', () {
      final emptyDnfs = Map<String, dynamic>.from(data)..['dnfs'] = <String>[];
      final rr = RaceResult.fromFirestore(emptyDnfs, 'rr1');

      expect(rr.dnfs, isEmpty);
      expect(rr.toFirestore()['dnfs'], isEmpty);
    });
  });

  group('Achievement', () {
    final data = <String, dynamic>{
      'nameHu': 'Első tipp',
      'nameEn': 'First Prediction',
      'descriptionHu': 'Adtad le az első tipped.',
      'descriptionEn': 'You submitted your first prediction.',
      'icon': '🏆',
      'threshold': 1,
      'type': 'prediction_count',
    };

    test('fromFirestore parses all fields', () {
      final ach = Achievement.fromFirestore(data, 'ach_first');

      expect(ach.id, 'ach_first');
      expect(ach.nameHu, 'Első tipp');
      expect(ach.nameEn, 'First Prediction');
      expect(ach.descriptionHu, 'Adtad le az első tipped.');
      expect(ach.descriptionEn, 'You submitted your first prediction.');
      expect(ach.icon, '🏆');
      expect(ach.threshold, 1);
      expect(ach.type, 'prediction_count');
    });

    test('toFirestore produces correct map', () {
      final ach = Achievement.fromFirestore(data, 'ach_first');
      final map = ach.toFirestore();

      expect(map, data);
      expect(map.containsKey('id'), false);
    });
  });

  group('UserStanding', () {
    final data = <String, dynamic>{
      'displayName': 'SpeedKing',
      'avatarUrl': 'https://example.com/avatar.png',
      'totalPoints': 250,
      'seasonPoints': 50,
      'racePoints': 200,
      'racesParticipated': 10,
      'correctP1Count': 3,
      'streakBest': 5,
      'racePointsMap': {'race1': 30, 'race2': 45},
    };

    test('fromFirestore parses all fields including map', () {
      final us = UserStanding.fromFirestore(data, 'user_abc');

      expect(us.uid, 'user_abc');
      expect(us.displayName, 'SpeedKing');
      expect(us.avatarUrl, 'https://example.com/avatar.png');
      expect(us.totalPoints, 250);
      expect(us.seasonPoints, 50);
      expect(us.racePoints, 200);
      expect(us.racesParticipated, 10);
      expect(us.correctP1Count, 3);
      expect(us.streakBest, 5);
      expect(us.racePointsMap, {'race1': 30, 'race2': 45});
    });

    test('toFirestore produces correct map', () {
      final us = UserStanding.fromFirestore(data, 'user_abc');
      final map = us.toFirestore();

      expect(map['displayName'], 'SpeedKing');
      expect(map['totalPoints'], 250);
      expect(map['racePointsMap'], {'race1': 30, 'race2': 45});
      expect(map.containsKey('uid'), false);
    });

    test('fromFirestore handles null avatarUrl', () {
      final noAvatar = Map<String, dynamic>.from(data)..['avatarUrl'] = null;
      final us = UserStanding.fromFirestore(noAvatar, 'user_abc');

      expect(us.avatarUrl, isNull);
    });
  });
}
