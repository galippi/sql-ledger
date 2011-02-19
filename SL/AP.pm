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
# Accounts Payables database backend routines
#
#======================================================================


package AP;

use SL::AM;

sub post_transaction {
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn off autocommit
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my $null;
  my $taxrate;
  my $amount;
  my $exchangerate = 0;
#$form->debug2;

	# did we use registered number or an odd number?
	undef my $toincrement;
	if ($form->{ordnumber}) {
		($toincrement) = $form->{ordnumber} =~ /^(\p{IsAlpha}+)\p{IsDigit}+$/;
		}
	else {
		$form->{ordnumber} = $form->{oddordnumber};
		}

  # split and store id numbers in link accounts
  map { ($form->{AP}{"amount_$_"}) = split(/--/, $form->{"AP_amount_$_"}) } (1 .. $form->{rowcount});
  ($form->{AP}{payables}) = split(/--/, $form->{AP});

  ($null, $form->{department_id}) = split(/--/, $form->{department});
  $form->{department_id} *= 1;

  if ($form->{currency} eq $form->{defaultcurrency}) {
    $form->{exchangerate} = 1;
  } else {
    $exchangerate = $form->check_exchangerate($myconfig, $form->{currency}, $form->{transdate}, 'sell');

    $form->{exchangerate} = ($exchangerate) ? $exchangerate : $form->parse_amount($myconfig, $form->{exchangerate});
  }
  
  # reverse and parse amounts
  for my $i (1 .. $form->{rowcount}) {
    $form->{"amount_$i"} = $form->round_amount($form->parse_amount($myconfig, $form->{"amount_$i"}) * $form->{exchangerate} * -1, 2);
    $form->{"netamount_$i"} = $form->round_amount($form->parse_amount($myconfig, $form->{"netamount_$i"}) * $form->{exchangerate} * -1, 2);
    $amount += ($form->{"amount_$i"} * -1);

  }
  

  # this is for ap
  $form->{amount} = $amount;
  
  # taxincluded doesn't make sense if there is no amount
  $form->{taxincluded} = 0 if ($form->{amount} == 0);

  for my $item (split / /, $form->{taxaccounts}) {
    $form->{AP}{"tax_$item"} = $item;

    $form->{"tax_$item"} = $form->round_amount($form->parse_amount($myconfig, $form->{"tax_$item"}) * $form->{exchangerate}, 2) * -1;
    $form->{total_tax} += ($form->{"tax_$item"} * -1);
  }
 

  # adjust paidaccounts if there is no date in the last row
  $form->{paidaccounts}-- unless ($form->{"datepaid_$form->{paidaccounts}"});
  
  $form->{invpaid} = 0;
  # add payments
  for my $i (1 .. $form->{paidaccounts}) {
    $form->{"paid_$i"} = $form->round_amount($form->parse_amount($myconfig, $form->{"paid_$i"}), 2);
    
    $form->{invpaid} += $form->{"paid_$i"};
    $form->{datepaid} = $form->{"datepaid_$i"};

  }
  
  $form->{invpaid} = $form->round_amount($form->{invpaid} * $form->{exchangerate}, 2);
  $form->{eva} *= 1;
  if ($form->{taxincluded} *= 1) {
    for $i (1 .. $form->{rowcount}) {
      $tax = $form->{"amount_$i"} - $form->{"netamount_$i"};
      $amount = $form->{"amount_$i"} - $tax;
      $form->{"amount_$i"} = $form->round_amount($amount, 2);
      $diff += $amount - $form->{"amount_$i"};
    }

    # deduct taxes from amount
    $form->{amount} -= $form->{total_tax};
    # deduct difference from amount_1
    $form->{amount_1} += $form->round_amount($diff, 2);
  }

  $form->{netamount} = $form->{amount};
  
  # store invoice total, this goes into ap table
  $form->{invtotal} = $form->{amount} + $form->{total_tax};
  
  # amount for total AP
  $form->{payables} = $form->{invtotal};
 

  my $query;
  my $sth;

  # if we have an id delete old records
  if ($form->{id}) {

    # delete detail records
    $query = qq|DELETE FROM acc_trans WHERE trans_id = $form->{id}|;

    $dbh->do($query) || $form->dberror($query);
    
  } else {
    my $uid = time;
    $uid .= $form->{login};

    $query = qq|INSERT INTO ap (invnumber, employee_id)
                VALUES ('$uid', (SELECT id FROM employee
		                 WHERE login = '$form->{login}') )|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id FROM ap
                WHERE invnumber = '$uid'|;
    ($form->{id}) = $dbh->selectrow_array($query);
  }

  $form->{invnumber} = $form->{id} unless $form->{invnumber};
  
  $form->{datepaid} = $form->{transdate} unless ($form->{datepaid});
  my $datepaid = ($form->{invpaid} != 0) ? qq|'$form->{datepaid}'| : 'NULL';
   $form->{archive} = $form->{scanned};
   if ($form->{archive}  && $form->{archive} !~ /_archiv/) {
    $form->{archive} =~ s/(.\S{2,3})$//;
    $form->{archive} .= "_archiv".$1;
   }
#kabai 149
  $query = qq|UPDATE ap SET
	      invnumber = |.$dbh->quote($form->{invnumber}).qq|,
              crdate = '$form->{crdate}',
	      transdate = '$form->{transdate}',
	      ordnumber = |.$dbh->quote($form->{ordnumber}).qq|,
	      vendor_id = $form->{vendor_id},
	      taxincluded = '$form->{taxincluded}',
	      eva = '$form->{eva}',
	      amount = $form->{invtotal},
	      duedate = |.$form->dbquote($form->{duedate}, SQL_DATE).qq|,
	      paid = $form->{invpaid},
	      datepaid = $datepaid,
	      netamount = $form->{netamount},
	      curr = |.$dbh->quote($form->{currency}).qq|,
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      department_id = $form->{department_id},
              scanned = '$form->{archive}'
	      WHERE id = $form->{id}
	     |;
  $dbh->do($query) || $form->dberror($query);


  # update exchangerate
  if (($form->{currency} ne $form->{defaultcurrency}) && !$exchangerate) {
    $form->update_exchangerate($dbh, $form->{currency}, $form->{transdate}, 0, $form->{exchangerate});
  }

  # add individual transactions

  foreach my $item (sort keys %{ $form->{AP} }) {
    if ($form->{$item} != 0) {

      $project_id = 'NULL';
      if ($item =~ /amount_/) {
	if ($form->{"projectnumber_$'"}) {
	  ($null, $project_id) = split /--/, $form->{"projectnumber_$'"}
	}
#kabai
        $sourcedata = $form->{"AP_base_$'"};
        $vmemo      = $form->{"vmemo_$'"};
#kabai
      }

      # insert detail records in acc_trans
#kabai taxbase
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
                                         project_id, taxbase, memo)
                  VALUES ($form->{id}, (SELECT id FROM chart
		         WHERE accno = '$form->{AP}{$item}'),
		  $form->{$item}, '$form->{transdate}', $project_id, '$sourcedata', '$vmemo')|;
      $dbh->do($query) || $form->dberror($query);
    }
  $sourcedata = "";
  $vmemo = "";
  }

  # if there is no amount but a payment record a payable
  if ($form->{amount} == 0 && $form->{invtotal} == 0) {
    $form->{payables} = $form->{invpaid};
  }
 
  # add paid transactions
  for my $i (1 .. $form->{paidaccounts}) {

    if ($form->{"paid_$i"} != 0) {
#kabai
    # did we use registered number or an odd number?
    undef my $toincrement;

    if ($form->{"regsource_$i"}) {
 	 $form->{"source_$i"} = $form->{"regsource_$i"};
	($toincrement) = $form->{"source_$i"}=~ /^(\p{IsAlpha}+)\p{IsDigit}+$/;
	# increment registered number
	AM->increment_regnum($myconfig, $form, $toincrement) if $toincrement;
    }
#kabai
      $exchangerate = 0;
      if ($form->{currency} eq $form->{defaultcurrency}) {
	$form->{"exchangerate_paid_$i"} = 1;
      } else {
#kabai +1
	$exchangerate = $form->check_exchangerate($myconfig, $form->{currency}, $form->{"datepaid_$i"}, 'sell_paid');
#kabai +1
	$form->{"exchangerate_paid_$i"} = ($exchangerate) ? $exchangerate : $form->parse_amount($myconfig, $form->{"exchangerate_paid_$i"});
      }
      
      
      # get paid account
      ($form->{AP}{"paid_$i"}) = split(/--/, $form->{"AP_paid_$i"});
      $form->{"datepaid_$i"} = $form->{transdate} unless ($form->{"datepaid_$i"});

      # if there is no amount and invtotal is zero there is no exchangerate
      if ($form->{amount} == 0 && $form->{invtotal} == 0) {
#kabai
	$form->{exchangerate} = $form->{"exchangerate_paid_$i"};
      }

      $amount = $form->round_amount($form->{"paid_$i"} * $form->{exchangerate} * -1, 2);
      if ($form->{payables}) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		    transdate)
		    VALUES ($form->{id},
		        (SELECT id FROM chart
			WHERE accno = '$form->{AP}{payables}'),
		    $amount, '$form->{"datepaid_$i"}')|;
	$dbh->do($query) || $form->dberror($query);
      }
      $form->{payables} = $amount;

      # add payment
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
                  transdate, source, memo)
                  VALUES ($form->{id},
		      (SELECT id FROM chart
		      WHERE accno = '$form->{AP}{"paid_$i"}'),
		  $form->{"paid_$i"}, '$form->{"datepaid_$i"}', |
		  .$dbh->quote($form->{"source_$i"}).qq|, |
		  .$dbh->quote($form->{"memo_$i"}).qq|)|;
      $dbh->do($query) || $form->dberror($query);
      
      # add exchange rate difference
