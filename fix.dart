
import 'dart:io';
void main() {
  var file = File('lib/main.dart');
  var text = file.readAsStringSync();
  
  text = text.replaceAll('GÃ©nÃ¨re', 'Génère');
  text = text.replaceAll('Ãªtre', 'être');
  text = text.replaceAll('crÃ©er', 'créer');
  text = text.replaceAll('rÃ©fÃ©rence', 'référence');
  text = text.replaceAll('Pendu amÃ©liorÃ©', 'Pendu amélioré');
  text = text.replaceAll('ComplÃ©ter', 'Compléter');
  text = text.replaceAll('MystÃ¨re', 'Mystère');
  text = text.replaceAll('REMPLACÃ‰:', 'REMPLACÉ:');
  text = text.replaceAll('FlÃ©chÃ©s', 'Fléchés');
  text = text.replaceAll('VÃ©ritÃ©s', 'Vérités');
  text = text.replaceAll('MÃ©langÃ©e', 'Mélangée');
  text = text.replaceAll('GÃ©nÃ©rer', 'Générer');
  text = text.replaceAll('rÃ©cupÃ©rer', 'récupérer');
  text = text.replaceAll('DÃ©connexion', 'Déconnexion');
  text = text.replaceAll('SuccÃ¨s', 'Succès');
  text = text.replaceAll('ValidÃ©', 'Validé');
  text = text.replaceAll('CrÃ©er', 'Créer');
  text = text.replaceAll('RÃ©sultats', 'Résultats');
  text = text.replaceAll('DÃ©tail', 'Détail');
  text = text.replaceAll('gÃ©nÃ©ration', 'génération');
  text = text.replaceAll('gÃ©nÃ©rer', 'générer');
  text = text.replaceAll('gÃ©nÃ©rÃ©', 'généré');
  text = text.replaceAll('GÃ©nÃ©ration', 'Génération');

  file.writeAsStringSync(text);
}

