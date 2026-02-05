import https from "https";
import fs from "fs";
import path from "path";
import {items} from "./item";
import {ensureDir, getTargetPath} from "../../../utils/utils";
import {unzipFile} from "../../../utils/unzip";

// Téléchargement d’un fichier
async function downloadFile(url: string, dest: string) {
    if (fs.existsSync(dest)) {
        console.log(`✔ File already exists: ${dest}`);
        return;
    }

    return new Promise<void>((resolve, reject) => {
        const file = fs.createWriteStream(dest);
        https.get(url, (response) => {
            response.pipe(file);
            file.on("finish", () => {
                file.close();
                console.log(`✔ Downloaded: ${dest}`);
                resolve();
            });
        }).on("error", (err) => {
            fs.unlinkSync(dest);
            reject(err);
        });
    });
}

// Script unitaire : ts-node downloadItem.ts <legislature> <type>
async function main() {
    const [,, legislature, type] = process.argv;

    if (!legislature || !type) {
        console.error("Usage: ts-node downloadItem.ts <legislature> <acteurs|scrutins>");
        process.exit(1);
    }

    const item = items.find(i => i.legislature === legislature && i.type === type);

    if (!item) {
        console.error("❌ Item not found");
        process.exit(1);
    }

    const targetDir = getTargetPath(item.legislature, item.status, item.type);
    ensureDir(targetDir);
    const zipPath = path.join(targetDir, item.filename);

    await downloadFile(item.url, zipPath);
    await unzipFile(zipPath, targetDir);
}

main().catch(console.error);
