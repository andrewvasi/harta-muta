-- Clasamente pentru Harta Mută
-- Rulează o singură dată în Supabase: SQL Editor -> New query -> lipești -> Run.

create table if not exists public.scoruri (
  id bigint generated always as identity primary key,
  joc text not null check (joc in ('capitale-europa', 'capitale-lume', 'judete', 'compara', 'continente')),
  nume text not null check (char_length(nume) between 2 and 20),
  scor int not null check (scor between 1 and 10),
  creat_la timestamptz not null default now()
);

create index if not exists scoruri_joc_scor_idx on public.scoruri (joc, scor desc, creat_la);

alter table public.scoruri enable row level security;

-- Oricine poate citi clasamentul.
create policy "citire publica" on public.scoruri
  for select using (true);

-- Oricine poate adăuga un scor valid. Nu există reguli pentru modificare sau ștergere,
-- deci nimeni din site nu poate schimba sau șterge scoruri.
create policy "adaugare publica" on public.scoruri
  for insert with check (true);
