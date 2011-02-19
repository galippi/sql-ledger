DROP FUNCTION g_gifi_accno_by_transid (integer,double precision,date);
--
CREATE FUNCTION g_gifi_accno_by_transid (integer,double precision,date) RETURNS text AS '
declare
trans_id alias for $1;
amount_num alias for $2;
transdate alias for $3;

acc RECORD;
query text;
w text;
begin

if amount_num > 0 then
 w := ''and amount < 0'';
 else
  w := ''and amount >= 0'';
  end if;
  
  query := ''select gifi_accno from chart where id in (SELECT chart_id from acc_trans where trans_id = ''''''||trans_id||'''''' ''||w||'' AND transdate = ''''''||transdate||'''''' order by oid desc) '';
  w := '''';
  
  for acc in execute query loop
  w := w ||''<br>''||acc.gifi_accno;
  end loop;
  
  return substr(w,5,length(w));
  end;
  'LANGUAGE 'plpgsql';
-- end function
--
update defaults set version = '2.4.21';