#kabai +1
      $amount = $form->round_amount($form->{"paid_$i"} * ($form->{"exchangerate_paid_$i"} - 1), 2);
      if ($amount != 0) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		    transdate, fx_transaction, cleared)
		    VALUES ($form->{id},
		      (SELECT id FROM chart
		      WHERE accno = '$form->{AP}{"paid_$i"}'),
		    $amount, '$form->{"datepaid_$i"}', '1', '0')|;

	$dbh->do($query) || $form->dberror($query);
      }

      # exchangerate gain/loss
      $amount = $form->round_amount($form->{"paid_$i"} * ($form->{exchangerate} - $form->{"exchangerate_paid_$i"}), 2);

      if ($amount != 0) {
	$accno = ($amount > 0) ? $form->{fxgain_accno} : $form->{fxloss_accno};
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		    transdate, fx_transaction, cleared)
		    VALUES ($form->{id}, (SELECT id FROM chart
				WHERE accno = '$accno'),
		    $amount, '$form->{"datepaid_$i"}', '1', '0')|;
	$dbh->do($query) || $form->dberror($query);
      }

      # update exchange rate record
      if (($form->{currency} ne $form->{defaultcurrency}) && !$exchangerate) {
#kabai +1
	$form->update_exchangerate_paid($dbh, $form->{currency}, $form->{"datepaid_$i"}, 0, $form->{"exchangerate_paid_$i"});
      }
    }
  }
  
  my %audittrail = ( tablename  => 'ap',
                     reference  => $form->{invnumber},
		     formname   => 'transaction',
		     action     => 'posted',
		     id         => $form->{id} );
  $form->audittrail($dbh, "", \%audittrail);
  
	# increment registered number
	if ($toincrement) {
		AM->increment_regnumber($myconfig, $form, $toincrement);
		}

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
  
}




