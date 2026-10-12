// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'QuizBot';

  @override
  String get login => 'Войти';

  @override
  String get register => 'Регистрация';

  @override
  String get welcome => 'Добро пожаловать!';

  @override
  String get createAccount => 'Создайте учетную запись';

  @override
  String get username => 'Имя пользователя';

  @override
  String get email => 'Электронная почта';

  @override
  String get password => 'Пароль';

  @override
  String get passwordLengthError =>
      'Пароль должен содержать не менее 8 символов.';

  @override
  String get passwordDigitError =>
      'Пароль должен содержать как минимум 1 цифру.';

  @override
  String get joinWithCode => 'Войти по коду';

  @override
  String get haveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get noAccount => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get createTab => 'Создать';

  @override
  String get myGamesTab => 'Мои игры';

  @override
  String get leaderboardTab => 'Рейтинг';

  @override
  String get myIQTab => 'Мой IQ';

  @override
  String get friendsTab => 'Друзья';

  @override
  String get settings => 'Настройки';

  @override
  String get appearance => 'ОФОРМЛЕНИЕ';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Темная';

  @override
  String get themeSystem => 'Системная';

  @override
  String get language => 'ЯЗЫК';

  @override
  String get account => 'АККАУНТ';

  @override
  String get logout => 'Выйти';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountConfirmTitle => 'Удалить аккаунт?';

  @override
  String get deleteAccountConfirmMessage =>
      'Это действие необратимо. Все викторины, очки и статистика IQ будут безвозвратно удалены.';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get cancel => 'Отмена';

  @override
  String get generateWithAI => 'Создать с помощью ИИ';

  @override
  String get generating => 'Генерация...';

  @override
  String get playOnline => 'Играть онлайн';

  @override
  String get createGame => 'Создать игру';

  @override
  String get joinRoom => 'Войти в комнату';

  @override
  String get inviteCode => 'Код приглашения';

  @override
  String get enter6DigitCode => 'Введите 6-значный код от организатора';

  @override
  String get waitingRoom => 'Комната ожидания';

  @override
  String get waitingForPlayers => 'Ожидание организатора или игроков...';

  @override
  String get startGame => 'Начать игру';

  @override
  String playerLeft(String player) {
    return '$player покинул игру.';
  }

  @override
  String playerJoined(String player) {
    return '$player присоединился к игре.';
  }

  @override
  String get correct => 'Верно!';

  @override
  String get incorrect => 'Неверно.';

  @override
  String timeRemaining(int seconds) {
    return 'Осталось времени: $secondsс';
  }

  @override
  String get nextQuestion => 'Следующий вопрос';

  @override
  String get finishQuiz => 'Завершить викторину';

  @override
  String get podium => 'Пьедестал';

  @override
  String get finalRanking => 'Итоговая таблица';

  @override
  String get backToMenu => 'В главное меню';

  @override
  String get seeHint => 'Показать подсказку';

  @override
  String get trueLabel => 'Правда';

  @override
  String get falseLabel => 'Ложь';
}
