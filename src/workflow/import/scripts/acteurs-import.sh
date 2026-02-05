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
# ACTEURS - IMPORT COMPLET (LOCAL VERSION)
# ==============================================================================
SCHEMA_NAME="acteurs.schema.sql"
ACTEURS_JSON="acteurs.json"
ACTEURS_ADRESSES_POSTALES_JSON="acteursAdressesPostales.json"
ACTEURS_ADRESSES_MAILS_JSON="acteursAdressesMails.json"
ACTEURS_RESEAUX_SOCIAUX_JSON="acteursReseauxSociaux.json"
ACTEURS_TELEPHONES_JSON="acteursTelephones.json"

echo "=============================================="
echo "ACTEURS IMPORT SCRIPT"
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
# STEP 2: Import ACTEURS (main table)
# ==============================================================================
echo "=============================================="
echo "ACTEURS (main table)"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$ACTEURS_JSON $DB_CONTAINER:/$ACTEURS_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$ACTEURS_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO acteurs_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$ACTEURS_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM acteurs_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO acteurs (uid, civilite, prenom, nom, nom_alpha, trigramme, date_naissance, ville_naissance, departement_naissance, pays_naissance, date_deces, profession_libelle, profession_categorie, profession_famille, uri_hatvp)
   SELECT data->>'uid', data->>'civilite', data->>'prenom', data->>'nom', data->>'nom_alpha', data->>'trigramme',
          NULLIF(data->>'date_naissance', '')::date, data->>'ville_naissance', data->>'departement_naissance',
          data->>'pays_naissance', NULLIF(data->>'date_deces', '')::date, data->>'profession_libelle',
          data->>'profession_categorie', data->>'profession_famille', data->>'uri_hatvp'
   FROM acteurs_raw
   ON CONFLICT (uid) DO NOTHING;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM acteurs;"

echo "✓ Acteurs imported"
echo ""

# ==============================================================================
# STEP 3: Import ACTEURS_ADRESSES_POSTALES
# ==============================================================================
echo "=============================================="
echo "ACTEURS_ADRESSES_POSTALES"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$ACTEURS_ADRESSES_POSTALES_JSON $DB_CONTAINER:/$ACTEURS_ADRESSES_POSTALES_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$ACTEURS_ADRESSES_POSTALES_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO acteurs_adresses_postales_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$ACTEURS_ADRESSES_POSTALES_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM acteurs_adresses_postales_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO acteurs_adresses_postales (acteur_uid, uid_adresse, type_code, type_libelle, intitule, numero_rue, nom_rue, complement_adresse, code_postal, ville)
   SELECT data->>'acteur_uid', data->>'uid_adresse', data->>'type_code', data->>'type_libelle',
          data->>'intitule', data->>'numero_rue', data->>'nom_rue', data->>'complement_adresse',
          data->>'code_postal', data->>'ville'
   FROM acteurs_adresses_postales_raw;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM acteurs_adresses_postales;"

echo "✓ Adresses postales imported"
echo ""

# ==============================================================================
# STEP 4: Import ACTEURS_ADRESSES_MAILS
# ==============================================================================
echo "=============================================="
echo "ACTEURS_ADRESSES_MAILS"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$ACTEURS_ADRESSES_MAILS_JSON $DB_CONTAINER:/$ACTEURS_ADRESSES_MAILS_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$ACTEURS_ADRESSES_MAILS_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO acteurs_adresses_mails_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$ACTEURS_ADRESSES_MAILS_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM acteurs_adresses_mails_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO acteurs_adresses_mails (acteur_uid, uid_adresse, type_code, type_libelle, email)
   SELECT data->>'acteur_uid', data->>'uid_adresse', data->>'type_code', data->>'type_libelle', data->>'email'
   FROM acteurs_adresses_mails_raw;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM acteurs_adresses_mails;"

echo "✓ Adresses mails imported"
echo ""

