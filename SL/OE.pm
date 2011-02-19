#=====================================================================
# SQL-Ledger Accounting
# Copyright (C) 2001
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#
#  Modified by Tavugyvitel Kft. (info@tavugyvitel.hu)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#======================================================================
#
# Order entry module
# Quotation
#
#======================================================================

package OE;

#pasztor
sub tr_transactions {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $query;
  my $where = '1=1';
  my $ordnumber = 'szlnumber';
  my ($null, $department_id) = split /--/, $form->{department};

  my $department = " AND o.department_id = $department_id" if $department_id;

  my $number = $form->like(lc $form->{$ordnumber});
  my $notes = $form->like(lc $form->{notes});
  my $intnotes = $form->like(lc $form->{intnotes});
  my ($warehouse, $warehouse_id) = split /--/, $form->{warehouse};
  if ($form->{hhovawarehouse}) {
       my ($null, $hhovawarehouse_id) = split /--/, $form->{hhovawarehouse};
       $where .= " AND hw.id = $hhovawarehouse_id";
  }

  my $query = qq|SELECT o.id, o.szlnumber, o.transdate, o.shipdate AS reqdate,
		 o.shippingpoint, e.name AS employee, o.notes, o.intnotes,
                 hw.description as hovawarehouse, w.description as warehouse
	         FROM szl o
	         LEFT JOIN employee e ON (o.employee_id = e.id)
	         LEFT JOIN warehouse hw ON (hw.id = o.to_warehouse_id)
		 LEFT JOIN warehouse w ON (w.id = o.warehouse_id)
	         WHERE $where
		 $department|;

  my %ordinal = ( 'id' => 1,
                  'szlnumber' => 2,
                  'transdate' => 3,
		  'reqdate' => 4,
		  'employee' => 6,
		  'notes' => 7,
		  'intnotes' => 8,
                  'hovawarehouse' => 9,
                  'warehouse' => 10
		);

  my @a = (transdate, $ordnumber, name);
  my $sortorder = $form->sort_order(\@a, \%ordinal);

  $query .= " AND lower($ordnumber) LIKE '$number'" if $form->{$ordnumber};
#kabai
  $query .= " AND lower(o.notes) LIKE '$notes'" if $form->{notes};
  $query .= " AND lower(o.intnotes) LIKE '$intnotes'" if $form->{intnotes};
#kabai
  $query .= " AND o.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
  $query .= " AND o.transdate <= '$form->{transdateto}'" if $form->{transdateto};
  $query .= " ORDER by $sortorder";

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my %id = ();
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{exchangerate} = 1 unless $ref->{exchangerate};
    push @{ $form->{OE} }, $ref if $ref->{id} != $id{$ref->{id}};
    $id{$ref->{id}} = $ref->{id};
  }
  $sth->finish;
  $dbh->disconnect;
  
}



sub transactions {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $query;
  my $ordnumber = 'ordnumber';
  my $quotation = '0';
  my ($null, $department_id) = split /--/, $form->{department};

  my $department = " AND o.department_id = $department_id" if $department_id;
  
  my $rate = ($form->{vc} eq 'customer') ? 'buy' : 'sell';

  if ($form->{type} =~ /_quotation$/) {
    $quotation = '1';
    $ordnumber = 'quonumber';
  }
  
  my $number = $form->like(lc $form->{$ordnumber});
#kabai
  my $notes = $form->like(lc $form->{notes});
  my $intnotes = $form->like(lc $form->{intnotes});
#kabai
  my $name = $form->like(lc $form->{$form->{vc}});
 
  my $query = qq|SELECT o.id, o.ordnumber, o.transdate, o.reqdate,
                 o.amount, ct.name, o.netamount, o.$form->{vc}_id,
		 ex.$rate AS exchangerate,
		 o.closed, o.quonumber, o.shippingpoint, o.shipvia,
		 e.name AS employee, o.notes, o.intnotes
	         FROM oe o
	         JOIN $form->{vc} ct ON (o.$form->{vc}_id = ct.id)
	         LEFT JOIN employee e ON (o.employee_id = e.id)
	         LEFT JOIN exchangerate ex ON (ex.curr = o.curr
		                               AND ex.transdate = o.transdate)
	         WHERE o.quotation = '$quotation'
		 $department|;

  my %ordinal = ( 'id' => 1,
                  'ordnumber' => 2,
                  'transdate' => 3,
		  'reqdate' => 4,
		  'name' => 6,
		  'quonumber' => 11,
		  'employee' => 14,
		  'shipvia' => 13,
		  'notes' => 15,
		  'intnotes' => 16
		);

  my @a = (transdate, $ordnumber, name);
  my $sortorder = $form->sort_order(\@a, \%ordinal);
  
  my $on = ($myconfig->{dbdriver} =~ /Pg/) ? "ON" : "";
  
  # build query if type eq (ship|receive)_order
  if ($form->{type} =~ /(ship|receive)_order/) {
    
    $sortorder = "id $form->{direction}, ".$sortorder;
    
    my ($warehouse, $warehouse_id) = split /--/, $form->{warehouse};

    $query =  qq|SELECT DISTINCT $on (id) o.id, o.ordnumber, o.transdate,
                 o.reqdate, o.amount, ct.name, o.netamount, o.$form->{vc}_id,
		 ex.$rate AS exchangerate,
		 o.closed, o.quonumber, o.shippingpoint, o.shipvia,
		 e.name AS employee, o.notes, o.intnotes
	         FROM oe o
	         JOIN $form->{vc} ct ON (o.$form->{vc}_id = ct.id)
		 JOIN orderitems oi ON (oi.trans_id = o.id)
		 JOIN parts p ON (p.id = oi.parts_id)|;

      if ($warehouse_id && $form->{type} eq 'ship_order') {
	$query .= qq|
	         JOIN inventory i ON (oi.parts_id = i.parts_id)
		 |;
      }

    $query .= qq|
	         LEFT JOIN employee e ON (o.employee_id = e.id)
	         LEFT JOIN exchangerate ex ON (ex.curr = o.curr
		                               AND ex.transdate = o.transdate)
	         WHERE o.quotation = '0'
		 AND (p.inventory_accno_id > 0 OR p.assembly = '1')
		 AND oi.qty != oi.ship
		 $department|;
		 
    if ($warehouse_id && $form->{type} eq 'ship_order') {
#kabai ALLOW_NEGATIVE_WAREHOUSE
 #     $query .= qq|
  #               AND i.warehouse_id = $warehouse_id
		 #AND i.qty >= (oi.qty - oi.ship)
#		 |;
#
    }

  }
 
  if ($form->{"$form->{vc}_id"}) {
    $query .= qq| AND o.$form->{vc}_id = $form->{"$form->{vc}_id"}|;
  } else {
    if ($form->{$form->{vc}}) {
      $query .= " AND lower(ct.name) LIKE '$name'";
    }
  }
  if (!$form->{open} && !$form->{closed}) {
    $query .= " AND o.id = 0";
  } elsif (!($form->{open} && $form->{closed})) {
     $query .= ($form->{open}) ? " AND o.closed = '0'" : " AND o.closed = '1'";
  }

  $query .= " AND lower($ordnumber) LIKE '$number'" if $form->{$ordnumber};
#kabai
  $query .= " AND lower(o.notes) LIKE '$notes'" if $form->{notes};
  $query .= " AND lower(o.intnotes) LIKE '$intnotes'" if $form->{intnotes};
#kabai
  $query .= " AND o.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
  $query .= " AND o.transdate <= '$form->{transdateto}'" if $form->{transdateto};
  $query .= " ORDER by $sortorder";

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my %id = ();
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{exchangerate} = 1 unless $ref->{exchangerate};
    push @{ $form->{OE} }, $ref if $ref->{id} != $id{$ref->{id}};
    $id{$ref->{id}} = $ref->{id};
  }
  $sth->finish;
  $dbh->disconnect;
  
}


