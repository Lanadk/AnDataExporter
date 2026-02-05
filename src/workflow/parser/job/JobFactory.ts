import * as path from 'path';
import {
    acteursSourceDirectoryName,
    baseInData,
    baseOutData,
    completeJsonActeursFileName, completeJsonVotesFileName, outTableDirectoryName, votesSourceDirectoryName
} from "./const";
import {runBatch} from "../batch/runBatch";
import {ActeursExtractor} from "../batch/JsonParser/domains/ActeursExtractor";
import {VotesExtractor} from "../batch/JsonParser/domains/VotesExtractor";


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

    async runVotesParser(): Promise<void> {
        return runBatch(this.baseDataDir, this.baseExportDir, {
            sourceDir: votesSourceDirectoryName,
            extractor: new VotesExtractor(),
            completeFileName: completeJsonVotesFileName,
            exportTableDir: outTableDirectoryName
        });
    }
}
