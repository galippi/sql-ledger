##=====================================================================
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
# General ledger backend code
#
#======================================================================

package GL;

use SL::AM;

sub delete_transaction {
  my ($self, $myconfig, $form) = @_;
#KS
  my $tem=($_[3]) ? '_template' : '';
    
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my %audittrail = ( tablename  => 'gl'.$tem,
                     reference  => $form->{reference},
		     formname   => 'transaction',
		     action     => 'deleted',
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);

  my $query = qq|DELETE FROM gl$tem WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|DELETE FROM acc_trans$tem WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # commit and redirect
  my $rc = $dbh->commit;
  $dbh->disconnect;
  
  $rc;
  
}


sub post_transaction {
  
my ($self, $myconfig, $form) = @_;
  my $null;
  my $project_id;
  my $department_id;
  my $i;

  # connect to database, turn off AutoCommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  # post the transaction
  # make up a unique handle and store in reference field
  # then retrieve the record based on the unique handle to get the id
  # replace the reference field with the actual variable
  # add records to acc_trans

  # if there is a $form->{id} replace the old transaction
  # delete all acc_trans entries and add the new ones

  my $query;
  my $sth;
#kabai
    # did we use registered number or an odd number?
    undef my $toincrement;

    if ($form->{regsource}) {
 	 $form->{reference} = $form->{regsource};
	($toincrement) = $form->{reference}=~ /^(\p{IsAlpha}+)\p{IsDigit}+$/;

	# increment registered number
	AM->increment_regnum($myconfig, $form, $toincrement) if $toincrement;
    }
#KS
my $fname=($_[3]) ? "gl_template" : "gl";
 my $fname_acc=($_[3]) ? "acc_trans_template" : "acc_trans";
   if ($_[3]){
     $query=qq|SELECT id, tempnum from gl_template WHERE tempname='$form->{tempname}'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
     while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
       $query=qq|DELETE FROM gl_template WHERE id=$ref->{id}|;
       $dbh->do($query) || $form->dberror($query);
       $query=qq|DELETE FROM acc_trans_template WHERE trans_id=$ref->{id}|;
       $dbh->do($query) || $form->dberror($query);
       $tempnum=$ref->{tempnum};
     }
     if (!$tempnum){
       $query=qq|SELECT MAX(tempnum) FROM gl_template|;
       $dbh->do($query) || $form->dberror($query);
       $tempnum = $dbh->selectrow_array($query)+1;
    }
  }
#kabai -KS
  
  if ($form->{id} and !$_[3]) {
    # delete individual transactions
    $query = qq|DELETE FROM acc_trans 
                WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
    
  } else {
    my $uid = time;
    $uid .= $form->{login};

    $query = qq|INSERT INTO $fname (reference, employee_id)
                VALUES ('$uid', (SELECT id FROM employee
		                 WHERE login = '$form->{login}'))|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id FROM $fname
                WHERE reference = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;
  }
  
  ($null, $department_id) = split /--/, $form->{department};
  $department_id *= 1;
#kabai
  my $cash = $form->{cash} ? "t" : "f";  
#KS
  my $transdate = ($form->{transdate}) ? qq|'$form->{transdate}'| : 'NULL';
    
    #kabai
  $query = qq|UPDATE $fname SET 
	      reference = |.$dbh->quote($form->{reference}).qq|,
	      description = |.$dbh->quote($form->{description}).qq|,
	      notes = |.$dbh->quote($form->{notes}).qq|, |;
#KS
	      if($form->{transdate}) {$query.= qq|
	       transdate = '$form->{transdate}', |}
	      $query.= qq|
	      department_id = $department_id,
	      cash = '$cash'|;
#KS
              if ($_[3]) {$query.=qq|, tempname=|.$dbh->quote($form->{tempname}).qq|, tempnum=|.$tempnum.qq|, tip=|.$form->{tip}}
	      $query .=qq| WHERE id = $form->{id}|;
