-- Colloc — schéma Supabase. À exécuter une fois dans SQL Editor (ou `supabase db push`).

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null,
  phone text,
  role text not null default 'student' check (role in ('student','agency')),
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

-- Une ligne par mise en contact payée (écrite uniquement par l'Edge Function, avec la service key).
create table public.contact_unlocks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  listing_id uuid not null references public.listings on delete cascade,
  amount integer not null,
  provider text not null,
  provider_ref text,
  status text not null default 'pending' check (status in ('pending','paid','failed')),
  created_at timestamptz not null default now(),
  unique (user_id, listing_id)
);

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
  select u.listing_id, l.owner_name, p.phone, u.created_at
  from contact_unlocks u
  join listings l on l.id = u.listing_id
  join profiles p on p.id = l.owner_id
  where u.user_id = auth.uid() and u.status = 'paid'
  order by u.created_at desc
$$;

-- RLS
alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.contact_unlocks enable row level security;

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
-- aucune policy insert/update : seule l'Edge Function (service role) écrit.

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
  color_a text default '0F766E', -- dégradé de fond (hex sans #)
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
  ('Ta coloc, sans prise de tête', 'Trouve une maison ou des colocataires en quelques minutes.', '0F766E', '2DD4BF', 0),
  ('Agences : publiez vos logements', 'Photos, caution, frais : touchez des milliers d''étudiants.', '4338CA', '818CF8', 1);
insert into public.promos (title, subtitle, color_a, color_b, sponsor, sort) values
  ('Votre publicité ici', 'Boutiques, déménageurs, internet… parlez aux étudiants.', 'EA580C', 'FBBF24', true, 2);
