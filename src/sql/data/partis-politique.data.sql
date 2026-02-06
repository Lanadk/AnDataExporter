INSERT INTO ref_partis_politiques (groupe_id, libelle, code)
SELECT * FROM (VALUES
                   ('PO800484', 'Démocrate (MoDem et Indépendants)', 'DEM'),
                   ('PO800526', 'Écologiste - NUPES', 'ECOLO'),
                   ('PO800502', 'Gauche démocrate et républicaine - NUPES', 'GDR-NUPES'),
                   ('PO800514', 'Horizons et apparentés', 'HOR'),
                   ('PO800490', 'La France insoumise - NUPES', 'LFI-NUPES'),
                   ('PO800508', 'Les Républicains', 'LR'),
                   ('PO800532', 'Libertés, Indépendants, Outre-mer et Territoires', 'LIOT'),
                   ('PO800520', 'Rassemblement National', 'RN'),
                   ('PO800538', 'Renaissance', 'RE'),
                   ('PO800496', 'Socialistes et apparentés - NUPES', 'SOC-NUPES'),
                   (NULL, 'Ensemble pour la République', 'EPR'),
                   (NULL, 'La France insoumise - NFP', 'LFI-NFP'),
                   (NULL, 'Socialistes et apparentés', 'SOC'),
                   (NULL, 'Droite Républicaine', 'DR'),
                   (NULL, 'Écologiste et Social', 'ECOS'),
                   (NULL, 'Les Démocrates', 'DEM-2'),
                   (NULL, 'Horizons & Indépendants', 'HOR-2'),
                   (NULL, 'Gauche Démocrate et Républicaine', 'GDR'),
                   (NULL, 'Union des droites pour la République', 'UDDPLR'),
                   (NULL, 'Non inscrits', 'NI')
              ) AS v(groupe_id, libelle, code)
WHERE NOT EXISTS (
    SELECT 1 FROM ref_partis_politiques
    WHERE ref_partis_politiques.code = v.code
);