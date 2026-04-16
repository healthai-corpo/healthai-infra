-- Migration 000005 : adherence_regime max value = 100.0
-- NUMERIC(4,2) max = 99.99 → overflow sur 100.00
-- NUMERIC(5,2) max = 999.99 → ok

ALTER TABLE dataset_recommendations_regime
    ALTER COLUMN adherence_regime TYPE NUMERIC(5,2);
