import * as fs from 'fs';
import * as path from 'path';
import {FileSource} from "./FileSource";
import {formatJsonForImport} from "../../../utils/utils";

export interface Extractor {
    processFile(filePath: string, data?: any): Promise<void> | void;
    getTables(): Record<string, any[]>;
    getErrors(): { file: string; error: string }[];
}

export class BatchProcessor {
    constructor(private source: FileSource, private extractor: Extractor) {}

    // ---- Lancer le batch ----
    async run(): Promise<void> {
        const files = this.source.getFiles();
        console.log(`Found ${files.length} files\nProcessing...\n`);

        for (let i = 0; i < files.length; i++) {
            const file = files[i];
            const percentage = ((i + 1) / files.length * 100).toFixed(1);
            process.stdout.write(`\r[${i + 1}/${files.length}] (${percentage}%) ${path.basename(file).padEnd(50, ' ')}`);

            try {
                await this.extractor.processFile(file);
            } catch (err: any) {
                // L’extractor peut aussi gérer ses propres erreurs
                console.error(`\nError processing ${file}: ${err.message || err}`);
            }
        }

        console.log('\n\nProcessing complete!\n');
    }

    // ---- Export fichier unique ----
    exportToJSON(outputFile: string): void {
        const tables = this.extractor.getTables();
        fs.writeFileSync(outputFile, JSON.stringify(tables, null, 2), 'utf-8');

        console.log('='.repeat(50));
        console.log('EXPORT SUMMARY (JSON UNIQUE)');
        console.log('='.repeat(50));

        for (const [table, data] of Object.entries(tables)) {
            console.log(`${table.padEnd(35)} ${data.length}`);
        }

        console.log('='.repeat(50));

        // Gestion erreurs
        this.exportErrors(outputFile);
    }

    // ---- Export fichiers séparés ----
    exportSeparateFiles(outputDir: string): void {
        if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

        const tables = this.extractor.getTables();
        for (const [table, data] of Object.entries(tables)) {
            const filePath = path.join(outputDir, `${table}.json`);
            formatJsonForImport(data, filePath);
        }

        console.log('='.repeat(50));
        console.log('EXPORT SUMMARY (SEPARATE FILES)');
        console.log('='.repeat(50));
        for (const [table, data] of Object.entries(tables)) {
            console.log(`${table.padEnd(35)} ${data.length}`);
        }
        console.log('='.repeat(50));

        // Gestion erreurs
        this.exportErrors(path.join(outputDir, 'errors.json'));
    }

    // ---- Export erreurs ----
    private exportErrors(basePath: string): void {
        const errors = this.extractor.getErrors();
        if (errors.length === 0) return;

        const errorsPath = basePath.includes('.json')
            ? basePath.replace(/\.json$/, '-errors.json')
            : path.join(basePath, 'errors.json');

        fs.writeFileSync(errorsPath, JSON.stringify(errors, null, 2), 'utf-8');
        console.log(`⚠️  ${errors.length} errors recorded: ${errorsPath}`);
    }
}
