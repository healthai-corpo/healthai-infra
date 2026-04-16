-- ============================================================
-- Rollback — suppression complète du schéma HealthAI
-- ============================================================

-- Tables avec dépendances en premier
DROP TABLE IF EXISTS dataset_historique_seance_exercice_import_anomalies;
DROP TABLE IF EXISTS dataset_recommendations_regime_import_anomalies;
DROP TABLE IF EXISTS exercice_import_anomalies;
DROP TABLE IF EXISTS aliment_import_anomalies;
DROP TABLE IF EXISTS profil_sante_import_anomalies;
DROP TABLE IF EXISTS utilisateur_import_anomalies;

DROP TABLE IF EXISTS etl_log;
DROP TABLE IF EXISTS etl_column_date_constraints;
DROP TABLE IF EXISTS etl_column_numeric_constraints;
DROP TABLE IF EXISTS etl_column_string_constraints;
DROP TABLE IF EXISTS etl_column_mapping;
DROP TABLE IF EXISTS etl_pipeline;

DROP TABLE IF EXISTS dataset_historique_seance_exercice;
DROP TABLE IF EXISTS dataset_recommendations_regime;

DROP TABLE IF EXISTS log_sante;
DROP TABLE IF EXISTS log_seance;
DROP TABLE IF EXISTS log_aliment;

DROP TABLE IF EXISTS profil_sante;
DROP TABLE IF EXISTS aliment;
DROP TABLE IF EXISTS exercice;
DROP TABLE IF EXISTS utilisateur;

-- ENUMs
DROP TYPE IF EXISTS column_type_enum;
DROP TYPE IF EXISTS file_name_variable_enum;
DROP TYPE IF EXISTS file_extension_enum;
