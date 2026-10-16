-- Colloc — schéma Supabase (colocation étudiante, Burkina Faso).
--
-- Ce projet Supabase est PARTAGÉ avec d'autres applications (Telima, etc.) : tout ce que crée Colloc est préfixé `coloc_`,
-- et on ne crée AUCUN déclencheur sur auth.users (le profil Colloc est créé par l'app via coloc_ensure_profile).
-- Migration additive : elle ne modifie ni ne supprime rien d'existant.

-- ───────────── tables ─────────────
create table public.coloc_profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null,
  phone text,
  role text not null default 'student' check (role in ('student','agency','admin')),
  agency_name text,
  created_at timestamptz not null default now()
);

create table public.coloc_listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users on delete cascade,
  owner_name text not null,
  owner_role text not null check (owner_role in ('student','agency','admin')),
  kind text not null check (kind in ('offer','request','agency')),
  title text not null,
  city text not null,
  neighborhood text,
  description text,
  rent integer not null default 0 check (rent >= 0),
  caution integer not null default 0 check (caution >= 0),
  service_fee integer not null default 0 check (service_fee >= 0),
  spots integer not null default 1 check (spots between 1 and 99),
  house_state text check (house_state in ('neuf','bon','arafraichir')),
  conditions text,
  photos text[] not null default '{}',
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create index coloc_listings_active_created on public.coloc_listings (active, created_at desc);
create index coloc_listings_city on public.coloc_listings (city);

-- Avis de paiement de mise en contact (1 000 FCFA). Paiement manuel : l'utilisateur envoie l'argent en Mobile Money
-- puis émet un avis ; l'administrateur vérifie et valide => le numéro de l'annonceur est débloqué.
create table public.coloc_contact_unlocks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  listing_id uuid not null references public.coloc_listings on delete cascade,
  amount integer not null default 1000,
  method text not null,
  payer_phone text not null,
  reference text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  reviewed_by uuid references auth.users,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, listing_id)
);

-- Réglages publics : numéros Mobile Money (payment_methods) et design choisi par l'admin (theme).
create table public.coloc_app_settings (key text primary key, value jsonb not null);

