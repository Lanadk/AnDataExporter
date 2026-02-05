# Import JSON vers PostgreSQL avec Split Automatique

## Architecture

```
src/scripts/db/
├── paths.sh                  # Configuration (DB_CONTAINER, DB_USER, etc.)
├── json-splitter.ts          # Découpe les gros JSON en parts de 150MB
├── json-import-utils.sh      # Fonctions réutilisables d'import
└── import-toto.sh            # Script d'import
```

## Fonctionnement

### 1. Split automatique

Les fichiers > 150MB sont automatiquement découpés :
```
votesDeputes.json (308MB)
    ↓ split
part000.json (150MB) + part001.json (158MB)
```

### 2. Import incrémental

Chaque part est traitée séparément :
```
Part 0 → raw table (json en une ligne) → projection SQL → TRUNCATE raw
Part 1 → raw table → projection SQL → TRUNCATE raw
```

Les petits fichiers (< 150MB) passent directement sans se faire split

### 3. Projection via callback

Chaque table définit sa fonction de projection :

```bash
project_votes_deputes() {
    docker exec psql ... "INSERT INTO votes_deputes SELECT ... FROM $1"
}

import_json_to_raw_table "votesDeputes.json" "votes_deputes_raw" "project_votes_deputes"
```

Le callback est appelé après chaque import (1 fois pour petits fichiers, N fois pour gros).

## Utilisation

### Import complet

```bash
./import-votes.sh
./import-acteurs.sh
```

### Avec nettoyage auto des tables raw

```bash
./import-votes.sh --auto-cleanup
```

## Compatibilité Windows

Les chemins dans `docker exec` utilisent `//` pour Git Bash :
```bash
docker exec container psql ... "pg_read_file('//file.json')"
```

## Dépendances

- `ts-node` : `npm install -g ts-node typescript @types/node`
- Docker avec PostgreSQL
- Bash 4+

## Limite PostgreSQL

PostgreSQL limite les éléments JSONB à 268MB. Le split à 150MB laisse une marge de sécurité.

## Workflow complet

```
1. Le script vérifie la taille du JSON
2. Si > 150MB : découpe avec TypeScript
3. Import part par part dans table raw
4. Projection via callback après chaque part
5. TRUNCATE raw entre chaque part
6. Nettoyage des fichiers temporaires
7. Drop optionnel des tables raw
```

## Avantages

- ✅ Pas de limite de taille
- ✅ Mémoire maîtrisée (max 150MB en raw)
- ✅ Code DRY et réutilisable
- ✅ Compatible Windows/Linux/macOS