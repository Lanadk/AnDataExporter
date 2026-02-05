#!/usr/bin/env bash

# ==============================================================================
# JSON IMPORT UTILITIES - WITH INCREMENTAL PROJECTION
# ==============================================================================
# Fonctions réutilisables pour importer des JSON dans PostgreSQL
# avec support du split pour les gros fichiers
#
# Projection incrémentale après chaque part
# - Import part 0 → raw → projection → clean raw
# - Import part 1 → raw → projection → clean raw
# - etc.
#
# Usage:
#   source "$SCRIPT_DIR/json-import-utils.sh"
#   import_json_to_raw_table "$TABLES_DIR/file.json" "table_raw" "projection_callback"
#
# IMPORTANT - Windows Git Bash Compatibility:
#   Tous les chemins dans les commandes docker exec utilisent le préfixe //
#   pour éviter la conversion automatique des chemins par Git Bash
# ==============================================================================

# ==============================================================================
# FILE SIZE CHECK
# ==============================================================================
should_split_json() {
    local file=$1
    local max_size_mb=${2:-$MAX_JSON_SIZE_MB}

    if [ ! -f "$file" ]; then
        echo "❌ File not found: $file" >&2
        return 1
    fi

    local file_size_mb=$(du -m "$file" | cut -f1)

    [ "$file_size_mb" -gt "$max_size_mb" ]
}

# ==============================================================================
# SPLIT JSON WITH TYPESCRIPT
# ==============================================================================
split_json_with_ts() {
    local input_file=$1
    local max_size_mb=$2

    if ! command -v ts-node &> /dev/null; then
        echo "❌ Error: ts-node not found" >&2
        echo "Please install: npm install -g ts-node typescript @types/node" >&2
        return 1
    fi

    if [ ! -f "$JSON_SPLITTER_TS" ]; then
        echo "❌ Error: json-splitter.ts not found at $JSON_SPLITTER_TS" >&2
        return 1
    fi

    ts-node "$JSON_SPLITTER_TS" "$input_file" "$max_size_mb"
}

# ==============================================================================
# CLEANUP SPLIT FILES
# ==============================================================================
cleanup_split_files() {
    local original_file=$1
    local base_name=$(basename "$original_file" .json)
    local dir_name=$(dirname "$original_file")

    rm -f "$dir_name/${base_name}_part"*.json
    echo "🧹 Cleaned up split files for $(basename "$original_file")"
}

# ==============================================================================
# IMPORT JSON TO RAW TABLE (MAIN FUNCTION)
# ==============================================================================
import_json_to_raw_table() {
    local json_file=$1
    local raw_table=$2
    local projection_callback=$3  # Fonction appelée après chaque import
    local max_size_mb=${4:-$MAX_JSON_SIZE_MB}

    # Validation des paramètres requis
    if [ -z "$json_file" ] || [ -z "$raw_table" ]; then
        echo "❌ Error: Missing required parameters" >&2
        echo "Usage: import_json_to_raw_table <json_file> <raw_table> <projection_callback> [max_size_mb]" >&2
        return 1
    fi

    # Validation des variables d'environnement
    if [ -z "$DB_CONTAINER" ] || [ -z "$DB_USER" ] || [ -z "$DB_NAME" ]; then
        echo "❌ Error: Missing environment variables" >&2
        echo "Required: DB_CONTAINER, DB_USER, DB_NAME" >&2
        return 1
    fi

    echo "Checking file size..."

    # Vérifier si le fichier doit être divisé
    if should_split_json "$json_file" "$max_size_mb"; then
        _import_large_json_incremental "$json_file" "$raw_table" "$projection_callback" "$max_size_mb"
    else
        _import_small_json "$json_file" "$raw_table" "$projection_callback"
    fi
}

