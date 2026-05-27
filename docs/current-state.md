# Etat actuel du projet

Date : 2026-05-27.

Ce document resume ce qui semble etre l'etat reel du projet d'apres le code present dans le repository.

## Ce qui est implemente cote app

- Demarrage Flutter avec Firebase.
- Authentification email/mot de passe via Firebase Auth.
- Synchronisation profil utilisateur avec une API REST.
- Navigation principale a 5 onglets.
- Consultation des bornes et jeux.
- Creation, listing, rafraichissement et annulation de reservations.
- Consultation des scores avec filtres.
- Statistiques personnelles.
- Boutique de tickets.
- Paiement Stripe Checkout par redirection externe.
- Polling du statut de transaction apres checkout.
- Historique d'achats.
- Utilisation et historique des codes promo.
- Recherche d'utilisateurs.
- Demandes d'ami et liste d'amis.
- Localisation Flutter configuree en `fr_FR`.

## Dependances externes indispensables

L'app n'est pas autonome. Pour fonctionner completement, elle a besoin de :

- Firebase Auth configure;
- fichiers Firebase natifs Android/iOS;
- backend REST compatible;
- Stripe configure cote backend;
- webhooks Stripe cote backend;
- reseau permettant a l'app mobile d'atteindre l'API.

## Configuration actuelle notable

### API

`lib/core/config/api_config.dart` contient :

```dart
static const String baseUrl = 'http://10.31.33.20:8000/api/v1';
```

Cette URL est une IP locale. Elle risque de ne pas fonctionner sur une autre machine ou un autre reseau.

### Firebase

Des fichiers Firebase sont presents dans le repository :

- `android/app/google-services.json`
- `ios/GoogleService-Info.plist`
- `ios/Runner/GoogleService-Info.plist`

Avant publication ou partage externe, verifier si ces fichiers doivent rester versionnes ou etre remplaces par une configuration d'environnement.

### Identifiants natifs

Android utilise encore :

```text
com.example.retronova_app
```

iOS utilise notamment :

```text
com.retronovaIndustry.retronovaApp
```

Verifier et harmoniser ces identifiants avant une release.

## Dette technique visible

- Deux couches HTTP coexistent :
  - `http` dans les services historiques;
  - `Dio` dans `AppDioClient` pour le paiement.
- Plusieurs `print` de debug sont encore dans les services/providers.
- Certains commentaires indiquent des changements temporaires (`AJOUTE`, `CHANGE`, `CORRECTION ICI`).
- La base URL API est hardcodee.
- Les tests automatises sont quasi absents.
- Les erreurs sont parfois mappees proprement avec `ApiException`, parfois encapsulees dans des `Exception` generiques.
- Les contrats API ne sont pas valides par tests.
- La distance des bornes est calculee par rapport a Toulouse en dur dans `ArcadeModel`.

## Tests actuels

Fichier :

```text
test/widget_test.dart
```

Ce test monte un widget `Text('Test')`. Il ne teste pas l'application reelle, Firebase, les providers, les services ou les modeles.

Commandes utiles :

```bash
flutter analyze
flutter test
```

## Priorites conseillees

1. Rendre la configuration API propre par environnement.
2. Ajouter des tests unitaires sur tous les modeles `fromJson`.
3. Ajouter des tests providers pour auth, reservation et paiement.
4. Migrer progressivement les services historiques vers `AppDioClient`.
5. Supprimer les `print` ou les remplacer par un logger controle.
6. Documenter le backend associe dans le meme niveau de detail que l'app.
7. Harmoniser les package IDs Android/iOS.
8. Clarifier la gestion des secrets Firebase/Stripe.

## Definition of Done proposee pour une nouvelle feature

Une feature peut etre consideree comme reprise proprement si :

- le comportement est branche a un provider ou repository existant;
- aucun appel reseau direct n'est ajoute dans un widget;
- le modele JSON est documente dans `docs/api-contract.md`;
- `flutter analyze` passe;
- `flutter test` passe;
- au moins un test couvre la logique ajoutee quand elle touche un modele, un provider ou un flux critique;
- la doc est mise a jour si une commande, une config ou un endpoint change.

## Roadmap fonctionnelle possible

- Notifications push pour reservations.
- Mode sombre complet.
- Mode hors ligne partiel pour profil et historique.
- Badges/achievements.
- Tournois.
- Partage de scores.
- Support multilingue au-dela de `fr_FR`.

## Roadmap technique possible

- Centraliser le client API sur `Dio`.
- Ajouter des environnements `dev`, `staging`, `prod`.
- Ajouter CI avec `flutter analyze` et `flutter test`.
- Ajouter tests unitaires et integration tests.
- Ajouter monitoring crash/performance.
- Ajouter une strategie de cache.
- Renforcer les erreurs utilisateur et les retries reseau.

