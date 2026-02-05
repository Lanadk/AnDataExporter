import fs from "fs";
import unzipper from "unzipper";

export async function unzipFile(zipPath: string, targetDir: string) {
    if (!fs.existsSync(zipPath)) {
        throw new Error(`Zip file does not exist: ${zipPath}`);
    }

    await fs.createReadStream(zipPath)
        .pipe(unzipper.Extract({ path: targetDir }))
        .promise();

    console.log(`✔ Unzipped: ${zipPath} → ${targetDir}`);
}
