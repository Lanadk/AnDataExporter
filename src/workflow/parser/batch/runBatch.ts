import * as path from 'path';
import {DirectorySource} from "./FileSource";
import {BatchProcessor, Extractor} from "./BatchProcessor";


export interface BatchConfig<TExtractor extends Extractor> {
    sourceDir: string;
    extractor: TExtractor;
    completeFileName: string;
    exportTableDir: string;
}

export async function runBatch<TExtractor extends Extractor>
(
    baseDataDir: string,
    baseExportDir: string,
    config: BatchConfig<TExtractor>
) {
    const source = new DirectorySource(
        path.join(baseDataDir, config.sourceDir)
    );

    const batch = new BatchProcessor(source, config.extractor);

    console.log('Starting job')
    await batch.run();

    /*
        batch.exportToJSON(
            path.join(baseExportDir, config.completeFileName)
        );
    */

    batch.exportSeparateFiles(
        path.join(baseExportDir, config.exportTableDir)
    );
}
