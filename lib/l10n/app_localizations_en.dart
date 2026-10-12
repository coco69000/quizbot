// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QuizBot';

  @override
  String get login => 'Login';

  @override
  String get register => 'Sign Up';

  @override
  String get welcome => 'Welcome!';

  @override
  String get createAccount => 'Create your account';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get passwordLengthError => 'Password must be at least 8 characters.';

  @override
  String get passwordDigitError => 'Password must contain at least 1 number.';

  @override
  String get joinWithCode => 'Join with a code';

  @override
  String get haveAccount => 'Already have an account? Log in';

  @override
  String get noAccount => 'Don\'t have an account? Sign up';

  @override
  String get createTab => 'Create';

  @override
  String get myGamesTab => 'My Games';

  @override
  String get leaderboardTab => 'Leaderboard';

  @override
  String get myIQTab => 'My IQ';

  @override
  String get friendsTab => 'Friends';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'APPEARANCE';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get language => 'LANGUAGE';

  @override
  String get account => 'ACCOUNT';

  @override
  String get logout => 'Log out';

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get deleteAccountConfirmTitle => 'Delete account?';

  @override
  String get deleteAccountConfirmMessage =>
      'This action cannot be undone. All your quizzes, scores, and IQ stats will be permanently erased.';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get generateWithAI => 'Generate with AI';

  @override
  String get generating => 'Generating...';

  @override
  String get playOnline => 'Play Online';

  @override
  String get createGame => 'Create Game';

  @override
  String get joinRoom => 'Join Room';

  @override
  String get inviteCode => 'Invite Code';

  @override
  String get enter6DigitCode => 'Enter the 6-digit code provided by the host';

  @override
  String get waitingRoom => 'Waiting Room';

  @override
  String get waitingForPlayers => 'Waiting for host or players...';

  @override
  String get startGame => 'Start Game';

  @override
  String playerLeft(String player) {
    return '$player left the game.';
  }

  @override
  String playerJoined(String player) {
    return '$player joined the game.';
  }

  @override
  String get correct => 'Correct!';

  @override
  String get incorrect => 'Incorrect.';

  @override
  String timeRemaining(int seconds) {
    return 'Time left: ${seconds}s';
  }

  @override
  String get nextQuestion => 'Next Question';

  @override
  String get finishQuiz => 'Finish Quiz';

  @override
  String get podium => 'Podium';

  @override
  String get finalRanking => 'Final Ranking';

  @override
  String get backToMenu => 'Back to Menu';

  @override
  String get seeHint => 'Show hint';

  @override
  String get trueLabel => 'True';

  @override
  String get falseLabel => 'False';
}
