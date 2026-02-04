#!/usr/bin/env ts-node

import * as path from 'path';
import {DirectorySource} from "../../batch/FileSource";
import {ActeursExtractor} from "../../batch/JSONextractors/domains/ActeursExtractor";
import {BatchProcessor} from "../../batch/BatchProcessor";

async function main() {
    const baseDataDir = path.resolve('../../data');
    const baseExportDir = path.resolve('../../exports');

    const source = new DirectorySource(path.join(baseDataDir, 'acteurs'));
    const extractor = new ActeursExtractor();
    const batch = new BatchProcessor(source, extractor);

    await batch.run();

    // export both
    batch.exportToJSON(path.join(baseExportDir, 'acteurs-complete.json'));
    batch.exportSeparateFiles(path.join(baseExportDir, 'tables'));

    console.log('✓ Acteurs exportés');
}

main().catch(console.error);
