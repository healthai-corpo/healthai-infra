-- Rollback seeds — purge des données de démo
TRUNCATE TABLE log_sante, log_seance, log_aliment CASCADE;
TRUNCATE TABLE profil_sante CASCADE;
TRUNCATE TABLE aliment, exercice CASCADE;
TRUNCATE TABLE utilisateur CASCADE;