#$form->error($query);
  $dbh->do($query) || $form->dberror($query);


  my $amount = 0;
  my $posted = 0;
  # insert acc_trans transactions
  for $i (1 .. $form->{rowcount}) {

    $form->{"debit_$i"} = $form->parse_amount($myconfig, $form->{"debit_$i"});
    $form->{"credit_$i"} = $form->parse_amount($myconfig, $form->{"credit_$i"});

    # extract accno
    ($accno) = split(/--/, $form->{"accno_$i"});
    $amount = 0;
    
    if ($form->{"credit_$i"} != 0) {
      $amount = $form->{"credit_$i"};
      $posted = 0;
    }
    if ($form->{"debit_$i"} != 0) {
      $amount = $form->{"debit_$i"} * -1;
      $posted = 0;
    }


    # add the record
    if (! $posted) {
      
      ($null, $project_id) = split /--/, $form->{"projectnumber_$i"};
      $project_id *= 1;
      $form->{"fx_transaction_$i"} *= 1;
      
      $query = qq|INSERT INTO $fname_acc (trans_id, chart_id, amount, transdate,
		  source, project_id, fx_transaction, rowc)
		  VALUES
		  ($form->{id}, (SELECT id
				 FROM chart
				 WHERE accno = '$accno'),
		   $amount, $transdate, |
		   .$dbh->quote($form->{reference}).qq|,
		  $project_id, '$form->{"fx_transaction_$i"}', $i)|;
      $dbh->do($query) || $form->dberror($query);

      $posted = 1;
    }

  }
  
  my %audittrail = ( tablename  => 'gl',
                     reference  => $form->{reference},
		     formname   => 'transaction',
		     action     => 'posted',
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);

  # commit and redirect
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
#  $form->{id}=$id;
}



