# QuickFix Tunisia

Application Flutter de mise en relation entre clients et artisans pour le dépannage à domicile. Les données sont stockées dans Cloud Firestore et les comptes sont gérés par Firebase Authentication (e-mail/mot de passe).

## Expériences par rôle

- **Client** : recherche d’un artisan vérifié, consultation de sa fiche, création et suivi d’une demande, annulation avant acceptation et dépôt d’un avis après intervention terminée.
- **Artisan** : tableau de bord des demandes, gestion du planning et des indisponibilités, acceptation/refus, progression d’une intervention jusqu’à sa terminaison, rapport d’intervention et consultation de son profil professionnel.
- **Administrateur** : statistiques, validation ou refus des profils artisans, consultation des utilisateurs et correction exceptionnelle des statuts de demande.

Le devis est une étape de la même demande : `pending` → `awaitingQuote` → `accepted` → `inProgress` → `completed`. Une fois l’intervention commencée, l’artisan peut enregistrer un brouillon de rapport puis doit décrire les travaux réalisés pour la clôturer. Le rapport peut contenir un diagnostic, les matériaux utilisés et des conseils. Le client consulte ce récapitulatif depuis l’historique de sa demande ; le devis accepté reste inchangé. Le client peut refuser le devis (`quoteRefused`), ce qui clôture définitivement la demande ; l’artisan ne peut donc plus démarrer l’intervention. Une demande reçue peut aussi être refusée par l’artisan ou annulée par le client.

Après la clôture, l’artisan peut préparer un **projet de facture** à partir du devis accepté et du rapport. Il renseigne son nom ou sa raison sociale, son adresse professionnelle, son matricule fiscal et le taux de TVA applicable. L’application affiche un aperçu PDF avant de figer le document ; le client et l’artisan peuvent ensuite le consulter et le télécharger, y compris sur le Web. Le montant TTC reste celui du devis accepté. Les données sont enregistrées une seule fois dans Firestore et le PDF est généré à la demande sur l’appareil : aucun fichier PDF n’est stocké dans Firebase Storage. Le document porte la mention « Projet de facture - non validé par Tunisie TradeNet ». Il ne constitue pas une facture électronique officielle et aucune signature ou référence fiscale n’est inventée.

Le chat est disponible uniquement au client et à l’artisan concerné, après acceptation et pendant l’intervention. Il permet de préciser l’accès, l’horaire ou le besoin ; il est fermé lorsque l’intervention est terminée, refusée ou annulée.

Les clients peuvent enregistrer des adresses dans leur compte. Elles sont stockées dans `users/{uid}/addresses` et peuvent préremplir une nouvelle demande. L’apparence suit automatiquement le réglage clair ou sombre de l’appareil.

## Réservations et confidentialité

L’artisan publie ses plages habituelles, la durée des créneaux et ses journées d’absence depuis l’onglet **Planning**. Le client voit uniquement les jours ouverts et les créneaux calculés à partir de ce planning, puis envoie une demande que l’artisan accepte ou refuse.

L'adresse complète est stockée dans un document privé séparé. Avant l'acceptation, l'artisan ne voit que sa zone d'intervention ; l'adresse est révélée à l'artisan après acceptation. Les demandes ne sont lisibles que par leur client, leur artisan ou un administrateur.

Pour les nouvelles demandes, `requests/{id}` ne contient que la ville ; l’adresse complète est dans `requests/{id}/private/location`. Les anciennes demandes qui contiennent déjà l’adresse complète dans le document principal nécessitent une migration administrative si elles doivent bénéficier de la même protection.

## Prérequis

- Flutter et Dart stables ;
- un projet Firebase ;
- Firebase CLI et FlutterFire CLI.

## Installation Firebase

