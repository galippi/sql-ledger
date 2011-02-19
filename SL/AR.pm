#=====================================================================
# SQL-Ledger Accounting
# Copyright (C) 2001
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#
#  Contributors:
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


sub post_transaction {
  my ($self, $myconfig, $form) = @_;

  my ($null, $taxrate, $amount, $tax, $diff);
  my $exchangerate = 0;
  my $i;

  # split and store id numbers in link accounts
  map { ($form->{AR}{"amount_$_"}) = split(/--/, $form->{"AR_amount_$_"}) } (1 .. $form->{rowcount});
  ($form->{AR}{receivables}) = split(/--/, $form->{AR});

  if ($form->{currency} eq $form->{defaultcurrency}) {
    $form->{exchangerate} = 1;
  } else {
    $exchangerate = $form->check_exchangerate($myconfig, $form->{currency}, $form->{transdate}, 'buy');
  }
  
  $form->{exchangerate} = ($exchangerate) ? $exchangerate : $form->parse_amount($myconfig, $form->{exchangerate}); 

  for $i (1 .. $form->{rowcount}) {
    $form->{"amount_$i"} = $form->round_amount($form->parse_amount($myconfig, $form->{"amount_$i"}) * $form->{exchangerate}, 2);
    $amount += $form->{"amount_$i"};
  }
  
  # this is for ar
  $form->{amount} = $amount;

  # taxincluded doesn't make sense if there is no amount
  $form->{taxincluded} = 0 if ($form->{amount} == 0);

  foreach my $item (split / /, $form->{taxaccounts}) {
    $form->{AR}{"tax_$item"} = $item;

    $amount = $form->round_amount($form->parse_amount($myconfig, $form->{"tax_$item"}), 2);
    
    $form->{"tax_$item"} = $form->round_amount($amount * $form->{exchangerate}, 2);
    $form->{total_tax} += $form->{"tax_$item"};

  }

  # adjust paidaccounts if there is no date in the last row
  $form->{paidaccounts}-- unless ($form->{"datepaid_$form->{paidaccounts}"});

  $form->{invpaid} = 0;
  # add payments
  for $i (1 .. $form->{paidaccounts}) {
    $form->{"paid_$i"} = $form->round_amount($form->parse_amount($myconfig, $form->{"paid_$i"}), 2);
    
    $form->{invpaid} += $form->{"paid_$i"};
    $form->{datepaid} = $form->{"datepaid_$i"};

    # reverse payment
    $form->{"paid_$i"} *= -1;

  }
  
  $form->{invpaid} = $form->round_amount($form->{invpaid} * $form->{exchangerate}, 2);
 
  if ($form->{taxincluded} *= 1) {
    for $i (1 .. $form->{rowcount}) {
      $tax = $form->{total_tax} * $form->{"amount_$i"} / $form->{amount};
      $amount = $form->{"amount_$i"} - $tax;
      $form->{"amount_$i"} = $form->round_amount($amount, 2);
      $diff += $amount - $form->{"amount_$i"};
    }
    
    $form->{amount} -= $form->{total_tax};
    # deduct difference from amount_1
    $form->{amount_1} += $form->round_amount($diff, 2);
  }

  # store invoice total, this goes into ar table
  $form->{invtotal} = $form->{amount} + $form->{total_tax};
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my ($query, $sth);
  
  # if we have an id delete old records
  if ($form->{id}) {

    # delete detail records
    $query = qq|DELETE FROM acc_trans WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
    
  } else {
    my $uid = time;
    $uid .= $form->{login};

    $query = qq|INSERT INTO ar (invnumber, employee_id)
                VALUES ('$uid', (SELECT id FROM employee
		                 WHERE login = '$form->{login}') )|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id FROM ar
                WHERE invnumber = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;

  }

  # escape '
  $form->{notes} =~ s/'/''/g;

  # record last payment date in ar table
  $form->{datepaid} = $form->{transdate} unless $form->{datepaid};
  my $datepaid = ($form->{invpaid} != 0) ? qq|'$form->{datepaid}'| : 'NULL';
  
  $query = qq|UPDATE ar set
	      invnumber = '$form->{invnumber}',
	      ordnumber = '$form->{ordnumber}',
	      transdate = '$form->{transdate}',
	      customer_id = $form->{customer_id},
	      taxincluded = '$form->{taxincluded}',
	      amount = $form->{invtotal},
	      duedate = '$form->{duedate}',
	      paid = $form->{invpaid},
	      datepaid = $datepaid,
	      netamount = $form->{amount},
	      curr = '$form->{currency}',
	      notes = '$form->{notes}'
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  
  # amount for AR account
  $form->{receivables} = $form->round_amount($form->{invtotal} * -1, 2);
  

  # update exchangerate
  if (($form->{currency} ne $form->{defaultcurrency}) && !$exchangerate) {
    $form->update_exchangerate($dbh, $form->{currency}, $form->{transdate}, $form->{exchangerate}, 0);
  }
  
  # add individual transactions for AR, amount and taxes
  foreach my $item (keys %{ $form->{AR} }) {

    if ($form->{$item} != 0) {
      $project_id = 'NULL';
      if ($item =~ /amount_/) {
	if ($form->{"projectnumber_$'"}) {

	  $form->{"projectnumber_$'"} =~ s/'/''/g;
	  
	  $project_id = qq|(SELECT id
			    FROM project
			    WHERE projectnumber = '$form->{"projectnumber_$'"}')|;
	}
      }
      
      # insert detail records in acc_trans
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
                                         project_id)
		  VALUES ($form->{id}, (SELECT id FROM chart
		                        WHERE accno = '$form->{AR}{$item}'),
		  $form->{$item}, '$form->{transdate}', $project_id)|;
      $dbh->do($query) || $form->dberror($query);
    }
  }

  # if there is no amount but a payment record a receivables
  if ($form->{amount} == 0 && $form->{invtotal} == 0) {
    $form->{receivables} = $form->{invpaid} * -1;
  }
  
  # add paid transactions
  for my $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"} != 0) {
      
       ($form->{AR}{"paid_$i"}) = split(/--/, $form->{"AR_paid_$i"});
      $form->{"datepaid_$i"} = $form->{transdate} unless ($form->{"datepaid_$i"});
     
      $exchangerate = 0;
      if ($form->{currency} eq $form->{defaultcurrency}) {
	$form->{"exchangerate_$i"} = 1;
      } else {
	$exchangerate = $form->check_exchangerate($myconfig, $form->{currency}, $form->{"datepaid_$i"}, 'buy');
	
	$form->{"exchangerate_$i"} = ($exchangerate) ? $exchangerate : $form->parse_amount($myconfig, $form->{"exchangerate_$i"}); 
      }
      

      # if there is no amount and invtotal is zero there is no exchangerate
      if ($form->{amount} == 0 && $form->{invtotal} == 0) {
	$form->{exchangerate} = $form->{"exchangerate_$i"};
      }
      
      # receivables amount
      $amount = $form->round_amount($form->{"paid_$i"} * $form->{exchangerate} * -1, 2);
      
      if ($form->{receivables} != 0) {
	# add receivable
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		    transdate)
		    VALUES ($form->{id},
		           (SELECT id FROM chart
			    WHERE accno = '$form->{AR}{receivables}'),
		    $amount, '$form->{"datepaid_$i"}')|;
	$dbh->do($query) || $form->dberror($query);
      }
      $form->{receivables} = $amount;
      
      # add payment
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		  transdate, source)
		  VALUES ($form->{id},
		         (SELECT id FROM chart
			  WHERE accno = '$form->{AR}{"paid_$i"}'),
		  $form->{"paid_$i"}, '$form->{"datepaid_$i"}',
		  '$form->{"source_$i"}')|;
      $dbh->do($query) || $form->dberror($query);
      
      
      # exchangerate difference for payment
      $amount = $form->round_amount($form->{"paid_$i"} * ($form->{"exchangerate_$i"} - 1), 2);
	
      if ($amount != 0) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		    transdate, fx_transaction, cleared)
		    VALUES ($form->{id},
		           (SELECT id FROM chart
			    WHERE accno = '$form->{AR}{"paid_$i"}'),
		    $amount, '$form->{"datepaid_$i"}', '1', '0')|;
	$dbh->do($query) || $form->dberror($query);
      }
	
      # exchangerate gain/loss
      $amount = $form->round_amount($form->{"paid_$i"} * ($form->{exchangerate} - $form->{"exchangerate_$i"}), 2);
      
      if ($amount != 0) {
	$accno = ($amount > 0) ? $form->{fxgain_accno} : $form->{fxloss_accno};
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		    transdate, fx_transaction, cleared)
		    VALUES ($form->{id}, (SELECT id FROM chart
					  WHERE accno = '$accno'),
		    $amount, '$form->{"datepaid_$i"}', '1', '0')|;
	$dbh->do($query) || $form->dberror($query);
      }
      
      # update exchangerate record
      if (($form->{currency} ne $form->{defaultcurrency}) && !$exchangerate) {
	$form->update_exchangerate($dbh, $form->{currency}, $form->{"datepaid_$i"}, $form->{"exchangerate_$i"}, 0);
      }
    }
  }


  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
  
}