sub all_transactions {
  my ($self, $myconfig, $form) = @_;
#KS  
  $tem=($form->{listtype} eq "T") ? "_template" : "";
  $tn=($form->{listtype} eq "T") ? " g.tempname," : "";
  $tna=($form->{listtype} eq "T") ? " a.tempname," : "";   
   
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my ($query, $sth, $source, $null);

  my ($gljournalwhere,$glwhere, $arwhere, $apwhere) = ("g.id NOT IN (SELECT trans_id FROM acc_trans ac JOIN chart c ON (c.id = ac.chart_id) WHERE c.link LIKE '%_paid') ","1 = 1", "1 = 1", "1 = 1");
#KS 
  if ($form->{id}) {
    $glwhere .= " AND ac.trans_id = '$form->{id}'";
    $arwhere .= " AND ac.trans_id = '$form->{id}'";
    $apwhere .= " AND ac.trans_id = '$form->{id}'";
  }
  if ($form->{reference}) {
    $source = $form->like(lc $form->{reference});
    $glwhere .= " AND lower(g.reference) LIKE '$source'";
    $arwhere .= " AND lower(a.invnumber) LIKE '$source'";
    $apwhere .= " AND lower(a.invnumber) LIKE '$source'";
  }
  if ($form->{department}) {
    ($null, $source) = split /--/, $form->{department};
    $glwhere .= " AND g.department_id = $source";
    $arwhere .= " AND a.department_id = $source";
    $apwhere .= " AND a.department_id = $source";
  }

  if ($form->{source}) {
    $source = $form->like(lc $form->{source});
    $glwhere .= " AND lower(ac.source) LIKE '$source'";
    $arwhere .= " AND lower(ac.source) LIKE '$source'";
    $apwhere .= " AND lower(ac.source) LIKE '$source'";
  }
  if ($form->{datefrom}) {
    $glwhere .= " AND ac.transdate >= '$form->{datefrom}'";
    $arwhere .= " AND ac.transdate >= '$form->{datefrom}'";
    $apwhere .= " AND ac.transdate >= '$form->{datefrom}'";
  }
  if ($form->{dateto}) {
    $glwhere .= " AND ac.transdate <= '$form->{dateto}'";
    $arwhere .= " AND ac.transdate <= '$form->{dateto}'";
    $apwhere .= " AND ac.transdate <= '$form->{dateto}'";
  }
  if ($form->{idfrom}) {
    $glwhere .= " AND g.id >= $form->{idfrom}";
    $arwhere .= " AND a.id >= $form->{idfrom}";
    $apwhere .= " AND a.id >= $form->{idfrom}";
  }
  if ($form->{idto}) {
    $glwhere .= " AND g.id <= $form->{idto}";
    $arwhere .= " AND a.id <= $form->{idto}";
    $apwhere .= " AND a.id <= $form->{idto}";
  }
  if ($form->{amountfrom}) {
    $glwhere .= " AND abs(ac.amount) >= $form->{amountfrom}";
    $arwhere .= " AND abs(ac.amount) >= $form->{amountfrom}";
    $apwhere .= " AND abs(ac.amount) >= $form->{amountfrom}";
  }
  if ($form->{amountto}) {
    $glwhere .= " AND abs(ac.amount) <= $form->{amountto}";
    $arwhere .= " AND abs(ac.amount) <= $form->{amountto}";
    $apwhere .= " AND abs(ac.amount) <= $form->{amountto}";
  }
  if ($form->{description}) {
    my $description = $form->like(lc $form->{description});
    $glwhere .= " AND lower(g.description) LIKE '$description'";
    $arwhere .= " AND lower(ct.name) LIKE '$description'";
    $apwhere .= " AND lower(ct.name) LIKE '$description'";
  }
  if ($form->{notes}) {
    my $notes = $form->like(lc $form->{notes});
    $glwhere .= " AND lower(g.notes) LIKE '$notes'";
    $arwhere .= " AND lower(a.notes) LIKE '$notes'";
    $apwhere .= " AND lower(a.notes) LIKE '$notes'";
  }
  if ($form->{accno}) {
    $glwhere .= " AND c.accno = '$form->{accno}'";
    $arwhere .= " AND c.accno = '$form->{accno}'";
    $apwhere .= " AND c.accno = '$form->{accno}'";
  }
  if ($form->{gifi_accno}) {
    $glwhere .= " AND c.gifi_accno = '$form->{gifi_accno}'";
    $arwhere .= " AND c.gifi_accno = '$form->{gifi_accno}'";
    $apwhere .= " AND c.gifi_accno = '$form->{gifi_accno}'";
  }
  if ($form->{category} ne 'X') {
    $glwhere .= " AND c.category = '$form->{category}'";
    $arwhere .= " AND c.category = '$form->{category}'";
    $apwhere .= " AND c.category = '$form->{category}'";
  }
  if ($form->{accno}) {
    # get category for account
    $query = qq|SELECT category, link
                FROM chart
		WHERE accno = '$form->{accno}'|;
    $sth = $dbh->prepare($query); 

    $sth->execute || $form->dberror($query); 
    ($form->{ml}, $form->{link}) = $sth->fetchrow_array; 
    $sth->finish; 
    
    if ($form->{datefrom}) {
      $query = qq|SELECT SUM(ac.amount)
		  FROM acc_trans$tem ac, chart c
		  WHERE ac.chart_id = c.id
		  AND c.accno = '$form->{accno}'
		  AND ac.transdate < date '$form->{datefrom}'
		  |;
      $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);

      ($form->{balance}) = $sth->fetchrow_array;
      $sth->finish;
    }
     $counteraccno = ", g_accno_by_transid(ac.trans_id,ac.amount,ac.transdate, c.link) AS counteraccno ";
  }
  
  if ($form->{gifi_accno}) {
    # get category for account
    $query = qq|SELECT category, link
                FROM chart
		WHERE gifi_accno = '$form->{gifi_accno}'|;
    $sth = $dbh->prepare($query); 

    $sth->execute || $form->dberror($query); 
    ($form->{ml}, $form->{link}) = $sth->fetchrow_array; 
    $sth->finish; 
   
    if ($form->{datefrom}) {
      $query = qq|SELECT SUM(ac.amount)
		  FROM acc_trans ac, chart c
		  WHERE ac.chart_id = c.id
		  AND c.gifi_accno = '$form->{gifi_accno}'
		  AND ac.transdate < date '$form->{datefrom}'
		  |;
      $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);

      ($form->{balance}) = $sth->fetchrow_array;
      $sth->finish;
    }
#kabai
     $counteraccno = ", g_gifi_accno_by_transid(ac.trans_id,ac.amount,ac.transdate, c.link) AS counteraccno ";
