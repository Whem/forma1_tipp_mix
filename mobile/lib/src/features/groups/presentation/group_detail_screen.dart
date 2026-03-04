import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/auth/presentation/auth_controller.dart';
import 'package:forma1_tipp/src/features/groups/data/group_repository.dart';

final _groupDetailProvider = StreamProvider.family(
  (ref, String groupId) => ref.watch(groupRepositoryProvider).watchGroup(groupId),
);

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _friendCodeController = TextEditingController();
  bool _inviting = false;

  @override
  void dispose() {
    _friendCodeController.dispose();
    super.dispose();
  }

  Future<void> _inviteByCode() async {
    final code = _friendCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    final repo = ref.read(groupRepositoryProvider);
    final currentUser = ref.read(authControllerProvider).valueOrNull?.appUser;
    if (currentUser == null) return;

    setState(() => _inviting = true);
    try {
      final targetUid = await repo.findUserByFriendCode(code);
      if (targetUid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isHu
                  ? 'Nem található felhasználó ezzel a kóddal'
                  : 'No user found with this code'),
            ),
          );
        }
        return;
      }

      if (targetUid == currentUser.uid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isHu
                  ? 'Saját magadat nem hívhatod meg'
                  : 'You cannot invite yourself'),
            ),
          );
        }
        return;
      }

      final group = await repo.getGroup(widget.groupId);
      if (group == null) return;

      if (group.memberUids.contains(targetUid)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isHu
                  ? 'Ez a felhasználó már tag'
                  : 'This user is already a member'),
            ),
          );
        }
        return;
      }

      await repo.inviteToGroup(
        groupId: widget.groupId,
        groupName: group.name,
        fromUid: currentUser.uid,
        fromName: currentUser.displayName,
        toUid: targetUid,
      );

      _friendCodeController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHu ? 'Meghívó elküldve!' : 'Invite sent!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(_groupDetailProvider(widget.groupId));
    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    final currentUid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isHu ? 'Csoport' : 'Group'),
      ),
      body: AppGradientBackground(
        child: groupAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (group) {
            if (group == null) {
              return Center(
                child: Text(isHu ? 'Csoport nem található' : 'Group not found'),
              );
            }

            final isOwner = group.creatorUid == currentUid;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.group_rounded, size: 48, color: AppColors.f1Red),
                      const SizedBox(height: 8),
                      Text(
                        group.name,
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHu
                            ? '${group.memberUids.length} tag'
                            : '${group.memberUids.length} members',
                        style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 16),

                if (isOwner) ...[
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHu ? 'Tag meghívása' : 'Invite member',
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _friendCodeController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: isHu ? 'Barát kód (pl. F1X8KM)' : 'Friend code (e.g. F1X8KM)',
                                  prefixIcon: const Icon(Icons.person_add),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _inviting ? null : _inviteByCode,
                              style: FilledButton.styleFrom(backgroundColor: AppColors.f1Red),
                              child: _inviting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(isHu ? 'Meghív' : 'Invite'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),
                ],

                Text(
                  isHu ? 'Tagok' : 'Members',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                ...group.memberUids.asMap().entries.map((e) {
                  final memberUid = e.value;
                  return FutureBuilder<String?>(
                    future: ref.read(groupRepositoryProvider).getUserDisplayName(memberUid),
                    builder: (context, snap) {
                      final name = snap.data ?? '...';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey.shade800,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              if (memberUid == group.creatorUid)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.f1Gold.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isHu ? 'Alapító' : 'Owner',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.f1Gold,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 50 * e.key));
                    },
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
