CREATE FUNCTION ap(integer) RETURNS text AS '
declare
trans_id alias for $1;

acc RECORD;
query text;
w text;
begin



  query := ''select accno, description from acc_trans a, chart c where trans_id=''''''||trans_id||'''''' AND chart_id=c.id AND link LIKE ''''%AP_amount%'''' '';
  w := '''';
  
  for acc in execute query loop
  w := w ||''<br>''||acc.accno||''--''||acc.description;
  end loop;
  
  return substr(w,5,length(w));
  end;
  'LANGUAGE 'plpgsql';
--end function
UPDATE defaults SET version = '2.4.39';
