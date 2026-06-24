-- Migration 000006 : log_seance.calorie_brulee devient nullable
-- Une séance peut être enregistrée par le front avant que le service IA
-- (endpoint predict-from-session) n'estime et ne renseigne les calories brûlées.
-- NB : ne concerne PAS dataset_historique_seance_exercice.calories_brulees
-- (table d'entraînement de l'IA, qui reste NOT NULL).

ALTER TABLE log_seance
    ALTER COLUMN calorie_brulee DROP NOT NULL;
