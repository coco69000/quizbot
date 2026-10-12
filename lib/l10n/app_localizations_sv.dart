// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'QuizBot';

  @override
  String get login => 'Logga in';

  @override
  String get register => 'Registrera dig';

  @override
  String get welcome => 'Välkommen!';

  @override
  String get createAccount => 'Skapa ditt konto';

  @override
  String get username => 'Användarnamn';

  @override
  String get email => 'E-post';

  @override
  String get password => 'Lösenord';

  @override
  String get passwordLengthError =>
      'Lösenordet måste vara minst 8 tecken långt.';

  @override
  String get passwordDigitError =>
      'Lösenordet måste innehålla minst en siffra.';

  @override
  String get joinWithCode => 'Gå med med kod';

  @override
  String get haveAccount => 'Har du redan ett konto? Logga in';

  @override
  String get noAccount => 'Inget konto? Registrera dig';

  @override
  String get createTab => 'Skapa';

  @override
  String get myGamesTab => 'Mina spel';

  @override
  String get leaderboardTab => 'Topplista';

  @override
  String get myIQTab => 'Mitt IQ';

  @override
  String get friendsTab => 'Vänner';

  @override
  String get settings => 'Inställningar';

  @override
  String get appearance => 'UTSEENDE';

  @override
  String get themeLight => 'Ljust';

  @override
  String get themeDark => 'Mörkt';

  @override
  String get themeSystem => 'System';

  @override
  String get language => 'SPRÅK';

  @override
  String get account => 'KONTO';

  @override
  String get logout => 'Logga ut';

  @override
  String get deleteAccount => 'Radera mitt konto';

  @override
  String get deleteAccountConfirmTitle => 'Radera konto?';

  @override
  String get deleteAccountConfirmMessage =>
      'Denna åtgärd kan inte ångras. Alla dina quiz, poäng och IQ-data tas bort permanent.';

  @override
  String get confirm => 'Bekräfta';

  @override
  String get cancel => 'Avbryt';

  @override
  String get generateWithAI => 'Skapa med AI';

  @override
  String get generating => 'Genererar...';

  @override
  String get playOnline => 'Spela online';

  @override
  String get createGame => 'Skapa match';

  @override
  String get joinRoom => 'Gå med i rum';

  @override
  String get inviteCode => 'Inbjudningskod';

  @override
  String get enter6DigitCode => 'Ange den 6-siffriga koden från värden';

  @override
  String get waitingRoom => 'Väntrum';

  @override
  String get waitingForPlayers => 'Väntar på värden eller fler spelare...';

  @override
  String get startGame => 'Starta spelet';

  @override
  String playerLeft(String player) {
    return '$player lämnade spelet.';
  }

  @override
  String playerJoined(String player) {
    return '$player gick med i spelet.';
  }

  @override
  String get correct => 'Rätt!';

  @override
  String get incorrect => 'Fel.';

  @override
  String timeRemaining(int seconds) {
    return 'Tid kvar: ${seconds}s';
  }

  @override
  String get nextQuestion => 'Nästa fråga';

  @override
  String get finishQuiz => 'Slutför quiz';

  @override
  String get podium => 'Prispall';

  @override
  String get finalRanking => 'Slutställning';

  @override
  String get backToMenu => 'Tillbaka till menyn';

  @override
  String get seeHint => 'Visa ledtråd';

  @override
  String get trueLabel => 'Sant';

  @override
  String get falseLabel => 'Falskt';
}
