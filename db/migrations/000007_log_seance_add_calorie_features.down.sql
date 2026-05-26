-- Rollback : retire bpm_max et consommation_eau_ml de log_seance.

ALTER TABLE log_seance
    DROP COLUMN IF EXISTS bpm_max,
    DROP COLUMN IF EXISTS consommation_eau_ml;
