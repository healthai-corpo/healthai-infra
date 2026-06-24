-- Rollback : retire le statut et la liste d'exercices de log_seance.

ALTER TABLE log_seance
    DROP CONSTRAINT IF EXISTS log_seance_statut_check;

ALTER TABLE log_seance
    DROP COLUMN IF EXISTS statut,
    DROP COLUMN IF EXISTS exercices;
