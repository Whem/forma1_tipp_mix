// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Forma1 Tipp';

  @override
  String get welcomeTitle => 'Válaszd ki a bajnokokat';

  @override
  String get welcomeSubtitle =>
      'Csatlakozz a barátaidhoz. Szavazz a rajt előtt. Nézd élőben, hogyan alakul a pontállás.';

  @override
  String get welcomeFootnote =>
      'A szavazás a futam kezdete előtt 10 perccel lezár.';

  @override
  String get login => 'Bejelentkezés';

  @override
  String get register => 'Regisztráció';

  @override
  String get continueLabel => 'Tovább';

  @override
  String get email => 'Email';

  @override
  String get password => 'Jelszó';

  @override
  String get nickname => 'Becenév';

  @override
  String get language => 'Nyelv';

  @override
  String get homeTitle => 'Kezdőlap';

  @override
  String get homeSubtitle => 'Készen állsz a szezonra?';

  @override
  String get logout => 'Kijelentkezés';

  @override
  String get comingSoon => 'Hamarosan';

  @override
  String get comingSoonBody =>
      'Következő lépésként jönnek a szezonok, csapatok, pilóták és a tipp képernyők — élő izgalommal.';

  @override
  String get errorGeneric => 'Hiba történt. Próbáld újra.';
}
