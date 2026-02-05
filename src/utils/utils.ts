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
