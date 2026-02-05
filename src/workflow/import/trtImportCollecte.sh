#!/usr/bin/env bash

# ==============================================================================
# IMPORT ALL - Script pour importer toutes les données dans la DB
# ==============================================================================

set -e

# Déterminer le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Récupérer le paramètre --auto-cleanup
AUTO_CLEANUP=""
if [[ "$1" == "--auto-cleanup" ]]; then
    AUTO_CLEANUP="--auto-cleanup"
    echo "ℹ️  Auto cleanup mode enabled"
fi

# ----------------------------------------------------------------------
# Scripts d'import existants
# ----------------------------------------------------------------------
SCRIPTS=(
  "$SCRIPT_DIR/scripts/acteurs-import.sh"
  "$SCRIPT_DIR/scripts/scrutins-import.sh"
  # ajouter ici les futurs imports
)

# ----------------------------------------------------------------------
# Boucle sur tous les scripts
# ----------------------------------------------------------------------
echo "=============================================="
echo "🚀 Starting ALL imports"
echo "=============================================="

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        echo ""
        echo "=============================================="
        echo "Running $script"
        echo "=============================================="
        bash "$script" $AUTO_CLEANUP
    else
        echo "⚠️  Script not found: $script, skipping..."
    fi
done

echo ""
echo "=============================================="
echo "🎉 All imports completed"
echo "=============================================="