--Table de parametrage des legislatures
CREATE TABLE param_legislatures
(
    id         SERIAL PRIMARY KEY,
    number     INT NOT NULL UNIQUE,
    start_date DATE,
    end_date   DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

--Table de parametrage de la legislature en cours (une seule ligne possible en base)
CREATE TABLE param_current_legislatures
(
    id             SERIAL PRIMARY KEY,
    legislature_id INT NOT NULL REFERENCES param_legislatures (id),
    number         INT NOT NULL UNIQUE,
    updated_at     TIMESTAMP DEFAULT NOW()
);
CREATE UNIQUE INDEX only_one_row
    ON param_current_legislatures ((true));

-- Table de refentiel des domains métier qu'on exploite
CREATE TABLE ref_data_domains
(
    id          SERIAL PRIMARY KEY,
    code        TEXT NOT NULL UNIQUE,
    description TEXT
);

-- Table de parametrage des sources de données de l'AN
CREATE TABLE param_data_sources
(
    id             SERIAL PRIMARY KEY,
    domain_id      INT  NOT NULL REFERENCES ref_data_domains (id),
    legislature_id INT  NOT NULL REFERENCES param_legislatures (id),
    download_url   TEXT NOT NULL,
    file_name      TEXT NOT NULL,
    created_at     TIMESTAMP DEFAULT NOW(),

    UNIQUE (domain_id, legislature_id)
);

-- Table de monitoring des fichiers téléchargés
CREATE TABLE monitor_data_download
(
    id               SERIAL PRIMARY KEY,
    source_id        INT     NOT NULL REFERENCES param_data_sources (id),
    file_name        TEXT,
    downloaded       BOOLEAN NOT NULL DEFAULT FALSE,
    last_download_at TIMESTAMP,
    checksum         TEXT, -- (SHA pourquoi pas)
    file_size        BIGINT,
    error_message    TEXT,
    updated_at       TIMESTAMP        DEFAULT NOW(),

    UNIQUE (source_id)
);