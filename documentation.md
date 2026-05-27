# Documentation technique - Retronova App

Ce document explique comment l'application est organisee et comment un developpeur peut la faire evoluer sans devoir tout deduire depuis les ecrans.

## Objectif du produit

Retronova est une application mobile Flutter centree sur les bornes d'arcade retro :

- trouver une borne et les jeux disponibles;
- reserver une partie avec un cout en tickets;
- afficher un code de deverrouillage pour la borne;
- consulter les scores et statistiques;
- acheter des tickets avec Stripe Checkout;
- utiliser des codes promo;
- ajouter des amis et jouer en multijoueur.

## Architecture globale

L'app suit une architecture Flutter simple :

```text
UI screens/widgets
        |
        v
Providers ChangeNotifier
        |
        v
Services / Repositories
        |
        v
API REST + Firebase Auth + Stripe
```

Les widgets lisent l'etat depuis les providers. Les providers appellent les services ou repositories. Les services transforment les reponses JSON en modeles Dart.

## Demarrage applicatif

- `lib/main.dart`
  - initialise Flutter;
  - initialise Firebase avec `Firebase.initializeApp()`;
  - installe les providers dans un `MultiProvider`.

- `lib/app.dart`
  - configure `MaterialApp`;
  - applique le theme;
  - active les localisations `fr_FR` et `en_US`;
  - affiche `AuthWrapper` en page racine.

- `lib/presentation/widgets/auth_wrapper.dart`
  - verifie l'etat Firebase;
  - affiche `LoginScreen` si l'utilisateur n'est pas connecte;
  - affiche `MainNavigation` si l'utilisateur est connecte;
  - charge le solde de tickets apres connexion.

## Navigation

La navigation principale est dans `lib/presentation/widgets/main_navigation.dart`.

Onglets actuels :

1. `ArcadeScreen`
2. `ScoreScreen`
3. `StoreScreen`
4. `FriendsScreen`
5. `ProfileScreen`

L'onglet actif est conserve dans un `IndexedStack`, donc les ecrans restent montes quand on change d'onglet.

## Providers

### AuthProvider

Fichier : `lib/providers/auth_provider.dart`

Responsabilites :

- inscription Firebase;
- connexion/deconnexion;
- reinitialisation du mot de passe;
- synchronisation du profil avec l'API via `ApiService`;
- etats `isLoading`, `isAuthenticated`, `error`.

### ArcadeProvider

Fichier : `lib/providers/arcade_provider.dart`

Responsabilites :

- charger les bornes;
- charger les jeux;
- rechercher/filtrer les bornes;
- creer et annuler des reservations;
- charger les reservations de l'utilisateur.

Service associe : `ArcadeService`.

### ScoreProvider

Fichier : `lib/providers/score_provider.dart`

Responsabilites :

- charger les scores;
- appliquer les filtres `gameId`, `arcadeId`, amis seulement, solo seulement;
- charger les statistiques personnelles;
- exposer des helpers de tri/affichage.

Service associe : `ScoreService`.

### TicketProvider

Fichier : `lib/providers/ticket_provider.dart`

Responsabilites :

- charger les offres de tickets;
- charger le solde;
- demarrer une session Stripe Checkout;
- suivre le statut d'une transaction active;
- charger l'historique d'achats;
- utiliser un code promo;
- charger l'historique des codes promo.

Services associes :

- `TicketService` pour l'historique, les promos et certains appels historiques;
- `PaymentRepository` pour le flux Stripe Checkout recent.

### FriendProvider

Fichier : `lib/providers/friend_provider.dart`

Responsabilites :

- charger la liste d'amis;
- charger les demandes recues;
- rechercher des utilisateurs;
- envoyer, accepter, rejeter une demande;
- supprimer un ami.

Service associe : `FriendService`.

## Services et repositories

### Services historiques avec `http`

Ces classes appellent directement `package:http/http.dart` :

- `ApiService`
- `ArcadeService`
- `FriendService`
- `ScoreService`
- `TicketService`

Elles recuperent le token Firebase via :

```dart
FirebaseAuth.instance.currentUser?.getIdToken()
```

Puis elles envoient :

```text
Authorization: Bearer <token>
Content-Type: application/json
Accept: application/json
```

### Repository paiement avec `Dio`

`PaymentRepository` utilise `AppDioClient`.

`AppDioClient` ajoute automatiquement les headers JSON et ajoute le token Firebase quand l'option `authRequired` vaut `true`.

Cette couche gere mieux les erreurs reseau via `ApiException`, `UnauthorizedException` et `NetworkException`.