sub save {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database, turn off autocommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $sth;
  my $null;
  my $exchangerate = 0;

  ($null, $form->{employee_id}) = split /--/, $form->{employee};
  unless ($form->{employee_id}) {
    ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
    $form->{employee} = "$form->{employee}--$form->{employee_id}";
  }
  
  my $ml = ($form->{type} eq 'sales_order') ? 1 : -1;
  
  if ($form->{id}) {
    
#kabai    &adj_onhand($dbh, $form, $ml) if $form->{type} =~ /_order$/;
    
    $query = qq|DELETE FROM orderitems
                WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|DELETE FROM shipto
                WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);

  } else {
    my $uid = time;
    $uid .= $form->{login};
    
    $query = qq|INSERT INTO oe (ordnumber, employee_id)
		VALUES ('$uid', $form->{employee_id})|;
    $dbh->do($query) || $form->dberror($query);
   
    $query = qq|SELECT id FROM oe
                WHERE ordnumber = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;
    
  }

  my $amount;
  my $linetotal;
  my $discount;
  my $project_id;
  my $reqdate;
  my $taxrate;
  my $taxamount;
  my $fxsellprice;
  my %taxbase;
  my @taxaccounts;
  my %taxaccounts;
  my $netamount = 0;

  for my $i (1 .. $form->{rowcount}) {

    map { $form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"}) } qw(qty ship);

      $form->{"discount_$i"} = $form->parse_amount($myconfig, $form->{"discount_$i"}) / 100;
      $form->{"sellprice_$i"} = $form->parse_amount($myconfig, $form->{"sellprice_$i"});
    
    if ($form->{"qty_$i"}) {
      
      # set values to 0 if nothing entered
      $fxsellprice = $form->{"sellprice_$i"};

      my ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > 2) ? $dec : 2;
      
      $discount = $form->round_amount($form->{"sellprice_$i"} * $form->{"discount_$i"}, $decimalplaces);
      $form->{"sellprice_$i"} = $form->round_amount($form->{"sellprice_$i"} - $discount, $decimalplaces);
      
      $form->{"inventory_accno_$i"} *= 1;
      $form->{"expense_accno_$i"} *= 1;
      
      $linetotal = $form->round_amount($form->{"sellprice_$i"} * $form->{"qty_$i"}, 2);
#kabai      
      @taxaccounts = "";
      foreach $item (split / /, $form->{"taxaccounts_$i"}) {
        if ($form->{"${item}_rate"}){
            if ($form->datetonum($form->{transdate}, $myconfig) >= $form->datetonum($form->{"${item}_validfrom"}, $myconfig)
		&& $form->datetonum($form->{transdate},$myconfig) <= $form->datetonum($form->{"${item}_validto"}, $myconfig)){
               push @taxaccounts, $item;
            }  
        }  
      }   
#kabai
      $taxrate = 0;
      $taxdiff = 0;
      
      map { $taxrate += $form->{"${_}_rate"} } @taxaccounts;

      if ($form->{taxincluded}) {
	$taxamount = $linetotal * $taxrate / (1 + $taxrate);
	$taxbase = $linetotal - $taxamount;
	# we are not keeping a natural price, do not round
	$form->{"sellprice_$i"} = $form->{"sellprice_$i"} * (1 / (1 + $taxrate));
      } else {
	$taxamount = $linetotal * $taxrate;
	$taxbase = $linetotal;
      }

      if (@taxaccounts && $form->round_amount($taxamount, 2) == 0) {
	if ($form->{taxincluded}) {
	  foreach $item (@taxaccounts) {
	    $taxamount = $form->round_amount($linetotal * $form->{"${item}_rate"} / (1 + abs($form->{"${item}_rate"})), 2);

	    $taxaccounts{$item} += $taxamount;
	    $taxdiff += $taxamount; 

	    $taxbase{$item} += $taxbase;
	  }
	  $taxaccounts{$taxaccounts[0]} += $taxdiff;
	} else {
	  foreach $item (@taxaccounts) {
	    $taxaccounts{$item} += $linetotal * $form->{"${item}_rate"};
	    $taxbase{$item} += $taxbase;
	  }
	}
      } else {
	foreach $item (@taxaccounts) {
	  $taxaccounts{$item} += $taxamount * $form->{"${item}_rate"} / $taxrate;
	  $taxbase{$item} += $taxbase;
	}
      }


      $netamount += $form->{"sellprice_$i"} * $form->{"qty_$i"};
      
      $project_id = 'NULL';
      if ($form->{"projectnumber_$i"}) {
	($null, $project_id) = split /--/, $form->{"projectnumber_$i"};
	$project_id *= 1;
      }
      $reqdate = ($form->{"reqdate_$i"}) ? qq|'$form->{"reqdate_$i"}'| : "NULL";
      
      # save detail record in orderitems table
      $query = qq|INSERT INTO orderitems (|;
      $query .= "id, " if $form->{"orderitems_id_$i"};
      $query .= qq|trans_id, parts_id, description, qty, sellprice, discount,
		   unit, reqdate, project_id, serialnumber, ship)
                   VALUES (|;
      $query .= qq|$form->{"orderitems_id_$i"},| if $form->{"orderitems_id_$i"};
      $query .= qq|$form->{id}, $form->{"id_$i"}, |
		   .$dbh->quote($form->{"description_$i"}).qq|,
		   $form->{"qty_$i"}, $fxsellprice, $form->{"discount_$i"}, |
		   .$dbh->quote($form->{"unit_$i"}).qq|, $reqdate,
		   $project_id, |
		   .$dbh->quote($form->{"serialnumber_$i"}).qq|,
		   $form->{"ship_$i"})|;
      $dbh->do($query) || $form->dberror($query);

      $form->{"sellprice_$i"} = $fxsellprice;
      $form->{"discount_$i"} *= 100;
    }
  }


  # set values which could be empty
  map { $form->{$_} *= 1 } qw(vendor_id customer_id taxincluded closed quotation);

  $reqdate = ($form->{reqdate}) ? qq|'$form->{reqdate}'| : "NULL";
  
  # add up the tax
  my $tax = 0;
  map { $tax += $form->round_amount($taxaccounts{$_}, 2) } keys %taxaccounts;
  
  $amount = $form->round_amount($netamount + $tax, 2);
  $netamount = $form->round_amount($netamount, 2);

  if ($form->{currency} eq $form->{defaultcurrency}) {
    $form->{exchangerate} = 1;
  } else {
    $exchangerate = $form->check_exchangerate($myconfig, $form->{currency}, $form->{transdate}, ($form->{vc} eq 'customer') ? 'buy' : 'sell');
  }
  
  $form->{exchangerate} = ($exchangerate) ? $exchangerate : $form->parse_amount($myconfig, $form->{exchangerate});
  
  my $quotation = ($form->{type} =~ /_order$/) ? '0' : '1';
  
  ($null, $form->{department_id}) = split(/--/, $form->{department});
  $form->{department_id} *= 1;
