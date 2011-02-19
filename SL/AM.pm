#=====================================================================
# SQL-Ledger Accounting
# Copyright (C) 2000
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#
#  Modified by Tavugyvitel Kft. (info@tavugyvitel.hu) 
#  Contributors: Jim Rawlings <jim@your-dba.com>
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
# Administration module
#    Chart of Accounts
#    template routines
#    preferences
#
#======================================================================

package AM;


sub get_account {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
#kabai +2
  my $query = qq|SELECT accno, description, charttype, gifi_accno, notes,
                 category, link, ptype
                 FROM chart
	         WHERE id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
  
  foreach my $key (keys %$ref) {
    $form->{"$key"} = $ref->{"$key"};
  }

  # get default accounts
  $query = qq|SELECT inventory_accno_id, income_accno_id, expense_accno_id
              FROM defaults|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $ref = $sth->fetchrow_hashref(NAME_lc);
  map { $form->{$_} = $ref->{$_} } keys %ref;
  $sth->finish;

  # check if we have any transactions
  $query = qq|SELECT trans_id FROM acc_trans
              WHERE chart_id = $form->{id}|;
  ($form->{orphaned}) = $dbh->selectrow_array($query);
  $form->{orphaned} = !$form->{orphaned};

  $dbh->disconnect;

}


sub save_account {
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn off AutoCommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  $form->{link} = "";
  foreach my $item ($form->{AR},
		    $form->{AR_amount},
                    $form->{AR_tax},
                    $form->{AR_paid},
                    $form->{AP},
		    $form->{AP_amount},
		    $form->{ASSET},
		    $form->{AP_tax},
		    $form->{AP_paid},
		    $form->{IC},
		    $form->{IC_sale},
		    $form->{IC_cogs},
		    $form->{IC_taxpart},
		    $form->{IC_income},
		    $form->{IC_expense},
		    $form->{IC_taxservice},
		    $form->{CT_tax},
		    $form->{BANK},
		    $form->{CASH}
		    ) {
     $form->{link} .= "${item}:" if ($item);
  }
  chop $form->{link};
 
  # strip blanks from accno
  map { $form->{$_} =~ s/( |')//g } qw(accno gifi_accno);
  
  foreach my $item (qw(accno gifi_accno description)) {
    $form->{$item} =~ s/-(-+)/-/g;
    $form->{$item} =~ s/ ( )+/ /g;
  }
  
  my $query;
  my $sth;
  
  # if we have an id then replace the old record
  if ($form->{id}) {
#kabai +7
    $query = qq|UPDATE chart SET
                accno = '$form->{accno}',
		description = |.$dbh->quote($form->{description}).qq|,
		charttype = '$form->{charttype}',
		gifi_accno = '$form->{gifi_accno}',
		category = '$form->{category}',
		link = '$form->{link}',
		notes = '$form->{notes}',
		ptype = '$form->{ptype}'
		WHERE id = $form->{id}|;
  } else {
#kabai +2,+6
    $query = qq|INSERT INTO chart 
                (accno, description, charttype, gifi_accno, category, link, ptype, notes)
                VALUES ('$form->{accno}',|
		.$dbh->quote($form->{description}).qq|,
		'$form->{charttype}', '$form->{gifi_accno}',
		'$form->{category}', '$form->{link}', '$form->{ptype}', '$form->{notes}')|;
  }
  $dbh->do($query) || $form->dberror($query);


  $chart_id = $form->{id};

  if (! $form->{id}) {
    # get id from chart
    $query = qq|SELECT id
		FROM chart
		WHERE accno = '$form->{accno}'|;
    ($chart_id) = $dbh->selectrow_array($query);
  }

  if ($form->{IC_taxpart} || $form->{IC_taxservice} || $form->{CT_tax}) {
   
    # add account if it doesn't exist in tax
    $query = qq|SELECT chart_id
                FROM tax
		WHERE chart_id = $chart_id|;
    my ($tax_id) = $dbh->selectrow_array($query);
    
    # add tax if it doesn't exist
    unless ($tax_id) {
      $query = qq|INSERT INTO tax (chart_id, rate)
                  VALUES ($chart_id, 0)|;
      $dbh->do($query) || $form->dberror($query);
    }
  } else {
    # remove tax
    if ($form->{id}) {
      $query = qq|DELETE FROM tax
		  WHERE chart_id = $form->{id}|;
      $dbh->do($query) || $form->dberror($query);
    }
  }

  # commit
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
  
}



sub delete_account {
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn off AutoCommit
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my $query = qq|SELECT * FROM acc_trans
                 WHERE chart_id = $form->{id}|;
  if ($dbh->selectrow_array($query)) {
    $dbh->disconnect;
    return;
  }


  # delete chart of account record
  $query = qq|DELETE FROM chart
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # set inventory_accno_id, income_accno_id, expense_accno_id to defaults
  $query = qq|UPDATE parts
              SET inventory_accno_id = 
	                 (SELECT inventory_accno_id FROM defaults)
	      WHERE inventory_accno_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|UPDATE parts
              SET income_accno_id =
	                 (SELECT income_accno_id FROM defaults)
	      WHERE income_accno_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|UPDATE parts
              SET expense_accno_id =
	                 (SELECT expense_accno_id FROM defaults)
	      WHERE expense_accno_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  foreach my $table (qw(partstax customertax vendortax tax)) {
    $query = qq|DELETE FROM $table
		WHERE chart_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }

  # commit and redirect
  my $rc = $dbh->commit;
  $dbh->disconnect;
  
  $rc;

}


sub gifi_accounts {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT accno, description
                 FROM gifi
		 ORDER BY accno|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }

  $sth->finish;
  $dbh->disconnect;
  
}



sub get_gifi {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT accno, description
                 FROM gifi
	         WHERE accno = '$form->{accno}'|;

  ($form->{accno}, $form->{description}) = $dbh->selectrow_array($query);

  # check for transactions
  $query = qq|SELECT * FROM acc_trans a
              JOIN chart c ON (a.chart_id = c.id)
	      JOIN gifi g ON (c.gifi_accno = g.accno)
	      WHERE g.accno = '$form->{accno}'|;
  ($form->{orphaned}) = $dbh->selectrow_array($query);
  $form->{orphaned} = !$form->{orphaned};

  $dbh->disconnect;

}


sub save_gifi {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{accno} =~ s/( |')//g;
  
  foreach my $item (qw(accno description)) {
    $form->{$item} =~ s/-(-+)/-/g;
    $form->{$item} =~ s/ ( )+/ /g;
  }

  # id is the old account number!
  if ($form->{id}) {
    $query = qq|UPDATE gifi SET
                accno = '$form->{accno}',
		description = |.$dbh->quote($form->{description}).qq|
		WHERE accno = '$form->{id}'|;
  } else {
    $query = qq|INSERT INTO gifi 
                (accno, description)
                VALUES ('$form->{accno}',|
		.$dbh->quote($form->{description}).qq|)|;
  }
  $dbh->do($query) || $form->dberror; 
  
  $dbh->disconnect;

}


sub delete_gifi {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  # id is the old account number!
  $query = qq|DELETE FROM gifi
	      WHERE accno = '$form->{id}'|;
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}


sub warehouses {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->sort_order();
  my $query = qq|SELECT id, description
                 FROM warehouse
		 ORDER BY 2 $form->{direction}|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }

  $sth->finish;
  $dbh->disconnect;
  
}



sub get_warehouse {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT description
                 FROM warehouse
	         WHERE id = $form->{id}|;
  ($form->{description}) = $dbh->selectrow_array($query);

  # see if it is in use
  $query = qq|SELECT * FROM inventory
              WHERE warehouse_id = $form->{id}|;
  ($form->{orphaned}) = $dbh->selectrow_array($query);
  $form->{orphaned} = !$form->{orphaned};

  $dbh->disconnect;

}


sub save_warehouse {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $form->{description} =~ s/-(-)+/-/g;
  $form->{description} =~ s/ ( )+/ /g;

  if ($form->{id}) {
    $query = qq|UPDATE warehouse SET
		description = |.$dbh->quote($form->{description}).qq|
		WHERE id = $form->{id}|;
  } else {
    $query = qq|INSERT INTO warehouse
                (description)
                VALUES (|.$dbh->quote($form->{description}).qq|)|;
  }
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}


sub delete_warehouse {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $query = qq|DELETE FROM warehouse
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}



sub departments {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->sort_order();
  my $query = qq|SELECT id, description, role
                 FROM department
		 ORDER BY 2 $form->{direction}|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }

  $sth->finish;
  $dbh->disconnect;
  
}



