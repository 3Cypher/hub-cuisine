# Renouvellement quotidien de Hub Cuisine sur l’iPad

Cette configuration se fait dans l’app **Raccourcis de ton iPad**, après l’installation de SideStore et de Hub Cuisine. Elle n’est pas activée par le téléchargement de ce dossier. Aucun renouvellement n’a encore été testé sur ton appareil.

## 1. Vérifier une première fois la signature

Connecter l’iPad au Wi-Fi, activer **LocalDevVPN**, ouvrir SideStore et lancer **Refresh All** dans **My Apps**. Vérifier que les compteurs de **SideStore et Hub Cuisine** reviennent à environ sept jours. Ouvrir Hub Cuisine depuis son icône et vérifier que le carnet est présent.

## 2. Créer le raccourci « Renouveler Hub Cuisine »

Dans **Raccourcis → +**, nommer le raccourci puis ajouter les actions suivantes, dans cet ordre :

1. **Définir le VPN / Set VPN** : choisir **Connecter** et le profil **LocalDevVPN** déjà installé. Si cette action ne propose pas ce profil, activer LocalDevVPN manuellement et le laisser connecté pour les renouvellements.
2. **Attendre** : trois secondes, pour laisser au tunnel le temps de se connecter.
3. Dans les actions de l’app **SideStore**, choisir **Refresh All Apps**. Le libellé peut être traduit selon la langue de l’app. Cette action effectue le renouvellement de toutes les apps concernées, y compris SideStore ; simplement ouvrir SideStore ne remplace pas cette action.

Lancer une première fois le raccourci avec l’iPad déverrouillé et accepter les demandes d’accès nécessaires. Vérifier à nouveau les deux compteurs dans SideStore. Si l’action SideStore n’apparaît pas, ouvrir SideStore puis relancer Raccourcis ; vérifier la version installée avant de créer l’automatisation.

## 3. Déclencher le raccourci chaque jour

Dans **Raccourcis → Automatisation → + → Heure de la journée** :

1. Choisir **Tous les jours**, à une heure où l’iPad est normalement allumé et connecté au Wi-Fi, par exemple **09 h 00**.
2. Choisir **Exécuter immédiatement**. Sur une version qui présente plutôt **Demander avant d’exécuter**, désactiver cette demande et confirmer.
3. Sélectionner le raccourci **Renouveler Hub Cuisine**. Si nécessaire, ajouter l’action **Exécuter le raccourci** et le sélectionner.
4. Conserver les notifications d’exécution proposées par iPadOS, au moins pendant la vérification initiale.

Un essai quotidien laisse plusieurs occasions de renouveler avant l’expiration. Il ne faut pas programmer un unique essai le septième jour. Le renouvellement se fait avec SideStore sur l’iPad ; il n’est pas nécessaire de recompiler le projet sur GitHub chaque semaine.

## 4. Vérifier que l’automatisation fonctionne réellement

Après le premier déclenchement automatique, ouvrir SideStore et contrôler les dates de validité des deux apps. Répéter cette vérification le lendemain. Une notification de déclenchement de Raccourcis ne prouve pas, à elle seule, que la signature a été renouvelée.

L’iPad doit disposer du Wi-Fi et du tunnel local lors de l’exécution. Une tâche peut échouer ou demander une intervention : le code public de SideStore prévoit notamment une demande de passage au premier plan si le renouvellement prend trop longtemps. Cette procédure automatise les tentatives ; elle ne garantit pas une signature permanente sans surveillance.

Si le compteur continue à descendre, lancer **Refresh All** manuellement avant l’expiration et examiner l’erreur de SideStore. Si SideStore a déjà expiré ou si son association avec l’appareil est devenue invalide après une mise à jour, un ordinateur peut être nécessaire pour réparer l’installation. Exporter régulièrement le carnet depuis Hub Cuisine avant toute réinstallation.

## Sources vérifiées le 15 septembre 2026

- [SideStore : Wi-Fi, VPN local et ordinateur pour l’installation initiale](https://docs.sidestore.io/docs/installation/prerequisites).
- [SideStore : action Refresh All Apps et gestion du délai en arrière-plan](https://github.com/SideStore/SideStore/blob/develop/AltStore/Intents/App%20Intents/RefreshAllAppsIntent.swift). Le fichier consulté appartient à la branche de développement ; le comportement exact dépend de la version installée.
- [Apple : exécuter une automatisation personnelle sans confirmation](https://support.apple.com/guide/shortcuts/enable-or-disable-a-personal-automation-apd602971e63/9.0/ios/26).
- [SideStore : installation et premier renouvellement](https://docs.sidestore.io/docs/installation/install).