-- Flyers du slider d'accueil, gérés par l'administrateur depuis l'app.
create table public.coloc_promos (
  id uuid primary key default gen_random_uuid(),
  title text not null default '',
  subtitle text not null default '',
  image_url text,
  link_url text,
  color_a text not null default '0F766E',
  color_b text not null default '14B8A6',
  sponsor boolean not null default false,
  sort integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Statistiques de fréquentation (anonymes : identifiant aléatoire stocké dans le navigateur/l'appareil).
create table public.coloc_events (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  visitor_id text not null,
  session_id text not null,
  user_id uuid,
  type text not null,
  screen text,
  listing_id uuid,
  promo_id uuid,
  query text,
  city text,
  device text
);
create index coloc_events_created on public.coloc_events (created_at);
create index coloc_events_type on public.coloc_events (type, created_at);

-- ───────────── fonctions ─────────────
create function public.coloc_is_admin() returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from coloc_profiles where id = auth.uid() and role = 'admin')
$$;

-- Crée (ou complète) le profil Colloc de l'utilisateur connecté. Le rôle admin ne peut pas être demandé ici.
create function public.coloc_ensure_profile(p_name text, p_phone text, p_role text, p_agency text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  insert into coloc_profiles (id, name, phone, role, agency_name)
  values (auth.uid(), coalesce(nullif(trim(p_name), ''), 'Utilisateur'), nullif(trim(coalesce(p_phone, '')), ''),
          case when p_role = 'agency' then 'agency' else 'student' end, nullif(trim(coalesce(p_agency, '')), ''))
  on conflict (id) do update set
    name = coalesce(nullif(trim(p_name), ''), coloc_profiles.name),
    phone = coalesce(nullif(trim(coalesce(p_phone, '')), ''), coloc_profiles.phone);
end $$;

create function public.coloc_update_phone(p_phone text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if length(trim(coalesce(p_phone, ''))) < 8 then raise exception 'Numéro invalide.'; end if;
  update coloc_profiles set phone = trim(p_phone) where id = auth.uid();
end $$;

-- Contacts débloqués par l'utilisateur courant (le téléphone n'est jamais exposé autrement).
create function public.coloc_my_unlocked_contacts()
returns table (listing_id uuid, name text, phone text, at timestamptz)
language sql security definer set search_path = public stable as $$
  select u.listing_id, l.owner_name, p.phone, u.reviewed_at
  from coloc_contact_unlocks u
  join coloc_listings l on l.id = u.listing_id
  join coloc_profiles p on p.id = l.owner_id
  where u.user_id = auth.uid() and u.status = 'approved'
  order by u.reviewed_at desc
$$;

-- Émission d'un avis de paiement (statut pending). Un avis refusé peut être ré-émis.
create function public.coloc_request_unlock(p_listing uuid, p_method text, p_phone text, p_reference text)
returns uuid language plpgsql security definer set search_path = public as $$
declare lst coloc_listings; cur coloc_contact_unlocks; new_id uuid;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  select * into lst from coloc_listings where id = p_listing and active;
  if not found then raise exception 'Annonce introuvable.'; end if;
  if lst.owner_id = auth.uid() then raise exception 'C''est votre propre annonce.'; end if;
  if length(trim(coalesce(p_phone, ''))) < 8 then raise exception 'Numéro invalide.'; end if;
  select * into cur from coloc_contact_unlocks where user_id = auth.uid() and listing_id = p_listing;
  if found and cur.status <> 'rejected' then raise exception 'Un avis existe déjà pour cette annonce.'; end if;
  if found then
    update coloc_contact_unlocks set status = 'pending', method = p_method, payer_phone = p_phone, reference = p_reference,
      reviewed_by = null, reviewed_at = null, created_at = now() where id = cur.id returning id into new_id;
  else
    insert into coloc_contact_unlocks (user_id, listing_id, method, payer_phone, reference)
    values (auth.uid(), p_listing, p_method, p_phone, p_reference) returning id into new_id;
  end if;
  return new_id;
end $$;

create function public.coloc_my_payments()
returns table (id uuid, listing_id uuid, listing_title text, method text, payer_phone text, reference text,
               status text, amount integer, created_at timestamptz)
language sql security definer set search_path = public stable as $$
  select u.id, u.listing_id, l.title, u.method, u.payer_phone, u.reference, u.status, u.amount, u.created_at
  from coloc_contact_unlocks u join coloc_listings l on l.id = u.listing_id
  where u.user_id = auth.uid() order by u.created_at desc
$$;

-- Réservé aux administrateurs (coloc_profiles.role = 'admin', à positionner à la main).
create function public.coloc_admin_payments()
returns table (id uuid, listing_id uuid, listing_title text, payer_name text, method text, payer_phone text,
               reference text, status text, amount integer, created_at timestamptz)
language plpgsql security definer set search_path = public stable as $$
begin
  if not coloc_is_admin() then raise exception 'Réservé à l''administrateur.'; end if;
  return query
    select u.id, u.listing_id, l.title, p.name, u.method, u.payer_phone, u.reference, u.status, u.amount, u.created_at
    from coloc_contact_unlocks u join coloc_listings l on l.id = u.listing_id
    left join coloc_profiles p on p.id = u.user_id
    order by (u.status = 'pending') desc, u.created_at desc;
end $$;

create function public.coloc_admin_review_payment(p_id uuid, p_approve boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not coloc_is_admin() then raise exception 'Réservé à l''administrateur.'; end if;
  update coloc_contact_unlocks set status = case when p_approve then 'approved' else 'rejected' end,
    reviewed_by = auth.uid(), reviewed_at = now() where id = p_id;
end $$;

-- Design choisi par l'administrateur (lisible par tous via coloc_app_settings, écrit seulement ici).
create function public.coloc_admin_set_theme(p_value jsonb) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not coloc_is_admin() then raise exception 'Réservé à l''administrateur.'; end if;
  insert into coloc_app_settings (key, value) values ('theme', p_value)
  on conflict (key) do update set value = excluded.value;
end $$;

-- Enregistrement d'une action de visiteur (appelable sans compte).
create function public.coloc_track(p_visitor text, p_session text, p_type text, p_screen text default null,
  p_listing uuid default null, p_promo uuid default null, p_query text default null, p_city text default null,
  p_device text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_type not in ('view','listing_view','search','filter_city','contact_click','payment_notice','signup','login','promo_view','promo_click') then
    return;
  end if;
  if length(coalesce(p_visitor, '')) not between 6 and 64 or length(coalesce(p_session, '')) not between 6 and 64 then return; end if;
  insert into coloc_events (visitor_id, session_id, user_id, type, screen, listing_id, promo_id, query, city, device)
  values (p_visitor, p_session, auth.uid(), p_type, left(p_screen, 40), p_listing, p_promo, left(p_query, 80), left(p_city, 60),
          case when p_device in ('mobile','desktop') then p_device else null end);
end $$;

-- Tableau de bord admin : visiteurs, comportement, entonnoir, classements.
create function public.coloc_admin_stats(p_days integer default 14) returns jsonb
language plpgsql security definer set search_path = public stable as $$
declare
  d integer := greatest(1, least(coalesce(p_days, 14), 90));
  today_ts timestamptz := date_trunc('day', now());
  from_ts timestamptz := date_trunc('day', now()) - ((greatest(1, least(coalesce(p_days, 14), 90)) - 1) * interval '1 day');
  r jsonb;
begin
  if not coloc_is_admin() then raise exception 'Réservé à l''administrateur.'; end if;
  with ev as (select * from coloc_events where created_at >= from_ts),
  agg as (
    select count(distinct session_id) as sessions,
           count(*) filter (where type in ('view','listing_view')) as page_views,
           count(*) filter (where type = 'listing_view') as listing_views,
           count(*) filter (where type = 'search') as searches,
           count(*) filter (where type = 'contact_click') as contact_clicks,
           count(*) filter (where type = 'payment_notice') as payment_notices,
           count(*) filter (where type = 'signup') as signups,
           count(*) filter (where type = 'promo_view') as promo_views,
           count(*) filter (where type = 'promo_click') as promo_clicks,
           count(distinct visitor_id) as f_visitors,
           count(distinct visitor_id) filter (where type = 'listing_view') as f_listing,
           count(distinct visitor_id) filter (where type = 'contact_click') as f_contact,
           count(distinct visitor_id) filter (where type = 'payment_notice') as f_notice
    from ev
  )
  select jsonb_build_object(
    'visitors_today', (select count(distinct visitor_id) from coloc_events where created_at >= today_ts),
    'visitors_7', (select count(distinct visitor_id) from coloc_events where created_at >= today_ts - interval '6 days'),
    'visitors_30', (select count(distinct visitor_id) from coloc_events where created_at >= today_ts - interval '29 days'),
    'sessions', a.sessions, 'page_views', a.page_views, 'listing_views', a.listing_views, 'searches', a.searches,
    'contact_clicks', a.contact_clicks, 'payment_notices', a.payment_notices, 'signups', a.signups,
    'promo_views', a.promo_views, 'promo_clicks', a.promo_clicks,
    'approved', (select count(*) from coloc_contact_unlocks where status = 'approved'),
    'screens_per_session', round(a.page_views::numeric / nullif(a.sessions, 0), 2),
    'funnel_visitors', a.f_visitors, 'funnel_listing', a.f_listing, 'funnel_contact', a.f_contact, 'funnel_notice', a.f_notice,
    'daily', coalesce((
      select jsonb_agg(jsonb_build_object('day', g::date, 'visitors', coalesce(v.vis, 0), 'views', coalesce(v.vw, 0)) order by g)
      from generate_series(from_ts::date, today_ts::date, interval '1 day') g
      left join (select created_at::date as dd, count(distinct visitor_id) as vis,
                        count(*) filter (where type in ('view','listing_view')) as vw from ev group by 1) v on v.dd = g::date
    ), '[]'::jsonb),
    'top_listings', coalesce((
      select jsonb_agg(jsonb_build_object('label', t.title, 'a', t.views, 'b', t.contacts) order by t.views desc)
      from (select l.title, count(*) filter (where e.type = 'listing_view') as views, count(*) filter (where e.type = 'contact_click') as contacts
            from ev e join coloc_listings l on l.id = e.listing_id where e.type in ('listing_view','contact_click')
            group by l.title order by views desc limit 5) t
    ), '[]'::jsonb),
    'top_searches', coalesce((
      select jsonb_agg(jsonb_build_object('label', t.q, 'a', t.n) order by t.n desc)
      from (select lower(query) as q, count(*) as n from ev where type = 'search' and query is not null group by 1 order by n desc limit 5) t
    ), '[]'::jsonb),
    'top_cities', coalesce((
      select jsonb_agg(jsonb_build_object('label', t.city, 'a', t.n) order by t.n desc)
      from (select city, count(*) as n from ev where type = 'filter_city' and city is not null group by 1 order by n desc limit 6) t
    ), '[]'::jsonb),
    'top_promos', coalesce((
      select jsonb_agg(jsonb_build_object('label', t.title, 'a', t.views, 'b', t.clicks) order by t.views desc)
      from (select pr.title, count(*) filter (where e.type = 'promo_view') as views, count(*) filter (where e.type = 'promo_click') as clicks
            from ev e join coloc_promos pr on pr.id = e.promo_id where e.type in ('promo_view','promo_click')
            group by pr.title order by views desc limit 6) t
    ), '[]'::jsonb),
    'devices', coalesce((
      select jsonb_agg(jsonb_build_object('label', case t.device when 'mobile' then 'Mobile' else 'Ordinateur' end, 'a', t.n))
      from (select device, count(distinct visitor_id) as n from ev where device is not null group by 1) t
    ), '[]'::jsonb)
  ) into r
  from agg a;
  return r;
end $$;

-- ───────────── droits ─────────────
revoke all on function
  public.coloc_is_admin(), public.coloc_ensure_profile(text, text, text, text), public.coloc_update_phone(text),
  public.coloc_my_unlocked_contacts(), public.coloc_request_unlock(uuid, text, text, text), public.coloc_my_payments(),
  public.coloc_admin_payments(), public.coloc_admin_review_payment(uuid, boolean), public.coloc_admin_set_theme(jsonb),
  public.coloc_track(text, text, text, text, uuid, uuid, text, text, text), public.coloc_admin_stats(integer)
from public, anon, authenticated;
grant execute on function
  public.coloc_is_admin(), public.coloc_ensure_profile(text, text, text, text), public.coloc_update_phone(text),
  public.coloc_my_unlocked_contacts(), public.coloc_request_unlock(uuid, text, text, text), public.coloc_my_payments(),
  public.coloc_admin_payments(), public.coloc_admin_review_payment(uuid, boolean), public.coloc_admin_set_theme(jsonb),
  public.coloc_admin_stats(integer)
to authenticated;
grant execute on function public.coloc_track(text, text, text, text, uuid, uuid, text, text, text) to anon, authenticated;

-- ───────────── RLS ─────────────
alter table public.coloc_profiles enable row level security;
alter table public.coloc_listings enable row level security;
alter table public.coloc_contact_unlocks enable row level security;
alter table public.coloc_app_settings enable row level security;
alter table public.coloc_promos enable row level security;
alter table public.coloc_events enable row level security;

create policy "coloc profil: lecture du sien" on public.coloc_profiles for select to authenticated using (id = auth.uid());

create policy "coloc annonces: lecture publique des actives" on public.coloc_listings for select using (active or owner_id = auth.uid());
create policy "coloc annonces: création par le propriétaire" on public.coloc_listings for insert to authenticated
  with check (
    owner_id = auth.uid()
    and (kind <> 'agency' or exists (select 1 from public.coloc_profiles p where p.id = auth.uid() and p.role = 'agency'))
  );
create policy "coloc annonces: modification par le propriétaire" on public.coloc_listings for update to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "coloc annonces: suppression par le propriétaire" on public.coloc_listings for delete to authenticated using (owner_id = auth.uid());

create policy "coloc déblocages: lecture des siens" on public.coloc_contact_unlocks for select to authenticated using (user_id = auth.uid());
-- aucune policy d'écriture : tout passe par coloc_request_unlock / coloc_admin_review_payment.

create policy "coloc réglages: lecture publique" on public.coloc_app_settings for select using (true);
-- écriture des réglages : numéros de paiement via le Table Editor ; design via coloc_admin_set_theme.

create policy "coloc promos: lecture publique des actives" on public.coloc_promos for select using (active or public.coloc_is_admin());
create policy "coloc promos: gestion par l'admin" on public.coloc_promos for all to authenticated
  using (public.coloc_is_admin()) with check (public.coloc_is_admin());
-- coloc_events : aucune policy => inaccessible en direct ; écriture par coloc_track, lecture par coloc_admin_stats.

-- ───────────── stockage ─────────────
insert into storage.buckets (id, name, public) values ('coloc-listing-photos', 'coloc-listing-photos', true) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('coloc-promo-images', 'coloc-promo-images', true) on conflict (id) do nothing;
create policy "coloc photos: lecture publique" on storage.objects for select using (bucket_id in ('coloc-listing-photos', 'coloc-promo-images'));
create policy "coloc photos: envoi dans son dossier" on storage.objects for insert to authenticated
  with check (bucket_id = 'coloc-listing-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "coloc photos: suppression dans son dossier" on storage.objects for delete to authenticated
  using (bucket_id = 'coloc-listing-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "coloc flyers: gestion par l'admin" on storage.objects for all to authenticated
  using (bucket_id = 'coloc-promo-images' and public.coloc_is_admin()) with check (bucket_id = 'coloc-promo-images' and public.coloc_is_admin());

-- ───────────── données initiales ─────────────
insert into public.coloc_app_settings (key, value) values
  ('payment_methods', '[
    {"id":"orange","label":"Orange Money","number":"+226 00 00 00 00","holder":"NOM DU TITULAIRE"},
    {"id":"moov","label":"Moov Money","number":"+226 00 00 00 00","holder":"NOM DU TITULAIRE"}
  ]'::jsonb),
  ('theme', '{"design":"ocean","primary":null,"accent":null}'::jsonb);

insert into public.coloc_promos (title, subtitle, color_a, color_b, sort) values
  ('Ta coloc, sans prise de tête', 'Trouve une maison ou des colocataires en quelques minutes.', '0F766E', '2DD4BF', 0),
  ('Agences : publiez vos logements', 'Photos, caution, frais : touchez des milliers d''étudiants.', '4338CA', '818CF8', 1);