sub delete_transaction {
  my ($self, $myconfig, $form, $spool) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my %audittrail = ( tablename  => 'ap',
                     reference  => $form->{invnumber},
		     formname   => 'transaction',
		     action     => 'deleted',
		     id         => $form->{id} );
  $form->audittrail($dbh, "", \%audittrail);

  my $query = qq|DELETE FROM ap WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|DELETE FROM acc_trans WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  # commit and redirect
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}




sub ap_transactions {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $var;
  
	my $paid, $datepaid, $account, $payment_tables, $bankrate, $pmfxamount;
	if ($form->{payment_list}) {
		$paid = "CASE WHEN (a.curr <> 'HUF'::bpchar) THEN ac.amount * (
                    SELECT exchangerate.sell
                    FROM exchangerate
                    WHERE ((exchangerate.transdate = a.transdate) AND (a.curr = exchangerate.curr))
                    ) ELSE ac.amount END";
		$datepaid = "ac.transdate";
		$account = "c.accno || ' -- ' || c.description AS account," ;
		$payment_tables = "LEFT OUTER JOIN acc_trans ac ON
				(ac.trans_id = a.id AND ac.fx_transaction = 'f' AND
				EXISTS (SELECT 1 FROM chart c WHERE c.id = ac.chart_id AND c.link LIKE '%AP_paid%'))
			LEFT OUTER JOIN chart c ON (c.id = ac.chart_id)";
		$bankrate = "CASE WHEN (a.curr <> 'HUF'::bpchar) THEN (
                    SELECT exchangerate.sell_paid
                    FROM exchangerate
                    WHERE ((exchangerate.transdate = ac.transdate) AND (a.curr = exchangerate.curr))
                    ) ELSE NULL::double precision END AS bankrate,";
		$pmfxamount = "CASE WHEN (a.curr <> 'HUF'::bpchar) THEN ac.amount
                    ELSE NULL::double precision END AS pmfxamount,";
		}
	else {
		$paid = "a.paid";
  if ($form->{outstanding}) {
    $paid = qq|SELECT SUM(ac.amount) 
               FROM acc_trans ac
	       JOIN chart c ON (c.id = ac.chart_id)
	       WHERE ac.trans_id = a.id
	       AND (c.link LIKE '%AP_paid%' OR c.link = '')|;
    $paid .= qq|
               AND ac.transdate <= '$form->{transdateto}'| if $form->{transdateto};
  }
		$datepaid = "a.datepaid";
		}
  $ap = ", ap(a.id) as ap" if $form->{l_ap};
