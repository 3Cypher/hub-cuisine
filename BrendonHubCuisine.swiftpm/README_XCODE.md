# Reprise facultative dans Xcode

Le livrable principal reste le projet Swift Playground pour iPad. Aucun projet `.xcodeproj` généré n’est requis.

1. Sur un Mac disposant d’un Xcode avec SDK iOS 17 ou ultérieur (Xcode 15 minimum), décompressez le ZIP.
2. Ouvrez `BrendonHubCuisine.swiftpm` dans Xcode, depuis **File → Open** ou le Finder.
3. Sélectionnez le produit d’application **Hub Cuisine** et un simulateur iPad ou iPhone sous iOS 17+, puis **Product → Run**.
4. Si Xcode ouvre seulement le package de tests `HubCuisineCore`, il n’a pas reconnu le contexte d’app `AppleProductTypes`. Rouvrez le bundle `.swiftpm` complet et vérifiez la version de Xcode. La branche de tests du manifeste est prévue pour une chaîne Swift ordinaire, elle ne produit pas d’application iOS.
5. Pour un appareil physique ou une distribution, configurez la signature dans Xcode selon votre environnement. Aucun identifiant d’équipe ni certificat n’est inclus.

Le bundle identifier est `be.brendon.hubcuisine`. Un changement d’identifiant ou une nouvelle installation peut créer un conteneur de données distinct : exportez le carnet avant toute opération de ce type.

## Organisation

- `Sources/Core` : modèles Codable, quantités, recherche, courses, planning, import et sauvegardes. Foundation uniquement.
- `Sources/Persistence` : schéma SwiftData versionné et transactions du magasin.
- `Sources/Services` : Photos, caméra, Vision, URLSession, notifications et documents JSON.
- `Sources/Design` : couleurs sémantiques, typographie système et composants SwiftUI.
- `Sources/Features` : écrans organisés par fonction.
- `Resources` : données initiales, images, couleurs et icône.
- `Tests` : XCTest réutilisant les scénarios du cœur métier.

Le manifeste est en Swift tools 5.9 et le code d’application en mode Swift 5. Le chemin Apple déclare `.iOSApplication`; le chemin Swift ordinaire expose uniquement le cœur métier pour ses tests. Il n’ajoute aucune cible de tests à l’app Swift Playground.

Dans une chaîne Swift ordinaire sans `AppleProductTypes` :

```sh
swift test --package-path BrendonHubCuisine.swiftpm --jobs 1
```

Sur appareil, **Plus → Vérifications de l’application** exécute les mêmes contrôles et un contrôle SwiftData. Pour une évolution iOS plus large, un développeur peut aussi ajouter une cible de tests Xcode distincte ; elle n’est pas nécessaire pour ouvrir ce livrable.

Aucun build Xcode ou simulateur n’a été exécuté pendant la réalisation. Consultez `VALIDATION.md` avant de considérer une version prête à distribuer.
