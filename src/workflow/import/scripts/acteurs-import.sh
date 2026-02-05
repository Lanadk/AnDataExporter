#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/paths.sh"
source "$SCRIPT_DIR/json-import-utils.sh"

AUTO_CLEANUP=false
if [[ "$1" == "--auto-cleanup" ]]; then
    AUTO_CLEANUP=true
    echo "ℹ️  Auto cleanup mode enabled"
fi

SCHEMA_NAME="acteurs.schema.sql"
ACTEURS_JSON="acteurs.json"
ACTEURS_ADRESSES_POSTALES_JSON="acteursAdressesPostales.json"
ACTEURS_ADRESSES_MAILS_JSON="acteursAdressesMails.json"
ACTEURS_RESEAUX_SOCIAUX_JSON="acteursReseauxSociaux.json"
ACTEURS_TELEPHONES_JSON="acteursTelephones.json"

project_acteurs() {
    local raw_table=$1
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
      "INSERT INTO acteurs (uid, civilite, prenom, nom, nom_alpha, trigramme, date_naissance, ville_naissance, departement_naissance, pays_naissance, date_deces, profession_libelle, profession_categorie, profession_famille, uri_hatvp)
       SELECT data->>'uid', data->>'civilite', data->>'prenom', data->>'nom', data->>'nom_alpha', data->>'trigramme',
              NULLIF(data->>'date_naissance', '')::date, data->>'ville_naissance', data->>'departement_naissance',
              data->>'pays_naissance', NULLIF(data->>'date_deces', '')::date, data->>'profession_libelle',
              data->>'profession_categorie', data->>'profession_famille', data->>'uri_hatvp'
       FROM $raw_table
       ON CONFLICT (uid) DO NOTHING;"
}

project_acteurs_adresses_postales() {
    local raw_table=$1
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
      "INSERT INTO acteurs_adresses_postales (acteur_uid, uid_adresse, type_code, type_libelle, intitule, numero_rue, nom_rue, complement_adresse, code_postal, ville)
       SELECT data->>'acteur_uid', data->>'uid_adresse', data->>'type_code', data->>'type_libelle',
              data->>'intitule', data->>'numero_rue', data->>'nom_rue', data->>'complement_adresse',
              data->>'code_postal', data->>'ville'
       FROM $raw_table;"
}

project_acteurs_adresses_mails() {
    local raw_table=$1
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
      "INSERT INTO acteurs_adresses_mails (acteur_uid, uid_adresse, type_code, type_libelle, email)
       SELECT data->>'acteur_uid', data->>'uid_adresse', data->>'type_code', data->>'type_libelle', data->>'email'
       FROM $raw_table;"
}

project_acteurs_reseaux_sociaux() {
    local raw_table=$1
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
      "INSERT INTO acteurs_reseaux_sociaux (acteur_uid, uid_adresse, type_code, type_libelle, plateforme, identifiant)
       SELECT data->>'acteur_uid', data->>'uid_adresse', data->>'type_code', data->>'type_libelle',
              data->>'plateforme', data->>'identifiant'
       FROM $raw_table;"
}

project_acteurs_telephones() {
    local raw_table=$1
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
      "INSERT INTO acteurs_telephones (acteur_uid, uid_adresse, type_code, type_libelle, adresse_rattachement, numero)
       SELECT data->>'acteur_uid', data->>'uid_adresse', data->>'type_code', data->>'type_libelle',
              data->>'adresse_rattachement', data->>'numero'
       FROM $raw_table;"
}

for dir in "$SCHEMA_DIR" "$TABLES_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "❌ Missing directory: $dir"
    exit 1
  fi
done

echo "=============================================="
echo "ACTEURS IMPORT SCRIPT"
echo "=============================================="
echo ""

echo "Importing schema..."
cat "$SCHEMA_DIR/$SCHEMA_NAME" | docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME"
echo "✓ Schema imported"
echo ""

echo "=============================================="
echo "ACTEURS"
echo "=============================================="

import_json_to_raw_table "$TABLES_DIR/$ACTEURS_JSON" "acteurs_raw" "project_acteurs"

echo "Final verification..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
  "SELECT COUNT(*) FROM acteurs;"

echo "✓ Acteurs imported"
echo ""

echo "=============================================="
echo "ACTEURS_ADRESSES_POSTALES"
echo "=============================================="

import_json_to_raw_table "$TABLES_DIR/$ACTEURS_ADRESSES_POSTALES_JSON" "acteurs_adresses_postales_raw" "project_acteurs_adresses_postales"

echo "Final verification..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
  "SELECT COUNT(*) FROM acteurs_adresses_postales;"

echo "✓ Adresses postales imported"
echo ""

echo "=============================================="
echo "ACTEURS_ADRESSES_MAILS"
echo "=============================================="

import_json_to_raw_table "$TABLES_DIR/$ACTEURS_ADRESSES_MAILS_JSON" "acteurs_adresses_mails_raw" "project_acteurs_adresses_mails"

echo "Final verification..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
  "SELECT COUNT(*) FROM acteurs_adresses_mails;"

echo "✓ Adresses mails imported"
echo ""

echo "=============================================="
echo "ACTEURS_RESEAUX_SOCIAUX"
echo "=============================================="

import_json_to_raw_table "$TABLES_DIR/$ACTEURS_RESEAUX_SOCIAUX_JSON" "acteurs_reseaux_sociaux_raw" "project_acteurs_reseaux_sociaux"

echo "Final verification..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
  "SELECT COUNT(*) FROM acteurs_reseaux_sociaux;"

echo "✓ Réseaux sociaux imported"
echo ""

echo "=============================================="
echo "ACTEURS_TELEPHONES"
echo "=============================================="

import_json_to_raw_table "$TABLES_DIR/$ACTEURS_TELEPHONES_JSON" "acteurs_telephones_raw" "project_acteurs_telephones"

echo "Final verification..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
  "SELECT COUNT(*) FROM acteurs_telephones;"

echo "✓ Téléphones imported"
echo ""

echo "=============================================="
echo "CLEANUP"
echo "=============================================="

if [[ "$AUTO_CLEANUP" == true ]]; then
    echo "🤖 Auto cleanup enabled - dropping raw tables..."
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
      "DROP TABLE IF EXISTS acteurs_raw, acteurs_adresses_postales_raw, acteurs_adresses_mails_raw, acteurs_reseaux_sociaux_raw, acteurs_telephones_raw CASCADE;"
    echo "✓ Raw tables dropped"
else
    read -p "Do you want to drop raw tables? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
          "DROP TABLE IF EXISTS acteurs_raw, acteurs_adresses_postales_raw, acteurs_adresses_mails_raw, acteurs_reseaux_sociaux_raw, acteurs_telephones_raw CASCADE;"
        echo "✓ Raw tables dropped"
    fi
fi
echo ""

echo "=============================================="
echo "FINAL VERIFICATION"
echo "=============================================="

docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
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