#kabai #invoice amounts rounded to integer
  $netamount = $form->round_amount($netamount,0);
  $amount = $form->round_amount($amount,0);
#kabai  
  # save OE record
  $query = qq|UPDATE oe set
	      ordnumber = |.$dbh->quote($form->{ordnumber}).qq|,
	      quonumber = |.$dbh->quote($form->{quonumber}).qq|,
              transdate = '$form->{transdate}',
              vendor_id = $form->{vendor_id},
	      customer_id = $form->{customer_id},
              amount = $amount,
              netamount = $netamount,
	      reqdate = $reqdate,
	      taxincluded = '$form->{taxincluded}',
	      shippingpoint = |.$dbh->quote($form->{shippingpoint}).qq|,
	      shipvia = |.$dbh->quote($form->{shipvia}).qq|,
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      intnotes = |.$dbh->quote($form->{intnotes}).qq|,
	      curr = '$form->{currency}',
	      closed = '$form->{closed}',
	      quotation = '$quotation',
	      department_id = $form->{department_id},
	      employee_id = $form->{employee_id},
	      language_code = '$form->{language_code}'
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $form->{ordtotal} = $amount;

  # add shipto
  $form->{name} = $form->{$form->{vc}};
  $form->{name} =~ s/--$form->{"$form->{vc}_id"}//;
  $form->add_shipto($dbh, $form->{id});

  # save printed, emailed, queued
  $form->save_status($dbh); 
    
  if (($form->{currency} ne $form->{defaultcurrency}) && !$exchangerate) {
    if ($form->{vc} eq 'customer') {
      $form->update_exchangerate($dbh, $form->{currency}, $form->{transdate}, $form->{exchangerate}, 0);
    }
    if ($form->{vc} eq 'vendor') {
      $form->update_exchangerate($dbh, $form->{currency}, $form->{transdate}, 0, $form->{exchangerate});
    }
  }
  

#kabai  if ($form->{type} =~ /_order$/) {
    # adjust onhand
#    &adj_onhand($dbh, $form, $ml * -1);
#    &adj_inventory($dbh, $myconfig, $form);
#kabai  }

  my %audittrail = ( tablename	=> 'oe',
                     reference	=> ($form->{type} =~ /_order$/) ? $form->{ordnumber} : $form->{quonumber},
		     formname	=> $form->{type},
		     action	=> 'saved',
		     id		=> $form->{id} );

  $form->audittrail($dbh, "", \%audittrail);
#kabai check_inventory
  my $query = qq|DELETE FROM inventory WHERE oe_id = $form->{id} AND orderitems_id NOT IN
		 (SELECT id FROM orderitems WHERE  trans_id = $form->{id}) |;     

  $dbh->do($query) || $form->dberror($query);
#kabai  
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
  
}



sub delete {
  my ($self, $myconfig, $form, $spool) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  # delete spool files
  my $query = qq|SELECT spoolfile FROM status
                 WHERE trans_id = $form->{id}
		 AND spoolfile IS NOT NULL|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $spoolfile;
  my @spoolfiles = ();

  while (($spoolfile) = $sth->fetchrow_array) {
    push @spoolfiles, $spoolfile;
  }
  $sth->finish;


  $query = qq|SELECT o.parts_id, o.ship, p.inventory_accno_id
              FROM orderitems o
	      JOIN parts p ON (p.id = o.parts_id)
              WHERE trans_id = $form->{id}|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  if ($form->{type} =~ /_order$/) {
    $ml = ($form->{type} eq 'purchase_order') ? -1 : 1;
    while (my ($id, $ship, $inv) = $sth->fetchrow_array) {
      $form->update_balance($dbh,
			    "parts",
			    "onhand",
			    qq|id = $id|,
			    $ship * $ml) if $inv;
    }
  }
  $sth->finish;

  # delete inventory
  $query = qq|DELETE FROM inventory
              WHERE oe_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  # delete status entries
  $query = qq|DELETE FROM status
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  # delete OE record
  $query = qq|DELETE FROM oe
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # delete individual entries
  $query = qq|DELETE FROM orderitems
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|DELETE FROM shipto
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  my %audittrail = ( tablename	=> 'oe',
                     reference	=> ($form->{type} =~ /_order$/) ? $form->{ordnumber} : $form->{quonumber},
		     formname	=> $form->{type},
		     action	=> 'deleted',
		     id		=> $form->{id} );

  $form->audittrail($dbh, "", \%audittrail);
  
  my $rc = $dbh->commit;
  $dbh->disconnect;

  if ($rc) {
    foreach $spoolfile (@spoolfiles) {
      unlink "$spool/$spoolfile" if $spoolfile;
    }
  }
  
  $rc;
  
}