#kabai         
  }

  my $false = ($myconfig->{dbdriver} =~ /Pg/) ? FALSE : q|'0'|;
#kabai BUG #KS                accno => 10,

  my %ordinal = ( id => 1,
                  transdate => 6,
                  reference => 4,
                  source => 7,
		  description => 5,
		  tempname => 8);
  
  my @a = (id, transdate, reference, source, description, tempname);
  my $sortorder = $form->sort_order(\@a, \%ordinal);
#kabai
my $query;
      if ($form->{journal} eq 'gl'){
     $query = qq|SELECT g.id, 'gl' AS type, $false AS invoice, g.reference,
                 g.description, ac.transdate, ac.source, $tn
		 ac.amount, c.accno, c.gifi_accno, g.notes, c.link,
		 c.description AS acc_descr, gifi.description AS gifi_descr, 
		 '' AS till, ac.cleared, cash $counteraccno
                 FROM gl$tem g 
		 JOIN acc_trans$tem ac ON (g.id = ac.trans_id)
		 JOIN chart c ON (ac.chart_id = c.id)
		 LEFT JOIN gifi ON ( gifi.accno = c.gifi_accno)
		 WHERE $gljournalwhere|;
#KS
		$query .= " AND tip = ".$form->{tip} if ($form->{tip} || ($form->{tip} eq '0'));		  
     	         $query.= qq| ORDER BY $sortorder|;
     }elsif ($form->{journal} eq 'ar'){
	  if ($form->{ordnumberfrom}) {
	    $arwhere .= " AND a.ordnumber >= '$form->{ordnumberfrom}'";
	    }
	  if ($form->{ordnumberto}) {
	    $arwhere .= " AND a.ordnumber <= '$form->{ordnumberto}'";
	    }

     $query = qq|SELECT a.id, 'ar' AS type, a.invoice, a.invnumber AS reference,
		 ct.name AS description, a.transdate, ac.source, $tna a.duedate,
		 ac.amount, c.accno, c.gifi_accno, a.notes, c.link,
		 c.description AS acc_descr, gifi.description AS gifi_descr, 
		 a.till, a.ordnumber, ac.cleared $counteraccno,
                 a.curr AS curr,  

		 CASE WHEN (a.curr <>'HUF'::bpchar) THEN ((
	         SELECT round(((a.amount / exchangerate.buy))::numeric, 2) AS round
	         FROM exchangerate
	         WHERE ((exchangerate.transdate = a.transdate) AND (a.curr = exchangerate.curr))
		 ))::double precision ELSE NULL::double precision END AS fxamount
		 

		 FROM ar$tem a 
		 JOIN acc_trans$tem ac ON (a.id = ac.trans_id)
		 JOIN chart c ON (ac.chart_id = c.id)
		 JOIN customer ct ON (a.customer_id = ct.id)
		 LEFT JOIN gifi ON ( gifi.accno = c.gifi_accno)
		 WHERE $arwhere
     	         ORDER BY $sortorder|;
     }elsif($form->{journal} eq 'ap'){
	  if ($form->{ordnumberfrom}) {
	    $apwhere .= " AND a.ordnumber >= '$form->{ordnumberfrom}'";
	    }
	  if ($form->{ordnumberto}) {
	    $apwhere .= " AND a.ordnumber <= '$form->{ordnumberto}'";
	    }


     $query = qq|SELECT a.id, 'ap' AS type, a.invoice, a.invnumber AS reference,
		 ct.name AS description, a.transdate, ac.source, $tna a.duedate,
		 ac.amount, c.accno, c.gifi_accno, a.notes, c.link,
		 c.description AS acc_descr, gifi.description AS gifi_descr, 
		 a.till, a.ordnumber, ac.cleared $counteraccno,
                 a.curr AS curr,  

		 CASE WHEN (a.curr <>'HUF'::bpchar) THEN ((
	         SELECT round(((a.amount / exchangerate.sell))::numeric, 2) AS round
	         FROM exchangerate
	         WHERE ((exchangerate.transdate = a.transdate) AND (a.curr = exchangerate.curr))
		 ))::double precision ELSE NULL::double precision END AS fxamount
		 
		 FROM ap$tem a 
		 JOIN acc_trans$tem ac ON (a.id = ac.trans_id)
		 JOIN chart c ON (ac.chart_id = c.id)
		 JOIN vendor ct ON (a.vendor_id = ct.id)
		 LEFT JOIN gifi ON ( gifi.accno = c.gifi_accno)
		 WHERE $apwhere
	         ORDER BY $sortorder|;

    }elsif($form->{journal} eq 'cash'){
     $query = qq|SELECT g.id, 'gl' AS type, $false AS invoice, g.reference,
                 g.description, ac.transdate, ac.source, $tn
		 ac.amount, c.accno, c.gifi_accno, g.notes, c.link,
		 c.description AS acc_descr, gifi.description AS gifi_descr, 
		 '' AS till, ac.cleared $counteraccno
                 FROM gl$tem g 
		 JOIN acc_trans$tem ac ON (g.id = ac.trans_id)
		 JOIN chart c ON (ac.chart_id = c.id)
		 LEFT JOIN gifi ON ( gifi.accno = c.gifi_accno)
		 WHERE $glwhere AND c.link LIKE '%_paid%'
	UNION ALL
	         SELECT a.id, 'ar' AS type, a.invoice, a.invnumber,
		 ct.name, ac.transdate, ac.source, $tna
		 ac.amount, c.accno, c.gifi_accno, a.notes, c.link,
		 c.description AS acc_descr, gifi.description AS gifi_descr, 
		 a.till, ac.cleared $counteraccno
		 FROM ar$tem a 
		 JOIN acc_trans$tem ac ON (a.id = ac.trans_id)
		 JOIN chart c ON (ac.chart_id = c.id)
		 JOIN customer ct ON (a.customer_id = ct.id)
		 LEFT JOIN gifi ON ( gifi.accno = c.gifi_accno)
		 WHERE $arwhere AND c.link LIKE '%_paid%'
	UNION ALL
	         SELECT a.id, 'ap' AS type, a.invoice, a.invnumber,
		 ct.name, ac.transdate, ac.source, $tna
		 ac.amount, c.accno, c.gifi_accno, a.notes, c.link,
		 c.description AS acc_descr, gifi.description AS gifi_descr, 
		 a.till, ac.cleared $counteraccno
		 FROM ap$tem a 
		 JOIN acc_trans ac ON (a.id = ac.trans_id)
		 JOIN chart c ON (ac.chart_id = c.id)
		 JOIN vendor ct ON (a.vendor_id = ct.id)
		 LEFT JOIN gifi ON ( gifi.accno = c.gifi_accno)
		 WHERE $apwhere AND c.link LIKE '%_paid%'
	         ORDER BY $sortorder|;

    }else{  
#kabai +5  
     $query = qq|SELECT g.id, 'gl' AS type, $false AS invoice, g.reference,
                 g.description, ac.transdate, ac.source, $tn
		 ac.amount, c.accno, c.gifi_accno, g.notes, c.link,
		 c.description AS acc_descr, gifi.description AS gifi_descr, 
		 '' AS till, ac.cleared, cash $counteraccno, fx_transaction
                 FROM gl$tem g 
		 JOIN acc_trans$tem ac ON (g.id = ac.trans_id)
		 JOIN chart c ON (ac.chart_id = c.id)
		 LEFT JOIN gifi ON ( gifi.accno = c.gifi_accno)
                 WHERE $glwhere
	UNION ALL
	         SELECT a.id, 'ar' AS type, a.invoice, a.invnumber,
		 ct.name, ac.transdate, ac.source, $tna
		 ac.amount, c.accno, c.gifi_accno, a.notes, c.link,
		 c.description AS acc_descr, gifi.description AS gifi_descr, 
		 a.till, ac.cleared, 'f' AS cash  $counteraccno, fx_transaction
		 FROM ar$tem a 
		 JOIN acc_trans$tem ac ON (a.id = ac.trans_id)
		 JOIN chart c ON (ac.chart_id = c.id)
		 JOIN customer ct ON (a.customer_id = ct.id)
		 LEFT JOIN gifi ON ( gifi.accno = c.gifi_accno)
		 WHERE $arwhere
	UNION ALL
	         SELECT a.id, 'ap' AS type, a.invoice, a.invnumber,
		 ct.name, ac.transdate, ac.source, $tna
		 ac.amount, c.accno, c.gifi_accno, a.notes, c.link,
		 c.description AS acc_descr, gifi.description AS gifi_descr, 
		 a.till, ac.cleared, 'f' AS cash $counteraccno, fx_transaction
		 FROM ap$tem a
		 JOIN acc_trans$tem ac ON (a.id = ac.trans_id)
		 JOIN chart c ON (ac.chart_id = c.id)
		 JOIN vendor ct ON (a.vendor_id = ct.id)
		 LEFT JOIN gifi ON ( gifi.accno = c.gifi_accno)
		 WHERE $apwhere
	         ORDER BY $sortorder|;
  } #query    
