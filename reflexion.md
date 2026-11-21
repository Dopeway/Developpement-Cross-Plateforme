# Réflexion technique — QuickFix Tunisia
## Objectif & Architecture en bref
QuickFix Tunisia est une application Flutter de mise en relation client–artisan, avec comptes Firebase Authentication et données Firestore. L’interface est organisée par fonctionnalités ; `AppController` centralise l’état de session et délègue les données aux repositories. Les demandes, le planning, le chat, les avis et les projets de facture sont persistés dans Firestore ; le PDF est créé localement. Le dépôt contient aussi des Cloud Functions Node.js et des règles Firestore, à maintenir en cohérence avec le client.

## Zones critiques & Pièges connus

- `firestore.rules` est le contrôle d’autorisation effectif : toute évolution de rôle, de statut, de champ ou de sous-collection doit y être validée, puis déployée.
- La création et les transitions de demandes touchent `app_controller.dart`, `request_repository.dart`, `intervention_request.dart` et `firestore.rules` ensemble. Préserver les contrôles de rôle, les montants de devis et la confidentialité de l’adresse.
- L’adresse complète doit rester dans `requests/{id}/private/location`; le document principal ne contient que la zone. Les anciennes demandes peuvent encore suivre le schéma historique, comme le précise le README.
- Les Cloud Functions (`functions/index.js`) ne suivent pas entièrement le schéma actuellement utilisé par le client et les règles : elles écrivent notamment `private/address` et des champs de réservation refusés par `firestore.rules`, tandis que Flutter écrit directement dans Firestore. Ne pas activer ou modifier ce parcours sans aligner les trois couches et leurs tests.
- `lib/firebase_options.dart`, `android/app/google-services.json` et `firebase.json` ciblent un projet Firebase concret. Régénérer avec FlutterFire lors d’un changement de projet plutôt que les modifier manuellement.
- Les statuts `accepted` et `quoteAccepted` coexistent dans les modèles/règles/fonctions : vérifier toutes les transitions et l’accès à l’adresse/chat lors d’un changement de workflow.

## Checklist d'auto-critique avant validation

- Le comportement modifié est-il couvert par un test Dart ou Node adapté, y compris le cas d’erreur utile ?
- Les règles Firestore autorisent-elles exactement la nouvelle écriture, sans élargir les droits d’un autre rôle ?
- Le client, les règles et les Functions utilisent-ils les mêmes noms de champs, sous-collections et statuts ?
- L’adresse privée, les données de compte et les identifiants Firebase restent-ils hors des lectures non autorisées et des logs ?
- Les écrans asynchrones affichent-ils un retour de chargement, d’erreur ou de réussite et vérifient-ils `mounted` après `await` ?
- Les modèles typés, les routes centralisées et le thème/conventions de fichiers existants sont-ils respectés ?
- `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test` et, si `functions/` change, `npm test` passent-ils ?

## Décisions & leçons établies

- Le client Flutter reste une base de code unique Material, avec interface en français, thème clair/sombre système et mise en page responsive (`ResponsivePageLayout` et `ResponsiveFormLayout`).
- L’état global léger est porté par `AppController` (`ChangeNotifier`) et exposé par `AppScope` (`InheritedNotifier`) : ne pas ajouter une seconde solution de gestion d’état sans nécessité.
- L’authentification repose sur Firebase Authentication par e-mail/mot de passe ; les profils et autorisations reposent sur Firestore, pas sur le seul état de l’interface.
- Les rôles sont limités à `client`, `artisan` et `admin`. Un administrateur est créé hors de l’application ; un artisan doit être validé avant d’être visible dans le catalogue.
- Les métiers et zones d’intervention utilisent des identifiants Firestore stables, avec libellés français dans l’interface. Conserver les valeurs du catalogue existant plutôt que stocker les libellés affichés.
- Les repositories isolent les accès Firestore par fonctionnalité ; les widgets appellent le contrôleur et ne doivent pas accéder directement à Firestore.
- La navigation utilise des routes nommées centralisées dans `lib/app/app_routes.dart` et des arguments typés pour les écrans de détail.
- Une demande contient l’état, le devis et le rapport d’intervention ; les transitions sont contrôlées à la fois par `AppController` et par `firestore.rules`.
- Le client peut annuler une demande en attente ou accepter/refuser un devis ; l’artisan peut envoyer le devis, refuser, démarrer puis terminer l’intervention. Toute nouvelle transition doit être ajoutée et testée dans les deux couches.
- Les rapports sont modifiables seulement pendant l’intervention ; la clôture exige une description des travaux d’au moins 10 caractères.
- Le chat appartient à `requests/{requestId}/messages`, est limité aux participants et fermé hors des états prévus par le workflow.
- Les avis sont liés à une demande terminée et un seul avis est attendu par demande. Les Cloud Functions recalculent la note et le nombre d’avis de l’artisan.
- Le planning artisan est un ensemble de plages hebdomadaires, d’exceptions et d’une durée de créneau. Les chevauchements sont refusés par le contrôleur et les créneaux sont calculés dans `availability_calculator.dart`.
- Les adresses enregistrées appartiennent à `users/{uid}/addresses`. Pour une demande, l’adresse précise est séparée dans la sous-collection privée afin de ne pas être révélée avant l’acceptation.
- Un projet de facture est créé seulement après intervention terminée, à partir du devis et du rapport. Ses données Firestore deviennent immuables et le PDF est généré localement avec `pdf` et `printing`, sans Firebase Storage.
- Les notifications sont lues depuis Firestore ; les notifications de changements de demande, chat et avis sont produites par les Cloud Functions.
- Les polices Lato sont des assets déclarés dans `pubspec.yaml`; ne pas les déplacer ou renommer sans mettre à jour la déclaration.
- La configuration Firebase est versionnée pour les plateformes prises en charge. Linux n’est pas configuré par `firebase_options.dart`, donc cette cible ne peut pas initialiser Firebase telle quelle.
- La couverture existante combine tests Dart de modèles, logique et widgets, avec trois tests Node pour la disponibilité. Il n’existe pas de test automatisé des règles Firestore ou d’intégration avec un émulateur Firebase dans le dépôt.
- Les Functions constituent un second parcours de réservation qui n’est pas appelé par le client Flutter actuel et dont le schéma diffère. Avant de l’utiliser, choisir explicitement le parcours de référence puis aligner client, règles, Functions et tests.