# ==============================================================================
# STEP 5: Import ACTEURS_RESEAUX_SOCIAUX
# ==============================================================================
echo "=============================================="
echo "ACTEURS_RESEAUX_SOCIAUX"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$ACTEURS_RESEAUX_SOCIAUX_JSON $DB_CONTAINER:/$ACTEURS_RESEAUX_SOCIAUX_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$ACTEURS_RESEAUX_SOCIAUX_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO acteurs_reseaux_sociaux_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$ACTEURS_RESEAUX_SOCIAUX_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM acteurs_reseaux_sociaux_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO acteurs_reseaux_sociaux (acteur_uid, uid_adresse, type_code, type_libelle, plateforme, identifiant)
   SELECT data->>'acteur_uid', data->>'uid_adresse', data->>'type_code', data->>'type_libelle',
          data->>'plateforme', data->>'identifiant'
   FROM acteurs_reseaux_sociaux_raw;"

echo "Final verification..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM acteurs_reseaux_sociaux;"

echo "✓ Réseaux sociaux imported"
echo ""

# ==============================================================================
# STEP 6: Import ACTEURS_TELEPHONES
# ==============================================================================
echo "=============================================="
echo "ACTEURS_TELEPHONES"
echo "=============================================="

echo "Copying JSON to container..."
docker cp $TABLES_DIR/$ACTEURS_TELEPHONES_JSON $DB_CONTAINER:/$ACTEURS_TELEPHONES_JSON

echo "Verifying file..."
docker exec -it $DB_CONTAINER ls -lh //$ACTEURS_TELEPHONES_JSON

echo "Importing to raw table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO acteurs_telephones_raw (data) SELECT elem FROM jsonb_array_elements(pg_read_file('//$ACTEURS_TELEPHONES_JSON')::jsonb) AS elem;"

echo "Checking raw count..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM acteurs_telephones_raw;"

echo "Projecting to SQL table..."
docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "INSERT INTO acteurs_telephones (acteur_uid, uid_adresse, type_code, type_libelle, adresse_rattachement, numero)
   SELECT data->>'acteur_uid', data->>'uid_adresse', data->>'type_code', data->>'type_libelle',
          data->>'adresse_rattachement', data->>'numero'
   FROM acteurs_telephones_raw;"

echo "Final verification..."

docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "SELECT COUNT(*) FROM acteurs_telephones;"

echo "✓ Téléphones imported"
echo ""

# ==============================================================================
# STEP 7: Clean up raw tables + files from container
# ==============================================================================
echo "=============================================="
echo "CLEANUP "
echo "=============================================="

echo "Cleaning JSON files from container"
docker exec -it $DB_CONTAINER rm -f \
  //$ACTEURS_JSON \
  //$ACTEURS_ADRESSES_POSTALES_JSON \
  //$ACTEURS_ADRESSES_MAILS_JSON \
  //$ACTEURS_RESEAUX_SOCIAUX_JSON \
  //$ACTEURS_TELEPHONES_JSON

if [[ "$AUTO_CLEANUP" == true ]]; then
    echo "🤖 Auto cleanup enabled - dropping raw tables..."
    docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
      "DROP TABLE IF EXISTS acteurs_raw, acteurs_adresses_postales_raw, acteurs_adresses_mails_raw, acteurs_reseaux_sociaux_raw, acteurs_telephones_raw CASCADE;"
    echo "✓ Raw tables dropped"
else
    read -p "Do you want to drop raw tables? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        docker exec -it $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
          "DROP TABLE IF EXISTS acteurs_raw, acteurs_adresses_postales_raw, acteurs_adresses_mails_raw, acteurs_reseaux_sociaux_raw, acteurs_telephones_raw CASCADE;"
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
  'acteurs' as table_name, COUNT(*) as count FROM acteurs
UNION ALL
SELECT 'acteurs_adresses_postales', COUNT(*) FROM acteurs_adresses_postales
UNION ALL
SELECT 'acteurs_adresses_mails', COUNT(*) FROM acteurs_adresses_mails
UNION ALL
SELECT 'acteurs_reseaux_sociaux', COUNT(*) FROM acteurs_reseaux_sociaux
UNION ALL
SELECT 'acteurs_telephones', COUNT(*) FROM acteurs_telephones;
"

echo ""
echo "=============================================="
echo "✓ IMPORT COMPLETED"
echo "=============================================="