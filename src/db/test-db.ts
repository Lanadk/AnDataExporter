import {prisma} from "../../prisma/prisma";

async function testConnection() {
    console.log('🔌 Testing database connection...\n');

    try {
        await prisma.$connect();
        console.log('✅ Database connected successfully');

        const result = await prisma.$queryRaw`SELECT version()`;
        console.log('✅ Query executed:', result);

        const tables = await prisma.$queryRaw`
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name;
        `;
        console.log(`✅ Found ${(tables as any[]).length} tables in database\n`);
        console.log('\n🎉 All tests passed!');
    } catch (error) {
        console.error('❌ Database connection failed:', error);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
        console.log('\n👋 Disconnected from database');
    }
}

testConnection();