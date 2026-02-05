#!/usr/bin/env ts-node

import * as path from 'path';
import {
    acteursSourceDirectoryName, baseInData, baseOutData,
    completeJsonActeursFileName,
    outTableDirectoryName
} from "./const";
import {ActeursExtractor} from "../batch/JsonParser/domains/ActeursExtractor";
import {runBatch} from "../batch/runBatch";

async function main() {
    await runBatch(
        path.resolve(__dirname, baseInData),
        path.resolve(__dirname, baseOutData),
        {
            sourceDir: acteursSourceDirectoryName,
            extractor: new ActeursExtractor(),
            completeFileName: completeJsonActeursFileName,
            exportTableDir: outTableDirectoryName
        }
    );

    console.log('✓ Acteurs exportés');
}

main().catch(console.error);
