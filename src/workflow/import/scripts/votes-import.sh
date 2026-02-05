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
# VOTES - IMPORT COMPLET (LOCAL VERSION)
# ==============================================================================
SCHEMA_NAME="votes.schema.sql"
VOTES_JSON="votes.json"
DEPUTES_JSON="deputes.json"
GROUPES_JSON="groupes.json"
VOTES_GROUPES_JSON="votesGroupes.json"
VOTES_DEPUTES_JSON="votesDeputes.json"
VOTES_AGREGATS_JSON="votesAgregats.json"
VOTES_GROUPES_AGREGATS_JSON="votesGroupesAgregats.json"

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
# STEP 4: Import VOTES
# ==============================================================================
echo "=============================================="
echo "VOTES"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$VOTES_JSON $DB_CONTAINER:/$VOTES_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$VOTES_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO votes_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$VOTES_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM votes_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO votes (uid, numero, legislature, date_vote, titre, type_vote_code, type_vote_libelle, type_majorite, resultat_code, resultat_libelle)
   SELECT data->>'uid', data->>'numero', data->>'legislature', NULLIF(data->>'date_vote', '')::date,
          data->>'titre', data->>'type_vote_code', data->>'type_vote_libelle', data->>'type_majorite',
          data->>'resultat_code', data->>'resultat_libelle'
   FROM votes_raw
   ON CONFLICT (uid) DO NOTHING;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM votes;"

echo "✓ votes imported"
echo ""

# ==============================================================================
# STEP 5: Import VOTES_GROUPES
# ==============================================================================
echo "=============================================="
echo "VOTES_GROUPES"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$VOTES_GROUPES_JSON $DB_CONTAINER:/$VOTES_GROUPES_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$VOTES_GROUPES_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO votes_groupes_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$VOTES_GROUPES_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM votes_groupes_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO votes_groupes (vote_uid, groupe_id, nombre_membres, position_majoritaire)
   SELECT data->>'vote_uid', data->>'groupe_id', (data->>'nombre_membres')::integer, data->>'position_majoritaire'
   FROM votes_groupes_raw;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM votes_groupes;"

echo "✓ votes groupes imported"
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
  "INSERT INTO votes_deputes (vote_uid, depute_id, groupe_id, mandat_ref, position, cause_position, par_delegation)
   SELECT data->>'vote_uid', data->>'depute_id', data->>'groupe_id', data->>'mandat_ref',
          data->>'position', data->>'cause_position', (data->>'par_delegation')::boolean
   FROM votes_deputes_raw;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM votes_deputes;"

echo "✓ Votes deputes imported"
echo ""

# ==============================================================================
# STEP 7: Import VOTES_AGREGATS
# ==============================================================================
echo "=============================================="
echo "VOTES_AGREGATS"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$VOTES_AGREGATS_JSON $DB_CONTAINER:/$VOTES_AGREGATS_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$VOTES_AGREGATS_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO votes_agregats_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$VOTES_AGREGATS_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM votes_agregats_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO votes_agregats (vote_uid, nombre_votants, suffrages_exprimes, suffrages_requis, total_pour, total_contre, total_abstentions, total_non_votants, total_non_votants_volontaires)
   SELECT data->>'vote_uid', (data->>'nombre_votants')::integer, (data->>'suffrages_exprimes')::integer,
          (data->>'suffrages_requis')::integer, (data->>'total_pour')::integer, (data->>'total_contre')::integer,
          (data->>'total_abstentions')::integer, (data->>'total_non_votants')::integer, (data->>'total_non_votants_volontaires')::integer
   FROM votes_agregats_raw
   ON CONFLICT (vote_uid) DO NOTHING;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM votes_agregats;"

echo "✓ votes agregats imported"
echo ""

# ==============================================================================
# STEP 8: Import VOTES_GROUPES_AGREGATS
# ==============================================================================
echo "=============================================="
echo "VOTES_GROUPES_AGREGATS"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$VOTES_GROUPES_AGREGATS_JSON $DB_CONTAINER:/$VOTES_GROUPES_AGREGATS_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$VOTES_GROUPES_AGREGATS_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO votes_groupes_agregats_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$VOTES_GROUPES_AGREGATS_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM votes_groupes_agregats_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO votes_groupes_agregats (vote_uid, groupe_id, pour, contre, abstentions, non_votants, non_votants_volontaires)
   SELECT data->>'vote_uid', data->>'groupe_id', (data->>'pour')::integer, (data->>'contre')::integer,
          (data->>'abstentions')::integer, (data->>'non_votants')::integer, (data->>'non_votants_volontaires')::integer
   FROM votes_groupes_agregats_raw;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM votes_groupes_agregats;"

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
  //$VOTES_JSON \
  //$VOTES_GROUPES_JSON \
  //$VOTES_DEPUTES_JSON \
  //$VOTES_AGREGATS_JSON \
  //$VOTES_GROUPES_AGREGATS_JSON

if [[ "$AUTO_CLEANUP" == true ]]; then
    echo "🤖 Auto cleanup enabled - dropping raw tables..."
    docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
      "DROP TABLE IF EXISTS deputes_raw, groupes_parlementaires_raw, votes_raw, votes_groupes_raw,
       votes_deputes_raw, votes_agregats_raw, votes_groupes_agregats_raw CASCADE;"
    echo "✓ Raw tables dropped"
else
    read -p "Do you want to drop raw tables? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
          "DROP TABLE IF EXISTS deputes_raw, groupes_parlementaires_raw, votes_raw, votes_groupes_raw,
           votes_deputes_raw, votes_agregats_raw, votes_groupes_agregats_raw CASCADE;"
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
SELECT 'votes', COUNT(*) FROM votes
UNION ALL
SELECT 'votes_groupes', COUNT(*) FROM votes_groupes
UNION ALL
SELECT 'votes_deputes', COUNT(*) FROM votes_deputes
UNION ALL
SELECT 'votes_agregats', COUNT(*) FROM votes_agregats
UNION ALL
SELECT 'votes_groupes_agregats', COUNT(*) FROM votes_groupes_agregats;
"

echo ""
echo "=============================================="
echo "✓ IMPORT COMPLETED"
echo "=============================================="