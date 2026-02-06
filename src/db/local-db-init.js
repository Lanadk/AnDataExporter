#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

// Si les variables ne sont pas déjà définies, charger .env.local
if (!process.env.DB_USER_WRITER && fs.existsSync('.env.local')) {
    dotenv.config({ path: '.env.local' });
    console.log('📄 Variables chargées depuis .env.local');
} else {
    console.log('🌍 Variables d’environnement système utilisées');
}

console.log('🐳 Préparation du script SQL...\n');
// Charger le template SQL
const template = fs.readFileSync(
    path.join(__dirname, '../db/init-db.sql'),
    'utf8'
);

let output = template
    .replace(/\$\{DB_USER_WRITER\}/g, process.env.DB_USER_WRITER)
    .replace(/\$\{DB_PASSWORD_WRITER\}/g, process.env.DB_PASSWORD_WRITER)
    .replace(/\$\{DB_USER_READER\}/g, process.env.DB_USER_READER)
    .replace(/\$\{DB_PASSWORD_READER\}/g, process.env.DB_PASSWORD_READER);
const outputPath = path.join(__dirname, '../db/init-db.generated.sql');
fs.writeFileSync(outputPath, output);

console.log('✅ Script SQL généré\n');
console.log('🐳 Démarrage du container PostgreSQL...\n');

try {
    execSync('docker compose --env-file .env.local up -d', { stdio: 'inherit' });
    console.log('\n✅ Container démarré');
    console.log('⏳ Attente de l\'initialisation de la base...\n');
    fs.unlinkSync(outputPath);
    console.log('🧹 Fichier SQL généré nettoyé\n');
    console.log('✅ Base de données prête\n');
} catch (error) {
    console.error('❌ Erreur:', error.message);
    process.exit(1);
}
