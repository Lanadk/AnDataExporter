#!/usr/bin/env bash

set -e  # Exit on error

# SOURCING
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/paths.sh"

# Gestion du paramètre --auto-cleanup
AUTO_CLEANUP=false
if [[ "$1" == "--auto-cleanup" ]]; then
    AUTO_CLEANUP=true
    echo "ℹ️  Auto cleanup mode enabled"
fi

# Check des repertoires
for dir in "$SCHEMA_DIR" "$TABLES_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "❌ Missing directory: $dir"
    exit 1
  fi
done

# ==============================================================================
# SCRUTINS - IMPORT COMPLET (LOCAL VERSION)
# ==============================================================================
SCHEMA_NAME="scrutins.schema.sql"
SCRUTINS_JSON="scrutins.json"
DEPUTES_JSON="deputes.json"
GROUPES_JSON="groupes.json"
SCRUTINS_GROUPES_JSON="scrutinsGroupes.json"
VOTES_DEPUTES_JSON="votesDeputes.json"
SCRUTINS_AGREGATS_JSON="scrutinsAgregats.json"
SCRUTINS_GROUPES_AGREGATS_JSON="scrutinsGroupesAgregats.json"

echo "=============================================="
echo "VOTES IMPORT SCRIPT"
echo "=============================================="
echo ""

# ==============================================================================
# STEP 1: Import Schema
# ==============================================================================
echo "Importing schema..."
cat $SCHEMA_DIR/$SCHEMA_NAME | docker exec -i $DB_CONTAINER psql -U $DB_USER -d $DB_NAME
echo "✓ Schema imported"
echo ""

# ==============================================================================
# STEP 2: Import DEPUTES
# ==============================================================================
echo "=============================================="
echo "DEPUTES"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$DEPUTES_JSON $DB_CONTAINER:/$DEPUTES_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$DEPUTES_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO deputes_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$DEPUTES_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM deputes_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO deputes (id)
   SELECT data->>'id'
   FROM deputes_raw
   ON CONFLICT (id) DO NOTHING;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM deputes;"

echo "✓ Deputes imported"
echo ""

# ==============================================================================
# STEP 3: Import GROUPES_PARLEMENTAIRES
# ==============================================================================
echo "=============================================="
echo "GROUPES_PARLEMENTAIRES"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$GROUPES_JSON $DB_CONTAINER:/$GROUPES_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$GROUPES_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO groupes_parlementaires_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$GROUPES_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM groupes_parlementaires_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO groupes_parlementaires (id, nom)
   SELECT data->>'id', data->>'nom'
   FROM groupes_parlementaires_raw
   ON CONFLICT (id) DO NOTHING;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM groupes_parlementaires;"

echo "✓ Groupes parlementaires imported"
echo ""

# ==============================================================================
# STEP 4: Import SCRUTINS
# ==============================================================================
echo "=============================================="
echo "SCRUTINS"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$SCRUTINS_JSON $DB_CONTAINER:/$SCRUTINS_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$SCRUTINS_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO scrutins_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$SCRUTINS_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM scrutins_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO scrutins (uid, numero, legislature, date_scrutin, titre, type_scrutin_code, type_scrutin_libelle, type_majorite, resultat_code, resultat_libelle)
   SELECT data->>'uid', data->>'numero', data->>'legislature', NULLIF(data->>'date_scrutin', '')::date,
          data->>'titre', data->>'type_scrutin_code', data->>'type_scrutin_libelle', data->>'type_majorite',
          data->>'resultat_code', data->>'resultat_libelle'
   FROM scrutins_raw
   ON CONFLICT (uid) DO NOTHING;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM scrutins;"

echo "✓ Scrutins imported"
echo ""

# ==============================================================================
# STEP 5: Import SCRUTINS_GROUPES
# ==============================================================================
echo "=============================================="
echo "SCRUTINS_GROUPES"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$SCRUTINS_GROUPES_JSON $DB_CONTAINER:/$SCRUTINS_GROUPES_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$SCRUTINS_GROUPES_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO scrutins_groupes_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$SCRUTINS_GROUPES_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM scrutins_groupes_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO scrutins_groupes (scrutin_uid, groupe_id, nombre_membres, position_majoritaire)
   SELECT data->>'scrutin_uid', data->>'groupe_id', (data->>'nombre_membres')::integer, data->>'position_majoritaire'
   FROM scrutins_groupes_raw;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM scrutins_groupes;"

