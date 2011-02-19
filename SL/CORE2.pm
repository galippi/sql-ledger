#=====================================================================
# SQL-Ledger Accounting
# Copyright (C) 2000
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
# Inventory Control backend
#
#======================================================================

package CORE2;

sub get_oe_id2 {
  my ($self, $myconfig, $form) = @_;
  
  my $dbh = $form->dbconnect($myconfig);
  my $where2 = $form->{vc} eq "vendor" ? "customer_id" : "vendor_id";  
  my $query = qq|SELECT id FROM oe WHERE  ordnumber = '$form->{ordnumber}' AND $where2 = 0|;     

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  ($form->{oe_id}) = $sth->fetchrow_array;    

  $sth->finish;

  $dbh->disconnect;
}

sub get_ship {
  my ($self, $myconfig, $form) = @_;
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

#kabai
  my ($itemsdb,$iasswhere);
  if ($form->{type} eq "invoice"){
    $itemsdb = "invoice";
    $iasswhere = " AND i.assemblyitem IS FALSE";
  }else{
    $itemsdb = "orderitems";    
  }
#kabai
  my $query = qq|SELECT i.id,ship,qty,parts_id,
		 serialnumber, accno, assembly
		 FROM $itemsdb i
		 LEFT JOIN parts p ON (p.id = i.parts_id)
		 LEFT JOIN chart c ON (p.inventory_accno_id = c.id)
		 WHERE trans_id = $form->{id} $iasswhere|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  my $k = 1;
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
      $form->{"${itemsdb}_id_$k"} = $ref->{id};
      $form->{"ship_$k"} = $form->{"qty_$k"} = $ref->{qty};
      $form->{"id_$k"} = $ref->{parts_id};
      $form->{"serialnumber_$k"} = $ref->{serialnumber};
      $form->{"inventory_accno_$k"} = $ref->{accno};
      $form->{"assembly_$k"} = $ref->{assembly};
      $k++;
  }
  $sth->finish;
  $dbh->disconnect;
}

sub update_oe_id {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my $fromdb = $form->{vc} eq "vendor" ? "ap" : "ar";
  my $id = $form->{vc} eq "vendor" ? "$form->{ap_id}" : "$form->{ar_id}";  

  my $query = qq|UPDATE $fromdb SET oe_id = $form->{id} WHERE  id = $id|;     

  my $sth = $dbh->prepare($query);
  $dbh->do($query) || $form->dberror($query);
  
  $sth->finish;
  $dbh->disconnect;


}

sub restock_assemblies {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
   
#kabai ASSEMBLY_HISTORY
  #@a = localtime; $a[5] += 1900; $a[4]++;
  #my $shippingdate = "$a[5]-$a[4]-$a[3]";
#kabai

  ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
    
  for my $i (1 .. $form->{rowcount}) {

    $form->{"qty_$i"} = $form->parse_amount($myconfig, $form->{"qty_$i"});
#$form->debug2;
    if ($form->{"qty_$i"} != 0 && !$form->{"notdeductcomp_$i"}) {
      &adjust_inventory_restock($dbh, $form, $form->{"id_$i"}, $form->{"qty_$i"},$form->{"shippingdate_$i"},$form->{"notes_$i"});
    }
 
    # add inventory record
    if ($form->{"qty_$i"} != 0) {
#kabai +3 ASSEMBLY_HISTORY
      $query = qq|INSERT INTO inventory (warehouse_id, parts_id, qty,
		  shippingdate, employee_id, notes) VALUES (
		  $form->{warehouse_id}, $form->{"id_$i"}, $form->{"qty_$i"}, '$form->{"shippingdate_$i"}',
		  $form->{employee_id}, |.$dbh->quote($form->{"notes_$i"}).qq|)|;
      $dbh->do($query) || $form->dberror($query);
      # update assembly
      $form->update_balance($dbh,
			"parts",
			"onhand",
			qq|id = $form->{"id_$i"}|,
			$form->{"qty_$i"});


    }

  }

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}
sub adjust_inventory_restock { #kabai
  my ($dbh, $form, $id, $qty, $shippingdate, $notes) = @_;

  my $query = qq|SELECT p.id, p.inventory_accno_id, p.assembly, a.qty
		 FROM parts p, assembly a
		 WHERE a.parts_id = p.id
		 AND a.id = $id|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);


  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    my $allocate = $qty * $ref->{qty};
    # is it a service item, then loop
    $ref->{inventory_accno_id} *= 1;
    next if (($ref->{inventory_accno_id} == 0) && !$ref->{assembly});
    
    # adjust parts onhand
    $form->update_balance($dbh,
			  "parts",
			  "onhand",
			  qq|id = $ref->{id}|,
			  $allocate * -1);

    if ($allocate != 0) {
      $query = qq|INSERT INTO inventory (warehouse_id, parts_id, qty,
		  shippingdate, employee_id, notes) VALUES (
		  $form->{warehouse_id}, $ref->{id}, $allocate * -1, '$shippingdate',
		  $form->{employee_id}, '$notes')|;
      $dbh->do($query) || $form->dberror($query);
    }

  }

  $sth->finish;

}


