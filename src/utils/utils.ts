import fs from "fs";
import path from "path";

/**
 * Crée un dossier si nécessaire
 */
export function ensureDir(dirPath: string) {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
        console.log(`✔ Created directory: ${dirPath}`);
    }
}

/**
 * Retourne le chemin complet pour une législature / type de fichier
 */
export function getTargetPath(
    legislature: string,
    status: "archive" | "current",
    type: "acteurs" | "scrutins",
    filename: string = ""
) {
    const base = path.join(
        __dirname,
        "..",
        "data",
        "assemblee-nationale",
        status,
        `legislature_${legislature}`,
        type
    );
    return filename ? path.join(base, filename) : base;
}

/**
 * Logger simple
 */
export function log(msg: string) {
    console.log(`📌 ${msg}`);
}


/**
 * Formate un tableau JSON pour un import PostgreSQL safe
 * - Chaque objet sur une ligne (NDJSON)
 * - UTF-8 encodé
 * - Caractères spéciaux échappés
 */
export function formatJsonForImport(data: any[], outputFile: string): void {
    const stream = fs.createWriteStream(outputFile, { encoding: 'utf-8' });

    for (const obj of data) {
        // JSON.stringify encode automatiquement les quotes et les \n
        stream.write(JSON.stringify(obj) + '\n');
    }

    stream.end();
    console.log(`✅ Formatted ${data.length} records for import: ${outputFile}`);
}
