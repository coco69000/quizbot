// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'QuizBot';

  @override
  String get login => 'Увійти';

  @override
  String get register => 'Зареєструватися';

  @override
  String get welcome => 'Ласкаво просимо!';

  @override
  String get createAccount => 'Створіть свій акаунт';

  @override
  String get username => 'Ім\'я користувача';

  @override
  String get email => 'Електронна пошта';

  @override
  String get password => 'Пароль';

  @override
  String get passwordLengthError => 'Пароль має містити щонайменше 8 символів.';

  @override
  String get passwordDigitError => 'Пароль повинен містити хоча б 1 цифру.';

  @override
  String get joinWithCode => 'Приєднатися за кодом';

  @override
  String get haveAccount => 'Вже є акаунт? Увійти';

  @override
  String get noAccount => 'Немає акаунта? Зареєструватися';

  @override
  String get createTab => 'Створити';

  @override
  String get myGamesTab => 'Мої ігри';

  @override
  String get leaderboardTab => 'Рейтинг';

  @override
  String get myIQTab => 'Мій IQ';

  @override
  String get friendsTab => 'Друзі';

  @override
  String get settings => 'Налаштування';

  @override
  String get appearance => 'ВИГЛЯД';

  @override
  String get themeLight => 'Світла';

  @override
  String get themeDark => 'Темна';

  @override
  String get themeSystem => 'Системна';

  @override
  String get language => 'МОВА';

  @override
  String get account => 'АККУНТ';

  @override
  String get logout => 'Вийти';

  @override
  String get deleteAccount => 'Видалити акаунт';

  @override
  String get deleteAccountConfirmTitle => 'Видалити акаунт?';

  @override
  String get deleteAccountConfirmMessage =>
      'Цю дію не можна скасувати. Всі ваші квізи, бали та статистика IQ будуть видалені назавжди.';

  @override
  String get confirm => 'Підтвердити';

  @override
  String get cancel => 'Скасувати';

  @override
  String get generateWithAI => 'Згенерувати через ШІ';

  @override
  String get generating => 'Генерація...';

  @override
  String get playOnline => 'Грати онлайн';

  @override
  String get createGame => 'Створити гру';

  @override
  String get joinRoom => 'Увійти в кімнату';

  @override
  String get inviteCode => 'Код запрошення';

  @override
  String get enter6DigitCode => 'Введіть 6-значний код від організатора';

  @override
  String get waitingRoom => 'Кімната очікування';

  @override
  String get waitingForPlayers => 'Очікування організатора або гравців...';

  @override
  String get startGame => 'Почати гру';

  @override
  String playerLeft(String player) {
    return '$player залишив гру.';
  }

  @override
  String playerJoined(String player) {
    return '$player приєднався до гри.';
  }

  @override
  String get correct => 'Правильно!';

  @override
  String get incorrect => 'Неправильно.';

  @override
  String timeRemaining(int seconds) {
    return 'Залишилося часу: $secondsс';
  }

  @override
  String get nextQuestion => 'Наступне питання';

  @override
  String get finishQuiz => 'Завершити квіз';

  @override
  String get podium => 'Подіум';

  @override
  String get finalRanking => 'Фінальний рейтинг';

  @override
  String get backToMenu => 'В головне меню';

  @override
  String get seeHint => 'Показати підказку';

  @override
  String get trueLabel => 'Правда';

  @override
  String get falseLabel => 'Неправда';
}
