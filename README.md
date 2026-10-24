# QuickFix Tunisia

Prototype Flutter de mise en relation entre clients et artisans pour le dépannage à domicile. Toutes les données sont locales, chargées depuis `assets/data/demo_data.json` ; aucune API, base de données ou paiement n’est intégré.

## Prérequis

- Flutter et Dart stables.

## Installation

```bash
flutter pub get
flutter run
```

## Écrans disponibles

- Recherche de services et liste d’artisans vérifiés.
- Fiche artisan et création validée d’une demande.
- Suivi des demandes et avis de démonstration.
- Aperçu des parcours artisan et administration.

## Comptes de démonstration

Les boutons de l’écran de connexion remplissent les identifiants automatiquement. Ils peuvent aussi être saisis manuellement :

- Client : `client@quickfix.tn` / `client123`
- Artisan : `artisan@quickfix.tn` / `artisan123`
- Administration : `admin@quickfix.tn` / `admin123`

Les filtres, demandes créées et changements d’état (acceptation/refus) restent en mémoire pendant l’exécution. Ils sont réinitialisés au redémarrage de l’application.

## Architecture

`lib/app` centralise le thème et les routes ; `lib/core` contient les modèles, le chargement du JSON et l’état local réactif ; `lib/features` organise les écrans par fonctionnalité. L’état restant strictement local, aucune solution de gestion d’état externe n’est nécessaire à ce stade.

## Vérifications

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Configuration

Il n’y a aucune variable d’environnement ni secret à renseigner pour cette version.

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

