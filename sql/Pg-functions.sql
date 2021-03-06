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
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_vendor AFTER DELETE ON vendor FOR EACH ROW EXECUTE PROCEDURE del_vendor();
-- end trigger
--
CREATE FUNCTION del_exchangerate() RETURNS OPAQUE AS '

declare
  t_transdate date;
  t_curr char(3);
  t_id int;
  d_curr text;

begin

  select into d_curr substr(curr,1,3) from defaults;
  
  if TG_RELNAME = ''ar'' then
    select into t_curr, t_transdate curr, transdate from ar where id = old.id;
  end if;
  if TG_RELNAME = ''ap'' then
    select into t_curr, t_transdate curr, transdate from ap where id = old.id;
  end if;
  if TG_RELNAME = ''oe'' then
    select into t_curr, t_transdate curr, transdate from oe where id = old.id;
  end if;

  if d_curr != t_curr then

    select into t_id a.id from acc_trans ac
    join ar a on (a.id = ac.trans_id)
    where a.curr = t_curr
    and ac.transdate = t_transdate

    except select a.id from ar a where a.id = old.id
    
    union
    
    select a.id from acc_trans ac
    join ap a on (a.id = ac.trans_id)
    where a.curr = t_curr
    and ac.transdate = t_transdate
    
    except select a.id from ap a where a.id = old.id
    
    union
    
    select o.id from oe o
    where o.curr = t_curr
    and o.transdate = t_transdate
    
    except select o.id from oe o where o.id = old.id;

    if not found then
      delete from exchangerate where curr = t_curr and transdate = t_transdate;
    end if;
  end if;
return old;

end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON ar FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON ap FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON oe FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE FUNCTION check_inventory() RETURNS OPAQUE AS '

declare
  itemid int;
  row_data inventory%rowtype;

begin

  if not old.quotation then
    for row_data in select * from inventory where oe_id = old.id loop
      select into itemid id from orderitems where trans_id = old.id and id = row_data.orderitems_id;

      if itemid is null then
	delete from inventory where oe_id = old.id and orderitems_id = row_data.orderitems_id;
      end if;
    end loop;
  end if;
  return old;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER check_inventory AFTER UPDATE ON oe FOR EACH ROW EXECUTE PROCEDURE check_inventory();
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
-- end function
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
