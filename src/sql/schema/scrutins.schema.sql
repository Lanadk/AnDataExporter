-- raw
DROP TABLE IF EXISTS deputes_raw CASCADE;
DROP TABLE IF EXISTS groupes_parlementaires_raw CASCADE;
DROP TABLE IF EXISTS scrutins_raw CASCADE;
DROP TABLE IF EXISTS scrutins_groupes_raw CASCADE;
DROP TABLE IF EXISTS votes_deputes_raw CASCADE;
DROP TABLE IF EXISTS scrutins_agregats_raw CASCADE;
DROP TABLE IF EXISTS scrutins_groupes_agregats_raw CASCADE;

CREATE TABLE deputes_raw (
                             data JSONB NOT NULL
);
CREATE TABLE groupes_parlementaires_raw (
                                            data JSONB NOT NULL
);

CREATE TABLE scrutins_raw (
                           data JSONB NOT NULL
);

CREATE TABLE scrutins_groupes_raw (
                                   data JSONB NOT NULL
);

CREATE TABLE votes_deputes_raw (
                                   data JSONB NOT NULL
);

CREATE TABLE scrutins_agregats_raw (
                                    data JSONB NOT NULL
);

CREATE TABLE scrutins_groupes_agregats_raw (
                                            data JSONB NOT NULL
);
