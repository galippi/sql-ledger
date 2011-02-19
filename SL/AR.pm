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
# Accounts Receivable module backend routines
#
#======================================================================

package AR;

use SL::AM;

sub post_transaction {
  my ($self, $myconfig, $form) = @_;

  my ($null, $taxrate, $amount, $tax, $diff);
  my $exchangerate = 0;
  my $i;

  # did we use registered number or an odd number?
  undef my $toincrement;
  if ($form->{ordnumber}) {
	($toincrement) = $form->{ordnumber} =~ /^(\p{IsAlpha}+)\p{IsDigit}+$/;
  }else{
	$form->{ordnumber} = $form->{oddordnumber};
  }


  # split and store id numbers in link accounts
  map { ($form->{AR_amounts}{"amount_$_"}) = split(/--/, $form->{"AR_amount_$_"}) } (1 .. $form->{rowcount});
  ($form->{AR_amounts}{receivables}) = split(/--/, $form->{AR});
  
  if ($form->{currency} eq $form->{defaultcurrency}) {
    $form->{exchangerate} = 1;
  } else {
    $exchangerate = $form->check_exchangerate($myconfig, $form->{currency}, $form->{transdate}, 'buy');
  }
  
  $form->{exchangerate} = ($exchangerate) ? $exchangerate : $form->parse_amount($myconfig, $form->{exchangerate}); 

 
  for $i (1 .. $form->{rowcount}) {
    
    $form->{"amount_$i"} = $form->round_amount($form->parse_amount($myconfig, $form->{"amount_$i"}) * $form->{exchangerate}, 2);
    $form->{"netamount_$i"} = $form->round_amount($form->parse_amount($myconfig, $form->{"netamount_$i"}) * $form->{exchangerate}, 2);
    
    $form->{netamount} += $form->{"amount_$i"};

  }
  
  
  # taxincluded doesn't make sense if there is no amount
  $form->{taxincluded} = 0 if ($form->{netamount} == 0);

  foreach my $item (split / /, $form->{taxaccounts}) {
    $form->{AR_amounts}{"tax_$item"} = $item;

    $form->{"tax_$item"} = $form->round_amount($form->parse_amount($myconfig, $form->{"tax_$item"}) * $form->{exchangerate}, 2);
    $form->{tax} += $form->{"tax_$item"};

  }

  # adjust paidaccounts if there is no date in the last row
  $form->{paidaccounts}-- unless ($form->{"datepaid_$form->{paidaccounts}"});

  $form->{paid} = 0;
  # add payments
  for $i (1 .. $form->{paidaccounts}) {
    $form->{"paid_$i"} = $form->round_amount($form->parse_amount($myconfig, $form->{"paid_$i"}), 2);
    
    $form->{paid} += $form->{"paid_$i"};
    $form->{datepaid} = $form->{"datepaid_$i"};

  }
 

  if ($form->{taxincluded} *= 1) {
    
    for $i (1 .. $form->{rowcount}) {
      $tax = $form->{"amount_$i"} - $form->{"netamount_$i"};
      $amount = $form->{"amount_$i"} - $tax;
      $form->{"amount_$i"} = $form->round_amount($amount, 2);
      $diff += $amount - $form->{"amount_$i"};
    }
    
    $form->{netamount} -= $form->{tax};
    # deduct difference from amount_1
    $form->{amount_1} += $form->round_amount($diff, 2);
  }

  $form->{amount} = $form->{netamount} + $form->{tax};
  $form->{paid} = $form->round_amount($form->{paid} * $form->{exchangerate}, 2);
 
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $sth;
  my $null;
  
  ($null, $form->{employee_id}) = split /--/, $form->{employee};
  unless ($form->{employee_id}) {
    ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh); 
  }
  
  # if we have an id delete old records
  if ($form->{id}) {

    # delete detail records
    $query = qq|DELETE FROM acc_trans WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
    
  } else {
    my $uid = time;
    $uid .= $form->{login};

    $query = qq|INSERT INTO ar (invnumber, employee_id)
                VALUES ('$uid', $form->{employee_id})|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id FROM ar
                WHERE invnumber = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;
  }

  
  # update department
  ($null, $form->{department_id}) = split(/--/, $form->{department});
  $form->{department_id} *= 1;

  # record last payment date in ar table
  $form->{datepaid} = $form->{transdate} unless $form->{datepaid};
  my $datepaid = ($form->{paid} != 0) ? qq|'$form->{datepaid}'| : 'NULL';

