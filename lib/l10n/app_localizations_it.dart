// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'QuizBot';

  @override
  String get login => 'Accedi';

  @override
  String get register => 'Registrati';

  @override
  String get welcome => 'Benvenuto!';

  @override
  String get createAccount => 'Crea il tuo account';

  @override
  String get username => 'Nome utente';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get passwordLengthError =>
      'La password deve contenere almeno 8 caratteri.';

  @override
  String get passwordDigitError =>
      'La password deve contenere almeno 1 numero.';

  @override
  String get joinWithCode => 'Entra con un codice';

  @override
  String get haveAccount => 'Hai già un account? Accedi';

  @override
  String get noAccount => 'Non hai un account? Registrati';

  @override
  String get createTab => 'Crea';

  @override
  String get myGamesTab => 'I miei giochi';

  @override
  String get leaderboardTab => 'Classifica';

  @override
  String get myIQTab => 'Il mio QI';

  @override
  String get friendsTab => 'Amici';

  @override
  String get settings => 'Impostazioni';

  @override
  String get appearance => 'ASPETTO';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get language => 'LINGUA';

  @override
  String get account => 'ACCOUNT';

  @override
  String get logout => 'Disconnettiti';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get deleteAccountConfirmTitle => 'Eliminare l\'account?';

  @override
  String get deleteAccountConfirmMessage =>
      'Questa operazione è irreversibile. Tutti i tuoi quiz, punteggi e statistiche verranno cancellati.';

  @override
  String get confirm => 'Conferma';

  @override
  String get cancel => 'Annulla';

  @override
  String get generateWithAI => 'Genera con IA';

  @override
  String get generating => 'Generazione in corso...';

  @override
  String get playOnline => 'Gioca online';

  @override
  String get createGame => 'Crea partita';

  @override
  String get joinRoom => 'Unisciti a una stanza';

  @override
  String get inviteCode => 'Codice invito';

  @override
  String get enter6DigitCode =>
      'Inserisci il codice a 6 cifre fornito dall\'host';

  @override
  String get waitingRoom => 'Sala d\'attesa';

  @override
  String get waitingForPlayers =>
      'In attesa dell\'host o di altri giocatori...';

  @override
  String get startGame => 'Inizia partita';

  @override
  String playerLeft(String player) {
    return '$player ha lasciato la partita.';
  }

  @override
  String playerJoined(String player) {
    return '$player si è unito alla partita.';
  }

  @override
  String get correct => 'Corretto!';

  @override
  String get incorrect => 'Errato.';

  @override
  String timeRemaining(int seconds) {
    return 'Tempo rimasto: ${seconds}s';
  }

  @override
  String get nextQuestion => 'Prossima Domanda';

  @override
  String get finishQuiz => 'Termina Quiz';

  @override
  String get podium => 'Podio';

  @override
  String get finalRanking => 'Classifica Finale';

  @override
  String get backToMenu => 'Torna al menu';

  @override
  String get seeHint => 'Mostra indizio';

  @override
  String get trueLabel => 'Vero';

  @override
  String get falseLabel => 'Falso';
}
