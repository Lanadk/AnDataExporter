#!/usr/bin/env ts-node

import * as path from 'path';
import {DirectorySource} from "./batch/FileSource";
import {ActeursExtractor} from "./batch/JSONextractors/domains/ActeursExtractor";
import {BatchProcessor} from "./batch/BatchProcessor";
import {VotesExtractor} from "./batch/JSONextractors/domains/VotesExtractor";

async function main() {
    const baseDataDir = path.resolve('./data');
    const baseExportDir = path.resolve('./exports');
    const separateDir = path.join(baseExportDir, 'tables');

    // -------- Acteurs -------- //
    const acteursSource = new DirectorySource(path.join(baseDataDir, 'acteurs'));
    const acteursExtractor = new ActeursExtractor();
    const acteursBatch = new BatchProcessor(acteursSource, acteursExtractor);

    await acteursBatch.run();

    const acteursCompleteFile = path.join(baseExportDir, 'acteurs-complete.json');
    acteursBatch.exportToJSON(acteursCompleteFile);
    acteursBatch.exportSeparateFiles(separateDir);
    console.log('✓ Acteurs exportés\n');
    // -------- FIN Acteurs -------- //

    // -------- Votes -------- //
    const votesSource = new DirectorySource(path.join(baseDataDir, 'votes'));
    const votesExtractor = new VotesExtractor();
    const votesBatch = new BatchProcessor(votesSource, votesExtractor);

    await votesBatch.run();

    const votesCompleteFile = path.join(baseExportDir, 'votes-complete.json');
    acteursBatch.exportToJSON(votesCompleteFile);
    acteursBatch.exportSeparateFiles(separateDir);
    console.log('✓ Votes exportés\n');
    // -------- FIN Votes -------- //

    console.log('🎉 Tous les extractors ont terminé !');
}

main();