#kabai +5
  $query = qq|UPDATE ar set
	      invnumber = |.$dbh->quote($form->{invnumber}).qq|,
	      ordnumber = |.$dbh->quote($form->{ordnumber}).qq|,
	      transdate = '$form->{transdate}',
	      crdate = '$form->{crdate}',
	      customer_id = $form->{customer_id},
	      taxincluded = '$form->{taxincluded}',
	      amount = $form->{amount},
	      duedate = '$form->{duedate}',
	      paid = $form->{paid},
	      datepaid = $datepaid,
	      netamount = $form->{netamount},
	      curr = '$form->{currency}',
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      department_id = $form->{department_id},
	      employee_id = $form->{employee_id}
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  
  # amount for AR account
  $form->{receivables} = $form->round_amount($form->{amount} * -1, 2);
  

  # update exchangerate
  if (($form->{currency} ne $form->{defaultcurrency}) && !$exchangerate) {
    $form->update_exchangerate($dbh, $form->{currency}, $form->{transdate}, $form->{exchangerate}, 0);
  }
  
  # add individual transactions for AR, amount and taxes
  foreach my $item (sort keys %{ $form->{AR_amounts} }) {
    if ($form->{$item} != 0) {
      
      $project_id = 'NULL';
      if ($item =~ /amount_/) {
	if ($form->{"projectnumber_$'"}) {
	  ($null, $project_id) = split /--/, $form->{"projectnumber_$'"};
	}
      }
#kabai
        $sourcedata = $form->{"AR_base_$'"};
#kabai     
      # insert detail records in acc_trans
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
                                         project_id, taxbase)
		  VALUES ($form->{id}, (SELECT id FROM chart
		                        WHERE accno = '$form->{AR_amounts}{$item}'),
		  $form->{$item}, '$form->{transdate}', $project_id, '$sourcedata')|;
      $dbh->do($query) || $form->dberror($query);
    }
  $sourcedata = "";
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
       ($form->{AR_amounts}{"paid_$i"}) = split(/--/, $form->{"AR_paid_$i"});
      $form->{"datepaid_$i"} = $form->{transdate} unless ($form->{"datepaid_$i"});
     
      $exchangerate = 0;
      if ($form->{currency} eq $form->{defaultcurrency}) {
	$form->{"exchangerate_paid_$i"} = 1;
      } else {
#kabai +1
	$exchangerate = $form->check_exchangerate($myconfig, $form->{currency}, $form->{"datepaid_$i"}, 'buy_paid');
#kabai +1	
	$form->{"exchangerate_paid_$i"} = ($exchangerate) ? $exchangerate : $form->parse_amount($myconfig, $form->{"exchangerate_paid_$i"}); 
      }
      
     
      # if there is no amount and invtotal is zero there is no exchangerate
      if ($form->{amount} == 0 && $form->{netamount} == 0) {
	$form->{exchangerate} = $form->{"exchangerate_$i"};
      }
      
      # receivables amount
      $amount = $form->round_amount($form->{"paid_$i"} * $form->{exchangerate}, 2);
      
      if ($form->{receivables} != 0) {
	# add receivable
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		    transdate)
		    VALUES ($form->{id},
		           (SELECT id FROM chart
			    WHERE accno = '$form->{AR_amounts}{receivables}'),
		    $amount, '$form->{"datepaid_$i"}')|;
	$dbh->do($query) || $form->dberror($query);
      }
      $form->{receivables} = $amount;
      
      if ($form->{"paid_$i"} != 0) {
	# add payment
	$amount = $form->{"paid_$i"} * -1;
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		    transdate, source, memo)
		    VALUES ($form->{id},
			   (SELECT id FROM chart
			    WHERE accno = '$form->{AR_amounts}{"paid_$i"}'),
		    $amount, '$form->{"datepaid_$i"}', |
		    .$dbh->quote($form->{"source_$i"}).qq|, |
		    .$dbh->quote($form->{"memo_$i"}).qq|)|;
	$dbh->do($query) || $form->dberror($query);
	
	
	# exchangerate difference for payment
	$amount = $form->round_amount($form->{"paid_$i"} * ($form->{"exchangerate_paid_$i"} - 1) * -1, 2);
	  
	if ($amount != 0) {
	  $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		      transdate, fx_transaction, cleared)
		      VALUES ($form->{id},
			     (SELECT id FROM chart
			      WHERE accno = '$form->{AR_amounts}{"paid_$i"}'),
		      $amount, '$form->{"datepaid_$i"}', '1', '0')|;
	  $dbh->do($query) || $form->dberror($query);
	}
	  
	# exchangerate gain/loss
	$amount = $form->round_amount($form->{"paid_$i"} * ($form->{exchangerate} - $form->{"exchangerate_paid_$i"}) * -1, 2);
	
	if ($amount != 0) {
	  $accno = ($amount > 0) ? $form->{fxgain_accno} : $form->{fxloss_accno};
	  $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		      transdate, fx_transaction, cleared)
		      VALUES ($form->{id}, (SELECT id FROM chart
					    WHERE accno = '$accno'),
		      $amount, '$form->{"datepaid_$i"}', '1', '0')|;
	  $dbh->do($query) || $form->dberror($query);
	}
      }
      
      # update exchangerate record
      if (($form->{currency} ne $form->{defaultcurrency}) && !$exchangerate) {
#kabai +1
	$form->update_exchangerate_paid($dbh, $form->{currency}, $form->{"datepaid_$i"}, $form->{"exchangerate_paid_$i"}, 0);
      }
    }
  }

  my %audittrail = ( tablename  => 'ar',
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
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn AutoCommit off
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my %audittrail = ( tablename  => 'ar',
                     reference  => $form->{invnumber},
		     formname   => 'transaction',
		     action     => 'deleted',
		     id         => $form->{id} );

  $form->audittrail($dbh, "", \%audittrail);
  
  my $query = qq|DELETE FROM ar WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|DELETE FROM acc_trans WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  # commit
  my $rc = $dbh->commit;
  $dbh->disconnect;
  
  $rc;

}



