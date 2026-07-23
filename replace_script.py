import sys

file_path = r"c:\Users\coren\AndroidStudioProjects\quizbot\lib\main.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

start_marker = "  Widget _buildCreateQuizTab("
end_marker = "class ManualQuizCreatorPage extends StatefulWidget {"

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx == -1:
    print("Error: Could not find start marker.")
    sys.exit(1)
if end_idx == -1:
    print("Error: Could not find end marker.")
    sys.exit(1)

# Find the end of the previous class
# We want to keep everything before `class ManualQuizCreatorPage extends StatefulWidget {`
# Actually, let's just go backwards from end_idx to find "} // end of _HomePageState"
# or just `}\n}\n\n// ===`
end_idx = content.rfind("  }\n}\n", start_idx, end_idx) + 5

if end_idx < start_idx:
    # Try with \r\n
    end_idx = content.rfind("  }\r\n}\r\n", start_idx, end_idx) + 7

if end_idx < start_idx:
    print("Error: Could not find the end of the method.")
    sys.exit(1)

replacement = """  Widget _buildCreateQuizTab(
    int nonVipGenerationsRemaining,
    int vipGenerationsRemaining,
    int vipImageGenerationsRemaining,
  ) {
    String displayModeToString(DisplayMode mode) {
      switch (mode) {
        case DisplayMode.text: return 'Texte uniquement';
        case DisplayMode.image: return 'Image uniquement';
        case DisplayMode.textAndImage: return 'Texte + Image';
      }
    }

    String matchDisplayModeToString(MatchDisplayMode mode) {
      switch (mode) {
        case MatchDisplayMode.definitionToWord: return 'Définition à Mot';
        case MatchDisplayMode.imageToDefinition: return 'Image à Définition';
      }
    }

    String memoryDisplayModeToString(MemoryDisplayMode mode) {
      switch (mode) {
        case MemoryDisplayMode.wordToDefinition: return 'Mot à Définition';
        case MemoryDisplayMode.definitionToImage: return 'Définition à Image';
        case MemoryDisplayMode.imagePair: return 'Paire d\\'images identiques';
      }
    }

    final selectedGamesCount = _selectedGames.entries.where((entry) => entry.value).length;
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
                              Icon(Icons.lightbulb, color: Colors.yellow.shade700),
                              const SizedBox(width: 8),
                              Text('QI: ${_userIQ.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        if (_isVip)
                          Row(
                            children: [
                              const Chip(
                                label: Text('VIP'),
                                backgroundColor: Colors.amber,
                                labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _cancelVipSubscription,
                                child: const Text('Se désabonner', style: TextStyle(color: Colors.red)),
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
                        style: TextStyle(color: nonVipGenerationsRemaining <= 5 ? Colors.red : Colors.grey[700]),
                      ),
                    if (_isVip) ...[
                      Text(
                        'Générations restantes aujourd\\'hui : $vipGenerationsRemaining / 30',
                        style: TextStyle(color: vipGenerationsRemaining <= 5 ? Colors.red : Colors.grey[700]),
                      ),
                      Text(
                        'Générations avec images restantes aujourd\\'hui : $vipImageGenerationsRemaining / 20',
                        style: TextStyle(color: vipImageGenerationsRemaining <= 5 ? Colors.red : Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
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
          const Text('Sélectionnez les jeux :', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StyledCard(
            child: Column(
              children: _selectedGames.keys.map((game) {
                final isSelected = _selectedGames[game] ?? false;
                final hintEnabled = _hintsEnabled[game] ?? false;
                final isLockedForNonVip = !_isVip && !isSelected && nonVipLimitReached;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(game, style: const TextStyle(fontSize: 14))),
                          if (isLockedForNonVip) const Icon(Icons.lock_rounded, color: AppColors.goldLock, size: 18),
                        ],
                      ),
                      value: isSelected,
                      onChanged: isLockedForNonVip ? null : (value) {
                        setState(() {
                          _selectedGames[game] = value!;
                          if (value == false) _hintsEnabled[game] = false;
                        });
                      },
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (isLockedForNonVip)
                      const Padding(
                        padding: EdgeInsets.only(left: 48, right: 16, bottom: 6),
                        child: Row(
                          children: [
                            Icon(Icons.workspace_premium, color: AppColors.goldLock, size: 14),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text('Limite non-VIP atteinte (3 jeux max). Passez VIP pour débloquer.', style: TextStyle(fontSize: 12, color: AppColors.goldLock)),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 48, right: 16, bottom: 6),
                      child: Opacity(
                        opacity: isSelected ? 1.0 : 0.35,
                        child: IgnorePointer(
                          ignoring: !isSelected,
                          child: Row(
                            children: [
                              Icon(Icons.lightbulb_outline, size: 15, color: hintEnabled ? Colors.amber.shade700 : Colors.grey),
                              const SizedBox(width: 6),
                              Text(hintEnabled ? 'Indice activé' : 'Indice désactivé', style: TextStyle(fontSize: 12, color: hintEnabled ? Colors.amber.shade700 : Colors.grey)),
                              const Spacer(),
                              Transform.scale(
                                scale: 0.75,
                                child: Switch(
                                  value: hintEnabled,
                                  onChanged: (v) => setState(() => _hintsEnabled[game] = v),
                                  activeColor: Colors.amber.shade700,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                      child: isSelected && (game == 'QCM' || game == 'Relier' || game == 'Memory') 
                        ? Container(
                            margin: const EdgeInsets.only(left: 48, right: 16, bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.settings, size: 16, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 8),
                                    Text('Options avancées', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (game == 'QCM') ...[
                                  DropdownButtonFormField<DisplayMode>(
                                    decoration: InputDecoration(
                                      labelText: 'Affichage de la question',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      suffixIcon: !_isVip ? const Icon(Icons.lock, color: Colors.amber, size: 18) : null,
                                    ),
                                    value: _qcmQuestionMode,
                                    items: DisplayMode.values.map((mode) {
                                      bool isImageOption = mode != DisplayMode.text;
                                      return DropdownMenuItem(
                                        value: mode,
                                        enabled: _isVip || !isImageOption,
                                        child: Text(displayModeToString(mode) + (!_isVip && isImageOption ? ' (VIP)' : ''), style: const TextStyle(fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (value) => setState(() => _qcmQuestionMode = value!),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<DisplayMode>(
                                    decoration: InputDecoration(
                                      labelText: 'Affichage des réponses',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      suffixIcon: !_isVip ? const Icon(Icons.lock, color: Colors.amber, size: 18) : null,
                                    ),
                                    value: _qcmAnswerMode,
                                    items: DisplayMode.values.map((mode) {
                                      bool isImageOption = mode != DisplayMode.text;
                                      return DropdownMenuItem(
                                        value: mode,
                                        enabled: _isVip || !isImageOption,
                                        child: Text(displayModeToString(mode) + (!_isVip && isImageOption ? ' (VIP)' : ''), style: const TextStyle(fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (value) => setState(() => _qcmAnswerMode = value!),
                                  ),
                                ],
                                if (game == 'Relier') ...[
                                  DropdownButtonFormField<MatchDisplayMode>(
                                    decoration: InputDecoration(
                                      labelText: 'Type de jeu',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      suffixIcon: !_isVip ? const Icon(Icons.lock, color: Colors.amber, size: 18) : null,
                                    ),
                                    value: _matchDisplayMode,
                                    items: MatchDisplayMode.values.map((mode) {
                                      bool isImageOption = mode == MatchDisplayMode.imageToDefinition;
                                      return DropdownMenuItem(
                                        value: mode,
                                        enabled: _isVip || !isImageOption,
                                        child: Text(matchDisplayModeToString(mode) + (!_isVip && isImageOption ? ' (VIP)' : ''), style: const TextStyle(fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (value) => setState(() => _matchDisplayMode = value!),
                                  ),
                                ],
                                if (game == 'Memory') ...[
                                  DropdownButtonFormField<MemoryDisplayMode>(
                                    decoration: InputDecoration(
                                      labelText: 'Type de paires',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      suffixIcon: !_isVip ? const Icon(Icons.lock, color: Colors.amber, size: 18) : null,
                                    ),
                                    value: _memoryDisplayMode,
                                    items: MemoryDisplayMode.values.map((mode) {
                                      final isImageOption = mode != MemoryDisplayMode.wordToDefinition;
                                      return DropdownMenuItem(
                                        value: mode,
                                        enabled: _isVip || !isImageOption,
                                        child: Text(memoryDisplayModeToString(mode) + (!_isVip && isImageOption ? ' (VIP)' : ''), style: const TextStyle(fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (value) => setState(() => _memoryDisplayMode = value!),
                                  ),
                                  const SizedBox(height: 8),
                                  SwitchListTile(
                                    title: const Text('Laisser l\\'IA décider du nombre de paires', style: TextStyle(fontSize: 13)),
                                    value: _aiDecidePairs,
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    onChanged: (value) {
                                      setState(() {
                                        _aiDecidePairs = value;
                                        if (_aiDecidePairs) _memoryPairs = null;
                                      });
                                    },
                                  ),
                                  if (!_aiDecidePairs)
                                    DropdownButtonFormField<int>(
                                      decoration: InputDecoration(
                                        labelText: 'Nombre de paires',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      value: _memoryPairs,
                                      items: List.generate(
                                        7,
                                        (index) => DropdownMenuItem<int>(
                                          value: 4 + index,
                                          child: Text('${4 + index} paires', style: const TextStyle(fontSize: 13)),
                                        ),
                                      ),
                                      onChanged: (value) => setState(() => _memoryPairs = value),
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
          
          const SizedBox(height: 16),
          AnimatedOpacity(
            opacity: _status.isEmpty ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Center(
              child: Text(
                _status,
                style: TextStyle(
                  color: _status.toLowerCase().contains('erreur') ? Colors.red : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _generateGames,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Générer les jeux (IA)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          
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
          
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManualQuizCreatorPage(initialGames: _generatedGames))),
              icon: const Icon(Icons.edit_note),
              label: const Text('Créer un jeu manuellement', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          if (!widget.isGuest) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _showOnlineOptions,
                icon: const Icon(Icons.public),
                label: const Text('Jouer en ligne', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
          
          if (_generatedGames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.play_circle_fill, color: Colors.indigo, size: 36),
                  title: const Text('Jouer au dernier quiz généré', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Mode Solo (Créé à l\\'instant)'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _playQuiz(_generatedGames, _textController.text.trim(), _lastGeneratedQuizId),
                ),
              ),
            ),
        ],
      ),
    );
"""

new_content = content[:start_idx] + replacement + "\n}\n" + content[end_idx:]

with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_content)

print("Replacement successful.")
