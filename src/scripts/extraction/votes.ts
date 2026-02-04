#!/usr/bin/env ts-node

import * as path from 'path';
import {DirectorySource} from "../../batch/FileSource";
import {BatchProcessor} from "../../batch/BatchProcessor";
import {VotesExtractor} from "../../batch/JSONextractors/domains/VotesExtractor";

async function main() {
    const baseDataDir = path.resolve('../../data');
    const baseExportDir = path.resolve('../../exports');

    const source = new DirectorySource(path.join(baseDataDir, 'votes'));
    const extractor = new VotesExtractor();
    const batch = new BatchProcessor(source, extractor);

    await batch.run();

    batch.exportToJSON(path.join(baseExportDir, 'votes-complete.json'));
    batch.exportSeparateFiles(path.join(baseExportDir, 'tables'));

    console.log('✓ Votes exportés');
}

main().catch(console.error);
