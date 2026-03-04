import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/shimmer_loading.dart';
import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/race/data/race_repository.dart';
import 'package:forma1_tipp/src/features/season_prediction/data/season_prediction_repository.dart';
import 'package:forma1_tipp/src/features/season_prediction/domain/season_prediction.dart';
import 'package:forma1_tipp/src/features/season_prediction/presentation/widgets/driver_select_grid.dart';
import 'package:forma1_tipp/src/features/season_prediction/presentation/widgets/point_slider.dart';
import 'package:forma1_tipp/src/features/season_prediction/presentation/widgets/team_select_grid.dart';

class SeasonWizardScreen extends ConsumerStatefulWidget {
  const SeasonWizardScreen({super.key});

  @override
  ConsumerState<SeasonWizardScreen> createState() => _SeasonWizardScreenState();
}

class _SeasonWizardScreenState extends ConsumerState<SeasonWizardScreen> {
  static const _totalSteps = 6;

  final _pageController = PageController();
  int _currentStep = 0;
  bool _submitting = false;

  String? _constructorChampion;
  String? _driverChampion;
  double _winnerPoints = 400;
  double _pointGap = 50;
  String? _lastConstructor;
  String? _lastDriver;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isHu => Localizations.localeOf(context).languageCode == 'hu';

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _constructorChampion != null;
      case 1:
        return _driverChampion != null;
      case 2:
      case 3:
        return true;
      case 4:
        return _lastConstructor != null;
      case 5:
        return _lastDriver != null;
      default:
        return false;
    }
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _confirmAndSubmit();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _confirmAndSubmit() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_isHu ? 'Biztosan beküldöd?' : 'Submit prediction?'),
        content: Text(
          _isHu
              ? 'A szezon tipped beküldés után nem módosítható! Biztosan folytatod?'
              : 'Your season prediction cannot be changed after submission! Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_isHu ? 'Mégsem' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.f1Red),
            child: Text(_isHu ? 'Beküldés' : 'Submit'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _submit();
    }
  }

  Future<void> _submit() async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;

    setState(() => _submitting = true);

    try {
      final prediction = SeasonPrediction(
        constructorChampion: _constructorChampion!,
        driverChampion: _driverChampion!,
        winnerPoints: _winnerPoints.round(),
        pointDifference: _pointGap.round(),
        lastConstructor: _lastConstructor!,
        lastDriver: _lastDriver!,
        submittedAt: DateTime.now(),
      );

      await ref
          .read(seasonPredictionRepoProvider)
          .submitSeasonPrediction(uid, DateTime.now().year, prediction);

      ref.invalidate(currentSeasonPredictionProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isHu ? 'Szezon tipp elküldve!' : 'Season prediction submitted!'),
          ),
        );
        _closeScreen();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_isHu ? 'Hiba' : 'Error'}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final existingPrediction = uid != null
        ? ref.watch(currentSeasonPredictionProvider(uid))
        : const AsyncData<SeasonPrediction?>(null);

    return existingPrediction.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(_isHu ? 'Szezon Tipp' : 'Season Prediction')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(_isHu ? 'Szezon Tipp' : 'Season Prediction')),
        body: Center(child: Text('${_isHu ? 'Hiba' : 'Error'}: $e')),
      ),
      data: (existing) {
        if (existing != null) {
          return _ExistingPredictionView(prediction: existing, isHu: _isHu);
        }
        return _buildWizard(context);
      },
    );
  }

  void _closeScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Widget _buildWizard(BuildContext context) {
    final teamsAsync = ref.watch(allTeamsProvider);
    final driversAsync = ref.watch(allDriversProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isHu ? 'Szezon Tipp' : 'Season Prediction'),
        leading: IconButton(
          onPressed: _closeScreen,
          icon: const Icon(Icons.close),
        ),
      ),
      body: AppGradientBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _totalSteps,
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 10,
                  activeDotColor: AppColors.f1Red,
                  dotColor: AppColors.f1Red.withValues(alpha: 0.2),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _WizardStep(
                    title: _isHu ? 'Ki lesz a Konstruktőri Világbajnok?' : 'Constructor World Champion?',
                    child: teamsAsync.when(
                      data: (teams) => TeamSelectGrid(
                        teams: teams,
                        selectedTeamId: _constructorChampion,
                        onSelect: (id) =>
                            setState(() => _constructorChampion = id),
                      ),
                      loading: () => const _LoadingGrid(),
                      error: (e, _) => Center(child: Text('${_isHu ? 'Hiba' : 'Error'}: $e')),
                    ),
                  ),
                  _WizardStep(
                    title: _isHu ? 'Ki lesz a Pilóták Világbajnoka?' : 'Driver World Champion?',
                    child: driversAsync.when(
                      data: (drivers) => DriverSelectGrid(
                        drivers: drivers,
                        selectedDriverId: _driverChampion,
                        onSelect: (id) =>
                            setState(() => _driverChampion = id),
                      ),
                      loading: () => const _LoadingGrid(),
                      error: (e, _) => Center(child: Text('${_isHu ? 'Hiba' : 'Error'}: $e')),
                    ),
                  ),
                  _WizardStep(
                    title: _isHu ? 'Hány ponttal nyer a bajnok?' : 'Champion\'s winning points?',
                    child: PointSlider(
                      value: _winnerPoints,
                      min: 200,
                      max: 600,
                      onChanged: (v) => setState(() => _winnerPoints = v),
                      label: _isHu ? 'pont' : 'points',
                    ),
                  ),
                  _WizardStep(
                    title: _isHu ? 'Mekkora pontkülönbség lesz az 1. és 2. között?' : 'Points gap between 1st and 2nd?',
                    child: PointSlider(
                      value: _pointGap,
                      min: 0,
                      max: 300,
                      onChanged: (v) => setState(() => _pointGap = v),
                      label: _isHu ? 'pont különbség' : 'points gap',
                    ),
                  ),
                  _WizardStep(
                    title: _isHu ? 'Ki lesz az utolsó a Konstruktőri pontversenyben?' : 'Last constructor in standings?',
                    child: teamsAsync.when(
                      data: (teams) => TeamSelectGrid(
                        teams: teams,
                        selectedTeamId: _lastConstructor,
                        onSelect: (id) =>
                            setState(() => _lastConstructor = id),
                      ),
                      loading: () => const _LoadingGrid(),
                      error: (e, _) => Center(child: Text('${_isHu ? 'Hiba' : 'Error'}: $e')),
                    ),
                  ),
                  _WizardStep(
                    title: _isHu ? 'Ki lesz az utolsó a Pilóta pontversenyben?' : 'Last driver in standings?',
                    child: driversAsync.when(
                      data: (drivers) => DriverSelectGrid(
                        drivers: drivers,
                        selectedDriverId: _lastDriver,
                        onSelect: (id) =>
                            setState(() => _lastDriver = id),
                      ),
                      loading: () => const _LoadingGrid(),
                      error: (e, _) => Center(child: Text('${_isHu ? 'Hiba' : 'Error'}: $e')),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _back,
                          child: Text(_isHu ? 'Vissza' : 'Back'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed:
                            _canProceed && !_submitting ? _next : null,
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _currentStep < _totalSteps - 1
                                    ? (_isHu ? 'Tovább' : 'Next')
                                    : (_isHu ? 'Beküldés' : 'Submit'),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExistingPredictionView extends ConsumerWidget {
  const _ExistingPredictionView({
    required this.prediction,
    required this.isHu,
  });

  final SeasonPrediction prediction;
  final bool isHu;

  static final DateTime _lastRaceDate = DateTime(2026, 12, 6);
  bool get _seasonEnded => DateTime.now().isAfter(_lastRaceDate.add(const Duration(days: 1)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final submitted = DateFormat(isHu ? 'yyyy.MM.dd. HH:mm' : 'MMM d, yyyy HH:mm')
        .format(prediction.submittedAt.toLocal());

    final results = _seasonEnded
        ? ref.watch(seasonResultsProvider(DateTime.now().year)).valueOrNull
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isHu ? 'Szezon Tipp' : 'Season Prediction'),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(Icons.close),
        ),
      ),
      body: AppGradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (_seasonEnded ? Colors.green : AppColors.f1Red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (_seasonEnded ? Colors.green : AppColors.f1Red).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _seasonEnded ? Icons.sports_score_rounded : Icons.lock_rounded,
                      color: _seasonEnded ? Colors.green : AppColors.f1Red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _seasonEnded
                            ? (isHu ? 'A szezon véget ért! Itt az eredmény.' : 'Season is over! Here are the results.')
                            : (isHu ? 'A tipped beküldve, nem módosítható.' : 'Your prediction is locked.'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                '${isHu ? 'Beküldve' : 'Submitted'}: $submitted',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              _predictionRow(
                context,
                icon: Icons.emoji_events_rounded,
                color: AppColors.f1Gold,
                label: isHu ? 'Konstruktőri VB' : 'Constructor Champion',
                value: prediction.constructorChampion,
                actual: results?['constructorChampion'] as String?,
                delay: 100,
              ),
              _predictionRow(
                context,
                icon: Icons.person_rounded,
                color: AppColors.f1Red,
                label: isHu ? 'Pilóta VB' : 'Driver Champion',
                value: prediction.driverChampion,
                actual: results?['driverChampion'] as String?,
                delay: 200,
              ),
              _predictionRow(
                context,
                icon: Icons.speed_rounded,
                color: AppColors.f1Turquoise,
                label: isHu ? 'Bajnoki pont' : 'Champion points',
                value: '${prediction.winnerPoints}',
                actual: results?['winnerPoints']?.toString(),
                delay: 300,
              ),
              _predictionRow(
                context,
                icon: Icons.compare_arrows_rounded,
                color: Colors.orange,
                label: isHu ? 'Pontkülönbség (1-2)' : 'Points gap (1st-2nd)',
                value: '${prediction.pointDifference}',
                actual: results?['pointDifference']?.toString(),
                delay: 400,
              ),
              _predictionRow(
                context,
                icon: Icons.arrow_downward_rounded,
                color: Colors.grey,
                label: isHu ? 'Utolsó konstruktőr' : 'Last constructor',
                value: prediction.lastConstructor,
                actual: results?['lastConstructor'] as String?,
                delay: 500,
              ),
              _predictionRow(
                context,
                icon: Icons.arrow_downward_rounded,
                color: Colors.grey.shade600,
                label: isHu ? 'Utolsó pilóta' : 'Last driver',
                value: prediction.lastDriver,
                actual: results?['lastDriver'] as String?,
                delay: 600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _predictionRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    String? actual,
    required int delay,
  }) {
    final theme = Theme.of(context);
    final bool? isCorrect = actual != null
        ? value.toLowerCase() == actual.toLowerCase()
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect == true
              ? Colors.green.withValues(alpha: 0.4)
              : isCorrect == false
                  ? Colors.red.withValues(alpha: 0.4)
                  : color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isHu ? 'Tipped' : 'Your pick'}: $value',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (actual != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${isHu ? 'Eredmény' : 'Result'}: $actual',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCorrect == true ? Colors.green : AppColors.f1Red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isCorrect == true)
            const Icon(Icons.check_circle, color: Colors.green, size: 22)
          else if (isCorrect == false)
            const Icon(Icons.cancel, color: Colors.red, size: 22)
          else
            Icon(Icons.check_circle, color: color.withValues(alpha: 0.4), size: 20),
        ],
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn(duration: 350.ms).slideX(begin: 0.05, end: 0);
  }
}

class _WizardStep extends StatelessWidget {
  const _WizardStep({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.1, end: 0, duration: 400.ms),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: 10,
      itemBuilder: (_, __) => const ShimmerCard(height: 100),
    );
  }
}
