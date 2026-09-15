# Hub Cuisine — compilation GitHub et installation sur iPad

Ce dossier contient le projet SwiftUI final et une chaîne de compilation iOS sur GitHub Actions. **Ce n’est pas encore un fichier IPA compilé.** La compilation n’a pas pu être lancée : la connexion GitHub disponible ne donne accès à aucun dépôt.

## Obtenir le fichier d’installation

1. Choisir ou créer un dépôt **public** GitHub, par exemple `hub-cuisine`. Son code sera visible publiquement. Ne jamais y ajouter une sauvegarde personnelle, un mot de passe Apple ou des certificats.
2. Autoriser ce dépôt dans la connexion GitHub de ChatGPT et transmettre son lien pour permettre la mise en place et le suivi de la compilation. La connexion actuelle reconnaît le compte, mais ne retourne aucun dépôt ni installation autorisés.
3. À défaut d’une mise en place accompagnée, déposer le **contenu** de ce dossier à la racine du dépôt, en conservant le dossier de workflow `.github/workflows`. Une simple pièce jointe ZIP dans un dépôt ne déclenche pas la compilation.
4. Dans l’onglet **Actions**, ouvrir **Compiler Hub Cuisine pour iPad**. Le workflow se lance lors de l’ajout du projet ; il peut aussi être lancé avec **Run workflow** depuis la branche principale.
5. Attendre un résultat réussi. Le workflow produit **HubCuisine-IPA-a-signer**, contenant `HubCuisine-unsigned.ipa`, son empreinte SHA-256 et la notice d’installation.
6. En cas d’échec, récupérer **HubCuisine-journaux**. Une erreur de compilation doit être corrigée avant d’obtenir une application : aucun faux IPA n’est produit.
7. Installer le fichier IPA avec les étapes de `INSTALLATION_IPAD.md`, puis configurer le renouvellement quotidien décrit dans `RENOUVELLEMENT_AUTO.md`. Cette automatisation doit être activée et vérifiée sur l’iPad ; elle n’a pas encore été exécutée.

Le workflow utilise une machine **macos-15 standard** et s’arrête après 25 minutes maximum. Les machines standard sont gratuites pour les dépôts publics selon les conditions de GitHub Actions. Pour éviter d’utiliser une allocation privée dont le solde n’est pas connu, ce workflow ignore les dépôts privés. Il ne modifie jamais la visibilité d’un dépôt. Les artifacts sont conservés sept jours et les petits journaux trois jours ; aucun cache de compilation n’est téléversé.

## Ce que GitHub fait

- Lit les sources SwiftUI et les ressources du projet livré.
- Utilise XcodeGen, outil de compilation gratuit, pour créer une cible Xcode classique. XcodeGen est installé uniquement sur la machine GitHub, pas dans l’app.
- Exécute les tests métier existants et le test des sept recettes initiales dans un package Foundation isolé.
- Compile une application iOS arm64 en Release, avec cible iOS 17 minimum.
- Vérifie la présence du binaire, des assets compilés et des recettes avant de créer le ZIP IPA attendu par les outils de signature.
- Ne signe pas l’application et n’utilise aucun compte Apple : la signature reste une étape locale dans SideStore ou Sideloadly.

`BuildSupport/BundleModule.swift` adapte la recherche des ressources au bundle principal de la cible Xcode. Ce fichier n’est pas ajouté à la cible Swift Playground, qui conserve son propre `Bundle.module` généré. Les sources du projet Swift Playground livré sont inchangées.

Le workflow utilise les versions majeures officielles `actions/checkout@v7` et `actions/upload-artifact@v7` et la version de Xcode fournie par l’image `macos-15`. Leurs versions peuvent évoluer. Les versions de Xcode, Swift et XcodeGen sont affichées dans les journaux pour faciliter les corrections.

## État de validation

La préparation du package de tests, la syntaxe Python, la structure YAML, les chemins des sources/ressources et l’intégrité du ZIP ont été contrôlés localement. Le script de création d’IPA refuse de fonctionner lorsqu’aucune application compilée n’existe.

Les tests métier précédemment réussis sont documentés dans `BrendonHubCuisine.swiftpm/VALIDATION.md`. Aucun nouveau succès de compilation Apple n’est revendiqué ici. Le premier run GitHub devra compiler l’interface SwiftUI et SwiftData ; les éventuelles erreurs doivent être corrigées, puis un essai réel sur iPad reste nécessaire.

## Sources officielles

- [Facturation et gratuité GitHub Actions](https://docs.github.com/en/billing/concepts/product-billing/github-actions)
- [Image macOS 15 et versions de Xcode](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [Spécification de projet XcodeGen](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)
- [SideStore : installation et prérequis](https://docs.sidestore.io/docs/installation/prerequisites)
- [Sideloadly](https://sideloadly.io/)
