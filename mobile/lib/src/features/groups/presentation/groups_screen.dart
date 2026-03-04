import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/groups/data/group_repository.dart';
import 'package:forma1_tipp/src/features/groups/domain/group_invite.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    final textTheme = Theme.of(context).textTheme;

    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final groupsAsync = ref.watch(myGroupsProvider(uid));
    final invitesAsync = ref.watch(pendingInvitesProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(isHu ? 'Csoportjaim' : 'My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/groups/create'),
          ),
        ],
      ),
      body: AppGradientBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            invitesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (invites) {
                if (invites.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHu ? 'Meghívók' : 'Invitations',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...invites.map((invite) => _InviteCard(
                          invite: invite,
                          isHu: isHu,
                        )),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (groups) {
                if (groups.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Icon(Icons.group_add_rounded,
                            size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          isHu
                              ? 'Még nincsenek csoportjaid.\nHozz létre egyet!'
                              : 'No groups yet.\nCreate one!',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(color: Colors.white38),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHu ? 'Csoportok' : 'Groups',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...groups.asMap().entries.map((e) {
                      final group = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.f1Red.withValues(alpha: 0.2),
                              child: const Icon(Icons.group, color: AppColors.f1Red),
                            ),
                            title: Text(group.name,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              isHu
                                  ? '${group.memberUids.length} tag'
                                  : '${group.memberUids.length} members',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/groups/${group.id}'),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 60 * e.key))
                          .slideX(begin: 0.1);
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCard extends ConsumerWidget {
  const _InviteCard({required this.invite, required this.isHu});

  final GroupInvite invite;
  final bool isHu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isHu
                    ? '${invite.fromName} meghívott a "${invite.groupName}" csoportba'
                    : '${invite.fromName} invited you to "${invite.groupName}"',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => ref
                        .read(groupRepositoryProvider)
                        .rejectInvite(invite),
                    child: Text(isHu ? 'Elutasítás' : 'Decline'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => ref
                        .read(groupRepositoryProvider)
                        .acceptInvite(invite),
                    child: Text(isHu ? 'Elfogadás' : 'Accept'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }
}
