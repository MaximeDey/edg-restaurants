-- ============================================================================
-- EDG Restaurants — mise en place de la base Supabase
-- À coller UNE FOIS dans Supabase > SQL Editor > New query > Run.
-- Sans danger si on le relance (les "if not exists" / "or replace" évitent les doublons).
-- ============================================================================

-- ---------- 1. Profils : qui est qui, et combien de restaurants il a payés ----------
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text    not null,
  is_service   boolean not null default false,
  max_restos   int     not null default 1 check (max_restos between 1 and 50),
  created_at   timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Un utilisateur peut LIRE son propre profil, rien d'autre.
-- Aucune règle d'écriture : personne ne peut se donner plus de restaurants depuis l'appli.
-- (Seul toi, depuis ce tableau de bord, peux créer/modifier un profil.)
drop policy if exists "profil_lecture_perso" on public.profiles;
create policy "profil_lecture_perso" on public.profiles
  for select to authenticated
  using (id = (select auth.uid()));

-- ---------- 2. Données de l'appli (équipes, contraintes, plannings sauvegardés) ----------
create table if not exists public.app_data (
  owner      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  key        text not null check (char_length(key) <= 200),
  value      jsonb not null check (pg_column_size(value) < 2000000),
  updated_at timestamptz not null default now(),
  primary key (owner, key)
);

alter table public.app_data enable row level security;

-- Chacun ne voit, n'écrit et ne supprime QUE ses propres lignes.
drop policy if exists "data_select" on public.app_data;
drop policy if exists "data_insert" on public.app_data;
drop policy if exists "data_update" on public.app_data;
drop policy if exists "data_delete" on public.app_data;
create policy "data_select" on public.app_data for select to authenticated using (owner = (select auth.uid()));
create policy "data_insert" on public.app_data for insert to authenticated with check (owner = (select auth.uid()));
create policy "data_update" on public.app_data for update to authenticated using (owner = (select auth.uid())) with check (owner = (select auth.uid()));
create policy "data_delete" on public.app_data for delete to authenticated using (owner = (select auth.uid()));

-- Un visiteur non connecté n'a accès à rien.
revoke all on public.profiles from anon;
revoke all on public.app_data from anon;

-- ---------- 3. Garde-fou : on ne peut pas dépasser le nombre de restaurants payés ----------
-- Un compte client n'a le droit d'écrire que dans ses "emplacements" (slot1 ... slotN, N = max_restos).
-- Le compte Service n'a aucune restriction.
create or replace function public.app_data_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  p public.profiles;
  n int;
begin
  select * into p from public.profiles where id = new.owner;
  if not found then
    raise exception 'Compte non autorisé (aucun profil)';
  end if;

  new.updated_at := now();
  if p.is_service then
    return new;
  end if;

  if new.key = 'restoNames' then
    return new;
  elsif new.key ~ '^mcdo_team_slot[0-9]+$' then
    n := substring(new.key from '^mcdo_team_slot([0-9]+)$')::int;
  elsif new.key ~ '^mcdo_sched_slot[0-9]+_[0-9]{1,2}_[0-9]{4}$' then
    n := substring(new.key from '^mcdo_sched_slot([0-9]+)_')::int;
  else
    raise exception 'Clé non autorisée : %', new.key;
  end if;

  if n < 1 or n > p.max_restos then
    raise exception 'Nombre de restaurants dépassé (% autorisé(s))', p.max_restos;
  end if;
  return new;
end;
$$;

drop trigger if exists app_data_guard_trg on public.app_data;
create trigger app_data_guard_trg
  before insert or update on public.app_data
  for each row execute function public.app_data_guard();

-- ---------- 4. Petit "ping" pour garder le projet éveillé (offre gratuite) ----------
create or replace function public.ping()
returns text
language sql
stable
as $$ select 'ok'::text $$;
grant execute on function public.ping() to anon, authenticated;

-- ============================================================================
-- 5. CRÉATION DES COMPTES (à faire APRÈS avoir ajouté les utilisateurs dans
--    Authentication > Users > Add user, avec "Auto Confirm User" coché).
--    Décommente et adapte les lignes ci-dessous, puis relance seulement ce bloc.
-- ============================================================================

-- Ton compte Service (accès à tout, sans limite) :
-- insert into public.profiles (id, display_name, is_service, max_restos)
-- select id, 'Service', true, 6 from auth.users where email = 'maximedey.pro@gmail.com'
-- on conflict (id) do update set display_name = excluded.display_name, is_service = excluded.is_service, max_restos = excluded.max_restos;

-- Un compte client (ici : GERENAS, 1 restaurant payé) :
-- insert into public.profiles (id, display_name, is_service, max_restos)
-- select id, 'GERENAS', false, 1 from auth.users where email = 'EMAIL_DU_CLIENT@exemple.fr'
-- on conflict (id) do update set display_name = excluded.display_name, max_restos = excluded.max_restos;