sub retrieve {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $var;

  if ($form->{id}) {
    # get default accounts and last order number
    $query = qq|SELECT (SELECT c.accno FROM chart c
                        WHERE d.inventory_accno_id = c.id) AS inventory_accno,
                       (SELECT c.accno FROM chart c
		        WHERE d.income_accno_id = c.id) AS income_accno,
                       (SELECT c.accno FROM chart c
		        WHERE d.expense_accno_id = c.id) AS expense_accno,
                       (SELECT c.accno FROM chart c
		        WHERE d.fxgain_accno_id = c.id) AS fxgain_accno,
                       (SELECT c.accno FROM chart c
		        WHERE d.fxloss_accno_id = c.id) AS fxloss_accno,
                d.curr AS currencies
	 	FROM defaults d|;
  } else {
    $query = qq|SELECT (SELECT c.accno FROM chart c
                        WHERE d.inventory_accno_id = c.id) AS inventory_accno,
                       (SELECT c.accno FROM chart c
		        WHERE d.income_accno_id = c.id) AS income_accno,
                       (SELECT c.accno FROM chart c
		        WHERE d.expense_accno_id = c.id) AS expense_accno,
                       (SELECT c.accno FROM chart c
		        WHERE d.fxgain_accno_id = c.id) AS fxgain_accno,
                       (SELECT c.accno FROM chart c
		        WHERE d.fxloss_accno_id = c.id) AS fxloss_accno,
                d.curr AS currencies,
		current_date AS transdate, current_date AS reqdate
	 	FROM defaults d|;
  }
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
  map { $form->{$_} = $ref->{$_} } keys %$ref;
  $sth->finish;

  if ($form->{id}) {
#pasztor
    if ($form->{type} eq 'trans_packing_list') {
      $query = qq|SELECT o.szlnumber, o.transdate,
		o.shipdate as reqdate, o.shippingpoint, o.notes, o.intnotes,
		e.name AS employee, o.employee_id, 
		o.warehouse_id AS warehousefrom_id,
		o.to_warehouse_id AS warehouse_id, w.description AS warehouse,
		o.department_id, wfrom.description AS warehousefrom,
		d.description AS department, o.language_code
		FROM szl o
	        LEFT JOIN employee e ON (o.employee_id = e.id)
		LEFT JOIN warehouse w ON (w.id = o.to_warehouse_id)
		LEFT JOIN warehouse wfrom ON (wfrom.id = o.warehouse_id)
	        LEFT JOIN department d ON (o.department_id = d.id)
		WHERE o.id = $form->{id}|;

    } else {
    # retrieve order
    $query = qq|SELECT o.ordnumber, o.transdate, o.reqdate,
                o.taxincluded, o.shippingpoint, o.shipvia, o.notes, o.intnotes,
		o.curr AS currency, e.name AS employee, o.employee_id,
		o.$form->{vc}_id, cv.name AS $form->{vc}, o.amount AS invtotal,
		o.closed, o.reqdate, o.quonumber, o.department_id,
		d.description AS department, o.language_code
		FROM oe o
	        JOIN $form->{vc} cv ON (o.$form->{vc}_id = cv.id)
	        LEFT JOIN employee e ON (o.employee_id = e.id)
	        LEFT JOIN department d ON (o.department_id = d.id)
		WHERE o.id = $form->{id}|;
    }
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    map { $form->{$_} = $ref->{$_} } keys %$ref;
    $sth->finish;

#pasztor
    if ($form->{type} ne 'trans_packing_list') {
      $query = qq|SELECT * FROM shipto
                WHERE trans_id = $form->{id}|;
      $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);

      $ref = $sth->fetchrow_hashref(NAME_lc);
      map { $form->{$_} = $ref->{$_} } keys %$ref;
      $sth->finish;
    }

    # get printed, emailed and queued
    $query = qq|SELECT s.printed, s.emailed, s.spoolfile, s.formname
                FROM status s
		WHERE s.trans_id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $form->{printed} .= "$ref->{formname} " if $ref->{printed};
      $form->{emailed} .= "$ref->{formname} " if $ref->{emailed};
      $form->{queued} .= "$ref->{formname} $ref->{spoolfile} " if $ref->{spoolfile};
    }
    $sth->finish;
    map { $form->{$_} =~ s/ +$//g } qw(printed emailed queued);


    my %oid = ( 'Pg'		=> 'oid',
                'PgPP'		=> 'oid',
                'Oracle'	=> 'rowid',
		'DB2'		=> '1=1'
	      );
#pasztor
    my $fromtable = ($form->{type} eq 'trans_packing_list') ? "szlitems" : "orderitems";

    # retrieve individual items
    $query =  qq|SELECT o.id AS orderitems_id,
                 c1.accno AS inventory_accno,
                 c2.accno AS income_accno,
		 c3.accno AS expense_accno,
                 p.partnumber, p.assembly, o.description, o.parts_id AS id,
		 p.bin,|;
    $query .= qq|(SELECT abs(sum(i.qty)) FROM inventory i WHERE i.orderitems_id=o.id) AS ship,| if $form->{type} ne 'trans_packing_list';
    $query .= qq|o.ship,| if $form->{type} eq 'trans_packing_list';
    $query .= qq|o.project_id, o.serialnumber, pr.projectnumber,o.qty,
		 o.sellprice, o.unit, o.discount,o.reqdate,| if $form->{type} ne 'trans_packing_list';  #pasztor
    $query .= qq|p.unit,| if $form->{type} eq 'trans_packing_list';  #pasztor
    $query .= qq|pg.partsgroup, p.partsgroup_id, p.partnumber AS sku,
		 p.listprice, t.description AS partsgrouptranslation
		 FROM $fromtable o
		 |;
    $query .= qq| JOIN parts p ON (o.parts_id = p.id)
		 LEFT JOIN chart c1 ON (p.inventory_accno_id = c1.id)
		 LEFT JOIN chart c2 ON (p.income_accno_id = c2.id)
		 LEFT JOIN chart c3 ON (p.expense_accno_id = c3.id)|;
    $query .= qq|LEFT JOIN project pr ON (o.project_id = pr.id)| if $form->{type} ne 'trans_packing_list';  #pasztor
    $query .= qq| LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		 LEFT JOIN translation t ON (t.trans_id = p.partsgroup_id AND t.language_code = '$form->{language_code}')
		 WHERE o.trans_id = $form->{id}
                 ORDER BY o.$oid{$myconfig->{dbdriver}}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    # foreign exchange rates
    &exchangerate_defaults($dbh, $form);

    # query for price matrix
    my $pmh = &price_matrix_query($dbh, $form);
    
    # taxes
    $query = qq|SELECT c.accno
		FROM chart c
		JOIN partstax pt ON (pt.chart_id = c.id)
		WHERE pt.parts_id = ?|;
    my $tth = $dbh->prepare($query) || $form->dberror($query);
   
    my $taxrate;
    my $ptref;
    my $sellprice;
    my $listprice;
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
#pasztor
      if ($form->{type} ne 'trans_packing_list') {
        ($decimalplaces) = ($ref->{sellprice} =~ /\.(\d+)/);
        $decimalplaces = length $decimalplaces;
        $decimalplaces = 2 unless $decimalplaces;

        $tth->execute($ref->{id});
        $ref->{taxaccounts} = "";
        $taxrate = 0;
      
        while ($ptref = $tth->fetchrow_hashref(NAME_lc)) {
          $ref->{taxaccounts} .= "$ptref->{accno} ";
          $taxrate += $form->{"$ptref->{accno}_rate"};
        }
        $tth->finish;
        chop $ref->{taxaccounts};

        # preserve prices
        $sellprice = $ref->{sellprice};
        $listprice = $ref->{listprice};
      
        # multiply by exchnagerate
        $ref->{sellprice} = $form->round_amount($ref->{sellprice} * $form->{$form->{currency}}, $decimalplaces);
        $ref->{listprice} = $form->round_amount($ref->{listprice} * $form->{$form->{currency}}, $decimalplaces);
      
        # partnumber and price matrix
        &price_matrix($pmh, $ref, $form->{transdate}, $decimalplaces, $form, $myconfig, 1);

        $ref->{sellprice} = $sellprice;
        $ref->{listprice} = $listprice;
      }

      $ref->{partsgroup} = $ref->{partsgrouptranslation} if $ref->{partsgrouptranslation};
      
      push @{ $form->{form_details} }, $ref;
      
    }
    $sth->finish;

  } else {

    # get last name used
    $form->lastname_used($dbh, $myconfig, $form->{vc}) unless $form->{"$form->{vc}_id"};
    delete $form->{notes};

  }

  $dbh->disconnect;

}


sub price_matrix_query {
  my ($dbh, $form) = @_;

  my $query;
  my $sth;

  if ($form->{customer_id}) {
    $query = qq|SELECT p.*, g.pricegroup
             FROM partscustomer p
	     LEFT JOIN pricegroup g ON (g.id = p.pricegroup_id)
	     WHERE p.parts_id = ?
	     AND p.customer_id = $form->{customer_id}

	     UNION

	     SELECT p.*, g.pricegroup
	     FROM partscustomer p
	     LEFT JOIN pricegroup g ON (g.id = p.pricegroup_id)
	     JOIN customer c ON (c.pricegroup_id = g.id)
	     WHERE p.parts_id = ?
	     AND c.id = $form->{customer_id}

	     UNION

	     SELECT p.*, '' AS pricegroup
	     FROM partscustomer p
	     WHERE p.customer_id = 0
	     AND p.pricegroup_id = 0
	     AND p.parts_id = ?

	     ORDER BY customer_id DESC, pricegroup_id DESC, pricebreak
	     |;
    $sth = $dbh->prepare($query) || $form->dberror($query);
  }
  
  if ($form->{vendor_id}) {
    # price matrix and vendor's partnumber
    $query = qq|SELECT partnumber
		FROM partsvendor
		WHERE parts_id = ?
		AND vendor_id = $form->{vendor_id}|;
    $sth = $dbh->prepare($query) || $form->dberror($query);
  }
  
  $sth;

}


