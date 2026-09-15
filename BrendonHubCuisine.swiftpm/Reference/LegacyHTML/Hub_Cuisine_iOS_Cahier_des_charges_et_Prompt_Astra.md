# Brendon Hub Cuisine — cahier des charges iOS natif et prompt maître Astra

## 1. Vision du projet

**Nom de travail confirmé :** Brendon Hub Cuisine  
**Langue :** français  
**Promesse :** « Menu interactif, recettes, courses et mode cuisine. »

Brendon Hub Cuisine est une application personnelle qui réunit au même endroit :

- une bibliothèque de recettes ;
- la recherche et les filtres ;
- les favoris ;
- le choix aléatoire « Je ne sais pas quoi manger » ;
- le menu de la semaine ;
- la génération et la gestion de la liste de courses ;
- un vrai mode cuisine, lisible de loin, avec étapes et minuteurs ;
- l’ajout, la modification et l’import de recettes ;
- quelques statistiques simples.

L’objectif n’est plus de refaire une démonstration HTML. Il faut transformer les comportements des prototypes en **véritable application iPhone/iPad native**, écrite en Swift et SwiftUI, persistante, testable et ouvrable directement dans **Swift Playground sur iPad**. Le même projet pourra ensuite être ouvert dans Xcode sur Mac si nécessaire.

## 2. Sources historiques retrouvées

Cinq prototypes ont été créés le 4 juin 2026 :

1. `brendon_hub_cuisine.html`
2. `brendon_hub_cuisine_v3.html`
3. `brendon_hub_cuisine_v4.html`
4. `brendon_hub_cuisine_complet.html`
5. `brendon_hub_cuisine_fonctionnel.html`

Règle pour l’implémentation :

- utiliser `brendon_hub_cuisine_complet.html` comme référence principale pour le périmètre, le contenu et l’identité visuelle ;
- utiliser `brendon_hub_cuisine_fonctionnel.html` comme référence secondaire pour les interactions réparées ;
- considérer les trois autres versions comme des références historiques ;
- ne pas réutiliser leur JavaScript ni envelopper la page dans une WebView : il faut traduire les fonctions en Swift natif.

## 3. Ce qui est réellement confirmé

### Navigation et rubriques

- Accueil
- Toutes les recettes
- Favoris
- Statistiques
- Je ne sais pas quoi manger
- Liste de courses
- Menu de la semaine
- Ajouter une recette
- Importer

Sur iPhone, la barre latérale des prototypes doit être adaptée à une navigation mobile. Recommandation : une barre d’onglets avec **Accueil**, **Recettes**, **Semaine**, **Courses** et **Plus**. Favoris est accessible dans Recettes ; Statistiques, Ajouter et Importer sont dans Plus. Le bouton aléatoire reste très visible sur l’accueil.

### Accueil et découverte

- message d’accueil « Bon appétit, Brendon ! » ;
- recherche par nom, ingrédient, catégorie, difficulté ou tag ;
- catégories : **Entrée, Plat, Dessert, Petit creux, Boisson** ;
- filtres/chips : Tous, Rapide, Favoris, Petit budget/Économique, ainsi que les tags des recettes ;
- grille ou liste de cartes illustrées ;
- action pour réinitialiser les filtres ;
- affichage d’un premier groupe de recettes, puis « Voir plus » ;
- favoris activables depuis une carte ;
- cartes comportant au minimum photo, emoji, nom, temps, portions, difficulté, note et tags.

La définition historique de « Rapide » était environ 25 minutes maximum. La version complète considérait « Petit budget » comme un coût estimé inférieur ou égal à 7 €.

### Fiche recette

- grande photo et métadonnées ;
- onglets/sections : **Ingrédients, Préparation, Nutrition, Notes, Modifier** ;
- changement du nombre de portions avec adaptation des quantités simples ;
- ingrédients cochables ;
- bouton « Ajouter aux courses » ;
- étapes ordonnées avec titre, explication et durée/minuteur éventuel ;
- nutrition : calories, protéines, glucides et lipides ;
- notes personnelles modifiables ;
- modification et suppression avec confirmation ;
- changement de photo depuis la photothèque ou via URL.

### Mode cuisine

- présentation plein écran sombre, très lisible ;
- une étape active à la fois ;
- numéro, titre, instruction et progression ;
- étapes cochables/terminées ;
- boutons Précédent et Étape suivante ;
- possibilité d’afficher toute la recette et de revenir à l’étape active ;
- minuteur propre à une étape lorsqu’une durée existe ;
- fonctionnement correct lorsque l’application passe en arrière-plan, au moyen d’une date de fin et d’une notification locale, et non d’un simple compteur fragile ;
- message clair lorsque la recette est terminée.

### Liste de courses

- ajout de tous les ingrédients d’une recette ;
- ajout de tous les ingrédients du menu hebdomadaire ;
- ajout manuel d’un article ;
- regroupement par rayon/catégorie ;
- fusion des doublons raisonnables ;
- quantité, unité, origine éventuelle et compteur ;
- article cochable, supprimable et liste vidable ;
- badge avec le nombre d’articles restants.

### Menu de la semaine

- lundi à dimanche ;
- deux emplacements par jour : Midi et Soir ;
- sélection d’une recette pour un emplacement ;
- remplacement ou suppression ;
- ouverture de la recette depuis le planning ;
- génération de la liste de courses à partir du menu.

### Ajouter, modifier et importer

Champs confirmés d’une recette :

- nom ;
- catégorie ;
- difficulté : Très facile, Facile, Moyen, Difficile ;
- temps en minutes ;
- portions ;
- coût estimé en euros ;
- emoji ;
- photo ;
- tags ;
- ingrédients avec nom, quantité et rayon ;
- étapes avec titre, instruction et minuteur en minutes ;
- notes ;
- calories, protéines, glucides et lipides.

