import fs from "fs";
import path from "path";

export interface FileSource {
    getFiles(): string[];
}

export class DirectorySource implements FileSource {
    constructor(private dir: string) {}

    getFiles(): string[] {
        const files: string[] = [];

        const traverse = (currentDir: string) => {
            const items = fs.readdirSync(currentDir);
            for (const item of items) {
                const fullPath = path.join(currentDir, item);
                const stats = fs.statSync(fullPath);
                if (stats.isDirectory()) {
                    traverse(fullPath);
                } else if (stats.isFile() && item.endsWith('.json')) {
                    files.push(fullPath);
                }
            }
        };

        traverse(this.dir);
        return files;
    }
}

export class MultiDirectorySource implements FileSource {
    constructor(private base: string, private subdirs: string[]) {}

    getFiles(): string[] {
        let allFiles: string[] = [];

        for (const subdir of this.subdirs) {
            const fullPath = path.join(this.base, subdir);
            if (fs.existsSync(fullPath) && fs.statSync(fullPath).isDirectory()) {
                const files = new DirectorySource(fullPath).getFiles();
                allFiles = allFiles.concat(files);
            }
        }

        return allFiles;
    }
}