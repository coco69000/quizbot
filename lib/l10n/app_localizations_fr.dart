// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'QuizBot';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get welcome => 'Bienvenue !';

  @override
  String get createAccount => 'Créez votre compte';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordLengthError =>
      'Le mot de passe doit contenir au moins 8 caractères.';

  @override
  String get passwordDigitError =>
      'Le mot de passe doit contenir au moins 1 chiffre.';

  @override
  String get joinWithCode => 'Rejoindre avec un code';

  @override
  String get haveAccount => 'Déjà un compte ? Se connecter';

  @override
  String get noAccount => 'Pas encore de compte ? S\'inscrire';

  @override
  String get createTab => 'Créer';

  @override
  String get myGamesTab => 'Mes Jeux';

  @override
  String get leaderboardTab => 'Classement';

  @override
  String get myIQTab => 'Mon QI';

  @override
  String get friendsTab => 'Amis';

  @override
  String get settings => 'Paramètres';

  @override
  String get appearance => 'APPARENCE';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get language => 'LANGUE';

  @override
  String get account => 'COMPTE';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get deleteAccount => 'Supprimer mon compte';

  @override
  String get deleteAccountConfirmTitle => 'Supprimer mon compte ?';

  @override
  String get deleteAccountConfirmMessage =>
      'Cette action est irréversible. Toutes vos données, quiz, scores et statistiques seront effacés.';

  @override
  String get confirm => 'Confirmer';

  @override
  String get cancel => 'Annuler';

  @override
  String get generateWithAI => 'Générer par IA';

  @override
  String get generating => 'Génération en cours...';

  @override
  String get playOnline => 'Jouer en ligne';

  @override
  String get createGame => 'Créer une partie';

  @override
  String get joinRoom => 'Rejoindre une salle';

  @override
  String get inviteCode => 'Code d\'invitation';

  @override
  String get enter6DigitCode =>
      'Entrez le code à 6 chiffres fourni par l\'hôte';

  @override
  String get waitingRoom => 'Salle d\'attente';

  @override
  String get waitingForPlayers =>
      'En attente de l\'hôte ou d\'autres joueurs...';

  @override
  String get startGame => 'Démarrer la partie';

  @override
  String playerLeft(String player) {
    return '$player a quitté la partie.';
  }

  @override
  String playerJoined(String player) {
    return '$player a rejoint la partie.';
  }

  @override
  String get correct => 'Correct !';

  @override
  String get incorrect => 'Incorrect.';

  @override
  String timeRemaining(int seconds) {
    return 'Temps restant : ${seconds}s';
  }

  @override
  String get nextQuestion => 'Question Suivante';

  @override
  String get finishQuiz => 'Terminer le Quiz';

  @override
  String get podium => 'Podium';

  @override
  String get finalRanking => 'Classement Final';

  @override
  String get backToMenu => 'Retour au menu';

  @override
  String get seeHint => 'Voir l\'indice';

  @override
  String get trueLabel => 'Vrai';

  @override
  String get falseLabel => 'Faux';
}