#$form->error($query);
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    # gl
    if ($ref->{type} eq "gl") {
      $ref->{module} = "gl";
    }

    # ap
    if ($ref->{type} eq "ap") {
      if ($ref->{invoice}) {
        $ref->{module} = "ir";
      } else {
        $ref->{module} = "ap";
      }
    }

    # ar
    if ($ref->{type} eq "ar") {
      if ($ref->{invoice}) {
        $ref->{module} = ($ref->{till}) ? "ps" : "is";
      } else {
        $ref->{module} = "ar";
      }
    }

    if ($ref->{amount} < 0) {
      $ref->{debit} = $ref->{amount} * -1;
      $ref->{credit} = 0;
    } else {
      $ref->{credit} = $ref->{amount};
      $ref->{debit} = 0;
    }

    push @{ $form->{GL} }, $ref;
    
  }


  $sth->finish;

  if ($form->{accno}) {
    $query = qq|SELECT description FROM chart WHERE accno = '$form->{accno}'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{account_description}) = $sth->fetchrow_array;
    $sth->finish;
  }
  if ($form->{gifi_accno}) {
    $query = qq|SELECT description FROM gifi WHERE accno = '$form->{gifi_accno}'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{gifi_account_description}) = $sth->fetchrow_array;
    $sth->finish;
  }
 
  $dbh->disconnect;

}


