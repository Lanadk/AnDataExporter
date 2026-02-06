#!/usr/bin/env node

import {execSync} from 'child_process';
import fs from 'fs';
import dotenv from 'dotenv';

function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

function requireEnv(name: string): string {
    const value = process.env[name];
    if (!value) {
        console.error(`❌ Variable d'environnement manquante: ${name}`);
        process.exit(1);
    }
    return value;
}

// Charger .env.local
if (fs.existsSync('.env.local')) {
    dotenv.config({path: '.env.local'});
    console.log('📄 Variables chargées depuis .env.local');
} else {
    console.error('❌ .env.local introuvable');
    process.exit(1);
}

const DB_NAME = requireEnv('DB_NAME');
const DB_USER = requireEnv('DB_USER'); // utilisateur qui a créé la DB
const DB_USER_WRITER = requireEnv('DB_USER_WRITER'); // user prisma writer
const DB_PASSWORD_WRITER = requireEnv('DB_PASSWORD_WRITER');
const DB_USER_READER = requireEnv('DB_USER_READER');
const DB_PASSWORD_READER = requireEnv('DB_PASSWORD_READER');

async function waitForDb(): Promise<void> {
    console.log('⏳ Attente de PostgreSQL...');

    for (let i = 0; i < 30; i++) {
        try {
            execSync(`docker exec deputedex-db pg_isready -U ${DB_USER} -d ${DB_NAME}`, {
                stdio: 'ignore',
            });
            console.log('✅ Base prête');
            return;
        } catch {
            await sleep(1000);
        }
    }
    throw new Error('PostgreSQL ne répond pas');
}

(async () => {
    try {
        console.log('🐳 Démarrage du container PostgreSQL...\n');
        execSync('docker compose --env-file .env.local up -d', {stdio: 'inherit'});
        await waitForDb();

        console.log('👤 Création des utilisateurs et attribution des droits...');

        const sql = `
              DO
              $$
              BEGIN
                IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER_WRITER}') THEN
                  CREATE ROLE ${DB_USER_WRITER} LOGIN PASSWORD '${DB_PASSWORD_WRITER}' CREATEDB;
                END IF;
        
                IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER_READER}') THEN
                  CREATE ROLE ${DB_USER_READER} LOGIN PASSWORD '${DB_PASSWORD_READER}';
                END IF;
              END
              $$;
        
              GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER_WRITER};
              GRANT CONNECT ON DATABASE ${DB_NAME} TO ${DB_USER_READER};
        
              GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USER_WRITER};
              ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER_WRITER};
              ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER_WRITER};
        
              GRANT USAGE ON SCHEMA public TO ${DB_USER_READER};
              GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${DB_USER_READER};
              ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ${DB_USER_READER};
        `;

        execSync(`docker exec -i deputedex-db psql -U ${DB_USER} -d ${DB_NAME}`, {
            input: sql,
            stdio: ['pipe', 'inherit', 'inherit'],
        });

        console.log('✅ Utilisateurs et permissions configurés pour local dev\n');
    } catch (error) {
        console.error('❌ Erreur:', (error as Error).message);
        process.exit(1);
    }
})();
