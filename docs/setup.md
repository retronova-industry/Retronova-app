# Setup developpeur

Ce guide permet de reprendre le projet Retronova sur une nouvelle machine.

## Prerequis

- Flutter SDK compatible avec Dart `^3.8.1`.
- Android Studio ou VS Code avec extensions Flutter/Dart.
- Un emulateur Android, un simulateur iOS ou un telephone physique.
- Acces au projet Firebase utilise par l'app.
- Acces a un backend compatible avec les contrats de [api-contract.md](api-contract.md).
- Pour iOS : Xcode et CocoaPods.

## Installation

```bash
git clone <url-du-repository>
cd retronova_app_def
flutter doctor
flutter pub get
```

Si vous travaillez sur iOS :

```bash
cd ios
pod install
cd ..
```

## Configuration Firebase

L'app appelle `Firebase.initializeApp()` dans `lib/main.dart`, donc les fichiers natifs doivent etre presents.

Android :

```text
android/app/google-services.json
```

iOS :

```text
ios/Runner/GoogleService-Info.plist
```

Dans Firebase Console :

- activer Authentication;
- activer le provider Email/Password;
- verifier que les noms de package/bundle correspondent aux fichiers natifs;
- donner au backend la possibilite de verifier les tokens Firebase.

## Configuration API

Fichier a modifier :

```text
lib/core/config/api_config.dart
```

Valeur actuelle :

```dart
static const String baseUrl = 'http://10.31.33.20:8000/api/v1';
```

Cette IP est specifique a un reseau local. Pour une reprise :

- backend sur la meme machine et emulateur Android : `http://10.0.2.2:8000/api/v1`;
- backend sur la meme machine et app desktop/web : `http://localhost:8000/api/v1`;
- telephone physique : `http://<ip-locale-machine>:8000/api/v1`;
- environnement distant : utiliser une URL HTTPS.

Apres changement, relancer l'app :

```bash
flutter run
```

## Configuration Stripe

Le paiement est gere par Stripe Checkout, ouvert dans le navigateur ou l'app Stripe via `url_launcher`.

L'app attend ces URLs de retour :

```text
retronova://checkout/success
retronova://checkout/cancel
```

Android est configure dans :

```text
android/app/src/main/AndroidManifest.xml
```

iOS est configure dans :

```text
ios/Runner/Info.plist
```

Le backend doit :

- exposer `/payments/config`;
- creer une session via `/tickets/purchase`;
- fournir une `checkout_url` Stripe;
- recevoir les webhooks Stripe;
- mettre a jour le statut de transaction;
- exposer `/tickets/purchase/{transaction_id}/status`.

## Lancement

Android ou iOS :

```bash
flutter run
```

Choisir un device :

```bash
flutter devices
flutter run -d <device-id>
```

Mode release :

```bash
flutter run --release
```

## Verifications avant de coder

```bash
flutter analyze
flutter test
```

Si `flutter analyze` echoue sur un poste frais :

1. verifier la version Flutter;
2. relancer `flutter pub get`;
3. supprimer uniquement les caches generes si necessaire (`.dart_tool`, `build`) puis relancer `flutter pub get`.

## Builds

Android APK :

```bash
flutter build apk --release
```

Android App Bundle :

```bash
flutter build appbundle --release
```

iOS :

```bash
flutter build ios --release
```

## Problemes frequents

### L'app reste sur connexion ou affiche une erreur Firebase

- verifier les fichiers Firebase natifs;
- verifier que Email/Password est active;
- verifier que le package Android ou bundle iOS correspond au projet Firebase.

### Les listes bornes/scores/tickets ne chargent pas

- verifier `ApiConfig.baseUrl`;
- depuis un telephone physique, utiliser l'IP locale de la machine backend;
- verifier que le backend ecoute sur le bon port;
- verifier les logs backend;
- verifier que les endpoints correspondent a [api-contract.md](api-contract.md).

### Erreur 401

- l'utilisateur doit etre connecte;
- le backend doit verifier correctement le token Firebase;
- l'app envoie le token en header `Authorization: Bearer <token>`.

### Stripe ne revient pas dans l'app

- verifier les URLs de retour configurees cote backend Stripe;
- verifier le scheme `retronova`;
- verifier les declarations Android/iOS;
- tester manuellement l'ouverture de `retronova://checkout/success` sur le device.