sub assembly_history {
  my ($self, $myconfig, $form) = @_;

   my $var;
  my $null;
  my $where = "1 = 1";

  if ($form->{"partnumber"}) {
    $var = $form->like(lc $form->{partnumber});
    $where .= " AND lower(p.partnumber) LIKE '$var'";
  }
  if ($form->{"description"}) {
    $var = $form->like(lc $form->{description});
    $where .= " AND lower(p.description) LIKE '$var'";
  }
  if ($form->{"partsgroup"}) {
    $var = $form->like(lc $form->{partsgroup});
    $where .= " AND lower(pg.partsgroup) LIKE '$var'";
  }
  if ($form->{"make"}) {
    $var = $form->like(lc $form->{"make"});
    $where .= " AND lower(m.make) LIKE '$var'";
  }
  if ($form->{"model"}) {
    $var = $form->like(lc $form->{"model"});
    $where .= " AND lower(m.model) LIKE '$var'";
  }

  if ($form->{"drawing"}) {
    $var = $form->like(lc $form->{"drawing"});
    $where .= " AND lower(p.drawing) LIKE '$var'";
  }

  if ($form->{"microfiche"}) {
    $var = $form->like(lc $form->{"microfiche"});
    $where .= " AND lower(p.microfiche) LIKE '$var'";
  }
  if ($form->{"shippingdatefrom"}) {
        $where .= " AND i.shippingdate >='$form->{shippingdatefrom}'";
  }
  if ($form->{"shippingdateto"}) {
        $where .= " AND i.shippingdate <='$form->{shippingdateto}'";
  }
  if ($form->{"warehouse_id"}) {
        $where .= " AND i.warehouse_id = $form->{warehouse_id}";
  }
  if ($form->{"notes"}) {
    $var = $form->like(lc $form->{notes});
    $where .= " AND lower(i.notes) LIKE '$var'";
  }

  my %ordinal = ( 'partnumber' => 2,
                  'description' => 3,
                  'shippingdate' => 5,
                  'notes' => 6,
		  'name' => 10,
		  'warehouse' => 7,
		  'partsgroup' => 12

		);
  
  my @a = qw(partnumber description shippingdate);
  my $sortorder = $form->sort_order(\@a, \%ordinal);


  # connect to database
  my $dbh = $form->dbconnect($myconfig);

#pasztor
  my $query = qq|

    SELECT p.id, p.partnumber, p.description, i.qty,
    i.shippingdate, i.notes, w.description AS warehouse,

    CASE WHEN i.oe_id IS NOT NULL THEN
      CASE WHEN oe.customer_id=0
      THEN 'vendor'
      ELSE 'customer'
      END
    WHEN i.iris_id IS NOT NULL THEN
      CASE WHEN ar.customer_id IS NULL
      THEN 'vendor'
      ELSE 'customer'
      END
    ELSE NULL
    END AS vc,
	  
    CASE WHEN i.oe_id IS NOT NULL THEN
	CASE WHEN oe.customer_id=0
	THEN (SELECT id FROM ap WHERE oe_id = i.oe_id LIMIT 1)
	ELSE (SELECT id FROM ar WHERE oe_id = i.oe_id LIMIT 1)
	END
    WHEN i.iris_id IS NOT NULL THEN i.iris_id
    ELSE NULL
    END AS iris_id,

    CASE WHEN i.oe_id IS NOT NULL THEN
      CASE WHEN oe.customer_id=0
      THEN (SELECT name FROM vendor WHERE id = oe.vendor_id LIMIT 1)
      ELSE (SELECT name FROM customer WHERE id = oe.customer_id LIMIT 1)
      END
    WHEN i.iris_id IS NOT NULL THEN
      CASE WHEN ar.customer_id IS NULL
      THEN (SELECT name FROM vendor WHERE id = ap.vendor_id LIMIT 1)
      ELSE (SELECT name FROM customer WHERE id = ar.customer_id LIMIT 1)
      END
    ELSE NULL
    END AS name,
    i.oe_id,pg.partsgroup, p.partsgroup_id,
    
    CASE WHEN i.oe_id IS NOT NULL THEN
        CASE WHEN oe.id IS NOT NULL THEN oe.ordnumber
             ELSE szl.szlnumber
        END
    WHEN i.iris_id IS NOT NULL THEN
	CASE WHEN ar.customer_id IS NULL THEN ap.invnumber
	ELSE ar.invnumber
	END
	ELSE NULL
    END AS reference,
    CASE WHEN i.oe_id IS NOT NULL THEN
            CASE WHEN oe.id IS NOT NULL THEN NULL
            ELSE szl.id
            END
        ELSE NULL
    END AS szl_id
    
      FROM inventory i
      LEFT JOIN parts p ON (p.id = i.parts_id)
      LEFT JOIN warehouse w ON (w.id=i.warehouse_id)
      LEFT JOIN makemodel m ON (m.parts_id = i.parts_id)
      LEFT JOIN oe ON (oe.id = i.oe_id)
      LEFT JOIN szl ON (szl.id = i.oe_id)
      LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
      LEFT JOIN ar ON (ar.id = i.iris_id)
      LEFT JOIN ap ON (ap.id = i.iris_id) 
      WHERE $where
      ORDER BY $sortorder|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{assembly_history} }, $ref;
  }
  
  $sth->finish;
  $dbh->disconnect;
  
}