sub get_department {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT description, role
                 FROM department
	         WHERE id = $form->{id}|;
  ($form->{description}, $form->{role}) = $dbh->selectrow_array($query);
  
  map { $form->{$_} = $ref->{$_} } keys %$ref;

  # see if it is in use
  $query = qq|SELECT * FROM dpt_trans
              WHERE department_id = $form->{id}|;
  ($form->{orphaned}) = $dbh->selectrow_array($query);
  $form->{orphaned} = !$form->{orphaned};

  $dbh->disconnect;

}


sub save_department {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{description} =~ s/-(-)+/-/g;
  $form->{description} =~ s/ ( )+/ /g;

  if ($form->{id}) {
    $query = qq|UPDATE department SET
		description = |.$dbh->quote($form->{description}).qq|,
		role = '$form->{role}'
		WHERE id = $form->{id}|;
  } else {
    $query = qq|INSERT INTO department 
                (description, role)
                VALUES (|
		.$dbh->quote($form->{description}).qq|, '$form->{role}')|;
  }
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}


sub delete_department {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $query = qq|DELETE FROM department
	      WHERE id = $form->{id}|;
  $dbh->do($query);
  
  $dbh->disconnect;

}


sub business {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->sort_order();
  my $query = qq|SELECT id, description, discount, tdij1, tdij2
                 FROM business
		 ORDER BY 2 $form->{direction}|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }

  $sth->finish;
  $dbh->disconnect;
  
}



sub get_business {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT description, discount, tdij1, tdij2
                 FROM business
	         WHERE id = $form->{id}|;
  ($form->{description}, $form->{discount}, $form->{tdij1}, $form->{tdij2}) = $dbh->selectrow_array($query);

  $dbh->disconnect;

}


sub save_business {
  my ($self, $myconfig, $form) = @_;
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  $form->{description} =~ s/-(-)+/-/g;
  $form->{description} =~ s/ ( )+/ /g;
  $discount = $form->parse_amount($myconfig,$form->{discount})/100;
  if ($form->{id}) {
    $query = qq|UPDATE business SET
		description = |.$dbh->quote($form->{description}).qq|,
		discount = $discount, 
		tdij1=|.$form->parse_amount($myconfig, $form->{tdij1}).qq|, 
		tdij2=|.$form->parse_amount($myconfig, $form->{tdij2}).qq|
		WHERE id = $form->{id}|;
  } else {
    $query = qq|INSERT INTO business 
                (description, discount, tdij1, tdij2)
		VALUES (|
		.$dbh->quote($form->{description}).qq|, $discount, |
		.$form->parse_amount($myconfig, $form->{tdij1}).qq|, |
		.$form->parse_amount($myconfig, $form->{tdij2}).qq|)|;
  }
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}


sub delete_business {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $query = qq|DELETE FROM business
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}


sub sic {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{sort} = "code" unless $form->{sort};
  my @a = qw(code description);
  my %ordinal = ( code		=> 1,
                  description	=> 3 );
  my $sortorder = $form->sort_order(\@a, \%ordinal);
  my $query = qq|SELECT code, sictype, description
                 FROM sic
		 ORDER BY $sortorder|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }

  $sth->finish;
  $dbh->disconnect;
  
}



sub get_sic {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT code, sictype, description
                 FROM sic
	         WHERE code = |.$dbh->quote($form->{code});
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
  
  map { $form->{$_} = $ref->{$_} } keys %$ref;

  $sth->finish;
  $dbh->disconnect;

}


