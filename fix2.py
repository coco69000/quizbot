import os

main_file = r'c:\Users\coren\AndroidStudioProjects\quizbot\lib\main.dart'

with open(main_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 1. Regex fix
for i, line in enumerate(lines):
    if "final jsonMatch = RegExp(r'\\[[\\s\\S]*\\]').firstMatch(cleanedContent);" in line:
        lines[i] = "        // Accepte un tableau [...] OU un objet {...}\n        final jsonMatch = RegExp(r'(\\[[\\s\\S]*\\]|\\{[\\s\\S]*\\})').firstMatch(cleanedContent);\n"
    if "throw FormatException('No JSON array found in AI response');" in line:
        lines[i] = "          throw FormatException('Aucun JSON valide trouvé dans la réponse de l\\'IA');\n"

# 2. _processImagesForGames
process_start = -1
for i, line in enumerate(lines):
    if "if (itemsToProcess.isNotEmpty) {" in line and "Total d\\'images à traiter trouvé" in lines[i+1]:
        process_start = i
        break

if process_start != -1:
    process_end = process_start
    for i in range(process_start, len(lines)):
        if "return games;" in lines[i]:
            process_end = i
            break
    
    new_process_chunk = """    if (itemsToProcess.isNotEmpty) {
      print('>>> Total d\\'images à traiter trouvé : ${itemsToProcess.length}');

      // Traiter par lots de 3 pour éviter le timeout
      const int chunkSize = 3;
      for (int i = 0; i < itemsToProcess.length; i += chunkSize) {
        if (!mounted) return games;

        import 'dart:math';
        final endIndex = min(i + chunkSize, itemsToProcess.length);
        setState(() {
          _status = 'Recherche d\\'images... ($endIndex/${itemsToProcess.length})';
        });

        final chunk = itemsToProcess.sublist(i, endIndex);
        
        await Future.wait(
          chunk.map((item) => _fetchAndAssignImageUrl(item, 'image_description'))
        );

        if (endIndex < itemsToProcess.length) {
          await Future.delayed(const Duration(milliseconds: 600)); 
        }
      }
    } else {
      print('>>> Aucune "image_description" trouvée. Traitement des images sauté.');
    }
    """
    # Wait, dart import 'dart:math' cannot be inside a function! I should use dart's min which is probably already imported.
    new_process_chunk = new_process_chunk.replace("import 'dart:math';\n        ", "")
    lines[process_start:process_end] = [new_process_chunk]

# 3. _guessLetterOnline
guess_start = -1
for i, line in enumerate(lines):
    if "Future<void> _guessLetterOnline(String letter) async {" in line:
        guess_start = i
        break

if guess_start != -1:
    guess_end = guess_start
    brace_count = 0
    found_first_brace = False
    for i in range(guess_start, len(lines)):
        if "{" in lines[i]:
            brace_count += lines[i].count("{")
            found_first_brace = True
        if "}" in lines[i]:
            brace_count -= lines[i].count("}")
        if found_first_brace and brace_count == 0:
            guess_end = i + 1
            break

    new_guess_chunk = """  Future<void> _guessLetterOnline(String letter) async {
    if (widget.isGuest) return;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance.collection('onlineRooms').doc(widget.roomId);
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;
      
      var data = snapshot.data() as Map<String, dynamic>;
      var players = Map<String, dynamic>.from(data['players']);
      var gameState = Map<String, dynamic>.from(data['gameState']);
      var hState = Map<String, dynamic>.from(gameState['hangmanState']);

      if (hState['gameOver'] == true || hState['currentPlayerName'] != widget.playerName) return;

      var usedLetters = List<String>.from(hState['usedLetters'] ?? []);
      int mistakes = hState['mistakes'] ?? 0;
      final word = (hState['wordToGuess'] as String).toUpperCase();
      final currentPlayerName = hState['currentPlayerName'];

      if (usedLetters.contains(letter)) return;
      usedLetters.add(letter);

      bool letterFound = word.contains(letter);
      if (!letterFound) {
        mistakes++;
      }

      String currentDisplay = word.split('').map((char) => usedLetters.contains(char) ? char : '_').join();
      bool isWordGuessed = !currentDisplay.contains('_');

      if (isWordGuessed) {
        hState['gameOver'] = true;
        players[currentPlayerName]['score'] = (players[currentPlayerName]['score'] ?? 0) + 20;
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
"""
    lines[guess_start:guess_end] = [new_guess_chunk]


# 4. _updateGlobalScoreAndHistory
score_start = -1
for i, line in enumerate(lines):
    if "  Future<void> _updateGlobalScoreAndHistory(BuildContext context) async {" in line:
        score_start = i
        break

if score_start != -1:
    score_end = score_start
    brace_count = 0
    found_first_brace = False
    for i in range(score_start, len(lines)):
        if "{" in lines[i]:
            brace_count += lines[i].count("{")
            found_first_brace = True
        if "}" in lines[i]:
            brace_count -= lines[i].count("}")
        if found_first_brace and brace_count == 0:
            score_end = i + 1
            break
            
    new_score_chunk = """  Future<void> _updateGlobalScoreAndHistory(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || playerName == null || playerScores.isEmpty)
      return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    final userScore = playerScores[playerName] ?? 0;
    final maxScore = playerScores.values.reduce(max);
    final bool wasWinnerThisGame = (userScore == maxScore && playerScores.length > 1 && userScore > 0);
    final pointsGained = playerScores.length - 1;

    String? quizId;
    bool hasAlreadyWonThisQuiz = false;
    try {
      final roomDoc = await FirebaseFirestore.instance.collection('onlineRooms').doc(roomId).get();
      if (roomDoc.exists) {
        quizId = roomDoc.data()?['quizId'];
      }
      if (quizId != null) {
        final historySnapshot = await FirebaseFirestore.instance
            .collection('userGameHistory')
            .where('userId', isEqualTo: currentUser.uid)
            .where('quizId', isEqualTo: quizId)
            .where('wasWinner', isEqualTo: true)
            .limit(1)
            .get();
        if (historySnapshot.docs.isNotEmpty) {
          hasAlreadyWonThisQuiz = true;
        }
      }
    } catch (e) {
      print("Impossible de récupérer le quizId ou l'historique : $e");
    }

    bool isReplay = false;
    if (quizId != null) {
      final historySnapshot = await FirebaseFirestore.instance
          .collection('userGameHistory')
          .where('userId', isEqualTo: currentUser.uid)
          .where('quizId', isEqualTo: quizId)
          .limit(1)
          .get();
      if (historySnapshot.docs.isNotEmpty) isReplay = true;
    }

    double averageDifficulty = 5.0;
    double successRate = 0.0;
    if (quizText != null && gamesPlayed != null && gamesPlayed!.isNotEmpty) {
      final totalPossibleScore = gamesPlayed!.length * 10;
      successRate = totalPossibleScore > 0 ? (userScore / totalPossibleScore) : 0.0;
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

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot userSnapshot = await transaction.get(userRef);
      
      if (!userSnapshot.exists) {
        transaction.set(userRef, {
          'username': playerName,
          'score': wasWinnerThisGame ? pointsGained : 0,
          'iq': 100.0,
          'totalGamesPlayed': 1,
        });
        return; // On arrête la transaction ici pour un nouvel utilisateur
      }

      final userData = userSnapshot.data() as Map<String, dynamic>;
      int currentGlobalScore = userData['score'] ?? 0;
      double currentIQ = (userData['iq'] as num? ?? 100.0).toDouble();
      int totalGamesPlayed = userData['totalGamesPlayed'] as int? ?? 0;

      // 1. Calcul du nouveau score
      if (wasWinnerThisGame && pointsGained > 0 && !hasAlreadyWonThisQuiz) {
        currentGlobalScore += pointsGained;
      }

      // 2. Calcul de l'évolution du QI (si des jeux ont été joués)
      double newIQ = currentIQ;
      if (quizText != null && gamesPlayed != null && gamesPlayed!.isNotEmpty) {
        // Ton algorithme QI
        double expectedPerformance = 1.0 / (1.0 + exp(-(currentIQ - 100.0) / 40.0));
        double actualPerformance = successRate.toDouble();
        double difficultyMultiplier = 0.15 + pow(averageDifficulty / 10.0, 1.4).toDouble() * 2.2;
        
        double experienceFactor = totalGamesPlayed < 5 ? 3.0 : totalGamesPlayed < 20 ? 2.0 : totalGamesPlayed < 50 ? 1.4 : 1.0;
        double volatilityFactor = 1.0 + 0.6 * pow((currentIQ - 100.0).abs() / 50.0, 0.7).clamp(0.0, 1.2);
        double kFactor = 4.5 * experienceFactor * volatilityFactor;
        
        Set<String> gameTypes = gamesPlayed!.map((g) => (g['type']?.toString() ?? '')).toSet();
        double diversityBonus = (0.7 + gameTypes.length * 0.08).clamp(0.7, 1.5);
        double countWeight = (0.4 + gamesPlayed!.length / 14.0).clamp(0.6, 1.3);
        
        double performanceImpact = kFactor * (actualPerformance - expectedPerformance) * difficultyMultiplier * diversityBonus * countWeight;
        
        if (performanceImpact > 0 && currentIQ > 140) {
          performanceImpact *= max(0.3, 1.0 - (currentIQ - 140.0) / 60.0);
        } else if (performanceImpact < 0 && currentIQ < 70) {
          performanceImpact *= max(0.3, 1.0 - (70.0 - currentIQ) / 30.0);
        }
        
        if (isReplay && performanceImpact > 0) {
          performanceImpact = 0;
        } else if (isReplay && performanceImpact < 0) {
          performanceImpact *= 0.4;
        }
        
        performanceImpact = performanceImpact.clamp(-5.0, 5.0);
        newIQ = (currentIQ + performanceImpact).clamp(50.0, 200.0);
      }

      // 3. Application de toutes les modifications d'un coup en toute sécurité
      transaction.update(userRef, {
        'score': currentGlobalScore,
        'iq': newIQ,
        'totalGamesPlayed': totalGamesPlayed + 1,
      });
    });

    // Notifications
    if (wasWinnerThisGame && pointsGained > 0 && mounted) {
      if (hasAlreadyWonThisQuiz) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Vous avez déjà gagné ce quiz. Aucun point ajouté.'),
          backgroundColor: Colors.orange,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Félicitations ! Vous avez gagné $pointsGained points !'),
          backgroundColor: Colors.green,
        ));
      }
    }

    final theme = await _extractThemeFromText(quizText ?? '');
    await FirebaseFirestore.instance.collection('userGameHistory').add({
      'userId': currentUser.uid,
      'quizId': quizId,
      'averageDifficulty': averageDifficulty,
      'playerName': playerName,
      'quizText': quizText,
      'gamesPlayed': gamesPlayed,
      'userScore': userScore,
      'totalPlayers': playerScores.length,
      'gameType': 'online',
      'timestamp': FieldValue.serverTimestamp(),
      'theme': theme,
      'successRate': successRate,
      'wasWinner': wasWinnerThisGame,
    });
  }
"""
    lines[score_start:score_end] = [new_score_chunk]

with open(main_file, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("Done replacements in main.dart")
