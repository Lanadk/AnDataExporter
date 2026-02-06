import * as fs from 'fs';
import * as path from 'path';
import {prisma} from "../src/db/prisma";

async function main() {
    console.log('🌱 Seeding database...\n');
    const seedSqlPath = path.join(__dirname, '../src/sql/data/seed.sql');

    if (!fs.existsSync(seedSqlPath)) {
        console.error(`❌ seed.sql not found at: ${seedSqlPath}`);
        process.exit(1);
    }
    const seedSql = fs.readFileSync(seedSqlPath, 'utf-8');

    console.log('📄 Executing seed.sql...');
    try {
        await prisma.$executeRawUnsafe(seedSql);
        console.log('🎉 Seeding completed successfully!');
    } catch (error) {
        console.error('❌ Seeding failed:', error);
        throw error;
    }
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });