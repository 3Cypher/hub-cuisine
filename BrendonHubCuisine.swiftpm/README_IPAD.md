# Hub Cuisine — ouverture sur iPad

Le projet à ouvrir est **BrendonHubCuisine.swiftpm**. C’est une application native SwiftUI, avec ses ressources et sa base SwiftData locale. Aucun script, Mac, compte dans l’application ou service payant n’est nécessaire pour lancer le projet dans Swift Playground.

## Télécharger, décompresser, lancer

1. Installez Swift Playground depuis l’App Store et utilisez un iPad sous **iPadOS 17 ou version ultérieure**, avec une version de Swift Playground prenant en charge Swift 5.9 et les apps iOS 17.
2. Téléchargez **BrendonHubCuisine.zip**. Dans la feuille de partage, choisissez **Enregistrer dans Fichiers**, puis un dossier sur votre iPad.
3. Dans **Fichiers**, ouvrez ce dossier et touchez une fois le ZIP pour le décompresser. Vous devez obtenir un élément nommé **BrendonHubCuisine.swiftpm**. Gardez cette extension.
4. Touchez **BrendonHubCuisine.swiftpm** pour l’ouvrir dans Swift Playground. Si nécessaire, faites un appui prolongé, choisissez **Partager**, puis **Swift Playground**. Selon la version, vous pouvez aussi ouvrir le projet depuis le navigateur de documents de Swift Playground.
5. Ouvrez le projet d’app et touchez **▶ Exécuter**. Attendez la première compilation. Aucune dépendance externe n’est à télécharger.
6. Dans l’écran de bienvenue, vérifiez le prénom et les portions, puis touchez **Ouvrir mon carnet**. Les sept recettes initiales apparaissent une seule fois.
7. Sur iPad, naviguez avec la barre latérale. La largeur disponible adapte les grilles et les formulaires ; en fenêtre étroite, la navigation passe aux cinq onglets.

**État de validation :** le cœur métier a été compilé et ses 15 contrôles ont réussi sous Swift 6.0.3 Linux. La syntaxe des 19 fichiers Swift a été analysée. L’interface SwiftUI, le manifeste Apple, SwiftData, les notifications et l’OCR n’ont pas pu être compilés ou exécutés sur un appareil Apple dans l’environnement de réalisation. Un essai dans Swift Playground reste donc nécessaire. Voir `VALIDATION.md`.

## Premier tour du carnet

- **Accueil** : repas du jour, favoris, recettes consultées et bouton « Je ne sais pas quoi manger ».
- **Recettes** : recherche, filtres combinables, tri, favoris et fiche illustrée. Dans une fiche, changez les portions, cochez les ingrédients, ajoutez les courses et lancez la cuisine.
- **Semaine** : choisissez les dates et les repas, puis générez les courses pour les repas sélectionnés.
- **Courses** : cochez, modifiez, ajoutez et rangez les articles par rayon. Le transfert au garde-manger reste facultatif.
- **Plus** : ajout, import, collections, historique, garde-manger, minuteurs, statistiques, réglages et sauvegardes.

## Photos, appareil photo, notifications

Dans **Plus → Ajouter une recette**, la sélection de photo utilise le sélecteur système : seules les images choisies sont transmises à l’app. Il est normal de ne pas recevoir de demande d’accès à toute la photothèque. La prise de photo demande l’autorisation de la caméra au moment de l’utiliser.

Dans **Plus → Importer → Photo**, choisissez une capture ou photo lisible. Le texte est reconnu localement ; corrigez-le, puis touchez **Analyser et vérifier** avant d’enregistrer la recette.

Au premier minuteur, acceptez les notifications pour recevoir l’alerte lorsque l’app passe en arrière-plan. En cas de refus, le compte à rebours reste disponible dans l’app. Vous pouvez ensuite ouvrir **Plus → Réglages → Ouvrir les réglages de notifications**. Les modes Concentration et les réglages sonores d’iPadOS influencent la présentation des alertes.

Les imports par lien et les téléchargements de photos nécessitent Internet. Les photos de démonstration sont incluses et s’affichent hors ligne. Pour les pages sans recette JSON-LD accessible, utilisez **Coller le texte à la place**.

## Sauvegarder et retrouver ses données

1. Ouvrez **Plus → Sauvegarder et restaurer → Exporter ma sauvegarde**.
2. Choisissez un dossier dans Fichiers et conservez le JSON. Il contient les photos personnelles, les recettes, les brouillons, les repas, les courses, le garde-manger, les collections, l’historique, les réglages et la session en cours.
3. Pour restaurer, choisissez ce fichier, contrôlez l’aperçu, puis confirmez **Restaurer**. La restauration remplace le carnet actuel ; exportez-le d’abord si vous voulez conserver les deux versions.
4. L’annulation immédiate reste proposée tant qu’aucune nouvelle modification n’a remplacé cette possibilité.

La base se trouve dans le conteneur de l’app exécutée, pas dans les fichiers source du `.swiftpm`. Exportez votre carnet avant de supprimer Swift Playground, de remplacer le projet ou d’en utiliser une autre copie. Ce ZIP contient les sources et les recettes initiales, pas une copie de vos futures données.

## Si le projet ne s’ouvre pas ou ne compile pas

- Vérifiez que vous ouvrez le **.swiftpm décompressé**, et non le ZIP, un fichier Swift isolé ou le dossier `Sources`.
- Vérifiez iPadOS 17 minimum et mettez Swift Playground à jour.
- Si un dossier ordinaire apparaît, vérifiez qu’il porte exactement le suffixe `.swiftpm` et qu’il contient directement `Package.swift`, `Sources` et `Resources`.
- Si Swift Playground signale une erreur, touchez l’indicateur rouge dans l’éditeur, ouvrez le diagnostic, puis copiez le **premier message complet**, le nom du fichier et le numéro de ligne. Une capture d’écran du diagnostic convient aussi. Ajoutez les versions d’iPadOS et de Swift Playground.
- Une erreur mentionnant `AppleProductTypes`, `SwiftData` ou iOS 17 indique notamment que la version ou le contexte d’ouverture doit être vérifié.
- Une erreur de base de données affiche un écran de récupération. Les données existantes ne sont pas supprimées automatiquement. La restauration d’un JSON valide exige un aperçu puis une confirmation.

Dans **Plus → Vérifications de l’application**, exécutez les contrôles embarqués. Ils travaillent sur des exemples isolés et ajoutent une vérification SwiftData en mémoire. Effectuez aussi le scénario de fermeture et relance décrit dans `VALIDATION.md` pour contrôler la persistance sur disque.

## Documents du projet

- `DECISIONS.md` : architecture, périmètre et limites fonctionnelles.
- `VALIDATION.md` : résultats réels et liste de vérification sur appareil.
- `README_XCODE.md` : reprise facultative sur Mac.
- `Reference/LegacyHTML` : cahier des charges et cinq prototypes fournis, exclus de l’application.

Documentation Apple : [Swift Playground](https://developer.apple.com/swift-playground/) et [fichiers et ressources d’un projet sur iPad](https://support.apple.com/guide/playgrounds-ipad/add-swift-files-images-and-swift-packages-itc18b7bce9d/ipados).
