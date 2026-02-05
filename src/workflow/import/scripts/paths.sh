#!/usr/bin/env bash

# Répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Racine du repo
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
# SRC
SRC_DIR="$ROOT_DIR/src"
# DATA
DATA_DIR="$ROOT_DIR/src/data"

# Exported paths
export SCHEMA_DIR="$SRC_DIR/sql/schema"
export TABLES_DIR="$DATA_DIR/parser/tables"

# TODO Faudra lacher du token ici
export DB_CONTAINER="deputedex-db"
export DB_USER="dev"
export DB_NAME="deputedex"

# Paramètres du splitter
export MAX_JSON_SIZE_MB=150
export JSON_SPLITTER_TS="$SCRIPT_DIR/json-splitter.ts"