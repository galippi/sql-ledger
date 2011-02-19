--
CREATE FUNCTION del_yearend() RETURNS OPAQUE AS '
begin
  delete from yearend where trans_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_yearend AFTER DELETE ON gl FOR EACH ROW EXECUTE PROCEDURE del_yearend();
-- end trigger
--
CREATE FUNCTION del_department() RETURNS OPAQUE AS '
begin
  delete from dpt_trans where trans_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_department AFTER DELETE ON ar FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
CREATE TRIGGER del_department AFTER DELETE ON ap FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
CREATE TRIGGER del_department AFTER DELETE ON gl FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
CREATE TRIGGER del_department AFTER DELETE ON oe FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
--
CREATE FUNCTION del_customer() RETURNS OPAQUE AS '
begin
  delete from shipto where trans_id = old.id;
  delete from customertax where customer_id = old.id;
  delete from partscustomer where customer_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_customer AFTER DELETE ON customer FOR EACH ROW EXECUTE PROCEDURE del_customer();
-- end trigger
--
CREATE FUNCTION del_vendor() RETURNS OPAQUE AS '
begin
  delete from shipto where trans_id = old.id;
  delete from vendortax where vendor_id = old.id;
  delete from partsvendor where vendor_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_vendor AFTER DELETE ON vendor FOR EACH ROW EXECUTE PROCEDURE del_vendor();
-- end trigger
--
--
CREATE FUNCTION check_department() RETURNS OPAQUE AS '

declare
  dpt_id int;

begin

  if new.department_id = 0 then
    delete from dpt_trans where trans_id = new.id;
    return NULL;
  end if;

  select into dpt_id trans_id from dpt_trans where trans_id = new.id;
  
  if dpt_id > 0 then
    update dpt_trans set department_id = new.department_id where trans_id = dpt_id;
  else
    insert into dpt_trans (trans_id, department_id) values (new.id, new.department_id);
  end if;
return NULL;

end;
' language 'plpgsql';

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
--
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON ar FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON ap FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON gl FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON oe FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
--