sub ar_transactions {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $var;
  
	my $paid, $datepaid, $account, $payment_tables, $bankrate, $pmfxamount;

	if ($form->{payment_list}) {
		$paid = "CASE WHEN (a.curr <> 'HUF'::bpchar) THEN -ac.amount * (
                    SELECT exchangerate.buy
                    FROM exchangerate
                    WHERE ((exchangerate.transdate = a.transdate) AND (a.curr = exchangerate.curr))
                    ) ELSE -ac.amount END";
		$datepaid = "ac.transdate";
		$account = "ch.accno || ' -- ' || ch.description AS account," ;
		$payment_tables = "LEFT OUTER JOIN acc_trans ac ON
				(ac.trans_id = a.id AND ac.fx_transaction = 'f' AND
				EXISTS (SELECT 1 FROM chart ch WHERE ch.id = ac.chart_id AND ch.link LIKE '%AR_paid%'))
			LEFT OUTER JOIN chart ch ON (ch.id = ac.chart_id)";
		$bankrate = "CASE WHEN (a.curr <> 'HUF'::bpchar) THEN (
                    SELECT exchangerate.buy_paid
                    FROM exchangerate
                    WHERE ((exchangerate.transdate = ac.transdate) AND (a.curr = exchangerate.curr))
                    ) ELSE NULL::double precision END AS bankrate,";
		$pmfxamount = "CASE WHEN (a.curr <> 'HUF'::bpchar) THEN -ac.amount
                    ELSE NULL::double precision END AS pmfxamount,";
		}
	else {
		$paid = "a.paid";
  if ($form->{outstanding}) {
    $paid = qq|SELECT SUM(ac.amount) * -1
               FROM acc_trans ac
	       JOIN chart ch ON (ch.id = ac.chart_id)
	       WHERE ac.trans_id = a.id
	       AND (ch.link LIKE '%AR_paid%' OR ch.link = '')|;
    $paid .= qq|
               AND ac.transdate <= '$form->{transdateto}'| if $form->{transdateto};
  }
		$datepaid = "a.datepaid";
		}
    $lastcost = qq|,(SELECT SUM(qty * (SELECT lastcost FROM parts WHERE parts.id=parts_id))
                     FROM invoice WHERE trans_id=a.id) AS lastcost| if $form->{l_lastcost};
