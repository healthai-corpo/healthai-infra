-- Rollback : restaure la contrainte NOT NULL sur log_seance.calorie_brulee.
-- Échouera si des lignes ont calorie_brulee = NULL (les renseigner avant rollback).

ALTER TABLE log_seance
    ALTER COLUMN calorie_brulee SET NOT NULL;
