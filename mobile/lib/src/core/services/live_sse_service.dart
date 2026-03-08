import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const String _baseUrl = 'https://liggin.xyz';
const String _liveStateUrl = '$_baseUrl/api/live/state';
const String _liveStreamUrl = '$_baseUrl/api/live/stream';

/// Data model for a single driver position from SSE
class SseDriverPosition {
  final int position;
  final int driverNumber;
  final String driverId;
  final String acronym;
  final String name;
  final String team;
  final String gap;
  final int pitStops;
  final bool retired;

  SseDriverPosition({
    required this.position,
    required this.driverNumber,
    required this.driverId,
    required this.acronym,
    required this.name,
    required this.team,
    required this.gap,
    this.pitStops = 0,
    this.retired = false,
  });

  factory SseDriverPosition.fromJson(Map<String, dynamic> json) {
    return SseDriverPosition(
      position: json['position'] ?? 0,
      driverNumber: json['driverNumber'] ?? 0,
      driverId: json['driverId'] ?? '',
      acronym: json['acronym'] ?? '',
      name: json['name'] ?? 'Unknown',
      team: json['team'] ?? '',
      gap: json['gap'] ?? '',
      pitStops: json['pitStops'] ?? 0,
      retired: json['retired'] ?? false,
    );
  }
}

/// Data model for a user's live score from SSE
class SseUserScore {
  final String uid;
  final String displayName;
  final String avatarUrl;
  final int livePoints;
  final Map<String, String> predictions;
  final bool joker;

  SseUserScore({
    required this.uid,
    required this.displayName,
    required this.avatarUrl,
    required this.livePoints,
    required this.predictions,
    this.joker = false,
  });

  factory SseUserScore.fromJson(Map<String, dynamic> json) {
    final preds = json['predictions'] as Map<String, dynamic>? ?? {};
    return SseUserScore(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? 'Unknown',
      avatarUrl: json['avatarUrl'] ?? '',
      livePoints: json['livePoints'] ?? 0,
      predictions: preds.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      joker: json['joker'] ?? false,
    );
  }
}

/// Full live race state from SSE
class LiveRaceState {
  final String raceId;
  final String status;
  final int currentLap;
  final int totalLaps;
  final List<SseDriverPosition> positions;
  final List<SseUserScore> userScores;
  final String updatedAt;

  LiveRaceState({
    required this.raceId,
    required this.status,
    required this.currentLap,
    required this.totalLaps,
    required this.positions,
    required this.userScores,
    required this.updatedAt,
  });

  factory LiveRaceState.fromJson(Map<String, dynamic> json) {
    final positions = (json['positions'] as List? ?? [])
        .map((p) => SseDriverPosition.fromJson(p as Map<String, dynamic>))
        .toList();
    final scores = (json['userScores'] as List? ?? [])
        .map((s) => SseUserScore.fromJson(s as Map<String, dynamic>))
        .toList();

    return LiveRaceState(
      raceId: json['raceId'] ?? '',
      status: json['status'] ?? 'waiting',
      currentLap: json['currentLap'] ?? 0,
      totalLaps: json['totalLaps'] ?? 0,
      positions: positions,
      userScores: scores,
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  bool get isActive => status != 'waiting';
}

/// SSE-based live race data provider
final liveRaceSseProvider = StreamProvider<LiveRaceState>((ref) {
  return _connectSse();
});

/// One-shot state fetch (for initial load)
Future<LiveRaceState?> fetchLiveState() async {
  try {
    final resp = await http.get(Uri.parse(_liveStateUrl)).timeout(const Duration(seconds: 5));
    if (resp.statusCode == 200) {
      return LiveRaceState.fromJson(json.decode(resp.body));
    }
  } catch (e) {
    if (kDebugMode) print('[SSE] fetchLiveState error: $e');
  }
  return null;
}

/// Connect to SSE stream with auto-reconnect
Stream<LiveRaceState> _connectSse() async* {
  while (true) {
    try {
      if (kDebugMode) print('[SSE] Connecting to $_liveStreamUrl');
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_liveStreamUrl));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await client.send(request).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        if (kDebugMode) print('[SSE] Status ${response.statusCode}, retrying in 10s');
        await Future.delayed(const Duration(seconds: 10));
        continue;
      }

      if (kDebugMode) print('[SSE] Connected');

      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String buffer = '';
      await for (final line in lines) {
        if (line.startsWith('data: ')) {
          buffer = line.substring(6);
        } else if (line.isEmpty && buffer.isNotEmpty) {
          try {
            final data = json.decode(buffer) as Map<String, dynamic>;
            yield LiveRaceState.fromJson(data);
          } catch (e) {
            if (kDebugMode) print('[SSE] Parse error: $e');
          }
          buffer = '';
        } else if (line.startsWith(':')) {
          // Comment/keepalive, ignore
        }
      }

      if (kDebugMode) print('[SSE] Stream ended, reconnecting in 5s');
      client.close();
    } catch (e) {
      if (kDebugMode) print('[SSE] Error: $e, reconnecting in 10s');
    }
    await Future.delayed(const Duration(seconds: 10));
  }
}
