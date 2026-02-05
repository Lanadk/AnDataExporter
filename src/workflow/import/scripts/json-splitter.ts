#!/usr/bin/env ts-node

/**
 * JSON Splitter Utility (TypeScript version)
 *
 * Usage:
 *   ./json-splitter.ts <input-file> <max-size-mb>
 *
 * Example:
 *   ./json-splitter.ts votesDeputes.json 150
 */

import * as fs from 'fs';
import * as path from 'path';

interface SplitResult {
    partFiles: string[];
    totalItems: number;
    totalParts: number;
}

function splitJsonFile(inputFile: string, maxSizeMB: number = 150): SplitResult {
    const maxSizeBytes = maxSizeMB * 1024 * 1024;

    console.error(`📂 Reading ${inputFile}...`);

    if (!fs.existsSync(inputFile)) {
        throw new Error(`File not found: ${inputFile}`);
    }

    // Lire le fichier
    const rawData = fs.readFileSync(inputFile, 'utf-8');
    const data = JSON.parse(rawData);

    if (!Array.isArray(data)) {
        throw new Error(`${inputFile} must contain a JSON array`);
    }

    const totalItems = data.length;
    console.error(`📊 Total items: ${totalItems}`);

    const baseName = path.basename(inputFile, '.json');
    const dirName = path.dirname(inputFile);

    const partFiles: string[] = [];
    let partNum = 0;
    let currentBatch: any[] = [];
    let currentSize = 0;

    for (let idx = 0; idx < totalItems; idx++) {
        const item = data[idx];
        const itemStr = JSON.stringify(item);
        const itemSize = Buffer.byteLength(itemStr, 'utf-8');

        // Si l'ajout de cet item dépasse la limite ET qu'on a déjà des items
        if (currentBatch.length > 0 && (currentSize + itemSize) > maxSizeBytes) {
            // Sauvegarder le batch actuel
            const partFile = path.join(dirName, `${baseName}_part${String(partNum).padStart(3, '0')}.json`).replace(/\\/g, '/');
            fs.writeFileSync(partFile, JSON.stringify(currentBatch, null, 0), 'utf-8');

            partFiles.push(partFile);
            const sizeMB = (currentSize / 1024 / 1024).toFixed(1);
            console.error(`\n✓ Part ${partNum}: ${currentBatch.length} items (${sizeMB}MB)`);

            // Reset
            partNum++;
            currentBatch = [];
            currentSize = 0;
        }

        currentBatch.push(item);
        currentSize += itemSize;

        // Progress
        if ((idx + 1) % 1000 === 0) {
            process.stderr.write(`\r📦 Processing: ${idx + 1} / ${totalItems} items...`);
        }
    }

    process.stderr.write('\r' + ' '.repeat(60) + '\r'); // Clear progress

    // Sauvegarder le dernier batch
    if (currentBatch.length > 0) {
        const partFile = path.join(dirName, `${baseName}_part${String(partNum).padStart(3, '0')}.json`).replace(/\\/g, '/');
        fs.writeFileSync(partFile, JSON.stringify(currentBatch, null, 0), 'utf-8');

        partFiles.push(partFile);
        const sizeMB = (currentSize / 1024 / 1024).toFixed(1);
        console.error(`✓ Part ${partNum}: ${currentBatch.length} items (${sizeMB}MB)`);
    }

    console.error(`✅ Split complete: ${partNum + 1} parts (${totalItems} total items)`);

    return {
        partFiles,
        totalItems,
        totalParts: partNum + 1
    };
}

// CLI Interface
if (require.main === module) {
    const args = process.argv.slice(2);

    if (args.length < 1) {
        console.error('Usage: ./json-splitter.ts <input-file> [max-size-mb]');
        console.error('Example: ./json-splitter.ts votesDeputes.json 150');
        process.exit(1);
    }

    const inputFile = args[0];
    const maxSizeMB = args[1] ? parseInt(args[1], 10) : 150;

    try {
        const result = splitJsonFile(inputFile, maxSizeMB);

        // Output: liste des fichiers créés (pour script bash)
        result.partFiles.forEach(f => console.log(f));
    } catch (error) {
        console.error(`❌ Error: ${(error as Error).message}`);
        process.exit(1);
    }
}

export {splitJsonFile};