L’import par texte brut était prévu pour des contenus venant d’un blog, d’Instagram ou d’un PDF. L’import depuis une URL était visible mais non réellement implémenté, car le prototype signalait qu’il fallait une logique réseau/backend. Dans la première version native :

- l’import de texte doit réellement fonctionner et présenter un écran de vérification avant enregistrement ;
- l’import URL peut lire en priorité le JSON-LD `schema.org/Recipe` des pages publiques ;
- en cas d’échec, proposer de coller le texte ;
- ne jamais afficher un faux succès d’import.

### Statistiques

- nombre total de recettes ;
- nombre de favoris ;
- temps moyen ;
- nombre d’articles de courses ;
- répartition des recettes par catégorie ;
- meilleures recettes selon la note.

### Recettes de démonstration retrouvées

- Marry Me Chicken & Gnocchi
- Steak sauce échalote
- Cajun Chicken Alfredo
- Panini Express
- Bruschetta tomate basilic
- Tiramisu spéculoos
- Limonade maison

Ces recettes peuvent servir de données initiales, mais elles ne doivent être insérées qu’une seule fois au premier lancement.

## 4. Fonctions enrichies selon la vision du Hub Cuisine

L’application doit devenir un compagnon de cuisine quotidien, pas seulement un catalogue de recettes. Les ajouts suivants sont retenus et classés pour éviter de construire une app immense mais instable.

### Indispensable dès la première vraie version

**Accueil réellement utile**

- bloc « Aujourd’hui » affichant les repas prévus à midi et le soir ;
- accès rapide à « Je ne sais pas quoi manger », Ajouter, Importer et Courses ;
- recettes récemment consultées ;
- favoris mis en avant ;
- suggestion du jour et petite citation culinaire discrète ;
- progression de la liste de courses et aperçu du prochain minuteur actif.

**Organisation des recettes**

- collections personnalisées : « À tester », « Nos favoris », « Rapide semaine », « Invités », etc. ;
- tri par date d’ajout, nom, note, durée, coût ou dernière préparation ;
- filtres combinables avec bouton de remise à zéro ;
- historique des recettes cuisinées avec date, note personnelle et éventuel commentaire ;
- détection des doublons lors d’un import ;
- duplication d’une recette pour créer une variante sans écraser l’originale ;
- unités métriques adaptées à la Belgique : g, kg, ml, cl, l, c. à café, c. à soupe, pièce ;
- adaptation des portions en conservant une quantité lisible et arrondie intelligemment.

**Données fiables**

- sauvegarde automatique après chaque modification importante ;
- export complet des données dans un fichier JSON lisible et réimportable ;
- import de cette sauvegarde avec aperçu et confirmation ;
- partage d’une recette sous forme de texte propre ou de fiche visuelle ;
- états vides, erreurs, chargement et récupération après échec ;
- annulation après les suppressions et actions destructrices courantes ;
- aucune perte silencieuse lors d’une mise à jour du modèle de données.

**Planning amélioré**

- navigation entre les semaines avec dates réelles ;
- Midi et Soir par défaut, avec possibilité d’activer Petit-déjeuner et Collation dans les réglages ;
- copier le menu de la semaine précédente ;
- déplacer ou remplacer facilement un repas ;
- indiquer « Restes » ou « Repas extérieur » sans créer de fausse recette ;
- calculer le nombre de portions prévu pour chaque repas ;
- générer les courses uniquement pour certains jours ou certains repas ;
- afficher une estimation du coût de la semaine lorsqu’assez de prix sont renseignés.

**Courses intelligentes mais simples**

- regroupement personnalisable par rayon ;
- fusion des ingrédients compatibles et conservation séparée des quantités incompatibles ;
- possibilité de modifier quantité, unité et rayon ;
- filtre À acheter/Acheté et barre de progression ;
- tri manuel à l’intérieur d’un rayon ;
- mémorisation facultative de l’ordre habituel des rayons du magasin ;
- historique récent pour rajouter rapidement les produits fréquents ;
- geste de balayage, annulation et retour haptique léger ;
- partage de la liste par la feuille de partage iOS.

**Mode cuisine renforcé**

- empêcher la mise en veille pendant une recette, avec retour au comportement normal à la sortie ;
- taille du texte ajustable ;
- plusieurs minuteurs nommés pouvant continuer en arrière-plan ;
- notification locale avec le nom de l’étape ;
- répétition rapide de l’instruction active ;
- boutons très grands, gestes gauche/droite et contraste élevé ;
- gestes tactiles simples et boutons très accessibles pour éviter de toucher de petites commandes avec les mains occupées ;
- reprise d’une session interrompue ;
- récapitulatif final avec « Recette terminée », note et ajout à l’historique.

### Fonctions “Hub” très chouettes à ajouter après stabilisation du socle

**Mon garde-manger**

- inventaire Frigo, Congélateur et Placard ;
- quantité approximative, date d’ouverture et date de péremption ;
- statuts « bientôt périmé », « à racheter » et « toujours disponible » pour les basiques ;
- ajout manuel rapide ;
- transfert d’un article acheté vers le garde-manger ;
- déduction facultative des ingrédients après avoir cuisiné, avec confirmation plutôt qu’automatiquement.

**Que cuisiner avec ce que j’ai ?**

- classer les recettes selon le pourcentage d’ingrédients déjà disponibles ;
- afficher clairement ce qui manque ;
- filtres temps, budget, catégorie, difficulté et ingrédients à utiliser rapidement ;
- mode « zéro course », qui ne propose que les recettes réalisables ;
- mode anti-gaspillage favorisant les produits proches de leur date limite.

