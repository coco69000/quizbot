// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'QuizBot';

  @override
  String get login => 'Inloggen';

  @override
  String get register => 'Registreren';

  @override
  String get welcome => 'Welkom!';

  @override
  String get createAccount => 'Maak een account aan';

  @override
  String get username => 'Gebruikersnaam';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Wachtwoord';

  @override
  String get passwordLengthError =>
      'Wachtwoord moet minimaal 8 tekens bevatten.';

  @override
  String get passwordDigitError =>
      'Wachtwoord moet minimaal 1 cijfer bevatten.';

  @override
  String get joinWithCode => 'Deelnemen met code';

  @override
  String get haveAccount => 'Heb je al een account? Inloggen';

  @override
  String get noAccount => 'Nog geen account? Registreren';

  @override
  String get createTab => 'Maken';

  @override
  String get myGamesTab => 'Mijn Spellen';

  @override
  String get leaderboardTab => 'Ranglijst';

  @override
  String get myIQTab => 'Mijn IQ';

  @override
  String get friendsTab => 'Vrienden';

  @override
  String get settings => 'Instellingen';

  @override
  String get appearance => 'WEERGAVE';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Donker';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get language => 'TAAL';

  @override
  String get account => 'ACCOUNT';

  @override
  String get logout => 'Uitloggen';

  @override
  String get deleteAccount => 'Account verwijderen';

  @override
  String get deleteAccountConfirmTitle => 'Account definitief verwijderen?';

  @override
  String get deleteAccountConfirmMessage =>
      'Deze actie is onomkeerbaar. Al je quizzen, scores en statistieken worden gewist.';

  @override
  String get confirm => 'Bevestigen';

  @override
  String get cancel => 'Annuleren';

  @override
  String get generateWithAI => 'Genereren met AI';

  @override
  String get generating => 'Genereren...';

  @override
  String get playOnline => 'Online spelen';

  @override
  String get createGame => 'Spel maken';

  @override
  String get joinRoom => 'Kamer binnengaan';

  @override
  String get inviteCode => 'Uitnodigingscode';

  @override
  String get enter6DigitCode => 'Voer de 6-cijferige code in van de host';

  @override
  String get waitingRoom => 'Wachtkamer';

  @override
  String get waitingForPlayers => 'Wachten op de host of andere spelers...';

  @override
  String get startGame => 'Start spel';

  @override
  String playerLeft(String player) {
    return '$player heeft het spel verlaten.';
  }

  @override
  String playerJoined(String player) {
    return '$player doet mee aan het spel.';
  }

  @override
  String get correct => 'Juist!';

  @override
  String get incorrect => 'Onjuist.';

  @override
  String timeRemaining(int seconds) {
    return 'Resterende tijd: ${seconds}s';
  }

  @override
  String get nextQuestion => 'Volgende Vraag';

  @override
  String get finishQuiz => 'Quiz afronden';

  @override
  String get podium => 'Podium';

  @override
  String get finalRanking => 'Eindklassement';

  @override
  String get backToMenu => 'Terug naar menu';

  @override
  String get seeHint => 'Hint bekijken';

  @override
  String get trueLabel => 'Waar';

  @override
  String get falseLabel => 'Niet waar';
}
