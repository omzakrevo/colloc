-- Colloc — schéma Supabase. À exécuter une fois dans SQL Editor (ou `supabase db push`).

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null,
  phone text,
  role text not null default 'student' check (role in ('student','agency','admin')),
  agency_name text,
  created_at timestamptz not null default now()
);

create table public.listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users on delete cascade,
  owner_name text not null,
  owner_role text not null check (owner_role in ('student','agency')),
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
create index listings_active_created on public.listings (active, created_at desc);

-- Avis de paiement de mise en contact (1 000 FCFA). Paiement manuel : l'utilisateur envoie l'argent en Mobile Money
-- puis émet un avis ; l'administrateur vérifie et valide => le numéro de l'annonceur est débloqué.
create table public.contact_unlocks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  listing_id uuid not null references public.listings on delete cascade,
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

-- Réglages publics (ex. numéros Mobile Money où payer). À modifier dans le Table Editor.
create table public.app_settings (key text primary key, value jsonb not null);
insert into public.app_settings (key, value) values ('payment_methods', '[
  {"id":"wave","label":"Wave","number":"+221 00 000 00 00","holder":"NOM DU TITULAIRE"},
  {"id":"orange","label":"Orange Money","number":"+221 00 000 00 00","holder":"NOM DU TITULAIRE"}
]'::jsonb);

create function public.is_admin() returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin')
$$;

-- Profil créé automatiquement à l'inscription (données passées dans signUp(data: ...)).
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, phone, role, agency_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', 'Utilisateur'),
    new.raw_user_meta_data->>'phone',
    case when new.raw_user_meta_data->>'role' = 'agency' then 'agency' else 'student' end,
    new.raw_user_meta_data->>'agency_name'
  );
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Contacts débloqués par l'utilisateur courant (le téléphone n'est jamais exposé autrement).
create function public.my_unlocked_contacts()
returns table (listing_id uuid, name text, phone text, at timestamptz)
language sql security definer set search_path = public stable as $$
  select u.listing_id, l.owner_name, p.phone, u.reviewed_at
  from contact_unlocks u
  join listings l on l.id = u.listing_id
  join profiles p on p.id = l.owner_id
  where u.user_id = auth.uid() and u.status = 'approved'
  order by u.reviewed_at desc
$$;

-- Émission d'un avis de paiement (statut pending). Un avis refusé peut être ré-émis.
create function public.request_unlock(p_listing uuid, p_method text, p_phone text, p_reference text)
returns uuid language plpgsql security definer set search_path = public as $$
declare lst listings; cur contact_unlocks; new_id uuid;
begin
  if auth.uid() is null then raise exception 'Connexion requise.'; end if;
  select * into lst from listings where id = p_listing and active;
  if not found then raise exception 'Annonce introuvable.'; end if;
  if lst.owner_id = auth.uid() then raise exception 'C''est votre propre annonce.'; end if;
  if length(trim(coalesce(p_phone, ''))) < 8 then raise exception 'Numéro invalide.'; end if;
  select * into cur from contact_unlocks where user_id = auth.uid() and listing_id = p_listing;
  if found and cur.status <> 'rejected' then raise exception 'Un avis existe déjà pour cette annonce.'; end if;
  if found then
    update contact_unlocks set status = 'pending', method = p_method, payer_phone = p_phone, reference = p_reference,
      reviewed_by = null, reviewed_at = null, created_at = now() where id = cur.id returning id into new_id;
  else
    insert into contact_unlocks (user_id, listing_id, method, payer_phone, reference)
    values (auth.uid(), p_listing, p_method, p_phone, p_reference) returning id into new_id;
  end if;
  return new_id;
end $$;

create function public.my_payments()
returns table (id uuid, listing_id uuid, listing_title text, method text, payer_phone text, reference text,
               status text, amount integer, created_at timestamptz)
language sql security definer set search_path = public stable as $$
  select u.id, u.listing_id, l.title, u.method, u.payer_phone, u.reference, u.status, u.amount, u.created_at
  from contact_unlocks u join listings l on l.id = u.listing_id
  where u.user_id = auth.uid() order by u.created_at desc
$$;