sub price_matrix {
  my ($pmh, $ref, $transdate, $decimalplaces, $form, $myconfig, $init) = @_;

  $ref->{pricematrix} = "";
  my $customerprice = 0;
  my $pricegroup = 0;
  my $sellprice;
  my $mref;
  
  # depends if this is a customer or vendor
  if ($form->{customer_id}) {
    $pmh->execute($ref->{id}, $ref->{id}, $ref->{id});

    while ($mref = $pmh->fetchrow_hashref(NAME_lc)) {

      # check date
      if ($mref->{validfrom}) {
	next if $transdate < $form->datetonum($mref->{validfrom}, $myconfig);
      }
      if ($mref->{validto}) {
	next if $transdate > $form->datetonum($mref->{validto}, $myconfig);
      }

      # convert price
      $sellprice = $form->round_amount($mref->{sellprice} * $form->{$mref->{curr}}, $decimalplaces);
      
      if ($mref->{customer_id}) {
	$ref->{sellprice} = $sellprice unless $mref->{pricebreak};
	$ref->{pricematrix} .= "$mref->{pricebreak}:$sellprice ";
	$customerprice = 1;
      }

      if ($mref->{pricegroup_id}) {
	if (! $customerprice) {
	  $ref->{sellprice} = $sellprice unless $mref->{pricebreak};
	  $ref->{pricematrix} .= "$mref->{pricebreak}:$sellprice ";
	  $pricegroup = 1;
	}
      }

      if (! $customerprice && ! $pricegroup) {
	$ref->{sellprice} = $sellprice unless $mref->{pricebreak};
	$ref->{pricematrix} .= "$mref->{pricebreak}:$sellprice ";
      }

    }
    $pmh->finish;

    if ($ref->{pricematrix} !~ /^0:/) {
      if ($init) {
	$sellprice = $form->round_amount($ref->{sellprice}, $decimalplaces);
      } else {
	$sellprice = $form->round_amount($ref->{sellprice} * (1 - $form->{tradediscount}), $decimalplaces);
      }
      $ref->{pricematrix} = "0:$sellprice ".$ref->{pricematrix};
    }
    chop $ref->{pricematrix};

  }


  if ($form->{vendor_id}) {
    $pmh->execute($ref->{id});
    
    $mref = $pmh->fetchrow_hashref(NAME_lc);

    if ($mref->{partnumber}) {
      $ref->{partnumber} = $mref->{partnumber};
    }

    if ($mref->{lastcost}) {
      # do a conversion
      $ref->{sellprice} = $form->round_amount($mref->{lastcost} * $form->{$mref->{curr}}, $decimalplaces);
    }
    $pmh->finish;

    $ref->{sellprice} *= 1;

    # add 0:price to matrix
    $ref->{pricematrix} = "0:$ref->{sellprice}";

  }

}


sub exchangerate_defaults {
  my ($dbh, $form) = @_;

  my $var;
  my $buysell = ($form->{vc} eq "customer") ? "buy" : "sell";
  
  # get default currencies
  my $query = qq|SELECT substr(curr,1,3), curr FROM defaults|;
  my $eth = $dbh->prepare($query) || $form->dberror($query);
  $eth->execute;
  ($form->{defaultcurrency}, $form->{currencies}) = $eth->fetchrow_array;
  $eth->finish;

  $query = qq|SELECT $buysell
              FROM exchangerate
	      WHERE curr = ?
	      AND transdate = ?|;
  my $eth1 = $dbh->prepare($query) || $form->dberror($query);
  $query = qq~SELECT max(transdate || ' ' || $buysell || ' ' || curr)
              FROM exchangerate
	      WHERE curr = ?~;
  my $eth2 = $dbh->prepare($query) || $form->dberror($query);

  # get exchange rates for transdate or max
  foreach $var (split /:/, substr($form->{currencies},4)) {
    $eth1->execute($var, $form->{transdate});
    ($form->{$var}) = $eth1->fetchrow_array;
    if (! $form->{$var} ) {
      $eth2->execute($var);
      
      ($form->{$var}) = $eth2->fetchrow_array;
      ($null, $form->{$var}) = split / /, $form->{$var};
      $form->{$var} = 1 unless $form->{$var};
      $eth2->finish;
    }
    $eth1->finish;
  }

  $form->{$form->{defaultcurrency}} = 1;
      
}