#kabai  +20
  my $query = "SELECT a.id, a.invnumber, a.transdate, a.duedate,
                 a.amount, ($paid) AS paid, a.ordnumber, v.name,
		 a.invoice, a.netamount, ($datepaid) AS datepaid, a.notes,
		 a.vendor_id, e.name AS employee, m.name AS manager,
		$account
	         a.curr AS curr, 
		    $bankrate
		    CASE WHEN (a.curr <> 'HUF'::bpchar) THEN (
		    SELECT exchangerate.sell
		    FROM exchangerate
		    WHERE ((exchangerate.transdate = a.transdate) AND (a.curr = exchangerate.curr))
		    ) ELSE NULL::double precision END AS exchrate, 
		    $pmfxamount
		    CASE WHEN (a.curr <>
	            'HUF'::bpchar) THEN ((
		    SELECT
		    CASE WHEN exchangerate.sell != 0 THEN
		    round(((a.amount / exchangerate.sell))::numeric, 2)
		    ELSE 0
		    END
		    AS round
		    FROM exchangerate
		    WHERE ((exchangerate.transdate = a.transdate) AND (a.curr = exchangerate.curr))
		    ))::double precision ELSE NULL::double precision END AS fxamount,
                 a.scanned $ap
	         FROM ap a
		$payment_tables
	      JOIN vendor v ON (a.vendor_id = v.id)
	      LEFT JOIN employee e ON (a.employee_id = e.id)
	      LEFT JOIN employee m ON (e.managerid = m.id)
	      ";