**Imports puissants**

- import depuis texte collé ;
- import depuis URL avec JSON-LD `schema.org/Recipe` ;
- import d’une photo ou capture d’écran avec le framework Vision d’Apple pour reconnaître le texte ;
- découpage assisté en titre, ingrédients et étapes ;
- écran de vérification obligatoire avant sauvegarde ;
- indication de la source et lien vers la recette originale ;
- aucune prétention d’exactitude : signaler les champs incertains.

**Budget et habitudes**

- prix facultatif par ingrédient ou produit fréquent ;
- estimation par recette, portion et semaine ;
- budget hebdomadaire facultatif avec indicateur discret, jamais culpabilisant ;
- statistiques utiles : recettes les plus cuisinées, catégories, temps moyen, économies estimées et produits souvent jetés ;
- calendrier/historique de cuisine.

**Personnalisation**

- nom affiché dans l’accueil ;
- nombre de portions par défaut ;
- allergies, aliments exclus et préférences uniquement pour filtrer, sans conseil médical ;
- catégories, collections, rayons et créneaux de repas personnalisables ;
- thème clair, sombre et système ;
- option pour réduire les animations.

### Évolutions futures non bloquantes

- synchronisation iCloud et foyer partagé Lina/Brendon ;
- liste de courses collaborative en temps réel ;
- widget du repas du jour et Live Activity pour minuteur, seulement lorsqu’un passage par Xcode permet d’ajouter les extensions nécessaires ;
- publication App Store.

### Contrainte de coût actuelle

La version actuelle doit rester **entièrement gratuite à utiliser et à développer** :

- aucun abonnement nécessaire au fonctionnement ;
- aucune clé API ;
- aucune API OpenAI ni autre API d’IA ;
- aucun backend payant ;
- aucune base de données distante ;
- aucun service tiers obligatoire ;
- aucun achat intégré ni publicité ;
- traitement local sur l’iPad dès que possible ;
- OCR réalisé avec le framework Vision d’Apple directement sur l’appareil ;
- import URL effectué par lecture directe des données publiques de la page, notamment JSON-LD, sans service d’extraction externe ;
- dépendances open source seulement si elles sont gratuites, réellement nécessaires et compatibles Swift Playground ; préférer les frameworks Apple.

## 5. Direction artistique et système de design

### Palette

- Crème/papier : `#F8F4EE`
- Blanc : `#FFFFFF`
- Encre brun très foncé : `#1C120A`
- Brun : `#5C3317`
- Caramel : `#B87333`
- Or : `#C9962A`
- Or clair : `#EDD68A`

### Concept visuel

Le design doit évoquer un **beau carnet de cuisine contemporain**, chaleureux et haut de gamme, avec la qualité d’une application Apple soignée. Il ne doit ressembler ni à un tableau de bord professionnel, ni à une app de régime, ni à un template générique.

Mots-clés : crème, papier, cacao, caramel, laiton, lumière naturelle, photographie gourmande, éditorial, calme, tactile, généreux.

### Palette complète

**Thème clair**

- fond principal crème `#F8F4EE` ;
- surface principale `#FFFFFF` ;
- surface secondaire chaude `#F1E8DC` ;
- encre `#1C120A` ;
- brun `#5C3317` ;
- caramel `#B87333` ;
- or `#C9962A` ;
- or clair `#EDD68A` ;
- texte secondaire `#75675C` ;
- bordure chaude `#E6D9CB` ;
- succès doux `#52735A` ;
- erreur terre cuite `#A34F3F`.

**Thème sombre**

- fond cacao `#160F0A` ;
- surface `#24180F` ;
- surface élevée `#302116` ;
- texte crème `#F7F0E7` ;
- texte secondaire `#C9B8A7` ;
- caramel clair `#D69A62` ;
- or `#D7AE4A` ;
- bordure `#4A3527`.

Ne jamais utiliser le bleu système comme couleur de marque. Les couleurs sémantiques doivent cependant rester compréhensibles et accessibles.

### Typographie

- titres éditoriaux : Cormorant Garamond embarquée si possible ;
- interface et longs textes : Jost embarquée si possible ;
- solution de repli : New York/SF Pro ou polices système ;
- grand titre accueil : 34–40 pt, graisse semibold ;
- titre écran : 28–32 pt ;
- titre carte : 18–21 pt ;
- corps : 16–17 pt ;
- métadonnées : 13–14 pt ;
- petites légendes : jamais sous 11 pt ;
- prise en charge complète de Dynamic Type sans texte coupé.

### Grille, formes et profondeur

- grille d’espacement fondée sur 4 pt : 4, 8, 12, 16, 24, 32 et 40 ;
- marge horizontale iPhone : 16–20 pt ;
- cartes compactes : rayon 16 pt ;
- grandes cartes et feuilles : rayon 22–28 pt ;
- boutons principaux en forme de capsule ou rayon 14–16 pt ;
- ombres très diffuses, chaudes et peu opaques ;
- bordure chaude fine sur fond clair pour conserver le relief ;
- matériaux translucides uniquement pour la barre d’onglets, les contrôles flottants et les overlays, sans effet verre partout.

### Iconographie et photos

- SF Symbols cohérents pour la navigation et les actions ;
- emojis réservés aux catégories et à la personnalité des recettes, jamais comme unique repère fonctionnel ;
- photos au format cohérent, cadrées généreusement et toujours lisibles avec un dégradé brun discret sous le texte ;
- placeholder élégant avec dessin de cloche/assiette lorsqu’il n’y a pas de photo ;
- aucune photo étirée ;
- transitions douces entre carte et fiche recette quand la plateforme le permet.

### Mouvements et sensations

