import 'package:cloud_firestore/cloud_firestore.dart';

class FriendGroup {
  const FriendGroup({
    required this.id,
    required this.name,
    required this.creatorUid,
    required this.memberUids,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String creatorUid;
  final List<String> memberUids;
  final DateTime createdAt;

  factory FriendGroup.fromFirestore(Map<String, dynamic> data, String id) {
    return FriendGroup(
      id: id,
      name: data['name'] as String? ?? '',
      creatorUid: data['creatorUid'] as String? ?? '',
      memberUids: List<String>.from(data['memberUids'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'creatorUid': creatorUid,
      'memberUids': memberUids,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
