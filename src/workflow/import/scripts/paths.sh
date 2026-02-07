#!/usr/bin/env bash

# Répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Racine du repo
ROOT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
# SRC
SRC_DIR="$ROOT_DIR/src"
# DATA
DATA_DIR="$ROOT_DIR/data"

# Exported paths
export SCHEMA_DIR="$SRC_DIR/sql/schema"
export TABLES_DIR="$DATA_DIR/parser/tables"

# TODO Faudra lacher du token ici
export DB_CONTAINER="deputedex-db"
export DB_USER_WRITER="user_etl_writer"
export DB_NAME="deputedex"

# Paramètres du splitter
export MAX_JSON_SIZE_MB=125
export JSON_SPLITTER_TS="$SCRIPT_DIR/json-splitter.ts"