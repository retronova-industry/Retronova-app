# Retronova App

Retronova est une application mobile Flutter pour decouvrir des bornes d'arcade, reserver une partie, utiliser des tickets virtuels, consulter des scores et gerer une liste d'amis.

Derniere mise a jour de la documentation : 2026-05-27.

## Lecture rapide

- Guide d'installation complet : [docs/setup.md](docs/setup.md)
- Contrats API attendus par l'app : [docs/api-contract.md](docs/api-contract.md)
- Etat actuel, limites et priorites : [docs/current-state.md](docs/current-state.md)
- Documentation technique : [documentation.md](documentation.md)

## Fonctionnalites

- Authentification Firebase email / mot de passe.
- Creation et mise a jour du profil utilisateur.
- Liste des bornes d'arcade et des jeux disponibles.
- Reservation de parties solo ou multijoueur.
- Gestion du statut de reservation et code de deverrouillage.
- Scores, classement et statistiques personnelles.
- Boutique de tickets, solde, historique d'achats et codes promo.
- Paiement via Stripe Checkout en redirection externe.
- Recherche d'utilisateurs, demandes d'ami et liste d'amis.

## Stack technique

- Flutter avec Dart SDK `^3.8.1`.
- Firebase Core et Firebase Auth.
- Provider pour la gestion d'etat.
- API REST externe avec token Firebase dans le header `Authorization`.
- Clients HTTP : `http` pour les services historiques, `dio` pour la couche paiement.
- `url_launcher` pour ouvrir Stripe Checkout.
- Material Design avec localisation `fr_FR`.

## Structure du projet

```text
lib/
  app.dart                         # MaterialApp, theme, localisation
  main.dart                        # Firebase init + MultiProvider
  core/
    config/api_config.dart         # Base URL API + URLs retour Stripe
    constants/                     # Couleurs, icones, textes
    network/                       # Client Dio et exceptions API
    theme/                         # Theme Flutter
  models/                          # Modeles JSON utilises par les services
  providers/                       # Etat applicatif via ChangeNotifier
  repositories/                    # Acces API recent, notamment paiement
  services/                        # Services API historiques avec package http
  presentation/
    screens/                       # Ecrans par domaine
    widgets/                       # Widgets partages
test/
  widget_test.dart                 # Test de fumee minimal
```

## Installation courte

Pour le detail, voir [docs/setup.md](docs/setup.md).

```bash
flutter doctor
flutter pub get
flutter run
```

Avant de lancer l'app, verifier :

- `android/app/google-services.json` est present pour Android.
- `ios/Runner/GoogleService-Info.plist` est present pour iOS.
- `lib/core/config/api_config.dart` pointe vers une API accessible depuis l'emulateur ou le telephone.
- Le backend accepte les tokens Firebase du projet configure.

## Configuration API

La base URL actuelle est definie ici :

```dart
// lib/core/config/api_config.dart
static const String baseUrl = 'http://10.31.33.20:8000/api/v1';
```

Cette IP est une configuration locale/reseau. Pour reprendre le projet, remplacer cette valeur par l'URL du backend disponible dans votre environnement. Les endpoints attendus sont listes dans [docs/api-contract.md](docs/api-contract.md).

## Configuration Stripe Checkout

Le paiement utilise Stripe Checkout avec redirection externe.

URLs de retour attendues par l'app :

```text
retronova://checkout/success
retronova://checkout/cancel
```

Le deep link est configure cote mobile :

- Android : `android/app/src/main/AndroidManifest.xml`
- iOS : `ios/Runner/Info.plist`

Le backend doit creer la session Stripe, recevoir les webhooks Stripe et exposer le statut de la transaction a l'app.

## Commandes utiles

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

## Tests

Etat actuel : les tests sont tres limites. `test/widget_test.dart` verifie seulement qu'un widget de test s'affiche. Avant une reprise serieuse, ajouter au minimum :

- tests unitaires des modeles `fromJson`;
- tests des providers avec services mockes;
- tests du flux authentification/profil;
- tests du flux reservation;
- tests du flux paiement et polling de statut.

La commande `flutter drive --target=test_driver/app.dart` n'est pas documentee comme commande standard du projet, car le dossier `test_driver` n'existe pas actuellement.

## Points d'attention pour un nouveau dev

- L'app depend fortement du backend : sans API compatible, plusieurs ecrans chargeront en erreur.
- Les services `ApiService`, `ArcadeService`, `FriendService`, `ScoreService` et `TicketService` utilisent `http`.
- `PaymentRepository` utilise `Dio` via `AppDioClient`.
- Il y a encore des `print` de debug dans plusieurs providers/services.
- Certains chemins iOS generes contiennent des traces d'un ancien poste de developpement ; ils ne doivent pas etre consideres comme de la configuration fonctionnelle.
- Les identifiants package/bundle doivent etre verifies avant publication.

## Contribution

Avant une PR ou une reprise de fonctionnalite :

```bash
flutter pub get
flutter analyze
flutter test
```

Recommandations :

- garder le decoupage existant `model -> service/repository -> provider -> screen`;
- documenter tout nouvel endpoint dans [docs/api-contract.md](docs/api-contract.md);
- eviter d'ajouter de la logique metier lourde dans les widgets;
- ajouter un test quand une transformation JSON, un provider ou un flux critique change.

