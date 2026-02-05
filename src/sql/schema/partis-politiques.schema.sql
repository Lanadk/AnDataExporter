-- Table de reference pour les partis politiques
CREATE TABLE ref_partis_politiques
(
    id          SERIAL PRIMARY KEY,
    groupe_id   VARCHAR(50) REFERENCES groupes_parlementaires (id),
    libelle     VARCHAR(100) NOT NULL,
    code        VARCHAR(10) NOT NULL,
    created_at  TIMESTAMP DEFAULT NOW(),
    updated_at  TIMESTAMP DEFAULT NOW()
);
