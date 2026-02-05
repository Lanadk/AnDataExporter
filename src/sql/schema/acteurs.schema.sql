-- data
DROP TABLE IF EXISTS acteurs CASCADE;
DROP TABLE IF EXISTS acteurs_adresses_postales CASCADE;
DROP TABLE IF EXISTS acteurs_adresses_mails CASCADE;
DROP TABLE IF EXISTS acteurs_reseaux_sociaux CASCADE;
DROP TABLE IF EXISTS acteurs_telephones CASCADE;
-- raw
DROP TABLE IF EXISTS acteurs_raw CASCADE;
DROP TABLE IF EXISTS acteurs_adresses_postales_raw CASCADE;
DROP TABLE IF EXISTS acteurs_adresses_mails_raw CASCADE;
DROP TABLE IF EXISTS acteurs_reseaux_sociaux_raw CASCADE;
DROP TABLE IF EXISTS acteurs_telephones_raw CASCADE;

CREATE TABLE acteurs (
                         uid VARCHAR(50) PRIMARY KEY,
                         civilite VARCHAR(10),
                         prenom VARCHAR(100),
                         nom VARCHAR(255),
                         nom_alpha VARCHAR(255),
                         trigramme VARCHAR(10),
                         date_naissance DATE,
                         ville_naissance VARCHAR(255),
                         departement_naissance VARCHAR(255),
                         pays_naissance VARCHAR(255),
                         date_deces DATE,
                         profession_libelle VARCHAR(255),
                         profession_categorie VARCHAR(255),
                         profession_famille VARCHAR(255),
                         uri_hatvp TEXT,
                         created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE acteurs_raw (
                             data JSONB NOT NULL
);

CREATE TABLE acteurs_adresses_postales (
                                           id SERIAL PRIMARY KEY,
                                           acteur_uid VARCHAR(50) NOT NULL REFERENCES acteurs(uid) ON DELETE CASCADE,
                                           uid_adresse VARCHAR(50),
                                           type_code VARCHAR(10),
                                           type_libelle VARCHAR(255),
                                           intitule VARCHAR(255),
                                           numero_rue VARCHAR(50),
                                           nom_rue VARCHAR(255),
                                           complement_adresse VARCHAR(255),
                                           code_postal VARCHAR(10),
                                           ville VARCHAR(255),
                                           created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE acteurs_adresses_postales_raw (
                             data JSONB NOT NULL
);

CREATE TABLE acteurs_adresses_mails (
                                        id SERIAL PRIMARY KEY,
                                        acteur_uid VARCHAR(50) NOT NULL REFERENCES acteurs(uid) ON DELETE CASCADE,
                                        uid_adresse VARCHAR(50),
                                        type_code VARCHAR(10),
                                        type_libelle VARCHAR(255),
                                        email TEXT,
                                        created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE acteurs_adresses_mails_raw (
                                               data JSONB NOT NULL
);

CREATE TABLE acteurs_reseaux_sociaux (
                                         id SERIAL PRIMARY KEY,
                                         acteur_uid VARCHAR(50) NOT NULL REFERENCES acteurs(uid) ON DELETE CASCADE,
                                         uid_adresse VARCHAR(50),
                                         type_code VARCHAR(10),
                                         type_libelle VARCHAR(255),
                                         plateforme VARCHAR(50),
                                         identifiant TEXT,
                                         created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE acteurs_reseaux_sociaux_raw (
                                               data JSONB NOT NULL
);

CREATE TABLE acteurs_telephones (
                                    id SERIAL PRIMARY KEY,
                                    acteur_uid VARCHAR(50) NOT NULL REFERENCES acteurs(uid) ON DELETE CASCADE,
                                    uid_adresse VARCHAR(50),
                                    type_code VARCHAR(10),
                                    type_libelle VARCHAR(255),
                                    adresse_rattachement VARCHAR(50),
                                    numero VARCHAR(50),
                                    created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE acteurs_telephones_raw (
                                               data JSONB NOT NULL
);