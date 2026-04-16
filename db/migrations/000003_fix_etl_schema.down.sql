-- Rollback migration 000003
ALTER TABLE etl_log RENAME COLUMN message TO message_erreur;
ALTER TABLE etl_log DROP COLUMN IF EXISTS libelle_pipeline;
ALTER TABLE etl_log ADD COLUMN id_etl_pipeline INTEGER REFERENCES etl_pipeline (id_etl_pipeline) ON DELETE CASCADE;

ALTER TABLE dataset_historique_seance_exercice_import_anomalies
    RENAME COLUMN consommation_eau_ml TO consommation_eau_l;

ALTER TABLE dataset_historique_seance_exercice
    RENAME COLUMN consommation_eau_ml TO consommation_eau_l;
