import { config } from "dotenv"
import { existsSync } from "fs"
import { PrismaClient } from '../generated/prisma/client'
import { Pool } from 'pg'
import { PrismaPg } from '@prisma/adapter-pg'

if (existsSync('.env.local')) {
    config({ path: '.env.local' })
}

// Créer le pool PostgreSQL
const pool = new Pool({
    connectionString: process.env.DB_URL,
})

// Créer l'adapter
const adapter = new PrismaPg(pool)

// Créer le client Prisma avec l'adapter
const prisma = new PrismaClient({
    adapter,
})

export { prisma }