#kabai +10
  my %ordinal = ( 'id' => 1,
                  'invnumber' => 2,
                  'transdate' => 3,
		  'duedate' => 4,
		  'ordnumber' => 7,
		  'name' => 8,
		  'datepaid' => 11,
		  'employee' => 14,
		  'manager' => 15,
		  'curr' => 16,
		  'fxamount' => 17,
		  'exchrate' => 18
		);
  
  my @a = (id, transdate, invnumber, name);
  push @a, "employee" if $form->{l_employee};
  push @a, "manager" if $form->{l_manager};
  my $sortorder = $form->sort_order(\@a, \%ordinal);
  
  my $where = "1 = 1";
  
  if ($form->{vendor_id}) {
    $where .= " AND a.vendor_id = $form->{vendor_id}";
  } else {
    if ($form->{vendor}) {
      $var = $form->like(lc $form->{vendor});
      $where .= " AND lower(v.name) LIKE '$var'";
    }
  }
  if ($form->{department}) {
    my ($null, $department_id) = split /--/, $form->{department};
    $where .= " AND a.department_id = $department_id";
  }
  if ($form->{invnumber}) {
    $var = $form->like(lc $form->{invnumber});
    $where .= " AND lower(a.invnumber) LIKE '$var'";
    $form->{open} = $form->{closed} = 0;
  }
  if ($form->{ordnumber}) {
    $var = $form->like(lc $form->{ordnumber});
    $where .= " AND lower(a.ordnumber) LIKE '$var'";
    $form->{open} = $form->{closed} = 0;
  }
  if ($form->{notes}) {
    $var = $form->like(lc $form->{notes});
#kabai NOTLIKENOTES
   if ($form->{notlikenotes}){
    $where .= " AND lower(a.notes) NOT LIKE '$var'";
   }else{  
    $where .= " AND lower(a.notes) LIKE '$var'";
   }
#kabai    $form->{open} = $form->{closed} = 0;
  }

  $where .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
  $where .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};
#kabai
  $where .= " AND a.duedate >= '$form->{duefrom}'" if $form->{duefrom};
  $where .= " AND a.duedate <= '$form->{dueto}'" if $form->{dueto};
  $where .= " AND ABS(a.amount-paid) <=".$form->parse_amount($myconfig, $form->{marginerr1}) if $form->{marginerr1};
  $where .= " AND ABS(a.amount-paid) >=".$form->parse_amount($myconfig, $form->{marginerr2}) if $form->{marginerr2};
#kabai
  if ($form->{open} || $form->{closed}) {
    unless ($form->{open} && $form->{closed}) {
      $where .= " AND a.amount != a.paid" if ($form->{open});
      $where .= " AND a.amount = a.paid" if ($form->{closed});
    }
  }
 
  if ($form->{AP}) {
    my ($accno) = split /--/, $form->{AP};
    $where .= qq|
                AND a.id IN (SELECT ac.trans_id
		             FROM acc_trans ac
			     JOIN chart c ON (c.id = ac.chart_id)
			     WHERE a.id = ac.trans_id
			     AND c.accno = '$accno')
		|;
  }

  $query .= "WHERE $where
             ORDER by $sortorder";

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    if ($form->{outstanding}) {
      next if $form->round_amount($ref->{amount}, 2) == $form->round_amount($ref->{paid}, 2);
    }
    push @{ $form->{transactions} }, $ref;
  }
  
  $sth->finish;
  $dbh->disconnect;
  
}

sub ap_chart {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $query = "SELECT id, accno, description, notes FROM chart WHERE category='E' AND charttype='A' AND link='' ORDER BY accno ASC" ;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{charts} }, $ref;
  }
  
  $sth->finish;
  $dbh->disconnect;
  
}


sub chart_update {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $query = "UPDATE chart SET link='AP_amount' WHERE id=".$form->{choose};
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  $sth->finish;
  my $query = "SELECT accno FROM  chart WHERE id=".$form->{choose};
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  ($form->{AP_amount_1}) = $sth->fetchrow_array;    
  $sth->finish;
  $dbh->disconnect;
  
}
sub check_invnum {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $query = qq|SELECT invnumber from ap WHERE invnumber =
  '$form->{invnumber}' AND vendor_id = $form->{vendor_id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  ($form->{AP_invnumber}) = $sth->fetchrow_array;    
  $sth->finish;
  $dbh->disconnect;
  
}

1;
