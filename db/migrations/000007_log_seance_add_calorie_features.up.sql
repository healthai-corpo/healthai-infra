-- Migration 000007 : ajoute bpm_max et consommation_eau_ml à log_seance.
-- Ces deux champs sont des features du modèle d'estimation des calories : ils sont
-- désormais portés par la séance elle-même (renseignés par le front) plutôt que passés
-- en paramètres à l'endpoint predict-from-session.
-- Nullables : une séance peut exister sans ces mesures (le modèle impute alors par défaut).

ALTER TABLE log_seance
    ADD COLUMN IF NOT EXISTS bpm_max INTEGER,
    ADD COLUMN IF NOT EXISTS consommation_eau_ml NUMERIC(7, 1);