sub order_details {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $query;
  my $sth;
    
  my $item;
  my $i;
  my @sortlist = ();
  my $projectnumber;
  my $projectnumber_id;
  my $translation;
  my $partsgroup;

  my %oid = ( 'Pg'	=> 'oid',
              'PgPP'	=> 'oid',
              'Oracle'	=> 'rowid',
	      'DB2'	=> '1=1'
	    );
  
  # sort items by project and partsgroup
  for $i (1 .. $form->{rowcount}) {
    $projectnumber = "";
    $partsgroup = "";
    $projectnumber_id = 0;
    if ($form->{"projectnumber_$i"} && $form->{groupprojectnumber}) {
      ($projectnumber, $projectnumber_id) = split /--/, $form->{"projectnumber_$i"};
    }
    if ($form->{"partsgroup_$i"} && $form->{grouppartsgroup}) {
      ($partsgroup) = split /--/, $form->{"partsgroup_$i"};
    }
    push @sortlist, [ $i, "$projectnumber$partsgroup", $projectnumber, $projectnumber_id, $partsgroup ];

    # sort the whole thing by project and group
    @sortlist = sort { $a->[1] cmp $b->[1] } @sortlist;

  }

  # if there is a warehouse limit picking
  if ($form->{warehouse_id} && $form->{formname} =~ /(pick|packing)_list/) {
    # run query to check for inventory
    $query = qq|SELECT sum(qty) AS qty
                FROM inventory
		WHERE parts_id = ?
		AND warehouse_id = ?|;
    $sth = $dbh->prepare($query) || $form->dberror($query);

    for $i (1 .. $form->{rowcount}) {
      $sth->execute($form->{"id_$i"}, $form->{warehouse_id}) || $form->dberror;

      ($qty) = $sth->fetchrow_array;
      $sth->finish;

      $form->{"qty_$i"} = 0 if $qty == 0;
      
      if ($form->parse_amount($myconfig, $form->{"ship_$i"}) > $qty) {
	$form->{"ship_$i"} = $form->format_amount($myconfig, $qty);
      }
    }
  }
    
  my @taxaccounts;
  my %taxaccounts;
  my $taxrate;
  my $taxamount;
  my $taxbase;
  my $taxdiff;
 
  $query = qq|SELECT p.description, t.description
              FROM project p
	      LEFT JOIN translation t ON (t.trans_id = p.id AND t.language_code = '$form->{language_code}')
	      WHERE id = ?|;
  my $prh = $dbh->prepare($query) || $form->dberror($query);

  my $runningnumber = 1;
  my $sameitem = "";
  my $subtotal;
  my $k = scalar @sortlist;
  my $j = 0;
  
  foreach $item (@sortlist) {
    $i = $item->[0];
    $j++;

    if ($form->{groupprojectnumber} || $form->{grouppartsgroup}) {
      if ($item->[1] ne $sameitem) {

        $projectnumber = "";
	if ($form->{groupprojectnumber} && $item->[2]) {
	  # get project description
	  $prh->execute($item->[3]) || $form->dberror($query);

	  ($projectnumber, $translation) = $prh->fetchrow_array;
	  $prh->finish;

	  $projectnumber = ($translation) ? "$item->[2], $translation" : "$item->[2], $projectnumber";
	}
	  
	if ($form->{grouppartsgroup} && $item->[4]) {
	  $projectnumber .= " / " if $projectnumber;
	  $projectnumber .= $item->[4];
	}
	
	$form->{projectnumber} = $projectnumber;
	$form->format_string(projectnumber);
	
	push(@{ $form->{description} }, qq|$form->{projectnumber}|);
	$sameitem = $item->[1];

	map { push(@{ $form->{$_} }, "") } qw(runningnumber number sku qty ship unit bin serialnumber reqdate projectnumber sellprice listprice netprice discount discountrate linetotal);
      }
    }

    $form->{"qty_$i"} = $form->parse_amount($myconfig, $form->{"qty_$i"});
    foreach $taxitem (split / /, $form->{"taxaccounts_$i"}) {
      if ($form->{"${taxitem}_rate"}){
          if ($form->datetonum($form->{transdate}, $myconfig) >= $form->datetonum($form->{"${taxitem}_validfrom"}, $myconfig)
              && $form->datetonum($form->{transdate}, $myconfig) <= $form->datetonum($form->{"${taxitem}_validto"}, $myconfig)){
             $linetaxrate = $form->{"${taxitem}_rate"};
          }  
      }  
    }  

    if ($form->{"qty_$i"} != 0) {

      # add number, description and qty to $form->{number}, ....
      push(@{ $form->{runningnumber} }, $runningnumber++);
      push(@{ $form->{number} }, qq|$form->{"partnumber_$i"}|);
      push(@{ $form->{sku} }, qq|$form->{"sku_$i"}|);
      push(@{ $form->{description} }, qq|$form->{"description_$i"}|);
      push(@{ $form->{qty} }, $form->format_amount($myconfig, $form->{"qty_$i"}));
      push(@{ $form->{ship} }, $form->format_amount($myconfig, $form->{"ship_$i"}));
      push(@{ $form->{unit} }, qq|$form->{"unit_$i"}|);
      push(@{ $form->{bin} }, qq|$form->{"bin_$i"}|);
      push(@{ $form->{serialnumber} }, qq|$form->{"serialnumber_$i"}|);
      push(@{ $form->{reqdate} }, qq|$form->{"reqdate_$i"}|);
      push(@{ $form->{projectnumber} }, qq|$form->{"projectnumber_$i"}|);
      
      my $sellprice = $form->{taxincluded} ? $form->parse_amount($myconfig,$form->{"sellprice_$i"})/(1+$linetaxrate) : $form->parse_amount($myconfig, $form->{"sellprice_$i"});
      push(@{ $form->{sellprice} }, $form->format_amount($myconfig, $sellprice,2));
    
      push(@{ $form->{listprice} }, $form->{"listprice_$i"});

      my ($dec) = ($sellprice =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > 2) ? $dec : 2;

      
      my $discount = $form->round_amount($sellprice * $form->parse_amount($myconfig, $form->{"discount_$i"}) / 100, $decimalplaces);

      # keep a netprice as well, (sellprice - discount)
      $form->{"netprice_$i"} = $sellprice - $discount;

      my $linetotal = $form->round_amount($form->{"qty_$i"} * $form->{"netprice_$i"}, 2);

      push(@{ $form->{netprice} }, ($form->{"netprice_$i"} != 0) ? $form->format_amount($myconfig, $form->{"netprice_$i"}, $decimalplaces) : " ");
      
      $discount = ($discount != 0) ? $form->format_amount($myconfig, $discount * -1, $decimalplaces) : " ";
      $linetotal = ($linetotal != 0) ? $linetotal : " ";

      push(@{ $form->{discount} }, $discount);
      push(@{ $form->{discountrate} }, $form->format_amount($myconfig, $form->{"discount_$i"}));
      
      $form->{ordtotal} += $linetotal;

      # this is for the subtotals for grouping
      $subtotal += $linetotal;

      push(@{ $form->{linetotal} }, $form->format_amount($myconfig, $linetotal, 2));
      
#kabai      

      @taxaccounts = "";
      foreach my $item (split / /, $form->{"taxaccounts_$i"}) {
        if ($form->{"${item}_rate"}){
            if ($form->datetonum($form->{transdate}, $myconfig) >= $form->datetonum($form->{"${item}_validfrom"}, $myconfig)
		&& $form->datetonum($form->{transdate},$myconfig) <= $form->datetonum($form->{"${item}_validto"}, $myconfig)){
               push @taxaccounts, $item;
            }  
        }  
      }   
#kabai
      $taxrate = 0;
      
      map { $taxrate += $form->{"${_}_rate"} } @taxaccounts;
      $taxamount = $linetotal * $taxrate;
      $taxbase = $linetotal;


      if ($form->round_amount($taxamount, 2) != 0) {
	foreach my $item (@taxaccounts) {
	  $taxaccounts{$item} += $taxamount * $form->{"${item}_rate"} / $taxrate;
	  $taxbase{$item} += $taxbase;
	}
      }

      if ($form->{"assembly_$i"}) {
	my $sm = "";
	
        # get parts and push them onto the stack
	my $sortorder = "";
	if ($form->{grouppartsgroup}) {
	  $sortorder = qq|ORDER BY pg.partsgroup, a.$oid{$myconfig->{dbdriver}}|;
	} else {
	  $sortorder = qq|ORDER BY a.$oid{$myconfig->{dbdriver}}|;
	}
	
	$query = qq|SELECT p.partnumber, p.description, p.unit, a.qty,
	            pg.partsgroup, p.partnumber AS sku
	            FROM assembly a
		    JOIN parts p ON (a.parts_id = p.id)
		    LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		    WHERE a.bom = '1'
		    AND a.id = '$form->{"id_$i"}'
		    $sortorder|;
        $sth = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
	  if ($form->{grouppartsgroup} && $ref->{partsgroup} ne $sm) {
	    map { push(@{ $form->{$_} }, "") } qw(number sku unit qty runningnumber ship bin serialnumber reqdate projectnumber sellprice listprice netprice discount discountrate linetotal);
	    $sm = ($ref->{partsgroup}) ? $ref->{partsgroup} : "--";
	    push(@{ $form->{description} }, $sm);
	  }
	  
	  push(@{ $form->{description} }, $form->format_amount($myconfig, $ref->{qty} * $form->{"qty_$i"}) . qq|, $ref->{partnumber}, $ref->{description}|);

          map { push(@{ $form->{$_} }, "") } qw(number sku unit qty runningnumber ship bin serialnumber reqdate projectnumber sellprice listprice netprice discount discountrate linetotal);
	  
	}
	$sth->finish;
      }

    }

    # add subtotal
    if ($form->{groupprojectnumber} || $form->{grouppartsgroup}) {
      if ($subtotal) {
	if ($j < $k) {
	  # look at next item
	  if ($sortlist[$j]->[1] ne $sameitem) {

	    map { push(@{ $form->{$_} }, "") } qw(runningnumber number sku qty ship unit bin serialnumber reqdate projectnumber sellprice listprice netprice discount discountrate);

	    push(@{ $form->{description} }, $form->{groupsubtotaldescription});

	    push(@{ $form->{linetotal} }, $form->format_amount($myconfig, $subtotal, 2));
	    $subtotal = 0;
	  }

	} else {

	  map { push(@{ $form->{$_} }, "") } qw(runningnumber number sku qty ship unit bin serialnumber reqdate projectnumber sellprice listprice netprice discount discountrate);

	  # got last item
	  push(@{ $form->{description} }, $form->{groupsubtotaldescription});
	  push(@{ $form->{linetotal} }, $form->format_amount($myconfig, $subtotal, 2));
	  $subtotal = 0;
	}
      }
    }
  }


  my $tax = 0;
  foreach my $item (sort keys %taxaccounts) {
    if ($form->round_amount($taxaccounts{$item}, 2) != 0) {
      push(@{ $form->{taxbase} }, $form->format_amount($myconfig, $taxbase{$item}, 2));
      
      $tax += $taxamount = $form->round_amount($taxaccounts{$item}, 2);
      
      push(@{ $form->{tax} }, $form->format_amount($myconfig, $taxamount, 2));
      push(@{ $form->{taxdescription} }, $form->{"${item}_description"});
      push(@{ $form->{taxrate} }, $form->format_amount($myconfig, $form->{"${item}_rate"} * 100));
      push(@{ $form->{taxnumber} }, $form->{"${item}_taxnumber"});
    }
  }


  $form->{subtotal} = $form->format_amount($myconfig, $form->{ordtotal}, 2);
  $form->{ordtotal} = ($form->{taxincluded}) ? $form->{ordtotal} : $form->{ordtotal} + $tax;
  
  # format amounts
  $form->{quototal} = $form->{ordtotal} = $form->format_amount($myconfig, $form->{ordtotal}, 2);

  # myconfig variables
  map { $form->{$_} = $myconfig->{$_} } (qw(company address tel fax signature businessnumber));
  $form->{username} = $myconfig->{name};

  $dbh->disconnect;

}


