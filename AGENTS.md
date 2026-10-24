# Règles de contribution — projet Flutter

Ce dépôt accueillera un projet pédagogique de développement cross-platform. Tout agent IA, y compris Codex, doit appliquer ces règles avant de créer ou modifier du code. Elles complètent le cahier des charges qui sera ajouté ultérieurement ; en cas de conflit, le cahier des charges explicite et les consignes de l'enseignant priment.

## 1. Cadre de travail

- Développer en Flutter et Dart stable, avec une seule base de code pour les plateformes demandées.
- Ne pas initialiser l'application, choisir des packages, ni décider de l'architecture métier avant réception du cahier des charges.
- Avant toute modification, lire `README.md`, `pubspec.yaml`, les éventuels `AGENTS.md` plus proches du fichier modifié, puis les tests concernés.
- Préserver les modifications existantes de l'utilisateur. Ne jamais écraser, supprimer ou reformater largement des fichiers non liés à la demande.
- Garder les changements petits, cohérents et limités au besoin demandé. Ne pas ajouter de dépendance sans justification fonctionnelle et validation dans `pubspec.yaml`.
- Utiliser les versions stables des dépendances compatibles avec le SDK déclaré dans `environment: sdk`. Ne jamais modifier les fichiers générés ou verrouillés sans raison explicite (`.dart_tool/`, `build/`, fichiers plateforme générés, `pubspec.lock` pour une bibliothèque).

## 2. Structure attendue

Quand l'application sera créée, organiser `lib/` par fonctionnalité :

```text
lib/
  app/                 # point d'entrée, thème, routes et configuration globale
  core/                # code transverse (erreurs, réseau, utilitaires)
  features/
    <feature>/
      data/            # DTO, sources distantes/locales, repositories
      domain/          # entités et contrats, si la complexité le justifie
      presentation/    # pages, widgets, état et contrôleurs
```

- Une page, un widget réutilisable, un modèle et un service ont chacun leur fichier, nommé en `snake_case`.
- Éviter les fichiers « fourre-tout », les pages démesurées et les widgets avec logique métier ou réseau intégrée.
- Partager un composant seulement lorsqu'il est réellement commun ; sinon le conserver dans la fonctionnalité qui l'utilise.
- Utiliser des modèles Dart typés, immuables quand possible, avec `fromJson` / `toJson` explicites. Ne pas propager `Map<String, dynamic>` dans l'interface.

## 3. Dart et état

- Respecter `dart format` et les lints du projet. Préférer `final`, `const`, les types explicites aux frontières et les constructeurs `const` lorsque possible.
- Ne pas utiliser `dynamic`, `print`, des valeurs magiques, ni ignorer un lint sans expliquer précisément pourquoi.
- Un `StatelessWidget` est le choix par défaut. Employer un `StatefulWidget` uniquement pour un état local qui varie indépendamment de son parent.
- Appeler `setState` uniquement pour de l'état local et bref. Ne pas y lancer de requête HTTP, de navigation ou de calcul coûteux.
- Après un `await` dans un `State`, vérifier `context.mounted` avant d'utiliser `context` ou d'appeler `setState`.
- Créer et libérer les ressources au bon cycle de vie : `initState` / `dispose` pour les contrôleurs, focus nodes, streams et animations.
- Choisir une solution de gestion d'état seulement quand le besoin est connu et rester cohérent dans tout le projet. Documenter ce choix dans le README.

## 4. Interface et accessibilité

- Construire chaque écran à partir de `Scaffold` et des composants Material adaptés ; centraliser couleurs, espacements et typographie dans le thème au lieu de les répéter dans les widgets.
- Préférer `InkWell` ou les boutons Material pour les actions tactiles visibles. Employer `GestureDetector` seulement lorsqu'aucun retour visuel Material n'est souhaité ou pertinent.
- Ne pas figer l'interface sur une taille d'écran. Utiliser les contraintes, les widgets flexibles et les marges cohérentes ; tester les petits écrans et le redimensionnement si la cible desktop/web est prévue.
- Utiliser `SafeArea` lorsque le contenu peut croiser une encoche, la barre système ou le clavier.
- Toutes les actions doivent être compréhensibles : libellés clairs, contraste suffisant, retours de chargement/erreur/succès et sémantique accessible pour les icônes non textuelles.
- Préférer `ListView.builder` et `GridView.builder` pour les collections longues ou non bornées. Réserver les constructeurs avec `children` aux petites listes statiques.
- Donner des clés stables aux éléments de listes interactives ou susceptibles d'être réordonnés.

