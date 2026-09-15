# Validation de livraison

Date : 15 septembre 2026. Environnement : Linux x86_64, chaîne Swift 6.0.3. Aucun SDK iOS, Xcode, simulateur Apple ou iPad connecté n’était disponible.

## Résultats réellement obtenus

| Vérification | Résultat |
| --- | --- |
| Compilation du cœur Foundation et des tests XCTest | Réussie |
| `testCriticalScenarios` | Réussi : 15 contrôles métier, tous réussis |
| `testBundledRecipes` | Réussi : décodage des 7 vraies recettes, assets distincts, ingrédients/étapes, export et restauration |
| Bilan XCTest | 2 tests exécutés, 0 échec |
| Analyse syntaxique Swift | Réussie sur les 19 fichiers de `Sources` |
| Ressources | JSON et catalogues contrôlés, 7 images locales, icône 1024 × 1024 sans transparence |
| Illustrations | Planche de contrôle inspectée ; gnocchi et tiramisu corrigés |
| Archive | Uniquement `BrendonHubCuisine.swiftpm`, contrôle CRC du ZIP et chemins relatifs |
| Build iOS / résolution des types SwiftUI / macros SwiftData | Non exécutés : SDK Apple absent |
| Affichage, VoiceOver, caméra, OCR et notifications sur appareil | Non exécutés |
| Persistance SwiftData après arrêt du processus | Scénario reproductible ci-dessous ; non exécuté ici |

Le résultat de syntaxe ne prouve pas qu’un SDK Apple accepte toutes les API ni que l’interface s’affiche correctement. La branche Apple du manifeste n’a pas pu être compilée dans cet environnement. Les résultats sont donc une validation du code métier et du conditionnement, accompagnée d’une recette iPad à effectuer.

Les journaux de la dernière exécution sont inclus dans `Reference/TestResults`. La dernière ligne « Swift Testing … 0 tests » concerne l’autre moteur de tests livré avec Swift ; le bilan XCTest juste au-dessus indique bien **2 tests et 0 échec**.

## Commandes utilisées

Avec les exécutables de la chaîne Swift 6.0.3 ajoutés au chemin et les bibliothèques Linux nécessaires :

```sh
swift-format format --in-place --recursive BrendonHubCuisine.swiftpm/Sources BrendonHubCuisine.swiftpm/Tests BrendonHubCuisine.swiftpm/Package.swift
swift test --package-path BrendonHubCuisine.swiftpm --scratch-path .validation/build --jobs 1
```

L’analyse syntaxique a été lancée avec `swift-frontend -parse`, en lui passant la liste complète des 19 fichiers Swift de `Sources`. Code de sortie : 0. Les catalogues et l’archive ont été contrôlés avec Python (`json`, Pillow et `zipfile`). Les outils de validation et leurs caches ne sont pas inclus dans le livrable.

## Contrôles métier couverts

1. Recherche insensible aux accents et filtres combinés.
2. Fractions, portions et quantités non calculables.
3. Fusion g/kg et maintien des unités incompatibles et textes libres.
4. Unicité du planning, courses proportionnelles et génération répétée sans doublon.
5. Semaine traversant un changement d’année.
6. Import de texte français avec ingrédients et minuteur.
7. Import JSON-LD imbriqué, `@graph`, types multiples et `HowToSection`.
8. Échec d’import explicite sur une page sans recette.
9. Insertion initiale unique même après suppression de toutes les recettes.
10. Export/restauration JSON avec photos, texte accentué, brouillon, session et minuteur.
11. Variante indépendante et détection de doublon.
12. Temps restant après interruption et échéance dépassée.
13. Disponibilité du garde-manger selon quantités et péremption.
14. Stock affecté à deux lignes d’une recette sans double comptage.
15. Refus d’une sauvegarde avec identifiants incohérents.

Un deuxième test utilise réellement `Resources/LegacyRecipes.json` ; les premiers scénarios utilisent des données isolées reproductibles.

## Recette sur iPad — à effectuer

Ouvrez et lancez le projet suivant `README_IPAD.md`. Dans **Plus → Vérifications de l’application**, les 15 contrôles du cœur sont disponibles, plus une sauvegarde SwiftData et lecture depuis un nouveau contexte en mémoire. Ce dernier contrôle vérifie l’intégration SwiftData sans modifier le carnet ; il ne remplace pas le scénario disque ci-dessous.

