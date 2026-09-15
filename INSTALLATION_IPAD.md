# Installer Hub Cuisine parmi les apps de l’iPad

## Le fichier nécessaire

Il faut d’abord obtenir **HubCuisine-unsigned.ipa** à l’issue d’une compilation GitHub réussie. Le ZIP de sources et le dossier `.swiftpm` ne s’installent pas directement depuis Fichiers.

Une app iOS doit être signée pour ton appareil. Le fichier produit sur GitHub est volontairement non signé : ton compte Apple sera utilisé localement par l’outil d’installation. Aucun abonnement développeur Apple n’est nécessaire pour cette méthode personnelle, mais la signature gratuite est valable sept jours et doit être renouvelée.

## Option adaptée à un usage surtout sur iPad : SideStore

SideStore est gratuit et open source. Il permet l’installation de fichiers IPA et leur renouvellement depuis l’iPad, avec une connexion Wi-Fi et son VPN local. Sa documentation indique qu’un ordinateur Windows, Mac, Linux ou Chromebook compatible est requis pour **la première installation**. Un ordinateur emprunté peut donc suffire, sauf en cas de réinstallation ou de dépannage.

1. Sur cet ordinateur, suivre le [guide officiel de préparation SideStore](https://docs.sidestore.io/docs/installation/prerequisites). Il décrit l’installation d’iloader et des composants nécessaires selon le système.
2. Sur l’iPad, installer **LocalDevVPN** depuis le lien App Store donné dans ce guide. C’est un tunnel local utilisé pour communiquer avec les services de l’appareil.
3. Brancher l’iPad à l’ordinateur, accepter **Faire confiance**, puis suivre l’installation SideStore avec iloader et ton compte Apple. Saisir les informations de connexion uniquement dans les applications officielles concernées, jamais dans GitHub ou dans cette conversation.
4. Suivre les demandes de confiance du profil développeur et d’activation du mode Développeur lorsqu’elles apparaissent. Les étapes à jour figurent dans le [guide d’installation](https://docs.sidestore.io/docs/installation/install).
5. Télécharger et décompresser l’artifact GitHub dans Fichiers pour obtenir `HubCuisine-unsigned.ipa`.
6. Activer LocalDevVPN, ouvrir SideStore, aller dans **My Apps**, toucher **+**, puis choisir le fichier IPA. Attendre la signature et l’installation.
7. Hub Cuisine doit apparaître sur l’écran d’accueil. Ouvrir l’app et vérifier les parcours et les notifications.
8. Configurer le renouvellement quotidien de **SideStore et Hub Cuisine** avec les étapes de [RENOUVELLEMENT_AUTO.md](RENOUVELLEMENT_AUTO.md), puis vérifier son premier déclenchement sur l’iPad. Pour un renouvellement manuel, se connecter au Wi-Fi, activer le VPN local, puis utiliser **Refresh All** avant la fin des sept jours.

Le compte gratuit autorise trois apps installées par cette méthode, SideStore compris. Si SideStore expire, un ordinateur peut être nécessaire pour le réinstaller. La méthode ne garantit pas un fonctionnement permanent sans entretien et reste dépendante des changements d’Apple et du projet SideStore.

## Alternative avec un PC disponible régulièrement : Sideloadly

[Sideloadly](https://sideloadly.io/) fonctionne sous Windows et macOS avec un compte Apple gratuit. Il peut installer le fichier IPA et renouveler automatiquement les signatures, à condition que l’ordinateur et l’iPad puissent communiquer.

1. Installer Sideloadly depuis son site officiel et suivre les prérequis Apple indiqués pour Windows.
2. Brancher l’iPad, le déverrouiller et accepter **Faire confiance**.
3. Charger `HubCuisine-unsigned.ipa`, sélectionner l’iPad et renseigner ton compte Apple dans Sideloadly.
4. Lancer l’installation et suivre les demandes de confiance du développeur et de mode Développeur sur l’iPad.
5. Activer le renouvellement automatique. Pour le renouvellement par Wi-Fi, l’ordinateur doit être disponible et sur le même réseau que l’iPad.

## Tes données

Une app installée séparément peut avoir un conteneur de données différent de l’app exécutée dans Swift Playground. Avant de changer de méthode, exporter le carnet depuis **Plus → Sauvegarder et restaurer** puis importer ce JSON dans l’app installée.

Conserver le même compte de signature et le même identifiant d’application lors des mises à jour. Éviter de supprimer l’app pour la mettre à jour : exporter d’abord les données si une réinstallation devient nécessaire.

## Ce que cette méthode ne permet pas

GitHub remplace le Mac de compilation, mais ne signe pas automatiquement une app avec un compte Apple gratuit et ne peut pas se connecter physiquement à ton iPad. L’installation initiale nécessite encore les manipulations ci-dessus. Aucun certificat d’entreprise partagé, contournement de paiement ou jailbreak n’est utilisé.

Si tu ne peux accéder à aucun ordinateur, même une seule fois, cette procédure SideStore ne peut pas être menée jusqu’à l’installation initiale. Le projet reste exécutable dans Swift Playground en attendant ; ce n’est pas la même chose qu’une icône d’app indépendante.

Sources : [SideStore](https://sidestore.io/), [prérequis](https://docs.sidestore.io/docs/installation/prerequisites), [FAQ SideStore](https://docs.sidestore.io/docs/faq), [Sideloadly](https://sideloadly.io/), [limites du compte Apple gratuit](https://developer.apple.com/help/account/basics/about-your-developer-account).
