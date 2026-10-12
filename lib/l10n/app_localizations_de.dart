// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'QuizBot';

  @override
  String get login => 'Anmelden';

  @override
  String get register => 'Registrieren';

  @override
  String get welcome => 'Willkommen!';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get username => 'Benutzername';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get passwordLengthError =>
      'Das Passwort muss mindestens 8 Zeichen lang sein.';

  @override
  String get passwordDigitError =>
      'Das Passwort muss mindestens 1 Ziffer enthalten.';

  @override
  String get joinWithCode => 'Mit Code beitreten';

  @override
  String get haveAccount => 'Bereits registriert? Anmelden';

  @override
  String get noAccount => 'Noch kein Konto? Registrieren';

  @override
  String get createTab => 'Erstellen';

  @override
  String get myGamesTab => 'Meine Spiele';

  @override
  String get leaderboardTab => 'Rangliste';

  @override
  String get myIQTab => 'Mein IQ';

  @override
  String get friendsTab => 'Freunde';

  @override
  String get settings => 'Einstellungen';

  @override
  String get appearance => 'ERSCHEINUNGSBILD';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSystem => 'System';

  @override
  String get language => 'SPRACHE';

  @override
  String get account => 'KONTO';

  @override
  String get logout => 'Abmelden';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountConfirmTitle => 'Konto endgültig löschen?';

  @override
  String get deleteAccountConfirmMessage =>
      'Diese Aktion kann nicht rückgängig gemacht werden. Alle Daten, Quizze und IQ-Werte werden gelöscht.';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get generateWithAI => 'Mit KI generieren';

  @override
  String get generating => 'Wird generiert...';

  @override
  String get playOnline => 'Online spielen';

  @override
  String get createGame => 'Spiel erstellen';

  @override
  String get joinRoom => 'Raum beitreten';

  @override
  String get inviteCode => 'Einladungscode';

  @override
  String get enter6DigitCode => 'Gib den 6-stelligen Code des Hosts ein';

  @override
  String get waitingRoom => 'Warteraum';

  @override
  String get waitingForPlayers => 'Warte auf den Host oder andere Spieler...';

  @override
  String get startGame => 'Spiel starten';

  @override
  String playerLeft(String player) {
    return '$player hat das Spiel verlassen.';
  }

  @override
  String playerJoined(String player) {
    return '$player ist dem Spiel beigetreten.';
  }

  @override
  String get correct => 'Richtig!';

  @override
  String get incorrect => 'Falsch.';

  @override
  String timeRemaining(int seconds) {
    return 'Verbleibende Zeit: ${seconds}s';
  }

  @override
  String get nextQuestion => 'Nächste Frage';

  @override
  String get finishQuiz => 'Quiz beenden';

  @override
  String get podium => 'Podium';

  @override
  String get finalRanking => 'Endstand';

  @override
  String get backToMenu => 'Zurück zum Menü';

  @override
  String get seeHint => 'Hinweis anzeigen';

  @override
  String get trueLabel => 'Wahr';

  @override
  String get falseLabel => 'Falsch';
}
