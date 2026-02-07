import * as fs from 'fs';
import * as path from 'path';
import * as readline from 'readline';

async function splitJsonFile(inputFile: string, maxSizeMB: number): Promise<void> {
    const maxSizeBytes = maxSizeMB * 1024 * 1024;
    const baseName = path.basename(inputFile, '.json');
    const dirName = path.dirname(inputFile);

    let partNumber = 1;
    let currentSize = 0;

    const createNewPart = (): fs.WriteStream => {
        const partFile = path.join(dirName, `${baseName}_part${partNumber}.json`);
        const stream = fs.createWriteStream(partFile);
        console.log(partFile); // Pour le script bash
        partNumber++;
        currentSize = 0;
        return stream;
    };

    let outputStream = createNewPart();

    // Lire ligne par ligne
    const fileStream = fs.createReadStream(inputFile);
    const rl = readline.createInterface({
        input: fileStream,
        crlfDelay: Infinity
    });

    for await (const line of rl) {
        if (!line.trim()) continue;
        const lineSize = Buffer.byteLength(line + '\n', 'utf8');

        if (currentSize + lineSize > maxSizeBytes && currentSize > 0) {
            outputStream.end();
            outputStream = createNewPart();
        }

        outputStream.write(line + '\n');
        currentSize += lineSize;
    }

    outputStream.end();
}

// Récupérer les arguments
const [inputFile, maxSizeMB] = process.argv.slice(2);

if (!inputFile || !maxSizeMB) {
    console.error('Usage: ts-node json-splitter.ts <input-file> <max-size-mb>');
    process.exit(1);
}

splitJsonFile(inputFile, parseInt(maxSizeMB))
    .catch(err => {
        console.error('❌ Split error:', err.message);
        process.exit(1);
    });