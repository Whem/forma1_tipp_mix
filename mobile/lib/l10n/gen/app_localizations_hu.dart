// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'F1 Tipp Mix';

  @override
  String get welcomeTitle => 'Válaszd ki a bajnokokat';

  @override
  String get welcomeSubtitle =>
      'Csatlakozz a barátaidhoz. Szavazz a rajt előtt. Nézd élőben, hogyan alakul a pontállás.';

  @override
  String get welcomeFootnote =>
      'A tippelés a futam kezdete előtt 30 perccel lezár.';

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
  String get nickname => 'Megjelenítési név';

  @override
  String get language => 'Nyelv';

  @override
  String get homeTitle => 'Kezdőlap';

  @override
  String get homeSubtitle => 'Készen állsz a szezonra?';

  @override
  String get logout => 'Kijelentkezés';

  @override
  String get errorGeneric => 'Hiba történt. Próbáld újra.';

  @override
  String greeting(String name) {
    return 'Üdv, $name!';
  }

  @override
  String get nextRace => 'Következő futam';

  @override
  String get predict => 'Tippelj!';

  @override
  String get races => 'Futamok';

  @override
  String get standings => 'Ranglista';

  @override
  String get profile => 'Profil';

  @override
  String get achievements => 'Eredmények';

  @override
  String get live => 'ÉLŐ';

  @override
  String get seasonPrediction => 'Szezon tipp';

  @override
  String get constructorChampion => 'Ki lesz a Konstruktőri Világbajnok?';

  @override
  String get driverChampion => 'Ki lesz a Pilóták Világbajnoka?';

  @override
  String get winnerPoints => 'Hány ponttal nyer a bajnok?';

  @override
  String get pointDifference => 'Pontkülönbség az 1. és 2. között?';

  @override
  String get lastConstructor => 'Ki lesz az utolsó konstruktőr?';

  @override
  String get lastDriver => 'Ki lesz az utolsó pilóta?';

  @override
  String get submit => 'Beküldés';

  @override
  String get back => 'Vissza';

  @override
  String get next => 'Következő';

  @override
  String get raceCalendar => 'Futamnaptár';

  @override
  String round(int number) {
    return '$number. forduló';
  }

  @override
  String get sprint => 'Sprint hétvége';

  @override
  String get lockWarning => 'A tippek a futam előtt 30 perccel záródnak';

  @override
  String get racePrediction => 'Futam tipp';

  @override
  String get podium => 'Dobogó';

  @override
  String get p1 => 'P1 - Győztes';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get polePosition => 'Pole pozíció';

  @override
  String get fastestLap => 'Leggyorsabb kör';

  @override
  String get selectDriver => 'Válassz pilótát';

  @override
  String get joker => 'Joker';

  @override
  String get jokerActivated => 'Joker aktiválva! 2x pont';

  @override
  String jokersRemaining(int count) {
    return '$count joker maradt';
  }

  @override
  String get predictionLocked => 'Tipp zárolva';

  @override
  String get predictionSubmitted => 'Tipp beküldve!';

  @override
  String get liveRace => 'Élő futam';

  @override
  String lap(int current, int total) {
    return '$current. kör / $total';
  }

  @override
  String get safetyCar => 'Biztonsági autó';

  @override
  String get redFlag => 'Piros zászló';

  @override
  String get preRace => 'Futam előtt';

  @override
  String get finished => 'Befejezve';

  @override
  String get retired => 'Kiesett';

  @override
  String get resultReveal => 'Eredmény';

  @override
  String get correct => 'Helyes!';

  @override
  String get incorrect => 'Téves';

  @override
  String pointsEarned(int points) {
    return '+$points pont';
  }

  @override
  String get totalPoints => 'Összpontszám';

  @override
  String get jokerMultiplier => 'Joker x2!';

  @override
  String get fullStandings => 'Teljes ranglista';

  @override
  String points(int count) {
    return '$count pont';
  }

  @override
  String position(int pos) {
    return '#$pos';
  }

  @override
  String get racesParticipated => 'Futamok';

  @override
  String get bestStreak => 'Legjobb sorozat';

  @override
  String get streak => 'Sorozat';

  @override
  String streakCount(int count) {
    return '${count}x sorozat';
  }

  @override
  String get profileTitle => 'Profil';

  @override
  String memberSince(String date) {
    return 'Tag $date óta';
  }

  @override
  String get changeAvatar => 'Avatár váltás';

  @override
  String get settings => 'Beállítások';

  @override
  String get darkMode => 'Sötét mód';

  @override
  String get lightMode => 'Világos mód';

  @override
  String get systemTheme => 'Rendszer';

  @override
  String get achievementsTitle => 'Eredmények';

  @override
  String get achievementUnlocked => 'Eredmény feloldva!';

  @override
  String progress(int current, int target) {
    return '$current/$target';
  }

  @override
  String get bonusRound => 'Bónusz kör';

  @override
  String bonusRoundActive(String date) {
    return 'Aktív $date-ig';
  }

  @override
  String bonusPoints(int points) {
    return '+$points bónusz pont';
  }

  @override
  String get share => 'Megosztás';

  @override
  String get shareResult => 'Eredményem megosztása';

  @override
  String get sharePrediction => 'Tippem megosztása';

  @override
  String get days => 'n';

  @override
  String get hours => 'ó';

  @override
  String get minutes => 'p';

  @override
  String get seconds => 'mp';

  @override
  String get noRacesYet => 'Még nincsenek közelgő futamok';

  @override
  String get noPrediction => 'Még nincs tipp beküldve';

  @override
  String get loading => 'Betöltés...';

  @override
  String get retry => 'Újra';

  @override
  String get cancel => 'Mégse';

  @override
  String get save => 'Mentés';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Igen';

  @override
  String get no => 'Nem';

  @override
  String get friendCode => 'Barát kód';

  @override
  String get copyCode => 'Másolás';

  @override
  String get shareCode => 'Megosztás';

  @override
  String get myGroups => 'Csoportjaim';

  @override
  String get createGroup => 'Csoport létrehozása';

  @override
  String get inviteMembers => 'Tag meghívása';

  @override
  String get enterFriendCode => 'Barát kód (pl. F1X8KM)';

  @override
  String get inviteSent => 'Meghívó elküldve!';

  @override
  String get noGroupsYet => 'Még nincsenek csoportjaid. Hozz létre egyet!';

  @override
  String get groupInvitations => 'Meghívók';

  @override
  String get acceptInvite => 'Elfogadás';

  @override
  String get declineInvite => 'Elutasítás';

  @override
  String get notifications => 'Értesítések';

  @override
  String get markAllRead => 'Mind olvasott';

  @override
  String get noNotifications => 'Nincsenek értesítések';

  @override
  String get supportUs => 'Támogatás';

  @override
  String get supportDescription =>
      'Ha tetszik az alkalmazás, támogasd a fejlesztést!';

  @override
  String get aiAssistanceToggle => 'AI segítséget használok';

  @override
  String get aiAssistanceDescription =>
      'Jelöld be, ha AI eszközöket használsz a tippjeidhez. Külön ranglistán versenyzel.';

  @override
  String get globalStandings => 'Globális';

  @override
  String get groupStandings => 'Csoportjaim';

  @override
  String get filterAll => 'Mind';

  @override
  String get filterHuman => 'Emberi';

  @override
  String get filterAI => 'AI';

  @override
  String get owner => 'Alapító';

  @override
  String members(int count) {
    return '$count tag';
  }

  @override
  String get copied => 'Másolva!';
}