sub save_sic {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  foreach my $item (qw(code description)) {
    $form->{$item} =~ s/-(-)+/-/g;
  }
 
  # if there is an id
  if ($form->{id}) {
    $query = qq|UPDATE sic SET
                code = |.$dbh->quote($form->{code}).qq|,
		sictype = '$form->{sictype}',
		description = |.$dbh->quote($form->{description}).qq|
		WHERE code = |.$dbh->quote($form->{id});
  } else {
    $query = qq|INSERT INTO sic 
                (code, sictype, description)
                VALUES (|
		.$dbh->quote($form->{code}).qq|,
		'$form->{sictype}',|
		.$dbh->quote($form->{description}).qq|)|;
  }
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}


sub delete_sic {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $query = qq|DELETE FROM sic
	      WHERE code = |.$dbh->quote($form->{code});
  $dbh->do($query);
  
  $dbh->disconnect;

}


sub language {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{sort} = "code" unless $form->{sort};
  my @a = qw(code description);
  my %ordinal = ( code		=> 1,
                  description	=> 2 );
  my $sortorder = $form->sort_order(\@a, \%ordinal);
  
  my $query = qq|SELECT code, description
                 FROM language
		 ORDER BY $sortorder|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{ALL} }, $ref;
  }
  
#kabai
  $sth->finish;
#kabai
  $dbh->disconnect;
  
}



sub get_language {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT *
                 FROM language
	         WHERE code = |.$dbh->quote($form->{code});
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
  
  map { $form->{$_} = $ref->{$_} } keys %$ref;

  $sth->finish;

  $dbh->disconnect;

}


sub save_language {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->{code} =~ s/ //g;
  foreach my $item (qw(code description)) {
    $form->{$item} =~ s/-(-)+/-/g;
    $form->{$item} =~ s/ ( )+/-/g;
  }
  
  # if there is an id
  if ($form->{id}) {
    $query = qq|UPDATE language SET
                code = |.$dbh->quote($form->{code}).qq|,
		description = |.$dbh->quote($form->{description}).qq|
		WHERE code = |.$dbh->quote($form->{id});
  } else {
    $query = qq|INSERT INTO language
                (code, description)
                VALUES (|
		.$dbh->quote($form->{code}).qq|,|
		.$dbh->quote($form->{description}).qq|)|;
  }
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}


sub delete_language {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $query = qq|DELETE FROM language
	      WHERE code = |.$dbh->quote($form->{code});
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}



sub regnum {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$form->{sort} = "description" unless $form->{sort};
	my @a = qw(description regnumber);
	my %ordinal = (
		description => 1,
		regnumber => 2
		);
	my $sortorder = $form->sort_order(\@a, \%ordinal);

	my $query = "SELECT description, code || number AS regnum, code,
		(SELECT accno || '--' || description FROM chart WHERE id = chart_id) AS cashaccount,
		regcheck
		FROM regnum
		ORDER BY $sortorder";
	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{ALL} }, $ref;
		}

	$sth->finish;
	$dbh->disconnect;
	}


sub get_regnum {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT code, number, description, 
		      (SELECT accno FROM chart WHERE id = chart_id) AS cashaccount,
		      regcheck, vcurr
		      FROM regnum
		      WHERE code = |.$dbh->quote($form->{code});
	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
	map { $form->{$_} = $ref->{$_} } keys %$ref;
	$sth->finish;
	my $query= qq|SELECT mincash, maxcash FROM regnum_cash WHERE chart_id =
		      (SELECT id FROM chart WHERE accno = '$form->{cashaccount}')|;
	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
	map { $form->{$_} = $ref->{$_} } keys %$ref;

	$sth->finish;
	$dbh->disconnect;
	}


sub save_regnum {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	foreach my $item (qw(code description)) {
		$form->{$item} =~ s/-(-)+/-/g;
		}

	# if there is an id
	if ($form->{id}) {
		$query = qq|UPDATE regnum SET
			code = |.$dbh->quote($form->{code}).qq|,
			number = |.$dbh->quote($form->{number}).qq|,
			description = |.$dbh->quote($form->{description}).qq|,
			chart_id = (SELECT id FROM chart WHERE accno = '$form->{cashaccount}'),
			regcheck = '$form->{regcheck}',
			vcurr = '$form->{vcurr}'
			WHERE code = |.$dbh->quote($form->{id});
		}
	else {
		$query = qq|INSERT INTO regnum
                (code|;
		$query .= qq|, number| if ($form->{number});
		$query .= qq|, description, chart_id, regcheck, vcurr)
                VALUES (| . $dbh->quote($form->{code});
		$query .= qq|,| . $dbh->quote($form->{number}) if ($form->{number});
		$query .= qq|,| . $dbh->quote($form->{description}) . qq|,(SELECT id FROM chart WHERE accno = '$form->{cashaccount}'), '$form->{regcheck}', '$form->{vcurr}' )|;
		}
	$dbh->do($query) || $form->dberror($query);
	$query=qq|DELETE FROM regnum_cash WHERE chart_id=(SELECT id FROM chart WHERE accno = '$form->{cashaccount}')|;
	$dbh->do($query) || $form->dberror($query);
	$query=qq|INSERT INTO regnum_cash (chart_id, mincash, maxcash) VALUES 
	 ((SELECT id FROM chart WHERE accno = '$form->{cashaccount}'), |.$form->parse_amount($myconfig,$form->{mincash}).
	 qq|, |.$form->parse_amount($myconfig,$form->{maxcash}).qq|)|;
	$dbh->do($query) || $form->dberror($query);
	$dbh->disconnect;
	}


sub delete_regnum {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$query = qq|DELETE FROM regnum
		WHERE code = |.$dbh->quote($form->{code});
	$dbh->do($query) || $form->dberror($query);

	$dbh->disconnect;
	}


sub increment_regnum {
	my ($self, $myconfig, $form, $code) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$query = qq|UPDATE regnum
		SET number = number + 1
		WHERE code = |.$dbh->quote($code);
	$dbh->do($query) || $form->dberror($query);

	$dbh->disconnect;
	}



