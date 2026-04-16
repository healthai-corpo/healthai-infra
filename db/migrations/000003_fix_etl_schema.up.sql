-- Migration 000003 : alignement schéma DB ↔ modèles ETL
-- Problèmes détectés lors du run-all ETL :
--   1. dataset_historique_seance_exercice : colonne "consommation_eau_l" → "consommation_eau_ml"
--   2. etl_log : remplace la FK id_etl_pipeline par libelle_pipeline (string),
--                renomme message_erreur → message

-- ── 1. dataset_historique_seance_exercice ─────────────────────────────────────
ALTER TABLE dataset_historique_seance_exercice
    RENAME COLUMN consommation_eau_l TO consommation_eau_ml;

-- ── 2. dataset_historique_seance_exercice_import_anomalies ────────────────────
ALTER TABLE dataset_historique_seance_exercice_import_anomalies
    RENAME COLUMN consommation_eau_l TO consommation_eau_ml;

-- ── 3. etl_log ────────────────────────────────────────────────────────────────
-- Supprime la contrainte FK et la colonne id_etl_pipeline
ALTER TABLE etl_log DROP CONSTRAINT IF EXISTS etl_log_id_etl_pipeline_fkey;
ALTER TABLE etl_log DROP COLUMN IF EXISTS id_etl_pipeline;

-- Ajoute libelle_pipeline (nom libre du pipeline, sans FK)
ALTER TABLE etl_log ADD COLUMN IF NOT EXISTS libelle_pipeline VARCHAR(255);

-- Renomme message_erreur → message
ALTER TABLE etl_log RENAME COLUMN message_erreur TO message;