-- Réservé aux administrateurs (profiles.role = 'admin', à positionner à la main : voir docs/DEPLOIEMENT.md).
create function public.admin_payments()
returns table (id uuid, listing_id uuid, listing_title text, payer_name text, method text, payer_phone text,
               reference text, status text, amount integer, created_at timestamptz)
language plpgsql security definer set search_path = public stable as $$
begin
  if not is_admin() then raise exception 'Réservé à l''administrateur.'; end if;
  return query
    select u.id, u.listing_id, l.title, p.name, u.method, u.payer_phone, u.reference, u.status, u.amount, u.created_at
    from contact_unlocks u join listings l on l.id = u.listing_id join profiles p on p.id = u.user_id
    order by (u.status = 'pending') desc, u.created_at desc;
end $$;

create function public.admin_review_payment(p_id uuid, p_approve boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'Réservé à l''administrateur.'; end if;
  update contact_unlocks set status = case when p_approve then 'approved' else 'rejected' end,
    reviewed_by = auth.uid(), reviewed_at = now() where id = p_id;
end $$;

revoke all on function public.request_unlock, public.my_payments, public.admin_payments, public.admin_review_payment, public.my_unlocked_contacts from public;
grant execute on function public.request_unlock, public.my_payments, public.admin_payments, public.admin_review_payment, public.my_unlocked_contacts to authenticated;

-- RLS
alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.contact_unlocks enable row level security;
alter table public.app_settings enable row level security;
create policy "réglages: lecture publique" on public.app_settings for select using (true);

create policy "profil: lecture du sien" on public.profiles for select using (id = auth.uid());
create policy "profil: modification du sien" on public.profiles for update using (id = auth.uid())
  with check (id = auth.uid() and role = (select role from public.profiles where id = auth.uid()));

create policy "annonces: lecture publique des actives" on public.listings for select
  using (active or owner_id = auth.uid());
create policy "annonces: création par le propriétaire" on public.listings for insert
  with check (
    owner_id = auth.uid()
    and (kind <> 'agency' or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'agency'))
  );
create policy "annonces: modification par le propriétaire" on public.listings for update
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "annonces: suppression par le propriétaire" on public.listings for delete using (owner_id = auth.uid());

create policy "déblocages: lecture des siens" on public.contact_unlocks for select using (user_id = auth.uid());
-- aucune policy insert/update : tout passe par les fonctions request_unlock / admin_review_payment.

-- Photos
insert into storage.buckets (id, name, public) values ('listing-photos', 'listing-photos', true)
  on conflict (id) do nothing;
create policy "photos: lecture publique" on storage.objects for select using (bucket_id = 'listing-photos');
create policy "photos: envoi dans son dossier" on storage.objects for insert to authenticated
  with check (bucket_id = 'listing-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos: suppression dans son dossier" on storage.objects for delete to authenticated
  using (bucket_id = 'listing-photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- Slider de l'accueil (publicités / annonces). Géré depuis le Table Editor de Supabase :
-- ajouter une ligne = une nouvelle bannière, sans toucher à l'application.
create table public.promos (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text,
  image_url text,              -- optionnel : visuel plein cadre (URL publique)
  link_url text,               -- optionnel : ouvert au clic
  color_a text default '0F766E', -- dégradé de fond (hex sans #) ; fond clair => texte foncé, fond sombre => texte blanc automatiquement
  color_b text default '14B8A6',
  sponsor boolean not null default false, -- affiche « Publicité »
  sort integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.promos enable row level security;
create policy "promos: lecture publique" on public.promos for select using (active);
-- écriture : uniquement via le dashboard / service role (aucune policy d'écriture)

insert into public.promos (title, subtitle, color_a, color_b, sort) values
  ('Ta coloc, sans prise de tête', 'Trouve une maison ou des colocataires en quelques minutes.', 'D1FAE5', 'A7F3D0', 0),
  ('Agences : publiez vos logements', 'Photos, caution, frais : touchez des milliers d''étudiants.', 'E0E7FF', 'C7D2FE', 1);
insert into public.promos (title, subtitle, color_a, color_b, sponsor, sort) values
  ('Votre publicité ici', 'Boutiques, déménageurs, internet… parlez aux étudiants.', 'FEF3C7', 'FDE68A', true, 2);