sub regnumber {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$form->{sort} = "description" unless $form->{sort};
	my @a = qw(description regnumber);
	my %ordinal = (
		description => 1,
		regnumber => 2
		);
	my $sortorder = $form->sort_order(\@a, \%ordinal);
	my $query = "SELECT description, code || regnumber AS regnumber, code, aparcheck
		FROM regnumber
		ORDER BY $sortorder";
	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{ALL} }, $ref;
		}

	$sth->finish;
	$dbh->disconnect;
	}


sub get_regnumber {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT *
		FROM regnumber
		WHERE code = |.$dbh->quote($form->{code});
	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
	map { $form->{$_} = $ref->{$_} } keys %$ref;

	$sth->finish;
	$dbh->disconnect;
	}


sub save_regnumber {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	foreach my $item (qw(code description)) {
		$form->{$item} =~ s/-(-)+/-/g;
		}

	# if there is an id
	if ($form->{id}) {
		$query = qq|UPDATE regnumber SET
			code = |.$dbh->quote($form->{code}).qq|,
			regnumber = |.$dbh->quote($form->{regnumber}).qq|,
			description = |.$dbh->quote($form->{description}).qq|,
			aparcheck = '$form->{aparcheck}'
			WHERE code = |.$dbh->quote($form->{id});
		}
	else {
		$query = qq|INSERT INTO regnumber
                (code|;
		$query .= qq|, regnumber| if ($form->{regnumber});
		$query .= qq|, description, aparcheck)
                VALUES (| . $dbh->quote($form->{code});
		$query .= qq|,| . $dbh->quote($form->{regnumber}) if ($form->{regnumber});
		$query .= qq|,| . $dbh->quote($form->{description}) . qq|, '$form->{aparcheck}')|;
		}

	$dbh->do($query) || $form->dberror($query);

	$dbh->disconnect;
	}


sub delete_regnumber {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$query = qq|DELETE FROM regnumber
		WHERE code = |.$dbh->quote($form->{code});
	$dbh->do($query) || $form->dberror($query);

	$dbh->disconnect;
	}


sub increment_regnumber {
	my ($self, $myconfig, $form, $code) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$query = qq|UPDATE regnumber
		SET regnumber = regnumber + 1
		WHERE code = |.$dbh->quote($code);
	$dbh->do($query) || $form->dberror($query);

	$dbh->disconnect;
	}



sub load_template {
  my ($self, $form) = @_;
  
  open(TEMPLATE, "$form->{file}") or $form->error("$form->{file} : $!");

  while (<TEMPLATE>) {
    $form->{body} .= $_;
  }

  close(TEMPLATE);

}


sub save_template {
  my ($self, $form) = @_;
  
  open(TEMPLATE, ">$form->{file}") or $form->error("$form->{file} : $!");
  
  # strip 
  $form->{body} =~ s/\r\n/\n/g;
  print TEMPLATE $form->{body};

  close(TEMPLATE);

}



sub save_preferences {
  my ($self, $myconfig, $form, $memberfile, $userspath) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  # update name
  my $query = qq|UPDATE employee
                 SET name = |.$dbh->quote($form->{name}).qq|,
	         role = '$form->{role}'
	         WHERE login = '$form->{login}'|;
  $dbh->do($query) || $form->dberror($query);
  
  # get default currency
  $query = qq|SELECT substr(curr,1,strpos(curr,':')-1), businessnumber
              FROM defaults|;
  ($form->{currency}, $form->{businessnumber}) = $dbh->selectrow_array($query);
  
  $dbh->disconnect;

  my $myconfig = new User "$memberfile", "$form->{login}";
  
  foreach my $item (keys %$form) {
    $myconfig->{$item} = $form->{$item};
  }
  
  $myconfig->{password} = $form->{new_password} if ($form->{old_password} ne $form->{new_password});

  $myconfig->save_member($memberfile, $userspath);

  1;

}


sub save_defaults {
  my ($self, $myconfig, $form) = @_;

#kabai +1
  map { ($form->{$_}) = split /--/, $form->{$_} } qw(inventory_accno income_accno expense_accno fxgain_accno fxloss_accno ar_accno ap_accno rincome_accno rcost_accno cash_accno);
  
  my @a;
  $form->{curr} =~ s/ //g;
  map { push(@a, uc pack "A3", $_) if $_ } split /:/, $form->{curr};
  $form->{curr} = join ':', @a;
#kabai
  $form->{promptshipreceive} = $form->{promptshipreceive} ? 1 : 0;
#kabai

    
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  # save defaults
#kabai +31
  my $query = qq|UPDATE defaults SET
                 inventory_accno_id = 
		     (SELECT id FROM chart
		                WHERE accno = '$form->{inventory_accno}'),
                 income_accno_id =
		     (SELECT id FROM chart
		                WHERE accno = '$form->{income_accno}'),
	         expense_accno_id =
		     (SELECT id FROM chart
		                WHERE accno = '$form->{expense_accno}'),
	         fxgain_accno_id =
		     (SELECT id FROM chart
		                WHERE accno = '$form->{fxgain_accno}'),
	         fxloss_accno_id =
		     (SELECT id FROM chart
		                WHERE accno = '$form->{fxloss_accno}'),
	         ar_accno_id =
		     (SELECT id FROM chart
		                WHERE accno = '$form->{ar_accno}'),
	         ap_accno_id =
		     (SELECT id FROM chart
		                WHERE accno = '$form->{ap_accno}'),
	         rincome_accno_id =
		     (SELECT id FROM chart
		                WHERE accno = '$form->{rincome_accno}'),
	         rcost_accno_id =
		     (SELECT id FROM chart
		                WHERE accno = '$form->{rcost_accno}'),
	         cash_accno_id =
		     (SELECT id FROM chart
		                WHERE accno = '$form->{cash_accno}'),
		 prefix = |.$dbh->quote($form->{prefix}).qq|,
		 suffix = |.$dbh->quote($form->{suffix}).qq|,
	         invnumber = '$form->{invnumber}',
	         invnumber_st = '$form->{invnumber_st}',
	         sonumber = '$form->{sonumber}',
	         ponumber = '$form->{ponumber}',
		 sqnumber = '$form->{sqnumber}',
		 rfqnumber = '$form->{rfqnumber}',
		 yearend = '$form->{yearend}',
		 curr = '$form->{curr}',
		 promptshipreceive = '$form->{promptshipreceive}',
		 weightunit = |.$dbh->quote($form->{weightunit}).qq|,
		 businessnumber = |.$dbh->quote($form->{businessnumber});
  $dbh->do($query) || $form->dberror($query);

  foreach my $item (split / /, $form->{taxaccounts}) {
    $form->{"base_$item"} = $form->{"base_$item"} ? 1 : 0;
    
    $query = qq|UPDATE tax
		SET rate = |.($form->{$item} / 100).qq|,
		taxnumber = |.$dbh->quote($form->{"taxnumber_$item"}).qq|,
		base = '$form->{"base_$item"}'
		WHERE chart_id = $item|;
    $dbh->do($query) || $form->dberror($query);
#kabai
    $query = qq|UPDATE chart
		SET 
		validfrom = '$form->{"validfrom_$item"}',
		validto = '$form->{"validto_$item"}'
		WHERE id = $item|;
    $dbh->do($query) || $form->dberror($query);
#kabai
  }

  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;
  
}


