-- Migration 000004 : correction types numériques
-- consommation_eau_ml stocke des valeurs en millilitres (ex: 2000 ml)
-- NUMERIC(4,1) max = 999.9 → overflow ; on passe à NUMERIC(8,2)

ALTER TABLE dataset_historique_seance_exercice
    ALTER COLUMN consommation_eau_ml TYPE NUMERIC(8,2);
