import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/notifications/domain/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(firestore: ref.watch(firestoreProvider));
});

final userNotificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, uid) {
  return ref.watch(notificationRepositoryProvider).watchNotifications(uid);
});

final unreadCountProvider = StreamProvider.family<int, String>((ref, uid) {
  return ref.watch(notificationRepositoryProvider).watchUnreadCount(uid);
});

class NotificationRepository {
  NotificationRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('notifications');

  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _col
        .where('toUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppNotification.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Stream<int> watchUnreadCount(String uid) {
    return _col
        .where('toUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String notificationId) {
    return _col.doc(notificationId).update({'read': true});
  }

  Future<void> markAllAsRead(String uid) async {
    final snap =
        await _col.where('toUid', isEqualTo: uid).where('read', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