### Persistance et restauration

- [ ] Au premier lancement, constater 7 recettes. Terminer l’accueil et choisir un prénom.
- [ ] Créer « Test de relance », ajouter une photo personnelle, un ingrédient, une étape et la note « À retrouver après fermeture ».
- [ ] La mettre en favori, l’ajouter à une collection et au menu de demain pour 3 portions.
- [ ] Générer ses courses et cocher un article. Ajouter un produit au garde-manger avec une date.
- [ ] Commencer sa cuisine, cocher un ingrédient et une étape ; lancer un minuteur de 3 minutes.
- [ ] Quitter l’app ou arrêter son aperçu, fermer Swift Playground depuis le sélecteur d’apps, puis rouvrir **la même copie** du projet et relancer.
- [ ] Retrouver photo, note, favori, collection, repas, article coché, produit et session. Vérifier que le minuteur tient compte du temps écoulé.
- [ ] Exporter un JSON. Modifier la note. Choisir la sauvegarde, lire l’aperçu, annuler une première fois : aucune donnée ne change.
- [ ] Restaurer en confirmant : l’ancienne note et les autres données sont retrouvées. Vérifier l’annulation immédiate de la restauration.
- [ ] Dans une copie de test uniquement, supprimer toutes les recettes, relancer et confirmer que les exemples ne reviennent pas.

### Principaux parcours

- [ ] Importer un texte avec titre, « Ingrédients » et « Préparation », corriger une quantité et enregistrer. Réimporter pour vérifier l’alerte doublon.
- [ ] Importer une URL publique contenant du JSON-LD Recipe. Essayer ensuite une page sans recette et vérifier le repli vers le texte.
- [ ] Importer une photo de texte par Vision, corriger le résultat et créer la recette.
- [ ] Choisir une photo du sélecteur système, prendre une photo si la caméra est disponible, et essayer une URL image valide puis invalide.
- [ ] Combiner recherche, catégorie, tag, favori et durée ; essayer une recherche sans résultat.
- [ ] Adapter les portions, consulter ingrédients/préparation/nutrition/notes, partager et dupliquer une recette.
- [ ] Naviguer entre deux semaines et un changement d’année, copier la semaine précédente, modifier un repas, confirmer un remplacement, utiliser Restes et Repas extérieur.
- [ ] Générer les courses deux fois pour les mêmes repas : pas de double ajout. Essayer plusieurs repas utilisant g et kg d’un même ingrédient.
- [ ] Ajouter, modifier, déplacer, cocher, partager et vider les courses ; vérifier confirmation et annulation. Replier un rayon.
- [ ] Transférer un achat au garde-manger. Vérifier les trois zones, une date dépassée, les modes Zéro course et Anti-gaspillage, puis la quantité manquante.
- [ ] Terminer une recette avec note et commentaire ; accepter puis refuser, lors de deux sessions, la proposition de déduction du garde-manger.

### Minuteurs et présentation native

- [ ] Autoriser les notifications, lancer deux minuteurs nommés, verrouiller l’iPad puis vérifier les alertes et les comptes à rebours au retour.
- [ ] Annuler un minuteur juste après lancement : pas d’alerte ultérieure. Vérifier une nouvelle ouverture avec minuteur actif : pas d’alertes dupliquées.
- [ ] Refuser les notifications : message explicite, compte à rebours dans l’app toujours utilisable.
- [ ] Vérifier l’écran maintenu allumé pendant la cuisine et le retour au comportement normal en quittant ce mode.
- [ ] Tester portrait/paysage iPad, fenêtre étroite et, ultérieurement, iPhone. La cuisine large doit présenter les étapes à gauche.
- [ ] Tester thème clair, thème sombre, Réduire les animations, les plus grandes tailles de texte et VoiceOver. Contrôler les zones tactiles, les lignes longues et les formulaires au clavier.
- [ ] Activer le mode avion : recettes et photos initiales, planning, courses et sauvegardes doivent fonctionner. L’import URL doit échouer avec un message lisible.

Les points non cochés ci-dessus ne sont pas présentés comme testés. Les limites métier connues figurent dans `DECISIONS.md`.