sub adjust_now {

  my ($self, $myconfig, $form) = @_;
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query = qq|SELECT parts_id, sum(qty) AS onhand FROM inventory GROUP BY parts_id |;     
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
    $query = qq|UPDATE parts SET onhand = 0|;
    $dbh->do($query) || $form->dberror($query);
  
  while (my $ref = $sth->fetchrow_hashref()) {  
    my $query = qq|UPDATE parts SET onhand = $ref->{onhand} WHERE id = $ref->{parts_id}|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  $sth->finish;
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
}


sub ischange {
  my ($self, $myconfig, $form) = @_;
  my ($depname, $depid) = split /--/, $form->{department};
  my ($AR) = split /--/, $form->{AR};
 ($null, $form->{customer_id}) = split /--/, $form->{customer} if $form->{customer} =~ /--/;
  $depid = 0 if !$depid;  

  my $dbh = $form->dbconnect_noauto($myconfig);
  my $query = qq|UPDATE ar SET
                 customer_id = $form->{customer_id},
                 department_id = $depid,
                 crdate = '$form->{crdate}',
                 transdate = '$form->{transdate}',
		 duedate = '$form->{duedate}',
		 ordnumber = '$form->{ordnumber}',
		 shippingpoint = '$form->{shippingpoint}',
		 shipvia = '$form->{shipvia}',
		 notes = '$form->{notes}',
		 intnotes = '$form->{intnotes}'
		 WHERE id = $form->{id}|;

  $dbh->do($query) || $form->dberror($query);
  $query = qq| UPDATE dpt_trans SET department_id = $depid WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query= qq|UPDATE acc_trans SET chart_id=(SELECT id FROM chart WHERE accno = '$AR') WHERE
	     chart_id IN (SELECT id FROM chart WHERE link='AR') AND trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq| UPDATE status SET printed = 'f' WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $dbh->commit;
  $dbh->disconnect;
}

sub get_allocated {
  my ($self, $myconfig, $form) = @_;
  my $dbh = $form->dbconnect($myconfig);
  my $onlyminusalloc = "WHERE bought-sold < 0" if $form->{onlyminusalloc};
  my $query = qq| SELECT t1.partnumber,bought,sold,bought-sold AS bs_diff,
  ballocated, sallocated, ballocated-sallocated AS basa_diff
  FROM
  (SELECT partnumber,sum(qty)*-1 AS bought,sum(allocated) AS ballocated
  FROM invoice i
  LEFT JOIN parts p ON (p.id=i.parts_id)
  LEFT JOIN ap ON (ap.id=i.trans_id)
  WHERE ap.transdate <= '$form->{allocdate}' AND p.inventory_accno_id IS NOT NULL
                    GROUP BY partnumber) AS t1
                    LEFT JOIN
                    (SELECT partnumber,sum(qty) AS sold, sum(allocated)*-1 AS sallocated
                    FROM invoice i
                    LEFT JOIN parts p ON (p.id=i.parts_id)
                    LEFT JOIN ar ON (ar.id=i.trans_id)
                    WHERE ar.transdate <= '$form->{allocdate}' AND p.inventory_accno_id IS NOT NULL
                    GROUP BY partnumber) AS t2 ON (t1.partnumber=t2.partnumber)
                    $onlyminusalloc ORDER by bs_diff,partnumber  ASC |;
      my $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{get_allocated} }, $ref;
  }
								      
  $sth->finish;
  $dbh->disconnect;
}
sub init_cogs {
  my ($self, $myconfig, $form) = @_;
  my $dbh = $form->dbconnect($myconfig);
  my $query;
    $query = qq|UPDATE invoice SET allocated = 0|;
    $dbh->do($query) || $form->dberror($query);
    $query = qq|DELETE FROM cogs|;
    $dbh->do($query) || $form->dberror($query);

      $query = qq| SELECT trans_id, ar.transdate
                FROM invoice i
                  LEFT JOIN ar ON (ar.id = i.trans_id)
                  LEFT JOIN parts p ON (p.id = i.parts_id)
                  WHERE trans_id IN (SELECT id FROM ar)
                  AND p.inventory_accno_id IS NOT NULL
                 GROUP BY trans_id, ar.transdate
                  ORDER BY 2,1 ASC |;
      my $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);

      while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
        push @{ $form->{get_allinvoice} }, $ref;
      }
								      
      $sth->finish;
      $dbh->disconnect;   
} 

