import 'package:flutter/material.dart';
import 'package:forma1_tipp/src/core/theme/app_colors.dart';

class ShareablePredictionCard extends StatelessWidget {
  final GlobalKey repaintKey;
  final String raceName;
  final String raceDate;
  final String p1;
  final String p2;
  final String p3;
  final String pole;
  final String fastestLap;
  final String displayName;

  const ShareablePredictionCard({
    super.key,
    required this.repaintKey,
    required this.raceName,
    required this.raceDate,
    required this.p1,
    required this.p2,
    required this.p3,
    required this.pole,
    required this.fastestLap,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.f1DarkBg,
              AppColors.f1DarkCard,
              Color(0xFF0F0F23),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.f1Red.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(),
            const SizedBox(height: 16),
            _buildRaceInfo(),
            const SizedBox(height: 20),
            _buildPodium(),
            const SizedBox(height: 16),
            _buildExtras(),
            const SizedBox(height: 20),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.f1Red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'F1 TIPP MIX',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildRaceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          raceName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          raceDate,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPodium() {
    return Column(
      children: [
        _podiumRow('🥇', 'P1', p1, AppColors.f1Gold),
        const SizedBox(height: 8),
        _podiumRow('🥈', 'P2', p2, AppColors.f1Silver),
        const SizedBox(height: 8),
        _podiumRow('🥉', 'P3', p3, AppColors.f1Bronze),
      ],
    );
  }

  Widget _podiumRow(String medal, String position, String driver, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(
            position,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              driver,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtras() {
    return Row(
      children: [
        _extraChip('🏁 Pole', pole),
        const SizedBox(width: 12),
        _extraChip('⚡ Fastest', fastestLap),
      ],
    );
  }

  Widget _extraChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          displayName,
          style: TextStyle(
            color: AppColors.f1Turquoise.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '#F1TippMix',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
