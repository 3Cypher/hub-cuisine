# Décisions de réalisation — Hub Cuisine 1.0

## Sources et périmètre

Le cahier des charges et les cinq prototypes ont été lus intégralement. `brendon_hub_cuisine_complet.html` sert de référence principale ; `brendon_hub_cuisine_fonctionnel.html` précise les interactions. Les trois autres versions ont été auditées pour les données et les variations de parcours. Le prompt maître de la section 11 a guidé la réalisation.

Les six sources sont conservées dans `Reference/LegacyHTML`. Elles sont exclues de la cible : aucun HTML n’est exécuté, aucune WebView n’est utilisée. Les sept recettes initiales viennent du prototype complet ; favoris et quantités sont normalisés au premier démarrage. Les valeurs de prix et de nutrition fournies restent des estimations de démonstration.

| Domaine | Réalisation |
| --- | --- |
| Navigation | Cinq onglets iPhone ; NavigationSplitView iPad ; grilles selon la largeur, formulaire avec colonne photo, cuisine avec étapes à gauche |
| Recettes | CRUD, photos locales/caméra/URL, favoris, recherche et filtres combinés, six tris, duplication, collections, portions, partage |
| Planning | Dates réelles, semaines lundi–dimanche, portions par repas, restes/extérieur, copie de semaine confirmée, modification date/créneau, courses pour une sélection de repas |
| Courses | Quantités compatibles fusionnées, rayons, ajout/édition/coche/suppression, progression, historique récent, ordre, partage, annulation immédiate |
| Cuisine | Session persistée avec instantané de recette, étapes et ingrédients cochés, plusieurs minuteurs nommés, notifications locales, écran allumé, lecture vocale facultative, historique final |
| Import | Texte français, JSON-LD public avec objets imbriqués, OCR Vision local, correction avant sauvegarde, alerte doublons |
| Garde-manger | Trois zones, quantités et dates, basiques, à racheter, transfert acheté, déduction confirmée, ingrédients manquants, zéro course, anti-gaspillage |
| Données | SwiftData local, JSON complet avec aperçu et restauration confirmée, brouillons automatiques, insertion unique des exemples |
| Réglages | Prénom, portions, activation des quatre créneaux proposés, rayons et ordre, exclusions, budget, thème, taille du texte cuisine et réduction des animations |

Les fonctions de phase 2 sont livrées dans le code. Leur recette sur appareil reste à effectuer, comme celle de la phase 1 : la réussite des contrôles métier ne constitue pas une validation de stabilité iOS.

## Architecture et persistance

Le cœur métier utilise des structures `Codable` indépendantes de SwiftUI. Un `HubStore` isolé sur l’acteur principal publie un état cohérent aux écrans. Une mutation est encodée et enregistrée avant publication ; en cas d’échec, le contexte SwiftData revient en arrière et le dernier état valide reste visible.

`HubSchemaV1` contient une entité `StoredRecipe` par recette et une entité `StoredWorkspace` pour les autres données. Les objets métier sont des payloads JSON, avec stockage externe SwiftData des données volumineuses. Ce choix simplifie les transactions et l’export complet d’un petit carnet personnel, au prix d’une réécriture du payload de travail et de recherches en mémoire. Il ne vise pas un catalogue de dizaines de milliers de recettes.

Le schéma 1.0.0 et `HubMigrationPlan` forment la migration initiale. Aucune migration historique fictive n’est ajoutée. Une future version doit prévoir explicitement ses changements de schéma **et** de JSON. Le format de sauvegarde est versionné à 1 ; les versions inconnues et incohérences structurelles sont refusées. Les dates des sauvegardes ISO 8601 sont conservées à la seconde ; les photos personnelles sont en base64.

La suppression de la dernière recette ne réinsère pas les exemples. Une restauration conserve le marqueur d’initialisation. Une base illisible n’est jamais effacée pour faire disparaître une erreur.

## Choix d’interface

Les couleurs sémantiques adaptent crème, papier et cacao aux thèmes clair/sombre. Le caramel des textes est assombri pour le contraste. Les titres utilisent la sérif système et l’interface la sans-sérif système : aucune police externe ou licence de police à installer. Les composants du fichier `DesignSystem.swift` centralisent cartes, filtres, boutons, lignes, photos, états vides et minuteurs.

