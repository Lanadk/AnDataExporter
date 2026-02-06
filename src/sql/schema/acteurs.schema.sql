-- raw
DROP TABLE IF EXISTS acteurs_raw CASCADE;
DROP TABLE IF EXISTS acteurs_adresses_postales_raw CASCADE;
DROP TABLE IF EXISTS acteurs_adresses_mails_raw CASCADE;
DROP TABLE IF EXISTS acteurs_reseaux_sociaux_raw CASCADE;
DROP TABLE IF EXISTS acteurs_telephones_raw CASCADE;


CREATE TABLE acteurs_raw (
                             data JSONB NOT NULL
);
CREATE TABLE acteurs_adresses_postales_raw (
                             data JSONB NOT NULL
);
CREATE TABLE acteurs_adresses_mails_raw (
                                               data JSONB NOT NULL
);
CREATE TABLE acteurs_reseaux_sociaux_raw (
                                               data JSONB NOT NULL
);
CREATE TABLE acteurs_telephones_raw (
                                               data JSONB NOT NULL
);