sub project_description {
  my ($self, $dbh, $id) = @_;

  my $query = qq|SELECT description
                 FROM project
		 WHERE id = $id|;
  ($_) = $dbh->selectrow_array;
  
  $_;

}


sub get_warehouses {
  my ($self, $myconfig, $form) = @_;
  
  my $dbh = $form->dbconnect($myconfig);
  # setup warehouses
  my $query = qq|SELECT id, description
                 FROM warehouse
		 ORDER BY 2|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_warehouses} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}


sub save_inventory {
  my ($self, $myconfig, $form) = @_;

  my ($null, $warehouse_id) = split /--/, $form->{warehouse};
  $warehouse_id *= 1;

  my $employee_id;
  ($null, $employee_id) = split /--/, $form->{employee};

  my $ml = ($form->{type} =~ /(invoice|ship_order)/) ? -1 : 1;
  
  my $dbh = $form->dbconnect_noauto($myconfig);
  my $sth;
  my $wth;
  my $serialnumber;
  my $ship;
#kabai
  my ($itemsdb, $idname);
  if ($form->{type} eq "invoice"){
    $itemsdb = "invoice";
    $idname = "iris";
  }else{
    $itemsdb = "orderitems";    
    $idname = "oe";
  }
#kabai

  $query = qq|SELECT serialnumber, ship
              FROM $itemsdb
              WHERE trans_id = ?
	      AND id = ?
	      FOR UPDATE|;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  for my $i (1 .. $form->{rowcount}) {

#kabai BUG(?)
    #$ship = (abs($form->{"ship_$i"}) > abs($form->{"qty_$i"})) ? $form->{"qty_$i"} : $form->{"ship_$i"};
    if (abs($form->{"ship_$i"}) > abs($form->{"qty_$i"})){
     $form->{"ship_$i"} = $form->{"qty_$i"};
     $ship = $form->{"qty_$i"};
    }else{
     $ship = $form->{"ship_$i"};
    }
 
#kabai
    $ship = 0 if (!$form->{"inventory_accno_$i"}  && !$form->{"assembly_$i"}); #no inventory for services

    if ($ship != 0) {

      $ship *= $ml;
#kabai +notes
      $query = qq|INSERT INTO inventory (parts_id, warehouse_id,
                  qty, ${idname}_id, ${itemsdb}_id, shippingdate, employee_id,notes)
                  VALUES ($form->{"id_$i"}, $warehouse_id,
		  $ship, $form->{"id"},
		  $form->{"${itemsdb}_id_$i"}, '$form->{shippingdate}',
		  $employee_id, '$form->{notes}')|;

      $dbh->do($query) || $form->dberror($query);
     
      # add serialnumber, ship to orderitems
      $sth->execute($form->{id}, $form->{"${itemsdb}_id_$i"}) || $form->dberror;
      ($serialnumber, $ship) = $sth->fetchrow_array;
      $sth->finish;

      $serialnumber .= " " if $serialnumber;
      $serialnumber .= qq|$form->{"serialnumber_$i"}|;
      $ship += $form->{"ship_$i"};

      $query = qq|UPDATE $itemsdb SET
                  serialnumber = '$serialnumber',
		  ship = $ship
		  WHERE trans_id = $form->{id}
		  AND id = $form->{"${itemsdb}_id_$i"}|;
      $dbh->do($query) || $form->dberror($query);

      if ($form->{type} =~ /order/){
       # update order with ship via
       $query = qq|UPDATE oe SET
                   shippingpoint = '$form->{shippingpoint}',
                   shipvia = '$form->{shipvia}'
                   WHERE id = $form->{id}|;
       $dbh->do($query) || $form->dberror($query);
      }
		  
      # update onhand for parts
      $form->update_balance($dbh,
                            "parts",
                            "onhand",
                            qq|id = $form->{"id_$i"}|,
                            $form->{"ship_$i"} * $ml);

    }
  }

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


sub adj_onhand {
  my ($dbh, $form, $ml) = @_;

  my $query = qq|SELECT oi.parts_id, oi.ship, p.inventory_accno_id, p.assembly
                 FROM orderitems oi
		 JOIN parts p ON (p.id = oi.parts_id)
                 WHERE oi.trans_id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $query = qq|SELECT sum(p.inventory_accno_id)
	      FROM parts p
	      JOIN assembly a ON (a.parts_id = p.id)
	      WHERE a.id = ?|;
  my $ath = $dbh->prepare($query) || $form->dberror($query);

  my $ispa;
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    if ($ref->{inventory_accno_id} || $ref->{assembly}) {

      # do not update if assembly consists of all services
      if ($ref->{assembly}) {
	$ath->execute($ref->{parts_id}) || $form->dberror($query);

        ($ispa) = $ath->fetchrow_array;
	$ath->finish;
	
	next unless $ispa;
	
      }

      # adjust onhand in parts table
      $form->update_balance($dbh,
			    "parts",
			    "onhand",
			    qq|id = $ref->{parts_id}|,
			    $ref->{ship} * $ml);
    }
  }
  
  $sth->finish;

}


