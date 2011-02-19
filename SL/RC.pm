#=====================================================================
# SQL-Ledger Accounting
# Copyright (C) 2002
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
# Account reconciliation routines
#
#======================================================================

package RC;


sub paymentaccounts {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT accno, description
                 FROM chart
		 WHERE link LIKE '%_paid%'
		 AND (category = 'A' OR category = 'L')
		 ORDER BY accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{PR} }, $ref;
  }
  $sth->finish;
  $dbh->disconnect;

}


sub payment_transactions {
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn AutoCommit off
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $sth;

  $query = qq|SELECT category FROM chart
              WHERE accno = '$form->{accno}'|;
  ($form->{category}) = $dbh->selectrow_array($query);
  
  my $cleared;
  my $transdate = qq| AND ac.transdate < date '$form->{fromdate}'|;

  if (! $form->{fromdate}) {
    $cleared = qq| AND ac.cleared = '1'|;
    $transdate = "";
  }
    
  # get beginning balance
  $query = qq|SELECT sum(ac.amount)
	      FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      WHERE c.accno = '$form->{accno}'
	      $transdate
	      $cleared
	      |;
  ($form->{beginningbalance}) = $dbh->selectrow_array($query);

  # fx balance
  $query = qq|SELECT sum(ac.amount)
	      FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      WHERE c.accno = '$form->{accno}'
	      AND ac.fx_transaction = '1'
	      $transdate
	      $cleared
	      |;
  ($form->{fx_balance}) = $dbh->selectrow_array($query);
  

  $transdate = "";
  if ($form->{todate}) {
    $transdate = qq| AND ac.transdate <= date '$form->{todate}'|;
  }
 
  # get statement balance
  $query = qq|SELECT sum(ac.amount)
	      FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      WHERE c.accno = '$form->{accno}'
	      $transdate
	      |;
  ($form->{endingbalance}) = $dbh->selectrow_array($query);

  # fx balance
  $query = qq|SELECT sum(ac.amount)
	      FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      WHERE c.accno = '$form->{accno}'
	      AND ac.fx_transaction = '1'
	      $transdate
	      |;
  ($form->{fx_endingbalance}) = $dbh->selectrow_array($query);


  $cleared = qq| AND ac.cleared = '0'| unless $form->{fromdate};
  
  if ($form->{report}) {
    $cleared = qq| AND NOT (ac.cleared = '0' OR ac.cleared = '1')|;
    if ($form->{cleared}) {
      $cleared = qq| AND ac.cleared = '1'|;
    }
    if ($form->{outstanding}) {
      $cleared = ($form->{cleared}) ? "" : qq| AND ac.cleared = '0'|;
    }
    if (! $form->{fromdate}) {
      $form->{beginningbalance} = 0;
      $form->{fx_balance} = 0;
    }
  }
  
  $query = qq|SELECT ac.transdate, ac.source, ac.fx_transaction,
              sum(ac.amount) AS amount, ac.cleared
	      FROM acc_trans ac
	      JOIN chart ch ON (ac.chart_id = ch.id)
	      WHERE ch.accno = '$form->{accno}'
	      $cleared|;
  $query .= " AND ac.transdate >= '$form->{fromdate}'" if $form->{fromdate};
  $query .= " AND ac.transdate <= '$form->{todate}'" if $form->{todate};
  $query .= " GROUP BY ac.source, ac.transdate, ac.fx_transaction, ac.cleared";
  $query .= " ORDER BY 1,2,3";

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  $query = qq|SELECT c.name
              FROM customer c
	      JOIN ar a ON (c.id = a.customer_id)
	      JOIN acc_trans ac ON (a.id = ac.trans_id)
	      WHERE ac.transdate = ?
	      AND ac.source = ?
	      $cleared
  
      UNION
              SELECT v.name
	      FROM vendor v
	      JOIN ap a ON (v.id = a.vendor_id)
	      JOIN acc_trans ac ON (a.id = ac.trans_id)
	      WHERE ac.transdate = ?
	      AND ac.source = ?
	      $cleared
	      
      UNION
	      SELECT g.description
	      FROM gl g
	      JOIN acc_trans ac ON (g.id = ac.trans_id)
	      WHERE ac.transdate = ?
	      AND ac.source = ?
	      $cleared
	      |;
  
  $query .= " ORDER BY 1";
  
  my $tth = $dbh->prepare($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $tth->execute($ref->{transdate}, $ref->{source}, $ref->{transdate}, $ref->{source}, $ref->{transdate}, $ref->{source});
    $ref->{oldcleared} = $ref->{cleared};
    $ref->{name} = ();
    while (my ($name) = $tth->fetchrow_array) {
      push @{ $ref->{name} }, $name;
    }
    $tth->finish;

    push @{ $form->{PR} }, $ref;
    
  }
  $sth->finish;

  $dbh->disconnect;
  
}


sub reconcile {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT id FROM chart
                 WHERE accno = '$form->{accno}'|;
  my ($chart_id) = $dbh->selectrow_array($query);
  $chart_id *= 1;
  
  $query = qq|SELECT trans_id FROM acc_trans
              WHERE source = ?
	      AND transdate = ?
	      AND cleared = '0'|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
    
  my $i;
  my $trans_id;

  $query = qq|UPDATE acc_trans SET cleared = '1'
              WHERE cleared = '0'
	      AND trans_id = ? 
	      AND transdate = ?
	      AND chart_id = $chart_id|;
  my $tth = $dbh->prepare($query) || $form->dberror($query);
  
  # clear flags
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"cleared_$i"} && ! $form->{"oldcleared_$i"}) {
      $sth->execute($form->{"source_$i"}, $form->{"transdate_$i"}) || $form->dberror;
      while (($trans_id) = $sth->fetchrow_array) {
	$tth->execute($trans_id, $form->{"transdate_$i"}) || $form->dberror;
	$tth->finish;
      }
      $sth->finish;
    }
  }

  $dbh->disconnect;

}

1;

