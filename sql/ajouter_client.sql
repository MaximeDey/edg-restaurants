-- ============================================================================
-- EDG Restaurants : gérer les comptes clients
-- Prérequis : le client existe déjà dans Authentication > Users (Auto Confirm User coché).
-- Remplace les valeurs EN MAJUSCULES, puis exécute UN SEUL bloc à la fois (Run).
-- ============================================================================

-- A) CRÉER ou METTRE À JOUR un client (nombre de restaurants payés)
insert into public.profiles (id, display_name, is_service, max_restos)
select id, 'NOM_DU_COMPTE', false, 1          -- 1 = nombre de restaurants payés
from auth.users where email = 'EMAIL_DU_CLIENT@exemple.fr'
on conflict (id) do update
  set display_name = excluded.display_name,
      max_restos   = excluded.max_restos;

-- B) CONTRÔLER tous les comptes
select p.display_name, p.max_restos, p.is_service, u.email, u.email_confirmed_at, u.banned_until
from public.profiles p join auth.users u on u.id = p.id
order by p.created_at;

-- C) SUSPENDRE un client (données conservées, connexion bloquée)
update auth.users set banned_until = 'infinity' where email = 'EMAIL_DU_CLIENT@exemple.fr';

-- D) RÉACTIVER un client suspendu
update auth.users set banned_until = null where email = 'EMAIL_DU_CLIENT@exemple.fr';

-- E) SUPPRIMER définitivement un client et toutes ses données (IRRÉVERSIBLE)
--    À faire seulement après restitution des données au client (contrat, article 7).
delete from auth.users where email = 'EMAIL_DU_CLIENT@exemple.fr';
