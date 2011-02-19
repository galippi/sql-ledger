--correcting counteraccno functions
DROP FUNCTION g_accno_by_transid (integer, double precision,date, text);
DROP FUNCTION g_gifi_accno_by_transid (integer, double precision,date, text);
CREATE FUNCTION g_accno_by_transid (integer,double precision,date, text) RETURNS text AS '
declare
trans_id alias for $1;
amount_num alias for $2;
transdate alias for $3;
link alias for $4;

acc RECORD;
query text;
w text;
l text;
begin

if amount_num > 0 then
 w := ''and amount < 0'';
 else
  w := ''and amount >= 0'';
  end if;

if link LIKE ''%_amount%'' OR link SIMILAR TO ''%IC_(income|sale)%'' OR link SIMILAR TO ''(IC|%IC_expense%)'' then
 l := ''and link NOT LIKE ''''%_paid%'''''';
else
 l := '''';
end if;  

  query := ''select accno from chart where id in (SELECT chart_id from acc_trans where trans_id = ''''''||trans_id||'''''' ''||w||'' ''||l||'' AND transdate = ''''''||transdate||'''''') '';
  w := '''';
  
  for acc in execute query loop
  w := w ||''<br>''||acc.accno;
  end loop;
  
  return substr(w,5,length(w));
  end;
  'LANGUAGE 'plpgsql';
--end function
CREATE FUNCTION g_gifi_accno_by_transid (integer,double precision,date, text) RETURNS text AS '
declare
trans_id alias for $1;
amount_num alias for $2;
transdate alias for $3;
link alias for $4;

acc RECORD;
query text;
w text;
l text;
begin

if amount_num > 0 then
 w := ''and amount < 0'';
 else
  w := ''and amount >= 0'';
  end if;

if link LIKE ''%_amount%'' OR link SIMILAR TO ''%IC_(income|sale)%'' OR link SIMILAR TO ''(IC|%IC_expense%)'' then
 l := ''and link NOT LIKE ''''%_paid%'''''';
else
 l := '''';
end if; 
  
  query := ''select gifi_accno from chart where id in (SELECT chart_id from acc_trans where trans_id = ''''''||trans_id||'''''' ''||w||'' ''||l||'' AND transdate = ''''''||transdate||'''''') '';
  w := '''';
  
  for acc in execute query loop
  w := w ||''<br>''||acc.gifi_accno;
  end loop;
  
  return substr(w,5,length(w));
  end;
  'LANGUAGE 'plpgsql';
-- end function
ALTER TABLE defaults ADD COLUMN prefix TEXT;
ALTER TABLE defaults ADD COLUMN suffix TEXT;
--
UPDATE defaults SET version = '2.4.33';
