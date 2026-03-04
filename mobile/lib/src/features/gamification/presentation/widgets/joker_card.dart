import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';

class JokerCard extends StatelessWidget {
  const JokerCard({
    super.key,
    required this.jokersRemaining,
    this.totalJokers = 3,
    this.onUse,
  });

  final int jokersRemaining;
  final int totalJokers;
  final VoidCallback? onUse;

  bool get _hasJokers => jokersRemaining > 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget card = GlassCard(
      onTap: _hasJokers ? onUse : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hasJokers
                    ? [AppColors.jokerGold, AppColors.f1Gold]
                    : [Colors.grey, Colors.grey.shade600],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: _hasJokers
                  ? [
                      BoxShadow(
                        color: AppColors.jokerGold.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: const Icon(
              Icons.style,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'JOKER',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: _hasJokers ? AppColors.jokerGold : Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: List.generate(totalJokers, (i) {
                  final used = i >= jokersRemaining;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      used ? Icons.star_border : Icons.star,
                      size: 16,
                      color: used ? Colors.grey : AppColors.f1Gold,
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '$jokersRemaining/$totalJokers',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: _hasJokers ? AppColors.jokerGold : Colors.grey,
            ),
          ),
        ],
      ),
    );

    if (_hasJokers) {
      card = card
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 2000.ms,
            color: AppColors.jokerGold.withValues(alpha: 0.15),
          );
    }

    return card;
  }
}