- animations courtes, naturelles et utiles, entre 160 et 300 ms ;
- légère élévation au toucher d’une carte ;
- animation de cœur chaleureuse mais discrète ;
- coche d’ingrédient et progression de cuisine animées ;
- haptique léger sur ajout, coche et changement d’étape ;
- haptique plus marqué seulement à la fin d’un minuteur ;
- respecter Réduire les animations ;
- ne jamais retarder une action pour montrer une animation.

### Composants à concevoir comme un vrai design system

- `HCPrimaryButton`, `HCSecondaryButton`, `HCIconButton` ;
- `HCRecipeCard` en variantes grande, compacte et horizontale ;
- `HCCategoryCard` ;
- `HCFilterChip` avec états normal, actif et désactivé ;
- `HCSectionHeader` ;
- `HCEmptyState`, `HCErrorState`, `HCSkeleton` ;
- `HCIngredientRow`, `HCShoppingRow`, `HCMealSlot` ;
- `HCPhotoHero` ;
- `HCStatCard` ;
- `HCTimerPill` et `HCTimerCard` ;
- `HCToast` et bannière d’annulation ;
- styles centralisés pour couleurs, espacements, rayons, ombres et typographies.

### Conception écran par écran

**Lancement et première ouverture**

- écran de lancement crème avec monogramme ou assiette stylisée or/brun ;
- onboarding très court : prénom affiché, portions par défaut et autorisations seulement au moment où elles sont utiles ;
- ne pas imposer de création de compte.

**Accueil**

- grand « Bon appétit, Brendon ! » et date discrète ;
- carte héro « Aujourd’hui » avec repas Midi/Soir et grande photo ;
- bouton signature « Je ne sais pas quoi manger » ;
- actions rapides en petites cartes ;
- sections horizontales Favoris et Récemment consultées ;
- aperçu courses ou produits à utiliser bientôt ;
- hiérarchie aérée, pas plus de deux informations fortes au-dessus de la ligne de flottaison.

**Bibliothèque de recettes**

- barre de recherche intégrée ;
- catégories sous forme de cartes photographiques ou chips ;
- filtres dans une feuille dédiée lorsqu’ils deviennent nombreux ;
- affichage grille sur iPad, liste/cartes adaptatives sur iPhone ;
- changement de tri visible sans surcharger ;
- menu contextuel pour Favori, Ajouter au menu, Dupliquer, Partager et Supprimer.

**Fiche recette**

- photo héro plein bord avec retour, favori et menu ;
- titre superposé ou juste sous la photo selon la lisibilité ;
- métadonnées dans des capsules ;
- sélecteur de portions accessible ;
- sections Ingrédients, Préparation, Nutrition et Notes dans une navigation claire ;
- bouton « Commencer la recette » persistant mais jamais gênant ;
- panneau de modification présenté comme feuille sur iPhone et colonne sur iPad.

**Mode cuisine**

- expérience immersive cacao/encre ;
- texte très grand, largeur de lecture maîtrisée ;
- progression visuelle or ;
- minuteurs sous forme de cartes lumineuses ;
- commandes en bas accessibles à une main ;
- sur iPad paysage, liste des étapes à gauche et étape active à droite ;
- ne laisser visibles que les contrôles utiles pendant la cuisson.

**Planning**

- bandeau semaine avec dates et navigation précédente/suivante ;
- cartes de jours verticales sur iPhone ;
- grille hebdomadaire sur iPad paysage ;
- emplacements avec photo miniature, portions et état Restes/Extérieur ;
- bouton de génération des courses clairement lié aux jours sélectionnés.

**Courses**

- progression en haut, rayons repliables, grandes cases tactiles ;
- article acheté atténué sans devenir illisible ;
- ajout rapide toujours accessible ;
- barre d’action partage/vider discrète ;
- mode magasin très lisible, utilisable d’une main.

**Garde-manger**

- trois segments Frigo, Congélateur, Placard ;
- priorité visuelle aux produits proches de la date limite ;
- code couleur accompagné de texte/icône, jamais couleur seule ;
- bouton « Cuisiner avec ça » visible.

**Ajout et import**

- formulaire découpé en étapes courtes plutôt qu’une page interminable ;
- aperçu permanent de la photo et du nom ;
- ajout d’ingrédients et étapes fluide, réordonnable ;
- pour OCR/URL, comparaison claire entre contenu détecté et champs à corriger ;
- sauvegarde brouillon automatique.

**Statistiques et réglages**

- graphiques très simples et utiles, sans dashboard dense ;
- réglages regroupés en Identité, Cuisine, Planning, Données et Accessibilité ;
- export/restauration particulièrement visibles dans Données.

### Adaptation iPad

- `NavigationSplitView` lorsque pertinent ;
- barre latérale crème ou cacao et contenu détaillé à droite ;
- grilles de deux à quatre colonnes selon la largeur ;
- formulaires et fiches en deux colonnes ;
- mode cuisine optimisé paysage ;
- aucune interface simplement agrandie depuis l’iPhone.

Cormorant Garamond et Jost peuvent être incluses comme polices embarquées si leurs licences et fichiers sont ajoutés correctement. À défaut, employer une sérif et une sans-sérif système proches sans casser la mise en page.

## 6. Architecture native recommandée

### Choix du MVP

- Swift et SwiftUI uniquement ;
- cible iOS 17 ou supérieure afin d’utiliser SwiftData ;
- SwiftData pour la persistance locale ;
- architecture par fonctionnalités, avec vues SwiftUI, modèles SwiftData, petits services et view models seulement lorsqu’ils apportent une vraie valeur ;
- PhotosUI pour choisir des images ;
- URLSession et `async/await` pour les imports réseau ;
- UserNotifications pour la fin des minuteurs ;
- tests unitaires du calcul des portions, des filtres, de la fusion des courses, du planning et de l’import ;
- tests d’interface des parcours essentiels si l’environnement Xcode le permet.

