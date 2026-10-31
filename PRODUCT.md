# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack

Flutter/Dart stable — choisi explicitement dans les règles du dépôt et la demande.

## Users

Les clients tunisiens recherchent rapidement un artisan fiable pour un dépannage ou une maintenance à domicile. Les artisans et administrateurs sont aussi représentés dans des vues de démonstration afin de préparer leurs parcours.

## Product Purpose

QuickFix Tunisia met en relation clients et artisans à domicile. La V1 avancée utilise Firebase Authentication et Cloud Firestore pour fournir des parcours séparés et sécurisés aux clients, artisans et administrateurs.

## Positioning

Le produit rend le dépannage local plus lisible grâce à la recherche par métier et zone, aux profils vérifiés, aux prix indicatifs et à un suivi clair de chaque intervention.

## Operating Context

Usage mobile prioritaire, souvent dans une situation de besoin immédiat. Le client recherche, consulte un artisan, crée puis suit une demande. Les rôles artisan et administration utilisent des listes et changements d’état illustratifs.

## Capabilities and Constraints

- Parcours à préparer : recherche, fiche artisan, création et suivi de demande, avis ; espace artisan ; aperçu administratif.
- Les comptes, profils, artisans, demandes et avis sont stockés dans Cloud Firestore.
- Firebase Authentication gère les sessions par e-mail et mot de passe.
- Aucun paiement, chat temps réel, justificatif documentaire ni upload photo dans cette V1.
- Les transitions de demande et les droits de rôle sont contrôlés par l’application et les règles Firestore.
- L’interface est en français, responsive et accessible.

## Brand Commitments

Nom : QuickFix Tunisia. Le ton doit être rassurant, direct et pratique. Aucun logo ni autre actif de marque n’a été fourni.

## Evidence on Hand

Le cahier des charges `Cahier_des_charges_QuickFix_Tunisia_v1_1.docx` est la source des rôles, états et parcours. Les contenus de profils et prix sont explicitement fictifs dans le prototype.

## Product Principles

- Aider à agir vite, sans masquer les informations utiles.
- Rendre la confiance visible avant la prise de contact.
- Expliquer l’avancement d’une intervention par un état simple et compréhensible.
- Donner à chaque rôle une expérience orientée vers ses tâches réelles.
- Ne jamais considérer l’interface comme une sécurité : les règles Firestore restent la source de contrôle.

## Accessibility & Inclusion

Utiliser les composants Material, un contraste lisible, des libellés explicites, des cibles tactiles adaptées et un comportement responsive.
