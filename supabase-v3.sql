-- Clasamente pentru jocurile noi: 3 vieți, Steaguri, Vecinii, Cunoaște România, hărțile.
-- Rulează o singură dată în Supabase: SQL Editor -> New query -> lipești tot -> Run.
-- Poți rula scriptul și a doua oară, nu strică nimic.
-- Presupune că ai rulat deja supabase.sql și supabase-v2.sql.

-- 1. Numele de jocuri permise.
alter table public.scoruri drop constraint if exists scoruri_joc_check;
alter table public.scoruri add constraint scoruri_joc_check
  check (joc ~ '^(capitale-europa|capitale-lume|judete|compara|continente|viata|steaguri|vecini|romania|harta-(europa|asia|africa|america-nord|america-sud|oceania|judete)|zilnic-[0-9]{4}-[0-9]{2}-[0-9]{2})$');

-- 2. Scorul: 1-10 la jocurile cu 10 întrebări, 1-300 la „3 vieți” (fără sfârșit).
alter table public.scoruri drop constraint if exists scoruri_scor_check;
alter table public.scoruri drop constraint if exists scoruri_scor_per_joc;
alter table public.scoruri add constraint scoruri_scor_per_joc
  check ((joc = 'viata' and scor between 1 and 300) or (joc <> 'viata' and scor between 1 and 10));
