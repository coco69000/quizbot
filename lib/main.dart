import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

// --- CLASSE POUR LE FEEDBACK DU JEU "MOT MYSTÈRE" ---
// Représente le statut de chaque lettre d'une tentative.
enum LetterStatus { none, notInWord, inWord, correctPosition }

class LetterFeedback {
  final String letter;
  final LetterStatus status;

  LetterFeedback({required this.letter, required this.status});
}

Future<Map<String, dynamic>> callSecureAI({
  String? model,
  required String systemMessage,
  required String prompt,
  double temperature = 0.3,
  bool imageRequested = false,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Vous devez être connecté pour utiliser l'IA.");
    }

    final callable = FirebaseFunctions.instance.httpsCallable('generateQuiz');
    final result = await callable.call({
      'systemMessage': systemMessage,
      'prompt': prompt,
      'temperature': temperature,
      'imageRequested': imageRequested,
    });

    if (result.data == null) {
      throw Exception("Le serveur n'a renvoyé aucune donnée.");
    }

    return Map<String, dynamic>.from(result.data as Map);
  } on FirebaseFunctionsException catch (e) {
    if (e.message != null && e.message!.contains('401')) {
      throw Exception(
        'Clé API SiliconFlow non autorisée (401). Vérifiez DEEPSEEK_API_KEY.',
      );
    }
    throw Exception(e.message ?? 'Erreur du serveur [${e.code}]');
  } catch (e) {
    final msg = e.toString().replaceAll('Exception: ', '');
    throw Exception(msg);
  }
}

Future<String?> extractThemeFromQuizText(String quizText) async {
  try {
    final data = await callSecureAI(
      systemMessage:
          'Extrais le thème principal du texte. Réponds UNIQUEMENT avec un objet JSON strict au format {"theme": "NomDuTheme"}. Utilise un thème général et court (1-3 mots max, ex: "Histoire", "Sciences", "Animaux"). Ne fais aucune phrase.',
      prompt: quizText,
    );

    if (data['choices'] != null && (data['choices'] as List).isNotEmpty) {
      String content =
          data['choices'][0]['message']['content']?.toString().trim() ?? '';
      content = content.replaceAll(RegExp(r'```json\s*|```'), '');

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final decoded = jsonDecode(jsonMatch.group(0)!);
        return decoded['theme']?.toString().trim() ?? 'Général';
      }
    }
    return 'Général';
  } catch (e) {
    print('Erreur lors de l\'extraction du thème : $e');
    return 'Général';
  }
}

class AppColors {
  static const midnight = Color(0xFF0A1020);
  static const midnightSurface = Color(0xFF121A2C);
  static const midnightCard = Color(0xFF17233A);
  static const softWhite = Color(0xFFF8FAFF);
  static const softWhiteAlt = Color(0xFFEFF3FF);
  static const primaryBlue = Color(0xFF245BFF);
  static const deepBlue = Color(0xFF0D2A6C);
  static const neonCyan = Color(0xFF49E6FF);
  static const neonMint = Color(0xFF62F5D1);
  static const goldLock = Color(0xFFFFC857);
  static const textSecondary = Color(0xFF6B7280);

  // AJOUT : Nouvelles couleurs
  static const quizPurple = Color(0xFF6C3FC7);
  static const quizOrange = Color(0xFFFF6B35);
  static const successGreen = Color(0xFF2ECC71);
  static const errorRed = Color(0xFFE74C3C);
  static const warningOrange = Color(0xFFF39C12);
}

class AppRadii {
  static const double card = 24;
  static const double button = 16;
}

class AppBadges {
  static final List<Map<String, dynamic>> allBadges = [
    {'id': 'first_game', 'name': 'Débutant', 'desc': 'Jouer votre première partie.', 'icon': '🎮', 'color': Colors.blue},
    {'id': 'amateur', 'name': 'Amateur', 'desc': 'Jouer 10 parties.', 'icon': '🎲', 'color': Colors.lightBlue},
    {'id': 'veteran', 'name': 'Vétéran', 'desc': 'Jouer 50 parties.', 'icon': '⚔️', 'color': Colors.purple},
    {'id': 'expert', 'name': 'Expert', 'desc': 'Jouer 100 parties.', 'icon': '🏅', 'color': Colors.orange},
    {'id': 'first_win', 'name': 'Première Victoire', 'desc': 'Gagner en ligne.', 'icon': '🏆', 'color': Colors.amber},
    {'id': 'champion', 'name': 'Champion', 'desc': 'Gagner 10 parties en ligne.', 'icon': '👑', 'color': Colors.amberAccent},
    {'id': 'legend', 'name': 'Légende', 'desc': 'Gagner 50 parties en ligne.', 'icon': '🌟', 'color': Colors.yellowAccent},
    {'id': 'iq_110', 'name': 'Esprit Vif', 'desc': 'Atteindre 110 de QI.', 'icon': '💡', 'color': Colors.teal},
    {'id': 'iq_130', 'name': 'Génie', 'desc': 'Atteindre 130 de QI.', 'icon': '🧠', 'color': Colors.indigo},
    {'id': 'iq_150', 'name': 'Einstein', 'desc': 'Atteindre 150 de QI.', 'icon': '⚛️', 'color': Colors.deepPurple},
    {'id': 'score_500', 'name': 'Apprenti', 'desc': 'Atteindre 500 points.', 'icon': '🪙', 'color': Colors.grey},
    {'id': 'score_2000', 'name': 'Connaisseur', 'desc': 'Atteindre 2000 points.', 'icon': '🥈', 'color': Colors.blueGrey},
    {'id': 'score_5000', 'name': 'Maître', 'desc': 'Atteindre 5000 points.', 'icon': '🥇', 'color': Colors.amber},
    {'id': 'perfect_score', 'name': 'Perfection', 'desc': '100% de réussite.', 'icon': '🎯', 'color': Colors.redAccent},
    {'id': 'history_buff', 'name': 'Historien', 'desc': 'Bon score en Histoire.', 'icon': '🏛️', 'color': Colors.brown},
    {'id': 'science_buff', 'name': 'Scientifique', 'desc': 'Bon score en Sciences.', 'icon': '🔬', 'color': Colors.cyan},
    {'id': 'geo_buff', 'name': 'Explorateur', 'desc': 'Bon score en Géographie.', 'icon': '🌍', 'color': Colors.green},
    {'id': 'art_buff', 'name': 'Artiste', 'desc': 'Bon score en Art.', 'icon': '🎨', 'color': Colors.pink},
    {'id': 'cinema_buff', 'name': 'Cinéphile', 'desc': 'Bon score en Cinéma.', 'icon': '🎬', 'color': Colors.black87},
    {'id': 'sport_buff', 'name': 'Athlète', 'desc': 'Bon score en Sport.', 'icon': '⚽', 'color': Colors.deepOrange},
    {'id': 'survivor', 'name': 'Survivant', 'desc': 'Finir un long quiz.', 'icon': '🛡️', 'color': Colors.red},
    {'id': 'fast_learner', 'name': 'Évolution', 'desc': 'Améliorer son QI.', 'icon': '📈', 'color': Colors.lightGreen},
    {'id': 'creator_5', 'name': 'Créateur Novice', 'desc': 'Créer 5 quiz.', 'icon': '📝', 'color': Colors.indigoAccent},
    {'id': 'creator_10', 'name': 'Créateur Confirmé', 'desc': 'Créer 10 quiz.', 'icon': '🏗️', 'color': Colors.deepOrangeAccent},
    {'id': 'creator_50', 'name': 'Maître Créateur', 'desc': 'Créer 50 quiz.', 'icon': '🎨', 'color': Colors.purpleAccent},
  ];

  static Future<void> checkCreationBadges(BuildContext context, String uid) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userRef.get();
      if (!userDoc.exists) return;

      final currentBadges = List<String>.from(userDoc.data()?['badges'] ?? []);
      final quizzesSnap = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('userId', isEqualTo: uid)
          .get();
      final count = quizzesSnap.docs.length;

      List<String> newBadges = [];
      if (count >= 5 && !currentBadges.contains('creator_5')) newBadges.add('creator_5');
      if (count >= 10 && !currentBadges.contains('creator_10')) newBadges.add('creator_10');
      if (count >= 50 && !currentBadges.contains('creator_50')) newBadges.add('creator_50');

      if (newBadges.isNotEmpty) {
        await userRef.update({
          'badges': FieldValue.arrayUnion(newBadges),
        });
        if (context.mounted) {
          showNewBadges(context, newBadges);
        }
      }
    } catch (e) {
      print('Erreur vérification badges création: $e');
    }
  }

  static void showNewBadges(BuildContext context, List<dynamic> newBadgeIds) {
    for (String id in newBadgeIds.cast<String>()) {
      final badge = allBadges.firstWhere((b) => b['id'] == id, orElse: () => {});
      if (badge.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(badge['icon'], style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('NOUVEAU BADGE DÉBLOQUÉ !', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                      Text(badge['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: badge['color'],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  static Widget buildBadgeGrid(List<String> earnedIds) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: allBadges.length,
      itemBuilder: (context, index) {
        final badge = allBadges[index];
        final isEarned = earnedIds.contains(badge['id']);
        final Color badgeColor = badge['color'] as Color;
        return Tooltip(
          message: '${badge['name']}\n${badge['desc']}',
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isEarned ? 1.0 : 0.3,
            child: Card(
              elevation: isEarned ? 4 : 0,
              color: isEarned ? badgeColor.withValues(alpha: 0.15) : Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isEarned ? badgeColor : Colors.grey.shade400,
                  width: isEarned ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(badge['icon'], style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 6),
                  Text(
                    badge['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
                      color: isEarned ? badgeColor : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class StyledCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const StyledCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.white.withOpacity(0.65),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.03),
                  ]
                  : [
                    Colors.white.withOpacity(0.92),
                    Colors.white.withOpacity(0.78),
                  ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.neonCyan : AppColors.primaryBlue)
                .withOpacity(0.09),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class HangmanPainter extends CustomPainter {
  final int mistakes;

  final Color color;
  HangmanPainter({required this.mistakes, this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;
    if (mistakes > 0)
      canvas.drawLine(
        Offset(size.width * 0.1, size.height * 0.9),
        Offset(size.width * 0.9, size.height * 0.9),
        paint,
      );
    if (mistakes > 1)
      canvas.drawLine(
        Offset(size.width * 0.2, size.height * 0.9),
        Offset(size.width * 0.2, size.height * 0.1),
        paint,
      );
    if (mistakes > 2)
      canvas.drawLine(
        Offset(size.width * 0.2, size.height * 0.1),
        Offset(size.width * 0.6, size.height * 0.1),
        paint,
      );
    if (mistakes > 3)
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.1),
        Offset(size.width * 0.6, size.height * 0.2),
        paint,
      );
    if (mistakes > 4)
      canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.3),
        size.width * 0.1,
        paint,
      );
    if (mistakes > 5) {
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.4),
        Offset(size.width * 0.6, size.height * 0.6),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.5),
        Offset(size.width * 0.5, size.height * 0.4),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.5),
        Offset(size.width * 0.7, size.height * 0.4),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.6),
        Offset(size.width * 0.5, size.height * 0.7),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.6),
        Offset(size.width * 0.7, size.height * 0.7),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HangmanPainter oldDelegate) =>
      oldDelegate.mistakes != mistakes;
}

class GameResultsPage extends StatelessWidget {
  final Map<String, int> playerScores;
  final bool isHost;
  final String roomId;
  final String? playerName;
  final String? quizText;
  final List<dynamic>? gamesPlayed;

  const GameResultsPage({
    super.key,
    required this.playerScores,
    required this.isHost,
    required this.roomId,
    this.playerName,
    this.quizText,
    this.gamesPlayed,
  });

  Future<void> _updateGlobalScoreAndHistory(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || playerName == null || playerScores.isEmpty)
      return;

    String? quizId;
    DocumentSnapshot<Map<String, dynamic>>? roomDoc;
    try {
      roomDoc =
          await FirebaseFirestore.instance
              .collection('onlineRooms')
              .doc(roomId)
              .get();
      if (roomDoc.exists) {
        quizId = roomDoc.data()?['quizId'];
      }
    } catch (e) {
      print("Impossible de récupérer le quizId : $e");
    }

    double averageDifficulty = 5.0;
    if (gamesPlayed != null && gamesPlayed!.isNotEmpty) {
      double totalDifficulty = 0;
      int gamesWithDifficulty = 0;
      for (var game in gamesPlayed!) {
        if (game.containsKey('difficulty')) {
          totalDifficulty += (game['difficulty'] as num?) ?? 5;
          gamesWithDifficulty++;
        }
      }
      if (gamesWithDifficulty > 0) {
        averageDifficulty = totalDifficulty / gamesWithDifficulty;
      }
    }

    String theme = "Inconnu";
    if (roomDoc != null && roomDoc.exists && roomDoc.data()?['theme'] != null) {
      theme = roomDoc.data()!['theme'];
    } else if (quizText != null) {
      theme = await extractThemeFromQuizText(quizText!) ?? "Inconnu";
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'submitGameResult',
      );
      final result = await callable.call({
        'gameType': 'online',
        'quizId': quizId,
        'gamesPlayed': gamesPlayed,
        'playerScores': playerScores,
        'playerName': playerName,
        'averageDifficulty': averageDifficulty,
        'quizText': quizText,
        'theme': theme,
      });

      final data = result.data as Map<dynamic, dynamic>;
      final pointsAdded = data['pointsAdded'] ?? 0;
      final wasWinnerThisGame = data['wasWinner'] ?? false;

      // --- AJOUT BADGES ---
      final newBadges = data['newBadges'] as List<dynamic>? ?? [];
      if (newBadges.isNotEmpty && context.mounted) {
        AppBadges.showNewBadges(context, newBadges);
      }
      // --------------------

      // Notifications
      if (wasWinnerThisGame && context.mounted) {
        if (pointsAdded == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Vous avez déjà gagné ce quiz. Aucun point ajouté.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Félicitations ! Vous avez gagné $pointsAdded points !',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print("Erreur lors de la soumission du résultat : $e");
    }
  }

  Widget _buildPodium(
    List<MapEntry<String, int>> sortedPlayers,
    BuildContext context,
  ) {
    final top = sortedPlayers.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();
    final podiumOrder = <int>[1, 0, 2].where((i) => i < top.length).toList();
    final heights = <double>[100, 138, 82];
    final colors = <Color>[
      const Color(0xFFC0C0C0),
      AppColors.neonCyan,
      const Color(0xFFCD7F32),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          podiumOrder.map((rankIndex) {
            final player = top[rankIndex];
            return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        player.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 550),
                        curve: Curves.easeOutBack,
                        height: heights[rankIndex],
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: colors[rankIndex].withOpacity(0.2),
                          border: Border.all(
                            color: colors[rankIndex].withOpacity(0.75),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${rankIndex + 1} • ${player.value} pts',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate(delay: Duration(milliseconds: 90 * (rankIndex + 1)))
                .fadeIn(duration: 340.ms)
                .moveY(
                  begin: 34,
                  end: 0,
                  duration: 380.ms,
                  curve: Curves.easeOutCubic,
                );
          }).toList(),
    );
  }

  Widget _buildScoreTrendChart(
    List<MapEntry<String, int>> sortedPlayers,
    BuildContext context,
  ) {
    if (sortedPlayers.length < 2) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedPlayers.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedPlayers[i].value.toDouble()));
    }
    return StyledCard(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (sortedPlayers.length - 1).toDouble(),
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: isDark ? AppColors.neonCyan : AppColors.primaryBlue,
                    barWidth: 3,
                    dotData: FlDotData(show: sortedPlayers.length <= 8),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          (isDark ? AppColors.neonCyan : AppColors.primaryBlue)
                              .withOpacity(0.28),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .moveY(begin: 18, end: 0, duration: 350.ms);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateGlobalScoreAndHistory(context),
    );

    final sortedPlayers =
        playerScores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final int maxScore =
        sortedPlayers.isNotEmpty ? sortedPlayers.first.value : 0;
    if (maxScore > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HapticFeedback.mediumImpact();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement Final'),
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.deepBlue, AppColors.primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.softWhite, AppColors.softWhiteAlt],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              StyledCard(
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.amber,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Podium',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPodium(sortedPlayers, context),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildScoreTrendChart(sortedPlayers, context),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedPlayers.length,
                  itemBuilder: (context, index) {
                    final playerEntry = sortedPlayers[index];
                    final isWinner =
                        playerEntry.value == maxScore && maxScore > 0;
                    final List<Color> podiumColors = [
                      Colors.amber,
                      Colors.grey.shade400,
                      const Color(0xFFCD7F32),
                    ];
                    final List<IconData> podiumIcons = [
                      Icons.emoji_events_rounded,
                      Icons.workspace_premium_rounded,
                      Icons.military_tech_rounded,
                    ];
                    return StyledCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              index < 3
                                  ? Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: podiumColors[index],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      podiumIcons[index],
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  )
                                  : SizedBox(
                                    width: 40,
                                    child: Text(
                                      '#${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  playerEntry.key,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        isWinner
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isWinner
                                          ? Colors.amber.withOpacity(0.2)
                                          : AppColors.primaryBlue.withOpacity(
                                            0.1,
                                          ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${playerEntry.value} pts',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isWinner
                                            ? Colors.black87
                                            : AppColors.deepBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate(delay: Duration(milliseconds: 70 * index))
                        .fadeIn(duration: 280.ms)
                        .moveY(begin: 16, end: 0, duration: 280.ms);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (isHost) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('onlineRooms')
                            .doc(roomId)
                            .delete();
                      } catch (e) {
                        print("Erreur lors de la suppression de la salle: $e");
                      }
                    }
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Retour au menu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ THEME PROVIDER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('theme_mode') ?? 'system';
    _themeMode =
        s == 'dark'
            ? ThemeMode.dark
            : s == 'light'
            ? ThemeMode.light
            : ThemeMode.system;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      mode == ThemeMode.dark
          ? 'dark'
          : mode == ThemeMode.light
          ? 'light'
          : 'system',
    );
  }
}

class LocaleProvider extends ChangeNotifier {
  String _locale = 'fr'; // Par défaut
  String get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('app_lang')) {
      _locale = prefs.getString('app_lang')!;
    } else {
      try {
        final sysLang =
            WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        _locale = ['fr', 'en', 'es'].contains(sysLang) ? sysLang : 'en';
      } catch (e) {
        _locale = 'fr';
      }
      await prefs.setString('app_lang', _locale);
    }
    notifyListeners();
  }

  Future<void> setLocale(String lang) async {
    _locale = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
  }
}

// â”€â”€â”€ THEME HELPERS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
ThemeData _buildLightTheme() {
  const seedColor = AppColors.primaryBlue;
  final cs = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
    scaffoldBackgroundColor: AppColors.softWhite,
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(space: 1, thickness: 0.5),
  );
}

ThemeData _buildDarkTheme() {
  const seedColor = AppColors.neonCyan;
  final cs = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    textTheme: GoogleFonts.outfitTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
    scaffoldBackgroundColor: AppColors.midnight,
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.midnightCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.midnight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      filled: true,
      fillColor: AppColors.midnightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(space: 1, thickness: 0.5),
  );
}

// â”€â”€â”€ MAIN â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialisé avec succès");
  } catch (e) {
    print("Erreur lors de l'initialisation de Firebase: $e");
  }
  runApp(const MiniGamesApp());
}

