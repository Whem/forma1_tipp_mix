import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:forma1_tipp/src/core/audio/music_service.dart';
import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/providers/locale_provider.dart';
import 'package:forma1_tipp/src/core/providers/theme_provider.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/features/auth/presentation/auth_controller.dart';
import 'package:forma1_tipp/src/features/gamification/domain/achievement.dart';
import 'package:forma1_tipp/src/features/profile/data/profile_repository.dart';

final _userAchievementsProvider =
    FutureProvider.family<List<Achievement>, String>((ref, uid) {
  return ref.watch(profileRepositoryProvider).getUserAchievements(uid);
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;

  Future<void> _pickAndUploadAvatar(String uid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Avatar',
          toolbarColor: AppColors.f1DarkBg,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: 'Crop Avatar', aspectRatioLockEnabled: true),
      ],
    );
    if (cropped == null) return;

    setState(() => _uploading = true);
    try {
      await ref.read(profileRepositoryProvider).uploadAvatar(uid, File(cropped.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final user = authState?.appUser;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    final achievementsAsync = ref.watch(_userAchievementsProvider(user.uid));
    final currentLocale = ref.watch(localeProvider);
    final selectedLang = currentLocale?.languageCode ?? user.language;

    return Scaffold(
      appBar: AppBar(title: Text(isHu ? 'Profil' : 'Profile')),
      body: AppGradientBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _AvatarSection(
              avatarUrl: user.avatarUrl,
              uploading: _uploading,
              onTap: () => _pickAndUploadAvatar(user.uid),
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: 16),

            GlassCard(
              child: Column(
                children: [
                  Text(
                    user.displayName,
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(user.email, style: textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    isHu
                        ? 'Tag ${user.createdAt.year}.${user.createdAt.month.toString().padLeft(2, '0')}.${user.createdAt.day.toString().padLeft(2, '0')} óta'
                        : 'Member since ${user.createdAt.year}.${user.createdAt.month.toString().padLeft(2, '0')}.${user.createdAt.day.toString().padLeft(2, '0')}',
                    style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

            const SizedBox(height: 16),

            _StatsRow(
              totalPoints: user.streak,
              racesParticipated: 0,
              bestStreak: user.streak,
              isHu: isHu,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 16),

            achievementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (achievements) => _AchievementShowcase(achievements: achievements),
            ),

            const SizedBox(height: 16),

            _FriendCodeCard(
              friendCode: user.friendCode,
              isAIAssisted: user.isAIAssisted,
              isHu: isHu,
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

            const SizedBox(height: 12),

            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.group_rounded, color: AppColors.f1Red),
                title: Text(
                  isHu ? 'Csoportjaim' : 'My Groups',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/groups'),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 16),

            _DonationSection(isHu: isHu)
                .animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHu ? 'Beállítások' : 'Settings',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _SettingRow(
                    icon: Icons.language,
                    label: isHu ? 'Nyelv' : 'Language',
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'hu', label: Text('HU')),
                        ButtonSegment(value: 'en', label: Text('EN')),
                      ],
                      selected: {selectedLang},
                      onSelectionChanged: (val) {
                        final lang = val.first;
                        ref.read(localeProvider.notifier).setLocale(lang);
                        ref.read(profileRepositoryProvider).updateLanguage(
                              user.uid,
                              lang,
                            );
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  _SettingRow(
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    label: isDark
                        ? (isHu ? 'Sötét mód' : 'Dark Mode')
                        : (isHu ? 'Világos mód' : 'Light Mode'),
                    trailing: Switch(
                      value: isDark,
                      onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                      activeColor: AppColors.f1Turquoise,
                    ),
                  ),
                  const Divider(height: 24),
                  Builder(
                    builder: (context) {
                      final musicOn = ref.watch(musicEnabledProvider);
                      return _SettingRow(
                        icon: musicOn ? Icons.music_note : Icons.music_off,
                        label: musicOn
                            ? (isHu ? 'Zene BE' : 'Music ON')
                            : (isHu ? 'Zene KI' : 'Music OFF'),
                        trailing: Switch(
                          value: musicOn,
                          onChanged: (_) => ref.read(musicEnabledProvider.notifier).toggle(),
                          activeColor: AppColors.f1Turquoise,
                        ),
                      );
                    },
                  ),
                  Builder(
                    builder: (context) {
                      final musicOn = ref.watch(musicEnabledProvider);
                      if (!musicOn) return const SizedBox.shrink();
                      final service = ref.watch(musicServiceProvider);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.volume_down, size: 18),
                            Expanded(
                              child: Slider(
                                value: service.volume,
                                onChanged: (v) {
                                  service.setVolume(v);
                                  (context as Element).markNeedsBuild();
                                },
                                activeColor: AppColors.f1Turquoise,
                              ),
                            ),
                            const Icon(Icons.volume_up, size: 18),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).logout(),
                      icon: const Icon(Icons.logout),
                      label: Text(isHu ? 'Kijelentkezés' : 'Logout'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.avatarUrl,
    required this.uploading,
    required this.onTap,
  });

  final String? avatarUrl;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: uploading ? null : onTap,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: Colors.grey.shade800,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl!)
                  : null,
              child: uploading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : (avatarUrl == null
                      ? const Icon(Icons.person, size: 48)
                      : null),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.f1Red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.totalPoints,
    required this.racesParticipated,
    required this.bestStreak,
    this.isHu = false,
  });

  final int totalPoints;
  final int racesParticipated;
  final int bestStreak;
  final bool isHu;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: isHu ? 'Pontok' : 'Points', value: totalPoints, icon: Icons.emoji_events)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(label: isHu ? 'Futamok' : 'Races', value: racesParticipated, icon: Icons.flag)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(label: isHu ? 'Sorozat' : 'Streak', value: bestStreak, icon: Icons.local_fire_department)),
      ],
    );
  }
}