echo "✓ Scrutins groupes imported"
echo ""

# ==============================================================================
# STEP 6: Import VOTES_DEPUTES
# ==============================================================================
echo "=============================================="
echo "VOTES_DEPUTES"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$VOTES_DEPUTES_JSON $DB_CONTAINER:/$VOTES_DEPUTES_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$VOTES_DEPUTES_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO votes_deputes_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$VOTES_DEPUTES_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM votes_deputes_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO votes_deputes (scrutin_uid, depute_id, groupe_id, mandat_ref, position, cause_position, par_delegation)
   SELECT data->>'scrutin_uid', data->>'depute_id', data->>'groupe_id', data->>'mandat_ref',
          data->>'position', data->>'cause_position', (data->>'par_delegation')::boolean
   FROM votes_deputes_raw;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM votes_deputes;"

echo "✓ Scrutins deputes imported"
echo ""

# ==============================================================================
# STEP 7: Import SCRUTINS_AGREGATS
# ==============================================================================
echo "=============================================="
echo "SCRUTINS_AGREGATS"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$SCRUTINS_AGREGATS_JSON $DB_CONTAINER:/$SCRUTINS_AGREGATS_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$SCRUTINS_AGREGATS_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO scrutins_agregats_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$SCRUTINS_AGREGATS_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM scrutins_agregats_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO scrutins_agregats (scrutin_uid, nombre_votants, suffrages_exprimes, suffrages_requis, total_pour, total_contre, total_abstentions, total_non_votants, total_non_votants_volontaires)
   SELECT data->>'scrutin_uid', (data->>'nombre_votants')::integer, (data->>'suffrages_exprimes')::integer,
          (data->>'suffrages_requis')::integer, (data->>'total_pour')::integer, (data->>'total_contre')::integer,
          (data->>'total_abstentions')::integer, (data->>'total_non_votants')::integer, (data->>'total_non_votants_volontaires')::integer
   FROM scrutins_agregats_raw
   ON CONFLICT (scrutin_uid) DO NOTHING;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM scrutins_agregats;"

echo "✓ Scrutins agregats imported"
echo ""

# ==============================================================================
# STEP 8: Import SCRUTINS_GROUPES_AGREGATS
# ==============================================================================
echo "=============================================="
echo "SCRUTINS_GROUPES_AGREGATS"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$SCRUTINS_GROUPES_AGREGATS_JSON $DB_CONTAINER:/$SCRUTINS_GROUPES_AGREGATS_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$SCRUTINS_GROUPES_AGREGATS_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO scrutins_groupes_agregats_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$SCRUTINS_GROUPES_AGREGATS_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM scrutins_groupes_agregats_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO scrutins_groupes_agregats (scrutin_uid, groupe_id, pour, contre, abstentions, non_votants, non_votants_volontaires)
   SELECT data->>'scrutin_uid', data->>'groupe_id', (data->>'pour')::integer, (data->>'contre')::integer,
          (data->>'abstentions')::integer, (data->>'non_votants')::integer, (data->>'non_votants_volontaires')::integer
   FROM scrutins_groupes_agregats_raw;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM scrutins_groupes_agregats;"

echo "✓ votes groupes agregats imported"
echo ""

# ==============================================================================
# STEP 9: Clean up raw tables
# ==============================================================================
echo "=============================================="
echo "CLEANUP"
echo "=============================================="

echo "Cleaning JSON files from container"
docker exec -it $DB_CONTAINER rm -f \
  //$DEPUTES_JSON \
  //$GROUPES_JSON \
  //$SCRUTINS_JSON \
  //$SCRUTINS_GROUPES_JSON \
  //$VOTES_DEPUTES_JSON \
  //$SCRUTINS_AGREGATS_JSON \
  //$SCRUTINS_GROUPES_AGREGATS_JSON

if [[ "$AUTO_CLEANUP" == true ]]; then
    echo "🤖 Auto cleanup enabled - dropping raw tables..."
    docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
      "DROP TABLE IF EXISTS deputes_raw, groupes_parlementaires_raw, scrutins_raw, scrutins_groupes_raw,
       votes_deputes_raw, scrutins_agregats_raw, scrutins_groupes_agregats_raw CASCADE;"
    echo "✓ Raw tables dropped"
else
    read -p "Do you want to drop raw tables? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
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

docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
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