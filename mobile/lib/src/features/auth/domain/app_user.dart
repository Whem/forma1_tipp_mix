import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.language = 'en',
    this.streak = 0,
    this.lastPredictionDate,
    this.jokerUsed = false,
    this.jokersRemaining = 3,
    this.achievementIds = const [],
    this.friendCode = '',
    this.isAIAssisted = false,
    this.groupIds = const [],
    required this.createdAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String language;
  final int streak;
  final DateTime? lastPredictionDate;
  final bool jokerUsed;
  final int jokersRemaining;
  final List<String> achievementIds;
  final String friendCode;
  final bool isAIAssisted;
  final List<String> groupIds;
  final DateTime createdAt;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      language: data['language'] as String? ?? 'en',
      streak: data['streak'] as int? ?? 0,
      lastPredictionDate:
          (data['lastPredictionDate'] as Timestamp?)?.toDate(),
      jokerUsed: data['jokerUsed'] as bool? ?? false,
      jokersRemaining: data['jokersRemaining'] as int? ?? 3,
      achievementIds:
          List<String>.from(data['achievementIds'] as List? ?? []),
      friendCode: data['friendCode'] as String? ?? '',
      isAIAssisted: data['isAIAssisted'] as bool? ?? false,
      groupIds: List<String>.from(data['groupIds'] as List? ?? []),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'language': language,
      'streak': streak,
      'lastPredictionDate': lastPredictionDate != null
          ? Timestamp.fromDate(lastPredictionDate!)
          : null,
      'jokerUsed': jokerUsed,
      'jokersRemaining': jokersRemaining,
      'achievementIds': achievementIds,
      'friendCode': friendCode,
      'isAIAssisted': isAIAssisted,
      'groupIds': groupIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? language,
    int? streak,
    DateTime? lastPredictionDate,
    bool? jokerUsed,
    int? jokersRemaining,
    List<String>? achievementIds,
    String? friendCode,
    bool? isAIAssisted,
    List<String>? groupIds,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language ?? this.language,
      streak: streak ?? this.streak,
      lastPredictionDate: lastPredictionDate ?? this.lastPredictionDate,
      jokerUsed: jokerUsed ?? this.jokerUsed,
      jokersRemaining: jokersRemaining ?? this.jokersRemaining,
      achievementIds: achievementIds ?? this.achievementIds,
      friendCode: friendCode ?? this.friendCode,
      isAIAssisted: isAIAssisted ?? this.isAIAssisted,
      groupIds: groupIds ?? this.groupIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
