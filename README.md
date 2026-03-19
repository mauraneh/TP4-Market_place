# TP4 - Market Place

Dans ce TP, j'ai realise une petite marketplace en Swift.

J'ai separe le projet en deux parties :

- un serveur API en Vapor
- un client CLI en Swift Package Manager

Le but est de pouvoir creer des utilisateurs, publier des annonces, les consulter et les supprimer depuis le terminal.

## Structure

- `swiftmarket-server` : serveur Vapor avec SQLite
- `swiftmarket-client` : client CLI avec `swift-argument-parser`

## Lancement

### Demarrer le serveur

```bash
cd swiftmarket-server
swift build
swift run
```

Le serveur tourne ensuite sur `http://localhost:8080`.

### Lancer le client

Dans un autre terminal :

```bash
cd swiftmarket-client
swift build
swift run SwiftMarketClient users
```

## Exemples

Creer des utilisateurs :

```bash
swift run SwiftMarketClient create-user --username maurane --email maurane@mail.com
swift run SwiftMarketClient create-user --username melina --email melina@mail.com
```

Lister les utilisateurs :

```bash
swift run SwiftMarketClient users
```

Afficher un utilisateur :

```bash
swift run SwiftMarketClient user <USER_ID>
```

Poster une annonce :

```bash
swift run SwiftMarketClient post \
  --title "MacBook Air M1" \
  --desc "Tres bon etat" \
  --price 750 \
  --category electronics \
  --seller <USER_ID>
```

Lister les annonces :

```bash
swift run SwiftMarketClient listings
swift run SwiftMarketClient listings --category electronics
swift run SwiftMarketClient listings --query "mac"
```

Afficher une annonce :

```bash
swift run SwiftMarketClient listing <LISTING_ID>
```

Afficher les annonces d'un utilisateur :

```bash
swift run SwiftMarketClient user-listings <USER_ID>
```

Supprimer une annonce :

```bash
swift run SwiftMarketClient delete <LISTING_ID>
```

## Remarques

- la base `db.sqlite` est creee automatiquement au lancement du serveur
- pour repartir de zero, il suffit de supprimer `db.sqlite` puis de relancer le serveur
- les validations sont gerees cote serveur avec Vapor
