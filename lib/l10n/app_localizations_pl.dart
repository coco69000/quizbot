// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'QuizBot';

  @override
  String get login => 'Zaloguj się';

  @override
  String get register => 'Zarejestruj się';

  @override
  String get welcome => 'Witaj!';

  @override
  String get createAccount => 'Utwórz konto';

  @override
  String get username => 'Nazwa użytkownika';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Hasło';

  @override
  String get passwordLengthError => 'Hasło musi mieć co najmniej 8 znaków.';

  @override
  String get passwordDigitError => 'Hasło musi zawierać co najmniej 1 cyfrę.';

  @override
  String get joinWithCode => 'Dołącz z kodem';

  @override
  String get haveAccount => 'Masz już konto? Zaloguj się';

  @override
  String get noAccount => 'Nie masz konta? Zarejestruj się';

  @override
  String get createTab => 'Utwórz';

  @override
  String get myGamesTab => 'Moje Gry';

  @override
  String get leaderboardTab => 'Ranking';

  @override
  String get myIQTab => 'Moje IQ';

  @override
  String get friendsTab => 'Znajomi';

  @override
  String get settings => 'Ustawienia';

  @override
  String get appearance => 'WYGLĄD';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get themeSystem => 'Systemowy';

  @override
  String get language => 'JĘZYK';

  @override
  String get account => 'KONTO';

  @override
  String get logout => 'Wyloguj się';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get deleteAccountConfirmTitle => 'Usunąć konto?';

  @override
  String get deleteAccountConfirmMessage =>
      'Tej operacji nie można cofnąć. Wszystkie Twoje quizy, wyniki i statystyki IQ zostaną trwale usunięte.';

  @override
  String get confirm => 'Potwierdź';

  @override
  String get cancel => 'Anuluj';

  @override
  String get generateWithAI => 'Generuj przez AI';

  @override
  String get generating => 'Generowanie...';

  @override
  String get playOnline => 'Graj online';

  @override
  String get createGame => 'Stwórz grę';

  @override
  String get joinRoom => 'Dołącz do pokoju';

  @override
  String get inviteCode => 'Kod zaproszenia';

  @override
  String get enter6DigitCode => 'Wpisz 6-cyfrowy kod podany przez gospodarza';

  @override
  String get waitingRoom => 'Poczekalnia';

  @override
  String get waitingForPlayers => 'Oczekiwanie na gospodarza lub graczy...';

  @override
  String get startGame => 'Rozpocznij grę';

  @override
  String playerLeft(String player) {
    return '$player opuścił grę.';
  }

  @override
  String playerJoined(String player) {
    return '$player dołączył do gry.';
  }

  @override
  String get correct => 'Prawidłowo!';

  @override
  String get incorrect => 'Nieprawidłowo.';

  @override
  String timeRemaining(int seconds) {
    return 'Pozostały czas: ${seconds}s';
  }

  @override
  String get nextQuestion => 'Następne pytanie';

  @override
  String get finishQuiz => 'Zakończ quiz';

  @override
  String get podium => 'Podium';

  @override
  String get finalRanking => 'Klasyfikacja końcowa';

  @override
  String get backToMenu => 'Wróć do menu';

  @override
  String get seeHint => 'Pokaż podpowiedź';

  @override
  String get trueLabel => 'Prawda';

  @override
  String get falseLabel => 'Fałsz';
}