### Modèles de données conseillés

**Recipe**

- id UUID
- name String
- category enum
- difficulty enum
- emoji String
- photo locale et/ou URL distante
- timeMinutes Int
- servings Int
- estimatedCostEUR Decimal
- rating Double
- isFavorite Bool
- tags [String]
- ingredients [Ingredient]
- steps [RecipeStep]
- nutrition NutritionInfo
- notes String
- createdAt, updatedAt

**Ingredient**

- id UUID
- name
- amount Decimal optionnel
- unit String optionnelle
- originalQuantityText pour les quantités impossibles à analyser
- aisle/rayon
- order

**RecipeStep**

- id UUID
- order
- title
- instruction
- timerSeconds optionnel

**ShoppingItem**

- id UUID
- normalizedName
- displayName
- amount et unité si compatibles
- originalQuantityText
- aisle
- isChecked
- sourceRecipeIDs
- createdAt

**MealPlanEntry**

- id UUID
- date ou jour de semaine
- slot Midi/Soir
- recipeID

**PantryItem**

- id UUID
- name normalisé et nom affiché
- zone Frigo/Congélateur/Placard
- quantité et unité optionnelles
- openedAt et expiryDate optionnels
- isStaple, needsRestock et notes

**RecipeCollection**

- id UUID
- name, symbol, colorToken
- recipeIDs ordonnés

**CookingHistoryEntry**

- id UUID
- recipeID
- cookedAt
- servings, rating et note optionnelle

**AppSettings**

- displayName
- defaultServings
- enabledMealSlots
- allergies et exclusions
- preferredAisleOrder
- appearance et reduceMotionOverride

Le statut temporaire des ingrédients et étapes cochés pendant une session de cuisine peut rester en mémoire, sauf si la reprise de session est activée. Le contenu permanent doit survivre aux relances. Toute donnée importante doit pouvoir être exportée et restaurée.

## 7. Priorités de réalisation

**Phase 1 — socle irréprochable**

- recettes, recherche, filtres, favoris et collections ;
- fiche, ajout, modification, duplication et suppression ;
- mode cuisine et minuteurs ;
- planning hebdomadaire ;
- liste de courses ;
- statistiques essentielles ;
- import texte et URL ;
- export/restauration ;
- design system complet et interfaces iPhone/iPad.

**Phase 2 — véritable Hub**

- garde-manger ;
- « Que cuisiner avec ce que j’ai ? » ;
- anti-gaspillage et dates ;
- OCR depuis photo/capture ;
- budget ;
- historique et statistiques enrichies ;
- sauvegarde/restauration et partage natif.

**Phase 3 — lorsque l’accès aux capacités Apple avancées est disponible**

- iCloud et partage Lina/Brendon ;
- widgets et Live Activities ;
- TestFlight/App Store.

Toujours exclus : publicité, abonnement imposé, réseau social public, conseils nutritionnels médicaux et faux boutons IA. L’ancienne suggestion de photo IA ne doit jamais être simulée.

## 8. Définition de « terminé » pour le MVP

Le MVP est terminé quand :

1. le livrable contient un vrai **projet d’app Swift Playground au format `.swiftpm`** et des sources Swift, sans React Native, Flutter, Capacitor, PWA ni WKWebView ;
2. les données persistent après fermeture et réouverture ;
3. toutes les fonctions confirmées ci-dessus fonctionnent réellement ;
4. aucun bouton principal n’est factice ;
5. l’app possède les sept recettes initiales ;
6. les tests unitaires critiques passent ;
7. le projet est structuré pour s’ouvrir avec Swift Playground sur iPad et, si un environnement Apple compatible est disponible, il y compile réellement ;
8. si Astra travaille dans un environnement sans SDK Apple, il le dit explicitement et ne prétend pas avoir compilé ;
9. un README explique comment transférer, ouvrir et lancer le `.swiftpm` dans Swift Playground, puis comment l’ouvrir éventuellement dans Xcode ;
10. aucune clé secrète n’est committée ;
11. le design est cohérent sur tous les écrans, y compris états vides, erreurs, chargement et thème sombre ;
12. la navigation et les formulaires sont réellement adaptés à l’iPad ;
13. l’export puis la restauration d’une sauvegarde sont vérifiés.

## 9. Outils et plugins à utiliser

### Essentiel

- **Astra dans Codex** : pour analyser les références, écrire et corriger le code.
- **GitHub** : déjà installé ; créer ou connecter un dépôt privé `brendon-hub-cuisine-ios` pour conserver le projet et son historique.
- **Swift Playground sur iPad** : environnement principal choisi par Lina. Il permet de créer une app SwiftUI multi-fichiers, d’utiliser des assets et des Swift Packages, de la lancer sur l’iPad et même de préparer un envoi vers App Store Connect.
- **Xcode sur un Mac** : utile plus tard pour le débogage avancé, les tests d’interface, Instruments, certaines capacités/signatures complexes et la maintenance professionnelle, mais il n’est pas obligatoire pour commencer ce MVP.

### Utile mais facultatif

- **Figma** : à connecter si l’on veut d’abord figer les écrans et composants ou transmettre à Astra une référence visuelle extrêmement précise.
- **Codex Security** : utile avant une publication si l’app reçoit plus tard un backend, des comptes ou des clés d’API.

Aucun plugin payant et aucune connexion à un fournisseur d’IA ne sont nécessaires. Figma peut être ignoré : Astra peut créer le design system directement à partir de ce cahier des charges.

### À ne pas choisir pour ce but

