-- data
DROP TABLE IF EXISTS deputes CASCADE;
DROP TABLE IF EXISTS groupes_parlementaires CASCADE;
DROP TABLE IF EXISTS scrutins CASCADE;
DROP TABLE IF EXISTS scrutins_groupes CASCADE;
DROP TABLE IF EXISTS votes_deputes CASCADE;
DROP TABLE IF EXISTS scrutins_agregats CASCADE;
DROP TABLE IF EXISTS scrutins_groupes_agregats CASCADE;

-- raw
DROP TABLE IF EXISTS deputes_raw CASCADE;
DROP TABLE IF EXISTS groupes_parlementaires_raw CASCADE;
DROP TABLE IF EXISTS scrutins_raw CASCADE;
DROP TABLE IF EXISTS scrutins_groupes_raw CASCADE;
DROP TABLE IF EXISTS votes_deputes_raw CASCADE;
DROP TABLE IF EXISTS scrutins_agregats_raw CASCADE;
DROP TABLE IF EXISTS scrutins_groupes_agregats_raw CASCADE;



CREATE TABLE deputes (
                         id VARCHAR(50) PRIMARY KEY,
                         created_at TIMESTAMP DEFAULT NOW(),
                         updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE deputes_raw (
                             data JSONB NOT NULL
);

CREATE TABLE groupes_parlementaires (
                                        id VARCHAR(50) PRIMARY KEY,
                                        nom VARCHAR(255),
                                        created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE groupes_parlementaires_raw (
                                            data JSONB NOT NULL
);

CREATE TABLE scrutins (
                       uid VARCHAR(50) PRIMARY KEY,
                       numero VARCHAR(10),
                       legislature VARCHAR(10),
                       date_scrutin DATE,
                       titre TEXT,
                       type_scrutin_code VARCHAR(10),
                       type_scrutin_libelle VARCHAR(255),
                       type_majorite TEXT,
                       resultat_code VARCHAR(50),
                       resultat_libelle TEXT,
                       created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE scrutins_raw (
                           data JSONB NOT NULL
);

CREATE TABLE scrutins_groupes (
                               id SERIAL PRIMARY KEY,
                               scrutin_uid VARCHAR(50) NOT NULL REFERENCES scrutins(uid) ON DELETE CASCADE,
                               groupe_id VARCHAR(50) NOT NULL REFERENCES groupes_parlementaires(id),
                               nombre_membres INTEGER,
                               position_majoritaire VARCHAR(50),
                               created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE scrutins_groupes_raw (
                                   data JSONB NOT NULL
);

CREATE TABLE votes_deputes (
                               id SERIAL PRIMARY KEY,
                               scrutin_uid VARCHAR(50) NOT NULL REFERENCES scrutins(uid) ON DELETE CASCADE,
                               depute_id VARCHAR(50) NOT NULL REFERENCES deputes(id),
                               groupe_id VARCHAR(50) REFERENCES groupes_parlementaires(id),
                               mandat_ref VARCHAR(50),
                               position VARCHAR(20) NOT NULL,
                               cause_position VARCHAR(10),
                               par_delegation BOOLEAN,
                               created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE votes_deputes_raw (
                                   data JSONB NOT NULL
);

CREATE TABLE scrutins_agregats (
                                scrutin_uid VARCHAR(50) PRIMARY KEY REFERENCES scrutins(uid) ON DELETE CASCADE,
                                nombre_votants INTEGER,
                                suffrages_exprimes INTEGER,
                                suffrages_requis INTEGER,
                                total_pour INTEGER,
                                total_contre INTEGER,
                                total_abstentions INTEGER,
                                total_non_votants INTEGER,
                                total_non_votants_volontaires INTEGER,
                                created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE scrutins_agregats_raw (
                                    data JSONB NOT NULL
);


CREATE TABLE scrutins_groupes_agregats (
                                        id SERIAL PRIMARY KEY,
                                        scrutin_uid VARCHAR(50) NOT NULL REFERENCES scrutins(uid) ON DELETE CASCADE,
                                        groupe_id VARCHAR(50) NOT NULL REFERENCES groupes_parlementaires(id),
                                        pour INTEGER,
                                        contre INTEGER,
                                        abstentions INTEGER,
                                        non_votants INTEGER,
                                        non_votants_volontaires INTEGER,
                                        created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE scrutins_groupes_agregats_raw (
                                            data JSONB NOT NULL
);
