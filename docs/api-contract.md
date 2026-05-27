# Contrats API attendus par l'application

Base URL definie dans `lib/core/config/api_config.dart` :

```text
http://10.31.33.20:8000/api/v1
```

Toutes les routes ci-dessous sont relatives a cette base URL.

## Authentification

Les endpoints publics ne demandent pas de token. Les endpoints prives demandent :

```text
Authorization: Bearer <firebase_id_token>
Content-Type: application/json
Accept: application/json
```

Le token est recupere cote mobile avec :

```dart
FirebaseAuth.instance.currentUser?.getIdToken()
```

Format d'erreur attendu quand possible :

```json
{
  "detail": "Message lisible par l'utilisateur ou le developpeur"
}
```

## Auth et profil

### POST `/auth/register`

Auth : oui.

Body envoye par l'app :

```json
{
  "firebase_uid": "firebase-user-id",
  "email": "user@example.com",
  "nom": "Dupont",
  "prenom": "Alice",
  "pseudo": "alice",
  "date_naissance": "2000-01-31",
  "numero_telephone": "0600000000"
}
```

Reponse attendue `200` :

```json
{
  "id": 1,
  "firebase_uid": "firebase-user-id",
  "email": "user@example.com",
  "nom": "Dupont",
  "prenom": "Alice",
  "pseudo": "alice",
  "date_naissance": "2000-01-31",
  "numero_telephone": "0600000000",
  "tickets_balance": 0,
  "created_at": "2026-05-27T10:00:00Z",
  "updated_at": "2026-05-27T10:00:00Z"
}
```

### GET `/auth/me`

Auth : oui.

Reponse : meme forme que `UserModel`.

### PUT `/users/me`

Auth : oui.

Body envoye :

```json
{
  "email": "user@example.com",
  "nom": "Dupont",
  "prenom": "Alice",
  "pseudo": "alice",
  "date_naissance": "2000-01-31",
  "numero_telephone": "0600000000"
}
```

Reponse : meme forme que `UserModel`.

## Bornes et jeux

### GET `/arcades/`

Auth : non.

Reponse attendue `200` :

```json
[
  {
    "id": 1,
    "nom": "Retronova Toulouse",
    "description": "Borne principale",
    "localisation": "Toulouse",
    "latitude": 43.6047,
    "longitude": 1.4442,
    "games": [
      {
        "id": 10,
        "nom": "Pac-Man",
        "description": "Arcade classic",
        "min_players": 1,
        "max_players": 1,
        "ticket_cost": 2,
        "slot_number": 1
      }
    ]
  }
]
```

### GET `/arcades/{arcade_id}`

Auth : non.

Reponse : un objet arcade identique a l'item de `/arcades/`.

### GET `/games/`

Auth : non.

Reponse attendue `200` :

```json
[
  {
    "id": 10,
    "nom": "Pac-Man",
    "description": "Arcade classic",
    "min_players": 1,
    "max_players": 1,
    "ticket_cost": 2
  }
]
```

## Reservations

Statuts reconnus par l'app :

```text
waiting
playing
completed
cancelled
```

### POST `/reservations/`

Auth : oui.

Body solo :

```json
{
  "arcade_id": 1,
  "game_id": 10
}
```

Body multijoueur :

```json
{
  "arcade_id": 1,
  "game_id": 10,
  "player2_id": 2
}
```

Reponse attendue `200` :

```json
{
  "id": 100,
  "unlock_code": "ABCD12",
  "status": "waiting",
  "arcade_name": "Retronova Toulouse",
  "game_name": "Pac-Man",
  "player_pseudo": "alice",
  "player2_pseudo": null,
  "tickets_used": 2,
  "position_in_queue": 1,
  "created_at": "2026-05-27T10:00:00Z"
}
```

### GET `/reservations/`

Auth : oui.

Reponse : liste de reservations.

### GET `/reservations/{reservation_id}`

Auth : oui.

Reponse : une reservation.

### DELETE `/reservations/{reservation_id}`

Auth : oui.

Reponse attendue : `200`.

## Scores

### GET `/scores/`

Auth : oui.

Query parameters utilises par l'app :

- `limit`, par defaut `50`;
- `game_id`;
- `arcade_id`;
- `friends_only=true`;
- `single_player_only=true`.

Exemple :

```text
/scores/?limit=50&game_id=10&friends_only=true
```

Reponse attendue :

