#!/usr/bin/env ts-node

import * as path from 'path';
import {
    scrutinsSourceDirectoryName,
    completeJsonScrutinsFileName,
} from "./const";
import {ScrutinsExtractor} from "../batch/JsonParser/domains/ScrutinsExtractor";
import {runBatch} from "../batch/runBatch";
import {baseInData, baseOutData, outTableDirectoryName} from "./const";

async function main() {
    await runBatch(
        path.resolve(__dirname, baseInData),
        path.resolve(__dirname, baseOutData),
        {
            sourceDir: scrutinsSourceDirectoryName,
            extractor: new ScrutinsExtractor(),
            completeFileName: completeJsonScrutinsFileName,
            exportTableDir: outTableDirectoryName
        }
    );

    console.log('✓ Scrutins exportés');
}

main().catch(console.error);
