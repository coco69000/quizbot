// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'QuizBot';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get register => 'Registrarse';

  @override
  String get welcome => '¡Bienvenido!';

  @override
  String get createAccount => 'Crea tu cuenta';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get passwordLengthError =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String get passwordDigitError =>
      'La contraseña debe contener al menos 1 número.';

  @override
  String get joinWithCode => 'Unirse con un código';

  @override
  String get haveAccount => '¿Ya tienes una cuenta? Iniciar sesión';

  @override
  String get noAccount => '¿No tienes cuenta? Regístrate';

  @override
  String get createTab => 'Crear';

  @override
  String get myGamesTab => 'Mis Juegos';

  @override
  String get leaderboardTab => 'Clasificación';

  @override
  String get myIQTab => 'Mi CI';

  @override
  String get friendsTab => 'Amigos';

  @override
  String get settings => 'Ajustes';

  @override
  String get appearance => 'APARIENCIA';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get language => 'IDIOMA';

  @override
  String get account => 'CUENTA';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get deleteAccount => 'Eliminar mi cuenta';

  @override
  String get deleteAccountConfirmTitle => '¿Eliminar mi cuenta?';

  @override
  String get deleteAccountConfirmMessage =>
      'Esta acción es irreversible. Se borrarán todas tus partidas, puntuaciones y estadísticas de CI.';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get generateWithAI => 'Generar con IA';

  @override
  String get generating => 'Generando...';

  @override
  String get playOnline => 'Jugar en línea';

  @override
  String get createGame => 'Crear partida';

  @override
  String get joinRoom => 'Unirse a una sala';

  @override
  String get inviteCode => 'Código de invitación';

  @override
  String get enter6DigitCode =>
      'Introduce el código de 6 dígitos proporcionado por el anfitrión';

  @override
  String get waitingRoom => 'Sala de espera';

  @override
  String get waitingForPlayers => 'Esperando al anfitrión o más jugadores...';

  @override
  String get startGame => 'Iniciar partida';

  @override
  String playerLeft(String player) {
    return '$player ha salido de la partida.';
  }

  @override
  String playerJoined(String player) {
    return '$player se ha unido a la partida.';
  }

  @override
  String get correct => '¡Correcto!';

  @override
  String get incorrect => 'Incorrecto.';

  @override
  String timeRemaining(int seconds) {
    return 'Tiempo restante: ${seconds}s';
  }

  @override
  String get nextQuestion => 'Siguiente Pregunta';

  @override
  String get finishQuiz => 'Terminar Quiz';

  @override
  String get podium => 'Podio';

  @override
  String get finalRanking => 'Clasificación Final';

  @override
  String get backToMenu => 'Volver al menú';

  @override
  String get seeHint => 'Ver pista';

  @override
  String get trueLabel => 'Verdadero';

  @override
  String get falseLabel => 'Falso';
}
