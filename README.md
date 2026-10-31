# QuickFix Tunisia

Application Flutter de mise en relation entre clients et artisans pour le dépannage à domicile. Les données sont stockées dans Cloud Firestore et les comptes sont gérés par Firebase Authentication (e-mail/mot de passe).

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

## Lancer l’application

```bash
flutter pub get
flutter run
```

## Architecture

- `lib/features/auth/data` : connexion et inscription Firebase Authentication ;
- `lib/features/users/data` : profils et rôles Firestore ;
- `lib/features/artisans/data` : catalogue temps réel des artisans ;
- `lib/features/request/data` : création, lecture et mise à jour des demandes ;
- `lib/core/state/app_controller.dart` : état de session léger partagé par l’interface.

Les collections Firestore sont `users`, `artisans` et `requests`. Les règles dans `firestore.rules` limitent les lectures et modifications au client, à l’artisan concerné ou à l’administrateur.

## Vérifications

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```
