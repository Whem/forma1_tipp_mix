import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/notifications/data/notification_repository.dart';
import 'package:forma1_tipp/src/features/notifications/domain/app_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    final textTheme = Theme.of(context).textTheme;

    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final notificationsAsync = ref.watch(userNotificationsProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(isHu ? 'Értesítések' : 'Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationRepositoryProvider).markAllAsRead(uid),
            child: Text(
              isHu ? 'Mind olvasott' : 'Mark all read',
              style: TextStyle(color: AppColors.f1Turquoise, fontSize: 12),
            ),
          ),
        ],
      ),
      body: AppGradientBackground(
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_off_rounded,
                        size: 64, color: Colors.white24),
                    const SizedBox(height: 12),
                    Text(
                      isHu ? 'Nincsenek értesítések' : 'No notifications',
                      style: textTheme.bodyLarge?.copyWith(color: Colors.white38),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _NotificationTile(notif: notif, isHu: isHu)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 40 * index))
                    .slideX(begin: 0.1);
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notif, required this.isHu});

  final AppNotification notif;
  final bool isHu;

  IconData _icon() {
    switch (notif.type) {
      case 'group_invite':
        return Icons.group_add_rounded;
      case 'invite_accepted':
        return Icons.check_circle_rounded;
      case 'invite_rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _iconColor() {
    switch (notif.type) {
      case 'group_invite':
        return AppColors.f1Turquoise;
      case 'invite_accepted':
        return AppColors.successGreen;
      case 'invite_rejected':
        return AppColors.errorRed;
      default:
        return AppColors.f1Gold;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeAgo = timeago.format(notif.createdAt, locale: isHu ? 'hu' : 'en');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          if (!notif.read) {
            ref.read(notificationRepositoryProvider).markAsRead(notif.id);
          }
        },
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _iconColor().withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon(), color: _iconColor(), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: notif.read ? FontWeight.w500 : FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.body,
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(fontSize: 10, color: Colors.white30),
                    ),
                  ],
                ),
              ),
              if (!notif.read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.f1Red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
