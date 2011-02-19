#=====================================================================
# SQL-Ledger Accounting
# Copyright (C) 2003
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
# Batch printing module backend routines
#
#======================================================================

package BP;


sub get_vc {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my %arap = ( invoice => 'ar',
               packing_list => 'oe',
	       sales_order => 'oe',
	       work_order => 'oe',
	       pick_list => 'oe',
	       purchase_order => 'oe',
	       bin_list => 'oe',
	       sales_quotation => 'oe',
	       request_quotation => 'oe',
	       check => 'ap',
	       receipt => 'ar'
	     );
  
  $query = qq|SELECT count(*)
	      FROM (SELECT DISTINCT vc.id
		    FROM $form->{vc} vc, $arap{$form->{type}} a, status s
		    WHERE a.$form->{vc}_id = vc.id
		    AND s.trans_id = a.id
		    AND s.formname = '$form->{type}'
		    AND s.spoolfile IS NOT NULL) AS total|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  my ($count) = $sth->fetchrow_array;
  $sth->finish;

  # build selection list
  if ($count < $myconfig->{vclimit}) {
    $query = qq|SELECT DISTINCT vc.id, vc.name
                FROM $form->{vc} vc, $arap{$form->{type}} a, status s
		WHERE a.$form->{vc}_id = vc.id
		AND s.trans_id = a.id
		AND s.formname = '$form->{type}'
		AND s.spoolfile IS NOT NULL|;
  }
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{"all_$form->{vc}"} }, $ref;
  }
  
  $sth->finish;
  $dbh->disconnect;
 
}
		 
  

sub payment_accounts {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT DISTINCT c.accno, c.description
                 FROM status s, chart c
		 WHERE s.chart_id = c.id
		 AND s.formname = '$form->{type}'|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{accounts} }, $ref;
  }
  
  $sth->finish;
  $dbh->disconnect;
  
}

 
sub get_spoolfiles {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query;
  my $var;
  
  my %arap = ( invoice => 'ar',
               packing_list => 'oe',
	       sales_order => 'oe',
	       work_order => 'oe',
	       pick_list => 'oe',
	       purchase_order => 'oe',
	       bin_list => 'oe',
	       sales_quotation => 'oe',
	       request_quotation => 'oe',
	       check => 'ap',
	       receipt => 'ar'
	     );
  
  my $invnumber = "invnumber";

  if ($form->{type} eq 'check' || $form->{type} eq 'receipt') {
    
    my ($accno) = split /--/, $form->{account};
    
    $query = qq|SELECT a.id, vc.name, a.invnumber, ac.transdate, s.spoolfile,
                a.invoice, '$arap{$form->{type}}' AS module
                FROM status s, chart c, $form->{vc} vc,
		$arap{$form->{type}} a, acc_trans ac
		WHERE s.formname = '$form->{type}'
		AND s.chart_id = c.id
		AND c.accno = '$accno'
		AND s.trans_id = a.id
		AND a.$form->{vc}_id = vc.id
		AND ac.trans_id = s.trans_id
		AND ac.chart_id = c.id
		AND NOT ac.fx_transaction|;
  } else {
 
    $invoice = "a.invoice";
    
    if ($form->{type} !~ /invoice/) {
      $invnumber = "ordnumber";
      $invoice = '0';
    }
      
    $query = qq|SELECT a.id, vc.name, a.$invnumber AS invnumber, a.transdate,
                a.ordnumber, a.quonumber, $invoice AS invoice,
		'$arap{$form->{type}}' AS module, s.spoolfile
		FROM $arap{$form->{type}} a, $form->{vc} vc, status s
		WHERE s.trans_id = a.id
		AND s.spoolfile IS NOT NULL
		AND s.formname = '$form->{type}'
		AND a.$form->{vc}_id = vc.id|;
  }
  
  my %ordinal = ( 'name' => 2,
                  'invnumber' => 3,
                  'transdate' => 4,
		  'ordnumber' => 5,
		  'quonumber' => 6
		);
  my @a = (transdate, $invnumber, name);
  my $sortorder = $form->sort_order(\@a, \%ordinal);
  
  if ($form->{"$form->{vc}_id"}) {
    $query .= qq| AND a.$form->{vc}_id = $form->{"$form->{vc}_id"}|;
  } else {
    if ($form->{$form->{vc}}) {
      $var = $form->like(lc $form->{$form->{vc}});
      $query .= " AND lower(vc.name) LIKE '$var'";
    }
  }
  if ($form->{invnumber}) {
    $var = $form->like(lc $form->{invnumber});
    $query .= " AND lower(a.invnumber) LIKE '$var'";
  }
  if ($form->{ordnumber}) {
    $var = $form->like(lc $form->{ordnumber});
    $query .= " AND lower(a.ordnumber) LIKE '$var'";
  }
  if ($form->{quonumber}) {
    $var = $form->like(lc $form->{quonumber});
    $query .= " AND lower(a.quonumber) LIKE '$var'";
  }

  $query .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
  $query .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};
  
  $query .= " ORDER by $sortorder";


  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{SPOOL} }, $ref;
  }
  
  $sth->finish;
  $dbh->disconnect;

}


sub delete_spool {
  my ($self, $myconfig, $form, $spool) = @_;

  # connect to database, turn AutoCommit off
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my %audittrail;
  
  if ($form->{type} =~ /(check|receipt)/) {
    $query = qq|DELETE FROM status
                WHERE spoolfile = ?|;
  } else {
    $query = qq|UPDATE status SET
                 spoolfile = NULL,
		 printed = '1'
                 WHERE spoolfile = ?|;
  }
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  
  
  foreach my $i (1 .. $form->{rowcount}) {
    if ($form->{"checked_$i"}) {
      $sth->execute($form->{"spoolfile_$i"}) || $form->dberror($query);
      $sth->finish;
      
      %audittrail = ( tablename  => $form->{module},
                      reference  => $form->{"reference_$i"},
		      formname   => $form->{type},
		      action     => 'dequeued',
		      id         => $form->{"id_$i"} );
 
      $form->audittrail($dbh, "", \%audittrail);
    }
  }
    
  # commit
  my $rc = $dbh->commit;
  $dbh->disconnect;

  if ($rc) {
    foreach my $i (1 .. $form->{rowcount}) {
      $_ = qq|$spool/$form->{"spoolfile_$i"}|;
      if ($form->{"checked_$i"}) {
	unlink;
      }
    }
  }

  $rc;
  
}


sub print_spool {
  my ($self, $myconfig, $form, $spool) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my %audittrail;
  
  my $query = qq|UPDATE status SET
		 printed = '1'
                 WHERE formname = '$form->{type}'
		 AND spoolfile = ?|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  
  foreach my $i (1 .. $form->{rowcount}) {
    if ($form->{"checked_$i"}) {
      open(OUT, $form->{OUT}) or $form->error("$form->{OUT} : $!");
      
      $spoolfile = qq|$spool/$form->{"spoolfile_$i"}|;
      
      # send file to printer
      open(IN, $spoolfile) or $form->error("$spoolfile : $!");

      while (<IN>) {
	print OUT $_;
      }
      close(IN);
      close(OUT);

      $sth->execute($form->{"spoolfile_$i"}) || $form->dberror($query);
      $sth->finish;
      
      %audittrail = ( tablename  => $form->{module},
                      reference  => $form->{"reference_$i"},
		      formname   => $form->{type},
		      action     => 'printed',
		      id         => $form->{"id_$i"} );
 
      $form->audittrail($dbh, "", \%audittrail);
      
      $dbh->commit;
    }
  }

  $dbh->disconnect;

}


1;