sub get_nonallocated {
  my ($self, $myconfig, $form) = @_;
  my $dbh = $form->dbconnect($myconfig);
  my $query;
  
  $query = qq| SELECT trans_id, ar.transdate
               FROM invoice i
                  LEFT JOIN ar ON (ar.id = i.trans_id)
                  LEFT JOIN parts p ON (p.id = i.parts_id)
                  WHERE trans_id IN (SELECT id FROM ar)
                  AND ar.transdate <= '$form->{allocdate}' AND p.inventory_accno_id IS NOT NULL
                  GROUP BY trans_id, ar.transdate
                  HAVING sum(qty)+sum(allocated) != 0
                  ORDER BY 2,1 ASC |;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{get_nonallocated} }, $ref;
  }
								      
  $sth->finish;
  $dbh->disconnect;
}
sub cogs_insert {
  my ($self,$form, $dbh, $invdate, $parts_id, $allocated, $sellprice, $costprice, $ar_id, $ap_id) = @_;

    $query = qq|INSERT INTO cogs (invdate,parts_id,allocated,sellprice,costprice,ar_id,ap_id)
                VALUES('$invdate',$parts_id,$allocated,$sellprice,$costprice,$ar_id,$ap_id)|;

    $dbh->do($query) || $form->dberror($query);
  
}

