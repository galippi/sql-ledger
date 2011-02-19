#=====================================================================
# SQL-Ledger Accounting
# Copyright (C) 2002
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
 
  # get cleared balance
  if ($form->{fromdate}) {
    $query = qq|SELECT sum(ac.amount),
                     (SELECT DISTINCT category FROM chart
                      WHERE accno = '$form->{accno}') AS category
		FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		WHERE ac.transdate < date '$form->{fromdate}'
		AND ac.cleared = '1'
		AND c.accno = '$form->{accno}'
		|;
  } else {
    $query = qq|SELECT sum(ac.amount),
                     (SELECT DISTINCT category FROM chart
                      WHERE accno = '$form->{accno}') AS category
		FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		WHERE ac.cleared = '1'
		AND c.accno = '$form->{accno}'
		|;
  }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  ($form->{beginningbalance}, $form->{category}) = $sth->fetchrow_array;

  $sth->finish;


  if ($form->{fromdate}) {
    $query = qq|SELECT sum(ac.amount)
		FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		WHERE ac.transdate < date '$form->{fromdate}'
		AND ac.cleared = '1'
		AND c.accno = '$form->{accno}'
                AND ac.fx_transaction = '1';
		|;
  } else {
    $query = qq|SELECT sum(ac.amount)
		FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		WHERE ac.cleared = '1'
		AND c.accno = '$form->{accno}'
                AND ac.fx_transaction = '1';
		|;
  }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  ($form->{fx_balance}) = $sth->fetchrow_array;

  $sth->finish;

  $query = qq|SELECT c.name, ac.source, ac.transdate,
	      ac.fx_transaction, sum(ac.amount) AS amount
	      FROM acc_trans ac
	      JOIN ar a ON (ac.trans_id = a.id)
	      JOIN chart ch ON (ac.chart_id = ch.id)
	      JOIN customer c ON (c.id = a.customer_id)
	      WHERE ac.cleared = '0'
	      AND ch.accno = '$form->{accno}'
	      |;
	      
  $query .= " AND ac.transdate >= '$form->{fromdate}'" if $form->{fromdate};
  $query .= " AND ac.transdate <= '$form->{todate}'" if $form->{todate};
  $query .= " GROUP BY c.name, ac.source, ac.transdate,
              ac.fx_transaction";

  $query .= qq|
  
      UNION
              SELECT v.name, ac.source, ac.transdate,
	      ac.fx_transaction, sum(ac.amount) AS amount
	      FROM acc_trans ac
	      JOIN ap a ON (ac.trans_id = a.id)
	      JOIN chart ch ON (ac.chart_id = ch.id)
	      JOIN vendor v ON (v.id = a.vendor_id)
	      WHERE ac.cleared = '0'
	      AND ch.accno = '$form->{accno}'
	      |;
	      
  $query .= " AND ac.transdate >= '$form->{fromdate}'" if $form->{fromdate};
  $query .= " AND ac.transdate <= '$form->{todate}'" if $form->{todate};
  $query .= " GROUP BY v.name, ac.source, ac.transdate,
              ac.fx_transaction";

  $query .= qq|
  
      UNION
	      SELECT g.description, ac.source, ac.transdate,
	      ac.fx_transaction, sum(ac.amount) AS amount
	      FROM acc_trans ac
	      JOIN gl g ON (ac.trans_id = g.id)
	      JOIN chart ch ON (ac.chart_id = ch.id)
	      WHERE ac.cleared = '0'
	      AND ch.accno = '$form->{accno}'
	      |;

  $query .= " AND ac.transdate >= '$form->{fromdate}'" if $form->{fromdate};
  $query .= " AND ac.transdate <= '$form->{todate}'" if $form->{todate};
  $query .= " GROUP BY g.description, ac.source, ac.transdate,
              ac.fx_transaction";

  $query .= " ORDER BY 3,1,4";

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
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
    if ($form->{"cleared_$i"}) {
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