## 5. Formulaires et saisie

- Employer `Form` avec une `GlobalKey<FormState>` et des `TextFormField` pour les formulaires validables ; appeler `validate()` avant toute soumission.
- Ajouter validation, type de clavier, libellé, aide et messages d'erreur utiles pour chaque champ pertinent. Ne jamais faire confiance aux données côté client seulement : traiter les erreurs retournées par le service.
- Désactiver ou protéger la soumission pendant son traitement afin d'éviter les envois multiples, puis offrir un état de réussite ou d'échec explicite.
- Libérer les `TextEditingController` et `FocusNode` créés par le widget.

## 6. Navigation

- Centraliser la définition des routes dans `lib/app/`. Choisir et conserver une seule stratégie de navigation adaptée au périmètre (routes nommées ou routeur déclaratif) ; ne pas les mélanger sans besoin documenté.
- Passer des objets typés aux pages plutôt que des maps non typées. Valider les arguments reçus par une route et prévoir une page ou une gestion d'erreur de route.
- Respecter la pile du `Navigator` : `push` pour avancer, `pop` pour revenir, `pushReplacement` uniquement lorsque le retour n'a plus de sens.
- Utiliser `Drawer`, `BottomNavigationBar` ou `TabBar` seulement si la structure de l'information du cahier des charges les justifie.

## 7. HTTP, JSON et données distantes

- Isoler les appels réseau dans la couche `data` derrière un service ou un repository : aucune requête HTTP directement depuis `build`, un widget ou `setState`.
- Construire les URLs avec `Uri` (`Uri.https`, `Uri.parse` validé) ; ne pas concaténer des chaînes contenant des paramètres utilisateur.
- Définir explicitement méthode HTTP, en-têtes, corps et encodage JSON avec `dart:convert`. Vérifier le code de statut avant de désérialiser la réponse.
- Prévoir timeout, absence de réseau, réponse invalide, 4xx/5xx et liste vide. Convertir ces cas en erreurs typées et messages utilisateurs non techniques.
- Ne jamais inscrire dans le dépôt une clé API, un mot de passe, un jeton ou une URL interne. Utiliser une configuration locale ignorée par Git et fournir un fichier d'exemple sans secret si le projet en a besoin.
- Ne pas journaliser de données sensibles ni afficher au client les détails bruts d'une exception réseau.

## 8. Qualité et vérification

- Écrire ou adapter des tests pour chaque comportement métier, parsing JSON, validation de formulaire, navigation et état d'erreur modifiés.
- Préférer les tests unitaires pour la logique, les widget tests pour les interactions et un test d'intégration pour les parcours critiques lorsque le périmètre le justifie.
- Avant de remettre une modification Flutter, exécuter au minimum :

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

- Signaler honnêtement les commandes non exécutées et la raison. Ne jamais prétendre qu'un test, une build ou une cible plateforme a été validé sans l'avoir exécuté.

## 9. Documentation et livraison

- Maintenir un `README.md` en français : objectif, prérequis, installation, commandes de vérification, architecture, dépendances importantes et variables de configuration non secrètes.
- Commenter le *pourquoi* (décision ou contrainte), pas ce que le code évident dit déjà. Écrire les textes UI en français, sauf exigence contraire du cahier des charges.
- Tout commit doit être ciblé et lisible, au présent impératif, par exemple `feat: ajouter l'écran de connexion` ou `fix: gérer le délai HTTP`.
- Avant tout `git push`, vérifier `git status`, les fichiers inclus et les tests applicables. Ne jamais pousser de secret, d'artefact de build, de fichier IDE propre à une machine ou de modification non liée.

## 10. Liste de contrôle pour Codex

Avant de conclure une tâche, confirmer :

- le besoin et les critères d'acceptation sont respectés ;
- le code est typé, formaté, analysé et testé selon les commandes disponibles ;
- les états chargement, vide, erreur et réussite sont traités si l'écran utilise des données asynchrones ;
- la navigation, les formulaires et les appels HTTP respectent les sections dédiées ci-dessus ;
- aucun secret, artefact ou changement involontaire ne part dans le commit.

