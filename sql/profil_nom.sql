-- ============================================================================
-- EDG Restaurants : permettre à chaque compte de modifier SON PROPRE nom de compte
-- À exécuter UNE SEULE FOIS dans Supabase > SQL Editor > Run.
-- Sécurité : la fonction ne modifie QUE le nom (display_name) du compte connecté.
-- Le nombre de restaurants (max_restos) et le statut service restent modifiables
-- uniquement par vous depuis ajouter_client.sql.
-- ============================================================================
create or replace function public.set_my_display_name(new_name text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  clean text := left(btrim(regexp_replace(coalesce(new_name,''), '\s+', ' ', 'g')), 40);
begin
  if auth.uid() is null then
    raise exception 'Non connecté';
  end if;
  if char_length(clean) < 2 then
    raise exception 'Nom trop court';
  end if;
  update public.profiles set display_name = clean where id = auth.uid();
  return clean;
end;
$$;

revoke all on function public.set_my_display_name(text) from public, anon;
grant execute on function public.set_my_display_name(text) to authenticated;