sub defaultaccounts {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  # get defaults from defaults table
  my $query = qq|SELECT * FROM defaults|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  $form->{defaults} = $sth->fetchrow_hashref(NAME_lc);
  $form->{defaults}{IC} = $form->{defaults}{inventory_accno_id};
  $form->{defaults}{IC_income} = $form->{defaults}{income_accno_id};
  $form->{defaults}{IC_expense} = $form->{defaults}{expense_accno_id};
  $form->{defaults}{FX_gain} = $form->{defaults}{fxgain_accno_id};
  $form->{defaults}{FX_loss} = $form->{defaults}{fxloss_accno_id};
#kabai
  $form->{defaults}{AR} = $form->{defaults}{ar_accno_id};
  $form->{defaults}{AP} = $form->{defaults}{ap_accno_id};
  $form->{defaults}{promptshipreceive} = $form->{defaults}{promptshipreceive};
  $form->{defaults}{AP} = $form->{defaults}{ap_accno_id};
  $form->{defaults}{Rounding_cost} = $form->{defaults}{rcost_accno_id};
  $form->{defaults}{Rounding_income} = $form->{defaults}{rincome_accno_id};
  $form->{defaults}{Cash} = $form->{defaults}{cash_accno_id};
#kabai
  $sth->finish;

#kabai

  $query = qq|SELECT id, accno, description, link
              FROM chart
              WHERE ptype = 'pcash'
              ORDER BY accno|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    %{ $form->{IC}{Cash}{$ref->{accno}} } = ( id => $ref->{id},
                                      description => $ref->{description} );
  }
  $sth->finish;
  
  $query = qq|SELECT id, accno, description, link
              FROM chart
              WHERE link LIKE 'AR'
              ORDER BY accno|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    %{ $form->{IC}{AR}{$ref->{accno}} } = ( id => $ref->{id},
                                      description => $ref->{description} );
  }
  $sth->finish;

  $query = qq|SELECT id, accno, description, link
              FROM chart
              WHERE link LIKE 'AP'
              ORDER BY accno|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    %{ $form->{IC}{AP}{$ref->{accno}} } = ( id => $ref->{id},
                                      description => $ref->{description} );
  }
  $sth->finish;

#kabai

  $query = qq|SELECT id, accno, description, link
              FROM chart
              WHERE link LIKE '%IC%'
              ORDER BY accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    foreach my $key (split(/:/, $ref->{link})) {
      if ($key =~ /IC/) {
	$nkey = $key;
	if ($key =~ /cogs/) {
	  $nkey = "IC_expense";
	}
	if ($key =~ /sale/) {
	  $nkey = "IC_income";
	}
        %{ $form->{IC}{$nkey}{$ref->{accno}} } = ( id => $ref->{id},
                                        description => $ref->{description} );
      }
    }
  }
  $sth->finish;


  $query = "SELECT id, accno, description
              FROM chart
	      WHERE category = 'I'
	      AND charttype = 'A'
	      AND link = ''
              ORDER BY accno";
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    %{ $form->{IC}{FX_gain}{$ref->{accno}} } = ( id => $ref->{id},
                                      description => $ref->{description} );
  }
  $sth->finish;

  $query = qq|SELECT id, accno, description
              FROM chart
	      WHERE category = 'E'
	      AND charttype = 'A'
	      AND link = ''
              ORDER BY accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    %{ $form->{IC}{FX_loss}{$ref->{accno}} } = ( id => $ref->{id},
                                      description => $ref->{description} );
  }
  $sth->finish;

  $query = "SELECT id, accno, description
              FROM chart
	      WHERE category = 'I'
	      AND charttype = 'A'
	      AND link SIMILAR TO '%(AR|AP)_paid%'
              ORDER BY accno";
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    %{ $form->{IC}{Rounding_income}{$ref->{accno}} } = ( id => $ref->{id},
                                      description => $ref->{description} );
  }
  $sth->finish;

  $query = "SELECT id, accno, description
              FROM chart
	      WHERE category = 'E'
	      AND charttype = 'A'
	      AND link SIMILAR TO '%(AR|AP)_paid%'
              ORDER BY accno";
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    %{ $form->{IC}{Rounding_cost}{$ref->{accno}} } = ( id => $ref->{id},
                                      description => $ref->{description} );
  }
  $sth->finish;