Les photos sont embarquées, et l’icône temporaire est un monogramme H dans une assiette avec couverts. Deux photos mal associées dans le prototype (gnocchi et tiramisu) ont été remplacées par des illustrations adaptées. Ces photos illustrent les plats et ne prétendent pas montrer leur préparation exacte. Les crédits se trouvent dans `Reference/ASSET_CREDITS.md`.

Les animations des boutons durent 180 ms et respectent Réduire les animations. Dynamic Type, libellés VoiceOver et contrôles natifs sont utilisés ; une vérification visuelle et tactile sur appareil reste nécessaire, notamment aux très grandes tailles de texte.

## Règles métier et limites explicites

- Recherche insensible à la casse et aux accents. Les filtres se combinent par intersection. « Rapide » correspond à 25 minutes maximum ; « Petit budget » à un coût total connu de 7 € maximum. Un prix inconnu reste inconnu.
- Les noms d’ingrédients sont rapprochés après normalisation simple. Il n’y a ni moteur de synonymes ni inférence d’allergènes. Les exclusions sont un filtre textuel configurable.
- Portions : fractions simples, virgule décimale et conversion g/kg ou ml/cl/l. Les quantités libres ou plages conservent leur texte original. On ne convertit pas une masse en volume ni une cuillère en grammes.
- Courses : les articles non cochés se fusionnent seulement à nom et unité compatibles. Les provenances sont conservées. Une même entrée de menu déjà représentée dans les courses n’est pas ajoutée une seconde fois. Après modification d’un repas déjà généré, videz la liste concernée puis régénérez-la pour recalculer toutes ses contributions ; il n’existe pas de synchronisation automatique différentielle. Supprimer seulement une ligne d’un repas ne recrée pas cette ligne lors d’une nouvelle génération tant que ce repas est encore représenté ailleurs.
- Le rapprochement garde-manger tient compte des quantités déjà affectées à une autre ligne de la même recette. Les produits périmés ne comptent pas comme disponibles ; les basiques sont supposés présents jusqu’à leur marquage « À racheter ». Une déduction est proposée après cuisine, jamais imposée. Les noms et unités non reconnus demandent une vérification manuelle.
- Les minuteurs reposent sur une date de fin persistée, pas sur un compteur en mémoire. La présentation de l’alerte dépend des permissions et réglages iPadOS. Le retour au premier plan recalcule le temps restant. Un maximum de 50 minuteurs futurs actifs est autorisé. Une modification manuelle de l’horloge de l’appareil influence les échéances absolues.
- L’import URL lit le JSON-LD présent dans le HTML reçu. Il ne contourne aucun blocage, ne se connecte pas à un compte et n’exécute pas JavaScript. Le collage de texte et l’OCR sont les replis. Une URL photo doit être téléchargée explicitement pour obtenir une copie locale. Les connexions HTTP non sécurisées peuvent être refusées par iPadOS.
- L’OCR fournit du texte à vérifier, pas une reconnaissance parfaite de mise en page. Aucun modèle d’IA externe, aucune analyse nutritionnelle calculée et aucune estimation de prix en ligne ne sont utilisés.
- Les quatre créneaux prédéfinis sont activables ; leurs noms et les cinq catégories de recette ne sont pas librement renommables. Les collections et les noms de rayons sont personnalisables.
- L’annulation conserve une seule action en mémoire, jusqu’à la modification suivante. Les sauvegardes JSON assurent la conservation de versions durables.
- Les statistiques partent du catalogue, du planning, de l’historique et des pertes saisies. Aucune économie financière imaginaire n’est affichée.

## Confidentialité et hors périmètre

Fonctionnement local, sans compte, abonnement, publicité, clé ou backend. Les imports contactent le site et l’URL d’image choisis par l’utilisateur, avec leurs éventuelles redirections ; ils n’envoient pas le contenu du carnet. Vision travaille sur l’appareil. PhotosPicker n’exige pas d’accès global à la photothèque. Aucune donnée utilisateur n’est synchronisée avec CloudKit.

Pas de widget, Live Activity, réseau social, extension, intégration de distributeur, téléchargement de prix ou génération d’image IA. Pas de signature de distribution ni publication App Store dans ce projet. La lecture vocale utilise AVSpeechSynthesizer ; aucune reconnaissance de commande vocale n’est incluse.

La principale limite de livraison est l’absence de SDK Apple dans l’environnement de réalisation : les composants natifs doivent être compilés et testés dans Swift Playground. Les contrôles exécutés et les scénarios restants sont consignés sans assimilation entre analyse syntaxique et compilation iOS.
