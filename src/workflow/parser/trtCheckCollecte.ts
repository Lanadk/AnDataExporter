#!/usr/bin/env ts-node

import {JobFactory} from "./job/JobFactory";

async function main() {
    const jobFactory = new JobFactory();

    await jobFactory.runActeursParser();
    await jobFactory.runScrutinsParser();

    console.log('🎉 Tous les extractors ont terminé !');
}

main().catch(console.error);
