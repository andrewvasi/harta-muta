-- Protecție pentru clasamente + provocarea zilei
-- Rulează o singură dată în Supabase: SQL Editor -> New query -> lipești tot -> Run.
-- Presupune că ai rulat deja supabase.sql (tabelul public.scoruri există).

-- 1. Acceptă și clasamentul provocării zilei (joc = 'zilnic-AAAA-LL-ZZ').
alter table public.scoruri drop constraint if exists scoruri_joc_check;
alter table public.scoruri add constraint scoruri_joc_check
  check (joc ~ '^(capitale-europa|capitale-lume|judete|compara|continente|zilnic-[0-9]{4}-[0-9]{2}-[0-9]{2})$');

-- 2. Coloană internă (hash, nu adresa reală) pentru limitarea trimiterilor.
alter table public.scoruri add column if not exists ip_hash text;

-- 3. Cititorii publici văd doar coloanele clasamentului, nu și ip_hash.
revoke select on public.scoruri from anon, authenticated;
grant select (id, joc, nume, scor, creat_la) on public.scoruri to anon, authenticated;

-- 4. Verificări la fiecare scor trimis: nume permis și limită de trimiteri.
create or replace function public.scoruri_guard() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  headers json;
  ip text;
  plain text;
  letters text;
begin
  new.nume := btrim(regexp_replace(new.nume, '\s+', ' ', 'g'));
  if char_length(new.nume) < 2 or char_length(new.nume) > 20 then
    raise exception 'nume invalid';
  end if;

  plain := translate(lower(new.nume), 'ăâîșşțţ', 'aaisstt');
  letters := regexp_replace(translate(plain, '0134@$5', 'oieaass'), '[^a-z]', '', 'g');
  if plain ~ '(http|www|\.ro|\.com|@)'
     or letters ~ '(pizda|muie|cacat|curva|fututi|sugi|hitler|nazist)'
     or plain ~ '(^|[^a-z])(pula|fut|cur)([^a-z]|$)' then
    raise exception 'nume nepermis';
  end if;

  begin
    headers := current_setting('request.headers', true)::json;
  exception when others then
    headers := null;
  end;
  ip := coalesce(headers->>'cf-connecting-ip', split_part(coalesce(headers->>'x-forwarded-for', ''), ',', 1), '');
  new.ip_hash := md5('harta-muta:' || ip);

  if ip <> '' then
    if (select count(*) from public.scoruri
        where ip_hash = new.ip_hash and creat_la > now() - interval '10 minutes') >= 6 then
      raise exception 'limita de trimiteri';
    end if;
    if (select count(*) from public.scoruri
        where ip_hash = new.ip_hash and creat_la > now() - interval '1 day') >= 40 then
      raise exception 'limita de trimiteri';
    end if;
    if exists (select 1 from public.scoruri
        where ip_hash = new.ip_hash and joc = new.joc and nume = new.nume and scor = new.scor
          and creat_la > now() - interval '10 minutes') then
      raise exception 'limita de trimiteri';
    end if;
  end if;

  return new;
end
$$;

drop trigger if exists scoruri_guard_trg on public.scoruri;
create trigger scoruri_guard_trg
  before insert on public.scoruri
  for each row execute function public.scoruri_guard();
