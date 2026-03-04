import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/groups/domain/friend_group.dart';
import 'package:forma1_tipp/src/features/groups/domain/group_invite.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(firestore: ref.watch(firestoreProvider));
});

final myGroupsProvider = StreamProvider.family<List<FriendGroup>, String>(
  (ref, uid) => ref.watch(groupRepositoryProvider).watchMyGroups(uid),
);

final pendingInvitesProvider = StreamProvider.family<List<GroupInvite>, String>(
  (ref, uid) => ref.watch(groupRepositoryProvider).watchPendingInvites(uid),
);

class GroupRepository {
  GroupRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _groupsCol =>
      _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> get _invitesCol =>
      _firestore.collection('group_invites');

  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');

  Future<String> createGroup({
    required String name,
    required String creatorUid,
  }) async {
    final doc = await _groupsCol.add({
      'name': name,
      'creatorUid': creatorUid,
      'memberUids': [creatorUid],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(creatorUid).update({
      'groupIds': FieldValue.arrayUnion([doc.id]),
    });

    return doc.id;
  }

  Stream<List<FriendGroup>> watchMyGroups(String uid) {
    return _groupsCol
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FriendGroup.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<FriendGroup?> getGroup(String groupId) async {
    final doc = await _groupsCol.doc(groupId).get();
    if (!doc.exists) return null;
    return FriendGroup.fromFirestore(doc.data()!, doc.id);
  }

  Stream<FriendGroup?> watchGroup(String groupId) {
    return _groupsCol.doc(groupId).snapshots().map(
          (doc) =>
              doc.exists ? FriendGroup.fromFirestore(doc.data()!, doc.id) : null,
        );
  }

  Future<String?> findUserByFriendCode(String code) async {
    final snap = await _firestore
        .collection('users')
        .where('friendCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<String?> getUserDisplayName(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['displayName'] as String?;
  }

  Future<void> inviteToGroup({
    required String groupId,
    required String groupName,
    required String fromUid,
    required String fromName,
    required String toUid,
  }) async {
    final existing = await _invitesCol
        .where('groupId', isEqualTo: groupId)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    await _invitesCol.add({
      'groupId': groupId,
      'groupName': groupName,
      'fromUid': fromUid,
      'fromName': fromName,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _notificationsCol.add({
      'toUid': toUid,
      'type': 'group_invite',
      'title': 'Csoportmeghívó / Group Invite',
      'body': '$fromName meghívott a "$groupName" csoportba / $fromName invited you to "$groupName"',
      'data': {'groupId': groupId, 'fromUid': fromUid},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<GroupInvite>> watchPendingInvites(String uid) {
    return _invitesCol
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => GroupInvite.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> acceptInvite(GroupInvite invite) async {
    await _invitesCol.doc(invite.id).update({'status': 'accepted'});

    await _groupsCol.doc(invite.groupId).update({
      'memberUids': FieldValue.arrayUnion([invite.toUid]),
    });

    await _firestore.collection('users').doc(invite.toUid).update({
      'groupIds': FieldValue.arrayUnion([invite.groupId]),
    });

    await _notificationsCol.add({
      'toUid': invite.fromUid,
      'type': 'invite_accepted',
      'title': 'Meghívó elfogadva / Invite accepted',
      'body': 'A meghívód a "${invite.groupName}" csoportba elfogadásra került.',
      'data': {'groupId': invite.groupId},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectInvite(GroupInvite invite) async {
    await _invitesCol.doc(invite.id).update({'status': 'rejected'});

    await _notificationsCol.add({
      'toUid': invite.fromUid,
      'type': 'invite_rejected',
      'title': 'Meghívó elutasítva / Invite rejected',
      'body': 'A meghívód a "${invite.groupName}" csoportba elutasításra került.',
      'data': {'groupId': invite.groupId},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveGroup(String groupId, String uid) async {
    await _groupsCol.doc(groupId).update({
      'memberUids': FieldValue.arrayRemove([uid]),
    });
    await _firestore.collection('users').doc(uid).update({
      'groupIds': FieldValue.arrayRemove([groupId]),
    });
  }
}