#kabai
  # now get the tax rates and numbers
  $query = qq|SELECT chart.id, chart.accno, chart.description,
              tax.rate * 100 AS rate, tax.taxnumber, chart.validfrom, chart.validto, tax.base
              FROM chart, tax
	      WHERE chart.id = tax.chart_id|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $form->{taxrates}{$ref->{accno}}{id} = $ref->{id};
    $form->{taxrates}{$ref->{accno}}{description} = $ref->{description};
    $form->{taxrates}{$ref->{accno}}{taxnumber} = $ref->{taxnumber} if $ref->{taxnumber};
    $form->{taxrates}{$ref->{accno}}{rate} = $ref->{rate} if $ref->{rate};
    $form->{taxrates}{$ref->{accno}}{validfrom} = $ref->{validfrom} if $ref->{validfrom};
    $form->{taxrates}{$ref->{accno}}{validto} = $ref->{validto} if $ref->{validto};
    $form->{taxrates}{$ref->{accno}}{base} = $ref->{base};
  }

  $sth->finish;
  $dbh->disconnect;
  
}

sub backup { #From 2.6.15
  my ($self, $myconfig, $form, $userspath, $gzip) = @_;
  
  my $mail;
  my $err;
  
  my @t = localtime(time);
  $t[4]++;
  $t[5] += 1900;
  $t[3] = substr("0$t[3]", -2);
  $t[4] = substr("0$t[4]", -2);

  my $boundary = time;
#kabai
  my $dbname = $myconfig->{dbname};
  $dbname =~ s|/|-|g;

  my $tmpfile = "$userspath/$boundary.$dbname-$form->{dbversion}-$t[5]$t[4]$t[3].sql";
#  my $tmpfile = "$userspath/$boundary.$myconfig->{dbname}-$form->{dbversion}-$t[5]$t[4]$t[3].sql";
#kabai

  my $out = $form->{OUT};
  $form->{OUT} = ">$tmpfile";

  open(OUT, "$form->{OUT}") or $form->error("$form->{OUT} : $!");

  # get sequences, functions and triggers
  my @tables = ();
  my @sequences = ();
  my @functions = ();
  my @triggers = ();
  my @schema = ();
  
  # get dbversion from -tables.sql
  my $file = "$myconfig->{dbdriver}-tables.sql";

  open(FH, "sql/$file") or $form->error("sql/$file : $!");

  my @a = <FH>;
  close(FH);

  @dbversion = grep /defaults \(version\)/, @a;
  
  $dbversion = "@dbversion";
  $dbversion =~ /(\d+\.\d+\.\d+)/;
  $dbversion = User::calc_version($1);
  
  opendir SQLDIR, "sql/." or $form->error($!);
  @a = grep /$myconfig->{dbdriver}-upgrade-.*?\.sql$/, readdir SQLDIR;
  closedir SQLDIR;

  my $mindb;
  my $maxdb;
  
  foreach my $line (@a) {

    $upgradescript = $line;
    $line =~ s/(^$myconfig->{dbdriver}-upgrade-|\.sql$)//g;
    
    ($mindb, $maxdb) = split /-/, $line;
    $mindb = User::calc_version($mindb);

    next if $mindb < $dbversion;
    
    $maxdb = User::calc_version($maxdb);
    
    $upgradescripts{$maxdb} = $upgradescript;
  }


  $upgradescripts{$dbversion} = "$myconfig->{dbdriver}-tables.sql";
  $upgradescripts{functions} = "$myconfig->{dbdriver}-functions.sql";

  if (-f "sql/$myconfig->{dbdriver}-custom_tables.sql") {
    $upgradescripts{customtables} = "$myconfig->{dbdriver}-custom_tables.sql";
  }
  if (-f "sql/$myconfig->{dbdriver}-custom_functions.sql") {
    $upgradescripts{customfunctions} = "$myconfig->{dbdriver}-custom_functions.sql";
  }
  
  foreach my $key (sort keys %upgradescripts) {

    $file = $upgradescripts{$key};
  
    open(FH, "sql/$file") or $form->error("sql/$file : $!");

    push @schema, qq|-- $file\n|;
   
    while (<FH>) {

      if (/create table (\w+)/i) {
	push @tables, $1;
      }

      if (/create sequence (\w+)/i) {
	push @sequences, $1;
	next;
      }

      if (/end function/i) {
	push @functions, $_;
	$function = 0;
	$temp = 0;
	next;
      }

      if (/create function /i) {
	$function = 1;
      }
      
      if ($function) {
	push @functions, $_;
	next;
      }

      if (/end trigger/i) {
	push @triggers, $_;
	$trigger = 0;
	next;
      }

      if (/create trigger/i) {
	$trigger = 1;
      }

      if ($trigger) {
	push @triggers, $_;
	next;
      }
      
      push @schema, $_ if $_ !~ /^(insert|--)/i;
      
    }
    close(FH);
    
  }


  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $today = scalar localtime;

  $myconfig->{dbhost} = 'localhost' unless $myconfig->{dbhost};
  
  print OUT qq|-- Ledger Backup
-- Dataset: $myconfig->{dbname}
-- Version: $form->{dbversion}
-- Host: $myconfig->{dbhost}
-- Login: $form->{login}
-- User: $myconfig->{name}
-- Date: $today
--
|;

 
  @tables = grep !/^temp/, @tables;
  # drop tables and sequences
  for (@tables) { print OUT qq|DROP TABLE $_;\n| }

  print OUT "--\n";
  
  # triggers and index files are dropped with the tables
  
  # drop functions
  foreach $item (@functions) {
    if ($item =~ /create function (.*\))/i) {
      print OUT qq|DROP FUNCTION $1;\n|;
    }
  }
  
  # create sequences
  foreach $item (@sequences) {
    if ($myconfig->{dbdriver} eq 'DB2') {
      $query = qq|SELECT NEXTVAL FOR $item FROM sysibm.sysdummy1|;
    } else {
      $query = qq|SELECT last_value FROM $item|;
    }
    
    my ($id) = $dbh->selectrow_array($query);
  
    if ($myconfig->{dbdriver} eq 'DB2') {
      print OUT qq|DROP SEQUENCE $item RESTRICT
CREATE SEQUENCE $item AS INTEGER START WITH $id INCREMENT BY 1 MAXVALUE 2147483647 MINVALUE 1 CACHE 5;\n|;
    } else {
      if ($myconfig->{dbdriver} eq 'Pg') {
	print OUT qq|CREATE SEQUENCE $item;
SELECT SETVAL('$item', $id, FALSE);\n|;
      } else {
	print OUT qq|DROP SEQUENCE $item
CREATE SEQUENCE $item START $id;\n|;
      }
    }
  }
 
  print OUT "--\n";

  # add schema
  print OUT @schema;
  print OUT "\n";
  
  print OUT qq|-- set options
