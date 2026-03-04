import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:forma1_tipp/l10n/app_localizations.dart';
import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push('/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),

                Text(
                  'F1',
                  style: textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.f1Red,
                    height: 0.9,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideX(
                      begin: -0.3,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),

                Text(
                  'TIPP MIX',
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideX(
                      begin: -0.3,
                      delay: 200.ms,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 12),

                Text(
                  l10n.welcomeTitle,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 500.ms),

                const SizedBox(height: 10),

                Text(
                  l10n.welcomeSubtitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

                const Spacer(),

                GlassCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: () => context.push('/login'),
                        child: Text(l10n.login),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.push('/register'),
                        child: Text(l10n.register),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 650.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.15,
                      delay: 650.ms,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 18),

                Center(
                  child: Text(
                    l10n.welcomeFootnote,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ).animate().fadeIn(delay: 850.ms, duration: 400.ms),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
