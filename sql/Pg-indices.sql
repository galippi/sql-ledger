create index acc_trans_trans_id_key on acc_trans (trans_id);
create index acc_trans_chart_id_key on acc_trans (chart_id);
create index acc_trans_transdate_key on acc_trans (transdate);
create index acc_trans_source_key on acc_trans (lower(source));
--
create index ap_id_key on ap (id);
create index ap_transdate_key on ap (transdate);
create index ap_invnumber_key on ap (lower(invnumber));
create index ap_ordnumber_key on ap (lower(ordnumber));
create index ap_vendor_id_key on ap (vendor_id);
create index ap_employee_id_key on ap (employee_id);
create index ap_quonumber_key on ap (lower(quonumber));
--
create index ar_id_key on ar (id);
create index ar_transdate_key on ar (transdate);
create index ar_invnumber_key on ar (lower(invnumber));
create index ar_ordnumber_key on ar (lower(ordnumber));
create index ar_customer_id_key on ar (customer_id);
create index ar_employee_id_key on ar (employee_id);
create index ar_quonumber_key on ar (lower(quonumber));
--
create index assembly_id_key on assembly (id);
--
create index chart_id_key on chart (id);
create unique index chart_accno_key on chart (accno);
create index chart_category_key on chart (category);
create index chart_link_key on chart (link);
create index chart_gifi_accno_key on chart (gifi_accno);
--
create index customer_id_key on customer (id);
create index customer_customernumber_key on customer (customernumber);
create index customer_name_key on customer (name);
create index customer_contact_key on customer (contact);
create index customer_customer_id_key on customertax (customer_id);
--
create index employee_id_key on employee (id);
create unique index employee_login_key on employee (login);
create index employee_name_key on employee (name);
--
create index exchangerate_ct_key on exchangerate (curr, transdate);
--
create unique index gifi_accno_key on gifi (accno);
--
create index gl_id_key on gl (id);
create index gl_transdate_key on gl (transdate);
create index gl_reference_key on gl (lower(reference));
create index gl_description_key on gl (lower(description));
create index gl_employee_id_key on gl (employee_id);
--
create index invoice_id_key on invoice (id);
create index invoice_trans_id_key on invoice (trans_id);
--
create index makemodel_parts_id_key on makemodel (parts_id);
create index makemodel_make_key on makemodel (lower(make));
create index makemodel_model_key on makemodel (lower(model));
--
create index oe_id_key on oe (id);
create index oe_transdate_key on oe (transdate);
create index oe_ordnumber_key on oe (lower(ordnumber));
create index oe_employee_id_key on oe (employee_id);
create index orderitems_trans_id_key on orderitems (trans_id);
create index orderitems_id_key on orderitems (id);
--
create index parts_id_key on parts (id);
create index parts_partnumber_key on parts (lower(partnumber));
create index parts_description_key on parts (lower(description));
create index partstax_parts_id_key on partstax (parts_id);
--
create index vendor_id_key on vendor (id);
create index vendor_name_key on vendor (name);
create index vendor_vendornumber_key on vendor (vendornumber);
create index vendor_contact_key on vendor (contact);
create index vendortax_vendor_id_key on vendortax (vendor_id);
--
create index shipto_trans_id_key on shipto (trans_id);
--
create index project_id_key on project (id);
create unique index projectnumber_key on project (projectnumber);
--
create index partsgroup_id_key on partsgroup (id);
create unique index partsgroup_key on partsgroup (partsgroup);
--
create index status_trans_id_key on status (trans_id);
--
create index department_id_key on department (id);
--
create index partsvendor_vendor_id_key on partsvendor (vendor_id);
create index partsvendor_parts_id_key on partsvendor (parts_id);
--
create index pricegroup_pricegroup_key on pricegroup (pricegroup);
create index pricegroup_id_key on pricegroup (id);
--
create index audittrail_trans_id_key on audittrail (trans_id);
--
create index translation_trans_id_key on translation (trans_id);
--
create unique index language_code_key on language (code);
--
create unique index regnum_key on regnum (code);
create unique index regtype_key on regnum (chart_id,regcheck);
--
CREATE UNIQUE INDEX regnumber_key ON regnumber (code);
--
CREATE INDEX szl_id_key on szl (id);
CREATE INDEX szl_transdate_key on szl (transdate);
CREATE INDEX szl_szlnumber_key on szl (lower(szlnumber));
CREATE INDEX szl_employee_id_key on szl (employee_id);
CREATE INDEX szlitems_trans_id_key on szlitems (trans_id);

create index armod_moddate_key on armod (moddate);
create index armod_parts_id_key on armod (parts_id);