$myconfig->{dboptions};
--
|;

  my $query;
  my $sth;
  my @arr;
  my $fields;
  
  foreach $table (@tables) {

    $query = qq|SELECT * FROM $table|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $query = qq|INSERT INTO $table (|;
    $query .= join ',', (map { $sth->{NAME}->[$_] } (0 .. $sth->{NUM_OF_FIELDS} - 1));
    $query .= qq|) VALUES|;
    
    while (@arr = $sth->fetchrow_array) {

      $fields = "(";
      
      $fields .= join ',', map { $dbh->quote($_) } @arr;
      $fields .= ")";
	
      print OUT qq|$query $fields;\n|;
    }
    
    $sth->finish;
  }

  print OUT "--\n";
  
  # functions
  for (@functions) { print OUT $_ }

  # triggers
  for (@triggers) { print OUT $_ }

  # add the index files
  open(FH, "sql/$myconfig->{dbdriver}-indices.sql");
  @a = <FH>;
  close(FH);
  print OUT @a;
  
  close(OUT);
  
  $dbh->disconnect;

  # compress backup if gzip defined
  my $suffix = "";
  if ($gzip) {
    my @args = split / /, $gzip;
    my @s = @args;
    
    push @args, "$tmpfile";
    system(@args) == 0 or $form->error("$args[0] : $?");
    
    shift @s;
    my %s = @s;
    $suffix = ${-S} || ".gz";
    $tmpfile .= $suffix;
  }
  
  if ($form->{media} eq 'email') {
   
    use SL::Mailer;
    $mail = new Mailer;

    $mail->{to} = qq|"$myconfig->{name}" <$myconfig->{email}>|;
    $mail->{from} = qq|"$myconfig->{name}" <$myconfig->{email}>|;
#kabai
    if ($form->{windows}){
     $mail->{to} = qq|$myconfig->{email}|;
     $mail->{from} = qq|$myconfig->{email}|;
	$mail->{windows} = $form->{windows};
	$mail->{smtpserver} = $form->{smtpserver};

	$tmpfile =~ s/\Q$form->{userspath}\E\///g;

     use Cwd;
     $form->{cwd} = cwd();
     $mail->{tmpdir} = $form->{cwd}."\\".$form->{userspath};
     $mail->{tmpdir} =~ s/\//\\/g;
    }
#kabai    
    $mail->{subject} = "Ledger Backup / $myconfig->{dbname}-$form->{dbversion}-$t[5]$t[4]$t[3].sql$suffix";
    @{ $mail->{attachments} } = ($tmpfile);
    $mail->{version} = $form->{version};
    $mail->{fileid} = "$boundary.";

    $myconfig->{signature} =~ s/\\n/\n/g;
    $mail->{message} = "-- \n$myconfig->{signature}";
    
    $err = $mail->send($out);
  }
  
  if ($form->{media} eq 'file') {
   
    open(IN, "$tmpfile") or $form->error("$tmpfile : $!");
    open(OUT, ">-") or $form->error("STDOUT : $!");
   
    print OUT qq|Content-Type: application/file;
Content-Disposition: attachment; filename="$myconfig->{dbname}-$form->{dbversion}-$t[5]$t[4]$t[3].sql$suffix"

|;
    binmode(IN);
    binmode(OUT);
    
    while (<IN>) {
      print OUT $_;
    }

    close(IN);
    close(OUT);
    
  }

  unlink "$tmpfile";
   
}


sub closedto {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT closedto, revtrans, audittrail, taxreturn
                 FROM defaults|;
  ($form->{closedto}, $form->{revtrans}, $form->{audittrail}, $form->{taxreturn}) = $dbh->selectrow_array($query);
  
  $dbh->disconnect;

}

 
sub closebooks {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect_noauto($myconfig);

  if ($form->{revtrans}) {
    
    $query = qq|UPDATE defaults SET closedto = NULL,
				    revtrans = '1'|;
  } else {

    if ($form->{closedto}) {
      
      $query = qq|UPDATE defaults SET closedto = '$form->{closedto}',
				      revtrans = '0'|;
    } else {
      
      $query = qq|UPDATE defaults SET closedto = NULL,
				      revtrans = '0'|;
    }
  }

  if ($form->{audittrail}) {
    $query .= qq|, audittrail = '1'|;
  } else {
    $query .= qq|, audittrail = '0'|;
  }

  # set close in defaults
  $dbh->do($query) || $form->dberror($query);

  if ($form->{taxreturn}) {
    $query = qq|UPDATE defaults SET taxreturn = '$form->{taxreturn}'|;
  }else {
    $query = qq|UPDATE defaults SET taxreturn = null|;
  }
    $dbh->do($query) || $form->dberror($query);
  
  if ($form->{removeaudittrail}) {
    $query = qq|DELETE FROM audittrail
                WHERE transdate < '$form->{removeaudittrail}'|;
    $dbh->do($query) || $form->dberror($query);
  }
		
  
  $dbh->commit;
  $dbh->disconnect;
  
}


sub earningsaccounts {
  my ($self, $myconfig, $form) = @_;

  my ($query, $sth, $ref);

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  # get chart of accounts
  $query = qq|SELECT accno,description
              FROM chart
              WHERE charttype = 'A'
	      AND category = 'Q'
              ORDER by accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  $form->{chart} = "";
						  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{chart} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;
	      
}


