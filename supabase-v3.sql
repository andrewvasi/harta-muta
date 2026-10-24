-- Clasamente pentru jocurile noi: Steaguri, Vecinii, Cunoaște România, hărțile.
-- Rulează o singură dată în Supabase: SQL Editor -> New query -> lipești tot -> Run.
-- Presupune că ai rulat deja supabase.sql și supabase-v2.sql.
alter table public.scoruri drop constraint if exists scoruri_joc_check;
alter table public.scoruri add constraint scoruri_joc_check
  check (joc ~ '^(capitale-europa|capitale-lume|judete|compara|continente|steaguri|vecini|romania|harta-(europa|asia|africa|america-nord|america-sud|oceania|judete)|zilnic-[0-9]{4}-[0-9]{2}-[0-9]{2})$');
