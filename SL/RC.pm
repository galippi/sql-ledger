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

  my ($query, $sth);
  
 
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


  my %oid = ( 'Pg'	=> 'ac.oid',
              'PgPP'	=> 'ac.oid',
              'Oracle'	=> 'ac.rowid',
	      'DB2'	=> 'ac.trans_id || ac.chart_id || ac.transdate'
	    );
  
  $query = qq|SELECT c.name, ac.source, ac.transdate, ac.cleared,
	      ac.fx_transaction, ac.amount, a.id,
	      $oid{$myconfig->{dbdriver}} AS oid
	      FROM customer c, acc_trans ac, ar a, chart ch
	      WHERE c.id = a.customer_id
	      AND ac.cleared = '0'
	      AND ac.trans_id = a.id
	      AND ac.chart_id = ch.id
	      AND ch.accno = '$form->{accno}'
	      |;
	      
  $query .= " AND ac.transdate >= '$form->{fromdate}'" if $form->{fromdate};
  $query .= " AND ac.transdate <= '$form->{todate}'" if $form->{todate};


  $query .= qq|
  
      UNION
              SELECT v.name, ac.source, ac.transdate, ac.cleared,
	      ac.fx_transaction, ac.amount, a.id,
	      $oid{$myconfig->{dbdriver}} AS oid 
	      FROM vendor v, acc_trans ac, ap a, chart ch
	      WHERE v.id = a.vendor_id
	      AND ac.cleared = '0'
	      AND ac.trans_id = a.id
	      AND ac.chart_id = ch.id
	      AND ch.accno = '$form->{accno}'
	     |;
	      
  $query .= " AND ac.transdate >= '$form->{fromdate}'" if $form->{fromdate};
  $query .= " AND ac.transdate <= '$form->{todate}'" if $form->{todate};

  $query .= qq|
  
      UNION
	      SELECT g.description, ac.source, ac.transdate, ac.cleared,
	      ac.fx_transaction, ac.amount, g.id,
	      $oid{$myconfig->{dbdriver}} AS oid 
	      FROM gl g, acc_trans ac, chart ch
	      WHERE g.id = ac.trans_id
	      AND ac.cleared = '0'
	      AND ac.trans_id = g.id
	      AND ac.chart_id = ch.id
	      AND ch.accno = '$form->{accno}'
	      |;

  $query .= " AND ac.transdate >= '$form->{fromdate}'" if $form->{fromdate};
  $query .= " AND ac.transdate <= '$form->{todate}'" if $form->{todate};

  $query .= " ORDER BY 3,7,8";

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $pr = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{PR} }, $pr;
  }
  $sth->finish;

  $dbh->disconnect;
  
}


sub reconcile {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my ($query, $i);
  my %oid = ( 'Pg'	=> 'oid',
              'PgPP'	=> 'oid',
              'Oracle'	=> 'rowid',
	      'DB2'	=> 'trans_id || chart_id || transdate'
	    );
  
  # clear flags
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"cleared_$i"}) {
      $query = qq|UPDATE acc_trans SET cleared = '1'
		  WHERE $oid{$myconfig->{dbdriver}} = $form->{"oid_$i"}|;
      $dbh->do($query) || $form->dberror($query);

      # clear fx_transaction
      if ($form->{"fxoid_$i"}) {
	$query = qq|UPDATE acc_trans SET cleared = '1'
		    WHERE $oid{$myconfig->{dbdriver}} = $form->{"fxoid_$i"}|;
	$dbh->do($query) || $form->dberror($query);
      }
    }
  }

  $dbh->disconnect;

}

1;