sub post_yearend {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database, turn off AutoCommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $uid = time;
  $uid .= $form->{login};

  $query = qq|INSERT INTO gl (reference, employee_id)
	      VALUES ('$uid', (SELECT id FROM employee
			       WHERE login = '$form->{login}'))|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|SELECT id FROM gl
	      WHERE reference = '$uid'|;
  ($form->{id}) = $dbh->selectrow_array($query);

  $query = qq|UPDATE gl SET 
	      reference = |.$dbh->quote($form->{reference}).qq|,
	      description = |.$dbh->quote($form->{description}).qq|,
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      transdate = '$form->{transdate}',
	      department_id = 0
	      WHERE id = $form->{id}|;

  $dbh->do($query) || $form->dberror($query);

  # insert acc_trans transactions
  for my $i (1 .. $form->{rowcount}) {
    # extract accno
    ($accno) = split(/--/, $form->{"accno_$i"});
    my $amount = 0;

    if ($form->{"credit_$i"} != 0) {
      $amount = $form->{"credit_$i"};
    }
    if ($form->{"debit_$i"} != 0) {
      $amount = $form->{"debit_$i"} * -1;
    }


    # if there is an amount, add the record
    if ($amount != 0) {
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
                  source)
		  VALUES
		  ($form->{id}, (SELECT id
		                 FROM chart
				 WHERE accno = '$accno'),
		   $amount, '$form->{transdate}', |
		   .$dbh->quote($form->{reference}).qq|)|;
  
      $dbh->do($query) || $form->dberror($query);
    }
  }

  $query = qq|INSERT INTO yearend (trans_id, transdate)
              VALUES ($form->{id}, '$form->{transdate}')|;
  $dbh->do($query) || $form->dberror($query);

  my %audittrail = ( tablename	=> 'gl',
                     reference	=> $form->{reference},
	  	     formname	=> 'yearend',
		     action	=> 'posted',
		     id		=> $form->{id} );
  $form->audittrail($dbh, "", \%audittrail);
  
  # commit and redirect
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $rc;

}

sub get_basecurr {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT  curr
                 FROM defaults|;

  ($form->{currencies}) = $dbh->selectrow_array($query);
 
  $dbh->disconnect;

}

sub get_curr {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $query = qq| SELECT curr, transdate, buy,sell,sell_paid,buy_paid FROM exchangerate WHERE curr = '$form->{currency}'
	      AND transdate = '$form->{transdate}'|;

  ($form->{currency0}, $form->{transdate0}, $form->{buy}, $form->{sell}, $form->{sell_paid}, $form->{buy_paid}) = $dbh->selectrow_array($query);

  $query = qq|
  --buy
  SELECT id FROM ar WHERE transdate='$form->{transdate}' AND curr='$form->{currency}'
  UNION
  SELECT id FROM oe WHERE transdate='$form->{transdate}' AND curr='$form->{currency}'
  AND vendor_id = 0 LIMIT 1;
  |;
  ($form->{buy_noedit}) = $dbh->selectrow_array($query);

  $query = qq|
  --sell
  SELECT id FROM ap WHERE transdate='$form->{transdate}' AND curr='$form->{currency}'
  UNION
  SELECT id FROM oe WHERE transdate='$form->{transdate}' AND curr='$form->{currency}'
  AND customer_id = 0 LIMIT 1;
  |;
  ($form->{sell_noedit}) = $dbh->selectrow_array($query);
  
  $query = qq|
  --buy_paid
  SELECT ar.id FROM acc_trans a
  JOIN ar ON (ar.id = a.trans_id)
  JOIN chart c ON (c.id=a.chart_id)
  WHERE a.transdate = '$form->{transdate}'
  AND ar.curr='$form->{currency}'
  AND c.link LIKE '%_paid%'
  LIMIT 1;
  |;
  ($form->{buy_paid_noedit}) = $dbh->selectrow_array($query);
  
  $query = qq|
  --sell_paid
  SELECT ap.id FROM acc_trans a
  JOIN ap ON (ap.id = a.trans_id)
  JOIN chart c ON (c.id=a.chart_id)
  WHERE a.transdate = '$form->{transdate}'
  AND ap.curr='$form->{currency}'
  AND c.link LIKE '%_paid%'
  LIMIT 1;   
  |;
  ($form->{sell_paid_noedit}) = $dbh->selectrow_array($query);

   $dbh->disconnect;

}
sub save_curr { #kabai
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);
  my $query;
  if ($form->{currency0} && $form->{transdate0}){
    $query = qq|UPDATE exchangerate SET
                buy = $form->{buy},
		sell = $form->{sell},
		buy_paid = $form->{buy_paid},
		sell_paid = $form->{sell_paid}
		WHERE curr = '$form->{currency}'
		AND transdate = '$form->{transdate}'
		|;
   }else{
     $query = qq|INSERT INTO exchangerate(curr, transdate, buy, sell, buy_paid, sell_paid) 
		 VALUES('$form->{currency}','$form->{transdate}', $form->{buy}, $form->{sell}, $form->{buy_paid}, $form->{sell_paid})
		|;
   }
  $dbh->do($query) || $form->dberror($query);
  $dbh->disconnect;
}  

sub get_cashlimit{
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT chart_id, mincash, maxcash FROM regnum_cash WHERE chart_id = 
	(SELECT id FROM chart WHERE accno='$form->{cashaccount}')|;
	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
	map { $form->{$_} = $ref->{$_} } keys %$ref;

	$sth->finish;
	$dbh->disconnect;

}

sub get_sumcash{
	my ($self, $myconfig, $form, $datepaid) = @_;
	# connect to database
	my $dbh = $form->dbconnect($myconfig);
	$datepaid = $datepaid ? $datepaid : $form->{transdate};
	my $query = qq|SELECT -SUM(amount) AS sumamount FROM acc_trans WHERE chart_id = 
	(SELECT id FROM chart WHERE accno='$form->{cashaccount}') AND transdate <= '$datepaid'|;
	$query .=qq| AND	trans_id <>'$form->{id}'| if $form->{id};
	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
	$form->{sumamount} = $ref->{sumamount};
	$sth->finish;
	$dbh->disconnect;
}

1;