Sites, Replit, Base44, Webflow et les constructeurs de sites sont adaptés au Web, pas à une application iOS native. Canva peut aider pour une icône ou des visuels, mais ne remplace pas Xcode et ne construit pas l’application.

## 10. Marche à suivre concrète

1. Créer un dépôt GitHub privé vide nommé `brendon-hub-cuisine-ios`, ou demander à Astra de produire directement une archive ZIP téléchargeable.
2. Y placer ce cahier des charges et les cinq prototypes dans `Reference/LegacyHTML/`.
3. Ouvrir le dépôt ou le dossier de travail dans Codex, sélectionner **GPT-6 Astra** avec un niveau de raisonnement élevé.
4. Coller le prompt maître ci-dessous.
5. Laisser Astra auditer les fichiers puis créer un projet d’app **`BrendonHubCuisine.swiftpm`** compatible avec Swift Playground sur iPad.
6. Télécharger le dossier ou le ZIP terminé dans l’app Fichiers de l’iPad ; décompresser le ZIP si nécessaire.
7. Toucher `BrendonHubCuisine.swiftpm` et choisir de l’ouvrir dans Swift Playground.
8. Appuyer sur Exécuter et corriger avec Astra toute erreur exacte affichée par Swift Playground.
9. Tester manuellement : création de recette, relance de l’app, ajout aux courses, planning, minuteur et suppression.
10. N’utiliser Xcode sur Mac que plus tard si une limite réelle de Swift Playground apparaît ou pour une finition avancée/App Store.

## 11. Prompt maître à copier dans une tâche Astra

