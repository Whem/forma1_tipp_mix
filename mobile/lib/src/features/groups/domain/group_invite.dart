import 'package:cloud_firestore/cloud_firestore.dart';

class GroupInvite {
  const GroupInvite({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String fromUid;
  final String fromName;
  final String toUid;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  factory GroupInvite.fromFirestore(Map<String, dynamic> data, String id) {
    return GroupInvite(
      id: id,
      groupId: data['groupId'] as String? ?? '',
      groupName: data['groupName'] as String? ?? '',
      fromUid: data['fromUid'] as String? ?? '',
      fromName: data['fromName'] as String? ?? '',
      toUid: data['toUid'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'fromUid': fromUid,
      'fromName': fromName,
      'toUid': toUid,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
