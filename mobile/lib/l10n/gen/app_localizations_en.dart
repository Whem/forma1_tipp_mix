// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'F1 Tipp Mix';

  @override
  String get welcomeTitle => 'Pick your champions';

  @override
  String get welcomeSubtitle =>
      'Join your friends. Vote before the lights go out. Watch the standings change live.';

  @override
  String get welcomeFootnote => 'Voting closes 30 minutes before race start.';

  @override
  String get login => 'Sign in';

  @override
  String get register => 'Create account';

  @override
  String get continueLabel => 'Continue';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get nickname => 'Display name';

  @override
  String get language => 'Language';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeSubtitle => 'Ready for the season?';

  @override
  String get logout => 'Logout';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String greeting(String name) {
    return 'Hi, $name!';
  }

  @override
  String get nextRace => 'Next Race';

  @override
  String get predict => 'Predict!';

  @override
  String get races => 'Races';

  @override
  String get standings => 'Standings';

  @override
  String get profile => 'Profile';

  @override
  String get achievements => 'Achievements';

  @override
  String get live => 'LIVE';

  @override
  String get seasonPrediction => 'Season Prediction';

  @override
  String get constructorChampion => 'Constructor Champion?';

  @override
  String get driverChampion => 'Driver World Champion?';

  @override
  String get winnerPoints => 'Champion\'s winning points?';

  @override
  String get pointDifference => 'Point gap between P1 & P2?';

  @override
  String get lastConstructor => 'Last constructor in points?';

  @override
  String get lastDriver => 'Last driver in points?';

  @override
  String get submit => 'Submit';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get raceCalendar => 'Race Calendar';

  @override
  String round(int number) {
    return 'Round $number';
  }

  @override
  String get sprint => 'Sprint Weekend';

  @override
  String get lockWarning => 'Predictions lock 30 min before race';

  @override
  String get racePrediction => 'Race Prediction';

  @override
  String get podium => 'Podium';

  @override
  String get p1 => 'P1 - Winner';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get polePosition => 'Pole Position';

  @override
  String get fastestLap => 'Fastest Lap';

  @override
  String get selectDriver => 'Select driver';

  @override
  String get joker => 'Joker';

  @override
  String get jokerActivated => 'Joker activated! 2x points';

  @override
  String jokersRemaining(int count) {
    return '$count jokers remaining';
  }

  @override
  String get predictionLocked => 'Prediction locked';

  @override
  String get predictionSubmitted => 'Prediction submitted!';

  @override
  String get liveRace => 'Live Race';

  @override
  String lap(int current, int total) {
    return 'Lap $current/$total';
  }

  @override
  String get safetyCar => 'Safety Car';

  @override
  String get redFlag => 'Red Flag';

  @override
  String get preRace => 'Pre-Race';

  @override
  String get finished => 'Finished';

  @override
  String get retired => 'Retired';

  @override
  String get resultReveal => 'Result Reveal';

  @override
  String get correct => 'Correct!';

  @override
  String get incorrect => 'Incorrect';

  @override
  String pointsEarned(int points) {
    return '+$points pts';
  }

  @override
  String get totalPoints => 'Total Points';

  @override
  String get jokerMultiplier => 'Joker x2!';

  @override
  String get fullStandings => 'Full standings';

  @override
  String points(int count) {
    return '$count pts';
  }

  @override
  String position(int pos) {
    return '#$pos';
  }

  @override
  String get racesParticipated => 'Races';

  @override
  String get bestStreak => 'Best Streak';

  @override
  String get streak => 'Streak';

  @override
  String streakCount(int count) {
    return '$count streak';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String memberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get changeAvatar => 'Change avatar';

  @override
  String get settings => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemTheme => 'System';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementUnlocked => 'Achievement Unlocked!';

  @override
  String progress(int current, int target) {
    return '$current/$target';
  }

  @override
  String get bonusRound => 'Bonus Round';

  @override
  String bonusRoundActive(String date) {
    return 'Active until $date';
  }

  @override
  String bonusPoints(int points) {
    return '+$points bonus pts';
  }

  @override
  String get share => 'Share';

  @override
  String get shareResult => 'Share my result';

  @override
  String get sharePrediction => 'Share my prediction';

  @override
  String get days => 'd';

  @override
  String get hours => 'h';

  @override
  String get minutes => 'm';

  @override
  String get seconds => 's';

  @override
  String get noRacesYet => 'No upcoming races yet';

  @override
  String get noPrediction => 'No prediction submitted';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get friendCode => 'Friend Code';

  @override
  String get copyCode => 'Copy';

  @override
  String get shareCode => 'Share';

  @override
  String get myGroups => 'My Groups';

  @override
  String get createGroup => 'Create Group';

  @override
  String get inviteMembers => 'Invite member';

  @override
  String get enterFriendCode => 'Friend code (e.g. F1X8KM)';

  @override
  String get inviteSent => 'Invite sent!';

  @override
  String get noGroupsYet => 'No groups yet. Create one!';

  @override
  String get groupInvitations => 'Invitations';

  @override
  String get acceptInvite => 'Accept';

  @override
  String get declineInvite => 'Decline';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get supportUs => 'Support us';

  @override
  String get supportDescription =>
      'If you enjoy the app, consider supporting development!';

  @override
  String get aiAssistanceToggle => 'I use AI assistance';

  @override
  String get aiAssistanceDescription =>
      'Check if you use AI tools for your predictions. You\'ll compete in a separate leaderboard.';

  @override
  String get globalStandings => 'Global';

  @override
  String get groupStandings => 'My Groups';

  @override
  String get filterAll => 'All';

  @override
  String get filterHuman => 'Human';

  @override
  String get filterAI => 'AI';

  @override
  String get owner => 'Owner';

  @override
  String members(int count) {
    return '$count members';
  }

  @override
  String get copied => 'Copied!';
}