sub delete_transaction {
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn AutoCommit off
  my $dbh = $form->dbconnect_noauto($myconfig);

  # check for other foreign currency transactions
  $form->delete_exchangerate($dbh) if ($form->{currency} ne $form->{defaultcurrency});

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

  my $paid = "a.paid";
  
  if ($form->{outstanding}) {
    $paid = qq|SELECT SUM(ac.amount) * -1
               FROM acc_trans ac
	       JOIN chart c ON (c.id = ac.chart_id)
	       WHERE ac.trans_id = a.id
	       AND (c.link LIKE '%AR_paid%' OR c.link = '')|;
    $paid .= qq|
               AND ac.transdate <= '$form->{transdateto}'| if $form->{transdateto};
  }
    
  my $query = qq|SELECT a.id, a.invnumber, a.ordnumber, a.transdate,
                 a.duedate, a.netamount, a.amount, ($paid) AS paid,
		 c.name, a.invoice, a.datepaid, a.terms,
		 a.notes, a.shippingpoint, a.till, e.name AS employee
	         FROM ar a
		 JOIN customer c ON (a.customer_id = c.id)
		 LEFT JOIN employee e ON (a.employee_id = e.id)
		 WHERE 1=1|;

  my %ordinal = ( 'transdate' => 4,
                  'invnumber' => 2,
		  'name' => 9,
		  'till' => 15,
		  'employee' => 16
	        );
  
  my @a = (transdate, invnumber, name);
  push @a, "employee" if $form->{l_employee};
  my $sortorder = join ',', $form->sort_columns(@a);
  map { $sortorder =~ s/$_/$ordinal{$_}/ } keys %ordinal;
  $sortorder = $form->{sort} unless $sortorder;


  if ($form->{customer_id}) {
    $query .= " AND a.customer_id = $form->{customer_id}";
  } else {
    if ($form->{customer}) {
      my $customer = $form->like(lc $form->{customer});
      $query .= " AND lower(c.name) LIKE '$customer'";
    }
  }
  if ($form->{invnumber}) {
    my $invnumber = $form->like(lc $form->{invnumber});
    $query .= " AND lower(a.invnumber) LIKE '$invnumber'";
    $form->{open} = $form->{closed} = 0;
  }
  if ($form->{ordnumber}) {
    my $ordnumber = $form->like(lc $form->{ordnumber});
    $query .= " AND lower(a.ordnumber) LIKE '$ordnumber'";
    $form->{open} = $form->{closed} = 0;
  }
  if ($form->{notes}) {
    my $notes = $form->like(lc $form->{notes});
    $query .= " AND lower(a.notes) LIKE '$notes'";
    $form->{open} = $form->{closed} = 0;
  }
  
  $query .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
  $query .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};
  if ($form->{open} || $form->{closed}) {
    unless ($form->{open} && $form->{closed}) {
      $query .= " AND a.amount <> a.paid" if ($form->{open});
      $query .= " AND a.amount = a.paid" if ($form->{closed});
    }
  }


  if ($form->{till}) {
    $query .= " AND a.invoice = '1'
                AND NOT a.till IS NULL";
    if (!$myconfig->{admin}) {
      $query .= " AND e.login = '$form->{login}'";
    }
  }

 
  if ($form->{AR}) {
    my ($accno) = split /--/, $form->{AR};
    $query .= qq|
                AND a.id IN (SELECT ac.trans_id
		             FROM acc_trans ac
			     JOIN chart c ON (c.id = ac.chart_id)
			     WHERE a.id = ac.trans_id
			     AND c.accno = '$accno')
		|;
  }

  
  $query .= " ORDER by $sortorder";

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    next if $form->{outstanding} && $ref->{amount} == $ref->{paid};
    push @{ $form->{transactions} }, $ref;
  }
  
  $sth->finish;
  $dbh->disconnect;

}


1;

