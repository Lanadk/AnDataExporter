# DeputedexData 🏛️

Pipeline ETL automatisé pour collecter, transformer et charger les données ouvertes de l'Assemblée nationale française.

## 📋 Prérequis

- **Node.js** 18+ et npm
- **Docker** et Docker Compose
- **Git**

## 🚀 Installation

### 1. Cloner le projet
```bash
git clone https://github.com/ton-org/deputydex-data.git
cd deputydex-data
```

### 2. Installer les dépendances
```bash
npm install
```

### 3. Configurer les variables d'environnement

Créer un fichier `.env.local` à la racine du projet :
```env
# Database connection
DB_URL=postgresql://user:mdp@localhost:5432/deputedex?schema=public

# Database configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=deputedex

# Main user (Docker init)
DB_USER=user
DB_PASSWORD=mdp

# ETL Writer user (write operations - etl backend)
DB_USER_WRITER=user_etl_writer
DB_PASSWORD_WRITER=pwd

# App Reader user (read-only operations - front web app)
DB_USER_READER=user_app_reader
DB_PASSWORD_READER=pwd
```

### 4. Premier setup

Lancer le script d'initialisation complète :
```bash
npm run first-setup
```

Ce script automatise :
1. ✅ Démarrage du container PostgreSQL (Docker Compose)
2. ✅ Génération du client Prisma dans `./generated/prisma`
3. ✅ Application des migrations de schéma
4. ✅ Population des données de référence (seed)

À la fin, votre base de données est prête avec :
- Users `writer` et `reader` configurés
- Tables créées selon le schéma Prisma
- Données de référence (etl + donnée statiques)

## 📊 Charger les données de l'Assemblée nationale

### Option 1 : Script interactif (recommandé)
```bash
./menu.sh
```

Sélectionnez **"Run Global Workflow (Download + Parser + Import + Agregat/Statistiques)"** pour :
- Télécharger les données depuis l'Assemblée nationale
- Parser les fichiers XML/JSON
- Inserer les données en base
- Générer les agrégats et les statistiques

### Option 2 : TODO

//TODO

## 🗂️ Architecture du projet
```
deputydex-data/
├── prisma/
│   ├── schema.prisma      # Schéma de la base de données
│   ├── seed.ts            # Données de référence
│   └── seed.sql           # SQL de seed
├── src/
│   ├── db/
│   │   ├── client.ts      # Client Prisma configuré
│   │   └── init-db.sql    # Script d'init users/roles
│   └── workflow/
│       ├── download/      # Téléchargement des données
│       ├── processing/    # Extraction et transformation
│       └── import/        # Chargement en base
├── generated/
│   └── prisma/           # Client Prisma généré
├── docker-compose.yml    # Configuration PostgreSQL
└── menu.sh              # Menu interactif
```

## 🛠️ Scripts disponibles

| Script | Description |
|--------|-------------|
| `npm run first-setup` | Installation complète (DB + migrations + seed) |
| `npm run docker:db` | Démarrer le container PostgreSQL |
| `npm run prisma:generate` | Générer le client Prisma |
| `npm run prisma:migrate-dev` | Créer/appliquer une migration |
| `npm run prisma:seed` | Peupler les données de référence |
| `npm run prisma:reset` | Reset complet de la DB (⚠️ destructif) |
| `./menu.sh` | Menu interactif pour les workflows |

## 🔍 Vérifier l'installation
```bash
npm run test:db
```

Affiche les statistiques de connexion et le nombre de lignes dans chaque table.

## 📚 Client Prisma

Le client Prisma est généré dans `./generated/prisma` et fournit :
- Types TypeScript auto-générés
- Méthodes CRUD type-safe
- Query builder optimisé

**Exemple d'utilisation :**
```typescript
import { prisma } from './src/db/client';

// Récupérer tous les députés
const deputes = await prisma.deputes.findMany();

// Compter les scrutins
const count = await prisma.scrutins.count();
```

## 🐳 Gestion du container Docker
```bash
# Démarrer
docker compose up -d

# Arrêter
docker compose down

# Voir les logs
docker compose logs -f

# Reset complet (⚠️ supprime les données)
docker compose down -v
```

## 🔧 Travailler avec Prisma

### Workflow général

Prisma est utilisé à deux endroits dans l'écosystème Deputedex :
- **Backend ETL** (ce repo) : Gère le schéma, les migrations et les imports
- **Frontend** (deputedex) : Utilise le client Prisma généré en lecture seule

### Sur le Backend ETL (ce repo)

#### Modifier le schéma

1. **Éditer** `prisma/schema.prisma`
```prisma
model Acteurs {
  uid     String @id @db.VarChar(50)
  prenom  String? @db.VarChar(100)
  nom     String? @db.VarChar(255)
  // Ajouter un nouveau champ
  age     Int?
}
```

2. **Créer la migration**
```bash
npm run prisma:migrate-dev
# Prisma va demander un nom pour la migration, ex: "add_age_to_acteurs"
```

Cette commande :
- ✅ Génère le fichier SQL de migration dans `prisma/migrations/`
- ✅ Applique la migration sur ta base locale
- ✅ Régénère le client Prisma automatiquement (pas besoin de prisma generate)

3. **Vérifier la migration**
```bash
# La migration est dans prisma/migrations/YYYYMMDDHHMMSS_add_age_to_acteurs/
cat prisma/migrations/*/migration.sql
```

#### Régénérer le client pour être à jours par rapport au schema

```bash
npm run prisma:generate
```

#### Synchroniser avec le Frontend

**⚠️ Important :** Après chaque modification du schéma :

1. **Copier le schema.prisma vers le frontend**
```bash
# Depuis le repo ETL
prisma/schema.prisma ../deputydex/prisma/schema.prisma
```

2. **Dans le repo frontend, regénérer le client**
```bash
# Depuis le repo frontend
npm run prisma:generate
```

> 💡 **Note :** Ce process manuel sera automatisé via GitHub Actions dans une future version.

### Sur le Frontend (repo séparé)

Le frontend utilise Prisma **uniquement pour la génération du client**, pas pour les migrations.

#### Setup initial
```bash
# Dans le repo frontend
npm install
npm run prisma:generate
```

#### Après un changement de schéma (venant du backend)
```bash
# 1. Pull le nouveau schema.prisma depuis le backend
cp pull_command

# 2. Regénérer le client
npm run prisma:generate
```

**⚠️ Ne jamais exécuter `prisma migrate` depuis le frontend !** Les migrations sont gérées uniquement par le backend ETL.

### Commandes Prisma disponibles

| Commande | Usage | Backend ETL | Frontend |
|----------|-------|-------------|----------|
| `prisma:generate` | Générer le client Prisma | ✅ Après modif schéma | ✅ Après sync schéma |
| `prisma:migrate-dev` | Créer/appliquer migration | ✅ Uniquement | ❌ Jamais |
| `prisma:migrate-prod` | Appliquer en production | ✅ Via CI/CD | ❌ Jamais |
| `prisma:seed` | Peupler données de référence | ✅ Si besoin | ❌ Jamais |
| `prisma:reset` | Reset complet DB | ⚠️ Dev seulement | ❌ Jamais |
| `prisma:pull` | Introspect DB existante | 🔧 Rare | ❌ Jamais |

### Reset complet en développement

⚠️ **Attention : Supprime toutes les données !**
```bash
npm run prisma:reset
# Confirmer avec "y"
# Cela va : Drop toutes les tables
```