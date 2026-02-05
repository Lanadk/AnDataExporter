import {Pool, PoolClient, QueryResult, QueryResultRow} from 'pg';
import { dbConfig } from './config';

// Pool singleton
let poolInstance: Pool | null = null;

/**
 * Récupère ou crée le pool de connexion PostgreSQL
 */
export function getPool(): Pool {
    if (!poolInstance) {
        poolInstance = new Pool(dbConfig);

        // Gestion des erreurs du pool
        poolInstance.on('error', (err) => {
            console.error('❌ Unexpected error on idle client', err);
            process.exit(-1);
        });

        poolInstance.on('connect', () => {
            console.log('✅ New database connection established');
        });
    }

    return poolInstance;
}

/**
 * Ferme le pool de connexion proprement
 */
export async function closePool(): Promise<void> {
    if (poolInstance) {
        await poolInstance.end();
        poolInstance = null;
        console.log('🔌 Database pool closed');
    }
}

/**
 * Fonction helper pour exécuter une requête simple
 */
export async function query<T extends QueryResultRow = any>(text: string, params?: any[]): Promise<QueryResult<T>> {
    const pool = getPool();
    return pool.query<T>(text, params);
}

/**
 * Fonction helper pour exécuter une transaction
 */
export async function transaction<T>(
    callback: (client: PoolClient) => Promise<T>
): Promise<T> {
    const pool = getPool();
    const client = await pool.connect();

    try {
        await client.query('BEGIN');
        const result = await callback(client);
        await client.query('COMMIT');
        return result;
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
}