sub cogs_history {
  my ($self, $myconfig, $form) = @_;

   my $var;
  my $null;
  my $where = "1 = 1";

  if ($form->{invdatefrom}) {
        $where .= " AND invdate >='$form->{invdatefrom}'";
  }
  if ($form->{invdateto}) {
        $where .= " AND invdate <='$form->{invdateto}'";
  }

  if ($form->{invnumber}) {
    $var = $form->like(lc $form->{invnumber});
    $where .= " AND lower(ar.invnumber) LIKE '$var'";
  }
  
  if ($form->{partnumber}) {
    $var = $form->like(lc $form->{partnumber});
    $where .= " AND lower(p.partnumber) LIKE '$var'";
  }
  
  my %ordinal = ( 'invdate' => 1,
                  'partnumber' => 2,
                  'invnumber' => 3,
		);
  
  my @a = qw(partnumber);
  my $sortorder = $form->sort_order(\@a, \%ordinal);


  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|
      SELECT c.invdate, p.partnumber, ar.invnumber, c.allocated, '' AS sellprice , c.costprice,
      c.allocated *c.costprice AS margin, c.ap_id, p.id AS parts_id, c.ar_id
      FROM cogs c
      LEFT JOIN ar ON (c.ar_id = ar.id)
      LEFT JOIN parts p ON (c.parts_id = p.id)
      WHERE $where
      ORDER BY $sortorder|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{cogs_history} }, $ref;
  }
  
  $sth->finish;
  $dbh->disconnect;
  
}

sub get_whded { #kabai
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT warehouse_id FROM employee 
                 WHERE login = '$form->{login}'|;
  $form->{whded} = $dbh->selectrow_array($query);

  $dbh->disconnect;
}

sub get_booked { #kabai
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);
  my $icstring = $form->{vc} eq "customer" ? "%IC_(income|sale)%" : "(IC|%IC_expense%)";
  my $query = qq| SELECT sum(amount) AS booked_income FROM acc_trans a
		  LEFT JOIN chart c ON (c.id=a.chart_id)
		  LEFT JOIN defaults d ON (d.fxgain_accno_id = a.chart_id)
		  WHERE c.link SIMILAR TO '$icstring' AND d.fxgain_accno_id IS NULL
		  AND a.trans_id=$form->{id}
		  GROUP BY a.trans_id;|;

   $form->{booked_income} = $dbh->selectrow_array($query);

  $query = qq| SELECT c.description,sum(amount) AS amount FROM acc_trans a
		  LEFT JOIN chart c ON (c.id=a.chart_id)
		  WHERE c.link LIKE '%IC_tax%'
		  AND a.trans_id=$form->{id}
		  GROUP BY c.description
		  |;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{booked_tax} }, $ref;
  }	   	
  $sth->finish;
  $dbh->disconnect;
}
sub check_inventory { #kabai
  my ($self, $myconfig, $form) = @_;
  
  my $dbh = $form->dbconnect($myconfig);
  my $wth;
  my ($warehouse, $warehouse_id) = split /--/, $form->{warehouse};
  $warehouse_id *= 1;
  
  $query = qq|SELECT sum(qty)
              FROM inventory
	      WHERE parts_id = ?
	      AND warehouse_id = ?|;
  $wth = $dbh->prepare($query) || $form->dberror($query);
  

  for my $i (1 .. $form->{rowcount}) {
      next if $form->{"inventory_accno_$i"}==0;
      $form->{"id_$i"} *= 1;
      $wth->execute($form->{"id_$i"}, $warehouse_id) || $form->dberror;

      ($qty) = $wth->fetchrow_array;
      $wth->finish;
      if ($form->{vc} eq "customer"){
       if ($form->{"reqship_$i"} > $qty) {
        $form->{stockid} = $i;
        $form->{stockqty} = $qty*1;
        return -1;
       }
      }
#TEMP      else{
#       if (($form->{"qty_$i"} - $form->{"ship_$i"} + $qty) < 0) {
#          return -2;
#       }
#      }
  }
  $dbh->disconnect;
}
sub get_accnos {#kabai
  my ($self, $myconfig, $form) = @_;
  my $dbh = $form->dbconnect($myconfig);
  my $query;
  my $wherefrom;
  my $whereto;
  
  if ($form->{accnofrom}){
    $wherefrom = " AND accno >='$form->{accnofrom}'";
  }
  if ($form->{accnoto}){
    $whereto = " AND accno <='$form->{accnoto}'";
  }

  $query = qq| SELECT accno FROM chart
               WHERE charttype='A' $wherefrom $whereto
		  ORDER BY 1 ASC |;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{get_accnos} }, $ref;
  }
								      
  $sth->finish;
  $dbh->disconnect;
}
1;
