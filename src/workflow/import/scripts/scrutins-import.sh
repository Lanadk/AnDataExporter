#!/usr/bin/env bash

set -e  # Exit on error

# ==============================================================================
# SOURCING
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/paths.sh"
source "$SCRIPT_DIR/json-import-utils.sh"

# ==============================================================================
# CONFIGURATION
# ==============================================================================
AUTO_CLEANUP=false
if [[ "$1" == "--auto-cleanup" ]]; then
    AUTO_CLEANUP=true
    echo "ℹ️  Auto cleanup mode enabled"
fi

# Fichiers JSON
SCHEMA_NAME="scrutins.schema.sql"
DEPUTES_JSON="deputes.json"
GROUPES_JSON="groupes.json"
SCRUTINS_JSON="scrutins.json"
SCRUTINS_GROUPES_JSON="scrutinsGroupes.json"
VOTES_DEPUTES_JSON="votesDeputes.json"
SCRUTINS_AGREGATS_JSON="scrutinsAgregats.json"
SCRUTINS_GROUPES_AGREGATS_JSON="scrutinsGroupesAgregats.json"


# ==============================================================================
# PROJECTION CALLBACKS
# ==============================================================================
# Ces fonctions sont appelées après chaque import de part dans les tables raw

project_deputes() {
    local raw_table=$1
    docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
      "INSERT INTO deputes (id)
       SELECT data->>'id'
       FROM $raw_table
       ON CONFLICT (id) DO NOTHING;"
}

project_groupes_parlementaires() {
    local raw_table=$1
    docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
      "INSERT INTO groupes_parlementaires (id, nom)
       SELECT data->>'id', data->>'nom'
       FROM $raw_table
       ON CONFLICT (id) DO NOTHING;"
}

project_scrutins() {
    local raw_table=$1
    docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
      "INSERT INTO scrutins (uid, numero, legislature, date_scrutin, titre, type_scrutin_code, type_scrutin_libelle, type_majorite, resultat_code, resultat_libelle)
       SELECT data->>'uid', data->>'numero', data->>'legislature', NULLIF(data->>'date_scrutin', '')::date,
              data->>'titre', data->>'type_scrutin_code', data->>'type_scrutin_libelle', data->>'type_majorite',
              data->>'resultat_code', data->>'resultat_libelle'
       FROM $raw_table
       ON CONFLICT (uid) DO NOTHING;"
}

project_scrutins_groupes() {
    local raw_table=$1
    docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
      "INSERT INTO scrutins_groupes (scrutin_uid, groupe_id, nombre_membres, position_majoritaire)
       SELECT data->>'scrutin_uid', data->>'groupe_id', (data->>'nombre_membres')::integer, data->>'position_majoritaire'
       FROM $raw_table
       ON CONFLICT (scrutin_uid, groupe_id) DO NOTHING;"
}

project_votes_deputes() {
    local raw_table=$1
    docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
      "INSERT INTO votes_deputes (scrutin_uid, depute_id, groupe_id, mandat_ref, position, cause_position, par_delegation)
       SELECT data->>'scrutin_uid', data->>'depute_id', data->>'groupe_id', data->>'mandat_ref',
              data->>'position', data->>'cause_position', (data->>'par_delegation')::boolean
       FROM $raw_table
       ON CONFLICT (scrutin_uid, depute_id) DO NOTHING;"
}

project_scrutins_agregats() {
    local raw_table=$1
    docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
      "INSERT INTO scrutins_agregats (scrutin_uid, nombre_votants, suffrages_exprimes, suffrages_requis, total_pour, total_contre, total_abstentions, total_non_votants, total_non_votants_volontaires)
       SELECT data->>'scrutin_uid', (data->>'nombre_votants')::integer, (data->>'suffrages_exprimes')::integer,
              (data->>'suffrages_requis')::integer, (data->>'total_pour')::integer, (data->>'total_contre')::integer,
              (data->>'total_abstentions')::integer, (data->>'total_non_votants')::integer, (data->>'total_non_votants_volontaires')::integer
       FROM $raw_table
       ON CONFLICT (scrutin_uid) DO NOTHING;"
}

project_scrutins_groupes_agregats() {
    local raw_table=$1
    docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
      "INSERT INTO scrutins_groupes_agregats (scrutin_uid, groupe_id, pour, contre, abstentions, non_votants, non_votants_volontaires)
       SELECT data->>'scrutin_uid', data->>'groupe_id', (data->>'pour')::integer, (data->>'contre')::integer,
              (data->>'abstentions')::integer, (data->>'non_votants')::integer, (data->>'non_votants_volontaires')::integer
       FROM $raw_table
       ON CONFLICT (scrutin_uid, groupe_id) DO NOTHING;"
}

# ==============================================================================
# VALIDATION
# ==============================================================================
for dir in "$SCHEMA_DIR" "$TABLES_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "❌ Missing directory: $dir"
    exit 1
  fi
done

echo "=============================================="
echo "VOTES IMPORT SCRIPT"
echo "=============================================="
echo ""

# ==============================================================================
# STEP 1: Import Schema
# ==============================================================================
echo "Importing schema..."
cat "$SCHEMA_DIR/$SCHEMA_NAME" | docker exec -i "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME"
echo "✓ Schema imported"
echo ""