#kabai +1  
  my $query = "SELECT a.id, a.invnumber, a.ordnumber, a.transdate, a.crdate,
                 a.duedate, a.netamount, a.amount, ($paid) AS paid,
		 a.invoice, ($datepaid) AS datepaid, a.terms, a.notes,
		 a.shipvia, a.shippingpoint, e.name AS employee, c.name,
		 $account
		 a.customer_id, a.till, m.name AS manager,

	         a.curr AS curr, 
		     $bankrate
                    CASE WHEN (a.curr <> 'HUF'::bpchar) THEN (
		    SELECT exchangerate.buy
		    FROM exchangerate
		    WHERE ((exchangerate.transdate = a.transdate) AND (a.curr = exchangerate.curr))
		    ) ELSE NULL::double precision END AS exchrate, 
		     $pmfxamount
		    CASE WHEN (a.curr <>
	            'HUF'::bpchar) THEN ((
		    SELECT
		    CASE WHEN exchangerate.buy != 0 THEN
		    round(((a.amount / exchangerate.buy))::numeric, 2)
		    ELSE 0
		    END
		    AS round
		    FROM exchangerate
		    WHERE ((exchangerate.transdate = a.transdate) AND (a.curr = exchangerate.curr))
		    ))::double precision ELSE NULL::double precision END AS fxamount
                    $lastcost
	         
		 FROM ar a
		$payment_tables
	      JOIN customer c ON (a.customer_id = c.id)
	      LEFT JOIN employee e ON (a.employee_id = e.id)
	      LEFT JOIN employee m ON (e.managerid = m.id)
	      
	      ";

#kabai
  my %ordinal = ( 'id' => 1,
                  'invnumber' => 2,
		  'ordnumber' => 3,
		  'transdate' => 4,
		  'duedate' => 6,
		  'datepaid' => 11,
		  'shipvia' => 14,
		  'shippingpoint' => 15,
		  'employee' => 16,
		  'name' => 17,
		  'manager' => 20
		);

  
  my @a = (transdate, invnumber, name);
  push @a, "employee" if $form->{l_employee};
  push @a, "manager" if $form->{l_manager};
  my $sortorder = $form->sort_order(\@a, \%ordinal);
  
  my $where = "1 = 1";
  if ($form->{customer_id}) {
    $where .= " AND a.customer_id = $form->{customer_id}";
  } else {
    if ($form->{customer}) {
      $var = $form->like(lc $form->{customer});
      $where .= " AND lower(c.name) LIKE '$var'";
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
    $where .= " AND lower(a.notes) LIKE '$var'";
    $form->{open} = $form->{closed} = 0;
  }
  
  $where .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
  $where .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};
#kabai
  $where .= " AND a.crdate >= '$form->{crdatefrom}'" if $form->{crdatefrom};
  $where .= " AND a.crdate <= '$form->{crdateto}'" if $form->{crdateto};
  $where .= " AND a.duedate >= '$form->{duefrom}'" if $form->{duefrom};
  $where .= " AND a.duedate <= '$form->{dueto}'" if $form->{dueto};
  $where .= " AND ABS(a.amount-paid) <=".$form->parse_amount($myconfig, $form->{marginerr1}) if $form->{marginerr1};
  $where .= " AND ABS(a.amount-paid) >=".$form->parse_amount($myconfig, $form->{marginerr2}) if $form->{marginerr2};
    ##kabai
  if ($form->{open} || $form->{closed}) {
    unless ($form->{open} && $form->{closed}) {
      $where .= " AND a.amount != a.paid" if ($form->{open});
      $where .= " AND a.amount = a.paid" if ($form->{closed});
    }
  }

  if ($form->{till}) {
    $where .= " AND a.invoice = '1'
                AND NOT a.till IS NULL";
    if (!$myconfig->{admin}) {
      $where .= " AND e.login = '$form->{login}'";
    }
  }
  
  if ($form->{AR}) {
    my ($accno) = split /--/, $form->{AR};
    $where .= qq|
                AND a.id IN (SELECT ac.trans_id
		             FROM acc_trans ac
			     JOIN chart ch ON (ch.id = ac.chart_id)
			     WHERE a.id = ac.trans_id
			     AND ch.accno = '$accno')
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

1;
