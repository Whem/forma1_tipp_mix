import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/features/auth/presentation/auth_controller.dart';
import 'package:forma1_tipp/src/features/gamification/data/gamification_repository.dart';
import 'package:forma1_tipp/src/features/gamification/domain/achievement.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showAchievementDetail(Achievement achievement, bool earned) {
    if (!earned) return;

    _confettiController.play();

    final lang = Localizations.localeOf(context).languageCode;
    final name = lang == 'hu' ? achievement.nameHu : achievement.nameEn;
    final desc =
        lang == 'hu' ? achievement.descriptionHu : achievement.descriptionEn;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 40),
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 20,
            minBlastForce: 8,
            numberOfParticles: 30,
            gravity: 0.2,
            colors: const [
              AppColors.f1Gold,
              AppColors.f1Red,
              AppColors.f1Turquoise,
              Colors.white,
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDefsAsync = ref.watch(allAchievementDefsProvider);
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final uid = authState?.appUser?.uid;

    final earnedAsync =
        uid != null ? ref.watch(userAchievementsProvider(uid)) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: AppGradientBackground(
        child: Stack(
          children: [
            allDefsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (allDefs) {
                final earnedIds = <String>{};
                if (earnedAsync != null) {
                  earnedAsync.whenData(
                    (list) => earnedIds.addAll(list.map((a) => a.id)),
                  );
                }

                return AnimationLimiter(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: allDefs.length,
                    itemBuilder: (context, index) {
                      final def = allDefs[index];
                      final earned = earnedIds.contains(def.id);

                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        columnCount: 2,
                        duration: const Duration(milliseconds: 400),
                        child: ScaleAnimation(
                          child: FadeInAnimation(
                            child: _AchievementCard(
                              achievement: def,
                              earned: earned,
                              onTap: () =>
                                  _showAchievementDetail(def, earned),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                maxBlastForce: 20,
                minBlastForce: 8,
                numberOfParticles: 30,
                gravity: 0.2,
                colors: const [
                  AppColors.f1Gold,
                  AppColors.f1Red,
                  AppColors.f1Turquoise,
                  Colors.white,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.earned,
    required this.onTap,
  });

  final Achievement achievement;
  final bool earned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final name = lang == 'hu' ? achievement.nameHu : achievement.nameEn;
    final desc =
        lang == 'hu' ? achievement.descriptionHu : achievement.descriptionEn;

    return GlassCard(
      onTap: onTap,
      opacity: earned ? 0.1 : 0.04,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              ColorFiltered(
                colorFilter: earned
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.matrix(<double>[
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 0.5, 0,
                      ]),
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              if (earned)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.f1Gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: earned ? null : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: textTheme.bodySmall?.copyWith(
              color: earned ? Colors.grey : Colors.grey.shade600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!earned) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0,
                minHeight: 4,
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.f1Turquoise),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '0 / ${achievement.threshold}',
              style: textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
