// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'QuizBot';

  @override
  String get login => 'Entrar';

  @override
  String get register => 'Cadastrar-se';

  @override
  String get welcome => 'Bem-vindo!';

  @override
  String get createAccount => 'Crie sua conta';

  @override
  String get username => 'Nome de usuário';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get passwordLengthError =>
      'A senha deve conter pelo menos 8 caracteres.';

  @override
  String get passwordDigitError => 'A senha deve conter pelo menos 1 número.';

  @override
  String get joinWithCode => 'Entrar com código';

  @override
  String get haveAccount => 'Já tem uma conta? Entrar';

  @override
  String get noAccount => 'Não tem uma conta? Cadastre-se';

  @override
  String get createTab => 'Criar';

  @override
  String get myGamesTab => 'Meus Jogos';

  @override
  String get leaderboardTab => 'Classificação';

  @override
  String get myIQTab => 'Meu QI';

  @override
  String get friendsTab => 'Amigos';

  @override
  String get settings => 'Configurações';

  @override
  String get appearance => 'APARÊNCIA';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get language => 'IDIOMA';

  @override
  String get account => 'CONTA';

  @override
  String get logout => 'Sair';

  @override
  String get deleteAccount => 'Excluir conta';

  @override
  String get deleteAccountConfirmTitle => 'Excluir minha conta?';

  @override
  String get deleteAccountConfirmMessage =>
      'Esta ação é irreversível. Todas as suas pontuações, quizzes e dados de QI serão excluídos.';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get generateWithAI => 'Gerar com IA';

  @override
  String get generating => 'Gerando...';

  @override
  String get playOnline => 'Jogar online';

  @override
  String get createGame => 'Criar partida';

  @override
  String get joinRoom => 'Entrar na sala';

  @override
  String get inviteCode => 'Código de convite';

  @override
  String get enter6DigitCode =>
      'Digite o código de 6 dígitos fornecido pelo anfitrião';

  @override
  String get waitingRoom => 'Sala de espera';

  @override
  String get waitingForPlayers => 'Aguardando o anfitrião ou mais jogadores...';

  @override
  String get startGame => 'Iniciar partida';

  @override
  String playerLeft(String player) {
    return '$player saiu da partida.';
  }

  @override
  String playerJoined(String player) {
    return '$player entrou na partida.';
  }

  @override
  String get correct => 'Correto!';

  @override
  String get incorrect => 'Incorreto.';

  @override
  String timeRemaining(int seconds) {
    return 'Tempo restante: ${seconds}s';
  }

  @override
  String get nextQuestion => 'Próxima Pergunta';

  @override
  String get finishQuiz => 'Finalizar Quiz';

  @override
  String get podium => 'Pódio';

  @override
  String get finalRanking => 'Classificação Final';

  @override
  String get backToMenu => 'Voltar ao menu';

  @override
  String get seeHint => 'Ver dica';

  @override
  String get trueLabel => 'Verdadeiro';

  @override
  String get falseLabel => 'Falso';
}
