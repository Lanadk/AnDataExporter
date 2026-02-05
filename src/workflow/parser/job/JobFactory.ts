import * as path from 'path';
import {
    acteursSourceDirectoryName,
    baseInData,
    baseOutData,
    completeJsonActeursFileName, completeJsonScrutinsFileName, outTableDirectoryName, scrutinsSourceDirectoryName
} from "./const";
import {runBatch} from "../batch/runBatch";
import {ActeursExtractor} from "../batch/JsonParser/domains/ActeursExtractor";
import {ScrutinsExtractor} from "../batch/JsonParser/domains/ScrutinsExtractor";


export class JobFactory {
    private baseDataDir: string;
    private baseExportDir: string;

    constructor() {
        // Résolution absolue basée sur l'emplacement du fichier JobFactory.ts
        this.baseDataDir = path.resolve(__dirname, baseInData);
        this.baseExportDir = path.resolve(__dirname, baseOutData);
    }

    async runActeursParser(): Promise<void> {
        return runBatch(this.baseDataDir, this.baseExportDir, {
            sourceDir: acteursSourceDirectoryName,
            extractor: new ActeursExtractor(),
            completeFileName: completeJsonActeursFileName,
            exportTableDir: outTableDirectoryName
        });
    }

    async runScrutinsParser(): Promise<void> {
        return runBatch(this.baseDataDir, this.baseExportDir, {
            sourceDir: scrutinsSourceDirectoryName,
            extractor: new ScrutinsExtractor(),
            completeFileName: completeJsonScrutinsFileName,
            exportTableDir: outTableDirectoryName
        });
    }
}