```text
Tu es l’ingénieur iOS principal chargé de transformer les prototypes historiques « Brendon Hub Cuisine » en une véritable application iOS native, fonctionnelle et maintenable.

CONTEXTE ET SOURCES

Le dépôt contient :
- ce cahier des charges ;
- Reference/LegacyHTML/brendon_hub_cuisine_complet.html, référence principale pour le périmètre fonctionnel et l’identité visuelle ;
- Reference/LegacyHTML/brendon_hub_cuisine_fonctionnel.html, référence secondaire pour les interactions ;
- trois prototypes historiques supplémentaires.

Commence par lire complètement le cahier des charges et auditer les prototypes. Utilise-les comme spécification comportementale et visuelle, pas comme code à embarquer.

OBJECTIF NON NÉGOCIABLE

Construis un vrai projet iOS natif en Swift et SwiftUI. Interdiction d’utiliser une WebView, de simplement emballer le HTML, ou de remplacer le projet par React Native, Flutter, Capacitor, une PWA ou un site web. L’environnement principal de l’utilisatrice est **Swift Playground sur iPad, pas Xcode**. Le livrable principal doit donc être un projet d’app package-based nommé `BrendonHubCuisine.swiftpm`, directement ouvrable dans Swift Playground sur iPad. Il doit également rester ouvrable dans Xcode sur Mac plus tard.

CONTRAINTE GRATUITÉ ET CONFIDENTIALITÉ

La version à construire doit fonctionner gratuitement, localement et sans compte :
- aucune API OpenAI ou API d’IA ;
- aucune clé API ;
- aucun backend ;
- aucun abonnement, achat intégré ou publicité ;
- aucun service tiers obligatoire ;
- aucun envoi de recette, photo, inventaire ou préférence vers un serveur ;
- OCR avec Vision d’Apple sur l’appareil ;
- import URL par URLSession et lecture directe de JSON-LD public ;
- frameworks Apple privilégiés et dépendances externes évitées ;
- aucune fonction factice destinée à faire croire qu’une IA existe.

APPROCHE

1. Inspecte d’abord l’environnement, les fichiers et l’état Git.
2. Écris un plan court fondé sur les exigences confirmées.
3. Crée l’architecture du projet et implémente ensuite par tranches verticales fonctionnelles.
4. Ne t’arrête pas à des maquettes : les boutons, la persistance et les parcours principaux doivent réellement fonctionner.
5. Compile et lance les vérifications après chaque tranche lorsqu’un SDK Apple compatible est disponible.
6. Corrige les erreurs avant de poursuivre.
7. Ne prétends jamais qu’une compilation ou un test a réussi si la commande n’a pas réellement été exécutée.
8. Si l’environnement de travail n’a pas les SDK Apple, produis malgré tout l’intégralité du projet `.swiftpm`, effectue toutes les validations statiques possibles, puis indique précisément comment l’ouvrir et le tester dans Swift Playground sur iPad. Ne transforme pas l’absence de Xcode en blocage.
9. Respecte les changements déjà présents dans le dépôt et effectue des commits petits et explicites.

STACK IMPOSÉE

- Swift + SwiftUI ;
- cible iOS 17+ ;
- SwiftData pour la persistance locale du MVP ;
- PhotosUI pour la photothèque ;
- URLSession avec async/await pour le réseau ;
- UserNotifications pour les minuteurs en arrière-plan ;
- Vision pour l’OCR local d’une photo ou capture d’écran ;
- UniformTypeIdentifiers et fileImporter/fileExporter pour les sauvegardes ;
- ShareLink ou UIActivityViewController pour le partage local ;
- logique métier isolée et testable ; ajouter des tests de package uniquement s’ils restent compatibles avec l’ouverture du projet dans Swift Playground, sans bloquer l’app ;
- dépendances externes minimales et justifiées ;
- aucun secret dans le dépôt.

CONTRAINTES SWIFT PLAYGROUND IPAD

- utilise la structure officielle d’un projet d’app Swift Playground fondé sur un Swift Package ;
- garde le manifeste et les ressources compatibles avec Swift Playground sur iPad ;
- répartis proprement le code dans plusieurs fichiers Swift et les images/couleurs dans les ressources du package ;
- n’exige aucun script shell, générateur de projet, CocoaPods, outil Homebrew ou étape disponible uniquement sur Mac pour ouvrir l’app ;
- évite les extensions de cible, réglages de build avancés, entitlements complexes et dépendances binaires non nécessaires ;
- privilégie les frameworks Apple disponibles sur iPadOS ;
- fournis à la racine un fichier `README_IPAD.md` avec les étapes tactiles exactes : télécharger, décompresser, ouvrir le `.swiftpm`, lancer, autoriser les photos/notifications et récupérer le message d’erreur en cas d’échec ;
- fournis aussi un ZIP contenant uniquement le projet `.swiftpm` final, prêt à être téléchargé dans Fichiers.

EXPÉRIENCE MOBILE

Adapte la sidebar web à une interface iPhone native avec cinq onglets : Accueil, Recettes, Semaine, Courses, Plus. Dans Recettes, rendre Favoris facilement accessible. Dans Plus, placer Statistiques, Ajouter une recette et Importer. Le bouton « Je ne sais pas quoi manger » doit être visible sur Accueil.

Reproduis l’ambiance visuelle sans faire une copie rigide du desktop :
- crème #F8F4EE ;
- blanc #FFFFFF ;
- encre #1C120A ;
- brun #5C3317 ;
- caramel #B87333 ;
- or #C9962A ;
- or clair #EDD68A ;
- titres éditoriaux en sérif élégante, interface en sans-sérif nette ;
- cartes arrondies, ombres douces, belles images ;
- mode cuisine sombre avec accents or.

Utilise les composants et comportements iOS appropriés : NavigationStack, sheets/fullScreenCover, confirmationDialog, searchable, PhotosPicker, haptics discrets, Dynamic Type, VoiceOver, contraste correct, zones tactiles d’au moins 44 points et adaptation iPhone/iPad. Les textes visibles sont en français et les prix en euros.

DIRECTION ARTISTIQUE À IMPLÉMENTER, PAS SEULEMENT À DÉCRIRE

Avant de multiplier les écrans, crée un vrai design system centralisé : couleurs sémantiques clair/sombre, typographies, espacements 4/8/12/16/24/32/40, rayons 16/22/28, ombres chaudes, matériaux, animations et haptics. Crée des composants réutilisables HCPrimaryButton, HCSecondaryButton, HCRecipeCard, HCCategoryCard, HCFilterChip, HCSectionHeader, HCIngredientRow, HCShoppingRow, HCMealSlot, HCPhotoHero, HCStatCard, HCTimerCard, HCEmptyState, HCErrorState et HCSkeleton.

Le résultat doit évoquer un carnet de cuisine contemporain haut de gamme : crème, papier, cacao, caramel, or/laiton, lumière naturelle et grandes photographies gourmandes. Refuse l’apparence d’un template générique, d’un dashboard professionnel ou d’une app de régime. N’utilise pas le bleu système comme identité de marque. Utilise SF Symbols pour les actions et garde les emojis uniquement pour les catégories ou la personnalité des recettes.

Travaille chaque écran :
- lancement crème avec monogramme/assiette stylisée ;
- onboarding très court sans compte ;
- Accueil avec date, repas du jour, bouton signature aléatoire, favoris, récents et aperçu courses ;
- Recettes avec recherche, catégories, filtres, tri et belles cartes adaptatives ;
- fiche avec photo héro, capsules de métadonnées, portions, sections et bouton cuisine persistant ;
- mode cuisine cacao plein écran, texte très grand, progression or et commandes basses accessibles ;
- planning vertical sur iPhone et grille réelle sur iPad paysage ;
- courses utilisables d’une main avec progression et rayons repliables ;
- garde-manger en segments Frigo/Congélateur/Placard ;
- ajout/import découpé en étapes courtes avec brouillon automatique ;
- statistiques sobres et réglages bien regroupés.

Sur iPad, utilise NavigationSplitView, des grilles adaptées, des formulaires en deux colonnes et un mode cuisine paysage avec liste d’étapes à gauche. Ne livre jamais une simple interface iPhone agrandie. Implémente le thème sombre cacao, tous les états vides/chargement/erreur, Dynamic Type, VoiceOver, contraste, Réduire les animations et cibles tactiles de 44 points minimum. Les animations doivent durer environ 160 à 300 ms et ne jamais ralentir l’usage.

FONCTIONS À IMPLÉMENTER DANS LE MVP

- Accueil personnalisé « Bon appétit, Brendon ! » ;
- bibliothèque complète de recettes ;
- recherche par nom, ingrédient, catégorie, difficulté et tag ;
- catégories Entrée, Plat, Dessert, Petit creux, Boisson ;
- filtres Tous, Rapide, Favoris, Petit budget et tags ;
- cartes de recettes illustrées ;
- favoris ;
- suggestion aléatoire avec possibilité d’en demander une autre ;
- fiche recette avec Ingrédients, Préparation, Nutrition, Notes et Modifier ;
- ajustement des portions et quantités simples ;
- ingrédients cochables ;
- ajout aux courses ;
- création, modification, changement de photo et suppression confirmée ;
- planning lundi-dimanche, Midi/Soir ;
- création de la liste de courses depuis une recette ou le menu ;
- fusion raisonnable et regroupement par rayon ;
- ajout manuel, coche, suppression et vidage des courses ;
- statistiques définies dans le cahier des charges ;
- import de texte avec prévisualisation/correction avant sauvegarde ;
- import URL réel au minimum via JSON-LD schema.org/Recipe, avec repli honnête vers le collage de texte ;
- mode cuisine plein écran avec progression, navigation, vue de toutes les étapes et minuteur robuste en arrière-plan ;
- sept recettes de démonstration insérées une seule fois au premier lancement.

FONCTIONS INDISPENSABLES SUPPLÉMENTAIRES — PHASE 1

- Accueil « Aujourd’hui » avec repas planifiés, favoris et récemment consultées ;
- collections personnalisées ;
- tri par nom, date, durée, coût, note et dernière préparation ;
- filtres combinables ;
- duplication de recette et détection des doublons d’import ;
- historique de cuisine avec date, note et commentaire ;
- adaptation intelligente des unités et portions ;
- sauvegarde JSON complète, export, aperçu et restauration ;
- partage d’une recette et de la liste de courses avec les fonctions iOS ;
- navigation entre semaines avec dates réelles ;
- copie de la semaine précédente ;
- états Restes et Repas extérieur ;
- portions par repas et génération des courses sur une sélection de jours ;
- estimation facultative du coût hebdomadaire à partir des prix saisis ;
- progression des courses, rayons personnalisables, ordre habituel, historique récent et annulation ;
- reprise d’une session de cuisine ;
- maintien de l’écran allumé pendant la cuisson ;
- plusieurs minuteurs locaux nommés ;
- écran final de recette avec ajout à l’historique.

FONCTIONS HUB — PHASE 2, À COMMENCER UNIQUEMENT QUAND LA PHASE 1 EST STABLE

- garde-manger local avec Frigo, Congélateur et Placard ;
- quantités, dates d’ouverture/péremption, basiques et À racheter ;
- transfert facultatif d’un article acheté vers le garde-manger ;
- proposition de déduction après avoir cuisiné avec confirmation ;
- « Que cuisiner avec ce que j’ai ? » avec pourcentage disponible et ingrédients manquants ;
- modes Zéro course et Anti-gaspillage ;
- OCR local depuis photo/capture avec Vision ;
- écran de vérification du titre, des ingrédients et des étapes détectés ;
- budget hebdomadaire facultatif et non culpabilisant ;
- statistiques enrichies sur les habitudes et l’anti-gaspillage ;
- personnalisation du prénom, des portions, des créneaux, des rayons, du thème et des aliments exclus.

DONNÉES ET QUALITÉ

Normalise le modèle historique : isFavorite doit être un booléen et non un tag. Les quantités doivent conserver leur texte original tout en utilisant amount + unit lorsqu’elles sont analysables. Une fusion de courses ne doit additionner que des quantités compatibles ; sinon, conserver les deux indications de manière lisible.

Écris des tests au minimum pour :
- filtres et recherche ;
- conversion des portions ;
- fusion des articles de courses ;
- génération des courses depuis la semaine ;
- unicité des entrées de planning ;
- décodage de l’import texte/JSON-LD ;
- insertion unique des données de démonstration ;
- aller-retour export puis restauration JSON sans perte ;
- duplication et détection de doublon ;
- reprise de session et calcul de fin des minuteurs ;
- classement « Que cuisiner avec ce que j’ai ? » lorsque la phase 2 est présente.

HORS PÉRIMÈTRE ACTUEL

N’ajoute pas de compte, authentification, abonnement, publicité, achat intégré, backend, réseau social, CloudKit, API externe obligatoire ou fonction IA. N’ajoute pas non plus de widget, Live Activity ou extension nécessitant Xcode dans ce projet Swift Playground. Prévois seulement une architecture locale claire, sans écran ni bouton factice.

La suggestion/génération d’image IA de l’ancien prototype doit être complètement retirée. Conserve uniquement la sélection depuis la photothèque, l’appareil photo si disponible et l’URL d’une image.

LIVRABLES ATTENDUS

- projet d’app Swift Playground natif complet `BrendonHubCuisine.swiftpm` ;
- code source organisé par fonctionnalités ;
- modèles SwiftData et migration initiale ;
- données de démonstration ;
- tests ;
- assets, couleurs, icône temporaire propre et polices correctement déclarées si incluses ;
- fichier DesignSystem.swift et composants visuels réutilisables ;
- thème clair et thème sombre complets ;
- garde-manger et OCR local lorsque la phase 2 est livrée ;
- `README_IPAD.md` en français avec transfert, ouverture, exécution et dépannage dans Swift Playground ;
- README complémentaire pour Xcode si le projet est repris plus tard sur Mac ;
- fichier DECISIONS.md listant les choix techniques et ce qui reste volontairement hors MVP ;
- aucun bouton principal factice, aucun TODO bloquant et aucun secret.

CRITÈRES DE RECETTE FINALE

Avant de conclure :
1. vérifie l’arborescence ;
2. exécute le build et les vérifications si un environnement Apple compatible est disponible ;
3. corrige tous les échecs relevant du code ;
4. vérifie la persistance après relance avec un test ou un scénario reproductible ;
5. résume exactement ce qui est terminé, les commandes exécutées et les seules limites restantes ;
6. donne d’abord les étapes concrètes pour lancer l’app dans Swift Playground sur l’iPad, puis seulement l’option Xcode/simulateur pour plus tard.

Commence maintenant. Ne produis pas seulement une explication ou une maquette : crée et modifie réellement les fichiers du projet.
```

## 12. Questions à décider plus tard

Ces décisions peuvent être prises après le MVP, quand le fonctionnement de base est validé :

1. Le nom public doit-il rester « Brendon Hub Cuisine » ou devenir simplement « Hub Cuisine » ?
2. L’app doit-elle être utilisée uniquement par Brendon, ou par Lina et Brendon avec synchronisation ?
3. L’app restera-t-elle personnelle ou sera-t-elle publiée sur l’App Store ?
4. La synchronisation iCloud sera-t-elle utile plus tard, lorsqu’un accès Xcode sera disponible ?