sub adj_inventory {
  my ($dbh, $myconfig, $form) = @_;

  my %oid = ( 'Pg'	=> 'oid',
              'PgPP'	=> 'oid',
              'Oracle'	=> 'rowid',
	      'DB2'	=> '1=1'
	    );
  
  # increase/reduce qty in inventory table
  my $query = qq|SELECT oi.id, oi.parts_id, oi.ship
                 FROM orderitems oi
                 WHERE oi.trans_id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $query = qq|SELECT $oid{$myconfig->{dbdriver}} AS oid, qty,
                     (SELECT SUM(qty) FROM inventory
                      WHERE oe_id = $form->{id}
		      AND orderitems_id = ?) AS total
	      FROM inventory
              WHERE oe_id = $form->{id}
	      AND orderitems_id = ?|;
  my $ith = $dbh->prepare($query) || $form->dberror($query);
  
  my $qty;
  my $ml = ($form->{type} =~ /(ship|sales)_order/) ? -1 : 1;
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    $ith->execute($ref->{id}, $ref->{id}) || $form->dberror($query);

    while (my $inv = $ith->fetchrow_hashref(NAME_lc)) {

      if (($qty = (($inv->{total} * $ml) - $ref->{ship})) >= 0) {
	$qty = $inv->{qty} if ($qty > ($inv->{qty} * $ml));
	
#kabai   $form->update_balance($dbh,
        #                      "inventory",
        #                      "qty",
        #                      qq|$oid{$myconfig->{dbdriver}} = $inv->{oid}|,
        #                      $qty * -1 * $ml);
      }
    }
    $ith->finish;

  }
  $sth->finish;

  # delete inventory entries if qty = 0
 # kabai $query = qq|DELETE FROM inventory
  #            WHERE oe_id = $form->{id}
#	      AND qty = 0|;
 # $dbh->do($query) || $form->dberror($query);

}


sub get_inventory {
  my ($self, $myconfig, $form) = @_;
  
  my ($null, $warehouse_id) = split /--/, $form->{warehouse};
  $warehouse_id *= 1;

#pasztor
  my ($null, $warehousefrom_id) = split /--/, $form->{warehousefrom};
  $warehousefrom_id *= 1;

  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT p.id, p.partnumber, p.description, p.onhand,
                 pg.partsgroup
                 FROM parts p
		 LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
	         WHERE (p.inventory_accno_id IS NOT NULL OR assembly IS TRUE)|;
#kabai TRANSFER_FROM_NEG_WAREHOUSE WHERE p.onhand > 0
  if ($form->{partnumber}) {
    $var = $form->like(lc $form->{partnumber});
    $query .= "
                 AND lower(p.partnumber) LIKE '$var'";
  }
  if ($form->{description}) {
    $var = $form->like(lc $form->{description});
    $query .= "
                 AND lower(p.description) LIKE '$var'";
  }
  if ($form->{partsgroup}) {
    my ($partsgroup) = split /--/, $form->{partsgroup};
    $var = $form->like(lc $partsgroup);
    $query .= "
                 AND lower(pg.partsgroup) LIKE '$var'";
  }
  
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
#pasztor
  $query = qq|SELECT sum(i.qty)
              FROM inventory i
	      WHERE i.parts_id = ?
	      AND i.warehouse_id = $warehousefrom_id|;
  $wth = $dbh->prepare($query) || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

    $wth->execute($ref->{id}) || $form->dberror;

    while (($qty, $warehouse, $warehouse_id) = $wth->fetchrow_array) {

      push @{ $form->{all_inventory} }, {'id' => $ref->{id},
                                         'partnumber' => $ref->{partnumber},
                                         'description' => $ref->{description},
					 'partsgroup' => $ref->{partsgroup},
					 'qty' => $qty
					};# if $qty != 0;
# kabai if $qty > 0
    }
    $wth->finish;
  }
  $sth->finish;

  $dbh->disconnect;

  # sort inventory
  @{ $form->{all_inventory} } = sort { $a->{$form->{sort}} cmp $b->{$form->{sort}} } @{ $form->{all_inventory} };
}



sub transfer {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query = qq|INSERT INTO inventory
                 (oe_id, warehouse_id, parts_id, qty, shippingdate, employee_id, orderitems_id, notes)
		 VALUES ($form->{id},?, ?, ?, ?, ?, ?, '$form->{notes}')|;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);

#pasztor
  $query = qq|SELECT id FROM szlitems 
		WHERE trans_id=$form->{id} AND parts_id=? AND ship=? LIMIT 1|;
  $ssth = $dbh->prepare($query) || $form->dberror($query);

  for my $i (1 .. $form->{rowcount}) {
    $qty = $form->parse_amount($myconfig, $form->{"transfer_$i"});

#kabai ALLOW_NEGATIVE_WAREHOUSE
    #$qty = $form->{"qty_$i"} if ($qty > $form->{"qty_$i"});

    if ($qty) {
#pasztor
      $ssth->execute($form->{"id_$i"}, $qty);
      ($szlitems_id) = $ssth->fetchrow_array;
      $ssth->finish;
      # to warehouse
      $sth->execute($form->{warehouse_id}, $form->{"id_$i"}, $qty, $form->{shipdate}, $form->{employee_id}, $szlitems_id) || $form->dberror;
      $sth->finish;
#pasztor
      $sth->execute($form->{"warehousefrom_id"}, $form->{"id_$i"}, $qty * -1, $form->{shipdate}, $form->{employee_id}, $szlitems_id) || $form->dberror;
      $sth->finish;
    }

  }

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}


#pasztor
sub save_transfer {
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn off autocommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $sth;
  my $null;
  my $finalship;
  my $exchangerate = 0;

  ($null, $form->{employee_id}) = split /--/, $form->{employee};
  unless ($form->{employee_id}) {
    ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
    $form->{employee} = "$form->{employee}--$form->{employee_id}";
  }

  my $uid = time;
  $uid .= $form->{login};

  $query = qq|INSERT INTO szl (szlnumber, employee_id)
		VALUES ('$uid', $form->{employee_id})|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|SELECT id FROM szl
                WHERE szlnumber = '$uid'|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  ($form->{id}) = $sth->fetchrow_array;
  $sth->finish;

  for my $i (1 .. $form->{rowcount}) {

    $qty = $form->parse_amount($myconfig, $form->{"transfer_$i"});

    if ($qty) {

      $query = qq|INSERT INTO szlitems (trans_id, parts_id, description, ship)
                  VALUES ($form->{id}, $form->{"id_$i"},'$form->{"description_$i"}', $qty)|;
      $dbh->do($query) || $form->dberror($query);
    }
  }


  ($null, $form->{department_id}) = split(/--/, $form->{department});
  $form->{department_id} *= 1;

  $query = qq|UPDATE szl set
	      szlnumber = |.$dbh->quote($form->{szlnumber}).qq|,
              transdate = '$form->{transdate}',
	      to_warehouse_id = $form->{warehouse_id},
	      intnotes = |.$dbh->quote($form->{intnotes}).qq|,
	      department_id = $form->{department_id},
	      employee_id = $form->{employee_id},
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      shipdate = '$form->{shipdate}',
	      warehouse_id = $form->{warehousefrom_id}
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  # save printed, emailed, queued
  $form->save_status($dbh);

  my %audittrail = ( tablename	=> 'szl',
                     reference	=> $form->{szlnumber},
		     formname	=> $form->{type},
		     action	=> 'saved',
		     id		=> $form->{id} );

  $form->audittrail($dbh, "", \%audittrail);

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}



1;

