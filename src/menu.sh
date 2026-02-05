#!/usr/bin/env bash
set -e

# -----------------------------
# Functions calling the all-jobs scripts
# -----------------------------
run_download_all() { npx ts-node ./workflow/download/trtCollecteData.ts; }
run_parser_all() { npx ts-node ./workflow/parser/trtCheckCollecte.ts; }
run_import_all() { ./workflow/import/trtImportCollecte.sh "$1"; }
run_update_all() { npx ts-node ./workflow/update/updateAll.ts; }

# -----------------------------
# Sub menu for unit jobs
# -----------------------------
unit_job_menu() {
    while true; do
        echo "=============================================="
        echo " "
        echo "UNIT JOB MENU"
        echo " "
        echo "=============================================="
        echo " "
        echo "1) Download Acteurs"
        echo "2) Download Scrutins"
        echo "3) Parse Acteurs"
        echo "4) Parse Scrutins"
        echo "5) Import Acteurs"
        echo "6) Import Scrutins"
        echo "0) Back to Main Menu"
        echo " "
        echo "=============================================="
        read -p "Select a unit job: " unit_option

        case $unit_option in
            1) npx ts-node ./download/downloadActeurs.ts ;;
            2) npx ts-node ./download/downloadScrutins.ts ;;
            3) npx ts-node ./parser/runActeursJob.ts ;;
            4) npx ts-node ./parser/runScrutinsJob.ts ;;
            5) ./job/acteurs-import.sh ;;
            6) ./job/scrutins-import.sh ;;
            0) return ;;
            *) echo "⚠️ Invalid option, please try again." ;;
        esac
    done
}

# -----------------------------
# Main Menu
# -----------------------------
while true; do
    echo "=============================================="
    echo " "
    echo "DEPUTEDEX MAIN MENU"
    echo " "
    echo "=============================================="
    echo " "
    echo "1) Run Global Workflow (Download + Parser + Import + Update)"
    echo "2) Run Download All"
    echo "3) Run Parser All"
    echo "4) Run Import All"
    echo "5) Run Update All"
    echo "6) Show Unit Jobs"
    echo "0) Quit"
    echo " "
    echo "=============================================="
    read -p "Select an option: " option

    case $option in
        1)
            echo "🚀 Running Global Workflow..."
            run_download_all
            run_parser_all
            run_import_all --auto-cleanup
            run_update_all
            ;;
        2)
            echo "📥 Downloading All data..."
            run_download_all
            ;;
        3)
            echo "🛠 Parsing All..."
            run_parser_all
            ;;
        4)
            echo "📤 Importing All..."
            run_import_all --auto-cleanup
            ;;
        5)
            echo "🔄 Updating All..."
            run_update_all
            ;;
        6)
            unit_job_menu
            ;;
        0)
            echo "Bye!"
            exit 0
            ;;
        *)
            echo "⚠️ Invalid option, please try again."
            ;;
    esac

    echo "=============================================="
    echo "✓ Done"
    echo "=============================================="
done
