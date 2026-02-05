import fs from "fs";
import https from "https";
import path from "path";
import {ensureDir, getTargetPath} from "../../utils/utils";
import {items} from "./scripts/item";
import {unzipFile} from "../../utils/unzip";


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

async function main() {
    console.log("Starting Download Job");
    for (const item of items) {
        const targetDir = getTargetPath(item.legislature, item.status, item.type);
        ensureDir(targetDir);
        const zipPath = path.join(targetDir, item.filename);
        await downloadFile(item.url, zipPath);
        await unzipFile(zipPath, targetDir);
    }
    console.log("Ending Download Job");
}

main().catch(console.error);