# ==============================================================================
# INTERNAL: IMPORT LARGE JSON WITH INCREMENTAL PROJECTION
# ==============================================================================
_import_large_json_incremental() {
    local json_file=$1
    local raw_table=$2
    local projection_callback=$3
    local max_size_mb=$4

    echo "⚠️  File exceeds ${max_size_mb}MB - splitting with TypeScript..."

    # Split et récupérer la liste des fichiers
    local part_files=$(split_json_with_ts "$json_file" "$max_size_mb")

    if [ $? -ne 0 ]; then
        echo "❌ Split failed" >&2
        return 1
    fi

    # Compter le nombre total de parts
    local total_parts=$(echo "$part_files" | wc -l)
    echo "📊 Total parts to process: $total_parts"
    echo ""

    # Importer et projeter chaque partie séparément
    echo "Importing parts into tables"
    echo "DEBUG: [$part_files]"
    local part_num=0
    echo "DEBUG: Starting loop"
    while IFS= read -r part_file; do
        echo "DEBUG: Loop iteration, part_file=[$part_file]"
        [ -z "$part_file" ] && continue

        part_num=$((part_num + 1))
        echo "=============================================="
        echo "Processing part $part_num/$total_parts"
        echo "=============================================="

        # 1. Import dans raw
        _import_part_file "$part_file" "$raw_table" || return 1

        # 2. Vérifier le contenu de raw
        echo "Checking raw count..."
        docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
          "SELECT COUNT(*) FROM $raw_table;"

        # 3. Projection (callback fourni par l'appelant)
        if [ -n "$projection_callback" ] && [ "$(type -t "$projection_callback")" = "function" ]; then
            echo "Projecting to SQL table..."
            $projection_callback "$raw_table"
        fi

        # 4. Clean raw pour la prochaine part
        echo "Cleaning raw table for next part..."
        docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
          "TRUNCATE TABLE $raw_table;"

        echo "✓ Part $part_num/$total_parts processed"
        echo ""
    done <<< "$part_files"

    echo "✅ All $total_parts parts imported and projected"

    # Nettoyer les fichiers temporaires locaux
    cleanup_split_files "$json_file"
}

# ==============================================================================
# INTERNAL: IMPORT SMALL JSON (DIRECT)
# ==============================================================================
_import_small_json() {
    local json_file=$1
    local raw_table=$2
    local projection_callback=$3

    echo "ℹ️  File is under ${MAX_JSON_SIZE_MB}MB - direct import"

    local container_path="/$(basename "$json_file")"

    echo "Copying JSON to container..."
    docker cp "$json_file" "$DB_CONTAINER:$container_path"

    echo "Verifying file..."
    docker exec "$DB_CONTAINER" ls -lh "//$container_path"

    echo "Importing to raw table..."
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
        "INSERT INTO $raw_table (data)
         SELECT elem
         FROM jsonb_array_elements(pg_read_file('//$container_path')::jsonb) AS elem;"

    # Nettoyer le fichier du container
    docker exec "$DB_CONTAINER" rm -f "//$container_path"

    echo "✓ Imported into raw"

    # Vérifier le contenu de raw
    echo "Checking raw count..."
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
      "SELECT COUNT(*) FROM $raw_table;"

    # Projection (si callback fourni)
    if [ -n "$projection_callback" ] && [ "$(type -t "$projection_callback")" = "function" ]; then
        echo "Projecting to SQL table..."
        $projection_callback "$raw_table"
    fi

    echo "✅ Imported and projected"
}

# ==============================================================================
# INTERNAL: IMPORT SINGLE PART FILE
# ==============================================================================
_import_part_file() {
    local part_file=$1
    local raw_table=$2
    echo "DEBUG: _import_part_file called with part_file=[$1] raw_table=[$2]"
    echo "📦 Importing part $(basename "$part_file")..."

    local container_path="/$(basename "$part_file")"

    echo "Copying JSON to container..."
    docker cp "$part_file" "$DB_CONTAINER:$container_path" || return 1

    echo "Importing to raw table..."
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
        "INSERT INTO $raw_table (data)
         SELECT elem
         FROM jsonb_array_elements(pg_read_file('//$container_path')::jsonb) AS elem;" || return 1

    # Nettoyer le fichier du container
    docker exec "$DB_CONTAINER" rm -f "//$container_path"

    echo "✓ Part imported into raw"
}

export -f should_split_json
export -f split_json_with_ts
export -f cleanup_split_files
export -f import_json_to_raw_table
export -f _import_large_json_incremental
export -f _import_small_json
export -f _import_part_file