// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Forma1 Tipp';

  @override
  String get welcomeTitle => 'Pick your champions';

  @override
  String get welcomeSubtitle =>
      'Join your friends. Vote before the lights go out. Watch the standings change live.';

  @override
  String get welcomeFootnote => 'Voting closes 10 minutes before race start.';

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
  String get nickname => 'Nickname';

  @override
  String get language => 'Language';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeSubtitle => 'Ready for the season?';

  @override
  String get logout => 'Logout';

  @override
  String get comingSoon => 'Season setup is coming';

  @override
  String get comingSoonBody =>
      'Next we’ll add seasons, teams, drivers and the vote screens — with live race excitement.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';
}