# ==============================================================================
# STEP 2: Import DEPUTES
# ==============================================================================
echo "=============================================="
echo "DEPUTES"
echo "=============================================="

import_json_to_raw_table "$TABLES_DIR/$DEPUTES_JSON" "deputes_raw" "project_deputes"

echo "Final verification..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
  "SELECT COUNT(*) FROM deputes;"

echo "✓ Deputes imported"
echo ""

# ==============================================================================
# STEP 3: Import GROUPES_PARLEMENTAIRES
# ==============================================================================
echo "=============================================="
echo "GROUPES_PARLEMENTAIRES"
echo "=============================================="

import_json_to_raw_table "$TABLES_DIR/$GROUPES_JSON" "groupes_parlementaires_raw" "project_groupes_parlementaires"

echo "Final verification..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
  "SELECT COUNT(*) FROM groupes_parlementaires;"

echo "✓ Groupes parlementaires imported"
echo ""

# ==============================================================================
# STEP 4: Import SCRUTINS
# ==============================================================================
echo "=============================================="
echo "SCRUTINS"
echo "=============================================="

import_json_to_raw_table "$TABLES_DIR/$SCRUTINS_JSON" "scrutins_raw" "project_scrutins"

echo "Final verification..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
  "SELECT COUNT(*) FROM scrutins;"

echo "✓ Scrutins imported"
echo ""

# ==============================================================================
# STEP 5: Import SCRUTINS_GROUPES
# ==============================================================================
echo "=============================================="
echo "SCRUTINS_GROUPES"
echo "=============================================="

import_json_to_raw_table "$TABLES_DIR/$SCRUTINS_GROUPES_JSON" "scrutins_groupes_raw" "project_scrutins_groupes"

echo "Final verification..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
  "SELECT COUNT(*) FROM scrutins_groupes;"

echo "✓ Scrutins groupes imported"
echo ""

# ==============================================================================
# STEP 6: Import VOTES_DEPUTES
# ==============================================================================
echo "=============================================="
echo "VOTES_DEPUTES"
echo "=============================================="

import_json_to_raw_table "$TABLES_DIR/$VOTES_DEPUTES_JSON" "votes_deputes_raw" "project_votes_deputes"

echo "Final verification..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
  "SELECT COUNT(*) FROM votes_deputes;"

echo "✓ Votes deputes imported"
echo ""

# ==============================================================================
# STEP 7: Import SCRUTINS_AGREGATS
# ==============================================================================
echo "=============================================="
echo "SCRUTINS_AGREGATS"
echo "=============================================="

import_json_to_raw_table "$TABLES_DIR/$SCRUTINS_AGREGATS_JSON" "scrutins_agregats_raw" "project_scrutins_agregats"

echo "Final verification..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
  "SELECT COUNT(*) FROM scrutins_agregats;"

echo "✓ Scrutins agregats imported"
echo ""

# ==============================================================================
# STEP 8: Import SCRUTINS_GROUPES_AGREGATS
# ==============================================================================
echo "=============================================="
echo "SCRUTINS_GROUPES_AGREGATS"
echo "=============================================="

import_json_to_raw_table "$TABLES_DIR/$SCRUTINS_GROUPES_AGREGATS_JSON" "scrutins_groupes_agregats_raw" "project_scrutins_groupes_agregats"

echo "Final verification..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
  "SELECT COUNT(*) FROM scrutins_groupes_agregats;"

echo "✓ Scrutins groupes agregats imported"
echo ""

# ==============================================================================
# STEP 9: Clean up raw tables
# ==============================================================================
echo "=============================================="
echo "CLEANUP"
echo "=============================================="

if [[ "$AUTO_CLEANUP" == true ]]; then
    echo "🤖 Auto cleanup enabled - dropping raw tables..."
    docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
      "DROP TABLE IF EXISTS deputes_raw, groupes_parlementaires_raw, scrutins_raw, scrutins_groupes_raw,
       votes_deputes_raw, scrutins_agregats_raw, scrutins_groupes_agregats_raw CASCADE;"
    echo "✓ Raw tables dropped"
else
    read -p "Do you want to drop raw tables? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
          "DROP TABLE IF EXISTS deputes_raw, groupes_parlementaires_raw, scrutins_raw, scrutins_groupes_raw,
           votes_deputes_raw, scrutins_agregats_raw, scrutins_groupes_agregats_raw CASCADE;"
        echo "✓ Raw tables dropped"
    fi
fi
echo ""

# ==============================================================================
# FINAL VERIFICATION
# ==============================================================================
echo "=============================================="
echo "FINAL VERIFICATION"
echo "=============================================="

docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c "
SELECT
  'deputes' as table_name, COUNT(*) as count FROM deputes
UNION ALL
SELECT 'groupes_parlementaires', COUNT(*) FROM groupes_parlementaires
UNION ALL
SELECT 'scrutins', COUNT(*) FROM scrutins
UNION ALL
SELECT 'scrutins_groupes', COUNT(*) FROM scrutins_groupes
UNION ALL
SELECT 'votes_deputes', COUNT(*) FROM votes_deputes
UNION ALL
SELECT 'scrutins_agregats', COUNT(*) FROM scrutins_agregats
UNION ALL
SELECT 'scrutins_groupes_agregats', COUNT(*) FROM scrutins_groupes_agregats;
"

echo ""
echo "=============================================="
echo "✓ IMPORT COMPLETED"
echo "=============================================="