1. Créez un projet dans la [console Firebase](https://console.firebase.google.com/), puis activez **Authentication > E-mail/Mot de passe** et créez une base **Cloud Firestore**.
2. Connectez-vous puis installez l’outil de configuration :

```bash
firebase login
dart pub global activate flutterfire_cli
```

3. À la racine du dépôt, exécutez `flutterfire configure` et sélectionnez les plateformes de l’application. La commande génère `lib/firebase_options.dart` et la configuration native propre à votre projet.
4. Déployez les règles d’accès versionnées dans ce dépôt :

```bash
firebase deploy --only firestore:rules
```

5. Déployez à nouveau les règles après chaque modification :

```bash
firebase deploy --only firestore:rules
```

## Comptes et rôles

L’inscription permet de choisir un compte `client` ou `artisan` :

- un client crée son profil dans `users/{uid}` et accède à la recherche ainsi qu’au suivi de ses demandes ;
- un artisan crée son profil dans `users/{uid}` et une fiche dans `artisans/{uid}` avec son métier, sa zone et son tarif de départ. Sa fiche est créée non vérifiée ; seule l’administration peut la valider ;
- un administrateur ne peut pas être créé depuis l’application. Son rôle doit être attribué par un environnement d’administration de confiance.

Les règles Firestore interdisent à un artisan de se déclarer vérifié ou de modifier les données de validation.

### Mot de passe oublié

Depuis la connexion, l’utilisateur peut demander un e-mail de réinitialisation. Firebase Authentication envoie le lien et héberge la page où définir le nouveau mot de passe ; aucun serveur SMTP ni stockage de token dans Firestore n’est nécessaire. Vérifiez dans la console Firebase que le fournisseur **E-mail/Mot de passe** est activé, puis personnalisez si besoin le modèle **Authentication > Templates > Password reset**. Activez la protection contre l’énumération des adresses dans les paramètres d’Authentication. L’application affiche la même confirmation lorsque l’adresse ne correspond à aucun compte. Sur le plan gratuit Spark, la limite publiée est de 150 e-mails de réinitialisation par jour.

L’application demande un e-mail en français. Pour remplacer le nom technique du projet dans le message, configurez le modèle **Password reset** dans la console Firebase avec le nom d’expéditeur `QuickFix Tunisia`, l’objet `Réinitialisez votre mot de passe QuickFix Tunisia` et le corps HTML suivant. Conservez impérativement `%LINK%` : Firebase le remplace par le lien de réinitialisation personnel.

```html
<p>Bonjour,</p>
<p>Une demande de réinitialisation du mot de passe a été effectuée pour votre compte QuickFix Tunisia.</p>
<p>Pour choisir un nouveau mot de passe, cliquez sur le lien ci-dessous :</p>
<p><a href="%LINK%">Réinitialiser mon mot de passe</a></p>
<p>Si vous n’êtes pas à l’origine de cette demande, ignorez cet e-mail. Votre mot de passe reste inchangé.</p>
<p>L’équipe QuickFix Tunisia</p>
```

Le domaine `firebaseapp.com` restera visible dans l’adresse d’envoi et le lien tant qu’un domaine personnalisé n’aura pas été configuré et vérifié dans Firebase.

### Catalogue des profils artisans

Le métier et la ville d’intervention sont des valeurs contrôlées. L’application affiche leurs libellés français, mais Firestore stocke uniquement des identifiants stables : par exemple `plumber` et `tunis`. Les villes actuellement proposées sont Tunis, Ariana, Ben Arous, Manouba, Sfax, Sousse et Bizerte. La ville est obligatoire lors de la création d’un compte artisan et les clients peuvent filtrer les artisans par ville.

Après le déploiement des règles, convertissez les fiches existantes depuis un environnement administrateur Firebase. La commande utilise les identifiants applicatifs par défaut ou le chemin indiqué dans `GOOGLE_APPLICATION_CREDENTIALS`; elle ne contient aucun secret.

```bash
cd functions
npm run migrate:artisan-catalog
```

La migration convertit notamment `Plomberie` / `Plombier` en `plumber` et `Tunis` en `tunis`. Elle liste et laisse intactes les fiches dont les valeurs ne sont pas reconnues afin de les corriger explicitement.

### Comptes de démonstration

Le script suivant crée ou met à jour 24 comptes artisans de démonstration, avec des villes, métiers et plannings différents. Il attend le mot de passe en variable d’environnement pour qu’aucun mot de passe ne soit versionné. Exécutez-le depuis un environnement Firebase Admin autorisé :

```powershell
cd functions
$env:DEMO_ARTISANS_PASSWORD = 'votre-mot-de-passe-de-demo'
npm run seed:demo-artisans
```

Le script est idempotent : une nouvelle exécution met à jour les mêmes 24 comptes.

## Lancer l’application

```bash
flutter pub get
flutter run
```

## Architecture

- `lib/features/auth/data` : connexion et inscription Firebase Authentication ;
- `lib/features/users/data` : profils et rôles Firestore ;
- `lib/features/artisans/data` : catalogue temps réel des artisans ;
- `lib/features/availability/presentation` : gestion du planning artisan ;
- `lib/features/request/data` : demandes et génération locale du PDF de facturation ;
- `lib/core/state/app_controller.dart` : état de session léger partagé par l’interface.

Les collections Firestore sont `users`, `artisans`, `requests` et `reviews`. Les messages sont stockés dans `requests/{requestId}/messages`. Les règles dans `firestore.rules` limitent les lectures et modifications au client, à l’artisan concerné ou à l’administrateur. Les contrôles de transition sont également appliqués côté serveur.

Les projets de facture sont conservés dans `requests/{requestId}/billing/document` et deviennent non modifiables après création. Les packages `pdf` et `printing` servent à créer et prévisualiser le document ; les polices Lato livrées avec l’application sont distribuées sous licence OFL (`assets/fonts/OFL-Lato.txt`). Aucun service Firebase payant ni stockage binaire Firestore n’est nécessaire pour ce parcours.

## Notifications

L’application affiche une pastille de notifications Firestore. Les notifications système hors application (push) ne sont pas incluses : elles nécessiteraient la collecte explicite d’un jeton FCM et l’autorisation de l’utilisateur.
## Vérifications

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```
