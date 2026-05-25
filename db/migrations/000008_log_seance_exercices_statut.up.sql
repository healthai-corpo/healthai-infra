-- Migration 000008 : log_seance porte la liste d'exercices (JSON) et un statut.
--   exercices : liste d'exercices d'une séance, stockée en JSONB (multi-exercices).
--   statut    : cycle de vie de la séance — proposee (générée par l'IA, non validée),
--               prevue, en_cours, terminee.
-- Les deux colonnes sont nullables (séances historiques / mono-exercice non concernées).

ALTER TABLE log_seance
    ADD COLUMN IF NOT EXISTS exercices JSONB,
    ADD COLUMN IF NOT EXISTS statut VARCHAR(20);

ALTER TABLE log_seance
    DROP CONSTRAINT IF EXISTS log_seance_statut_check;

ALTER TABLE log_seance
    ADD CONSTRAINT log_seance_statut_check
    CHECK (statut IN ('proposee', 'prevue', 'en_cours', 'terminee'));
