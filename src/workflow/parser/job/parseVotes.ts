#!/usr/bin/env ts-node

import * as path from 'path';
import {
    votesSourceDirectoryName,
    completeJsonVotesFileName,
} from "./const";
import {VotesExtractor} from "../batch/JsonParser/domains/VotesExtractor";
import {runBatch} from "../batch/runBatch";
import {baseInData, baseOutData, outTableDirectoryName} from "./const";

async function main() {
    await runBatch(
        path.resolve(__dirname, baseInData),
        path.resolve(__dirname, baseOutData),
        {
            sourceDir: votesSourceDirectoryName,
            extractor: new VotesExtractor(),
            completeFileName: completeJsonVotesFileName,
            exportTableDir: outTableDirectoryName
        }
    );

    console.log('✓ Votes exportés');
}

main().catch(console.error);
