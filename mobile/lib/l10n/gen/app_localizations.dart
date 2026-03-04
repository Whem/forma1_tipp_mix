import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hu'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'F1 Tipp Mix'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your champions'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join your friends. Vote before the lights go out. Watch the standings change live.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeFootnote.
  ///
  /// In en, this message translates to:
  /// **'Voting closes 30 minutes before race start.'**
  String get welcomeFootnote;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get register;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get nickname;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for the season?'**
  String get homeSubtitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}!'**
  String greeting(String name);

  /// No description provided for @nextRace.
  ///
  /// In en, this message translates to:
  /// **'Next Race'**
  String get nextRace;

  /// No description provided for @predict.
  ///
  /// In en, this message translates to:
  /// **'Predict!'**
  String get predict;

  /// No description provided for @races.
  ///
  /// In en, this message translates to:
  /// **'Races'**
  String get races;

  /// No description provided for @standings.
  ///
  /// In en, this message translates to:
  /// **'Standings'**
  String get standings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @seasonPrediction.
  ///
  /// In en, this message translates to:
  /// **'Season Prediction'**
  String get seasonPrediction;

  /// No description provided for @constructorChampion.
  ///
  /// In en, this message translates to:
  /// **'Constructor Champion?'**
  String get constructorChampion;

  /// No description provided for @driverChampion.
  ///
  /// In en, this message translates to:
  /// **'Driver World Champion?'**
  String get driverChampion;

  /// No description provided for @winnerPoints.
  ///
  /// In en, this message translates to:
  /// **'Champion\'s winning points?'**
  String get winnerPoints;

  /// No description provided for @pointDifference.
  ///
  /// In en, this message translates to:
  /// **'Point gap between P1 & P2?'**
  String get pointDifference;

  /// No description provided for @lastConstructor.
  ///
  /// In en, this message translates to:
  /// **'Last constructor in points?'**
  String get lastConstructor;

  /// No description provided for @lastDriver.
  ///
  /// In en, this message translates to:
  /// **'Last driver in points?'**
  String get lastDriver;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @raceCalendar.
  ///
  /// In en, this message translates to:
  /// **'Race Calendar'**
  String get raceCalendar;

  /// No description provided for @round.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String round(int number);

  /// No description provided for @sprint.
  ///
  /// In en, this message translates to:
  /// **'Sprint Weekend'**
  String get sprint;

  /// No description provided for @lockWarning.
  ///
  /// In en, this message translates to:
  /// **'Predictions lock 30 min before race'**
  String get lockWarning;

  /// No description provided for @racePrediction.
  ///
  /// In en, this message translates to:
  /// **'Race Prediction'**
  String get racePrediction;

  /// No description provided for @podium.
  ///
  /// In en, this message translates to:
  /// **'Podium'**
  String get podium;

  /// No description provided for @p1.
  ///
  /// In en, this message translates to:
  /// **'P1 - Winner'**
  String get p1;

  /// No description provided for @p2.
  ///
  /// In en, this message translates to:
  /// **'P2'**
  String get p2;

  /// No description provided for @p3.
  ///
  /// In en, this message translates to:
  /// **'P3'**
  String get p3;

  /// No description provided for @polePosition.
  ///
  /// In en, this message translates to:
  /// **'Pole Position'**
  String get polePosition;

  /// No description provided for @fastestLap.
  ///
  /// In en, this message translates to:
  /// **'Fastest Lap'**
  String get fastestLap;

  /// No description provided for @selectDriver.
  ///
  /// In en, this message translates to:
  /// **'Select driver'**
  String get selectDriver;

  /// No description provided for @joker.
  ///
  /// In en, this message translates to:
  /// **'Joker'**
  String get joker;

  /// No description provided for @jokerActivated.
  ///
  /// In en, this message translates to:
  /// **'Joker activated! 2x points'**
  String get jokerActivated;

  /// No description provided for @jokersRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} jokers remaining'**
  String jokersRemaining(int count);

  /// No description provided for @predictionLocked.
  ///
  /// In en, this message translates to:
  /// **'Prediction locked'**
  String get predictionLocked;

  /// No description provided for @predictionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Prediction submitted!'**
  String get predictionSubmitted;

  /// No description provided for @liveRace.
  ///
  /// In en, this message translates to:
  /// **'Live Race'**
  String get liveRace;

  /// No description provided for @lap.
  ///
  /// In en, this message translates to:
  /// **'Lap {current}/{total}'**
  String lap(int current, int total);

  /// No description provided for @safetyCar.
  ///
  /// In en, this message translates to:
  /// **'Safety Car'**
  String get safetyCar;

  /// No description provided for @redFlag.
  ///
  /// In en, this message translates to:
  /// **'Red Flag'**
  String get redFlag;

  /// No description provided for @preRace.
  ///
  /// In en, this message translates to:
  /// **'Pre-Race'**
  String get preRace;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @retired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get retired;

  /// No description provided for @resultReveal.
  ///
  /// In en, this message translates to:
  /// **'Result Reveal'**
  String get resultReveal;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correct;

  /// No description provided for @incorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrect;

  /// No description provided for @pointsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{points} pts'**
  String pointsEarned(int points);

  /// No description provided for @totalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get totalPoints;

  /// No description provided for @jokerMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Joker x2!'**
  String get jokerMultiplier;

  /// No description provided for @fullStandings.
  ///
  /// In en, this message translates to:
  /// **'Full standings'**
  String get fullStandings;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'{count} pts'**
  String points(int count);

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'#{pos}'**
  String position(int pos);

  /// No description provided for @racesParticipated.
  ///
  /// In en, this message translates to:
  /// **'Races'**
  String get racesParticipated;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreak;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @streakCount.
  ///
  /// In en, this message translates to:
  /// **'{count} streak'**
  String streakCount(int count);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @changeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change avatar'**
  String get changeAvatar;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked!'**
  String get achievementUnlocked;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{target}'**
  String progress(int current, int target);

  /// No description provided for @bonusRound.
  ///
  /// In en, this message translates to:
  /// **'Bonus Round'**
  String get bonusRound;

  /// No description provided for @bonusRoundActive.
  ///
  /// In en, this message translates to:
  /// **'Active until {date}'**
  String bonusRoundActive(String date);

  /// No description provided for @bonusPoints.
  ///
  /// In en, this message translates to:
  /// **'+{points} bonus pts'**
  String bonusPoints(int points);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareResult.
  ///
  /// In en, this message translates to:
  /// **'Share my result'**
  String get shareResult;

  /// No description provided for @sharePrediction.
  ///
  /// In en, this message translates to:
  /// **'Share my prediction'**
  String get sharePrediction;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get seconds;

  /// No description provided for @noRacesYet.
  ///
  /// In en, this message translates to:
  /// **'No upcoming races yet'**
  String get noRacesYet;

  /// No description provided for @noPrediction.
  ///
  /// In en, this message translates to:
  /// **'No prediction submitted'**
  String get noPrediction;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @friendCode.
  ///
  /// In en, this message translates to:
  /// **'Friend Code'**
  String get friendCode;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyCode;

  /// No description provided for @shareCode.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareCode;

  /// No description provided for @myGroups.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get myGroups;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @inviteMembers.
  ///
  /// In en, this message translates to:
  /// **'Invite member'**
  String get inviteMembers;

  /// No description provided for @enterFriendCode.
  ///
  /// In en, this message translates to:
  /// **'Friend code (e.g. F1X8KM)'**
  String get enterFriendCode;

  /// No description provided for @inviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent!'**
  String get inviteSent;

  /// No description provided for @noGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No groups yet. Create one!'**
  String get noGroupsYet;

  /// No description provided for @groupInvitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get groupInvitations;

  /// No description provided for @acceptInvite.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptInvite;

  /// No description provided for @declineInvite.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineInvite;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @supportUs.
  ///
  /// In en, this message translates to:
  /// **'Support us'**
  String get supportUs;

  /// No description provided for @supportDescription.
  ///
  /// In en, this message translates to:
  /// **'If you enjoy the app, consider supporting development!'**
  String get supportDescription;

  /// No description provided for @aiAssistanceToggle.
  ///
  /// In en, this message translates to:
  /// **'I use AI assistance'**
  String get aiAssistanceToggle;

  /// No description provided for @aiAssistanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Check if you use AI tools for your predictions. You\'ll compete in a separate leaderboard.'**
  String get aiAssistanceDescription;

  /// No description provided for @globalStandings.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get globalStandings;

  /// No description provided for @groupStandings.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get groupStandings;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterHuman.
  ///
  /// In en, this message translates to:
  /// **'Human'**
  String get filterHuman;

  /// No description provided for @filterAI.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get filterAI;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String members(int count);

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