sub transaction {
  my ($self, $myconfig, $form) = @_;
  
  my ($query, $sth, $ref);
  my $temp=($_[3]) ? "_template" : "";  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  if ($form->{id}) {
    $query = "SELECT closedto, revtrans
              FROM defaults";
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{closedto}, $form->{revtrans}) = $sth->fetchrow_array;
    $sth->finish;

    $query = qq|SELECT g.*,
                d.description AS department
                FROM gl$temp g
	        LEFT JOIN department d ON (d.id = g.department_id)  
	        WHERE g.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
#KS
my $cash=$form->{cash};
   $ref->{transdate}=$form->{transdate} if !$ref->{transdate};
   $ref->{reference}=$form->{reference} if !$ref->{reference};
    map { $form->{$_} = $ref->{$_} } keys %$ref;
#$form->error($form->{transdate});
    if ($_[3]) {$form->{cash}=$cash}
    $sth->finish;
  

    # retrieve individual rows
    $query = qq|SELECT c.accno, c.description, ac.amount, ac.project_id,
                p.projectnumber, ac.fx_transaction, c.link
	        FROM acc_trans$temp ac
	        JOIN chart c ON (ac.chart_id = c.id)
	        LEFT JOIN project p ON (p.id = ac.project_id)
	        WHERE ac.trans_id = $form->{id}
	        ORDER BY ac.rowc|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      if ($ref->{link} =~ /paid/) {
	$form->{transfer} = 1;
      }
      push @{ $form->{GL} }, $ref;
    }
  } else {
    $query = "SELECT current_date AS transdate, closedto, revtrans
              FROM defaults";
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{transdate}, $form->{closedto}, $form->{revtrans}) = $sth->fetchrow_array;
#KS
    $form->{transdate}='' if $form->{sab}==1;
  }

  $sth->finish;

  my $paid;
  if ($form->{transfer}) {
#kabai
  if ($form->{cash}){
    $cashquery = " AND ptype = 'pcash'"; 
  }else{
    $cashquery = " AND ptype = 'bank'"; 
  }
#kabai
#kabai +1 +2
    $paid = qq|AND link LIKE '%_paid%'
             $cashquery 
             AND NOT (category = 'I'
	          OR category = 'E')
|;
#kabai	     
#	  UNION
	  
#	     SELECT accno,description
#	     FROM chart
#	     WHERE id IN (SELECT fxgain_accno_id FROM defaults)
#
#kabai	     OR id IN (SELECT fxloss_accno_id FROM defaults)|;
  }
  

  # get chart of accounts
