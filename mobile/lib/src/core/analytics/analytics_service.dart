import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(FirebaseAnalytics.instance);
});

class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logLogin() => _analytics.logLogin(loginMethod: 'email');

  Future<void> logSignUp() => _analytics.logSignUp(signUpMethod: 'email');

  Future<void> logScreenView(String screenName) =>
      _analytics.logScreenView(screenName: screenName);

  Future<void> logPredictionSubmitted({
    required String raceId,
    required bool isJoker,
  }) =>
      _analytics.logEvent(
        name: 'prediction_submitted',
        parameters: {'race_id': raceId, 'is_joker': isJoker},
      );

  Future<void> logSeasonPrediction() =>
      _analytics.logEvent(name: 'season_prediction_submitted');

  Future<void> logAchievementUnlocked(String achievementId) =>
      _analytics.logEvent(
        name: 'achievement_unlocked',
        parameters: {'achievement_id': achievementId},
      );

  Future<void> logShare(String contentType) =>
      _analytics.logShare(
        contentType: contentType,
        itemId: 'prediction',
        method: 'share_plus',
      );

  Future<void> logJokerUsed(String raceId) =>
      _analytics.logEvent(
        name: 'joker_used',
        parameters: {'race_id': raceId},
      );

  Future<void> logBonusRoundAnswer(String bonusRoundId) =>
      _analytics.logEvent(
        name: 'bonus_round_answer',
        parameters: {'bonus_round_id': bonusRoundId},
      );

  Future<void> setUserProperties({
    required String userId,
    required String language,
  }) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'language', value: language);
  }
}