class _StatCard extends StatefulWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animation = IntTween(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _StatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = IntTween(begin: 0, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(widget.icon, color: AppColors.f1Gold, size: 24),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) => Text(
              '${_animation.value}',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Text(widget.label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AchievementShowcase extends StatelessWidget {
  const _AchievementShowcase({required this.achievements});

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Achievements',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final a = achievements[index];
              final name = lang == 'hu' ? a.nameHu : a.nameEn;
              return GlassCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(a.icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 70,
                      child: Text(
                        name,
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)).slideX(begin: 0.2);
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        trailing,
      ],
    );
  }
}

class _FriendCodeCard extends StatelessWidget {
  const _FriendCodeCard({
    required this.friendCode,
    required this.isAIAssisted,
    required this.isHu,
  });

  final String friendCode;
  final bool isAIAssisted;
  final bool isHu;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: AppColors.f1Turquoise, size: 20),
              const SizedBox(width: 8),
              Text(
                isHu ? 'Barát kód' : 'Friend Code',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (isAIAssisted) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.smart_toy_rounded, size: 10, color: Color(0xFF00D4FF)),
                      SizedBox(width: 3),
                      Text('AI', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 9, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.f1Turquoise.withValues(alpha: 0.3)),
            ),
            child: Text(
              friendCode.isEmpty ? '------' : friendCode,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: AppColors.f1Turquoise,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: friendCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isHu ? 'Másolva!' : 'Copied!')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(isHu ? 'Másolás' : 'Copy'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Share.share(
                      isHu
                          ? 'Adj hozzá az F1 Tipp Mix barátaidhoz! Kódom: $friendCode'
                          : 'Add me on F1 Tipp Mix! My friend code: $friendCode',
                    );
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: Text(isHu ? 'Megosztás' : 'Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonationSection extends StatelessWidget {
  const _DonationSection({required this.isHu});

  final bool isHu;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: AppColors.f1Red, size: 20),
              const SizedBox(width: 8),
              Text(
                isHu ? 'Támogatás' : 'Support us',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isHu
                ? 'Ha tetszik az alkalmazás, támogasd a fejlesztést!'
                : 'If you enjoy the app, consider supporting development!',
            style: textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _DonationRow(
            icon: Icons.account_balance_wallet,
            label: 'Revolut',
            value: '@szabolt19q',
            onTap: () => launchUrl(Uri.parse('https://revolut.me/szabolt19q')),
            onCopy: () {
              Clipboard.setData(const ClipboardData(text: '@szabolt19q'));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isHu ? 'Másolva!' : 'Copied!')),
              );
            },
          ),
          const SizedBox(height: 8),
          _DonationRow(
            icon: Icons.currency_bitcoin,
            label: 'Bitcoin',
            value: 'bc1qeycd...purh8c',
            onTap: () {
              Clipboard.setData(const ClipboardData(
                  text: 'bc1qeycda4kdd8kupgh9mrxxgardkrkjh82wpurh8c'));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isHu ? 'BTC cím másolva!' : 'BTC address copied!')),
              );
            },
            onCopy: () {
              Clipboard.setData(const ClipboardData(
                  text: 'bc1qeycda4kdd8kupgh9mrxxgardkrkjh82wpurh8c'));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isHu ? 'BTC cím másolva!' : 'BTC address copied!')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DonationRow extends StatelessWidget {
  const _DonationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.f1Gold),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(value, style: TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 16),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