#kabai +5
  $accorderby = ($form->{showaccnumbers_true}) ? "accno" : "description";
  $query = qq|SELECT accno,description
              FROM chart
	      WHERE charttype = 'A'
	      $paid
              ORDER by $accorderby|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_accno} }, $ref;
  }
  $sth->finish;
#kabai
  if (($form->{transfer} && !$form->{id}) or ($form->{sab}==2)) {
      $counterwhere = " AND link LIKE '%BANK%'";
      $counterwhere = " AND link LIKE '%CASH%'" if $form->{cash};
  }  
  $query = qq|SELECT accno,description
              FROM chart
	      WHERE charttype = 'A'
	      $counterwhere
              ORDER by $accorderby|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_accno2} }, $ref;
  }
  $sth->finish;
#kabai  
  # get projects
  $query = qq|SELECT *
              FROM project
	      ORDER BY projectnumber|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_projects} }, $ref;
  }
  $sth->finish;
#mEGYA
	# get registered numbers
	$query = "SELECT code || number AS regnum,
                  (SELECT accno FROM chart WHERE id=chart_id) AS regnum_accno,
		  regcheck, vcurr
		FROM regnum";
	$sth = $dbh->prepare($query);
	$sth->execute || $self->dberror($query);

	$form->{all_sources} = ();
	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{all_sources} }, $ref;
		}
	$sth->finish;
#mEGYA
  
  $dbh->disconnect;
}

sub first_cash {
	my ($self, $myconfig, $form) = @_;
	my ($query, $sth, $ref);

	# connect to database
	my $dbh = $form->dbconnect ($myconfig);
	for $i (1..$form->{rowcount}-1) {
		$query = qq| SELECT ptype
			     FROM chart
			     WHERE accno = '$form->{"accno_$i"}'|;
		$sth = $dbh->prepare($query);
		$sth->execute || $form->dberror($query);
		if ($sth->fetchrow_array eq "pcash"){
		 $form->{rsprint} = $i;
		 $sth->finish;
		 last;
		}
		$sth->finish;
	}
  $dbh->disconnect;
}
#KS
sub template_list {
  my ($self, $myconfig, $form) = @_;
  
# connect to database
    my $dbh = $form->dbconnect($myconfig);
    my $query = qq|SELECT id, tempname, tempnum FROM gl_template WHERE tip=|.$form->{tip}.qq| ORDER BY tempname ASC|;
    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    $form->{GL}=();
		  
    while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{GL} }, $ref;
    }
			    
    $sth->finish;
    $dbh->disconnect;
}
sub template_select {
  my ($self, $myconfig, $form) = @_;
  
# connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $query = qq|SELECT * FROM gl_template WHERE id=|. $form->{template};
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  $form->{GL}=();
	  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{GL} }, $ref;
  }
  my $query = qq|SELECT * FROM acc_trans_template WHERE trans_id=|. $form->{template};
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  $form->{GL_acc}=();
			  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{GL_acc} }, $ref;
  }
					  
  $sth->finish;
  $dbh->disconnect;
}
					      

sub is_account {
	my ($self, $myconfig, $form) = @_;
	my ($query, $sth, $ref);

	# connect to database
	my $dbh = $form->dbconnect ($myconfig);
	$query = qq| SELECT accno
		     FROM chart
		     WHERE accno = '$form->{"accno"}'|;
		$sth = $dbh->prepare($query);
		$sth->execute || $form->dberror($query);
		($form->{van})=$sth->fetchrow_array;
		$sth->finish;
	
  $dbh->disconnect;

 }


1;
