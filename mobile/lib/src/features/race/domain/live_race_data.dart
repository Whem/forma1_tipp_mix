import 'package:cloud_firestore/cloud_firestore.dart';

class LivePosition {
  final String driverId;
  final int position;
  final String gap;
  final int pitStops;
  final bool retired;

  const LivePosition({
    required this.driverId,
    required this.position,
    required this.gap,
    required this.pitStops,
    required this.retired,
  });

  factory LivePosition.fromMap(Map<String, dynamic> data) {
    return LivePosition(
      driverId: data['driverId'] as String,
      position: data['position'] as int,
      gap: data['gap'] as String? ?? '',
      pitStops: data['pitStops'] as int? ?? 0,
      retired: data['retired'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'position': position,
      'gap': gap,
      'pitStops': pitStops,
      'retired': retired,
    };
  }
}

class LiveRaceData {
  final String raceId;
  final int currentLap;
  final int totalLaps;
  final String status;
  final List<LivePosition> positions;
  final DateTime updatedAt;

  const LiveRaceData({
    required this.raceId,
    required this.currentLap,
    required this.totalLaps,
    required this.status,
    required this.positions,
    required this.updatedAt,
  });

  factory LiveRaceData.fromFirestore(Map<String, dynamic> data, String id) {
    final positionsRaw = data['positions'] as List? ?? [];
    return LiveRaceData(
      raceId: id,
      currentLap: data['currentLap'] as int? ?? 0,
      totalLaps: data['totalLaps'] as int? ?? 0,
      status: data['status'] as String? ?? 'pre_race',
      positions: positionsRaw
          .map((e) => LivePosition.fromMap(e as Map<String, dynamic>))
          .toList(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'currentLap': currentLap,
      'totalLaps': totalLaps,
      'status': status,
      'positions': positions.map((p) => p.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