## Modeles principaux

- `UserModel` : profil utilisateur.
- `ArcadeModel` : borne et liste des jeux installes.
- `GameModel` / `GameOnArcadeModel` : jeu et position sur une borne.
- `ReservationModel` : reservation, code, statut et file d'attente.
- `ScoreModel` / `PlayerStatsModel` : score et statistiques.
- `TicketOfferModel` : offre de tickets.
- `TicketPurchaseModel` : achat historique.
- `TicketPurchaseCheckoutModel` : session Stripe Checkout.
- `TicketPurchaseStatusModel` : statut d'achat.
- `PromoCodeUseResponse` / `PromoCodeHistoryItem` : codes promo.
- `FriendModel` / `FriendshipModel` / `UserSearchResult` : social.

Les champs JSON exacts attendus sont documentes dans [docs/api-contract.md](docs/api-contract.md).

## Configuration

### API

Fichier : `lib/core/config/api_config.dart`.

La valeur actuelle :

```dart
static const String baseUrl = 'http://10.31.33.20:8000/api/v1';
```

Cette URL doit etre adaptee selon l'environnement :

- emulateur Android vers backend local : souvent `http://10.0.2.2:<port>/api/v1`;
- telephone physique : IP locale de la machine backend;
- production : URL HTTPS publique.

### Firebase

Fichiers attendus :

- Android : `android/app/google-services.json`
- iOS : `ios/Runner/GoogleService-Info.plist`

Firebase Auth doit activer la connexion email/mot de passe.

### Stripe

Deep links :

```text
retronova://checkout/success
retronova://checkout/cancel
```

Configuration mobile :

- Android : intent filter dans `AndroidManifest.xml`;
- iOS : `CFBundleURLTypes` dans `Info.plist`.

Le backend reste responsable de Stripe : creation de session Checkout, webhooks, validation du paiement et mise a jour du solde.

## Flux metier

### Inscription

1. L'utilisateur remplit le formulaire.
2. `AuthProvider` cree le compte Firebase.
3. L'app recupere le token Firebase.
4. `ApiService.registerUser` envoie le profil au backend.
5. L'utilisateur est connecte et l'app affiche la navigation principale.

### Connexion

1. `AuthProvider.signIn` connecte l'utilisateur via Firebase.
2. `AuthWrapper` detecte l'utilisateur authentifie.
3. `MainNavigation` est affiche.
4. `TicketProvider.loadBalance` charge le solde.

### Reservation

1. `ArcadeProvider` charge les bornes et les jeux.
2. L'utilisateur choisit une borne et un jeu.
3. `ArcadeService.createReservation` envoie `arcade_id`, `game_id` et eventuellement `player2_id`.
4. Le backend retourne une reservation avec `unlock_code`, `status`, `tickets_used`, `position_in_queue`.
5. L'app affiche la reservation et permet l'annulation si le statut est `waiting`.

### Paiement Stripe

1. `TicketProvider.startCheckoutPurchase` appelle `PaymentRepository.createPurchaseSession`.
2. Le backend retourne `transaction_id`, `stripe_session_id`, `checkout_url`.
3. `StoreScreen` ouvre `checkout_url` avec `url_launcher`.
4. Stripe redirige vers `retronova://checkout/success` ou `retronova://checkout/cancel`.
5. L'app interroge `/tickets/purchase/{id}/status`.
6. Si le statut est final, le solde est recharge.

### Social

1. Recherche via `/users/search?q=...`.
2. Demande via `/friends/request`.
3. Acceptation ou rejet via `/friends/request/{id}/accept` ou `/reject`.
4. Liste des amis via `/friends/`.

## Qualite et tests

Commandes a executer avant modification importante :

```bash
flutter analyze
flutter test
```

Etat actuel :

- pas de tests unitaires de modeles;
- pas de tests providers;
- pas de tests integration;
- test widget minimal uniquement.

Priorites de tests :

1. `fromJson` des modeles critiques.
2. `TicketProvider` et flux Checkout.
3. `ArcadeProvider` et creation/annulation de reservation.
4. `AuthProvider` avec service mocke.

## Regles de modification

- Garder la logique reseau hors des widgets.
- Mettre la logique d'etat dans les providers.
- Creer ou mettre a jour un modele quand un JSON backend change.
- Documenter chaque nouvel endpoint dans `docs/api-contract.md`.
- Preferer une migration progressive vers `AppDioClient` si les anciens services sont refactorises.
- Supprimer ou remplacer les `print` de debug avant une release.