```json
[
  {
    "id": 1,
    "player1_pseudo": "alice",
    "player2_pseudo": null,
    "game_name": "Pac-Man",
    "arcade_name": "Retronova Toulouse",
    "score_j1": 12000,
    "score_j2": null,
    "winner_pseudo": null,
    "is_single_player": true,
    "created_at": "2026-05-27T10:00:00Z"
  }
]
```

### GET `/scores/my-stats`

Auth : oui.

Reponse attendue :

```json
{
  "total_games": 12,
  "solo_games": 8,
  "multiplayer_games": 4,
  "wins": 3,
  "losses": 1,
  "draws": 0,
  "win_rate": 75.0
}
```

## Tickets et paiement

### GET `/payments/config`

Auth : non.

Reponse attendue :

```json
{
  "publishable_key": "pk_test_xxx",
  "currency": "eur",
  "checkout_mode": "redirect"
}
```

L'app reconnait `checkout_mode = redirect`. Toute autre valeur est consideree comme inconnue.

### GET `/tickets/offers`

Auth : non, puis retry possible avec auth dans `PaymentRepository`.

L'app accepte soit une liste directe :

```json
[
  {
    "id": 1,
    "tickets_amount": 10,
    "price_euros": 15.0,
    "name": "Pack 10 tickets"
  }
]
```

Soit une enveloppe contenant `offers`, `items` ou `data`.

### POST `/tickets/purchase`

Auth : oui.

Body :

```json
{
  "offer_id": 1
}
```

Reponse attendue pour le flux Checkout :

```json
{
  "transaction_id": 123,
  "stripe_session_id": "cs_test_xxx",
  "checkout_url": "https://checkout.stripe.com/c/pay/cs_test_xxx"
}
```

Compatibilite acceptee par le modele :

- `purchase_id` peut remplacer `transaction_id`;
- `checkout_session_id` peut remplacer `stripe_session_id`.

### GET `/tickets/purchase/{transaction_id}/status`

Auth : oui.

Reponse attendue :

```json
{
  "transaction_id": 123,
  "status": "succeeded",
  "current_balance": 42,
  "tickets_received": 10,
  "amount_paid": 15.0
}
```

Statuts reconnus :

- en attente : `pending`;
- succes : `paid`, `succeeded`, `completed`;
- echec : `expired`, `canceled`, `cancelled`, `failed`;
- autre : `unknown`.

### GET `/tickets/balance`

Auth : oui.

Reponse attendue :

```json
{
  "balance": 42
}
```

### GET `/tickets/history`

Auth : oui.

Reponse attendue :

```json
[
  {
    "id": 1,
    "tickets_received": 10,
    "amount_paid": 15.0,
    "created_at": "2026-05-27T10:00:00Z",
    "stripe_payment_id": "pi_xxx"
  }
]
```

## Codes promo

### POST `/promos/use`

Auth : oui.

Body :

```json
{
  "code": "WELCOME10"
}
```

Reponse attendue :

```json
{
  "tickets_received": 10,
  "new_balance": 52,
  "message": "Code promo utilise"
}
```

### GET `/promos/history`

Auth : oui.

Reponse attendue :

```json
[
  {
    "id": 1,
    "code": "WELCOME10",
    "tickets_received": 10,
    "used_at": "2026-05-27T10:00:00Z"
  }
]
```

## Amis

### GET `/friends/`

Auth : oui.

Reponse attendue :

```json
[
  {
    "id": 2,
    "pseudo": "bob",
    "nom": "Martin",
    "prenom": "Bob"
  }
]
```

### GET `/friends/requests`

Auth : oui.

Reponse attendue :

```json
[
  {
    "id": 50,
    "status": "pending",
    "requester": {
      "id": 2,
      "pseudo": "bob",
      "nom": "Martin",
      "prenom": "Bob"
    },
    "requested": {
      "id": 1,
      "pseudo": "alice",
      "nom": "Dupont",
      "prenom": "Alice"
    }
  }
]
```

Statuts reconnus :

```text
pending
accepted
rejected
```

### GET `/users/search?q=<query>`

Auth : oui.

Reponse attendue :

```json
[
  {
    "id": 2,
    "pseudo": "bob",
    "nom": "Martin",
    "prenom": "Bob"
  }
]
```

### POST `/friends/request`

Auth : oui.

Body :

```json
{
  "user_id": 2
}
```

Reponse attendue : `200`.

### PUT `/friends/request/{friendship_id}/accept`

Auth : oui.

Reponse attendue : `200`.

### PUT `/friends/request/{friendship_id}/reject`

Auth : oui.

Reponse attendue : `200`.

### DELETE `/friends/{user_id}`

Auth : oui.

Reponse attendue : `200`.