class MiniGamesApp extends StatelessWidget {
  const MiniGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'QuizBot',
            themeMode: themeProvider.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomePage();
        }
        return const AuthPage();
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLogin = true;
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _authenticate() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
        await userCredential.user?.updateDisplayName(
          _usernameController.text.trim(),
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .set({
              'username': _usernameController.text.trim(),
              'email': _emailController.text.trim(),
              'score': 0,
              'iq': 100,
              'country': 'Monde',
              'isVip': false,
              'createdAt': FieldValue.serverTimestamp(),
              'monthlyGenerationsCount': 0,
              'lastMonthlyReset': FieldValue.serverTimestamp(),
              'dailyGenerationsCount': 0,
              'dailyImageGenerationsCount': 0,
              'lastDailyReset': FieldValue.serverTimestamp(),
            });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors =
        isDark
            ? [const Color(0xFF2D1B69), const Color(0xFF1A1040)]
            : [const Color(0xFF5C35B8), const Color(0xFF3F6FD4)];
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLogin ? 'Connexion' : 'Inscription',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradientColors),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.quiz_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin ? 'Bienvenue !' : 'Créez votre compte',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_isLogin) ...[
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom d\'utilisateur',
                        prefixIcon: Icon(Icons.person),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _authenticate,
                          child: Text(
                            _isLogin ? 'Se connecter' : 'S\'inscrire',
                          ),
                        ),
                      ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'Pas encore de compte ? S\'inscrire'
                          : 'Déjà un compte ? Se connecter',
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const HomePage(isGuest: true),
                          ),
                        );
                      },
                      icon: const Icon(Icons.gamepad),
                      label: const Text('Rejoindre avec un code'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                        side: BorderSide(color: cs.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool isGuest;
  const HomePage({super.key, this.isGuest = false});
  @override
  State<HomePage> createState() => _HomePageState();
}

enum DisplayMode { text, image, textAndImage }

enum MatchDisplayMode { definitionToWord, imageToDefinition }

enum MemoryDisplayMode { wordToDefinition, definitionToImage, imagePair }

class _HomePageState extends State<HomePage> {
  final _textController = TextEditingController();
  final _nameController = TextEditingController();

  // NOUVEAU : Variables pour l'édition IA d'un quiz existant
  Map<String, dynamic>? _quizToComplete;
  bool _modifyExistingGames = false;
  bool _aiDecideGames =
      false; // Permet à l'IA de choisir automatiquement les jeux

  void _startCompletingQuiz(Map<String, dynamic> quiz) {
    setState(() {
      _quizToComplete = quiz;
      _currentTabIndex = 0; // Redirige vers l'onglet "Créer"
      if (_textController.text.trim().isEmpty) {
        _textController.text = quiz['quizText'] ?? '';
      }
      _modifyExistingGames = false; // Par défaut, on ajoute juste à la suite
    });
  }

  void _cancelCompletingQuiz() {
    setState(() {
      _quizToComplete = null;
      _modifyExistingGames = false;
    });
  }

  final Map<String, bool> _selectedGames = {
    'Vrai ou Faux': false,
    'QCM': true,
    'Choisir l\'Intrus': false,
    'Pendu amélioré': false,
    'Relier': false,
    'Memory': false,
    'Compléter la Phrase': false,
    'Mot Mystère': false,
    'Deux Vérités, un Mensonge': false,
    'Chronologie Mélangée': false,
    'Qui suis-je ?': false,
    'Le Mot Anagramme': false,
    'Estimation': false,
    'Quiz par Indices': false,
    'Quiz Éclair': false,
  };
  final Map<String, bool> _hintsEnabled = {
    'Vrai ou Faux': false,
    'QCM': false,
    'Choisir l\'Intrus': false,
    'Pendu amélioré': false,
    'Relier': false,
    'Memory': false,
    'Compléter la Phrase': false,
    'Mot Mystère': false,
    'Deux Vérités, un Mensonge': false,
    'Chronologie Mélangée': false,
    'Qui suis-je ?': false,
    'Le Mot Anagramme': false,
    'Estimation': false,
    'Quiz par Indices': false,
    'Quiz Éclair': false,
  };
  String _status = '';
  List<dynamic> _generatedGames = [];
  String? _lastGeneratedQuizId;
  String _savedName = '';
  int? _memoryPairs;
  bool _aiDecidePairs = true;
  int _score = 0;
  User? _currentUser;
  int _currentTabIndex = 0;
  double _userIQ = 100.0;
  bool _isVip = false;
  int _monthlyGenerationsCount = 0;
  int _dailyGenerationsCount = 0;
  int _dailyImageGenerationsCount = 0;
  int _dailyAiImageCount = 0;
  int _dailyOpenverseCount = 0;
  bool _isGenerating = false;

  DisplayMode _qcmQuestionMode = DisplayMode.text;
  DisplayMode _qcmAnswerMode = DisplayMode.textAndImage;
  MatchDisplayMode _matchDisplayMode = MatchDisplayMode.definitionToWord;
  MemoryDisplayMode _memoryDisplayMode = MemoryDisplayMode.wordToDefinition;

  bool _globalTimerEnabled = false;
  bool _aiCustomTimers = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (widget.isGuest) {
      _currentTabIndex =
          0; // <--- CORRIGÉ : 0 = la page pour rejoindre en ligne
    }
    _loadUserData();
  }

  @override
  void dispose() {
    _textController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (widget.isGuest) {
      if (mounted) {
        setState(() {
          if (_savedName.isEmpty || _savedName == 'Invité') {
            _savedName = 'Invité_${Random().nextInt(1000)}';
          }
          _nameController.text = _savedName;
          _score = 0;
          _userIQ = 0;
          _isVip = false;
          _monthlyGenerationsCount = 0;
          _dailyGenerationsCount = 0;
          _dailyImageGenerationsCount = 0;
          _dailyAiImageCount = 0;
          _dailyOpenverseCount = 0;
        });
      }
      return;
    }

    if (_currentUser != null) {
      String? displayName = _currentUser?.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        if (mounted) {
          setState(() {
            _savedName = displayName;
            _nameController.text = _savedName;
          });
        }
      }

      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_currentUser!.uid)
                .get();

        if (!mounted) return;

        if (userDoc.exists) {
          setState(() {
            final data = userDoc.data() as Map<String, dynamic>;
            _score = data['score'] ?? 0;
            _userIQ = (data['iq'] as num? ?? 100.0).toDouble();
            _isVip = data['isVip'] ?? false;
            _monthlyGenerationsCount = data['monthlyGenerationsCount'] ?? 0;
            _dailyGenerationsCount = data['dailyGenerationsCount'] ?? 0;
            _dailyImageGenerationsCount =
                data['dailyImageGenerationsCount'] ?? 0;
            _dailyAiImageCount = data['dailyAiImageCount'] ?? 0;
            _dailyOpenverseCount = data['dailyOpenverseCount'] ?? 0;

            _checkAndResetGenerationCounts(data);

            if (displayName == null || displayName.isEmpty) {
              _savedName = data['username'] ?? 'Utilisateur';
              _nameController.text = _savedName;
            }
          });
        }
      } catch (e) {
        print('Erreur lors du chargement des données utilisateur: $e');
        if (mounted) {
          setState(() {
            _status = 'Erreur lors du chargement du score.';
          });
        }
      }
    } else {
      print('Erreur: currentUser est null alors que isGuest est false');
    }
  }

  void _checkAndResetGenerationCounts(Map<String, dynamic> userData) async {
    if (_currentUser == null) return;
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid);
    DateTime now = DateTime.now();

    Timestamp? lastMonthlyResetTimestamp = userData['lastMonthlyReset'];
    DateTime lastMonthlyReset =
        lastMonthlyResetTimestamp?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    if (now.month != lastMonthlyReset.month ||
        now.year != lastMonthlyReset.year) {
      await userRef.update({
        'monthlyGenerationsCount': 0,
        'lastMonthlyReset': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _monthlyGenerationsCount = 0);
    }

    Timestamp? lastDailyResetTimestamp = userData['lastDailyReset'];
    DateTime lastDailyReset =
        lastDailyResetTimestamp?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    if (now.day != lastDailyReset.day ||
        now.month != lastDailyReset.month ||
        now.year != lastDailyReset.year) {
      await userRef.update({
        'dailyGenerationsCount': 0,
        'dailyImageGenerationsCount': 0,
        'dailyAiImageCount': 0,
        'dailyOpenverseCount': 0,
        'lastDailyReset': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() {
          _dailyGenerationsCount = 0;
          _dailyImageGenerationsCount = 0;
          _dailyAiImageCount = 0;
          _dailyOpenverseCount = 0;
        });
      }
    }
  }

  Future<void> _updateAndReloadScoreAndHistory(
    double points,
    String quizText,
    List<dynamic> gamesPlayed,
    String? quizId,
  ) async {
    if (widget.isGuest || _currentUser == null) return;

    double totalDifficulty = 0;
    int gamesWithDifficulty = 0;
    for (var game in gamesPlayed) {
      if (game.containsKey('difficulty')) {
        totalDifficulty += (game['difficulty'] as num?) ?? 5;
        gamesWithDifficulty++;
      }
    }
    final averageDifficulty =
        gamesWithDifficulty > 0 ? totalDifficulty / gamesWithDifficulty : 5.0;

    String? theme;
    if (quizId != null) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('quizzes')
                .doc(quizId)
                .get();
        if (doc.exists && doc.data()?['theme'] != null) {
          theme = doc.data()!['theme'];
        }
      } catch (_) {}
    }
    theme ??= await extractThemeFromQuizText(quizText);
    double totalPossibleScore = 0;
    if (gamesPlayed != null && gamesPlayed!.isNotEmpty) {
      for (var game in gamesPlayed!) {
        if (game is Map) {
          final type = game['type']?.toString() ?? '';
          if (type.contains('Relier')) {
            totalPossibleScore +=
                (game['pairs'] as List?)?.length ??
                (game['options'] as List?)?.length ??
                4;
          } else if (type.contains('Quiz par Indices')) {
            totalPossibleScore += (game['clues'] as List?)?.length ?? 3;
          } else if (type.contains('Estimation')) {
            totalPossibleScore += 2;
          } else {
            totalPossibleScore += 1;
          }
        }
      }
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'submitGameResult',
      );
      final result = await callable.call({
        'gameType': 'solo',
        'quizId': quizId,
        'gamesPlayed': gamesPlayed,
        'pointsScored': points,
        'totalPossibleScore': totalPossibleScore,
        'averageDifficulty': averageDifficulty,
        'quizText': quizText,
        'theme': theme,
      });

      final data = result.data as Map<dynamic, dynamic>;
      final pointsAdded = data['pointsAdded'] ?? 0;

      // --- AJOUT BADGES ---
      final newBadges = data['newBadges'] as List<dynamic>? ?? [];
      if (newBadges.isNotEmpty && mounted) {
        AppBadges.showNewBadges(context, newBadges);
      }
      // --------------------

      if (pointsAdded == 0 && points > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vous avez déjà terminé ce quiz. Aucun point n\'a été ajouté.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print("Erreur lors de la mise à jour du QI et du score: $e");
    }

    _loadUserData();
  }

  Future<String?> _saveQuizToFirestore(
    String name,
    String text,
    List<dynamic> games,
  ) async {
    if (widget.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour sauvegarder des quiz !'),
        ),
      );
      return null;
    }
    try {
      final theme = await extractThemeFromQuizText(text);
      final quizRef = FirebaseFirestore.instance.collection('quizzes').doc();
      await quizRef.set({
        'quizId': quizRef.id,
        'userName': name,
        'userId': _currentUser?.uid,
        'text': text,
        'games': games,
        'timestamp': FieldValue.serverTimestamp(),
        'isPublic': false,
        'theme': theme,
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quiz sauvegardé !')));
      if (_currentUser?.uid != null) {
        AppBadges.checkCreationBadges(context, _currentUser!.uid);
      }
      return quizRef.id;
    } catch (e) {
      setState(() {
        _status = 'Erreur lors de l\'enregistrement du quiz : $e';
      });
      print("ERREUR FIRESTORE: $e");
      return null;
    }
  }

  Future<void> _generateGames() async {
    if (_isGenerating) return;

    // Vérification préalable de l'authentification
    if (widget.isGuest || FirebaseAuth.instance.currentUser == null) {
      setState(() {
        _status = 'Veuillez vous connecter pour générer des quiz avec l\'IA.';
      });
      return;
    }

    final text = _textController.text.trim();
    final name = _nameController.text.trim();
    final selectedGamesList =
        _selectedGames.entries.where((entry) => entry.value).toList();
    final selectedGameNames =
        selectedGamesList
            .map((entry) => entry.key.replaceAll(' amélioré', ''))
            .toList();

    if (text.isEmpty) {
      setState(() {
        _status = 'Veuillez entrer du texte.';
      });
      return;
    }
    if (!_aiDecideGames && selectedGameNames.isEmpty) {
      setState(() {
        _status = 'Veuillez sélectionner au moins un jeu ou activer l\'IA.';
      });
      return;
    }

    // Vérification des limites de génération
    final bool canGenerate =
        _isVip
            ? (_dailyGenerationsCount < 30)
            : (_monthlyGenerationsCount < 20);

    bool imageRequested = false;
    if (_aiDecideGames) {
      imageRequested = _isVip;
    } else {
      if (_selectedGames['QCM'] == true) {
        if (_qcmQuestionMode != DisplayMode.text ||
            _qcmAnswerMode != DisplayMode.text)
          imageRequested = true;
      }
      if (_selectedGames['Relier'] == true) {
        if (_matchDisplayMode == MatchDisplayMode.imageToDefinition)
          imageRequested = true;
      }
      if (_selectedGames['Memory'] == true) {
        if (_memoryDisplayMode != MemoryDisplayMode.wordToDefinition)
          imageRequested = true;
      }
    }

    final bool canGenerateImages =
        _isVip ? (_dailyImageGenerationsCount < 20) : false;

    if (!canGenerate) {
      setState(() {
        _status =
            'Vous avez atteint votre limite de générations. Devenez VIP ou attendez le mois prochain.';
      });
      return;
    }

    if (imageRequested && !canGenerateImages) {
      setState(() {
        _status =
            'Vous avez atteint votre limite de générations d\'images (20/jour).';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = '1/5 : Génération de la structure du quiz...';
    });

    final bool includeAll = _aiDecideGames;

    String memoryInstruction = '';
    if (includeAll || (_selectedGames['Memory'] ?? false)) {
      String pairCount =
          _aiDecidePairs ? '4 à 10 paires' : 'exactement $_memoryPairs paires';
      switch (_memoryDisplayMode) {
        case MemoryDisplayMode.wordToDefinition:
          memoryInstruction =
              '- "Memory": {"type": "Memory", "pairs": [{"word": "...", "definition": "..."}, ...], "difficulty": 1-10} (Génère $pairCount. IMPORTANT: chaque "word" doit être unique dans la liste, jamais deux fois le même mot)';
          break;
        case MemoryDisplayMode.definitionToImage:
          memoryInstruction =
              '- "Memory": {"type": "Memory", "displayMode": "definitionToImage", "pairs": [{"definition": "...", "image_description": "...", "image_source": "openverse|ai"}, ...], "difficulty": 1-10} (Génère $pairCount)';
          break;
        case MemoryDisplayMode.imagePair:
          memoryInstruction =
              '- "Memory": {"type": "Memory", "displayMode": "imagePair", "items": [{"image_description": "...", "image_source": "openverse|ai", "text_label": "..."}, ...], "difficulty": 1-10} (Génère $pairCount)';
          break;
      }
    }
    String matchInstruction = '';
    if (includeAll || (_selectedGames['Relier'] ?? false)) {
      switch (_matchDisplayMode) {
        case MatchDisplayMode.definitionToWord:
          matchInstruction =
              '- "Relier": {"type": "Relier", "pairs": [{"word": "...", "definition": "..."}, ...], "difficulty": 1-10}';
          break;
        case MatchDisplayMode.imageToDefinition:
          matchInstruction =
              '- "Relier": {"type": "Relier", "displayMode": "imageToDefinition", "pairs": [{"image_description": "...", "image_source": "openverse|ai", "definition": "..."}, ...], "difficulty": 1-10}';
          break;
      }
    }
    String qcmInstruction = '';
    if (includeAll || (_selectedGames['QCM'] ?? false)) {
      String questionStructure;
      switch (_qcmQuestionMode) {
        case DisplayMode.text:
          questionStructure = '"text": "..."';
          break;
        case DisplayMode.image:
          questionStructure = '"image_description": "...", "image_source": "openverse|ai"';
          break;
        case DisplayMode.textAndImage:
          questionStructure = '"text": "...", "image_description": "...", "image_source": "openverse|ai"';
          break;
      }
      String optionStructure;
      switch (_qcmAnswerMode) {
        case DisplayMode.text:
          optionStructure = '"text": "..."';
          break;
        case DisplayMode.image:
          optionStructure = '"image_description": "...", "image_source": "openverse|ai"';
          break;
        case DisplayMode.textAndImage:
          optionStructure = '"text": "...", "image_description": "...", "image_source": "openverse|ai"';
          break;
      }
      qcmInstruction =
          '- "QCM": {"type": "QCM", "question": {$questionStructure}, "options": [{$optionStructure}, ...], "correct": "texte exact de la bonne option", "hint": "Indice", "difficulty": 1-10} (Génère entre 2 et 5 options selon la pertinence)';
    }

    final String allowedTypesText =
        _aiDecideGames
            ? "Choisis librement et de façon TRÈS VARIÉE parmi TOUS les types de jeux disponibles (QCM, Vrai/Faux, Intrus, Pendu, Relier, Memory, Mot Mystère, Estimation, Quiz par Indices, Chronologie)."
            : selectedGameNames.join(', ');

    try {
      String systemPromptContent = '''
Tu es un concepteur de quiz éducatifs très créatif et imprévisible. 
Ta mission est de transformer le texte fourni en un QUIZ sous forme de tableau JSON valide.

Types de jeux autorisés : $allowedTypesText.

RÈGLE DÉCISIVE POUR LE CHOIX DU FOURNISSEUR D'IMAGE (`image_source`) :
Pour chaque champ `image_description`, tu DOIS impérativement ajouter un champ `image_source` associé dans le même objet JSON.

RÈGLE D'OR (JEUX CENTRÉS SUR L'IMAGE) :
Si l'épreuve repose DIRECTEMENT sur la reconnaissance ou l'association d'images pour jouer (ex: Memory visuel, Relier Image-Définition, QCM avec questions ou options en images), la clarté visuelle doit être ABSOLUE et SANS ERREUR.
- Choisis `"ai"` (IA Générative FLUX) dès qu'il y a le MOINDRE DOUTE qu'une recherche web puisse donner un visuel ambigu, flou, incomplet ou approximatif. L'IA doit créer un visuel sur-mesure, net et 100% évident pour le joueur.
- Choisis `"openverse"` UNIQUEMENT si le sujet est d'une simplicité enfantine et universelle (ex: "pomme", "chat", "Tour Eiffel").

1. `image_source`: "openverse" (POUR CONCEPTS SIMPLES ET TRIVIAUX) :
   - À utiliser quand le sujet est un objet/animal/lieu réel et ultra-simple (1 à 3 mots-clés simples et clairs en anglais, ex: "lion safari", "eiffel tower", "red apple").

2. `image_source`: "ai" (JEUX VISUELS, SUJETS PRÉCIS, RARETÉS ET SCÈNES SUR-MESURE) :
   - À utiliser pour tout jeu visuel (Memory, Relier visuel, QCM visuel) non basique, sujet spécifique, historique, scientifique, rare ou imaginaire (prompt descriptif complet et net en anglais).

IMPORTANT : Base-toi UNIQUEMENT sur le texte et les consignes fournies par l'utilisateur.
''';

      if (_quizToComplete != null && _modifyExistingGames) {
        systemPromptContent += '''
\n\nATTENTION : Tu modifies un quiz existant. Voici les jeux actuels au format JSON :
${jsonEncode(_quizToComplete!['games'])}
Génère la NOUVELLE liste complète de manière créative et retourne UNIQUEMENT le tableau JSON complet.
''';
      } else {
        if (_aiDecideGames) {
          systemPromptContent += '''
RÈGLE DE CRÉATIVITÉ ABSOLUE (L'IA DÉCIDE) :
- Ne sois pas répétitif ! Ne crée pas que des QCM.
- Fais un mélange amusant et dynamique (ex: 1 Pendu, 2 QCM avec 3 choix, 1 Relier, 1 Intrus, 1 Mot Mystère).
- Adapte le nombre total de jeux à la longueur du texte (entre 3 et 10 jeux au total).
- Varie la difficulté.
''';
        } else {
          systemPromptContent += '''
RÈGLE DE QUANTITÉ ET CRÉATIVITÉ :
- Tu DOIS générer au moins 1 jeu pour CHAQUE type demandé.
- Varie le nombre de questions générées en fonction de la taille du texte (pas besoin de forcer 5 questions si le texte est court).
- Pour les QCM, varie le nombre d'options de réponse (entre 2 et 5 options). Ne fais pas toujours 4 options.
- Pour "Relier" et "Memory" : entre 3 et 8 paires selon le contexte.
''';
        }
      }

      systemPromptContent += '''
RÈGLE MEMORY : Chaque paire doit avoir un 'word' UNIQUE. N'utilise jamais deux fois le même mot.
${_aiCustomTimers ? '\nRÈGLE CHRONOMÈTRE (IMPORTANT) : Ajoute systématiquement un champ `"timeLimit"` (entier, en secondes) à chaque jeu généré. Adapte intelligemment ce temps à la complexité et la longueur de la question. (ex: 10 pour un QCM simple, 30 pour un Memory difficile, etc.).' : ''}
Voici les formats JSON attendus :

${(includeAll || (_selectedGames['Vrai ou Faux'] ?? false)) ? '- "Vrai ou Faux": {"type": "Vrai ou Faux", "question": "...", "answer": true/false, "difficulty": 1-10, "hint": "Indice optionnel"}' : ''}
${(includeAll || (_selectedGames['QCM'] ?? false)) ? qcmInstruction : ''}
${(includeAll || (_selectedGames['Choisir l\'Intrus'] ?? false)) ? '- "Choisir l\'Intrus": {"type": "Choisir l\'Intrus", "question": "...", "options": ["...", "...", "..."], "intruder": "...", "difficulty": 1-10, "hint": "Indice optionnel"}' : ''}
${(includeAll || (_selectedGames['Pendu amélioré'] ?? false)) ? '- "Pendu": {"type": "Pendu", "word": "MOT", "hint": "Indice sur le mot", "difficulty": 1-10}' : ''}
${(includeAll || (_selectedGames['Relier'] ?? false)) ? matchInstruction : ''}
${(includeAll || (_selectedGames['Memory'] ?? false)) ? memoryInstruction : ''}
${(includeAll || (_selectedGames['Compléter la Phrase'] ?? false)) ? '- "Compléter la Phrase": {"type": "Compléter la Phrase", "question": "Le chat est un ___.", "correct": "animal", "difficulty": 1-10, "hint": "Indice optionnel"}' : ''}
${(includeAll || (_selectedGames['Deux Vérités, un Mensonge'] ?? false)) ? '- "Deux Vérités, un Mensonge": {"type": "Deux Vérités, un Mensonge", "statements": [...], "lie": "...", "difficulty": 1-10, "hint": "Indice optionnel"}' : ''}
${(includeAll || (_selectedGames['Chronologie Mélangée'] ?? false)) ? '- "Chronologie Mélangée": {"type": "Chronologie Mélangée", "question": "...", "events": [...], "difficulty": 1-10, "hint": "Indice optionnel"}' : ''}
${(includeAll || (_selectedGames['Qui suis-je ?'] ?? false)) ? '- "Qui suis-je ?": {"type": "Qui suis-je ?", "riddle": "...", "answer": "...", "difficulty": 1-10, "hint": "Indice optionnel"}' : ''}
${(includeAll || (_selectedGames['Le Mot Anagramme'] ?? false)) ? '- "Le Mot Anagramme": {"type": "Le Mot Anagramme", "anagram": "...", "hint": "...", "solution": "...", "difficulty": 1-10}' : ''}
${(includeAll || (_selectedGames['Mot Mystère'] ?? false)) ? '- "Mot Mystère": {"type": "Mot Mystère", "word": "MOTSECRET", "difficulty": 1-10, "hint": "Indice optionnel"}' : ''}
${(includeAll || (_selectedGames['Estimation'] ?? false)) ? '- "Estimation": {"type": "Estimation", "question": "...", "answer": 1969, "unit": "année", "hint": "Indice optionnel", "difficulty": 1-10}' : ''}
${(includeAll || (_selectedGames['Quiz par Indices'] ?? false)) ? '- "Quiz par Indices": {"type": "Quiz par Indices", "clues": ["Indice 1", "Indice 2", "Indice 3"], "answer": "la réponse exacte", "difficulty": 1-10}' : ''}
${(includeAll || (_selectedGames['Quiz Éclair'] ?? false)) ? '- "Quiz Éclair": {"type": "Quiz Éclair", "question": "...", "options": ["Vrai", "Faux", "Peut-être"], "correct": "Vrai", "difficulty": 1-10}' : ''}

Assure-toi que le JSON est strictly valide. Ne renvoie AUCUN autre texte.
''';

      print(
        '''\n[API_PROMPT] --- Prompt système envoyé à l'IA --- \n$systemPromptContent\n---------------------------------------------\n''',
      );

      bool imageRequested = false;
      if (_aiDecideGames) {
        imageRequested = _isVip;
      } else {
        if (_selectedGames['QCM'] == true) {
          if (_qcmQuestionMode != DisplayMode.text ||
              _qcmAnswerMode != DisplayMode.text) {
            imageRequested = true;
          }
        }
        if (_selectedGames['Relier'] == true) {
          if (_matchDisplayMode == MatchDisplayMode.imageToDefinition) {
            imageRequested = true;
          }
        }
        if (_selectedGames['Memory'] == true) {
          if (_memoryDisplayMode != MemoryDisplayMode.wordToDefinition) {
            imageRequested = true;
          }
        }
      }

      final data = await callSecureAI(
        model: 'mistralai/Mistral-Nemo-Instruct-2407',
        temperature: 0.8,
        systemMessage: systemPromptContent,
        prompt:
            'Voici le texte à transformer en jeux : "$text"\n\nRappel: retourne UNIQUEMENT le tableau JSON, sois créatif sur le format des questions.',
        imageRequested: imageRequested,
      );

      if (data.isNotEmpty &&
          data['choices'] != null &&
          (data['choices'] as List).isNotEmpty) {
        print("[API_RESPONSE] Succès !");
        final rawContent =
            data['choices'][0]['message']['content']?.toString() ?? '';

        if (rawContent.isEmpty) {
          throw Exception("L'IA a renvoyé une réponse vide.");
        }
        print("[AI RAW RESPONSE] Contenu brut reçu de l'IA:\n$rawContent");

        final cleanedContent = rawContent.trim().replaceAll(
          RegExp(r'```json\s*|```'),
          '',
        );

        String jsonSubstring = cleanedContent;
        int firstBracket = cleanedContent.indexOf('[');
        int lastBracket = cleanedContent.lastIndexOf(']');
        if (firstBracket != -1 && lastBracket > firstBracket) {
          jsonSubstring = cleanedContent.substring(
            firstBracket,
            lastBracket + 1,
          );
        } else {
          int firstBrace = cleanedContent.indexOf('{');
          int lastBrace = cleanedContent.lastIndexOf('}');
          if (firstBrace != -1 && lastBrace > firstBrace) {
            jsonSubstring = cleanedContent.substring(firstBrace, lastBrace + 1);
          }
        }

        dynamic decodedJson;
        try {
          decodedJson = jsonDecode(jsonSubstring);
        } catch (e) {
          throw Exception(
            'L\'IA a généré un JSON invalide (erreur de syntaxe). Veuillez réessayer.',
          );
        }
        print("[JSON_PARSE] La réponse JSON a été parsée avec succès.");

        List<dynamic> gamesList;
        if (decodedJson is List) {
          gamesList = decodedJson;
        } else {
          gamesList = [decodedJson];
        }

        List<dynamic> validatedGames = _validateGeneratedGames(gamesList);
        if (validatedGames.isEmpty) {
          setState(() {
            _status =
                'Erreur: L\'IA n\'a généré aucun jeu valide. Veuillez réessayer ou reformuler votre texte.';
          });
          return;
        }
        if (_isVip) {
          setState(() {
            _status = '2/5 : Structure générée. Recherche des images...';
          });
          validatedGames = await _processImagesForGames(validatedGames);
        }

        // NOUVEAU : Si on complète SANS le switch "modifier", on ajoute les nouveaux jeux à la fin
        if (_quizToComplete != null && !_modifyExistingGames) {
          final existingGames =
              _quizToComplete!['games'] as List<dynamic>? ?? [];
          validatedGames = [...existingGames, ...validatedGames];
        }
        _generatedGames =
            validatedGames.map((game) {
              if (game['type'] == 'Pendu') game['type'] = 'Pendu amélioré';
              // Appliquer la préférence d'indice de l'utilisateur pour chaque type de jeu
              final gameType = game['type']?.toString() ?? '';
              game['hintEnabled'] = _hintsEnabled[gameType] ?? false;

              // Appliquer les chronomètres
              if (_globalTimerEnabled) {
                if (!_aiCustomTimers || game['timeLimit'] == null) {
                  final defaults = {
                    'QCM': 10,
                    'Vrai ou Faux': 8,
                    'Choisir l\'Intrus': 10,
                    'Pendu amélioré': 30,
                    'Relier': 45,
                    'Memory': 30,
                    'Compléter la Phrase': 15,
                    'Mot Mystère': 20,
                    'Deux Vérités, un Mensonge': 15,
                    'Chronologie Mélangée': 40,
                    'Qui suis-je ?': 20,
                    'Le Mot Anagramme': 15,
                    'Estimation': 15,
                    'Quiz par Indices': 30,
                    'Quiz Éclair': 8,
                  };
                  game['timeLimit'] = defaults[gameType] ?? 20;
                }
              }

              return game;
            }).toList();
        _status = 'Jeux générés avec succès !';
        print(
          "[SUCCESS] Jeux finaux validés et prêts à jouer: $_generatedGames",
        );
        String? finalQuizId;

        if (_quizToComplete != null) {
          // Si on modifie un quiz existant, on met à jour dans la base
          finalQuizId = _quizToComplete!['quizId'] ?? _quizToComplete!['id'];
          await FirebaseFirestore.instance
              .collection('quizzes')
              .doc(finalQuizId)
              .update({
                'games': _generatedGames,
                'timestamp': FieldValue.serverTimestamp(),
              });
          _cancelCompletingQuiz(); // On vide l'état après succès
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quiz complété/modifié avec succès !'),
              ),
            );
          }
        } else {
          // Sauvegarde classique d'un nouveau quiz
          finalQuizId = await _saveQuizToFirestore(
            name.isNotEmpty
                ? name
                : (widget.isGuest
                    ? "Invité"
                    : (_currentUser?.displayName ?? "Anonyme")),
            text,
            _generatedGames,
          );
        }

        if (finalQuizId != null) {
          // Increment is now handled in the Cloud Function
          await _loadUserData(); // Recharger les données pour mettre à jour l'interface
        } else {
          throw Exception(
            'Erreur lors de la sauvegarde du quiz dans Firestore',
          );
        }

        setState(() {
          _lastGeneratedQuizId = finalQuizId;
        });
      } else {
        throw Exception('Erreur API: Format de réponse invalide ou vide');
      }
    } catch (e) {
      setState(() {
        _status = 'Erreur lors de la génération : $e';
      });
      print("[ERREUR] Une erreur est survenue pendant la génération: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  List<dynamic> _validateGeneratedGames(List<dynamic> games) {
    print("[VALIDATION] --- Début de la validation des jeux ---");
    List<dynamic> validatedGames = [];

    for (var game in games) {
      if (game is! Map<String, dynamic>) {
        print(
          "[VALIDATION] -> INVALIDE: Un élément n'est pas un objet JSON valide. Ignoré.",
        );
        continue;
      }

      final type = game['type'] as String?;
      print("[VALIDATION] Validation du jeu de type: '$type'");
      bool isGameValid = true;

      switch (type) {
        case 'Vrai ou Faux':
          if (game['question'] == null ||
              game['answer'] == null ||
              game['answer'] is! bool) {
            print(
              "[VALIDATION] -> INVALIDE (Vrai ou Faux): question ou réponse manquante ou type invalide.",
            );
            isGameValid = false;
          }
          break;
        case 'QCM':
          final options = game['options'];
          final correct = game['correct'];
          if (game['question'] == null ||
              options == null ||
              (options is List && options.length < 2) ||
              correct == null) {
            print(
              "[VALIDATION] -> INVALIDE (QCM): question, options ou correct manquant(s).",
            );
            isGameValid = false;
          }
          break;
        case 'Choisir l\'Intrus':
          final options = game['options'];
          if (game['question'] == null ||
              options == null ||
              (options is List && options.length < 3) ||
              game['intruder'] == null) {
            print("[VALIDATION] -> INVALIDE (Intrus): champs manquants.");
            isGameValid = false;
          }
          break;
        case 'Pendu':
          final word = game['word'] as String?;
          if (word == null || word.isEmpty) {
            print("[VALIDATION] -> INVALIDE (Pendu): mot manquant.");
            isGameValid = false;
          }
          break;
        case 'Relier':
          final pairs = game['pairs'];
          if (pairs == null || (pairs is List && pairs.length < 2)) {
            print(
              "[VALIDATION] -> INVALIDE (Relier): paires manquantes ou insuffisantes.",
            );
            isGameValid = false;
          }
          break;
        case 'Memory':
          final pairs = game['pairs'] ?? game['items'];
          if (pairs == null || (pairs is List && pairs.length < 2)) {
            print("[VALIDATION] -> INVALIDE (Memory): paires/items manquants.");
            isGameValid = false;
          }
          break;
        case 'Compléter la Phrase':
          if (game['question'] == null || game['correct'] == null) {
            print(
              "[VALIDATION] -> INVALIDE (Compléter la Phrase): champs manquants.",
            );
            isGameValid = false;
          }
          break;
        case 'Deux Vérités, un Mensonge':
          final statements = game['statements'];
          if (statements == null ||
              (statements is List && statements.length < 3) ||
              game['lie'] == null) {
            print("[VALIDATION] -> INVALIDE (Deux Vérités): champs manquants.");
            isGameValid = false;
          }
          break;
        case 'Chronologie Mélangée':
          final events = game['events'];
          if (events == null || (events is List && events.length < 3)) {
            print(
              "[VALIDATION] -> INVALIDE (Chronologie): événements insuffisants.",
            );
            isGameValid = false;
          }
          break;
        case 'Qui suis-je ?':
          if (game['riddle'] == null || game['answer'] == null) {
            print(
              "[VALIDATION] -> INVALIDE (Qui suis-je ?): champs manquants.",
            );
            isGameValid = false;
          }
          break;
        case 'Le Mot Anagramme':
          if (game['anagram'] == null || game['solution'] == null) {
            print("[VALIDATION] -> INVALIDE (Anagramme): champs manquants.");
            isGameValid = false;
          }
          break;
        case 'Mot Mystère':
          final word = game['word'] as String?;
          if (word == null || word.isEmpty || word.length < 4) {
            print(
              "[VALIDATION] -> INVALIDE (Mot Mystère): Le mot est manquant ou trop court.",
            );
            isGameValid = false;
          }
          break;
        case 'Estimation':
          final answer = game['answer'];
          if (game['question'] == null || answer == null || (answer is! num)) {
            print(
              "[VALIDATION] -> INVALIDE (Estimation): question ou answer (nombre) manquant.",
            );
            isGameValid = false;
          }
          break;
        case 'Quiz par Indices':
          final clues = game['clues'];
          if (clues == null ||
              (clues is List && clues.length < 2) ||
              game['answer'] == null) {
            print(
              "[VALIDATION] -> INVALIDE (Quiz par Indices): clues ou answer manquants.",
            );
            isGameValid = false;
          }
          break;
        case 'Quiz Éclair':
          final options = game['options'] ?? game['choices'];
          final correct = game['correct'] ?? game['answer'];
          if (game['question'] == null ||
              options == null ||
              (options is List && options.length < 2) ||
              correct == null) {
            print("[VALIDATION] -> INVALIDE (Quiz Éclair): champs manquants.");
            isGameValid = false;
          }
          break;
        default:
          print("[VALIDATION] -> INVALIDE: Type '$type' non reconnu.");
          isGameValid = false;
      }

      if (isGameValid) {
        // Assurer qu'un champ difficulty existe (défaut 5)
        if (game['difficulty'] == null) game['difficulty'] = 5;
        validatedGames.add(game);
        print("[VALIDATION] --- Jeu '$type' jugé VALIDE. ---");
      } else {
        print("[VALIDATION] --- Jeu '$type' jugé INVALIDE et ignoré. ---");
      }
    }
    return validatedGames;
  }

  Future<List<dynamic>> _processImagesForGames(List<dynamic> games) async {
    List<Map<String, dynamic>> itemsToProcess = [];

    for (var game in games) {
      String gameType = game['type'] ?? '';

      if (gameType == 'QCM') {
        if (game['question'] is Map &&
            game['question']['image_description'] != null) {
          itemsToProcess.add(game['question'] as Map<String, dynamic>);
        }
        if (game['options'] is List) {
          for (var option in game['options']) {
            if (option is Map && option['image_description'] != null) {
              itemsToProcess.add(option as Map<String, dynamic>);
            }
          }
        }
      } else if (gameType == 'Relier' || gameType == 'Memory') {
        List<dynamic>? itemsList = game['pairs'] ?? game['items'];
        if (itemsList is List) {
          for (var item in itemsList) {
            if (item is Map && item['image_description'] != null) {
              itemsToProcess.add(item as Map<String, dynamic>);
            }
          }
        }
      }
    }

    if (itemsToProcess.isNotEmpty) {
      print('>>> Total d\'images à traiter trouvé : ${itemsToProcess.length}');

      // Traiter par lots de 3 pour éviter le timeout
      const int chunkSize = 3;
      for (int i = 0; i < itemsToProcess.length; i += chunkSize) {
        if (!mounted) return games;

        final endIndex = min(i + chunkSize, itemsToProcess.length);
        setState(() {
          _status =
              'Recherche d\'images... ($endIndex/${itemsToProcess.length})';
        });

        final chunk = itemsToProcess.sublist(i, endIndex);

        await Future.wait(
          chunk.map(
            (item) => _fetchAndAssignImageUrl(item, 'image_description'),
          ),
        );

        if (endIndex < itemsToProcess.length) {
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }
    } else {
      print(
        '>>> Aucune "image_description" trouvée. Traitement des images sauté.',
      );
    }
    return games;
  }

  Future<void> _fetchAndAssignImageUrl(
    Map<dynamic, dynamic> item,
    String key,
  ) async {
    String description = item[key]?.toString().trim() ?? '';
    String source = item['image_source']?.toString().toLowerCase() ?? 'openverse';
    bool fromTextFallback = false;
    
    // Si l'IA n'a pas fourni de description d'image, on se rabat sur le texte
    if (description.isEmpty && item['text'] != null) {
      description = item['text'].toString().trim();
      fromTextFallback = true;
    }
    if (description.isEmpty) return;

    // --- NETTOYAGE POUR LA RECHERCHE OPENVERSE ---
    String searchQuery = description;
    
    if ((source == 'openverse' || source == 'pixabay') && (fromTextFallback || description.split(RegExp(r'\s+')).length > 3)) {
      String cleanQuery = description.replaceAll(RegExp(r'[^\w\sÀ-ÿ]'), ' ');
      List<String> stopWords = [
        'le', 'la', 'les', 'l', 'd', 'de', 'du', 'des', 'un', 'une', 'qui', 'que', 'est', 'sont', 
        'dans', 'avec', 'et', 'ou', 'ce', 'cette', 'ces', 'mon', 'the', 'is', 'are', 'in', 'on', 'of', 'and'
      ];
      
      List<String> words = cleanQuery
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2 && !stopWords.contains(w.toLowerCase()))
          .toList();
      
      if (words.length > 3) {
        words.sort((a, b) => b.length.compareTo(a.length));
        words = words.take(3).toList();
      }
      searchQuery = words.join(' ');
    }

    final bool requiresAI = (source == 'ai');

    try {
      if (_isVip) {
        if (requiresAI) {
          if (mounted) setState(() => _status = 'Génération IA pour "$description"...');
          final callableAI = FirebaseFunctions.instance.httpsCallable('generateAIImage');
          final resultAI = await callableAI.call({'prompt': description});
          if (resultAI.data != null && resultAI.data['url'] != null) {
            item['image_url'] = resultAI.data['url'];
            return;
          }
        }

        // CONCEPT SIMPLE -> Openverse
        if (mounted) setState(() => _status = 'Recherche Openverse pour "$searchQuery"...');
        final callableOpenverse = FirebaseFunctions.instance.httpsCallable('fetchOpenverseImage');
        final resultOpenverse = await callableOpenverse.call({'query': searchQuery});

        if (resultOpenverse.data != null &&
            resultOpenverse.data['results'] != null &&
            (resultOpenverse.data['results'] as List).isNotEmpty) {
          item['image_url'] = resultOpenverse.data['results'][0]['url'];
        } else if (!requiresAI) {
          // Fallback IA si Openverse ne trouve rien
          if (mounted) setState(() => _status = 'Aucun résultat. Bascule sur l\'IA pour "$description"...');
          final callableAI = FirebaseFunctions.instance.httpsCallable('generateAIImage');
          final resultAI = await callableAI.call({'prompt': description});
          if (resultAI.data != null && resultAI.data['url'] != null) {
            item['image_url'] = resultAI.data['url'];
          }
        }
      } else {
        // NON-VIP : Banque d'images Openverse uniquement
        if (mounted) setState(() => _status = 'Recherche Openverse pour "$searchQuery"...');
        final callable = FirebaseFunctions.instance.httpsCallable('fetchOpenverseImage');
        final result = await callable.call({'query': searchQuery});
        if (result.data != null &&
            result.data['results'] != null &&
            (result.data['results'] as List).isNotEmpty) {
          item['image_url'] = result.data['results'][0]['url'];
        }
      }
    } catch (e) {
      print('Erreur lors du traitement d\'image : $e');
    }
  }

  void _playQuiz(List<dynamic> games, String quizText, String? quizId) {
    if (games.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez ajouter des questions avant de jouer.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GamePage(
              games: games,
              onScoreUpdate: (double points) {
                _updateAndReloadScoreAndHistory(
                  points,
                  quizText,
                  games,
                  quizId,
                );
              },
              isGuest: widget.isGuest,
              qcmQuestionMode: _qcmQuestionMode,
              qcmAnswerMode: _qcmAnswerMode,
            ),
      ),
    ).then((_) {
      _loadUserData();
    });
  }

  void _showAllQuizzes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AllQuizzesPage(
              onPlay: (games, text, quizId) => _playQuiz(games, text, quizId),
              isGuest: widget.isGuest,
              onCompleteAI: _startCompletingQuiz,
            ),
      ),
    );
  }

  Future<String?> _showNameDialog() async {
    final TextEditingController dialogNameController = TextEditingController(
      text: _nameController.text,
    );
    String? errorMessage;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Entrez votre prénom'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: dialogNameController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      border: const OutlineInputBorder(),
                      errorText: errorMessage,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ce prénom sera visible par les autres joueurs.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = dialogNameController.text.trim();
                    if (name.isEmpty) {
                      setState(() {
                        errorMessage = 'Le prénom est obligatoire.';
                      });
                    } else {
                      Navigator.of(context).pop(name);
                    }
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOnlineOptions({Map<String, dynamic>? initialQuiz}) {
    if (initialQuiz != null) {
      final games = initialQuiz['games'] as List<dynamic>? ?? [];
      if (games.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez ajouter des questions avant de jouer.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OnlineOptionsPage(
              initialQuiz: initialQuiz,
              playerName: _savedName,
              onCreateRoom: (roomSettings, selectedQuiz, saveToQuiz) {
                _createOnlineRoom(
                  _savedName,
                  roomSettings,
                  selectedQuiz,
                  saveToQuiz,
                );
              },
              onJoinRoom: (code) {
                _joinOnlineRoom(_savedName, code);
              },
              // ON MET À JOUR LE CALLBACK DE RECHERCHE
              onFindPublicGame: (String? theme) async {
                return await _findPublicGame(_savedName, theme: theme);
              },
              isGuest: widget.isGuest,
              qcmQuestionMode: _qcmQuestionMode,
              qcmAnswerMode: _qcmAnswerMode,
            ),
      ),
    ).then((_) => _loadUserData());
  }

  void _createOnlineRoom(
    String playerName,
    OnlineRoomSettings settings,
    Map<String, dynamic>? selectedQuiz,
    bool saveToQuiz,
  ) async {
    if (settings.isPublic && selectedQuiz != null) {
      try {
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('onlineRooms')
                .where('settings.isPublic', isEqualTo: true)
                .where('started', isEqualTo: false)
                .where('quizId', isEqualTo: selectedQuiz['quizId'])
                .get();

        final similarRooms =
            querySnapshot.docs.where((doc) {
              final data = doc.data();
              final players = data['players'] as Map<String, dynamic>? ?? {};
              final roomSettings = OnlineRoomSettings.fromMap(data['settings']);
              return players.length < roomSettings.maxPlayers;
            }).toList();

        if (similarRooms.isNotEmpty && mounted) {
          final roomToJoin = similarRooms.first;
          final join = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Partie similaire trouvée !'),
                  content: const Text(
                    'Une partie publique avec le même quiz est déjà disponible. Voulez-vous la rejoindre ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Non, créer la mienne'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Oui, rejoindre'),
                    ),
                  ],
                ),
          );

          if (join == true) {
            _joinOnlineRoom(playerName, roomToJoin.data()['inviteCode']);
            return;
          }
        }
      } catch (e) {
        print("Erreur lors de la vérification de salles similaires : $e");
      }
    }

    _executeCreateOnlineRoom(playerName, settings, selectedQuiz, saveToQuiz);
  }

  void _executeCreateOnlineRoom(
    String playerName,
    OnlineRoomSettings settings,
    Map<String, dynamic>? selectedQuiz,
    bool saveToQuiz,
  ) async {
    final gamesList =
        selectedQuiz != null ? selectedQuiz['games'] as List<dynamic>? : null;
    final quizText =
        selectedQuiz != null ? selectedQuiz['text'] as String? : null;
    final theme =
        selectedQuiz != null ? selectedQuiz['theme'] as String? : null;

    if (selectedQuiz == null ||
        gamesList == null ||
        gamesList.isEmpty ||
        quizText == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un quiz valide !')),
      );
      return;
    }

    // On vérifie une première fois si le widget est monté
    if (mounted) {
      setState(() {
        _status = 'Création de la salle...';
      });
    }

    try {
      final code = _generateInviteCode();
      final games = List<dynamic>.from(gamesList);

      DocumentReference roomRef = await FirebaseFirestore.instance
          .collection('onlineRooms')
          .add({
            'hostName': playerName,
            'inviteCode': code,
            'quizId': selectedQuiz['quizId'],
            'quizText': quizText,
            'theme': theme,
            'settings': settings.toMap(),
            'games': games,
            'players': {
              playerName: {
                'isHost': true,
                'score': 0,
                'uid': _currentUser?.uid,
              },
            },
            'gameState': {
              'currentGameIndex': 0,
              'playersAnswered': [],
              'memoryState': null,
              'hangmanState': null,
              'motMystereState': null,
            },
            'active': true,
            'started': false,
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (saveToQuiz && selectedQuiz['quizId'] != null) {
        await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(selectedQuiz['quizId'])
            .update({'games': games});
      }

      // LA CORRECTION PRINCIPALE EST ICI : on vérifie à nouveau après le "await"
      if (mounted) {
        setState(() {
          _status = '';
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => WaitingRoomPage(
                  roomId: roomRef.id,
                  inviteCode: code,
                  isHost: true,
                  playerName: playerName,
                  maxPlayers: settings.maxPlayers,
                  isGuest: widget.isGuest,
                ),
          ),
        );
      }
    } catch (e) {
      // On vérifie aussi dans le bloc d'erreur
      if (mounted) {
        setState(() {
          _status = 'Erreur lors de la création de la salle : $e';
        });
      }
    }
  }

  Future<String?> _promptForPseudo(BuildContext context) async {
    String? pseudo;
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String tempPseudo = '';
        return AlertDialog(
          title: const Text('Entrez votre pseudo'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Pseudo',
              hintText: 'Votre nom en jeu',
            ),
            onChanged: (value) {
              tempPseudo = value;
            },
            onSubmitted: (value) {
              Navigator.of(context).pop(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(tempPseudo);
              },
              child: const Text('Rejoindre'),
            ),
          ],
        );
      },
    ).then((value) => pseudo = value);
    return pseudo;
  }

  void _joinOnlineRoom(String playerName, String code) async {
    setState(() {
      _status = 'Recherche de la salle...';
    });
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('onlineRooms')
              .where('inviteCode', isEqualTo: code)
              .where('active', isEqualTo: true)
              .limit(1)
              .get();
      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _status = 'Aucune salle active trouvée avec ce code.';
        });
        return;
      }
      final roomDoc = querySnapshot.docs.first;
      final roomData = roomDoc.data();
      if (roomData['started'] == true) {
        setState(() {
          _status = 'Impossible de rejoindre une partie déjà commencée.';
        });
        return;
      }
      final players = Map<String, dynamic>.from(roomData['players'] ?? {});
      final settings = OnlineRoomSettings.fromMap(roomData['settings']);
      if (players.length >= settings.maxPlayers) {
        setState(() {
          _status = 'La salle est pleine.';
        });
        return;
      }
      String finalPlayerName = playerName;

      if (widget.isGuest) {
        final pseudo = await _promptForPseudo(context);
        if (pseudo == null || pseudo.trim().isEmpty) {
          setState(() {
            _status = 'Un pseudo est requis pour rejoindre la partie.';
          });
          return;
        }
        finalPlayerName = pseudo.trim();
      }

      if (players.containsKey(finalPlayerName)) {
        setState(() {
          _status =
              'Vous êtes déjà dans cette salle ou un joueur porte ce nom.';
        });
        return;
      }

      await roomDoc.reference.update({
        'players.$finalPlayerName': {
          'isHost': false,
          'score': 0,
          'uid': _currentUser?.uid,
        },
      });

      setState(() {
        _status = '';
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => WaitingRoomPage(
                roomId: roomDoc.id,
                inviteCode: code,
                isHost: false,
                playerName: finalPlayerName,
                maxPlayers: settings.maxPlayers,
                isGuest: widget.isGuest,
              ),
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Erreur lors de la recherche de la salle : $e';
      });
    }
  }

  // --- NOUVEAU : Renvoie un Future<bool> pour gérer l'animation du radar ---
  Future<bool> _findPublicGame(String playerName, {String? theme}) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('onlineRooms')
          .where('settings.isPublic', isEqualTo: true)
          .where('started', isEqualTo: false);

      if (theme != null && theme != 'any') {
        query = query.where('theme', isEqualTo: theme);
      }
      query = query.orderBy('timestamp', descending: true);

      final roomSnapshot = await query.get();

      final availableRooms =
          roomSnapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final players = data['players'] as Map<String, dynamic>? ?? {};
            final settings = OnlineRoomSettings.fromMap(data['settings']);
            return players.length < settings.maxPlayers &&
                !players.containsKey(playerName);
          }).toList();

      if (availableRooms.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aucune partie publique trouvée. Essayez d\'en créer une !',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false; // Pas trouvé
      }

      availableRooms.sort((a, b) {
        final pA = (a.data() as Map<String, dynamic>)['players'] as Map? ?? {};
        final pB = (b.data() as Map<String, dynamic>)['players'] as Map? ?? {};
        return pB.length.compareTo(pA.length);
      });

      final roomToJoin = availableRooms.first;
      _joinOnlineRoom(
        playerName,
        (roomToJoin.data() as Map<String, dynamic>)['inviteCode'],
      );
      return true; // Trouvé !
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de recherche : $e')));
      }
      return false; // Erreur
    }
  }

  String _generateInviteCode() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10)).join();
  }

  void _showVipAdvantagesPopup() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Devenez VIP !'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Débloquez des fonctionnalités exclusives :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.star, color: Colors.amber),
                    title: Text(
                      'Prompt de génération illimité (au lieu de 2000 caractères)',
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.casino, color: Colors.green),
                    title: Text(
                      'Combinez un nombre illimité de jeux par quiz (au lieu de 3)',
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.image, color: Colors.blue),
                    title: Text('Génération de quiz avec images activée'),
                  ),
                  ListTile(
                    leading: Icon(Icons.all_inclusive, color: Colors.purple),
                    title: Text(
                      'Génération de jeux illimitée (30/jour max, dont 20 avec images)',
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Abonnez-vous maintenant pour une expérience premium !',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
              ElevatedButton(
                onPressed: () {
                  _activateVipSubscription();
                  Navigator.of(context).pop();
                },
                child: const Text('S\'abonner (Simulé)'),
              ),
            ],
          ),
    );
  }

  Future<void> _activateVipSubscription() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour devenir VIP !')),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'isVip': true});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Félicitations ! Vous êtes maintenant un membre VIP !'),
        ),
      );
      _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'activation VIP : $e')),
      );
    }
  }

  Future<void> _cancelVipSubscription() async {
    if (_currentUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmation'),
            content: const Text(
              'Êtes-vous sûr de vouloir vous désabonner ? Vous perdrez immédiatement l\'accès à tous les avantages VIP.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Se désabonner'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update({'isVip': false});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez bien été désabonné.'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadUserData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du désabonnement : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int nonVipGenerationsRemaining = 20 - _monthlyGenerationsCount;
    final int vipGenerationsRemaining = 30 - _dailyGenerationsCount;
    final int vipImageGenerationsRemaining = 20 - _dailyImageGenerationsCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors =
        isDark
            ? [AppColors.midnight, AppColors.midnightSurface]
            : [const Color(0xFFEFF3FF), const Color(0xFFDCE7FF)];

    final pages =
        widget.isGuest
            ? [
              OnlineOptionsPage(
                playerName: _savedName,
                onCreateRoom: (s, q, save) {},
                onJoinRoom: (code) {
                  _joinOnlineRoom(_savedName, code);
                },
                onFindPublicGame: (String? theme) async {
                  return await _findPublicGame(_savedName, theme: theme);
                },
                isGuest: true,
                qcmQuestionMode: DisplayMode.textAndImage,
                qcmAnswerMode: DisplayMode.textAndImage,
              ),
            ]
            : [
              _buildCreateQuizTab(
                nonVipGenerationsRemaining,
                vipGenerationsRemaining,
                vipImageGenerationsRemaining,
              ),
              // --- NOUVEAU CONTENEUR UNIFIÉ ---
              QuizLibraryContainerPage(
                isGuest: widget.isGuest,
                onPlay: (games, text, quizId) => _playQuiz(games, text, quizId),
                onPlayOnline: (quiz) => _showOnlineOptions(initialQuiz: quiz),
                onCompleteAI: _startCompletingQuiz, // AJOUTEZ CETTE LIGNE
              ),
              LeaderboardPage(),
              MyIQPage(userId: _currentUser!.uid),
              FriendsPage(
                userId: _currentUser!.uid,
                playerName: _savedName,
                onInviteToGame:
                    (settings, quiz) =>
                        _createOnlineRoom(_savedName, settings, quiz, false),
              ),
            ];

    final destinations =
        widget.isGuest
            ? const [
              NavigationDestination(
                icon: Icon(Icons.login),
                label: 'Rejoindre',
              ),
            ]
            : const [
              NavigationDestination(
                icon: Icon(Icons.create_outlined),
                selectedIcon: Icon(Icons.create),
                label: 'Créer',
              ),
              NavigationDestination(
                icon: Icon(Icons.extension_outlined),
                selectedIcon: Icon(Icons.extension),
                label: 'Mes Jeux',
              ),
              NavigationDestination(
                icon: Icon(Icons.leaderboard_outlined),
                selectedIcon: Icon(Icons.leaderboard),
                label: 'Classement',
              ),
              NavigationDestination(
                icon: Icon(Icons.psychology_alt_outlined),
                selectedIcon: Icon(Icons.psychology_alt),
                label: 'Mon QI',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Amis',
              ),
            ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isGuest ? 'QuizBot (Invité)' : 'QuizBot',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: isDark ? Colors.white : AppColors.deepBlue,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (!widget.isGuest)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withOpacity(0.14)
                            : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$_score',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.deepBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: isDark ? Colors.white : AppColors.deepBlue,
                  ),
                  tooltip: 'Paramètres',
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      ),
                ),
              ],
            ),
          if (widget.isGuest) ...[
            TextButton.icon(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  FirebaseAuth.instance.signOut();
                }
              },
              icon: Icon(
                Icons.login,
                color: isDark ? Colors.white : AppColors.deepBlue,
              ),
              label: Text(
                'Se connecter',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.deepBlue,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: isDark ? Colors.white : AppColors.deepBlue,
              ),
              tooltip: 'Paramètres',
              onPressed:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
            ),
          ],
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: KeyedSubtree(
            key: ValueKey(_currentTabIndex),
            child: pages[_currentTabIndex],
          ),
        ),
      ),
      bottomNavigationBar:
          widget.isGuest
              ? null
              : NavigationBar(
                height: 74,
                selectedIndex: _currentTabIndex,
                onDestinationSelected:
                    (index) => setState(() => _currentTabIndex = index),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                backgroundColor:
                    isDark ? AppColors.midnightSurface : Colors.white,
                indicatorColor: (isDark
                        ? AppColors.neonCyan
                        : AppColors.primaryBlue)
                    .withOpacity(0.18),
                destinations: destinations,
              ),
    );
  }

  Widget _buildCreateQuizTab(
    int nonVipGenerationsRemaining,
    int vipGenerationsRemaining,
    int vipImageGenerationsRemaining,
  ) {
    String displayModeToString(DisplayMode mode) {
      switch (mode) {
        case DisplayMode.text:
          return 'Texte uniquement';
        case DisplayMode.image:
          return 'Image uniquement';
        case DisplayMode.textAndImage:
          return 'Texte + Image';
      }
    }

    String matchDisplayModeToString(MatchDisplayMode mode) {
      switch (mode) {
        case MatchDisplayMode.definitionToWord:
          return 'Définition à Mot';
        case MatchDisplayMode.imageToDefinition:
          return 'Image à Définition';
      }
    }

    String memoryDisplayModeToString(MemoryDisplayMode mode) {
      switch (mode) {
        case MemoryDisplayMode.wordToDefinition:
          return 'Mot à Définition';
        case MemoryDisplayMode.definitionToImage:
          return 'Définition à Image';
        case MemoryDisplayMode.imagePair:
          return 'Paire d\'images identiques';
      }
    }

    final selectedGamesCount =
        _selectedGames.entries.where((entry) => entry.value).length;
    final nonVipLimitReached = !_isVip && selectedGamesCount >= 3;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isGuest)
            StyledCard(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.yellow.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'QI: ${_userIQ.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isVip)
                          Row(
                            children: [
                              const Chip(
                                label: Text('VIP'),
                                backgroundColor: Colors.amber,
                                labelStyle: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _cancelVipSubscription,
                                child: const Text(
                                  'Se désabonner',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          )
                        else
                          ElevatedButton(
                            onPressed: _showVipAdvantagesPopup,
                            child: const Text('Devenir VIP'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!_isVip)
                      Text(
                        'Générations restantes ce mois-ci : $nonVipGenerationsRemaining / 20',
                        style: TextStyle(
                          color:
                              nonVipGenerationsRemaining <= 5
                                  ? Colors.red
                                  : Colors.grey[700],
                        ),
                      ),
                    if (_isVip) ...[
                      Text(
                        'Générations restantes aujourd\'hui : $vipGenerationsRemaining / 30',
                        style: TextStyle(
                          color:
                              vipGenerationsRemaining <= 5
                                  ? Colors.red
                                  : Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Générations avec images restantes aujourd\'hui : $vipImageGenerationsRemaining / 20',
                        style: TextStyle(
                          color:
                              vipImageGenerationsRemaining <= 5
                                  ? Colors.red
                                  : Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // NOUVEAU: Boutons d'action principaux en haut
          if (!widget.isGuest) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateGames,
                    icon:
                        _isGenerating
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(Icons.auto_awesome),
                    label: Text(
                      _isGenerating
                          ? 'Génération en cours...'
                          : (_quizToComplete != null
                              ? (_modifyExistingGames
                                  ? 'Modifier et Compléter par IA'
                                  : 'Compléter par IA')
                              : (_aiDecideGames
                                  ? 'Générer (l\'IA choisit les jeux)'
                                  : 'Générer par IA')),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      disabledBackgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.7),
                      disabledForegroundColor: Colors.white,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showOnlineOptions,
                    icon: const Icon(Icons.public),
                    label: const Text(
                      'Jouer en ligne',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            Center(
              child: Text(
                'Connectez-vous pour utiliser l\'IA et jouer en ligne.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // NOUVEAU : Encadré de modification
          if (_quizToComplete != null) ...[
            StyledCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.quizPurple,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Complétion par IA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.quizPurple,
                              ),
                            ),
                            Text(
                              'Quiz: ${_quizToComplete!['text']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _cancelCompletingQuiz,
                        tooltip: 'Annuler',
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Modifier le quiz existant',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Switch(
                        value: _modifyExistingGames,
                        onChanged:
                            (val) => setState(() => _modifyExistingGames = val),
                        activeColor: AppColors.quizPurple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          StyledCard(
            child: TextField(
              controller: _textController,
              maxLength: _isVip ? null : 2000,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Entrez votre texte ici pour générer un jeu',
                border: OutlineInputBorder(),
                hintText: 'Ex: un résumé sur la Seconde Guerre mondiale...',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Types de jeux à inclure dans le quiz :', // Clarification UI
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Option pour que l'IA choisisse automatiquement
          StyledCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Laisser l\'IA décider des jeux'),
                  subtitle: const Text(
                    'L\'IA sélectionnera automatiquement les meilleurs mini-jeux selon votre texte',
                  ),
                  value: _aiDecideGames,
                  activeColor: AppColors.quizPurple,
                  onChanged: (val) => setState(() => _aiDecideGames = val),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Activer un timer'),
                  subtitle: const Text(
                    'Ajouter un chrono par défaut à chaque jeu',
                  ),
                  value: _globalTimerEnabled,
                  activeColor: AppColors.neonCyan,
                  onChanged:
                      (val) => setState(() {
                        _globalTimerEnabled = val;
                        if (!val) _aiCustomTimers = false;
                      }),
                ),
                if (_globalTimerEnabled)
                  SwitchListTile(
                    title: Row(
                      children: [
                        const Text('Personnaliser par l\'IA'),
                        const SizedBox(width: 8),
                        if (!_isVip)
                          const Icon(
                            Icons.lock_rounded,
                            color: AppColors.goldLock,
                            size: 16,
                          ),
                      ],
                    ),
                    subtitle: const Text(
                      'L\'IA définit le meilleur temps selon la difficulté (VIP)',
                    ),
                    value: _aiCustomTimers,
                    activeColor: AppColors.neonCyan,
                    onChanged:
                        _isVip
                            ? (val) => setState(() => _aiCustomTimers = val)
                            : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Carte d'information sur la gestion intelligente des images
          StyledCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isVip ? Icons.auto_awesome : Icons.image_search,
                      color: _isVip ? AppColors.quizPurple : AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isVip ? 'Génération d\'images hybride (VIP)' : 'Images libres de droits (Standard)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isVip
                      ? '🤖 L\'IA choisit automatiquement Openverse pour les images simples et l\'IA FLUX pour les scènes complexes (Max 50 images IA/jour).'
                      : '🔍 Recherche automatique d\'images gratuites via Openverse (Max 300 recherches/jour).',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (!_isVip) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.lock_rounded, color: AppColors.goldLock, size: 14),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Passez VIP pour débloquer la génération d\'images sur-mesure par IA !',
                          style: TextStyle(fontSize: 11, color: AppColors.goldLock, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Si l'IA ne décide pas elle-même, on affiche la liste manuelle
          if (!_aiDecideGames) ...[
            const SizedBox(height: 12),
            StyledCard(
              child: Column(
                children:
                    _selectedGames.keys.map((game) {
                      final isSelected = _selectedGames[game] ?? false;
                      final hintEnabled = _hintsEnabled[game] ?? false;
                      final isLockedForNonVip =
                          !_isVip && !isSelected && nonVipLimitReached;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    game,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                if (isLockedForNonVip)
                                  const Icon(
                                    Icons.lock_rounded,
                                    color: AppColors.goldLock,
                                    size: 18,
                                  ),
                              ],
                            ),
                            value: isSelected,
                            onChanged:
                                isLockedForNonVip
                                    ? null
                                    : (value) {
                                      setState(() {
                                        _selectedGames[game] = value!;
                                        if (value == false)
                                          _hintsEnabled[game] = false;
                                      });
                                    },
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          if (isLockedForNonVip)
                            const Padding(
                              padding: EdgeInsets.only(
                                left: 48,
                                right: 16,
                                bottom: 6,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.workspace_premium,
                                    color: AppColors.goldLock,
                                    size: 14,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Limite non-VIP atteinte (3 jeux max). Passez VIP pour débloquer.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.goldLock,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 48,
                              right: 16,
                              bottom: 6,
                            ),
                            child: Opacity(
                              opacity: isSelected ? 1.0 : 0.35,
                              child: IgnorePointer(
                                ignoring: !isSelected,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: 15,
                                      color:
                                          hintEnabled
                                              ? Colors.amber.shade700
                                              : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      hintEnabled
                                          ? 'Indice activé'
                                          : 'Indice désactivé',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            hintEnabled
                                                ? Colors.amber.shade700
                                                : Colors.grey,
                                      ),
                                    ),
                                    const Spacer(),
                                    Transform.scale(
                                      scale: 0.75,
                                      child: Switch(
                                        value: hintEnabled,
                                        onChanged:
                                            (v) => setState(
                                              () => _hintsEnabled[game] = v,
                                            ),
                                        activeColor: Colors.amber.shade700,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child:
                                isSelected &&
                                        (game == 'QCM' ||
                                            game == 'Relier' ||
                                            game == 'Memory')
                                    ? Container(
                                      margin: const EdgeInsets.only(
                                        left: 48,
                                        right: 16,
                                        bottom: 12,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            isDark
                                                ? Colors.grey[850]
                                                : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.settings,
                                                size: 16,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).primaryColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Options avancées',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          if (game == 'QCM') ...[
                                            DropdownButtonFormField<
                                              DisplayMode
                                            >(
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Affichage de la question',
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                suffixIcon:
                                                    !_isVip
                                                        ? const Icon(
                                                          Icons.lock,
                                                          color: Colors.amber,
                                                          size: 18,
                                                        )
                                                        : null,
                                              ),
                                              value: _qcmQuestionMode,
                                              items:
                                                  DisplayMode.values.map((
                                                    mode,
                                                  ) {
                                                    bool isImageOption =
                                                        mode !=
                                                        DisplayMode.text;
                                                    return DropdownMenuItem(
                                                      value: mode,
                                                      enabled:
                                                          _isVip ||
                                                          !isImageOption,
                                                      child: Text(
                                                        displayModeToString(
                                                              mode,
                                                            ) +
                                                            (!_isVip &&
                                                                    isImageOption
                                                                ? ' (VIP)'
                                                                : ''),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                              onChanged:
                                                  (value) => setState(
                                                    () =>
                                                        _qcmQuestionMode =
                                                            value!,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            DropdownButtonFormField<
                                              DisplayMode
                                            >(
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Affichage des réponses',
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                suffixIcon:
                                                    !_isVip
                                                        ? const Icon(
                                                          Icons.lock,
                                                          color: Colors.amber,
                                                          size: 18,
                                                        )
                                                        : null,
                                              ),
                                              value: _qcmAnswerMode,
                                              items:
                                                  DisplayMode.values.map((
                                                    mode,
                                                  ) {
                                                    bool isImageOption =
                                                        mode !=
                                                        DisplayMode.text;
                                                    return DropdownMenuItem(
                                                      value: mode,
                                                      enabled:
                                                          _isVip ||
                                                          !isImageOption,
                                                      child: Text(
                                                        displayModeToString(
                                                              mode,
                                                            ) +
                                                            (!_isVip &&
                                                                    isImageOption
                                                                ? ' (VIP)'
                                                                : ''),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                              onChanged:
                                                  (value) => setState(
                                                    () =>
                                                        _qcmAnswerMode = value!,
                                                  ),
                                            ),
                                          ],
                                          if (game == 'Relier') ...[
                                            DropdownButtonFormField<
                                              MatchDisplayMode
                                            >(
                                              decoration: InputDecoration(
                                                labelText: 'Type de jeu',
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                suffixIcon:
                                                    !_isVip
                                                        ? const Icon(
                                                          Icons.lock,
                                                          color: Colors.amber,
                                                          size: 18,
                                                        )
                                                        : null,
                                              ),
                                              value: _matchDisplayMode,
                                              items:
                                                  MatchDisplayMode.values.map((
                                                    mode,
                                                  ) {
                                                    bool isImageOption =
                                                        mode ==
                                                        MatchDisplayMode
                                                            .imageToDefinition;
                                                    return DropdownMenuItem(
                                                      value: mode,
                                                      enabled:
                                                          _isVip ||
                                                          !isImageOption,
                                                      child: Text(
                                                        matchDisplayModeToString(
                                                              mode,
                                                            ) +
                                                            (!_isVip &&
                                                                    isImageOption
                                                                ? ' (VIP)'
                                                                : ''),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                              onChanged:
                                                  (value) => setState(
                                                    () =>
                                                        _matchDisplayMode =
                                                            value!,
                                                  ),
                                            ),
                                          ],
                                          if (game == 'Memory') ...[
                                            DropdownButtonFormField<
                                              MemoryDisplayMode
                                            >(
                                              decoration: InputDecoration(
                                                labelText: 'Type de paires',
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                suffixIcon:
                                                    !_isVip
                                                        ? const Icon(
                                                          Icons.lock,
                                                          color: Colors.amber,
                                                          size: 18,
                                                        )
                                                        : null,
                                              ),
                                              value: _memoryDisplayMode,
                                              items:
                                                  MemoryDisplayMode.values.map((
                                                    mode,
                                                  ) {
                                                    final isImageOption =
                                                        mode !=
                                                        MemoryDisplayMode
                                                            .wordToDefinition;
                                                    return DropdownMenuItem(
                                                      value: mode,
                                                      enabled:
                                                          _isVip ||
                                                          !isImageOption,
                                                      child: Text(
                                                        memoryDisplayModeToString(
                                                              mode,
                                                            ) +
                                                            (!_isVip &&
                                                                    isImageOption
                                                                ? ' (VIP)'
                                                                : ''),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                              onChanged:
                                                  (value) => setState(
                                                    () =>
                                                        _memoryDisplayMode =
                                                            value!,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            SwitchListTile(
                                              title: const Text(
                                                'Laisser l\'IA décider du nombre de paires',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                              value: _aiDecidePairs,
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                              onChanged: (value) {
                                                setState(() {
                                                  _aiDecidePairs = value;
                                                  if (_aiDecidePairs)
                                                    _memoryPairs = null;
                                                });
                                              },
                                            ),
                                            if (!_aiDecidePairs)
                                              DropdownButtonFormField<int>(
                                                decoration: InputDecoration(
                                                  labelText: 'Nombre de paires',
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                value: _memoryPairs,
                                                items: List.generate(
                                                  7,
                                                  (index) =>
                                                      DropdownMenuItem<int>(
                                                        value: 4 + index,
                                                        child: Text(
                                                          '${4 + index} paires',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                              ),
                                                        ),
                                                      ),
                                                ),
                                                onChanged:
                                                    (value) => setState(
                                                      () =>
                                                          _memoryPairs = value,
                                                    ),
                                              ),
                                          ],
                                        ],
                                      ),
                                    )
                                    : const SizedBox.shrink(),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 16),
          AnimatedOpacity(
            opacity: _status.isEmpty ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Center(
              child: Text(
                _status,
                style: TextStyle(
                  color:
                      _status.toLowerCase().contains('erreur')
                          ? Colors.red
                          : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (nonVipLimitReached) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.lock_rounded, color: AppColors.goldLock),
                label: const Text('Plus de 3 jeux: réservé VIP'),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade700,
                ),
              ),
            ),
          ],

          if (_generatedGames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.indigo,
                    size: 36,
                  ),
                  title: const Text(
                    'Jouer au dernier quiz généré',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Mode Solo (Créé à l\'instant)'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap:
                      () => _playQuiz(
                        _generatedGames,
                        _textController.text.trim(),
                        _lastGeneratedQuizId,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// PAGE DE CRÉATION MANUELLE DE QUIZ (REFONTE UI/UX)
// ============================================================
class ManualQuizCreatorPage extends StatefulWidget {
  final List<dynamic> initialGames;
  const ManualQuizCreatorPage({super.key, required this.initialGames});
  @override
  State<ManualQuizCreatorPage> createState() => _ManualQuizCreatorPageState();
}

class _ManualQuizCreatorPageState extends State<ManualQuizCreatorPage> {
  late List<Map<String, dynamic>> _games;

  final List<String> _gameTypes = [
    'QCM',
    'Vrai ou Faux',
    'Qui suis-je ?',
    'Le Mot Anagramme',
    'Compléter la Phrase',
    'Pendu amélioré',
    'Mot Mystère',
    'Choisir l\'Intrus',
    'Deux Vérités, un Mensonge',
    'Chronologie Mélangée',
    'Estimation',
    'Quiz par Indices',
    'Memory',
    'Relier',
    'Quiz Éclair',
  ];

  @override
  void initState() {
    super.initState();
    _games =
        widget.initialGames
            .map((g) => Map<String, dynamic>.from(g as Map))
            .toList();
  }

  void _addGame(Map<String, dynamic> game) {
    if (game['difficulty'] == null) game['difficulty'] = 5;
    setState(() => _games.add(game));
  }

  void _removeGame(int index) => setState(() => _games.removeAt(index));

  void _editGame(int index) async {
    final game = _games[index];
    final updatedGame = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddEditGameScreen(
              gameType: game['type']?.toString() ?? 'QCM',
              initialGame: Map<String, dynamic>.from(game),
            ),
      ),
    );
    if (updatedGame != null) {
      setState(() => _games[index] = updatedGame);
    }
  }

  void _showAddGameTypeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Format de la question', // Clarifié au lieu de "Type de jeu"
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _gameTypes.length,
                  itemBuilder: (context, index) {
                    final type = _gameTypes[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.extension_rounded,
                        color: AppColors.primaryBlue,
                      ),
                      title: Text(type),
                      onTap: () async {
                        Navigator.pop(context); // Fermer le bottom sheet
                        final newGame =
                            await Navigator.push<Map<String, dynamic>>(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AddEditGameScreen(gameType: type),
                              ),
                            );
                        if (newGame != null) {
                          _addGame(newGame);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _gameTypeSummary(Map<String, dynamic> game) {
    final type = game['type']?.toString() ?? '';
    try {
      if (type.contains('QCM'))
        return game['question'] is Map
            ? (game['question']['text'] ?? '')
            : (game['question'] ?? '');
      if (type.contains('Vrai ou Faux'))
        return game['question']?.toString() ?? '';
      if (type.contains('Compléter')) return game['question']?.toString() ?? '';
      if (type.contains('Qui suis')) return game['riddle']?.toString() ?? '';
      if (type.contains('Anagramme')) return game['anagram']?.toString() ?? '';
      if (type.contains('Pendu') || type.contains('Mot Mystère'))
        return game['word']?.toString() ?? '';
      if (type.contains('Intrus')) return game['question']?.toString() ?? '';
      if (type.contains('Deux Vérités'))
        return (game['statements'] as List?)?.join(', ') ?? '';
      if (type.contains('Chronologie'))
        return (game['events'] as List?)?.join(' → ') ?? '';
      if (type.contains('Estimation'))
        return game['question']?.toString() ?? '';
      if (type.contains('Quiz par Indices'))
        return 'Réponse: ${game['answer']?.toString() ?? ''}';
      if (type.contains('Relier') || type.contains('Memory')) {
        final pairs = game['pairs'] as List? ?? game['items'] as List? ?? [];
        return '${pairs.length} paires configurées';
      }
    } catch (_) {}
    return '';
  }

  List<Map<String, String>> _getImageInfos(Map<String, dynamic> game) {
    final result = <Map<String, String>>[];
    final q = game['question'];
    if (q is Map) {
      final url = q['image_url']?.toString() ?? '';
      if (url.isNotEmpty) result.add({'label': 'Question', 'url': url});
    }
    final topImg = game['image_url']?.toString() ?? '';
    if (topImg.isNotEmpty) result.add({'label': 'Image', 'url': topImg});

    final opts = game['options'] as List?;
    if (opts != null) {
      for (int i = 0; i < opts.length; i++) {
        final opt = opts[i];
        if (opt is Map) {
          final url = opt['image_url']?.toString() ?? '';
          if (url.isNotEmpty)
            result.add({'label': 'Option ${i + 1}', 'url': url});
        }
      }
    }
    final pairs = game['pairs'] as List? ?? game['items'] as List?;
    if (pairs != null) {
      for (int i = 0; i < pairs.length; i++) {
        final pair = pairs[i];
        if (pair is Map) {
          final url = pair['image_url']?.toString() ?? '';
          if (url.isNotEmpty)
            result.add({'label': 'Paire ${i + 1}', 'url': url});
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors =
        isDark
            ? [AppColors.deepBlue, AppColors.midnightSurface]
            : [AppColors.primaryBlue, const Color(0xFF6C3FC7)];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Éditeur de Quiz', // Un Quiz contient des questions
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: const BackButton(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed:
                _games.isEmpty
                    ? null
                    : () {
                      // Vous pouvez passer le titre ici si vous souhaitez le sauvegarder globalement
                      Navigator.of(context).pop(_games);
                    },
            icon: const Icon(Icons.save_rounded, color: Colors.white),
            label: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGameTypeSelector,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une question'), // Clarifié
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _games.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.extension_off_rounded,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune question dans ce quiz.', // Clarifié
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Appuyez sur + pour ajouter une question/épreuve.', // Clarifié
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ReorderableListView.builder(
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                        top: 8,
                        bottom: 80,
                      ),
                      itemCount: _games.length,
                      itemBuilder: (ctx, i) {
                        final game = _games[i];
                        game['id'] ??= '${game.hashCode}_$i';
                        final type = game['type']?.toString() ?? '';
                        final summary = _gameTypeSummary(game);
                        final imageInfos = _getImageInfos(game);

                        return StyledCard(
                          key: ValueKey(game['id']),
                          padding: const EdgeInsets.all(0),
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 8, right: 8),
                                  child: Icon(
                                    Icons.drag_indicator_rounded,
                                    color: Colors.grey,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Chip(
                                        label: Text(
                                          type,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor: AppColors.primaryBlue
                                            .withOpacity(0.1),
                                        side: BorderSide.none,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      if (summary.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            summary,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      if (imageInfos.isNotEmpty)
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children:
                                              imageInfos
                                                  .map(
                                                    (info) => Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons.image,
                                                            size: 12,
                                                            color: Colors.blue,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            info['label']!,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 10,
                                                                  color:
                                                                      Colors
                                                                          .blue,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        color: AppColors.primaryBlue,
                                      ),
                                      onPressed: () => _editGame(i),
                                      tooltip: 'Modifier',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_rounded,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeGame(i),
                                      tooltip: 'Supprimer',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      onReorder: (oldIdx, newIdx) {
                        setState(() {
                          if (newIdx > oldIdx) newIdx--;
                          _games.insert(newIdx, _games.removeAt(oldIdx));
                        });
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ECRAN D'AJOUT/ÉDITION D'UN JEU (REMPLACE _AddGameDialog)
// ============================================================
class AddEditGameScreen extends StatefulWidget {
  final String gameType;
  final Map<String, dynamic>? initialGame;

  const AddEditGameScreen({
    super.key,
    required this.gameType,
    this.initialGame,
  });

  @override
  State<AddEditGameScreen> createState() => _AddEditGameScreenState();
}

class _AddEditGameScreenState extends State<AddEditGameScreen> {
  final _formKey = GlobalKey<FormState>();

  final _c1 = TextEditingController();
  final _c2 = TextEditingController();
  final _c3 = TextEditingController();
  final _c4 = TextEditingController();
  final _c5 = TextEditingController();

  final _cImgOpt1 = TextEditingController();
  final _cImgOpt2 = TextEditingController();
  final _cImgOpt3 = TextEditingController();

  final _cHint = TextEditingController();
  final _cImageUrl = TextEditingController(); // Image de la question
  final _cTimeLimit = TextEditingController();

  // Listes dynamiques pour les options (QCM, Intrus, Quiz Eclair)
  List<TextEditingController> _optionsTexts = [
    TextEditingController(),
    TextEditingController(),
  ];
  List<TextEditingController> _optionsImages = [
    TextEditingController(),
    TextEditingController(),
  ];

  List<TextEditingController> _cEvents = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  List<TextEditingController> _cStatements = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  List<TextEditingController> _cPairWords = [
    TextEditingController(),
    TextEditingController(),
  ];
  List<TextEditingController> _cPairDefs = [
    TextEditingController(),
    TextEditingController(),
  ];
  List<TextEditingController> _cPairImgUrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _boolAnswer = true;
  int _difficulty = 5;
  String _displayMode = 'definitionToWord';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final g = widget.initialGame;
    if (g == null) return;

    _difficulty = (g['difficulty'] as num? ?? 5).toInt();
    final type = widget.gameType;

    _cHint.text = g['hint']?.toString() ?? '';
    _cImageUrl.text = g['image_url']?.toString() ?? '';
    if (g['timeLimit'] != null) {
      _cTimeLimit.text = g['timeLimit'].toString();
    }

    if (type == 'QCM' || type.contains('Intrus') || type == 'Quiz Éclair') {
      final q = g['question'];
      _c1.text =
          q is Map ? (q['text']?.toString() ?? '') : (q?.toString() ?? '');
      if (q is Map) _cImageUrl.text = q['image_url']?.toString() ?? '';

      List dynamicOpts = [];
      if (type == 'QCM') dynamicOpts = g['options'] as List? ?? [];
      if (type.contains('Intrus')) {
        dynamicOpts =
            (g['options'] as List?)?.map((o) => o.toString()).toList() ?? [];
        _c5.text = g['intruder']?.toString() ?? '';
        dynamicOpts.remove(_c5.text); // Enlever l'intrus des options normales
      }
      if (type == 'Quiz Éclair') {
        dynamicOpts = g['choices'] as List? ?? [];
        _c5.text = g['answer']?.toString() ?? '';
      }
      if (type == 'QCM') _c5.text = g['correct']?.toString() ?? '';

      if (dynamicOpts.isNotEmpty) {
        _optionsTexts.clear();
        _optionsImages.clear();
        for (var opt in dynamicOpts) {
          _optionsTexts.add(
            TextEditingController(
              text:
                  opt is Map ? (opt['text']?.toString() ?? '') : opt.toString(),
            ),
          );
          _optionsImages.add(
            TextEditingController(
              text: opt is Map ? (opt['image_url']?.toString() ?? '') : '',
            ),
          );
        }
      }
    } else if (type == 'Vrai ou Faux') {
      _c1.text = g['question']?.toString() ?? '';
      _boolAnswer = g['answer'] as bool? ?? true;
    } else if (type == 'Compléter la Phrase') {
      _c1.text = g['question']?.toString() ?? '';
      _c2.text = g['correct']?.toString() ?? '';
    } else if (type == 'Qui suis-je ?') {
      _c1.text = g['riddle']?.toString() ?? '';
      _c2.text = g['answer']?.toString() ?? '';
    } else if (type == 'Le Mot Anagramme') {
      _c1.text = g['solution']?.toString() ?? '';
    } else if (type == 'Pendu amélioré' || type == 'Mot Mystère') {
      _c1.text = g['word']?.toString() ?? '';
    }
    // Intrus traité plus haut
    else if (type.contains('Deux Vérités')) {
      final stmts =
          (g['statements'] as List?)?.map((s) => s.toString()).toList() ?? [];
      _cStatements = stmts.map((s) => TextEditingController(text: s)).toList();
      while (_cStatements.length < 3) _cStatements.add(TextEditingController());
      _c2.text = g['lie']?.toString() ?? '';
    } else if (type.contains('Chronologie') || type == 'Quiz par Indices') {
      _c1.text =
          (type.contains('Chronologie') ? g['question'] : g['answer'])
              ?.toString() ??
          '';
      final list =
          ((type.contains('Chronologie') ? g['events'] : g['clues']) as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      _cEvents = list.map((e) => TextEditingController(text: e)).toList();
      while (_cEvents.length < 3) _cEvents.add(TextEditingController());
    } else if (type == 'Estimation') {
      _c1.text = g['question']?.toString() ?? '';
      _c2.text = (g['answer'] as num?)?.toString() ?? '';
      _c3.text = g['unit']?.toString() ?? '';
    }
    // Quiz Eclair traité plus haut
    else if (type == 'Relier' || type == 'Memory') {
      _displayMode =
          g['displayMode']?.toString() ??
          (type == 'Relier' ? 'definitionToWord' : 'wordToDefinition');
      final pairs = (g['pairs'] as List? ?? g['items'] as List?) ?? [];
      _cPairWords.clear();
      _cPairDefs.clear();
      _cPairImgUrls.clear();

      for (final pair in pairs) {
        _cPairWords.add(
          TextEditingController(
            text:
                pair['word']?.toString() ??
                pair['image_description']?.toString() ??
                pair['text_label']?.toString() ??
                '',
          ),
        );
        _cPairDefs.add(
          TextEditingController(text: pair['definition']?.toString() ?? ''),
        );
        _cPairImgUrls.add(
          TextEditingController(text: pair['image_url']?.toString() ?? ''),
        );
      }
      while (_cPairWords.length < 2) {
        _cPairWords.add(TextEditingController());
        _cPairDefs.add(TextEditingController());
        _cPairImgUrls.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    for (var c in [
      _c1,
      _c2,
      _c3,
      _c4,
      _c5,
      _cHint,
      _cImageUrl,
      _cTimeLimit,
      _cImgOpt1,
      _cImgOpt2,
      _cImgOpt3,
      ..._optionsTexts,
      ..._optionsImages,
      ..._cEvents,
      ..._cStatements,
      ..._cPairWords,
      ..._cPairDefs,
      ..._cPairImgUrls,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // Fonction appelée quand on clique sur le bouton "Uploader"
  Future<void> _pickAndUploadImage(TextEditingController controller) async {
    try {
      // 1. Ouvrir la galerie pour choisir une image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Réduire légèrement la qualité pour alléger l'upload
      );

      if (image == null) return; // L'utilisateur a annulé

      // 2. Afficher un indicateur de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 16),
                Text("Upload de l'image en cours..."),
              ],
            ),
            duration: Duration(minutes: 1), // Reste affiché pendant l'upload
          ),
        );
      }

      // 3. Lire les données de l'image (readAsBytes fonctionne sur Mobile ET sur Web)
      final Uint8List imageData = await image.readAsBytes();

      // 4. Préparer le chemin dans Firebase Storage
      final user = FirebaseAuth.instance.currentUser;
      final String timestamp =
          DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${timestamp}_${image.name}';

      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('quiz_images')
          .child(user?.uid ?? 'anonymous')
          .child(fileName);

      // 5. Lancer l'upload
      final UploadTask uploadTask = storageRef.putData(
        imageData,
        SettableMetadata(contentType: 'image/jpeg'), // Forcer le type MIME
      );

      final TaskSnapshot snapshot = await uploadTask;

      // 6. Récupérer l'URL publique
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // 7. Mettre à jour l'interface
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Cacher le chargement
        setState(() {
          controller.text = downloadUrl; // Assigne l'URL au champ texte
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image uploadée avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Erreur d'upload : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'upload : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic>? _buildGameData() {
    if (!_formKey.currentState!.validate()) return null;

    final type = widget.gameType;
    final hint = _cHint.text.trim();
    final imgUrl = _cImageUrl.text.trim();
    final timeLimitStr = _cTimeLimit.text.trim();
    final timeLimit = int.tryParse(timeLimitStr);

    final base = {
      'type': type,
      'difficulty': _difficulty,
      if (hint.isNotEmpty) 'hint': hint,
      if (imgUrl.isNotEmpty && type != 'QCM') 'image_url': imgUrl,
      if (timeLimit != null) 'timeLimit': timeLimit,
    };

    if (type == 'QCM') {
      final optionsTextsStr =
          _optionsTexts
              .map((c) => c.text.trim())
              .where((s) => s.isNotEmpty)
              .toList();
      if (_c1.text.isEmpty || _c5.text.isEmpty || optionsTextsStr.length < 2)
        return null;
      if (!optionsTextsStr.contains(_c5.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erreur: La bonne réponse doit être identique à l\'une des options.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
      return {
        ...base,
        'question': {
          'text': _c1.text.trim(),
          if (imgUrl.isNotEmpty) 'image_url': imgUrl,
        },
        'options':
            List.generate(_optionsTexts.length, (i) {
              if (_optionsTexts[i].text.trim().isEmpty) return null;
              return {
                'text': _optionsTexts[i].text.trim(),
                if (_optionsImages[i].text.isNotEmpty)
                  'image_url': _optionsImages[i].text.trim(),
              };
            }).whereType<Map>().toList(),
        'correct': _c5.text.trim(),
      };
    }

    if (type.contains('Intrus')) {
      final intruder = _c5.text.trim();
      final normalOpts =
          _optionsTexts
              .map((c) => c.text.trim())
              .where((s) => s.isNotEmpty)
              .toList();
      if (normalOpts.isEmpty || intruder.isEmpty) return null;
      final allOptions = [...normalOpts, intruder]..shuffle();
      return {
        ...base,
        'question': _c1.text.trim(),
        'options': allOptions,
        'intruder': intruder,
      };
    }

    if (type == 'Quiz Éclair') {
      final choices =
          _optionsTexts
              .map((c) => c.text.trim())
              .where((s) => s.isNotEmpty)
              .toList();
      if (_c1.text.isEmpty || _c5.text.isEmpty || choices.isEmpty) return null;
      return {
        ...base,
        'question': _c1.text.trim(),
        'answer': _c5.text.trim(),
        'choices': choices,
      };
    }

    // Eclair traité plus haut

    if (type == 'Vrai ou Faux')
      return {...base, 'question': _c1.text.trim(), 'answer': _boolAnswer};
    if (type == 'Compléter la Phrase')
      return {...base, 'question': _c1.text.trim(), 'correct': _c2.text.trim()};
    if (type == 'Qui suis-je ?')
      return {...base, 'riddle': _c1.text.trim(), 'answer': _c2.text.trim()};

    // ROBUSTESSE: Suppression de tous les espaces
    if (type == 'Le Mot Anagramme') {
      final solution = _c1.text.trim().toUpperCase().replaceAll(
        RegExp(r'\s+'),
        '',
      );
      return {...base, 'anagram': solution, 'solution': solution};
    }
    if (type == 'Pendu amélioré' || type == 'Mot Mystère') {
      final word = _c1.text.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
      if (type == 'Mot Mystère' && word.length < 4) return null;
      return {...base, 'word': word};
    }

    // Intrus traité plus haut

    // ROBUSTESSE: Sécurisation du mensonge
    if (type.contains('Deux Vérités')) {
      final stmts =
          _cStatements
              .map((c) => c.text.trim())
              .where((s) => s.isNotEmpty)
              .toList();
      final lie = _c2.text.trim();
      if (stmts.length < 3 || lie.isEmpty) {
        if (stmts.length < 3)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Il faut au moins 3 affirmations.'),
              backgroundColor: Colors.orange,
            ),
          );
        return null;
      }
      if (!stmts.contains(lie)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erreur: Le mensonge doit être EXACTEMENT identique à l\'une des affirmations.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
      return {...base, 'statements': stmts, 'lie': lie};
    }

    if (type.contains('Chronologie')) {
      final evts =
          _cEvents
              .map((c) => c.text.trim())
              .where((s) => s.isNotEmpty)
              .toList();
      if (evts.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Il faut au moins 3 événements.'),
            backgroundColor: Colors.orange,
          ),
        );
        return null;
      }
      return {
        ...base,
        'question':
            _c1.text.trim().isNotEmpty
                ? _c1.text.trim()
                : "Remettez dans l'ordre",
        'events': evts,
      };
    }

    if (type == 'Estimation') {
      final val = double.tryParse(_c2.text.trim());
      if (val == null) return null;
      return {
        ...base,
        'question': _c1.text.trim(),
        'answer': val,
        'unit': _c3.text.trim(),
      };
    }

    if (type == 'Quiz par Indices') {
      final clues =
          _cEvents
              .map((c) => c.text.trim())
              .where((s) => s.isNotEmpty)
              .toList();
      if (clues.length < 2 || _c1.text.isEmpty) {
        if (clues.length < 2)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Il faut au moins 2 indices.'),
              backgroundColor: Colors.orange,
            ),
          );
        return null;
      }
      return {...base, 'clues': clues, 'answer': _c1.text.trim()};
    }

    if (type == 'Relier' || type == 'Memory') {
      final pairs = <Map<String, dynamic>>[];
      for (int i = 0; i < _cPairWords.length; i++) {
        final w = _cPairWords[i].text.trim();
        final d = _cPairDefs[i].text.trim();
        final img =
            i < _cPairImgUrls.length ? _cPairImgUrls[i].text.trim() : '';

        if (w.isNotEmpty || img.isNotEmpty) {
          Map<String, dynamic> pair = {};
          if (_displayMode == 'imagePair') {
            pair = {'text_label': w, if (img.isNotEmpty) 'image_url': img};
          } else if (_displayMode.contains('image')) {
            pair = {
              'definition': d,
              'image_description': w,
              if (img.isNotEmpty) 'image_url': img,
            };
          } else {
            pair = {
              'word': w,
              'definition': d,
              if (img.isNotEmpty) 'image_url': img,
            };
          }
          pairs.add(pair);
        }
      }
      if (pairs.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Il faut au moins 2 paires.'),
            backgroundColor: Colors.orange,
          ),
        );
        return null;
      }

      return {
        ...base,
        'displayMode': _displayMode,
        _displayMode == 'imagePair' ? 'items' : 'pairs': pairs,
      };
    }
    return null;
  }

  void _save() {
    final gameData = _buildGameData();
    if (gameData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez remplir correctement tous les champs obligatoires (*).',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.of(context).pop(gameData);
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.gameType;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialGame != null ? 'Modifier : $type' : 'Nouveau : $type',
        ),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save),
        label: const Text('Enregistrer'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 100,
          ),
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration Principale',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (type == 'QCM' ||
                        type.contains('Intrus') ||
                        type == 'Quiz Éclair') ...[
                      _buildTextField(_c1, 'Question *', maxLines: 2),
                      _buildImageField(
                        _cImageUrl,
                        'Image pour la question (Optionnelle)',
                      ),
                      const Divider(height: 32),

                      Text(
                        type == 'QCM'
                            ? 'Options possibles :'
                            : 'Options normales (Faux choix) :',
                      ),
                      ..._optionsTexts.asMap().entries.map((e) {
                        final idx = e.key;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12, top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      _optionsTexts[idx],
                                      'Option ${idx + 1} *',
                                    ),
                                  ),
                                  if (_optionsTexts.length > 2)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => setState(() {
                                            _optionsTexts[idx].dispose();
                                            _optionsImages[idx].dispose();
                                            _optionsTexts.removeAt(idx);
                                            _optionsImages.removeAt(idx);
                                          }),
                                    ),
                                ],
                              ),
                              if (type ==
                                  'QCM') // Image optionnelle seulement pour QCM
                                _buildImageField(
                                  _optionsImages[idx],
                                  'Image pour cette option',
                                ),
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed:
                            () => setState(() {
                              _optionsTexts.add(TextEditingController());
                              _optionsImages.add(TextEditingController());
                            }),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une option'),
                      ),
                      const Divider(height: 32),
                      _buildTextField(
                        _c5,
                        type == 'QCM'
                            ? 'Bonne réponse (copiez le texte exact d\'une option) *'
                            : (type.contains('Intrus')
                                ? 'L\'intrus (La bonne réponse) *'
                                : 'La bonne réponse *'),
                      ),
                    ] else if (type == 'Vrai ou Faux') ...[
                      _buildTextField(_c1, 'Question *', maxLines: 2),
                      SwitchListTile(
                        title: Text(
                          _boolAnswer ? 'Réponse : Vrai ✓' : 'Réponse : Faux ✗',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        value: _boolAnswer,
                        onChanged: (v) => setState(() => _boolAnswer = v),
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                      ),
                    ] else if (type == 'Compléter la Phrase') ...[
                      _buildTextField(
                        _c1,
                        'Phrase avec le mot manquant (ex: avec ___) *',
                        maxLines: 2,
                      ),
                      _buildTextField(_c2, 'Le mot manquant (Bonne réponse) *'),
                    ] else if (type == 'Qui suis-je ?') ...[
                      _buildTextField(_c1, 'La devinette *', maxLines: 3),
                      _buildTextField(_c2, 'La réponse *'),
                    ] else if (type == 'Le Mot Anagramme') ...[
                      _buildTextField(
                        _c1,
                        'Mot solution (sera mélangé automatiquement) *',
                      ),
                    ] else if (type == 'Pendu amélioré') ...[
                      _buildTextField(_c1, 'Mot à deviner (sans espaces) *'),
                    ] else if (type == 'Mot Mystère') ...[
                      _buildTextField(
                        _c1,
                        'Mot secret (min 4 lettres, sans espaces) *',
                      ),
                    ] else if (type.contains('Deux Vérités')) ...[
                      const Text(
                        'Entrez 3 affirmations (2 vraies, 1 fausse) :',
                      ),
                      ..._cStatements.asMap().entries.map(
                        (e) => _buildDynamicListItem(
                          _cStatements,
                          e.key,
                          'Affirmation ${e.key + 1}',
                        ),
                      ),
                      TextButton.icon(
                        onPressed:
                            () => setState(
                              () => _cStatements.add(TextEditingController()),
                            ),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une affirmation'),
                      ),
                      _buildTextField(
                        _c2,
                        'Lequel est le mensonge ? (Copiez le texte exact) *',
                      ),
                    ] else if (type.contains('Chronologie')) ...[
                      _buildTextField(
                        _c1,
                        'Question (ex: Remettez dans l\'ordre)',
                      ),
                      const Text(
                        'Entrez les événements dans l\'ordre CHRONOLOGIQUE (du plus ancien au plus récent) :',
                      ),
                      ..._cEvents.asMap().entries.map(
                        (e) => _buildDynamicListItem(
                          _cEvents,
                          e.key,
                          'Événement ${e.key + 1} *',
                        ),
                      ),
                      TextButton.icon(
                        onPressed:
                            () => setState(
                              () => _cEvents.add(TextEditingController()),
                            ),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un événement'),
                      ),
                    ] else if (type == 'Estimation') ...[
                      _buildTextField(
                        _c1,
                        'Question (ex: En quelle année...) *',
                        maxLines: 2,
                      ),
                      _buildTextField(
                        _c2,
                        'Réponse exacte (Nombre uniquement) *',
                        isNumber: true,
                      ),
                      _buildTextField(_c3, 'Unité (ex: ans, km, kg)'),
                    ] else if (type == 'Quiz par Indices') ...[
                      _buildTextField(_c1, 'La réponse finale à trouver *'),
                      const Text(
                        'Entrez les indices (du plus difficile au plus facile) :',
                      ),
                      ..._cEvents.asMap().entries.map(
                        (e) => _buildDynamicListItem(
                          _cEvents,
                          e.key,
                          'Indice ${e.key + 1} *',
                        ),
                      ),
                      TextButton.icon(
                        onPressed:
                            () => setState(
                              () => _cEvents.add(TextEditingController()),
                            ),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un indice'),
                      ),
                    ] else if (type == 'Relier' || type == 'Memory') ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Mode d'affichage",
                        ),
                        value: _displayMode,
                        items: [
                          const DropdownMenuItem(
                            value: 'definitionToWord',
                            child: Text('Mot <-> Définition (Texte)'),
                          ),
                          if (type == 'Memory')
                            const DropdownMenuItem(
                              value: 'imagePair',
                              child: Text("Paires d'images identiques"),
                            ),
                          const DropdownMenuItem(
                            value: 'imageToDefinition',
                            child: Text('Image <-> Texte'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _displayMode = v!),
                      ),
                      const SizedBox(height: 16),
                      const Text('Paires :'),
                      ..._cPairWords.asMap().entries.map((e) {
                        return Card(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade100,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Paire ${e.key + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_cPairWords.length > 2)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _cPairWords[e.key].dispose();
                                            _cPairDefs[e.key].dispose();
                                            _cPairImgUrls[e.key].dispose();
                                            _cPairWords.removeAt(e.key);
                                            _cPairDefs.removeAt(e.key);
                                            _cPairImgUrls.removeAt(e.key);
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                _buildTextField(
                                  e.value,
                                  _displayMode == 'imagePair'
                                      ? "Label (si pas d'image) *"
                                      : 'Mot / Label 1 *',
                                ),
                                if (_displayMode != 'imagePair')
                                  _buildTextField(
                                    _cPairDefs[e.key],
                                    'Définition / Label 2 *',
                                  ),
                                _buildImageField(
                                  _cPairImgUrls[e.key],
                                  'Image optionnelle pour cette paire',
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed:
                            () => setState(() {
                              _cPairWords.add(TextEditingController());
                              _cPairDefs.add(TextEditingController());
                              _cPairImgUrls.add(TextEditingController());
                            }),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une paire'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- CARTE OPTIONS AVANCEES ---
            Card(
              elevation: 2,
              child: ExpansionTile(
                initiallyExpanded: false,
                title: Text(
                  'Options Avancées (Indices, Image, Difficulté)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Difficulté : ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$_difficulty / 10',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _difficulty.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          onChanged:
                              (v) => setState(() => _difficulty = v.toInt()),
                        ),
                        const Divider(),
                        _buildTextField(
                          _cHint,
                          'Indice global pour aider le joueur (Optionnel)',
                          maxLines: 2,
                        ),
                        _buildTextField(
                          _cTimeLimit,
                          'Temps imparti (en secondes, laisser vide pour défaut)',
                        ),
                        if (type != 'QCM') // Le QCM gère ses images plus haut
                          _buildImageField(
                            _cImageUrl,
                            'Image illustrant la question (Optionnel)',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType:
            isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
        ),
        validator: (value) {
          if (label.contains('*') && (value == null || value.trim().isEmpty)) {
            return 'Ce champ est requis';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDynamicListItem(
    List<TextEditingController> list,
    int index,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: _buildTextField(list[index], label)),
          if (list.length > 3)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () {
                setState(() {
                  list[index].dispose();
                  list.removeAt(index);
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOptionWithImage(
    TextEditingController textCtrl,
    TextEditingController imgCtrl,
    String label,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTextField(textCtrl, label),
          _buildImageField(imgCtrl, 'Image pour cette option'),
        ],
      ),
    );
  }

  // Le widget sans TextField visible
  Widget _buildImageField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'URL de l\'image',
              hintText: 'https://...',
              prefixIcon: Icon(Icons.link),
            ),
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 8),

          if (controller.text.isEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickAndUploadImage(controller),
                icon: const Icon(Icons.upload_file),
                label: const Text('Uploader une image'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    controller.text.trim(),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          height: 50,
                          width: double.infinity,
                          color: Colors.red.shade50,
                          child: const Center(
                            child: Text(
                              'Erreur chargement image',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => controller.clear()),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS PAGE
// ============================================================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              'Supprimer mon compte ?',
              style: TextStyle(color: Colors.red),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer définitivement votre compte et toutes vos données ? '
              'Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();
          await user.delete();
        }
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erreur: Veuillez vous déconnecter et vous reconnecter avant de supprimer votre compte.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors =
        isDark
            ? [const Color(0xFF2D1B69), const Color(0xFF1A1040)]
            : [const Color(0xFF5C35B8), const Color(0xFF3F6FD4)];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: const BackButton(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // LANGUE
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
            child: Text(
              'LANGUE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Card(
            child: Consumer<LocaleProvider>(
              builder: (context, localeProvider, _) {
                return DropdownButtonFormField<String>(
                  value: localeProvider.locale,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'es', child: Text('Español')),
                  ],
                  onChanged: (val) {
                    if (val != null) localeProvider.setLocale(val);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // APPARENCE
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
            child: Text(
              'APPARENCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                _ThemeOptionTile(
                  label: 'Clair',
                  icon: Icons.light_mode_rounded,
                  selected: themeProvider.themeMode == ThemeMode.light,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                ),
                const Divider(height: 1, indent: 56),
                _ThemeOptionTile(
                  label: 'Sombre',
                  icon: Icons.dark_mode_rounded,
                  selected: themeProvider.themeMode == ThemeMode.dark,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                ),
                const Divider(height: 1, indent: 56),
                _ThemeOptionTile(
                  label: 'Système',
                  icon: Icons.brightness_auto_rounded,
                  selected: themeProvider.themeMode == ThemeMode.system,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // COMPTE
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'COMPTE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.orange),
                  title: const Text('Se déconnecter'),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Supprimer mon compte',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: selected ? color : null),
      title: Text(
        label,
        style:
            selected
                ? TextStyle(fontWeight: FontWeight.bold, color: color)
                : null,
      ),
      trailing:
          selected
              ? Icon(Icons.check_circle_rounded, color: color)
              : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class QuizLibraryContainerPage extends StatelessWidget {
  final bool isGuest;
  final Function(List<dynamic>, String, String?) onPlay;
  final Function(Map<String, dynamic>) onPlayOnline;
  final Function(Map<String, dynamic>) onCompleteAI; // NOUVEAU

  const QuizLibraryContainerPage({
    super.key,
    required this.isGuest,
    required this.onPlay,
    required this.onPlayOnline,
    required this.onCompleteAI, // NOUVEAU
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: isDark ? Colors.black12 : Colors.white54,
            child: TabBar(
              indicatorColor:
                  isDark ? AppColors.neonCyan : AppColors.primaryBlue,
              labelColor: isDark ? AppColors.neonCyan : AppColors.primaryBlue,
              unselectedLabelColor:
                  isDark ? Colors.white60 : AppColors.textSecondary,
              dividerColor: Colors.transparent,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.folder_shared_rounded),
                  text: 'Mes Créations',
                ),
                Tab(
                  icon: Icon(Icons.explore_rounded),
                  text: 'Explorer (Public)',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                AllQuizzesPage(
                  onPlay: onPlay,
                  isGuest: isGuest,
                  onCompleteAI: onCompleteAI,
                ), // MODIFIÉ
                SearchQuizzesPage(onPlay: onPlay, onPlayOnline: onPlayOnline),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AllQuizzesPage extends StatefulWidget {
  final Function(List<dynamic>, String, String?) onPlay;
  final Function(Map<String, dynamic>) onCompleteAI; // NOUVEAU
  final bool isGuest;

  const AllQuizzesPage({
    super.key,
    required this.onPlay,
    required this.isGuest,
    required this.onCompleteAI, // NOUVEAU
  });
  @override
  State<AllQuizzesPage> createState() => _AllQuizzesPageState();
}

class _AllQuizzesPageState extends State<AllQuizzesPage> {
  List<Map<String, dynamic>> _quizzes = [];
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadQuizzes();
  }

  void _createNewGame() async {
    String? title = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String tempTitle = '';
        return AlertDialog(
          title: const Text('Titre de votre jeu'),
          content: TextField(
            autofocus: true,
            onChanged: (value) => tempTitle = value,
            decoration: const InputDecoration(hintText: 'Ex: Histoire Romaine'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempTitle),
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );

    if (title != null && title.trim().isNotEmpty) {
      if (widget.isGuest) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connectez-vous pour créer des jeux.')),
        );
        return;
      }
      try {
        final quizRef = FirebaseFirestore.instance.collection('quizzes').doc();
        await quizRef.set({
          'quizId': quizRef.id,
          'userName': _currentUser?.displayName ?? 'Anonyme',
          'userId': _currentUser?.uid,
          'text': title.trim(),
          'games': [],
          'timestamp': FieldValue.serverTimestamp(),
          'isPublic': false,
          'theme': 'Général',
        });
        _loadQuizzes();
        if (_currentUser?.uid != null) {
          AppBadges.checkCreationBadges(context, _currentUser!.uid);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Jeu créé ! Cliquez sur l\'icône d\'édition pour y ajouter des mini-jeux.',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
        }
      }
    }
  }

  Future<void> _loadQuizzes() async {
    if (widget.isGuest || _currentUser == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connectez-vous pour voir vos quiz sauvegardés.'),
          ),
        );
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('quizzes')
              .where('userId', isEqualTo: _currentUser!.uid)
              .orderBy('timestamp', descending: true)
              .get();
      if (mounted)
        setState(() {
          _quizzes =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList();
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des quiz : $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _togglePublicStatus(String quizId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('quizzes').doc(quizId).update(
        {'isPublic': !currentStatus},
      );
      _loadQuizzes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quiz mis en ${!currentStatus ? 'public' : 'privé'} !'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  Future<void> _deleteQuiz(String quizId) async {
    try {
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .delete();
      _loadQuizzes();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quiz supprimé !')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  Future<void> _editQuiz(String quizId, List<dynamic> currentGames) async {
    final result = await Navigator.push<List<dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => ManualQuizCreatorPage(
              initialGames: List<dynamic>.from(currentGames),
            ),
      ),
    );
    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(quizId)
            .update({'games': result});
        _loadQuizzes();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz modifié avec succès !')),
          );
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewGame,
        icon: const Icon(Icons.add),
        label: const Text('Créer un jeu'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _quizzes.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Vous n\'avez pas encore créé de quiz. Allez dans l\'onglet "Créer" pour commencer !',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _quizzes.length,
                itemBuilder: (context, index) {
                  final quiz = _quizzes[index];
                  final userName = quiz['userName']?.toString() ?? 'Anonyme';
                  final textPreview =
                      (quiz['text']?.toString() ?? '').length > 50
                          ? '${quiz['text'].toString().substring(0, 50)}...'
                          : quiz['text']?.toString() ?? '';
                  final isPublic = quiz['isPublic'] as bool? ?? false;
                  final gamesInQuiz =
                      (quiz['games'] as List<dynamic>?)
                          ?.map((g) => g['type'] as String? ?? 'Inconnu')
                          .toSet()
                          .toList() ??
                      [];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ExpansionTile(
                      leading: const Icon(Icons.quiz, color: Colors.indigo),
                      title: Text('Quiz de $userName'),
                      subtitle: Text(textPreview),
                      trailing: const Icon(Icons.arrow_downward),
                      children: [
                        if (gamesInQuiz.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children:
                                  gamesInQuiz
                                      .map(
                                        (gameName) => Chip(
                                          label: Text(gameName),
                                          backgroundColor:
                                              Colors.indigo.shade50,
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  widget.onPlay(
                                    quiz['games'] ?? [],
                                    quiz['text'] ?? '',
                                    quiz['id'],
                                  );
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Jouer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                              // NOUVEAU BOUTON ICI
                              if (!widget.isGuest)
                                ElevatedButton.icon(
                                  onPressed: () => widget.onCompleteAI(quiz),
                                  icon: const Icon(Icons.auto_awesome),
                                  label: const Text('Compléter (IA)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.quizPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              if (!widget.isGuest)
                                ElevatedButton.icon(
                                  onPressed:
                                      () => _togglePublicStatus(
                                        quiz['id'],
                                        isPublic,
                                      ),
                                  icon: Icon(
                                    isPublic ? Icons.public_off : Icons.public,
                                  ),
                                  label: Text(isPublic ? 'Privé' : 'Public'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isPublic ? Colors.orange : Colors.blue,
                                  ),
                                ),
                              if (!widget.isGuest)
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.indigo,
                                  ),
                                  onPressed:
                                      () => _editQuiz(
                                        quiz['id'],
                                        quiz['games'] ?? [],
                                      ),
                                  tooltip: 'Modifier manuellement',
                                ),
                              if (!widget.isGuest)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteQuiz(quiz['id']),
                                  tooltip: 'Supprimer ce quiz',
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}

class SearchQuizzesPage extends StatefulWidget {
  final Function(List<dynamic>, String, String?) onPlay;
  final Function(Map<String, dynamic>) onPlayOnline;

  const SearchQuizzesPage({
    super.key,
    required this.onPlay,
    required this.onPlayOnline,
  });

  @override
  State<SearchQuizzesPage> createState() => _SearchQuizzesPageState();
}

class _SearchQuizzesPageState extends State<SearchQuizzesPage> {
  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> _filteredQuizzes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPublicQuizzes();
    _searchController.addListener(_filterQuizzes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterQuizzes);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPublicQuizzes() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('quizzes')
              .where('isPublic', isEqualTo: true)
              .orderBy('timestamp', descending: true)
              .limit(100)
              .get();
      if (mounted)
        setState(() {
          _quizzes =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                data['quizId'] = doc.id;
                return data;
              }).toList();
          _filteredQuizzes = List.from(_quizzes);
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des quiz publics : $e'),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterQuizzes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredQuizzes =
          _quizzes.where((quiz) {
            final userName = (quiz['userName']?.toString() ?? '').toLowerCase();
            final text = (quiz['text']?.toString() ?? '').toLowerCase();
            final theme = (quiz['theme']?.toString() ?? '').toLowerCase();
            return userName.contains(query) ||
                text.contains(query) ||
                theme.contains(query);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher par créateur, contenu ou thème',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (_filteredQuizzes.isEmpty
                        ? const Center(
                          child: Text(
                            'Aucun quiz public trouvé correspondant à votre recherche.',
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _filteredQuizzes.length,
                          itemBuilder: (context, index) {
                            final quiz = _filteredQuizzes[index];
                            final userName =
                                quiz['userName']?.toString() ?? 'Anonyme';
                            final textPreview =
                                (quiz['text']?.toString() ?? '').length > 50
                                    ? '${quiz['text'].toString().substring(0, 50)}...'
                                    : quiz['text']?.toString() ?? '';
                            final gamesInQuiz =
                                (quiz['games'] as List<dynamic>?)
                                    ?.map(
                                      (g) => g['type'] as String? ?? 'Inconnu',
                                    )
                                    .toSet()
                                    .toList() ??
                                [];

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ExpansionTile(
                                leading: const Icon(
                                  Icons.public,
                                  color: Colors.blue,
                                ),
                                title: Text('Quiz de $userName'),
                                subtitle: Text(textPreview),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.person,
                                        color: Colors.indigo,
                                      ),
                                      tooltip: 'Voir le profil',
                                      onPressed: () {
                                        if (quiz['userId'] != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => UserProfilePage(
                                                    userId: quiz['userId'],
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.report_problem_outlined,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Signaler',
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Le quiz a été signalé aux modérateurs.',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                children: [
                                  if (gamesInQuiz.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        8,
                                      ),
                                      child: Wrap(
                                        spacing: 8.0,
                                        runSpacing: 4.0,
                                        children:
                                            gamesInQuiz
                                                .map(
                                                  (gameName) => Chip(
                                                    label: Text(gameName),
                                                    backgroundColor:
                                                        Colors.blue.shade50,
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ),
                                  const Divider(),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed:
                                              () => widget.onPlay(
                                                quiz['games'] ?? [],
                                                quiz['text'] ?? '',
                                                quiz['id'],
                                              ),
                                          icon: const Icon(Icons.play_arrow),
                                          label: const Text('Jouer (Solo)'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed:
                                              () => widget.onPlayOnline(quiz),
                                          icon: const Icon(Icons.groups),
                                          label: const Text('Jouer en Ligne'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.indigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )),
          ),
        ],
      ),
    );
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> _topPlayers = [];
  bool _isLoading = true;
  String _selectedCountry = 'Monde';
  final List<String> _countries = [
    'Monde',
    'France',
    'Belgique',
    'Suisse',
    'Canada',
    'Maroc',
    'Algérie',
  ];

  // Données du joueur actuel
  int? _myRank;
  Map<String, dynamic>? _myScoreData;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .orderBy('score', descending: true);

      if (_selectedCountry != 'Monde') {
        query = query.where('country', isEqualTo: _selectedCountry);
      }

      // Limite aux 100 premiers
      final snapshot = await query.limit(100).get();

      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      bool iAmInTop100 = false;

      final List<Map<String, dynamic>> players = [];
      for (int i = 0; i < snapshot.docs.length; i++) {
        final data = snapshot.docs[i].data() as Map<String, dynamic>;
        final isMe = snapshot.docs[i].id == currentUid;
        if (isMe) iAmInTop100 = true;

        players.add({
          'uid': snapshot.docs[i].id,
          'username': data['username'] ?? 'Inconnu',
          'score': data['score'] ?? 0,
          'isMe': isMe,
        });
      }

      // Si l'utilisateur n'est pas dans le top 100, on récupère son rang exact
      if (!iAmInTop100 && currentUid != null) {
        final myDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUid)
                .get();
        if (myDoc.exists) {
          final myData = myDoc.data()!;
          final myScore = myData['score'] ?? 0;

          Query rankQuery = FirebaseFirestore.instance
              .collection('users')
              .where('score', isGreaterThan: myScore);
          if (_selectedCountry != 'Monde') {
            rankQuery = rankQuery.where('country', isEqualTo: _selectedCountry);
          }

          final countSnapshot = await rankQuery.count().get();
          _myRank =
              countSnapshot.count! +
              1; // Rang = nombre de personnes avec un meilleur score + 1

          _myScoreData = {
            'uid': currentUid,
            'username': myData['username'] ?? 'Moi',
            'score': myScore,
            'isMe': true,
          };
        }
      } else {
        _myRank = null;
        _myScoreData = null;
      }

      if (mounted) {
        setState(() {
          _topPlayers = players;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: DropdownButton<String>(
          value: _selectedCountry,
          dropdownColor: Theme.of(context).cardColor,
          items:
              _countries
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedCountry = val);
              _loadLeaderboard();
            }
          },
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child:
                        _topPlayers.isEmpty
                            ? const Center(
                              child: Text('Aucun joueur trouvé pour ce pays.'),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: _topPlayers.length,
                              itemBuilder: (context, index) {
                                final player = _topPlayers[index];
                                final isMe = player['isMe'] == true;
                                return Card(
                                  color:
                                      isMe
                                          ? AppColors.primaryBlue.withOpacity(
                                            0.1,
                                          )
                                          : null,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: ListTile(
                                    leading: Text(
                                      '#${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    title: Text(
                                      player['username'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            isMe
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: Text(
                                      '${player['score']} pts',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    onTap:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => UserProfilePage(
                                                  userId: player['uid'],
                                                ),
                                          ),
                                        ),
                                  ),
                                );
                              },
                            ),
                  ),
                  // Ligne épinglée si le joueur n'est pas dans le top 100
                  if (_myScoreData != null && _myRank != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        child: ListTile(
                          leading: Text(
                            '#$_myRank',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          title: Text(
                            '${_myScoreData!['username']} (Vous)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Text(
                            '${_myScoreData!['score']} pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
    );
  }
}

class MyIQPage extends StatefulWidget {
  final String userId;

  const MyIQPage({super.key, required this.userId});

  @override
  State<MyIQPage> createState() => _MyIQPageState();
}

class _MyIQPageState extends State<MyIQPage> {
  double _iq = 100.0;
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _themesPerformance = {};
  List<String> _testedThemes = [];
  List<String> _untestedThemes = [];
  String _recommendation =
      "Jouez à plus de quiz pour une analyse plus approfondie !";
  List<Map<String, dynamic>> _gameHistory = [];

  List<String> _myBadges = [];

  @override
  void initState() {
    super.initState();
    _loadIQData();
  }

  Future<void> _loadIQData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get();
      if (userDoc.exists) {
        _iq = (userDoc.data()?['iq'] as num? ?? 100.0).toDouble();
        _myBadges = List<String>.from(userDoc.data()?['badges'] ?? []);
      } else {
        _iq = 100.0;
        _myBadges = [];
      }

      final statsDoc =
          await FirebaseFirestore.instance
              .collection('userStats')
              .doc(widget.userId)
              .get();
      Map<String, dynamic> statsData = {};
      if (statsDoc.exists && statsDoc.data() != null) {
        statsData = statsDoc.data()!;
      }

      final userHistorySnapshot =
          await FirebaseFirestore.instance
              .collection('userGameHistory')
              .where('userId', isEqualTo: widget.userId)
              .orderBy('timestamp', descending: true)
              .limit(20)
              .get();
      _gameHistory = userHistorySnapshot.docs.map((doc) => doc.data()).toList();

      await _analyzeThemes(statsData);
    } catch (e) {
      print('Erreur lors du chargement des données QI : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données : $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _analyzeThemes(Map<String, dynamic> statsData) async {
    _themesPerformance.clear();
    _testedThemes.clear();
    _untestedThemes.clear();
    Set<String> allPossibleThemes = {
      'Histoire',
      'Géographie',
      'Sciences',
      'Littérature',
      'Art',
      'Musique',
      'Cinéma',
      'Sports',
      'Technologie',
      'Politique',
      'Économie',
      'Animaux',
      'Nature',
      'Cuisine',
    };
    Set<String> userTestedThemes = {};

    statsData.forEach((theme, data) {
      if (data is Map<String, dynamic>) {
        _themesPerformance[theme] = data;
        userTestedThemes.add(theme);
      }
    });

    _testedThemes = userTestedThemes.toList();
    _untestedThemes =
        allPossibleThemes
            .where((theme) => !userTestedThemes.contains(theme))
            .toList();

    _generateRecommendation(statsData);
  }

  void _generateRecommendation(Map<String, dynamic> statsData) {
    if (statsData.isEmpty) {
      _recommendation =
          "Commencez à jouer pour que l'IA puisse analyser vos compétences !";
      return;
    }

    String weakTheme = '';
    double minSuccessRate = 1.1;
    String strongTheme = '';
    double maxSuccessRate = -0.1;

    statsData.forEach((theme, data) {
      if (data is Map<String, dynamic>) {
        int gamesPlayed = (data['gamesPlayed'] as num?)?.toInt() ?? 0;
        if (gamesPlayed >= 2) {
          double wsr = (data['weightedSuccessRate'] as num?)?.toDouble() ?? 0.0;
          if (wsr < minSuccessRate) {
            minSuccessRate = wsr;
            weakTheme = theme;
          }
          if (wsr > maxSuccessRate) {
            maxSuccessRate = wsr;
            strongTheme = theme;
          }
        }
      }
    });

    List<String> recommendations = [];

    if (weakTheme.isNotEmpty && minSuccessRate < 0.6) {
      recommendations.add(
        "📚 Point faible détecté en '$weakTheme' (score ajusté : ${(minSuccessRate * 100).toStringAsFixed(0)}%). Entraînez-vous davantage !",
      );
    }

    if (strongTheme.isNotEmpty &&
        maxSuccessRate >= 0.8 &&
        strongTheme != weakTheme) {
      recommendations.add(
        "⭐ Vous excellez en '$strongTheme' (score ajusté : ${(maxSuccessRate * 100).toStringAsFixed(0)}%). Continuez !",
      );
    }

    if (_untestedThemes.isNotEmpty) {
      final unexplored = _untestedThemes.take(2).join(' et ');
      recommendations.add(
        "🌐 Explorez de nouveaux thèmes : $unexplored pour améliorer votre QI global !",
      );
    }

    if (_iq >= 130) {
      recommendations.add(
        "🧠 QI exceptionnel ! Essayez des quiz de difficulté maximale pour vous challenger.",
      );
    } else if (_iq < 90) {
      recommendations.add(
        "💡 Jouez régulièrement à des quiz variés pour développer vos connaissances.",
      );
    }

    _recommendation =
        recommendations.isNotEmpty
            ? recommendations.join('\n\n')
            : "Excellent travail ! Continuez à jouer pour maintenir votre QI élevé.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // NOUVEAU : Message de bienvenue
                            Text(
                              'Bonjour ${FirebaseAuth.instance.currentUser?.displayName ?? "Joueur"} 👋',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Votre QI de culture générale',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _iq.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // --- AJOUT DE LA SECTION BADGES ---
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mes Badges Débloqués',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            AppBadges.buildBadgeGrid(_myBadges),
                          ],
                        ),
                      ),
                    ),
                    // -----------------------------------
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Analyse de vos performances',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Recommandation: $_recommendation',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const Text(
                              'Vos points forts (thèmes joués au moins 2 fois, taux de réussite > 70%) :',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _themesPerformance.isEmpty
                                ? const Text(
                                  'Aucun thème analysé pour l\'instant.',
                                )
                                : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      _themesPerformance.entries
                                          .where((entry) {
                                            int gamesPlayed =
                                                (entry.value['gamesPlayed']
                                                        as num?)
                                                    ?.toInt() ??
                                                0;
                                            if (gamesPlayed < 2) return false;
                                            double wsr =
                                                (entry.value['weightedSuccessRate']
                                                        as num?)
                                                    ?.toDouble() ??
                                                0.0;
                                            return wsr >= 0.7;
                                          })
                                          .map((entry) {
                                            double wsr =
                                                (entry.value['weightedSuccessRate']
                                                        as num?)
                                                    ?.toDouble() ??
                                                0.0;
                                            int gamesPlayed =
                                                (entry.value['gamesPlayed']
                                                        as num?)
                                                    ?.toInt() ??
                                                0;
                                            return ListTile(
                                              leading: const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                              ),
                                              title: Text(entry.key),
                                              subtitle: Text(
                                                'Taux de réussite : ${(wsr * 100).toStringAsFixed(0)}% ($gamesPlayed quiz joués)',
                                              ),
                                            );
                                          })
                                          .toList(),
                                ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const Text(
                              'Vos points à améliorer (thèmes joués au moins 2 fois, taux de réussite < 70%) :',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _themesPerformance.isEmpty
                                ? const Text(
                                  'Aucun thème analysé pour l\'instant.',
                                )
                                : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      _themesPerformance.entries
                                          .where((entry) {
                                            int gamesPlayed =
                                                (entry.value['gamesPlayed']
                                                        as num?)
                                                    ?.toInt() ??
                                                0;
                                            if (gamesPlayed < 2) return false;
                                            double wsr =
                                                (entry.value['weightedSuccessRate']
                                                        as num?)
                                                    ?.toDouble() ??
                                                0.0;
                                            return wsr < 0.7;
                                          })
                                          .map((entry) {
                                            double wsr =
                                                (entry.value['weightedSuccessRate']
                                                        as num?)
                                                    ?.toDouble() ??
                                                0.0;
                                            int gamesPlayed =
                                                (entry.value['gamesPlayed']
                                                        as num?)
                                                    ?.toInt() ??
                                                0;
                                            return ListTile(
                                              leading: const Icon(
                                                Icons.warning,
                                                color: Colors.orange,
                                              ),
                                              title: Text(entry.key),
                                              subtitle: Text(
                                                'Taux de réussite : ${(wsr * 100).toStringAsFixed(0)}% ($gamesPlayed quiz joués)',
                                              ),
                                            );
                                          })
                                          .toList(),
                                ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const Text(
                              'Thèmes non testés :',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _untestedThemes.isEmpty
                                ? const Text(
                                  'Vous avez exploré tous les thèmes connus !',
                                )
                                : Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children:
                                      _untestedThemes
                                          .map(
                                            (theme) => Chip(
                                              avatar: const Icon(
                                                Icons.new_releases,
                                                color: Colors.blue,
                                              ),
                                              label: Text(theme),
                                              backgroundColor:
                                                  Colors.blue.shade100,
                                            ),
                                          )
                                          .toList(),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class FriendsPage extends StatefulWidget {
  final String userId;
  final String playerName;
  final Function(OnlineRoomSettings, Map<String, dynamic>?) onInviteToGame;

  const FriendsPage({
    super.key,
    required this.userId,
    required this.playerName,
    required this.onInviteToGame,
  });

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _friendRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendsAndRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendsAndRequests() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get();
      final friendUids =
          (userDoc.data()?['friends'] as List<dynamic>?)?.cast<String>() ?? [];

      List<Map<String, dynamic>> loadedFriends = [];
      for (String friendUid in friendUids) {
        final friendDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(friendUid)
                .get();
        if (friendDoc.exists) {
          loadedFriends.add({
            'uid': friendDoc.id,
            'username': friendDoc.data()?['username'],
            'score': friendDoc.data()?['score'],
            'iq': friendDoc.data()?['iq'],
          });
        }
      }

      final requestsSnapshot =
          await FirebaseFirestore.instance
              .collection('friendRequests')
              .where('receiverId', isEqualTo: widget.userId)
              .where('status', isEqualTo: 'pending')
              .get();

      List<Map<String, dynamic>> loadedRequests = [];
      for (var doc in requestsSnapshot.docs) {
        final senderUid = doc.data()['senderId'];
        final senderDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(senderUid)
                .get();
        if (senderDoc.exists) {
          loadedRequests.add({
            'id': doc.id,
            'senderId': senderUid,
            'senderName': senderDoc.data()?['username'],
          });
        }
      }

      if (mounted) {
        setState(() {
          _friends = loadedFriends;
          _friendRequests = loadedRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des amis/demandes: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('username', isGreaterThanOrEqualTo: query)
              .where('username', isLessThanOrEqualTo: '$query\uf8ff')
              .limit(10)
              .get();

      final currentFriendsUids = _friends.map((f) => f['uid']).toSet();
      final currentRequestsSenderIds =
          _friendRequests.map((r) => r['senderId']).toSet();
      final currentRequestsReceiverIds = await FirebaseFirestore.instance
          .collection('friendRequests')
          .where('senderId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'pending')
          .get()
          .then((s) => s.docs.map((d) => d.data()['receiverId']).toSet());

      if (mounted) {
        setState(() {
          _searchResults =
              snapshot.docs
                  .map((doc) {
                    final data = doc.data();
                    final uid = doc.id;
                    String status = 'none';
                    if (uid == widget.userId)
                      status = 'self';
                    else if (currentFriendsUids.contains(uid))
                      status = 'friend';
                    else if (currentRequestsSenderIds.contains(uid))
                      status = 'pending_received';
                    else if (currentRequestsReceiverIds.contains(uid))
                      status = 'pending_sent';

                    return {
                      'uid': uid,
                      'username': data['username'],
                      'status': status,
                    };
                  })
                  .where((user) => user['status'] != 'self')
                  .toList();
        });
      }
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de recherche: $e')));
    }
  }

  Future<void> _sendFriendRequest(String receiverId) async {
    try {
      await FirebaseFirestore.instance.collection('friendRequests').add({
        'senderId': widget.userId,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _searchUsers(_searchController.text);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande d\'ami envoyée !')),
        );
    } catch (e) {
      print('Erreur lors de l\'envoi de la demande: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _acceptFriendRequest(String requestId, String senderId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection('friendRequests').doc(requestId),
        {'status': 'accepted'},
      );

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(senderId),
        {
          'friends': FieldValue.arrayUnion([widget.userId]),
        },
      );

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(widget.userId),
        {
          'friends': FieldValue.arrayUnion([senderId]),
        },
      );

      await batch.commit();
      _loadFriendsAndRequests();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande acceptée ! Vous êtes amis.')),
        );
    } catch (e) {
      print('Erreur lors de l\'acceptation: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _declineFriendRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('friendRequests')
          .doc(requestId)
          .update({'status': 'declined'});
      _loadFriendsAndRequests();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Demande refusée.')));
    } catch (e) {
      print('Erreur lors du refus: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _removeFriend(String friendUid) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(widget.userId),
        {
          'friends': FieldValue.arrayRemove([friendUid]),
        },
      );

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(friendUid),
        {
          'friends': FieldValue.arrayRemove([widget.userId]),
        },
      );

      final requestsBetween =
          await FirebaseFirestore.instance
              .collection('friendRequests')
              .where('senderId', whereIn: [widget.userId, friendUid])
              .where('receiverId', whereIn: [widget.userId, friendUid])
              .get();
      for (var doc in requestsBetween.docs) {
        batch.update(doc.reference, {'status': 'removed'});
      }

      await batch.commit();
      _loadFriendsAndRequests();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ami supprimé.')));
    } catch (e) {
      print('Erreur lors de la suppression d\'ami: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserProfilePage(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ajouter un ami',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Rechercher par nom d\'utilisateur',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed:
                                      () =>
                                          _searchUsers(_searchController.text),
                                ),
                              ),
                              onChanged: _searchUsers,
                            ),
                            const SizedBox(height: 16),
                            ..._searchResults.map((user) {
                              return ListTile(
                                title: Text(user['username']),
                                trailing: _buildFriendActionButton(user),
                                onTap:
                                    () => _navigateToUserProfile(user['uid']),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Demandes d\'amis reçues',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _friendRequests.isEmpty
                                ? const Text(
                                  'Aucune demande d\'ami en attente.',
                                )
                                : Column(
                                  children:
                                      _friendRequests.map((request) {
                                        return ListTile(
                                          title: Text(request['senderName']),
                                          onTap:
                                              () => _navigateToUserProfile(
                                                request['senderId'],
                                              ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.check,
                                                  color: Colors.green,
                                                ),
                                                onPressed:
                                                    () => _acceptFriendRequest(
                                                      request['id'],
                                                      request['senderId'],
                                                    ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: Colors.red,
                                                ),
                                                onPressed:
                                                    () => _declineFriendRequest(
                                                      request['id'],
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mes Amis',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _friends.isEmpty
                                ? const Text(
                                  'Vous n\'avez pas encore d\'amis. Ajoutez-en !',
                                )
                                : Column(
                                  children:
                                      _friends.map((friend) {
                                        return ListTile(
                                          leading: const Icon(Icons.person),
                                          title: Text(friend['username']),
                                          subtitle: Text(
                                            'Score: ${friend['score'] ?? 0} - QI: ${friend['iq']?.toStringAsFixed(0) ?? 100}',
                                          ),
                                          onTap:
                                              () => _navigateToUserProfile(
                                                friend['uid'],
                                              ),
                                        );
                                      }).toList(),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildFriendActionButton(Map<String, dynamic> user) {
    switch (user['status']) {
      case 'friend':
        return Chip(
          label: const Text('Ami'),
          backgroundColor: Colors.green.shade100,
        );
      case 'pending_sent':
        return Chip(
          label: const Text('Envoyée'),
          backgroundColor: Colors.orange.shade100,
        );
      case 'pending_received':
        return ElevatedButton(
          onPressed: () {
            final request = _friendRequests.firstWhere(
              (req) => req['senderId'] == user['uid'],
            );
            _acceptFriendRequest(request['id'], user['uid']);
          },
          child: const Text('Accepter'),
        );
      default:
        return ElevatedButton(
          onPressed: () => _sendFriendRequest(user['uid']),
          child: const Text('Ajouter'),
        );
    }
  }
}

class UserProfilePage extends StatelessWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil du Joueur'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Utilisateur non trouvé.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final username = userData['username'] ?? 'Inconnu';
          final score = userData['score'] ?? 0;
          final iq = (userData['iq'] as num? ?? 100.0).toDouble();

          // --- AJOUT BADGES ---
          final userBadges = List<String>.from(userData['badges'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_pin,
                          size: 60,
                          color: Colors.indigo,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  'Score: $score',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  color: Colors.yellow.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'QI: ${iq.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // --- AJOUT DE LA SECTION BADGES SUR LE PROFIL ---
                const SizedBox(height: 24),
                const Text(
                  'Badges du Joueur',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                AppBadges.buildBadgeGrid(userBadges),
                // ------------------------------------------------
                const SizedBox(height: 24),
                const Text(
                  'Quiz Publics Créés',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('quizzes')
                          .where('userId', isEqualTo: userId)
                          .where('isPublic', isEqualTo: true)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                  builder: (context, quizSnapshot) {
                    if (quizSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!quizSnapshot.hasData ||
                        quizSnapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Cet utilisateur n\'a pas de quiz publics.',
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: quizSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final quizDoc = quizSnapshot.data!.docs[index];
                        final quizData = quizDoc.data() as Map<String, dynamic>;
                        final textPreview =
                            (quizData['text']?.toString() ?? '').length > 50
                                ? '${quizData['text'].toString().substring(0, 50)}...'
                                : quizData['text']?.toString() ?? '';

                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.quiz,
                              color: Colors.indigo,
                            ),
                            title: Text(
                              'Thème: ${quizData['theme'] ?? 'Général'}',
                            ),
                            subtitle: Text(textPreview),
                            trailing: const Icon(Icons.play_arrow),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'La fonction "Jouer" depuis un profil sera bientôt disponible !',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OnlineRoomSettings {
  final int questionDuration;
  final bool waitForAllPlayers;
  final String memoryMode;
  final String showAnswerPolicy;
  final String showLeaderboardPolicy;
  final bool isPublic;
  final int maxPlayers;
  final bool disableTimer;
  final bool useGameSpecificTimers;

  final DisplayMode qcmQuestionMode;
  final DisplayMode qcmAnswerMode;

  OnlineRoomSettings({
    required this.questionDuration,
    required this.waitForAllPlayers,
    required this.memoryMode,
    required this.showAnswerPolicy,
    required this.showLeaderboardPolicy,
    required this.isPublic,
    required this.maxPlayers,
    required this.qcmQuestionMode,
    required this.qcmAnswerMode,
    this.disableTimer = false,
    this.useGameSpecificTimers = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionDuration': questionDuration,
      'waitForAllPlayers': waitForAllPlayers,
      'memoryMode': memoryMode,
      'showAnswerPolicy': showAnswerPolicy,
      'showLeaderboardPolicy': showLeaderboardPolicy,
      'isPublic': isPublic,
      'maxPlayers': maxPlayers,
      'disableTimer': disableTimer,
      'useGameSpecificTimers': useGameSpecificTimers,

      'qcmQuestionMode': qcmQuestionMode.name,
      'qcmAnswerMode': qcmAnswerMode.name,
    };
  }

  factory OnlineRoomSettings.fromMap(Map<String, dynamic> map) {
    DisplayMode displayModeFromString(String? s, DisplayMode defaultValue) {
      return DisplayMode.values.firstWhere(
        (e) => e.name == s,
        orElse: () => defaultValue,
      );
    }

    return OnlineRoomSettings(
      questionDuration: map['questionDuration'] ?? 30,
      waitForAllPlayers: map['waitForAllPlayers'] ?? true,
      memoryMode: map['memoryMode'] ?? 'turnBased',
      showAnswerPolicy: map['showAnswerPolicy'] ?? 'endOfQuestion',
      showLeaderboardPolicy: map['showLeaderboardPolicy'] ?? 'endOfGame',
      isPublic: map['isPublic'] ?? false,
      maxPlayers: map['maxPlayers'] ?? 100,
      disableTimer: map['disableTimer'] ?? false,
      useGameSpecificTimers: map['useGameSpecificTimers'] ?? false,

      qcmQuestionMode: displayModeFromString(
        map['qcmQuestionMode'],
        DisplayMode.textAndImage,
      ),
      qcmAnswerMode: displayModeFromString(
        map['qcmAnswerMode'],
        DisplayMode.textAndImage,
      ),
    );
  }
}

class OnlineOptionsPage extends StatefulWidget {
  final String playerName;
  final Function(OnlineRoomSettings, Map<String, dynamic>?, bool) onCreateRoom;
  final Function(String) onJoinRoom;
  final Future<bool> Function(String?) onFindPublicGame; // <-- Modifié
  final bool isGuest;
  final Map<String, dynamic>? initialQuiz;
  final DisplayMode qcmQuestionMode;
  final DisplayMode qcmAnswerMode;

  const OnlineOptionsPage({
    super.key,
    required this.playerName,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onFindPublicGame,
    required this.isGuest,
    this.initialQuiz,
    required this.qcmQuestionMode,
    required this.qcmAnswerMode,
  });

  @override
  State<OnlineOptionsPage> createState() => _OnlineOptionsPageState();
}

class _OnlineOptionsPageState extends State<OnlineOptionsPage> {
  bool _showCreateRoom = false;
  bool _showJoinRoom = false;
  bool _isSearchingPublic = false; // <-- Pour l'animation radar
  bool _isLoading = true;

  final _codeController = TextEditingController();

  int _questionDuration = 30;
  bool _waitForAllPlayers = true;
  String _memoryMode = 'turnBased';
  String _showAnswerPolicy = 'endOfQuestion';
  String _showLeaderboardPolicy = 'afterQuestion';
  bool _isPublic = true;
  int _maxPlayers = 10;
  bool _disableTimer = false;
  bool _useGameSpecificTimers = false;
  bool _saveToQuiz = false;

  Map<String, dynamic>? _selectedQuiz;
  List<Map<String, dynamic>> _quizzes = [];
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  void _initUser() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      try {
        UserCredential creds = await FirebaseAuth.instance.signInAnonymously();
        _currentUser = creds.user;
      } catch (e) {
        print("Erreur de connexion anonyme: $e");
      }
    }
    if (mounted) {
      if (widget.initialQuiz != null) {
        setState(() {
          _selectedQuiz = widget.initialQuiz;
          _showCreateRoom = true;
          _isLoading = false;
        });
      } else if (widget.isGuest) {
        setState(() {
          _showJoinRoom = true;
          _isLoading = false;
        });
      } else {
        _loadQuizzes();
      }
    }
  }

  Future<void> _showTimersPopup() async {
    if (_selectedQuiz == null) return;
    final games = _selectedQuiz!['games'] as List;
    bool tempSaveToQuiz = _saveToQuiz;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return AlertDialog(
              title: const Text('Temps par jeu (sec)'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: games.length,
                        itemBuilder: (context, index) {
                          final game = games[index];
                          final type = game['type'];
                          final limit = game['timeLimit']?.toString() ?? '20';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Jeu ${index + 1} - $type',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: TextFormField(
                                    initialValue: limit,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.all(8),
                                    ),
                                    onChanged: (val) {
                                      final newLimit = int.tryParse(val);
                                      if (newLimit != null) {
                                        setPopupState(() {
                                          game['timeLimit'] = newLimit;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Sauvegarder ces timers pour ce quiz',
                        ),
                        value: tempSaveToQuiz,
                        activeColor: Colors.orange,
                        onChanged: (v) {
                          setPopupState(() => tempSaveToQuiz = v ?? false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      setState(() {
        _saveToQuiz = tempSaveToQuiz;
        _useGameSpecificTimers = true;
      });
    } else if (!_useGameSpecificTimers) {
      setState(() {
        _useGameSpecificTimers = false;
      });
    }
  }

  Future<void> _loadQuizzes() async {
    if (widget.isGuest || _currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('quizzes')
              .where('userId', isEqualTo: _currentUser!.uid)
              .orderBy('timestamp', descending: true)
              .get();
      if (mounted) {
        setState(() {
          _quizzes =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['quizId'] = doc.id;
                return data;
              }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // --- Lancement de la recherche avec le Radar ---
  Future<void> _startPublicSearch() async {
    final List<String> themes = [
      'Histoire',
      'Géographie',
      'Sciences',
      'Littérature',
      'Art',
      'Musique',
      'Cinéma',
      'Sports',
      'Technologie',
      'Animaux',
      'Nature',
    ];

    final selectedTheme = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choisissez un thème',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.public,
                        color: AppColors.primaryBlue,
                      ),
                      title: const Text(
                        'N\'importe quel thème',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => Navigator.of(context).pop('any'),
                    ),
                    const Divider(),
                    ...themes.map(
                      (t) => ListTile(
                        title: Text(t),
                        onTap: () => Navigator.of(context).pop(t),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedTheme != null) {
      setState(() {
        _isSearchingPublic = true;
      });
      // Délai artificiel pour l'effet visuel du radar
      await Future.delayed(const Duration(milliseconds: 1500));

      bool found = await widget.onFindPublicGame(selectedTheme);

      if (mounted && !found) {
        setState(() {
          _isSearchingPublic = false;
        });
      }
    }
  }

  // --- WIDGETS ---

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Card(
          elevation: 6,
          shadowColor: gradient.first.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 36, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildSearchingRadar() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlue.withOpacity(0.3),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(3.5, 3.5),
                    duration: 2.seconds,
                  )
                  .fade(begin: 1, end: 0),
              Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonCyan.withOpacity(0.4),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(2.5, 2.5),
                    duration: 2.seconds,
                    delay: 500.ms,
                  )
                  .fade(begin: 1, end: 0),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.deepBlue,
                ),
                child: const Icon(Icons.public, size: 40, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 80),
          const Text(
            'Recherche d\'adversaires...',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Balayage des serveurs en cours',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: () => setState(() => _isSearchingPublic = false),
            icon: const Icon(Icons.close),
            label: const Text('Annuler'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSearchingPublic) {
      return Scaffold(body: _buildSearchingRadar());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jeu en ligne',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.deepBlue, AppColors.primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (_showCreateRoom && widget.initialQuiz == null)
              setState(() => _showCreateRoom = false);
            else if (_showJoinRoom && !widget.isGuest)
              setState(() => _showJoinRoom = false);
            else
              Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- MENU PRINCIPAL ---
            if (!widget.isGuest && !_showCreateRoom && !_showJoinRoom) ...[
              const SizedBox(height: 10),
              _buildMenuCard(
                title: 'Créer une partie',
                subtitle: 'Hébergez votre propre quiz',
                icon: Icons.add_moderator_rounded,
                gradient: [const Color(0xFF6C3FC7), const Color(0xFF4A148C)],
                onTap: () => setState(() => _showCreateRoom = true),
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                title: 'Jouer avec le monde',
                subtitle: 'Trouvez une partie publique active',
                icon: Icons.public_rounded,
                gradient: [AppColors.primaryBlue, AppColors.neonCyan],
                onTap: _startPublicSearch,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                title: 'Rejoindre un ami',
                subtitle: 'Utilisez un code d\'invitation secret',
                icon: Icons.vpn_key_rounded,
                gradient: [const Color(0xFFF39C12), const Color(0xFFD35400)],
                onTap: () => setState(() => _showJoinRoom = true),
              ),
            ],

            // --- REJOINDRE AVEC CODE ---
            if (_showJoinRoom) ...[
              StyledCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_open_rounded,
                      size: 60,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Code d\'invitation',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Entrez le code à 6 chiffres fourni par l\'hôte',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 32,
                        letterSpacing: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: "000000",
                        hintStyle: TextStyle(
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_codeController.text.trim().length == 6)
                            widget.onJoinRoom(_codeController.text.trim());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Rejoindre la partie',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
            ],

            // --- CRÉER UNE PARTIE ---
            if (_showCreateRoom && !widget.isGuest)
              ...[
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  // SECTION 1 : Le Quiz
                  StyledCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.quiz_rounded,
                              color: AppColors.primaryBlue,
                            ),
                            SizedBox(width: 10),
                            Text(
                              '1. Sélection du Quiz',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_quizzes.isEmpty && widget.initialQuiz == null)
                          const Text(
                            'Aucun quiz personnel trouvé. Créez-en un !',
                            style: TextStyle(color: Colors.red),
                          )
                        else
                          DropdownButtonFormField<Map<String, dynamic>>(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            value: _selectedQuiz,
                            hint: const Text('Choisir un quiz'),
                            isExpanded: true,
                            items:
                                widget.initialQuiz != null
                                    ? [
                                      DropdownMenuItem(
                                        value: widget.initialQuiz,
                                        child: Text(
                                          'Quiz: ${widget.initialQuiz!['text'].toString().substring(0, min(30, widget.initialQuiz!['text'].toString().length))}...',
                                        ),
                                      ),
                                    ]
                                    : _quizzes.map((quiz) {
                                      final userName =
                                          quiz['userName']?.toString() ??
                                          'Anonyme';
                                      final textPreview =
                                          (quiz['text']?.toString() ?? '')
                                                      .length >
                                                  30
                                              ? '${quiz['text'].toString().substring(0, 30)}...'
                                              : quiz['text']?.toString() ?? '';
                                      return DropdownMenuItem(
                                        value: quiz,
                                        child: Text('$userName : $textPreview'),
                                      );
                                    }).toList(),
                            onChanged:
                                widget.initialQuiz != null
                                    ? null
                                    : (v) => setState(() => _selectedQuiz = v),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SECTION 2 : Visibilité
                  StyledCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.public, color: Colors.green),
                            SizedBox(width: 10),
                            Text(
                              '2. Visibilité',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Partie Publique',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Visible par le monde entier'),
                          value: _isPublic,
                          activeColor: Colors.green,
                          onChanged: (v) => setState(() => _isPublic = v),
                        ),
                        const Divider(),
                        Text(
                          'Joueurs maximum : $_maxPlayers',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Slider(
                          value: _maxPlayers.toDouble(),
                          min: 2,
                          max: 100,
                          divisions: 98,
                          activeColor: Colors.green,
                          onChanged:
                              (v) => setState(() => _maxPlayers = v.toInt()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SECTION 3 : Règles
                  StyledCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.rule_rounded, color: Colors.orange),
                            SizedBox(width: 10),
                            Text(
                              '3. Règles du jeu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Désactiver le timer'),
                          subtitle: const Text('Jouer sans limite de temps'),
                          value: _disableTimer,
                          activeColor: Colors.orange,
                          onChanged:
                              (v) => setState(() {
                                _disableTimer = v;
                                if (v) _useGameSpecificTimers = false;
                              }),
                        ),
                        if (!_disableTimer) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Temps par jeu'),
                            subtitle: const Text(
                              'Personnaliser le timer pour chaque jeu sélectionné',
                            ),
                            value: _useGameSpecificTimers,
                            activeColor: Colors.orange,
                            onChanged: (v) {
                              if (v) {
                                if (_selectedQuiz == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Veuillez d\'abord sélectionner un quiz !',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                // Ouvre immédiatement la fenêtre de réglage des timers lors de l'activation
                                _showTimersPopup();
                              } else {
                                setState(() => _useGameSpecificTimers = false);
                              }
                            },
                          ),
                          if (_useGameSpecificTimers &&
                              _selectedQuiz != null) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _showTimersPopup,
                                icon: const Icon(Icons.timer),
                                label: const Text(
                                  'Modifier les timers spécifiques',
                                ),
                              ),
                            ),
                          ],
                          if (!_useGameSpecificTimers) ...[
                            Text(
                              'Temps global par question : ${_questionDuration}s',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: _questionDuration.toDouble(),
                              min: 10,
                              max: 120,
                              divisions: 11,
                              activeColor: Colors.orange,
                              onChanged:
                                  (v) => setState(
                                    () => _questionDuration = v.toInt(),
                                  ),
                            ),
                          ],
                        ],
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Attendre tous les joueurs'),
                          subtitle: const Text(
                            'Passe à la suite si tout le monde a répondu',
                          ),
                          value: _waitForAllPlayers,
                          activeColor: Colors.orange,
                          onChanged:
                              (v) => setState(() => _waitForAllPlayers = v),
                        ),
                        const Divider(),
                        const Text(
                          'Afficher les réponses :',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Immédiat',
                                  style: TextStyle(fontSize: 13),
                                ),
                                value: 'immediate',
                                groupValue: _showAnswerPolicy,
                                onChanged:
                                    (v) =>
                                        setState(() => _showAnswerPolicy = v!),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Fin chrono',
                                  style: TextStyle(fontSize: 13),
                                ),
                                value: 'endOfQuestion',
                                groupValue: _showAnswerPolicy,
                                onChanged:
                                    (v) =>
                                        setState(() => _showAnswerPolicy = v!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BOUTON VALIDER
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.rocket_launch_rounded),
                      label: const Text(
                        'Créer et Lancer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed:
                          _selectedQuiz == null
                              ? null
                              : () {
                                final settings = OnlineRoomSettings(
                                  questionDuration: _questionDuration,
                                  waitForAllPlayers: _waitForAllPlayers,
                                  memoryMode: _memoryMode,
                                  showAnswerPolicy: _showAnswerPolicy,
                                  showLeaderboardPolicy: _showLeaderboardPolicy,
                                  isPublic: _isPublic,
                                  maxPlayers: _maxPlayers,
                                  qcmQuestionMode: widget.qcmQuestionMode,
                                  qcmAnswerMode: widget.qcmAnswerMode,
                                  disableTimer: _disableTimer,
                                  useGameSpecificTimers: _useGameSpecificTimers,
                                );
                                widget.onCreateRoom(
                                  settings,
                                  _selectedQuiz!,
                                  _saveToQuiz,
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.quizPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ].animate().fadeIn().moveY(begin: 20),
          ],
        ),
      ),
    );
  }
}

class WaitingRoomPage extends StatefulWidget {
  final String roomId, inviteCode, playerName;
  final bool isHost;
  final int maxPlayers;
  final bool isGuest;

  const WaitingRoomPage({
    super.key,
    required this.roomId,
    required this.inviteCode,
    required this.isHost,
    required this.playerName,
    required this.maxPlayers,
    required this.isGuest,
  });
  @override
  State<WaitingRoomPage> createState() => _WaitingRoomPageState();
}

class _WaitingRoomPageState extends State<WaitingRoomPage>
    with WidgetsBindingObserver {
  late StreamSubscription<DocumentSnapshot> _roomSubscription;
  Map<String, dynamic> _players = {};
  bool _isMounted = false;
  Timer? _countdownTimer;
  int _countdown = 10;
  Map<String, dynamic>? _roomData;
  bool _gameStarted = false; // Verrou pour éviter la navigation double

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addObserver(this);
    _listenToRoom();
  }

  void _listenToRoom() {
    _roomSubscription = FirebaseFirestore.instance
        .collection('onlineRooms')
        .doc(widget.roomId)
        .snapshots()
        .listen(
          (snapshot) {
            if (!_isMounted) return;

            if (!snapshot.exists) {
              _handleRoomClosure();
              return;
            }

            final data = snapshot.data()!;
            _roomData = data;
            final newPlayers = Map<String, dynamic>.from(data['players'] ?? {});

            if (_players.isNotEmpty) {
              final oldPlayerNames = _players.keys.toSet();
              final newPlayerNames = newPlayers.keys.toSet();

              final leftPlayers = oldPlayerNames.difference(newPlayerNames);
              for (String pName in leftPlayers) {
                if (pName != widget.playerName && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🏃 $pName a quitté la partie.'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }

              final joinedPlayers = newPlayerNames.difference(oldPlayerNames);
              for (String pName in joinedPlayers) {
                if (pName != widget.playerName && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('👋 $pName a rejoint la partie.'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            }

            if (mounted)
              setState(() {
                _players = newPlayers;
              });

            // La navigation se fait quand started passe à true
            if (data['started'] == true) {
              _navigateToGame();
              return;
            }

            if (data['active'] == false && data['started'] == false) {
              _handleRoomClosure(
                message: 'La partie a été arrêtée par l\'hôte',
              );
              return;
            }

            // Gestion du compte à rebours synchronisé via Firestore
            if (data.containsKey('countdownStartTime')) {
              final startTime =
                  (data['countdownStartTime'] as Timestamp).toDate();
              final secondsPassed =
                  DateTime.now().difference(startTime).inSeconds;
              final newCountdown = max(0, 10 - secondsPassed);

              if (mounted)
                setState(() {
                  _countdown = newCountdown;
                });

              // Seul l'hôte démarre la partie quand le compte à rebours atteint 0
              if (newCountdown <= 0 &&
                  widget.isHost &&
                  _countdownTimer == null) {
                _startGame();
              }
            } else {
              if (mounted)
                setState(() {
                  _countdown = 10;
                });
            }

            // Gestion du démarrage automatique côté hôte quand la salle est pleine
            if (widget.isHost) {
              if (_players.length >= widget.maxPlayers &&
                  _countdownTimer == null &&
                  !data.containsKey('countdownStartTime')) {
                _startCountdown();
              } else if (_players.length < widget.maxPlayers &&
                  _countdownTimer != null) {
                _cancelCountdown();
              }
            }
          },
          onError: (error) {
            print("Erreur lors de l'écoute de la salle: $error");
            if (_isMounted)
              _handleRoomClosure(message: 'Erreur de connexion à la salle.');
          },
        );
  }

  void _startCountdown() async {
    if (!widget.isHost) return;

    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('onlineRooms')
            .doc(widget.roomId)
            .get();
    if (snapshot.exists &&
        (snapshot.data() as Map<String, dynamic>).containsKey(
          'countdownStartTime',
        )) {
    } else {
      await FirebaseFirestore.instance
          .collection('onlineRooms')
          .doc(widget.roomId)
          .update({'countdownStartTime': FieldValue.serverTimestamp()});
    }

    _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isMounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 1) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        timer.cancel();
        _startGame();
      }
    });
  }

  void _cancelCountdown() {
    if (!widget.isHost) return;

    _countdownTimer?.cancel();
    _countdownTimer = null;
    FirebaseFirestore.instance
        .collection('onlineRooms')
        .doc(widget.roomId)
        .update({'countdownStartTime': FieldValue.delete()});
    if (mounted)
      setState(() {
        _countdown = 10;
      });
  }

  void _navigateToGame() {
    if (!_isMounted || _gameStarted) return;
    _gameStarted = true;
    _roomSubscription.cancel();
    _countdownTimer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => OnlineGamePage(
              roomId: widget.roomId,
              isHost: widget.isHost,
              playerName: widget.playerName,
              isGuest: widget.isGuest,
              quizText: _roomData?['quizText'],

              gamesPlayed: _roomData?['games'],
            ),
      ),
    );
  }

  void _handleRoomClosure({
    String message = 'La salle n\'existe plus ou a été fermée.',
  }) {
    if (!_isMounted || _gameStarted) return;
    _roomSubscription.cancel();
    _countdownTimer?.cancel();
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);
    _roomSubscription.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _quickLeaveOnAppKill();
    }
  }

  void _quickLeaveOnAppKill() {
    try {
      if (widget.isHost) {
        FirebaseFirestore.instance
            .collection('onlineRooms')
            .doc(widget.roomId)
            .update({'active': false});
      } else {
        FirebaseFirestore.instance
            .collection('onlineRooms')
            .doc(widget.roomId)
            .update({
              FieldPath(['players', widget.playerName]): FieldValue.delete(),
            });
      }
    } catch (e) {
      // Échec silencieux, le Heartbeat fera le travail de toute façon.
    }
  }

  void _startGame() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (!widget.isHost) return;
    // Utiliser une transaction pour éviter les doubles démarrages
    final roomRef = FirebaseFirestore.instance
        .collection('onlineRooms')
        .doc(widget.roomId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snap = await transaction.get(roomRef);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if (data['started'] == true) return; // Déjà démarré
      transaction.update(roomRef, {'started': true});
    });
  }

  void _leaveRoom() async {
    _roomSubscription.cancel();
    if (widget.isHost) {
      await FirebaseFirestore.instance
          .collection('onlineRooms')
          .doc(widget.roomId)
          .update({'active': false});
    } else {
      await FirebaseFirestore.instance
          .collection('onlineRooms')
          .doc(widget.roomId)
          .update({
            FieldPath(['players', widget.playerName]): FieldValue.delete(),
          });
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    bool isFull = _players.length == widget.maxPlayers;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leaveRoom();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Salle d\'attente'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _leaveRoom,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Code d\'invitation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SelectableText(
                            widget.inviteCode,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: widget.inviteCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copié !')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Joueurs (${_players.length}/${widget.maxPlayers})',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Card(
                  child: ListView(
                    children:
                        _players.entries.map((entry) {
                          final playerName = entry.key;
                          final playerData =
                              entry.value as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(
                              playerName,
                              style: TextStyle(
                                fontWeight:
                                    playerName == widget.playerName
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            trailing:
                                playerData['isHost'] == true
                                    ? const Chip(
                                      label: Text('Hôte'),
                                      backgroundColor: Colors.amber,
                                    )
                                    : null,
                          );
                        }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (isFull || (_countdownTimer != null))
                Column(
                  children: [
                    Text(
                      'La partie ${isFull ? 'est pleine !' : ''} Démarrage dans...',
                      style: const TextStyle(fontSize: 16, color: Colors.green),
                    ),
                    Text(
                      '$_countdown',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else if (widget.isHost)
                ElevatedButton(
                  onPressed: _players.length >= 2 ? _startCountdown : null,
                  child: const Text('Démarrer la partie (min 2 joueurs)'),
                )
              else
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('En attente de l\'hôte ou d\'autres joueurs...'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum GamePhase { playing, showingResult, showingLeaderboard }

class OnlineGamePage extends StatefulWidget {
  final String roomId, playerName;
  final bool isHost;
  final bool isGuest;
  final String? quizText;
  final List<dynamic>? gamesPlayed;

  const OnlineGamePage({
    super.key,
    required this.roomId,
    required this.isHost,
    required this.playerName,
    required this.isGuest,
    this.quizText,
    this.gamesPlayed,
  });
  @override
  State<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends State<OnlineGamePage>
    with WidgetsBindingObserver {
  late StreamSubscription<DocumentSnapshot> _roomSubscription;
  bool _isMounted = false;
  List<dynamic> _games = [];
  Map<String, dynamic> _players = {};
  OnlineRoomSettings? _settings;
  Map<String, dynamic> _gameState = {};
  bool _localAnswerSubmitted = false;
  String _feedback = '';
  Timer? _timer;
  final ValueNotifier<int> _remainingTime = ValueNotifier<int>(0);
  final _answerController = TextEditingController();

  GamePhase _phase = GamePhase.playing;
  bool _isAdvancing = false;

  List<Map<String, dynamic>> _memoryCards = [];
  List<int> _flippedCardIndexes = [];
  String? _memoryTurnPlayer;
  bool _isMemoryBusy = false;

  String? _hangmanCurrentPlayer;
  String? _motMystereCurrentPlayer;

  Map<String, String?> _onlineMatches = {};
  List<String>? _chronologyEvents;
  int _currentChronologyIndex = -1;
  int _currentAnagramIndex = -1;
  String? _currentAnagram;
  bool _isMatchSubmitted = false;

  // Suivi du nombre de joueurs actifs pour gérer les déconnexions
  int _lastKnownPlayerCount = 0;
  bool _isNavigatingToResults = false;

  final ValueNotifier<int> _quizEclairTimeLeft = ValueNotifier<int>(8);
  String? _quizEclairSelectedAnswer;
  bool _quizEclairShowHint = false;

  bool _gameHintVisible = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addObserver(this);
    _listenToRoom();
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);
    _roomSubscription.cancel();
    _timer?.cancel();
    _answerController.dispose();
    _quizEclairTimeLeft.dispose();
    _remainingTime.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _quickLeaveOnAppKill();
    }
  }

  void _quickLeaveOnAppKill() {
    try {
      if (widget.isHost) {
        FirebaseFirestore.instance
            .collection('onlineRooms')
            .doc(widget.roomId)
            .update({'active': false});
      } else {
        FirebaseFirestore.instance
            .collection('onlineRooms')
            .doc(widget.roomId)
            .update({
              FieldPath(['players', widget.playerName]): FieldValue.delete(),
            });
      }
    } catch (e) {
      // Échec silencieux, le Heartbeat fera le travail de toute façon.
    }
  }

  void _listenToRoom() {
    _roomSubscription = FirebaseFirestore.instance
        .collection('onlineRooms')
        .doc(widget.roomId)
        .snapshots()
        .listen(
          (snapshot) {
            if (!_isMounted) return;

            if (!snapshot.exists || snapshot.data()?['active'] == false) {
              if (mounted && !_isNavigatingToResults) {
                _navigateToResultsPage(
                  Map<String, dynamic>.from(
                    (snapshot.data()?['players'] as Map<String, dynamic>?) ??
                        (_players.isNotEmpty ? _players : {}),
                  ),
                );
              }
              return;
            }

            final data = snapshot.data()!;
            final newGameState =
                data['gameState'] as Map<String, dynamic>? ?? {};
            final oldGameIndex = _gameState['currentGameIndex'] as int? ?? -1;
            final newGameIndex = newGameState['currentGameIndex'] as int? ?? 0;

            final newPlayers = Map<String, dynamic>.from(data['players'] ?? {});
            final int newPlayerCount = newPlayers.length;

            if (_players.isNotEmpty) {
              final oldPlayerNames = _players.keys.toSet();
              final newPlayerNames = newPlayers.keys.toSet();

              final leftPlayers = oldPlayerNames.difference(newPlayerNames);
              for (String pName in leftPlayers) {
                if (pName != widget.playerName && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🏃 $pName a quitté la partie.'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }

              final joinedPlayers = newPlayerNames.difference(oldPlayerNames);
              for (String pName in joinedPlayers) {
                if (pName != widget.playerName && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('👋 $pName a rejoint la partie.'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            }

            if (mounted)
              setState(() {
                _games = data['games'] as List<dynamic>? ?? [];
                _players = newPlayers;
                _settings = OnlineRoomSettings.fromMap(data['settings'] ?? {});
                _gameState = newGameState;

                if (_gameState.containsKey('memoryState') &&
                    _gameState['memoryState'] != null) {
                  _memoryCards = List<Map<String, dynamic>>.from(
                    _gameState['memoryState']['cards'] ?? [],
                  );
                  _flippedCardIndexes = List<int>.from(
                    _gameState['memoryState']['flipped'] ?? [],
                  );
                  _memoryTurnPlayer =
                      _gameState['memoryState']['currentPlayerName'];
                } else {
                  _memoryCards = [];
                  _flippedCardIndexes = [];
                  _memoryTurnPlayer = null;
                }

                if (_gameState.containsKey('hangmanState') &&
                    _gameState['hangmanState'] != null) {
                  _hangmanCurrentPlayer =
                      _gameState['hangmanState']['currentPlayerName'];
                } else {
                  _hangmanCurrentPlayer = null;
                }

                if (_gameState.containsKey('motMystereState') &&
                    _gameState['motMystereState'] != null) {
                  _motMystereCurrentPlayer =
                      _gameState['motMystereState']['currentPlayerName'];
                } else {
                  _motMystereCurrentPlayer = null;
                }
              });

            // Si un joueur a quitté pendant la partie, vérifier si on peut avancer
            if (widget.isHost &&
                newPlayerCount < _lastKnownPlayerCount &&
                newPlayerCount > 0) {
              _checkIfAllRemainingPlayersAnswered();
              _handleDisconnectInTurnBasedGame(newPlayers, newGameState);
            }
            _lastKnownPlayerCount = newPlayerCount;

            if (oldGameIndex != newGameIndex) {
              _initializeNewQuestion();
              if (widget.isHost &&
                  _games.isNotEmpty &&
                  newGameIndex < _games.length) {
                final gameType = _games[newGameIndex]['type'] as String?;
                if (gameType != null) {
                  if (gameType.contains('Pendu') &&
                      newGameState['hangmanState'] == null) {
                    _initializeHangmanInFirestore();
                  } else if (gameType.contains('Memory') &&
                      newGameState['memoryState'] == null) {
                    _initializeMemoryInFirestore();
                  } else if (gameType.contains('Relier') &&
                      newGameState['matchState'] == null) {
                    _initializeMatchGameInFirestore();
                  } else if (gameType.contains('Mot Mystère') &&
                      newGameState['motMystereState'] == null) {
                    _initializeMotMystereInFirestore();
                  }
                }
              }
            }

            if (widget.isHost && !_isAdvancing) {
              final canGoToNext =
                  _gameState['canGoToNextQuestion'] as bool? ?? false;
              if (canGoToNext) {
                _isAdvancing = true;
                _scheduleNextQuestionPhase();
              }
            }
          },
          onError: (error) {
            print("Erreur lors de l'écoute de la salle: $error");
            if (_isMounted && !_isNavigatingToResults)
              _navigateToResultsPage(_players);
          },
        );
  }

  // Vérifie si tous les joueurs restants ont répondu (après déconnexion d'un joueur)
  void _checkIfAllRemainingPlayersAnswered() {
    if (!widget.isHost || _isAdvancing) return;
    final playersAnswered =
        (_gameState['playersAnswered'] as List<dynamic>?) ?? [];
    final gameType =
        _games.isNotEmpty && _gameState['currentGameIndex'] != null
            ? (_games[_gameState['currentGameIndex']]['type'] as String? ?? '')
            : '';
    // Pour les jeux à tour par tour, ne pas forcer l'avancement
    if (gameType.contains('Memory') ||
        gameType.contains('Pendu') ||
        gameType.contains('Mot Mystère') ||
        gameType.contains('Mot Mystere') ||
        gameType.contains('Relier'))
      return;

    final allRemainingAnswered = _players.keys.every(
      (p) => playersAnswered.contains(p),
    );
    if (allRemainingAnswered && _players.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('onlineRooms')
          .doc(widget.roomId)
          .update({'gameState.canGoToNextQuestion': true});
    }
  }

  void _initializeNewQuestion() {
    if (!_isMounted) return;
    setState(() {
      _localAnswerSubmitted = false;
      _isMatchSubmitted = false;
      _onlineMatches.clear();
      _feedback = '';
      _answerController.clear();
      _phase = GamePhase.playing;
      _isAdvancing = false;
      _isMemoryBusy = false;
      _quizEclairTimeLeft.value = 8;
      _quizEclairSelectedAnswer = null;
      _quizEclairShowHint = false;

      _gameHintVisible = false;
    });

    _timer?.cancel();
    if (_settings == null ||
        _games.isEmpty ||
        _gameState['currentGameIndex'] == null)
      return;

    final currentIndex = _gameState['currentGameIndex'] as int? ?? 0;
    if (currentIndex >= _games.length) return;
    final gameType = _games[currentIndex]['type'] as String? ?? '';

    // Les jeux à tour par tour n'ont pas de timer global
    final bool isTimedGame =
        !gameType.contains('Memory') &&
        !gameType.contains('Pendu') &&
        !gameType.contains('Mot Mystère');

    if (isTimedGame) {
      if (_settings!.disableTimer) {
        _remainingTime.value = 0;
      } else if (_settings!.useGameSpecificTimers &&
          _games[currentIndex]['timeLimit'] != null) {
        final rawLimit = _games[currentIndex]['timeLimit'];
        _remainingTime.value =
            (rawLimit is int)
                ? rawLimit
                : int.tryParse(rawLimit.toString()) ??
                    _settings!.questionDuration;
      } else if (gameType.contains('Quiz Éclair')) {
        _remainingTime.value = 8;
      } else {
        _remainingTime.value = _settings!.questionDuration;
      }

      if (_remainingTime.value > 0) {
        _startTimer();
      }
    } else {
      _remainingTime.value = 0;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isMounted) {
        timer.cancel();
        return;
      }
      if (_remainingTime.value > 0) {
        if (mounted) {
          _remainingTime.value--;
        }
      } else {
        timer.cancel();

        final currentIndex = _gameState['currentGameIndex'] as int? ?? 0;
        if (currentIndex >= _games.length) return;
        final gameType = _games[currentIndex]['type'] as String? ?? '';

        // Soumettre automatiquement si non soumis (jeux standards)
        if (!_localAnswerSubmitted &&
            !gameType.contains('Memory') &&
            !gameType.contains('Pendu') &&
            !gameType.contains('Relier') &&
            !gameType.contains('Mot Mystère') &&
            !gameType.contains('Mot Mystere') &&
            !gameType.contains('Estimation')) {
          _submitAnswer('', isCorrect: false);
        } else if (gameType.contains('Relier') && !_isMatchSubmitted) {
          _submitMatches();
        }

        // L'hôte vérifie si on peut passer à la suite
        if (widget.isHost && !_isAdvancing) {
          final playersAnswered =
              (_gameState['playersAnswered'] as List<dynamic>?) ?? [];
          // Considérer seulement les joueurs actifs (présents dans la room)
          final activePlayers = _players.keys.toList();
          bool allAnswered = activePlayers.every(
            (p) => playersAnswered.contains(p),
          );

          if (_settings?.waitForAllPlayers == false || allAnswered) {
            FirebaseFirestore.instance
                .collection('onlineRooms')
                .doc(widget.roomId)
                .update({'gameState.canGoToNextQuestion': true});
          } else {
            // Attendre encore un peu (5s max) pour les retardataires
            Future.delayed(const Duration(seconds: 5), () {
              if (_isMounted && !_isAdvancing && widget.isHost) {
                FirebaseFirestore.instance
                    .collection('onlineRooms')
                    .doc(widget.roomId)
                    .update({'gameState.canGoToNextQuestion': true});
              }
            });
          }
        }
      }
    });
  }

  void _scheduleNextQuestionPhase() {
    setState(() {
      _phase = GamePhase.showingResult;
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (!_isMounted) return;
      if (_settings!.showLeaderboardPolicy == 'afterQuestion' &&
          _gameState['currentGameIndex'] < _games.length - 1) {
        setState(() {
          _phase = GamePhase.showingLeaderboard;
        });
        Future.delayed(const Duration(seconds: 5), () {
          if (_isMounted) _goToNextQuestion();
        });
      } else {
        _goToNextQuestion();
      }
    });
  }

  Future<void> _submitAnswer(
    String? userAnswer, {
    required bool isCorrect,
  }) async {
    if (_localAnswerSubmitted) return;
    setState(() {
      _localAnswerSubmitted = true;
      if (_settings?.showAnswerPolicy == 'immediate') {
        _feedback =
            isCorrect
                ? 'Bonne réponse !' + (_gameHintVisible ? ' (+5 pts)' : '')
                : 'Mauvaise réponse...';
      } else {
        _feedback = 'Réponse enregistrée !';
      }
    });

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance
          .collection('onlineRooms')
          .doc(widget.roomId);
      DocumentSnapshot snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      var data = snapshot.data() as Map<String, dynamic>;
      var players = Map<String, dynamic>.from(data['players']);
      var gameState = Map<String, dynamic>.from(data['gameState']);
      var playersAnswered = List<dynamic>.from(
        gameState['playersAnswered'] ?? [],
      );

      if (isCorrect) {
        int pointsToAdd = _gameHintVisible ? 5 : 10;
        players[widget.playerName]['score'] =
            (players[widget.playerName]['score'] ?? 0) + pointsToAdd;
      }

      if (!playersAnswered.contains(widget.playerName)) {
        playersAnswered.add(widget.playerName);
      }
      gameState['playersAnswered'] = playersAnswered;

      if (_settings?.waitForAllPlayers == true &&
          playersAnswered.length >= players.length) {
        gameState['canGoToNextQuestion'] = true;
      }

      transaction.update(roomRef, {'players': players, 'gameState': gameState});
    });
  }

  Future<void> _submitMatches() async {
    if (_isMatchSubmitted) return;
    setState(() {
      _isMatchSubmitted = true;
      _feedback = 'Associations enregistrées !';
    });

    final game = _games[_gameState['currentGameIndex']];
    final correctPairs =
        (game['pairs'] as List<dynamic>?)?.cast<Map<dynamic, dynamic>>() ?? [];

    int correctCount = 0;
    for (var correctPair in correctPairs) {
      final definition = correctPair['definition'].toString();
      final correctWord = correctPair['word'].toString();
      if (_onlineMatches.containsKey(definition) &&
          _onlineMatches[definition] == correctWord) {
        correctCount++;
      }
    }

    final isCorrect = correctCount == correctPairs.length;
    final points = isCorrect ? 10 : 0;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance
          .collection('onlineRooms')
          .doc(widget.roomId);
      DocumentSnapshot snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      var data = snapshot.data() as Map<String, dynamic>;
      var players = Map<String, dynamic>.from(data['players']);
      var gameState = Map<String, dynamic>.from(data['gameState']);
      var playersAnswered = List<dynamic>.from(
        gameState['playersAnswered'] ?? [],
      );

      players[widget.playerName]['score'] =
          (players[widget.playerName]['score'] ?? 0) + points;

      if (!playersAnswered.contains(widget.playerName)) {
        playersAnswered.add(widget.playerName);
      }
      gameState['playersAnswered'] = playersAnswered;

      if (_settings?.waitForAllPlayers == true &&
          playersAnswered.length >= players.length) {
        gameState['canGoToNextQuestion'] = true;
      }

      transaction.update(roomRef, {'players': players, 'gameState': gameState});
    });
  }

  Future<void> _goToNextQuestion() async {
    if (!widget.isHost) return;

    final int currentGameIndex = _gameState['currentGameIndex'] ?? 0;
    if (currentGameIndex >= _games.length - 1) {
      await FirebaseFirestore.instance
          .collection('onlineRooms')
          .doc(widget.roomId)
          .update({'active': false});
    } else {
      await FirebaseFirestore.instance
          .collection('onlineRooms')
          .doc(widget.roomId)
          .update({
            'gameState.currentGameIndex': FieldValue.increment(1),
            'gameState.playersAnswered': [],
            'gameState.canGoToNextQuestion': false,
            'gameState.memoryState': null,
            'gameState.hangmanState': null,
            'gameState.matchState': null,
            'gameState.motMystereState': null,
          });
    }
    // Réinitialiser le verrou d'avancement côté hôte
    if (mounted)
      setState(() {
        _isAdvancing = false;
      });
  }

  void _navigateToResultsPage(Map<String, dynamic> finalPlayers) {
    if (!_isMounted || _isNavigatingToResults) return;
    _isNavigatingToResults = true;
    _roomSubscription.cancel();
    _timer?.cancel();
    final scores = {
      for (var p in finalPlayers.entries) p.key: (p.value['score'] ?? 0) as int,
    };
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => GameResultsPage(
              playerScores: scores,
              isHost: widget.isHost,
              roomId: widget.roomId,
              playerName: widget.isGuest ? null : widget.playerName,
              quizText: widget.quizText,
              gamesPlayed: widget.gamesPlayed,
            ),
      ),
    );
  }

  void _initializeHangmanInFirestore() async {
    if (!widget.isHost) return;

    final playersList = _players.keys.toList();
    if (playersList.isEmpty) return;

    final game = _games[_gameState['currentGameIndex']];
    final word = (game['word']?.toString() ?? '').toUpperCase();

    await FirebaseFirestore.instance
        .collection('onlineRooms')
        .doc(widget.roomId)
        .update({
          'gameState.hangmanState': {
            'currentPlayerName': playersList.first,
            'usedLetters': [],
            'mistakes': 0,
            'gameOver': false,
            'wordToGuess': word,
          },
        });
  }

  Future<void> _guessLetterOnline(String letter) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance
          .collection('onlineRooms')
          .doc(widget.roomId);
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      var data = snapshot.data() as Map<String, dynamic>;
      var players = Map<String, dynamic>.from(data['players']);
      var gameState = Map<String, dynamic>.from(data['gameState']);
      var hState = Map<String, dynamic>.from(gameState['hangmanState'] ?? {});

      if (hState['gameOver'] == true ||
          hState['currentPlayerName'] != widget.playerName)
        return;

      var usedLetters = List<String>.from(hState['usedLetters'] ?? []);
      int mistakes = hState['mistakes'] ?? 0;
      final word = (hState['wordToGuess']?.toString() ?? '').toUpperCase();
      final currentPlayerName = hState['currentPlayerName'];

      if (usedLetters.contains(letter)) return;
      usedLetters.add(letter);

      bool letterFound = word.contains(letter);
      if (!letterFound) {
        mistakes++;
      }

      String currentDisplay =
          word
              .split('')
              .map((char) => usedLetters.contains(char) ? char : '_')
              .join();
      bool isWordGuessed = !currentDisplay.contains('_');

      if (isWordGuessed) {
        hState['gameOver'] = true;
        if (players.containsKey(currentPlayerName) &&
            players[currentPlayerName] != null) {
          players[currentPlayerName]['score'] =
              (players[currentPlayerName]['score'] ?? 0) + 20;
        }
      } else if (mistakes >= 6) {
        hState['gameOver'] = true;
      }

      final playerNames = players.keys.toList();
      final currentIndex = playerNames.indexOf(currentPlayerName);
      final nextIndex = (currentIndex + 1) % playerNames.length;

      // Mise à jour propre de l'objet global
      hState['usedLetters'] = usedLetters;
      hState['mistakes'] = mistakes;
      if (hState['gameOver'] != true) {
        hState['currentPlayerName'] = playerNames[nextIndex];
      }

      gameState['hangmanState'] = hState;
      if (hState['gameOver'] == true) {
        gameState['canGoToNextQuestion'] = true;
      }

      transaction.update(roomRef, {'players': players, 'gameState': gameState});
    });
  }

  void _initializeMemoryInFirestore() async {
    if (!widget.isHost) return;

    final game = _games[_gameState['currentGameIndex']];
    final String displayMode = game['displayMode'] ?? 'wordToDefinition';
    List<Map<String, dynamic>> initialCards = [];
    int idCounter = 0;

    if (displayMode == 'imagePair') {
      final items =
          (game['items'] as List<dynamic>?)?.cast<Map<dynamic, dynamic>>() ??
          [];
      for (var item in items) {
        final img =
            (item['image_url'] ?? item['image_description'] ?? '').toString();
        final text = (item['text_label'] ?? item['text'] ?? '').toString();
        initialCards.add({
          'id': idCounter,
          'value': img.isNotEmpty ? img : text,
          'matched': false,
          'flipped': false,
        });
        initialCards.add({
          'id': idCounter,
          'value': text.isNotEmpty ? text : img,
          'matched': false,
          'flipped': false,
        });
        idCounter++;
      }
    } else {
      final pairsData =
          (game['pairs'] as List<dynamic>?)?.cast<Map<dynamic, dynamic>>() ??
          [];
      for (var pair in pairsData) {
        String value1 =
            displayMode == 'definitionToImage'
                ? (pair['definition'] ?? '').toString()
                : (pair['word'] ?? '').toString();
        String value2 =
            displayMode == 'definitionToImage'
                ? (pair['image_url'] ?? pair['image_description'] ?? '')
                    .toString()
                : (pair['definition'] ?? '').toString();
        initialCards.add({
          'id': idCounter,
          'value': value1,
          'matched': false,
          'flipped': false,
        });
        initialCards.add({
          'id': idCounter,
          'value': value2,
          'matched': false,
          'flipped': false,
        });
        idCounter++;
      }
    }
    initialCards.shuffle();

    final playersList = _players.keys.toList();

    await FirebaseFirestore.instance
        .collection('onlineRooms')
        .doc(widget.roomId)
        .update({
          'gameState.memoryState': {
            'cards': initialCards,
            'flipped': [], // Gardé par sécurité
            'playerFlipped': {}, // <-- NOUVEAU: Suivi indépendant par joueur
            'currentPlayerName': playersList.first,
            'gameOver': false,
            'status': 'playing',
          },
        });
  }

  Future<void> _flipCardOnline(int index) async {
    final memoryState = _gameState['memoryState'] as Map<String, dynamic>?;

    if (_isMemoryBusy ||
        memoryState == null ||
        memoryState['gameOver'] == true) {
      return;
    }

    final settings = _settings!;
    final isMyTurn = memoryState['currentPlayerName'] == widget.playerName;

    if (settings.memoryMode == 'turnBased' &&
        (!isMyTurn || memoryState['status'] == 'checking'))
      return;
    if (_memoryCards[index]['flipped'] == true) return;

    setState(() {
      _isMemoryBusy = true;
    });

    bool isSecondCard = false;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance
          .collection('onlineRooms')
          .doc(widget.roomId);
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      var data = snapshot.data() as Map<String, dynamic>;
      var gameState = Map<String, dynamic>.from(data['gameState']);
      var mState = Map<String, dynamic>.from(gameState['memoryState'] ?? {});
      List<dynamic> currentCards = List<dynamic>.from(mState['cards']);

      // Utilisation du tableau propre au joueur
      var playerFlipped = Map<String, dynamic>.from(
        mState['playerFlipped'] ?? {},
      );
      List<int> myFlipped = List<int>.from(
        playerFlipped[widget.playerName] ?? [],
      );

      if (myFlipped.length >= 2) return; // Sécurité anti-spam
      if (currentCards[index]['flipped'] == true ||
          currentCards[index]['matched'] == true)
        return;

      currentCards[index]['flipped'] = true;
      myFlipped.add(index);

      if (myFlipped.length == 2) {
        isSecondCard = true;
        // On bloque le statut global SEULEMENT en tour par tour
        if (settings.memoryMode != 'race') {
          mState['status'] = 'checking';
        }
      }

      playerFlipped[widget.playerName] = myFlipped;
      mState['playerFlipped'] = playerFlipped;
      mState['cards'] = currentCards;
      gameState['memoryState'] = mState;

      transaction.update(roomRef, {'gameState': gameState});
    });

    if (isSecondCard) {
      _resolveMemoryTurn(); // Résout pour le joueur spécifiquement
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_isMounted) setState(() => _isMemoryBusy = false);
    });
  }

  Future<void> _resolveMemoryTurn() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!_isMounted) return;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance
          .collection('onlineRooms')
          .doc(widget.roomId);
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      var data = snapshot.data() as Map<String, dynamic>;
      var players = Map<String, dynamic>.from(data['players']);
      var gameState = Map<String, dynamic>.from(data['gameState']);
      var mState = Map<String, dynamic>.from(gameState['memoryState'] ?? {});
      List<dynamic> currentCards = List<dynamic>.from(mState['cards']);

      var playerFlipped = Map<String, dynamic>.from(
        mState['playerFlipped'] ?? {},
      );
      List<int> myFlipped = List<int>.from(
        playerFlipped[widget.playerName] ?? [],
      );
      String currentPlayerName = mState['currentPlayerName'];

      if (myFlipped.length != 2) return;

      int card1Index = myFlipped[0];
      int card2Index = myFlipped[1];
      if (card1Index < 0 ||
          card1Index >= currentCards.length ||
          card2Index < 0 ||
          card2Index >= currentCards.length)
        return;

      Map<String, dynamic> card1 = Map<String, dynamic>.from(
        currentCards[card1Index],
      );
      Map<String, dynamic> card2 = Map<String, dynamic>.from(
        currentCards[card2Index],
      );

      if (card1['matched'] == true || card2['matched'] == true) {
        playerFlipped[widget.playerName] = [];
        mState['playerFlipped'] = playerFlipped;
        gameState['memoryState'] = mState;
        transaction.update(roomRef, {'gameState': gameState});
        return;
      }

      if (card1['id'] == card2['id']) {
        currentCards[card1Index]['matched'] = true;
        currentCards[card2Index]['matched'] = true;
        if (players.containsKey(widget.playerName) &&
            players[widget.playerName] != null) {
          players[widget.playerName]['score'] =
              (players[widget.playerName]['score'] ?? 0) + 15;
        }
      } else {
        currentCards[card1Index]['flipped'] = false;
        currentCards[card2Index]['flipped'] = false;

        // On passe le tour seulement en tour par tour ET si c'est bien à ce joueur de jouer
        if (_settings?.memoryMode == 'turnBased' &&
            currentPlayerName == widget.playerName) {
          final playerNames = players.keys.toList();
          final currentIndex = playerNames.indexOf(currentPlayerName);
          final nextIndex = (currentIndex + 1) % playerNames.length;
          mState['currentPlayerName'] = playerNames[nextIndex];
        }
      }

      bool allMatched = currentCards.every((c) => c['matched'] == true);
      if (allMatched) {
        mState['gameOver'] = true;
        gameState['canGoToNextQuestion'] = true;
      }

      // Réinitialise uniquement les cartes de CE joueur
      playerFlipped[widget.playerName] = [];
      mState['playerFlipped'] = playerFlipped;
      mState['cards'] = currentCards;

      if (_settings?.memoryMode != 'race') {
        mState['status'] = 'playing';
      }

      gameState['memoryState'] = mState;

      transaction.update(roomRef, {'players': players, 'gameState': gameState});
    });
  }

  void _initializeMatchGameInFirestore() async {
    if (!widget.isHost) return;

    final game = _games[_gameState['currentGameIndex']];
    final String displayMode = game['displayMode'] ?? 'definitionToWord';
    final pairsData =
        (game['pairs'] as List<dynamic>?)?.cast<Map<dynamic, dynamic>>() ?? [];

    List<String> items1 = [];
    List<String> items2Options = [];

    if (displayMode == 'imageToDefinition') {
      items1 = pairsData.map((p) => p['image_url'].toString()).toList();
      items2Options = pairsData.map((p) => p['definition'].toString()).toList();
    } else {
      // definitionToWord
      items1 = pairsData.map((p) => p['definition'].toString()).toList();
      items2Options = pairsData.map((p) => p['word'].toString()).toList();
    }
    items2Options.shuffle();

    await FirebaseFirestore.instance
        .collection('onlineRooms')
        .doc(widget.roomId)
        .update({
          'gameState.matchState': {
            'items1': items1,
            'items2Options': items2Options,
          },
        });
  }

  // NOUVEAU: Initialisation du jeu "Mot Mystère" en ligne
  void _initializeMotMystereInFirestore() async {
    if (!widget.isHost) return;

    final playersList = _players.keys.toList();
    if (playersList.isEmpty) return;

    final game = _games[_gameState['currentGameIndex']];
    final word = (game['word'] as String? ?? 'DEFAULT').toUpperCase();

    await FirebaseFirestore.instance
        .collection('onlineRooms')
        .doc(widget.roomId)
        .update({
          'gameState.motMystereState': {
            'currentPlayerName': playersList.first,
            'guesses': {},
            'gameOver': false,
            'wordToGuess': word,
            'maxGuesses':
                (word.length + 1) *
                playersList
                    .length, // <-- NOUVEAU: Sauvegarder la limite absolue
          },
        });
  }

  // NOUVEAU: Logique pour soumettre une tentative au "Mot Mystère"
  Future<void> _submitMotMystereGuess(String guess) async {
    final motMystereState =
        _gameState['motMystereState'] as Map<String, dynamic>?;
    if (motMystereState == null ||
        motMystereState['gameOver'] == true ||
        motMystereState['currentPlayerName'] != widget.playerName)
      return;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance
          .collection('onlineRooms')
          .doc(widget.roomId);
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      var data = snapshot.data() as Map<String, dynamic>;
      var players = Map<String, dynamic>.from(data['players']);
      var gameState = Map<String, dynamic>.from(data['gameState']);
      var mmState = Map<String, dynamic>.from(
        gameState['motMystereState'] ?? {},
      );
      var guesses = Map<String, dynamic>.from(mmState['guesses'] ?? {});

      final wordToGuess =
          (mmState['wordToGuess']?.toString() ?? '').toUpperCase();
      final currentPlayerName = mmState['currentPlayerName'];

      // Ajoute la tentative à la liste du joueur
      List<String> playerGuesses = List<String>.from(
        guesses[currentPlayerName] ?? [],
      );
      playerGuesses.add(guess.toUpperCase());
      guesses[currentPlayerName] = playerGuesses;

      bool isWordGuessed = guess.toUpperCase() == wordToGuess;
      int totalGuesses = 0;
      guesses.values.forEach((g) => totalGuesses += (g is List ? g.length : 0));

      // Utilise la limite sauvegardée (ou calcule en fallback)
      int maxGuesses =
          mmState['maxGuesses'] ?? ((wordToGuess.length + 1) * players.length);

      if (isWordGuessed) {
        mmState['gameOver'] = true;
        if (players.containsKey(currentPlayerName) &&
            players[currentPlayerName] != null) {
          players[currentPlayerName]['score'] =
              (players[currentPlayerName]['score'] ?? 0) + 25;
        }
      } else if (totalGuesses >= maxGuesses) {
        mmState['gameOver'] = true;
      }

      // Passe au joueur suivant
      final playerNames = players.keys.toList();
      final currentIndex = playerNames.indexOf(currentPlayerName);
      final nextIndex = (currentIndex + 1) % playerNames.length;
      mmState['currentPlayerName'] = playerNames[nextIndex];

      mmState['guesses'] = guesses;
      if (mmState['gameOver'] == true) gameState['canGoToNextQuestion'] = true;
      gameState['motMystereState'] = mmState;

      transaction.update(roomRef, {'players': players, 'gameState': gameState});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_games.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz vide')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline_rounded, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Veuillez ajouter des questions avant de jouer.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_settings == null || _gameState.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Synchronisation..."),
            ],
          ),
        ),
      );
    }

    final game = _games[_gameState['currentGameIndex']];
    final gameType = game['type'] as String? ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Empêcher le retour arrière pendant le jeu (pour éviter les désynchronisations)
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Quitter la partie ?'),
                content: const Text(
                  'Si vous quittez, votre score sera perdu et les autres joueurs pourront continuer.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Rester'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Quitter'),
                  ),
                ],
              ),
        );
        if (shouldLeave == true) {
          _handlePlayerLeave();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Question ${_gameState['currentGameIndex'] + 1}/${_games.length}',
          ),
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildPhaseWidget(game, gameType),
          ),
        ),
      ),
    );
  }

  // Gère le départ propre d'un joueur en cours de partie
  Future<void> _handlePlayerLeave() async {
    _roomSubscription.cancel();
    _timer?.cancel();

    // 1. D'ABORD sanctionner l'abandon auprès de la Cloud Function
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'abandonOnlineGame',
      );
      await callable.call({'roomId': widget.roomId, 'averageDifficulty': 5.0});
    } catch (e) {
      print("Erreur lors de la sanction d'abandon: $e");
    }

    // 2. PUIS quitter la room dans Firestore
    try {
      if (widget.isHost) {
        await FirebaseFirestore.instance
            .collection('onlineRooms')
            .doc(widget.roomId)
            .update({'active': false});
      } else {
        await FirebaseFirestore.instance
            .collection('onlineRooms')
            .doc(widget.roomId)
            .update({
              FieldPath(['players', widget.playerName]): FieldValue.delete(),
            });
        await _checkIfAllRemainingPlayersAnsweredAfterLeave();
      }
    } catch (e) {
      print("Erreur lors du départ du joueur: $e");
    }
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _checkIfAllRemainingPlayersAnsweredAfterLeave() async {
    // La vérification se fait via le listener Firestore côté hôte
  }

  // Gère le cas où le joueur actif dans un jeu tour-par-tour quitte la partie
  void _handleDisconnectInTurnBasedGame(
    Map<String, dynamic> currentPlayers,
    Map<String, dynamic> currentGameState,
  ) {
    if (!widget.isHost) return;
    final int currentIndex = currentGameState['currentGameIndex'] as int? ?? 0;
    if (currentIndex >= _games.length) return;
    final gameType = _games[currentIndex]['type'] as String? ?? '';

    if (gameType.contains('Pendu')) {
      final hState = currentGameState['hangmanState'] as Map<String, dynamic>?;
      if (hState == null || hState['gameOver'] == true) return;
      final currentPlayer = hState['currentPlayerName'] as String?;
      if (currentPlayer != null && !currentPlayers.containsKey(currentPlayer)) {
        // Le joueur courant a quitté — passer au suivant
        final remaining = currentPlayers.keys.toList();
        if (remaining.isEmpty) return;
        final nextPlayer = remaining.first;
        FirebaseFirestore.instance
            .collection('onlineRooms')
            .doc(widget.roomId)
            .update({'gameState.hangmanState.currentPlayerName': nextPlayer});
      }
    } else if (gameType.contains('Mot Mystère')) {
      final mmState =
          currentGameState['motMystereState'] as Map<String, dynamic>?;
      if (mmState == null || mmState['gameOver'] == true) return;
      final currentPlayer = mmState['currentPlayerName'] as String?;
      if (currentPlayer != null && !currentPlayers.containsKey(currentPlayer)) {
        final remaining = currentPlayers.keys.toList();
        if (remaining.isEmpty) return;
        final nextPlayer = remaining.first;
        FirebaseFirestore.instance
            .collection('onlineRooms')
            .doc(widget.roomId)
            .update({
              'gameState.motMystereState.currentPlayerName': nextPlayer,
            });
      }
    } else if (gameType.contains('Memory')) {
      final mState = currentGameState['memoryState'] as Map<String, dynamic>?;
      if (mState == null || mState['gameOver'] == true) return;
      if (_settings?.memoryMode == 'race') return;
      final currentPlayer = mState['currentPlayerName'] as String?;
      if (currentPlayer != null && !currentPlayers.containsKey(currentPlayer)) {
        final remaining = currentPlayers.keys.toList();
        if (remaining.isEmpty) return;
        final nextPlayer = remaining.first;
        FirebaseFirestore.instance
            .collection('onlineRooms')
            .doc(widget.roomId)
            .update({'gameState.memoryState.currentPlayerName': nextPlayer});
      }
    }
  }

  Widget _buildHintButton(Map<String, dynamic> game) {
    // Si aucun indice n'a été défini à la création, on n'affiche aucun bouton
    final hint = game['hint']?.toString();
    if (hint == null || hint.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (_gameHintVisible) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hint,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _gameHintVisible = true;
            if (game['type']?.toString().contains('Quiz Éclair') == true) {
              _remainingTime.value = max(0, _remainingTime.value - 2);
            }
          });
        },
        icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
        label: Text(
          game['type']?.toString().contains('Quiz Éclair') == true
              ? 'Voir l\'indice (-2s)'
              : 'Voir l\'indice',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.amber.shade700,
          side: BorderSide(color: Colors.amber.shade400),
        ),
      ),
    );
  }

  Widget _buildPhaseWidget(Map<String, dynamic> game, String gameType) {
    switch (_phase) {
      case GamePhase.playing:
        return _buildGamePlayingWidget(game, gameType);
      case GamePhase.showingResult:
        return _buildResultWidget(game);
      case GamePhase.showingLeaderboard:
        return _buildLeaderboardWidget();
    }
  }

  Widget _buildGamePlayingWidget(Map<String, dynamic> game, String gameType) {
    return Column(
      key: const ValueKey('playing'),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Indique le type/format de la question courante
                Text(
                  'Format : $gameType',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _remainingTime,
                  builder: (context, time, child) {
                    if (time > 0 &&
                        ![
                          'Memory',
                          'Pendu',
                          'Mot Mystère',
                        ].any(gameType.contains)) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Temps restant : $time',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
        if (game['theme'] != null) ...[
          const SizedBox(height: 8),
          Text(
            'Thème : ${game['theme']}',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
        const SizedBox(height: 16),
        _buildGameWidget(game, gameType),
        const SizedBox(height: 16),

        if (!gameType.contains('Quiz par Indices') &&
            (game['hintEnabled'] == null || game['hintEnabled'] == true))
          _buildHintButton(game),
        const SizedBox(height: 16),

        if (_feedback.isNotEmpty)
          Text(
            _feedback,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _feedback.contains('Bonne') ? Colors.green : Colors.grey,
            ),
          ),
      ],
    );
  }

  Widget _buildResultWidget(Map<String, dynamic> game) {
    final gameType = game['type']?.toString() ?? '';
    String correctAnswerText = 'Information non disponible.';

    try {
      if (gameType.contains('Vrai ou Faux'))
        correctAnswerText = game['answer'] ? 'Vrai' : 'Faux';
      else if (gameType.contains('QCM'))
        correctAnswerText = game['correct'];
      else if (gameType.contains('Choisir l\'Intrus'))
        correctAnswerText = game['intruder'];
      else if (gameType.contains('Compléter la Phrase') ||
          gameType.contains('Quiz par Indices'))
        correctAnswerText = game['correct'] ?? game['answer'] ?? '';
      else if (gameType.contains('Deux Vérités'))
        correctAnswerText = game['lie'];
      else if (gameType == 'Qui suis-je ?')
        correctAnswerText = game['answer'];
      else if (gameType == 'Le Mot Anagramme')
        correctAnswerText = game['solution'];
      else if (gameType.contains('Chronologie') ||
          gameType.contains('Quiz Éclair'))
        correctAnswerText =
            game['correct'] ??
            (game['events'] as List<dynamic>?)?.join(' -> ') ??
            '';
      else if (gameType.contains('Pendu'))
        correctAnswerText = game['word'];
      else if (gameType.contains('Mot Mystère'))
        correctAnswerText = game['word'];
      else if (gameType.contains('Estimation')) {
        final ans = (game['answer'] as num?)?.toDouble() ?? 0;
        final unit = game['unit']?.toString() ?? '';
        correctAnswerText =
            '${ans.toStringAsFixed(ans.truncateToDouble() == ans ? 0 : 2)} ${unit}';
      } else if (gameType.contains('Relier')) {
        final pairs =
            (game['pairs'] as List<dynamic>?)?.cast<Map<dynamic, dynamic>>() ??
            [];
        if (game['displayMode'] == 'imageToDefinition') {
          correctAnswerText = pairs
              .map((p) => 'Image = ${p['definition']}')
              .join('\n');
        } else {
          correctAnswerText = pairs
              .map((p) => '${p['definition']} = ${p['word']}')
              .join('\n');
        }
      }
    } catch (e) {
      print("Erreur de récupération de la bonne réponse: $e");
    }

    return Column(
      key: const ValueKey('result'),
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
        const SizedBox(height: 16),
        const Text(
          'Fin de la question !',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        if (!gameType.contains('Memory')) ...[
          const Text(
            'La bonne réponse était :',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            correctAnswerText,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 8),
        Text(
          _settings?.showLeaderboardPolicy == 'afterQuestion'
              ? "Affichage du classement..."
              : "Question suivante...",
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLeaderboardWidget() {
    final sortedPlayers =
        _players.entries.toList()..sort(
          (a, b) =>
              (b.value['score'] as int).compareTo(a.value['score'] as int),
        );

    return Column(
      key: const ValueKey('leaderboard'),
      children: [
        const Icon(Icons.leaderboard, color: Colors.amber, size: 80),
        const SizedBox(height: 16),
        const Text(
          'Classement Actuel',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...sortedPlayers.map((entry) {
          return Card(
            child: ListTile(
              leading: Text('#${sortedPlayers.indexOf(entry) + 1}'),
              title: Text(entry.key),
              trailing: Text(
                '${entry.value['score']} points',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 8),
        const Text(
          "Question suivante...",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildGameWidget(Map<String, dynamic> game, String gameType) {
    if (gameType.contains('Pendu')) {
      return _buildHangmanBody(game);
    } else if (gameType.contains('Memory')) {
      return _buildMemoryBody(game);
    } else if ([
      'Qui suis-je ?',
      'Le Mot Anagramme',
      'Compléter la Phrase',
    ].contains(gameType)) {
      return _buildTextInputGame(game, gameType);
    } else if (gameType.contains('Relier')) {
      return _buildMatchGameBody(game);
    } else if (gameType.contains('Mot Mystère')) {
      return _buildMotMystereBody(game);
    } else if (gameType.contains('Estimation')) {
      return _buildEstimationOnlineBody(game);
    } else if (gameType.contains('Chronologie')) {
      return _buildChronologyBody(game);
    } else {
      return _buildStandardGameBody(game, gameType);
    }
  }

  Widget _buildChronologyBody(Map<String, dynamic> game) {
    if (_gameState['currentGameIndex'] != _currentChronologyIndex) {
      _currentChronologyIndex = _gameState['currentGameIndex'] ?? 0;
      _chronologyEvents = List<String>.from(game['events'] ?? []);
      _chronologyEvents!.shuffle();
    }

    return Column(
      children: [
        Text(
          game['question'] ?? "Remettez les événements dans l'ordre :",
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _chronologyEvents!.length,
          itemBuilder:
              (context, index) => Card(
                key: ValueKey('${_chronologyEvents![index]}_$index'),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(_chronologyEvents![index]),
                ),
              ),
          onReorder: (oldIndex, newIndex) {
            if (_localAnswerSubmitted) return;
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _chronologyEvents!.removeAt(oldIndex);
              _chronologyEvents!.insert(newIndex, item);
            });
          },
        ),
        const SizedBox(height: 16),
        if (!_localAnswerSubmitted)
          ElevatedButton(
            onPressed: () {
              final originalEvents = List<String>.from(game['events'] ?? []);
              bool isCorrect = true;
              for (int i = 0; i < originalEvents.length; i++) {
                if (i >= _chronologyEvents!.length ||
                    originalEvents[i] != _chronologyEvents![i]) {
                  isCorrect = false;
                  break;
                }
              }
              _submitAnswer(
                _chronologyEvents!.join(' -> '),
                isCorrect: isCorrect,
              );
            },
            child: const Text('Valider l\'ordre'),
          ),
      ],
    );
  }

  Widget _buildTextInputGame(Map<String, dynamic> game, String gameType) {
    String questionText = '';
    String? hintText;
    String correctAnswer = '';

    if (gameType == 'Qui suis-je ?') {
      questionText = game['riddle']?.toString() ?? 'Devinette non trouvée.';
      correctAnswer = game['answer']?.toString() ?? '';
    } else if (gameType == 'Le Mot Anagramme') {
      String solution = game['solution']?.toString() ?? '';
      String defaultAnagram = game['anagram']?.toString() ?? '';

      if (_gameState['currentGameIndex'] != _currentAnagramIndex) {
        _currentAnagramIndex = _gameState['currentGameIndex'] ?? 0;

        if (defaultAnagram.isEmpty ||
            defaultAnagram.toUpperCase() == solution.toUpperCase()) {
          List<String> letters = solution.toUpperCase().split('');
          if (letters.toSet().length > 1) {
            letters.shuffle();
            while (letters.join() == solution.toUpperCase()) {
              letters.shuffle();
            }
            _currentAnagram = letters.join();
          } else {
            _currentAnagram = defaultAnagram;
          }
        } else {
          _currentAnagram = defaultAnagram;
        }
      }

      questionText =
          'Quel est le mot caché dans : ${_currentAnagram ?? defaultAnagram}';
      hintText = game['hint']?.toString();
      correctAnswer = solution;
    } else if (gameType == 'Compléter la Phrase') {
      questionText = game['question']?.toString() ?? 'Phrase non trouvée';
      correctAnswer = game['correct']?.toString() ?? '';
    } else if (gameType == 'Quiz par Indices') {
      final clues =
          (game['clues'] as List?)?.join('\n') ?? 'Indices non trouvés.';
      questionText = "Trouvez la réponse avec ces indices :\n$clues";
      correctAnswer = game['answer']?.toString() ?? '';
    }

    return Column(
      children: [
        Text(
          questionText,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        if (hintText != null) ...[
          const SizedBox(height: 8),
          Text(
            'Indice : $hintText',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _answerController,
          decoration: const InputDecoration(
            labelText: 'Votre réponse',
            border: OutlineInputBorder(),
          ),
          enabled: !_localAnswerSubmitted,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed:
              _localAnswerSubmitted
                  ? null
                  : () {
                    final userAnswer = _answerController.text.trim();
                    final isCorrect =
                        userAnswer.trim().toLowerCase() ==
                        correctAnswer.trim().toLowerCase();
                    _submitAnswer(userAnswer, isCorrect: isCorrect);
                  },
          child: const Text('Valider'),
        ),
      ],
    );
  }

  Widget _buildStandardGameBody(Map<String, dynamic> game, String gameType) {
    List<dynamic> options = [];
    Map<String, dynamic> questionData = {};
    String correctAnswer = '';

    if (game['question'] is Map) {
      questionData = Map<String, dynamic>.from(game['question']);
    } else if (game['question'] is String) {
      questionData['text'] = game['question'];
    } else {
      questionData['text'] = 'Question non trouvée.';
    }

    if (gameType.contains('Vrai ou Faux')) {
      options = ['True', 'False'];
      correctAnswer = game['answer'].toString();
    } else if (gameType.contains('QCM')) {
      options = List<dynamic>.from(game['options'] ?? []);
      final rawCorrect = game['correct']?.toString() ?? '';
      final qcmIdx = int.tryParse(rawCorrect);
      correctAnswer =
          (qcmIdx != null && qcmIdx >= 0 && qcmIdx < options.length)
              ? ((options[qcmIdx] is Map
                          ? options[qcmIdx]['text']
                          : options[qcmIdx])
                      ?.toString() ??
                  rawCorrect)
              : rawCorrect;
    } else if (gameType.contains('Choisir l\'Intrus')) {
      options = List<dynamic>.from(game['options'] ?? []);
      correctAnswer = game['intruder']?.toString() ?? '';
    } else if (gameType.contains('Deux Vérités') ||
        gameType.contains('Deux Vérités')) {
      options = List<dynamic>.from(game['statements'] ?? []);
      correctAnswer = game['lie']?.toString() ?? '';
    } else if (gameType.contains('Quiz Éclair') ||
        gameType.contains('Quiz Eclair')) {
      options = List<dynamic>.from(
        game['choices'] ?? game['options'] ?? ['Vrai', 'Faux', 'Peut-Être'],
      );
      correctAnswer =
          game['correct']?.toString() ?? game['answer']?.toString() ?? '';
    }

    Widget questionWidget = Column(
      children: [
        if (_settings!.qcmQuestionMode != DisplayMode.text &&
            questionData['image_url'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Image.network(
              questionData['image_url'],
              height: 150,
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stack) => Icon(Icons.broken_image, size: 50),
            ),
          ),
        if (_settings!.qcmQuestionMode != DisplayMode.image &&
            questionData['text'] != null)
          Text(
            questionData['text'],
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
      ],
    );

    return Column(
      children: [
        questionWidget,
        const SizedBox(height: 16),
        ...options.map((option) {
          String optionText;
          String? imageUrl;
          String? valueToCompare;

          if (option is Map) {
            optionText = option['text'] ?? '';
            imageUrl = option['image_url'];

            valueToCompare = option['text'];
          } else {
            optionText = option.toString();
            valueToCompare = optionText;
          }

          Widget optionContent = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_settings!.qcmAnswerMode != DisplayMode.text &&
                  imageUrl != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stack) =>
                              Center(child: Icon(Icons.broken_image, size: 40)),
                      loadingBuilder:
                          (context, child, progress) =>
                              progress == null
                                  ? child
                                  : Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              if (_settings!.qcmAnswerMode != DisplayMode.image &&
                  optionText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    optionText,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          );

          return SizedBox(
            height: _settings!.qcmAnswerMode == DisplayMode.text ? 60 : 150,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap:
                    _localAnswerSubmitted
                        ? null
                        : () {
                          final isCorrect =
                              valueToCompare != null &&
                              valueToCompare.toLowerCase() ==
                                  correctAnswer.toLowerCase();
                          _submitAnswer(valueToCompare, isCorrect: isCorrect);
                        },
                child: optionContent,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildHangmanBody(Map<String, dynamic> game) {
    final hangmanState = _gameState['hangmanState'] as Map<String, dynamic>?;
    if (hangmanState == null)
      return const Center(child: CircularProgressIndicator());

    final word = (hangmanState['wordToGuess']?.toString() ?? '').toUpperCase();
    final usedLetters = List<String>.from(hangmanState['usedLetters'] ?? []);
    final currentPlayerName =
        hangmanState['currentPlayerName']?.toString() ?? '';
    final isMyTurn = currentPlayerName == widget.playerName;
    final isGameOver = hangmanState['gameOver'] == true;
    final mistakes = hangmanState['mistakes'] as int? ?? 0;

    final displayWord = word
        .split('')
        .map((char) => usedLetters.contains(char) ? char : '_')
        .join(' ');

    String statusText;
    Color statusColor;
    if (isGameOver) {
      if (!displayWord.contains('_')) {
        statusText = 'Gagné ! Le mot était $word.';
        statusColor = Colors.green;
      } else {
        statusText = 'Perdu ! Le mot était $word.';
        statusColor = Colors.red;
      }
    } else if (isMyTurn) {
      statusText = "C'est votre tour !";
      statusColor = Colors.green;
    } else {
      statusText = "Au tour de $currentPlayerName";
      statusColor = Colors.blue;
    }

    return Column(
      children: [
        Text(
          statusText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: CustomPaint(
            size: const Size(150, 150),
            painter: HangmanPainter(mistakes: mistakes),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayWord,
          style: const TextStyle(fontSize: 32, letterSpacing: 8),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children:
              'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map((letter) {
                final isUsed = usedLetters.contains(letter);
                return ElevatedButton(
                  onPressed:
                      (isUsed || !isMyTurn || isGameOver || widget.isGuest)
                          ? null
                          : () => _guessLetterOnline(letter),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUsed ? Colors.grey : Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(letter),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildMemoryBody(Map<String, dynamic> game) {
    final memoryState = _gameState['memoryState'] as Map<String, dynamic>?;
    if (memoryState == null || _memoryCards.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final isGameOver = memoryState['gameOver'] == true;
    final gameStatus = memoryState['status'] as String? ?? 'playing';
    final isMyTurn =
        _settings?.memoryMode == 'turnBased' &&
        _memoryTurnPlayer == widget.playerName;

    String statusText;
    Color statusColor;

    if (isGameOver) {
      statusText = 'Le jeu de Memory est terminé !';
      statusColor = Colors.green;
    } else if (gameStatus == 'checking') {
      statusText = 'Vérification...';
      statusColor = Colors.orange;
    } else if (_settings?.memoryMode == 'turnBased') {
      statusText =
          isMyTurn ? "C'est votre tour !" : "Au tour de $_memoryTurnPlayer";
      statusColor = isMyTurn ? Colors.green : Colors.blue;
    } else {
      statusText = 'Trouvez les paires !';
      statusColor = Colors.blue;
    }

    return Column(
      children: [
        Text(
          statusText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _memoryCards.length,
          itemBuilder: (context, index) {
            final card = _memoryCards[index];

            bool canClick =
                (!card['matched'] &&
                    !card['flipped'] &&
                    !isGameOver &&
                    !widget.isGuest);

            // En tour par tour, on applique les restrictions de tour et de statut
            if (_settings?.memoryMode == 'turnBased') {
              canClick = canClick && gameStatus == 'playing' && isMyTurn;
            }

            Widget cardContent;
            final value = card['value'].toString();
            if (card['flipped'] && value.startsWith('http')) {
              cardContent = Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.network(
                  value,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (ctx, err, st) => const Icon(Icons.broken_image),
                ),
              );
            } else if (card['flipped']) {
              cardContent = Center(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            } else {
              cardContent = Container();
            }

            return GestureDetector(
              onTap: canClick ? () => _flipCardOnline(index) : null,
              child: Card(
                clipBehavior: Clip.antiAlias,
                color:
                    card['matched']
                        ? Colors.green.shade200
                        : (card['flipped']
                            ? Colors.blue.shade100
                            : Colors.grey.shade400),
                child: cardContent,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMatchGameBody(Map<String, dynamic> game) {
    final matchState = _gameState['matchState'] as Map<String, dynamic>?;
    if (matchState == null)
      return const Center(child: CircularProgressIndicator());

    final String displayMode = game['displayMode'] ?? 'definitionToWord';
    final items1 = List<String>.from(matchState['items1'] ?? []);
    final items2Options = List<String>.from(matchState['items2Options'] ?? []);

    return Column(
      children: [
        Text(
          displayMode == 'imageToDefinition'
              ? 'Associez chaque image à sa définition :'
              : 'Associez chaque définition à son mot :',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ...items1.map(
          (item1) => Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child:
                        displayMode == 'imageToDefinition'
                            ? Image.network(
                              item1,
                              height: 80,
                              errorBuilder:
                                  (c, e, s) => const Icon(Icons.image),
                            )
                            : Text(item1),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _onlineMatches[item1],
                    hint: const Text('Choisir'),
                    items:
                        items2Options
                            .map(
                              (option) => DropdownMenuItem(
                                value: option,
                                child: Text(
                                  option,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged:
                        _isMatchSubmitted || widget.isGuest
                            ? null
                            : (value) =>
                                setState(() => _onlineMatches[item1] = value),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!_isMatchSubmitted)
          ElevatedButton(
            onPressed: widget.isGuest ? null : _submitMatches,
            child: const Text('Valider mes associations'),
          ),
      ],
    );
  }

  // NOUVEAU: Widget pour le jeu "Mot Mystère" en ligne
  Widget _buildMotMystereBody(Map<String, dynamic> game) {
    final motMystereState =
        _gameState['motMystereState'] as Map<String, dynamic>?;
    if (motMystereState == null)
      return const Center(child: CircularProgressIndicator());

    final word =
        (motMystereState['wordToGuess'] as String? ?? '').toUpperCase();
    final currentPlayerName = motMystereState['currentPlayerName'] as String?;
    final isMyTurn = currentPlayerName == widget.playerName;
    final isGameOver = motMystereState['gameOver'] == true;
    final rawGuesses =
        (motMystereState['guesses'] as Map<String, dynamic>?) ?? {};
    final guesses = rawGuesses.map(
      (key, value) => MapEntry(key, List<dynamic>.from(value ?? [])),
    );

    String statusText;
    Color statusColor;
    if (isGameOver) {
      statusText = 'Partie terminée ! Le mot était $word.';
      statusColor = Colors.green;
    } else if (isMyTurn) {
      statusText =
          "C'est votre tour ! Devinez le mot de ${word.length} lettres.";
      statusColor = Colors.green;
    } else {
      statusText = "Au tour de $currentPlayerName";
      statusColor = Colors.blue;
    }

    // Fonction locale pour générer le feedback visuel d'une tentative
    List<LetterFeedback> getFeedbackForGuess(String guess, String solution) {
      List<LetterFeedback> feedback = [];
      List<String> solutionLetters = solution.split('');
      List<String> guessLetters = guess.split('');

      // Marquer les lettres bien placées
      for (int i = 0; i < guessLetters.length; i++) {
        if (guessLetters[i] == solutionLetters[i]) {
          feedback.add(
            LetterFeedback(
              letter: guessLetters[i],
              status: LetterStatus.correctPosition,
            ),
          );
          solutionLetters[i] = ''; // Marquer comme utilisée
        } else {
          feedback.add(
            LetterFeedback(letter: guessLetters[i], status: LetterStatus.none),
          ); // Statut temporaire
        }
      }

      // Marquer les lettres mal placées
      for (int i = 0; i < feedback.length; i++) {
        if (feedback[i].status == LetterStatus.none) {
          if (solutionLetters.contains(guessLetters[i])) {
            feedback[i] = LetterFeedback(
              letter: guessLetters[i],
              status: LetterStatus.inWord,
            );
            solutionLetters[solutionLetters.indexOf(guessLetters[i])] =
                ''; // Marquer comme utilisée
          } else {
            feedback[i] = LetterFeedback(
              letter: guessLetters[i],
              status: LetterStatus.notInWord,
            );
          }
        }
      }
      return feedback;
    }

    return Column(
      children: [
        Text(
          statusText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        const SizedBox(height: 16),
        // Affichage de toutes les tentatives
        ...guesses.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key} a tenté :',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(entry.value).map((g) {
                final feedback = getFeedbackForGuess(g, word);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      feedback.map((fb) {
                        Color color;
                        switch (fb.status) {
                          case LetterStatus.correctPosition:
                            color = Colors.green.shade300;
                            break;
                          case LetterStatus.inWord:
                            color = Colors.yellow.shade300;
                            break;
                          default:
                            color = Colors.grey.shade300;
                        }
                        return Container(
                          margin: const EdgeInsets.all(2),
                          width: 30,
                          height: 30,
                          color: color,
                          child: Center(
                            child: Text(
                              fb.letter,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
        const SizedBox(height: 24),
        if (isMyTurn && !isGameOver) ...[
          TextField(
            controller: _answerController,
            decoration: InputDecoration(
              labelText: 'Votre proposition (${word.length} lettres)',
              border: const OutlineInputBorder(),
            ),
            maxLength: word.length,
            enabled: !widget.isGuest,
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _answerController,
            builder: (context, value, child) {
              return ElevatedButton(
                onPressed:
                    (widget.isGuest || value.text.length != word.length)
                        ? null
                        : () {
                          _submitMotMystereGuess(value.text);
                          _answerController.clear();
                        },
                child: const Text('Proposer'),
              );
            },
          ),
        ],
      ],
    );
  }

  // ---- Estimation en ligne ----
  Future<void> _submitEstimation(double correctAnswer, String? unit) async {
    if (_localAnswerSubmitted) return;
    final userValue = double.tryParse(_answerController.text.trim());
    if (userValue == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entrez un nombre valide.')));
      return;
    }
    final double pctErr =
        correctAnswer != 0
            ? (userValue - correctAnswer).abs() / correctAnswer.abs()
            : 1.0;
    int points;
    if (pctErr == 0)
      points = 10;
    else if (pctErr <= 0.01)
      points = 9;
    else if (pctErr <= 0.05)
      points = 7;
    else if (pctErr <= 0.15)
      points = 5;
    else if (pctErr <= 0.30)
      points = 2;
    else
      points = 0;

    setState(() {
      _localAnswerSubmitted = true;
      _feedback =
          'Estimation : ${userValue.toStringAsFixed(0)} — Score : $points/10 pts';
    });

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance
          .collection('onlineRooms')
          .doc(widget.roomId);
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;
      var data = snapshot.data() as Map<String, dynamic>;
      var players = Map<String, dynamic>.from(data['players']);
      var gameState = Map<String, dynamic>.from(data['gameState']);
      var playersAnswered = List<dynamic>.from(
        gameState['playersAnswered'] ?? [],
      );
      players[widget.playerName]['score'] =
          (players[widget.playerName]['score'] ?? 0) + points;
      if (!playersAnswered.contains(widget.playerName))
        playersAnswered.add(widget.playerName);
      gameState['playersAnswered'] = playersAnswered;
      if (_settings?.waitForAllPlayers == true &&
          playersAnswered.length >= players.length) {
        gameState['canGoToNextQuestion'] = true;
      }
      transaction.update(roomRef, {'players': players, 'gameState': gameState});
    });
  }

  Widget _buildEstimationOnlineBody(Map<String, dynamic> game) {
    final question = game['question']?.toString() ?? '';
    final correctAnswer = (game['answer'] as num?)?.toDouble() ?? 0;
    final unit = game['unit']?.toString();
    final hint = game['hint']?.toString();
    final unitStr = unit != null && unit.isNotEmpty ? ' $unit' : '';

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calculate_rounded,
                      color: Color(0xFF6C3FC7),
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Jeu des Estimations',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C3FC7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (unit != null && unit.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Chip(
                    label: Text('Unité : $unit'),
                    backgroundColor: const Color(0xFF6C3FC7).withOpacity(0.1),
                  ),
                ],
                if (hint != null && hint.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Indice : $hint',
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _answerController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          enabled: !_localAnswerSubmitted,
          decoration: InputDecoration(
            labelText: 'Votre estimation$unitStr',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.edit_rounded),
          ),
          onSubmitted:
              _localAnswerSubmitted
                  ? null
                  : (_) => _submitEstimation(correctAnswer, unit),
        ),
        const SizedBox(height: 16),
        if (!_localAnswerSubmitted)
          ElevatedButton.icon(
            onPressed:
                widget.isGuest
                    ? null
                    : () => _submitEstimation(correctAnswer, unit),
            icon: const Icon(Icons.send_rounded),
            label: const Text('Valider mon estimation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C3FC7),
            ),
          ),
      ],
    );
  }
}

class GamePage extends StatefulWidget {
  final List<dynamic> games;
  final Function(double) onScoreUpdate;
  final bool isGuest;

  final DisplayMode qcmQuestionMode;
  final DisplayMode qcmAnswerMode;

  const GamePage({
    super.key,
    required this.games,
    required this.onScoreUpdate,
    this.isGuest = false,
    required this.qcmQuestionMode,
    required this.qcmAnswerMode,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  int _currentGameIndex = 0, _penduAttempts = 6;
  double _currentScore = 0.0;
  String _feedback = '', _penduCurrent = '';
  bool _answered = false, _memoryGameOver = false;
  final _answerController = TextEditingController();
  late AnimationController _animationController;
  Map<String, String?> _matches = {};
  List<Map<String, dynamic>> _memoryCards = [];
  List<String> _usedLetters = [], _shuffledEvents = [], _originalEvents = [];
  List<int> _flippedCardIndexes = [];

  // État pour le jeu Mot Mystère
  int _motMystereAttempts = 0;
  List<List<LetterFeedback>> _motMystereGuesses = [];

  // État pour le timer global du jeu (solo)
  final ValueNotifier<int> _gameTimeLeft = ValueNotifier<int>(0);
  int _gameTimeTotal = 0;
  Timer? _gameTimer;
  String? _quizEclairSelectedAnswer;
  bool _quizEclairShowHint = false;

  // État pour le jeu Estimation
  int _estimationPoints = 0;

  // État pour le jeu Quiz par Indices
  int _quizParIndicesRevealed = 1;

  // État pour les indices par jeu
  bool _gameHintVisible = false;

  // État pour l'anagramme (lettres mélangées garanties)
  String _currentAnagram = '';
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pageController = PageController();
    _initializeGame();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _animationController.dispose();
    _pageController.dispose();
    _gameTimer?.cancel();
    _gameTimeLeft.dispose();
    super.dispose();
  }

  void _initializeGame() {
    if (widget.games.isEmpty) return;
    setState(() {
      _feedback = '';
      _answered = false;
      _answerController.clear();
      _matches.clear();
      _memoryCards.clear();
      _memoryGameOver = false;
      _penduAttempts = 6;
      _usedLetters.clear();
      _penduCurrent = '';
      _shuffledEvents.clear();
      _originalEvents.clear();
      _flippedCardIndexes.clear();
      _motMystereAttempts = 0;
      _motMystereGuesses.clear();
      _gameTimeLeft.value = 0;
      _gameTimeTotal = 0;
      _quizEclairSelectedAnswer = null;
      _quizEclairShowHint = false;
      _gameTimer?.cancel();
      _estimationPoints = 0;
      _quizParIndicesRevealed = 1;
      _gameHintVisible = false;
      _currentAnagram = '';
    });

    final game = widget.games[_currentGameIndex];
    final gameType = game['type']?.toString() ?? '';

    try {
      if (gameType.contains('Relier')) {
        final pairs = (game['pairs'] as List<dynamic>?) ?? [];
        String keyField =
            game['displayMode'] == 'imageToDefinition'
                ? 'image_url'
                : 'definition';
        for (var pair in pairs) _matches[pair[keyField].toString()] = null;
      } else if (gameType.contains('Memory')) {
        final String displayMode = game['displayMode'] ?? 'wordToDefinition';
        int idCounter = 0;
        if (displayMode == 'imagePair') {
          final items =
              (game['items'] as List<dynamic>?)
                  ?.cast<Map<dynamic, dynamic>>() ??
              [];
          for (var item in items) {
            final imageUrl =
                (item['image_url'] ?? item['image_description'] ?? '')
                    .toString();
            final textLabel =
                (item['text_label'] ?? item['text'] ?? '').toString();
            _memoryCards.add({
              'id': idCounter,
              'value': imageUrl.isNotEmpty ? imageUrl : textLabel,
              'matched': false,
              'flipped': false,
            });
            _memoryCards.add({
              'id': idCounter,
              'value': textLabel.isNotEmpty ? textLabel : imageUrl,
              'matched': false,
              'flipped': false,
            });
            idCounter++;
          }
        } else {
          final rawPairs =
              (game['pairs'] as List<dynamic>?)
                  ?.cast<Map<dynamic, dynamic>>() ??
              [];
          // Deduplicate: remove pair if same word already seen
          final seenWords = <String>{};
          final pairsData =
              rawPairs.where((p) {
                final word = p['word']?.toString() ?? '';
                return seenWords.add(word);
              }).toList();
          for (var pair in pairsData) {
            String value1 =
                displayMode == 'definitionToImage'
                    ? (pair['definition'] ?? '').toString()
                    : (pair['word'] ?? '').toString();
            String value2 =
                displayMode == 'definitionToImage'
                    ? (pair['image_url'] ?? pair['image_description'] ?? '')
                        .toString()
                    : (pair['definition'] ?? '').toString();
            _memoryCards.add({
              'id': idCounter,
              'value': value1,
              'matched': false,
              'flipped': false,
            });
            _memoryCards.add({
              'id': idCounter,
              'value': value2,
              'matched': false,
              'flipped': false,
            });
            idCounter++;
          }
        }
        _memoryCards.shuffle();
      } else if (gameType.contains('Pendu')) {
        final word = (game['word'] as String? ?? '').toUpperCase();
        _penduCurrent = word.replaceAll(RegExp(r'[A-Z]'), '_');
      } else if (gameType.contains('Chronologie')) {
        _originalEvents = List<String>.from(game['events']);
        _shuffledEvents = List<String>.from(_originalEvents)..shuffle();
      } else if (gameType.contains('Mot Mystère')) {
        final word = (game['word'] as String? ?? 'ER_REUR').toUpperCase();
        _motMystereAttempts = word.length + 1;
      } else if (gameType == 'Le Mot Anagramme') {
        // Toujours mélanger les lettres de la solution pour garantir un vrai anagramme
        final solution = (game['solution'] as String? ?? '').toUpperCase();
        List<String> letters = solution.split('');
        bool canBeShuffled = letters.toSet().length > 1;
        if (canBeShuffled) {
          letters.shuffle();
          while (letters.join() == solution) {
            letters.shuffle();
          }
        }
        _currentAnagram = letters.join();
      } else if (gameType.contains('Quiz Éclair')) {
        _quizEclairSelectedAnswer = null;
        _quizEclairShowHint = false;
      }

      final isTurnBased = [
        'Memory',
        'Pendu',
        'Mot Mystère',
      ].any(gameType.contains);
      if (!isTurnBased) {
        int timeLimit = 0;
        if (gameType.contains('Quiz Éclair')) {
          timeLimit = 8;
        } else if (game['timeLimit'] != null) {
          timeLimit = int.tryParse(game['timeLimit'].toString()) ?? 0;
        }

        if (timeLimit > 0) {
          _gameTimeTotal = timeLimit;
          _gameTimeLeft.value = timeLimit;
          final answer =
              game['answer']?.toString() ??
              game['correct']?.toString() ??
              game['intruder']?.toString() ??
              game['lie']?.toString() ??
              '';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_answered) _startGameTimer(answer);
          });
        }
      }
    } catch (e) {
      setState(() {
        _feedback = 'Erreur d\'initialisation du jeu : $e';
        _answered = true;
      });
      print("Erreur d'initialisation du jeu '$gameType': $e");
      print("Données du jeu problématique : $game");
    }
  }

  void _checkAnswer(String? userAnswer) {
    if (_answered) return;
    final game = widget.games[_currentGameIndex];
    final gameType = game['type']?.toString() ?? '';
    bool isCorrect = false;
    String correctAnswerText = '';

    if (gameType.contains('Vrai ou Faux')) {
      isCorrect =
          (userAnswer?.toLowerCase() == 'true') == (game['answer'] as bool);
      correctAnswerText = game['answer'] ? 'Vrai' : 'Faux';
    } else if (gameType.contains('QCM')) {
      final rawCorrect = game['correct']?.toString() ?? '';
      final opts = List<dynamic>.from(game['options'] ?? []);
      final idx = int.tryParse(rawCorrect);
      final resolvedCorrect =
          (idx != null && idx >= 0 && idx < opts.length)
              ? ((opts[idx] is Map ? opts[idx]['text'] : opts[idx])
                      ?.toString() ??
                  rawCorrect)
              : rawCorrect;
      isCorrect = userAnswer != null && userAnswer == resolvedCorrect;
      correctAnswerText = resolvedCorrect;
    } else if (gameType.contains('Choisir l\'Intrus')) {
      isCorrect = userAnswer != null && userAnswer == game['intruder'];
      correctAnswerText = game['intruder'];
    } else if (gameType.contains('Compléter la Phrase')) {
      isCorrect =
          userAnswer != null &&
          userAnswer.trim().toLowerCase() ==
              (game['correct'] as String).toLowerCase();
      correctAnswerText = game['correct'];
    } else if (gameType.contains('Deux Vérités')) {
      isCorrect = userAnswer != null && userAnswer == game['lie'];
      correctAnswerText = game['lie'];
    } else if (gameType == 'Qui suis-je ?') {
      isCorrect =
          userAnswer != null &&
          userAnswer.trim().toLowerCase() ==
              (game['answer'] as String).toLowerCase();
      correctAnswerText = game['answer'];
    } else if (gameType == 'Le Mot Anagramme') {
      isCorrect =
          userAnswer != null &&
          userAnswer.trim().toUpperCase() ==
              (game['solution'] as String).toUpperCase();
      correctAnswerText = game['solution'];
    } else if (gameType.contains('Quiz par Indices')) {
      isCorrect =
          userAnswer != null &&
          userAnswer.trim().toLowerCase() ==
              (game['answer'] as String).toLowerCase();
      correctAnswerText = game['answer'];
      final totalClues = (game['clues'] as List?)?.length ?? 3;
      final earned =
          isCorrect
              ? (totalClues - _quizParIndicesRevealed + 1).clamp(1, totalClues)
              : 0;
      setState(() {
        _answered = true;
        if (isCorrect) {
          _feedback =
              'Correct ! +$earned point${earned > 1 ? "s" : ""} (${_quizParIndicesRevealed}/${totalClues} indices utilisés)';
          _currentScore += earned;
        } else {
          _feedback = 'Incorrect. La bonne réponse était : $correctAnswerText';
        }
      });
      return;
    }
    _finalizeAnswer(isCorrect, correctAnswerText);
  }

  void _finalizeAnswer(bool isCorrect, String correctAnswerText) {
    _gameTimer?.cancel();
    setState(() {
      _answered = true;
      if (isCorrect) {
        double points = _gameHintVisible ? 0.5 : 1.0;
        _feedback =
            'Correct !' +
            (_gameHintVisible ? ' (+0.5 pt suite à l\'indice)' : '');
        _currentScore += points;
      } else {
        _feedback = 'Incorrect. La bonne réponse était : $correctAnswerText';
      }
    });
  }

  Map<String, Color> get _motMystereKeyColors {
    final colors = <String, Color>{};
    for (final guess in _motMystereGuesses) {
      for (final fb in guess) {
        final letter = fb.letter;
        if (fb.status == LetterStatus.correctPosition) {
          colors[letter] = Colors.green.shade400;
        } else if (fb.status == LetterStatus.inWord &&
            colors[letter] != Colors.green.shade400) {
          colors[letter] = Colors.amber.shade400;
        } else if (fb.status == LetterStatus.notInWord &&
            !colors.containsKey(letter)) {
          colors[letter] = Colors.grey.shade400;
        }
      }
    }
    return colors;
  }

  Widget _buildHintButton(Map<String, dynamic> game) {
    // Si aucun indice n'a été défini à la création, on n'affiche aucun bouton
    final hint = game['hint']?.toString();
    if (hint == null || hint.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (_gameHintVisible) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hint,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _gameHintVisible = true),
        icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
        label: const Text('Voir l\'indice'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.amber.shade700,
          side: BorderSide(color: Colors.amber.shade400),
        ),
      ),
    );
  }

  void _checkMatches() {
    if (_answered) return;
    final game = widget.games[_currentGameIndex];
    final String displayMode = game['displayMode'] ?? 'definitionToWord';
    final pairs = (game['pairs'] as List<dynamic>?) ?? [];
    int correct = 0;
    List<String> corrections = [];

    for (var pair in pairs) {
      String key, correctValue, displayKey;
      if (displayMode == 'imageToDefinition') {
        key = pair['image_url'].toString();
        correctValue = pair['definition'].toString();
        displayKey = pair['image_description']?.toString() ?? 'Image';
      } else {
        key = pair['definition'].toString();
        correctValue = pair['word'].toString();
        displayKey = key;
      }
      if (_matches[key] == correctValue) {
        correct++;
      } else {
        final selected = _matches[key];
        corrections.add(
          '• $displayKey → $correctValue'
          '${selected != null ? ' (vous avez choisi : $selected)' : ''}',
        );
      }
    }

    setState(() {
      _answered = true;
      _currentScore += correct; // Point par association correcte
      if (correct == pairs.length) {
        _feedback = 'Correct ! Toutes les associations sont correctes.';
      } else if (correct == 0) {
        final solution = corrections.join('\n');
        _feedback =
            'Incorrect. Aucune association correcte.\nCorrections :\n$solution';
      } else {
        final solution = corrections.join('\n');
        _feedback =
            '$correct/${pairs.length} associations correctes.\nCorrections :\n$solution';
      }
    });
  }

  void _checkChronology() {
    if (_answered) return;
    bool allCorrect = _originalEvents.asMap().entries.every(
      (entry) => entry.value == _shuffledEvents[entry.key],
    );
    final numberedOrder = _originalEvents
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');
    _finalizeAnswer(allCorrect, 'Le bon ordre était :\n$numberedOrder');
  }

  void _flipCard(int index) {
    if (_answered ||
        _memoryCards[index]['flipped'] ||
        _flippedCardIndexes.length == 2)
      return;
    setState(() {
      _memoryCards[index]['flipped'] = true;
      _flippedCardIndexes.add(index);
    });

    if (_flippedCardIndexes.length == 2) {
      final card1Index = _flippedCardIndexes[0];
      final card2Index = _flippedCardIndexes[1];
      final card1 = _memoryCards[card1Index];
      final card2 = _memoryCards[card2Index];

      if (card1['id'] == card2['id']) {
        setState(() {
          _memoryCards[card1Index]['matched'] = true;
          _memoryCards[card2Index]['matched'] = true;
          _flippedCardIndexes.clear();
        });
        if (_memoryCards.every((c) => c['matched']))
          setState(() {
            _memoryGameOver = true;
            _finalizeAnswer(true, '');
          });
      } else {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _memoryCards[card1Index]['flipped'] = false;
              _memoryCards[card2Index]['flipped'] = false;
              _flippedCardIndexes.clear();
            });
          }
        });
      }
    }
  }

  void _guessLetter(String letter) {
    if (_answered || _usedLetters.contains(letter)) return;
    final game = widget.games[_currentGameIndex];
    final word = (game['word']?.toString() ?? '').toUpperCase();
    setState(() {
      _usedLetters.add(letter);
      if (word.contains(letter)) {
        String newCurrent = '';
        for (int i = 0; i < word.length; i++)
          newCurrent +=
              _penduCurrent[i] == '_' && word[i] == letter
                  ? letter
                  : _penduCurrent[i];
        _penduCurrent = newCurrent;
        if (!_penduCurrent.contains('_'))
          _finalizeAnswer(true, 'Le mot était $word.');
      } else {
        _penduAttempts--;
        if (_penduAttempts <= 0) _finalizeAnswer(false, 'Le mot était $word.');
      }
    });
  }

  void _checkMotMystere() {
    if (_answered) return;
    final game = widget.games[_currentGameIndex];
    final solution = (game['word'] as String? ?? '').toUpperCase();
    final guess = _answerController.text.toUpperCase();

    if (guess.length != solution.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Le mot doit faire ${solution.length} lettres.'),
        ),
      );
      return;
    }

    setState(() {
      _motMystereAttempts--;
      List<LetterFeedback> feedback = [];
      List<String> solutionLetters = solution.split('');

      // Marquer les lettres bien placées (vert)
      for (int i = 0; i < guess.length; i++) {
        if (guess[i] == solutionLetters[i]) {
          feedback.add(
            LetterFeedback(
              letter: guess[i],
              status: LetterStatus.correctPosition,
            ),
          );
          solutionLetters[i] =
              ''; // Marquer comme utilisée pour ne pas la compter en jaune
        } else {
          feedback.add(
            LetterFeedback(letter: guess[i], status: LetterStatus.none),
          ); // Statut temporaire
        }
      }

      // Marquer les lettres mal placées (jaune) et absentes (gris)
      for (int i = 0; i < feedback.length; i++) {
        if (feedback[i].status == LetterStatus.none) {
          if (solutionLetters.contains(guess[i])) {
            feedback[i] = LetterFeedback(
              letter: guess[i],
              status: LetterStatus.inWord,
            );
            solutionLetters[solutionLetters.indexOf(guess[i])] = '';
          } else {
            feedback[i] = LetterFeedback(
              letter: guess[i],
              status: LetterStatus.notInWord,
            );
          }
        }
      }

      _motMystereGuesses.add(feedback);
      _answerController.clear();

      if (guess == solution) {
        _finalizeAnswer(true, '');
      } else if (_motMystereAttempts <= 0) {
        _finalizeAnswer(false, 'Le mot était $solution.');
      }
    });
  }

  void _nextGame() {
    _gameTimer?.cancel();
    if (_currentGameIndex < widget.games.length - 1) {
      setState(() {
        _currentGameIndex++;
        _initializeGame();
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onScoreUpdate(_currentScore);
      Navigator.pop(context);
    }
  }

  Widget _cachedImage(
    String url, {
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      fit: fit,
      placeholder:
          (_, __) => const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 46),
    );
  }

  void _startGameTimer(String correctAnswer) {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_gameTimeLeft.value > 0) {
        _gameTimeLeft.value--;
      } else {
        timer.cancel();
        if (!_answered) _finalizeAnswer(false, correctAnswer);
      }
    });
  }

  void _checkQuizEclair(String userAnswer, String correctAnswer) {
    if (_answered) return;
    _gameTimer?.cancel();
    setState(() {
      _quizEclairSelectedAnswer = userAnswer;
    });
    final isCorrect =
        userAnswer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
    _finalizeAnswer(isCorrect, correctAnswer);
  }

  void _checkEstimation(double correctAnswer, String? unit) {
    if (_answered) return;
    final userValue = double.tryParse(_answerController.text.trim());
    if (userValue == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entrez un nombre valide.')));
      return;
    }
    // Calcul du score selon l'erreur relative
    final double percentError =
        correctAnswer != 0
            ? (userValue - correctAnswer).abs() / correctAnswer.abs()
            : (userValue - correctAnswer).abs();
    int points;
    String emoji;
    if (percentError == 0) {
      points = 10;
      emoji = '🎯 Parfait ! Réponse exacte !';
    } else if (percentError <= 0.01) {
      points = 9;
      emoji = 'ðŸ”¥ Excellent ! Erreur < 1%.';
    } else if (percentError <= 0.05) {
      points = 7;
      emoji = 'â­ Très bien ! Erreur < 5%.';
    } else if (percentError <= 0.15) {
      points = 5;
      emoji = 'ðŸ‘ Bien ! Erreur < 15%.';
    } else if (percentError <= 0.30) {
      points = 2;
      emoji = 'ðŸ™‚ Pas loin ! Erreur < 30%.';
    } else {
      points = 0;
      emoji = 'âŒ Trop éloigné.';
    }
    final unitStr = unit != null && unit.isNotEmpty ? ' $unit' : '';
    final correctStr = correctAnswer.toStringAsFixed(
      correctAnswer.truncateToDouble() == correctAnswer ? 0 : 2,
    );
    setState(() {
      _estimationPoints = points;
      _answered = true;
      _currentScore += (points ~/ 4); // 0 à 2 points sur le score global solo
      _feedback =
          'La réponse était $correctStr$unitStr\n$emoji ($points/10 pts)';
    });
  }

  Widget _buildQuizEclairWidget(Map<String, dynamic> game) {
    final question = game['question']?.toString() ?? '';
    final answer =
        game['answer']?.toString() ?? game['correct']?.toString() ?? '';
    final choices = List<String>.from(game['choices'] ?? game['options'] ?? []);
    final hint = game['hint']?.toString();
    final allOptions = {...choices, answer}.toList();
    final seed = question.hashCode;
    allOptions.sort(
      (a, b) =>
          ((a.hashCode + seed) % 1000).compareTo((b.hashCode + seed) % 1000),
    );
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: AppColors.quizOrange,
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Quiz Éclair !',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.quizOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hint != null && _quizEclairShowHint) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Indice : $hint',
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...allOptions.map((option) {
          final isCorrect =
              option.trim().toLowerCase() == answer.trim().toLowerCase();
          final isThisSelected = option == _quizEclairSelectedAnswer;
          Color bgColor = Colors.white;
          Color borderColor = const Color(0xFFFF6B35).withOpacity(0.4);
          Color textColor = Colors.black87;
          if (_answered && isCorrect) {
            bgColor = const Color(0xFF2ECC71);
            textColor = Colors.white;
            borderColor = const Color(0xFF2ECC71);
          } else if (_answered && isThisSelected && !isCorrect) {
            bgColor = const Color(0xFFE74C3C);
            textColor = Colors.white;
            borderColor = const Color(0xFFE74C3C);
          }
          return GestureDetector(
            onTap: _answered ? null : () => _checkQuizEclair(option, answer),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_answered && isCorrect)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  if (_answered && isThisSelected && !isCorrect)
                    const Icon(Icons.cancel, color: Colors.white, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
        if (hint != null && !_answered && !_quizEclairShowHint)
          TextButton.icon(
            onPressed:
                () => setState(() {
                  _quizEclairShowHint = true;
                  _gameTimeLeft.value = max(0, _gameTimeLeft.value - 2);
                }),
            icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
            label: const Text('Voir un indice (-2s)'),
            style: TextButton.styleFrom(foregroundColor: Colors.amber),
          ),
      ],
    );
  }

  Widget _buildGameTimer() {
    if (_gameTimeTotal <= 0) return const SizedBox.shrink();

    return ValueListenableBuilder<int>(
      valueListenable: _gameTimeLeft,
      builder: (context, timeLeft, child) {
        final timeRatio = timeLeft / _gameTimeTotal;
        final Color timerColor =
            timeRatio > 0.5
                ? AppColors.successGreen
                : timeRatio > 0.25
                ? AppColors.warningOrange
                : AppColors.errorRed;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_answered)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: timerColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: timerColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_rounded, size: 16, color: timerColor),
                        const SizedBox(width: 4),
                        Text(
                          '$timeLeft s',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: timerColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_answered)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: timeRatio,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                  minHeight: 8,
                ),
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.games.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz vide')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline_rounded, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Veuillez ajouter des questions avant de jouer.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final game = widget.games[_currentGameIndex];
    final gameType = game['type']?.toString() ?? 'Inconnu';
    final progress = (_currentGameIndex + 1) / max(1, widget.games.length);
    final progressColor =
        Theme.of(context).brightness == Brightness.dark
            ? AppColors.neonCyan
            : AppColors.primaryBlue;
    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentGameIndex + 1}/${widget.games.length}'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.deepBlue, AppColors.primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const Icon(Icons.person_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.games.length,
        onPageChanged: (index) {
          if (index != _currentGameIndex) {
            setState(() => _currentGameIndex = index);
            _initializeGame();
          }
        },
        itemBuilder: (context, pageIndex) {
          if (pageIndex != _currentGameIndex) {
            return const SizedBox.expand();
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StyledCard(
                      child: Column(
                        children: [
                          // Indique le type/format de la question courante
                          Text(
                            'Format : $gameType',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          if (game['theme'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Thème : ${game['theme']}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 280.ms)
                    .moveY(begin: 14, end: 0, duration: 280.ms),
                const SizedBox(height: 16),
                _buildGameTimer(),
                _buildGameWidget(game, gameType),
                const SizedBox(height: 8),
                if (!gameType.contains('Quiz par Indices') &&
                    (game['hintEnabled'] == null ||
                        game['hintEnabled'] == true))
                  _buildHintButton(game),
                const SizedBox(height: 16),
                if (_feedback.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                          (_feedback.contains('Correct') ||
                                  _feedback.contains('Gagné'))
                              ? const Color(0xFF2ECC71).withOpacity(0.1)
                              : const Color(0xFFE74C3C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            (_feedback.contains('Correct') ||
                                    _feedback.contains('Gagné'))
                                ? const Color(0xFF2ECC71).withOpacity(0.4)
                                : const Color(0xFFE74C3C).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (_feedback.contains('Correct') ||
                                  _feedback.contains('Gagné'))
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color:
                              (_feedback.contains('Correct') ||
                                      _feedback.contains('Gagné'))
                                  ? const Color(0xFF2ECC71)
                                  : const Color(0xFFE74C3C),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _feedback,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color:
                                  (_feedback.contains('Correct') ||
                                          _feedback.contains('Gagné'))
                                      ? const Color(0xFF2ECC71)
                                      : const Color(0xFFE74C3C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_answered) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _nextGame,
                    icon: Icon(
                      _currentGameIndex < widget.games.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.flag_rounded,
                    ),
                    label: Text(
                      _currentGameIndex < widget.games.length - 1
                          ? 'Question Suivante'
                          : 'Terminer le Quiz',
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameWidget(Map<String, dynamic> game, String gameType) {
    if ([
      'Vrai ou Faux',
      'QCM',
      'Choisir l\'Intrus',
      'Deux Vérités, un Mensonge',
    ].contains(gameType)) {
      return _buildStandardGameBody(game, gameType);
    }
    if ([
      'Compléter la Phrase',
      'Qui suis-je ?',
      'Le Mot Anagramme',
      'Quiz par Indices',
    ].contains(gameType)) {
      String questionText = '';
      String? hintText;
      if (gameType == 'Compléter la Phrase')
        questionText = game['question'] ?? '';
      if (gameType == 'Qui suis-je ?') questionText = game['riddle'] ?? '';
      if (gameType == 'Le Mot Anagramme') {
        questionText = 'Réorganisez ces lettres pour trouver le mot :';
        hintText = game['hint']?.isNotEmpty == true ? game['hint'] : null;
      }
      if (gameType == 'Quiz par Indices') {
        final clues =
            (game['clues'] as List?)?.join('\n') ?? 'Indices non trouvés.';
        questionText = "Trouvez la réponse avec ces indices :\n$clues";
      }
      return Column(
        children: [
          Text(
            questionText,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          if (game['image_url'] != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _cachedImage(
                game['image_url'],
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          ],
          if (gameType == 'Le Mot Anagramme') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo.withOpacity(0.3)),
              ),
              child: Text(
                _currentAnagram.split('').join('  '),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.indigo,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (hintText != null) ...[
            const SizedBox(height: 8),
            Text(
              'Indice : $hintText',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _answerController,
            decoration: const InputDecoration(
              labelText: 'Votre réponse',
              border: OutlineInputBorder(),
            ),
            enabled: !_answered,
            onSubmitted: _answered ? null : (value) => _checkAnswer(value),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                _answered ? null : () => _checkAnswer(_answerController.text),
            child: const Text('Valider'),
          ),
        ],
      );
    }
    if (gameType.contains('Pendu')) {
      return Column(
        children: [
          if (game['hint'] != null)
            Text(
              'Indice : ${game['hint']}',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: 16),
          Center(
            child: CustomPaint(
              size: const Size(150, 150),
              painter: HangmanPainter(mistakes: 6 - _penduAttempts),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _penduCurrent.split('').join(' '),
            style: const TextStyle(fontSize: 32, letterSpacing: 8),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children:
                'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map((letter) {
                  final isUsed = _usedLetters.contains(letter);
                  return ElevatedButton(
                    onPressed:
                        (_answered || isUsed)
                            ? null
                            : () => _guessLetter(letter),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUsed ? Colors.grey : Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(letter),
                  );
                }).toList(),
          ),
        ],
      );
    }
    if (gameType.contains('Chronologie')) {
      return Column(
        children: [
          Text(
            game['question'],
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: _shuffledEvents.length * 70.0,
            child: ReorderableListView.builder(
              itemCount: _shuffledEvents.length,
              itemBuilder:
                  (context, index) => Card(
                    key: ValueKey(_shuffledEvents[index]),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle),
                      title: Text(_shuffledEvents[index]),
                    ),
                  ),
              onReorder: (oldIndex, newIndex) {
                if (_answered) return;
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  _shuffledEvents.insert(
                    newIndex,
                    _shuffledEvents.removeAt(oldIndex),
                  );
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          if (!_answered)
            ElevatedButton(
              onPressed: _checkChronology,
              child: const Text('Vérifier l\'ordre'),
            ),
        ],
      );
    }
    if (gameType.contains('Relier')) {
      final String displayMode = game['displayMode'] ?? 'definitionToWord';
      final List<dynamic> pairs = (game['pairs'] as List<dynamic>?) ?? [];
      final List<String> options =
          (displayMode == 'imageToDefinition')
              ? pairs.map((p) => p['definition'].toString()).toList()
              : pairs.map((p) => p['word'].toString()).toList();
      options.shuffle();

      return Column(
        children: [
          Text(
            displayMode == 'imageToDefinition'
                ? 'Associez chaque image à sa définition :'
                : 'Associez chaque définition à son mot :',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ..._matches.keys.map(
            (key) => Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          displayMode == 'imageToDefinition'
                              ? _cachedImage(key, height: 80, fit: BoxFit.cover)
                              : Text(key),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _matches[key],
                      hint: const Text('Choisir'),
                      items:
                          options
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ),
                              )
                              .toList(),
                      onChanged:
                          _answered
                              ? null
                              : (value) =>
                                  setState(() => _matches[key] = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_answered)
            ElevatedButton(
              onPressed: _checkMatches,
              child: const Text('Vérifier les associations'),
            ),
        ],
      );
    }
    if (gameType.contains('Memory')) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _memoryCards.length,
        itemBuilder: (context, index) {
          final card = _memoryCards[index];
          final value = card['value'].toString();
          Widget cardContent;

          if (card['flipped'] && value.startsWith('http')) {
            cardContent = Padding(
              padding: const EdgeInsets.all(4.0),
              child: _cachedImage(value, fit: BoxFit.cover),
            );
          } else if (card['flipped']) {
            cardContent = Center(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            );
          } else {
            cardContent = Container();
          }

          return GestureDetector(
            onTap: () => _flipCard(index),
            child: Card(
              clipBehavior: Clip.antiAlias,
              color:
                  card['matched']
                      ? Colors.green.shade200
                      : (card['flipped']
                          ? Colors.blue.shade100
                          : Colors.grey.shade400),
              child: cardContent,
            ),
          );
        },
      );
    }
    // NOUVEAU: Logique d'affichage pour Mot Mystère
    if (gameType.contains('Mot Mystère')) {
      final word = (game['word'] as String? ?? '').toUpperCase();
      return Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Devinez le mot de ${word.length} lettres',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: Colors.orange,
                        size: 14,
                      ),
                      Text(
                        ' Essais restants : $_motMystereAttempts',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Affichage des tentatives précédentes
          ..._motMystereGuesses.map((guess) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    guess.map((fb) {
                      Color color;
                      switch (fb.status) {
                        case LetterStatus.correctPosition:
                          color = Colors.green.shade400;
                          break;
                        case LetterStatus.inWord:
                          color = Colors.amber.shade400;
                          break;
                        default:
                          color = Colors.grey.shade300;
                      }
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 40,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            fb.letter,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            );
          }).toList(),
          // Espaces vides
          ...List.generate(
            max(0, _motMystereAttempts - _motMystereGuesses.length),
            (_) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(word.length, (_) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 40,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (!_answered) ...[
            TextField(
              controller: _answerController,
              maxLength: word.length,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Votre proposition (${word.length} lettres)',
              ),
              enabled: !_answered,
              onSubmitted: _answered ? null : (_) => _checkMotMystere(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _answered ? null : _checkMotMystere,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Proposer'),
            ),
          ],
          // Clavier virtuel montrant les lettres utilisées
          const SizedBox(height: 16),
          Builder(
            builder: (_) {
              final keyColors = _motMystereKeyColors;
              const rows = ['AZERTYUIOP', 'QSDFGHJKLM', 'WXCVBN'];
              return Column(
                children:
                    rows
                        .map(
                          (row) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  row.split('').map((letter) {
                                    final color =
                                        keyColors[letter] ??
                                        Colors.grey.shade200;
                                    final textColor =
                                        keyColors.containsKey(letter)
                                            ? Colors.white
                                            : Colors.black87;
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      width: 30,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          letter,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      );
    }
    // NOUVEAU JEU: Quiz Éclair
    if (gameType.contains('Quiz Éclair')) {
      return _buildQuizEclairWidget(game);
    }
    // NOUVEAU JEU: Estimation
    if (gameType.contains('Estimation')) {
      return _buildEstimationWidget(game);
    }
    // NOUVEAU JEU: Quiz par Indices
    if (gameType.contains('Quiz par Indices')) {
      final clues = List<String>.from(game['clues'] ?? []);
      const clueIcons = [
        Icons.help_outline,
        Icons.lightbulb_outline,
        Icons.emoji_objects_outlined,
      ];
      return Column(
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Color(0xFF6C3FC7),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Quiz par Indices',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C3FC7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            _quizParIndicesRevealed.clamp(0, clues.length),
            (i) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6C3FC7).withOpacity(0.15),
                  child: Icon(
                    i < clueIcons.length ? clueIcons[i] : Icons.info_outline,
                    color: const Color(0xFF6C3FC7),
                    size: 18,
                  ),
                ),
                title: Text(
                  'Indice ${i + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF6C3FC7),
                  ),
                ),
                subtitle: Text(clues[i], style: const TextStyle(fontSize: 15)),
              ),
            ),
          ),
          if (_quizParIndicesRevealed < clues.length && !_answered) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _quizParIndicesRevealed++),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(
                'Voir l\'indice ${_quizParIndicesRevealed + 1}/${clues.length} (-1 point)',
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (!_answered)
            Builder(
              builder: (ctx) {
                final total = clues.length;
                final pot = (total - _quizParIndicesRevealed + 1).clamp(
                  1,
                  total,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C3FC7).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFF6C3FC7),
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Répondre maintenant = +$pot point${pot > 1 ? "s" : ""}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6C3FC7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'max $total',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _answerController,
            decoration: const InputDecoration(
              labelText: 'Votre réponse',
              border: OutlineInputBorder(),
            ),
            enabled: !_answered,
            onSubmitted: _answered ? null : (v) => _checkAnswer(v),
          ),
          const SizedBox(height: 16),
          if (!_answered)
            ElevatedButton(
              onPressed: () => _checkAnswer(_answerController.text),
              child: const Text('Valider'),
            ),
        ],
      );
    }
    return Center(child: Text('Type de jeu "$gameType" non pris en charge.'));
  }

  Widget _buildEstimationWidget(Map<String, dynamic> game) {
    final question = game['question']?.toString() ?? '';
    final correctAnswer = (game['answer'] as num?)?.toDouble() ?? 0;
    final unit = game['unit']?.toString();
    final hint = game['hint']?.toString();
    final unitStr = unit != null && unit.isNotEmpty ? ' $unit' : '';

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calculate_rounded,
                      color: Color(0xFF6C3FC7),
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Jeu des Estimations',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C3FC7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (unit != null && unit.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Chip(
                    label: Text('Unité : $unit'),
                    backgroundColor: const Color(0xFF6C3FC7).withOpacity(0.1),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!_answered) ...[
          TextField(
            controller: _answerController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            enabled: !_answered,
            decoration: InputDecoration(
              labelText: 'Votre estimation$unitStr',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.edit_rounded),
            ),
            onSubmitted: (_) => _checkEstimation(correctAnswer, unit),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _checkEstimation(correctAnswer, unit),
            icon: const Icon(Icons.send_rounded),
            label: const Text('Valider mon estimation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C3FC7),
            ),
          ),
        ] else ...[
          // Barre de progression de précision
          Builder(
            builder: (_) {
              final userVal =
                  double.tryParse(_answerController.text.trim()) ?? 0;
              final double pctErr =
                  correctAnswer != 0
                      ? (userVal - correctAnswer).abs() / correctAnswer.abs()
                      : 1.0;
              final double accuracy = (1.0 - pctErr.clamp(0.0, 1.0));
              return Column(
                children: [
                  Text(
                    'Précision : ${(accuracy * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: accuracy,
                      minHeight: 14,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        accuracy >= 0.85
                            ? Colors.green
                            : accuracy >= 0.70
                            ? Colors.lightGreen
                            : accuracy >= 0.50
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score : $_estimationPoints / 10 points',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6C3FC7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStandardGameBody(Map<String, dynamic> game, String gameType) {
    List<dynamic> options = [];
    Map<String, dynamic> questionData = {};
    String correctAnswer = '';

    if (game['question'] is Map) {
      questionData = Map<String, dynamic>.from(game['question']);
    } else if (game['question'] is String) {
      questionData['text'] = game['question'];
    } else {
      questionData['text'] = 'Question non trouvée.';
    }

    if (gameType.contains('Vrai ou Faux')) {
      options = ['True', 'False'];
      correctAnswer = game['answer'].toString();
    } else if (gameType.contains('QCM')) {
      options = List<dynamic>.from(game['options'] ?? []);
      final rawCorrect = game['correct']?.toString() ?? '';
      final idx = int.tryParse(rawCorrect);
      correctAnswer =
          (idx != null && idx >= 0 && idx < options.length)
              ? ((options[idx] is Map ? options[idx]['text'] : options[idx])
                      ?.toString() ??
                  rawCorrect)
              : rawCorrect;
    } else if (gameType.contains('Choisir l\'Intrus')) {
      options = List<dynamic>.from(game['options'] ?? []);
      correctAnswer = game['intruder']?.toString() ?? '';
    } else if (gameType.contains('Deux Vérités') ||
        gameType.contains('Deux Vérités')) {
      options = List<dynamic>.from(game['statements'] ?? []);
      correctAnswer = game['lie']?.toString() ?? '';
      questionData['text'] = "Identifiez le mensonge parmi ces affirmations :";
    } else if (gameType.contains('Quiz Éclair') ||
        gameType.contains('Quiz Eclair')) {
      options = List<dynamic>.from(
        game['choices'] ?? game['options'] ?? ['Vrai', 'Faux', 'Peut-Être'],
      );
      correctAnswer =
          game['correct']?.toString() ?? game['answer']?.toString() ?? '';
    }

    Widget questionWidget = Column(
      children: [
        if (widget.qcmQuestionMode != DisplayMode.text &&
            questionData['image_url'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _cachedImage(
              questionData['image_url'],
              height: 150,
              fit: BoxFit.contain,
            ),
          ),
        if (questionData['image_url'] == null && game['image_url'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _cachedImage(
                game['image_url'],
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
        if (widget.qcmQuestionMode != DisplayMode.image &&
            questionData['text'] != null)
          Text(
            questionData['text'],
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
      ],
    );

    return Column(
      children: [
        questionWidget,
        const SizedBox(height: 16),
        ...options.map((option) {
          String optionText;
          String? imageUrl;
          String? valueToCompare;

          if (option is Map) {
            optionText = option['text'] ?? '';
            imageUrl = option['image_url'];

            valueToCompare = option['text'];
          } else {
            optionText = option.toString();
            valueToCompare = optionText;
          }

          Widget optionContent = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.qcmAnswerMode != DisplayMode.text && imageUrl != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: _cachedImage(imageUrl, fit: BoxFit.contain),
                  ),
                ),
              if (widget.qcmAnswerMode != DisplayMode.image &&
                  optionText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    optionText,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          );

          return SizedBox(
            height: widget.qcmAnswerMode == DisplayMode.text ? 60 : 150,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap:
                    _answered
                        ? null
                        : () {
                          _checkAnswer(valueToCompare);
                        },
                child: optionContent,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
