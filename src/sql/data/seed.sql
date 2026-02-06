-- ============================================
-- SEED DATA - Données statiques de référence
-- ============================================

-- ============================================
-- LÉGISLATURES
-- ============================================

INSERT INTO param_legislatures (number)
VALUES
    (16),
    (17)
ON CONFLICT (number) DO NOTHING;

-- ============================================
-- LÉGISLATURE COURANTE
-- ============================================

INSERT INTO param_current_legislatures (legislature_id, number)
VALUES (
           (SELECT id FROM param_legislatures WHERE number = 17),
           17
       )
ON CONFLICT (legislature_id) DO UPDATE SET number = EXCLUDED.number;

-- ============================================
-- DOMAINES DE DONNÉES
-- ============================================

INSERT INTO ref_data_domains (code, description)
VALUES
    ('acteurs', 'Personne physique'),
    ('votes', 'Votes et scrutins publics')
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- SOURCES DE DONNÉES - Législature 16
-- ============================================

INSERT INTO param_data_sources (domain_id, legislature_id, download_url, file_name)
VALUES
    (
        (SELECT id FROM ref_data_domains WHERE code = 'acteurs'),
        (SELECT id FROM param_legislatures WHERE number = 16),
        'https://data.assemblee-nationale.fr/static/openData/repository/16/amo/acteurs_mandats_organes_divises/AMO50_acteurs_mandats_organes_divises.json.zip',
        'AMO50_acteurs_mandats_organes_divises.json.zip'
    ),
    (
        (SELECT id FROM ref_data_domains WHERE code = 'votes'),
        (SELECT id FROM param_legislatures WHERE number = 16),
        'https://data.assemblee-nationale.fr/static/openData/repository/16/loi/scrutins/Scrutins.json.zip',
        'Scrutins.json.zip'
    )
ON CONFLICT DO NOTHING;

-- ============================================
-- SOURCES DE DONNÉES - Législature 17
-- ============================================

INSERT INTO param_data_sources (domain_id, legislature_id, download_url, file_name)
VALUES
    (
        (SELECT id FROM ref_data_domains WHERE code = 'acteurs'),
        (SELECT id FROM param_legislatures WHERE number = 17),
        'https://data.assemblee-nationale.fr/static/openData/repository/17/amo/acteurs_mandats_organes_divises/AMO50_acteurs_mandats_organes_divises.json.zip',
        'AMO50_acteurs_mandats_organes_divises.json.zip'
    ),
    (
        (SELECT id FROM ref_data_domains WHERE code = 'votes'),
        (SELECT id FROM param_legislatures WHERE number = 17),
        'https://data.assemblee-nationale.fr/static/openData/repository/17/loi/scrutins/Scrutins.json.zip',
        'Scrutins.json.zip'
    )
ON CONFLICT DO NOTHING;

-- ============================================
-- VÉRIFICATION
-- ============================================

-- Compteurs pour validation
SELECT 'param_legislatures', COUNT(*) FROM param_legislatures
UNION ALL
SELECT 'param_current_legislatures', COUNT(*) FROM param_current_legislatures
UNION ALL
SELECT 'ref_data_domains', COUNT(*) FROM ref_data_domains
UNION ALL
SELECT 'param_data_sources', COUNT(*) FROM param_data_sources;