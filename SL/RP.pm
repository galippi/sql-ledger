#=====================================================================
# SQL-Ledger Accounting
# Copyright (C) 2001
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#
#  Contributors: Benjamin Lee <benjaminlee@consultant.com>
#                Jim Rawlings <jim@your-dba.com>
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
# backend code for reports
#
#======================================================================

package RP;


sub yearend_statement {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  # if todate < existing yearends, delete GL and yearends
  my $query = qq|SELECT trans_id FROM yearend
                 WHERE transdate >= '$form->{todate}'|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  my @trans_id = ();
  my $id;
  while (($id) = $sth->fetchrow_array) {
    push @trans_id, $id;
  }
  $sth->finish;

  $query = qq|DELETE FROM gl
              WHERE id = ?|;
  $sth = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|DELETE FROM acc_trans
              WHERE trans_id = ?|;
  my $ath = $dbh->prepare($query) || $form->dberror($query);
	      
  foreach $id (@trans_id) {
    $sth->execute($id);
    $ath->execute($id);
  }
  $sth->finish;
  
  
  my $last_period = 0;
  my @categories = qw(I E);
  my $category;

  $form->{decimalplaces} *= 1;

  &get_accounts($dbh, 0, $form->{fromdate}, $form->{todate}, $form, \@categories);
  
  # disconnect
  $dbh->disconnect;


  # now we got $form->{I}{accno}{ }
  # and $form->{E}{accno}{  }
  
  my %account = ( 'I' => { 'label' => 'income',
                           'labels' => 'income',
			   'ml' => 1 },
		  'E' => { 'label' => 'expense',
		           'labels' => 'expenses',
			   'ml' => -1 }
		);
  
  foreach $category (@categories) {
    foreach $key (sort keys %{ $form->{$category} }) {
      if ($form->{$category}{$key}{charttype} eq 'A') {
	$form->{"total_$account{$category}{labels}_this_period"} += $form->{$category}{$key}{this} * $account{$category}{ml};
      }
    }
  }


  # totals for income and expenses
  $form->{total_income_this_period} = $form->round_amount($form->{total_income_this_period}, $form->{decimalplaces});
  $form->{total_expenses_this_period} = $form->round_amount($form->{total_expenses_this_period}, $form->{decimalplaces});

  # total for income/loss
  $form->{total_this_period} = $form->{total_income_this_period} - $form->{total_expenses_this_period};
  
}


sub income_statement {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $last_period = 0;
  my @categories = qw(I E);
  my $category;

  $form->{decimalplaces} *= 1;

  if (! ($form->{fromdate} || $form->{todate})) {
    if ($form->{fromyear} && $form->{frommonth}) {
      ($form->{fromdate}, $form->{todate}) = $form->from_to($form->{fromyear}, $form->{frommonth}, $form->{interval});
    }
  }
  
  &get_accounts($dbh, $last_period, $form->{fromdate}, $form->{todate}, $form, \@categories, 1);
  
  if (! ($form->{comparefromdate} || $form->{comparetodate})) {
    if ($form->{compareyear} && $form->{comparemonth}) {
      ($form->{comparefromdate}, $form->{comparetodate}) = $form->from_to($form->{compareyear}, $form->{comparemonth}, $form->{interval});
    }
  }

  # if there are any compare dates
  if ($form->{comparefromdate} || $form->{comparetodate}) {
    $last_period = 1;

    &get_accounts($dbh, $last_period, $form->{comparefromdate}, $form->{comparetodate}, $form, \@categories, 1);
  }  

  
  # disconnect
  $dbh->disconnect;


  # now we got $form->{I}{accno}{ }
  # and $form->{E}{accno}{  }
  
  my %account = ( 'I' => { 'label' => 'income',
                           'labels' => 'income',
			   'ml' => 1 },
		  'E' => { 'label' => 'expense',
		           'labels' => 'expenses',
			   'ml' => -1 }
		);
  
  my $str;
  
  foreach $category (@categories) {
    
    foreach $key (sort keys %{ $form->{$category} }) {
      # push description onto array
      
      $str = ($form->{l_heading}) ? $form->{padding} : "";
      
      if ($form->{$category}{$key}{charttype} eq "A") {
	$str .= ($form->{l_accno}) ? "$form->{$category}{$key}{accno} - $form->{$category}{$key}{description}" : "$form->{$category}{$key}{description}";
      }
      if ($form->{$category}{$key}{charttype} eq "H") {
	if ($account{$category}{subtotal} && $form->{l_subtotal}) {
	  $dash = "- ";
	  push(@{$form->{"$account{$category}{label}_account"}}, "$str$form->{bold}$account{$category}{subdescription}$form->{endbold}");
	  push(@{$form->{"$account{$category}{labels}_this_period"}}, $form->format_amount($myconfig, $account{$category}{subthis} * $account{$category}{ml}, $form->{decimalplaces}, $dash));
	  
	  if ($last_period) {
	    push(@{$form->{"$account{$category}{labels}_last_period"}}, $form->format_amount($myconfig, $account{$category}{sublast} * $account{$category}{ml}, $form->{decimalplaces}, $dash));
	  }
	  
	}
	
	$str = "$form->{br}$form->{bold}$form->{$category}{$key}{description}$form->{endbold}";

	$account{$category}{subthis} = $form->{$category}{$key}{this};
	$account{$category}{sublast} = $form->{$category}{$key}{last};
	$account{$category}{subdescription} = $form->{$category}{$key}{description};
	$account{$category}{subtotal} = 1;

	$form->{$category}{$key}{this} = 0;
	$form->{$category}{$key}{last} = 0;

	next unless $form->{l_heading};

	$dash = " ";
      }
      
      push(@{$form->{"$account{$category}{label}_account"}}, $str);
      
      if ($form->{$category}{$key}{charttype} eq 'A') {
	$form->{"total_$account{$category}{labels}_this_period"} += $form->{$category}{$key}{this} * $account{$category}{ml};
	$dash = "- ";
      }
      
      push(@{$form->{"$account{$category}{labels}_this_period"}}, $form->format_amount($myconfig, $form->{$category}{$key}{this} * $account{$category}{ml}, $form->{decimalplaces}, $dash));
      
      # add amount or - for last period
      if ($last_period) {
	$form->{"total_$account{$category}{labels}_last_period"} += $form->{$category}{$key}{last} * $account{$category}{ml};

	push(@{$form->{"$account{$category}{labels}_last_period"}}, $form->format_amount($myconfig,$form->{$category}{$key}{last} * $account{$category}{ml}, $form->{decimalplaces}, $dash));
      }
    }

    $str = ($form->{l_heading}) ? $form->{padding} : "";
    if ($account{$category}{subtotal} && $form->{l_subtotal}) {
      push(@{$form->{"$account{$category}{label}_account"}}, "$str$form->{bold}$account{$category}{subdescription}$form->{endbold}");
      push(@{$form->{"$account{$category}{labels}_this_period"}}, $form->format_amount($myconfig, $account{$category}{subthis} * $account{$category}{ml}, $form->{decimalplaces}, $dash));

      if ($last_period) {
	push(@{$form->{"$account{$category}{labels}_last_period"}}, $form->format_amount($myconfig, $account{$category}{sublast} * $account{$category}{ml}, $form->{decimalplaces}, $dash));
      }
    }
      
  }


  # totals for income and expenses
  $form->{total_income_this_period} = $form->round_amount($form->{total_income_this_period}, $form->{decimalplaces});
  $form->{total_expenses_this_period} = $form->round_amount($form->{total_expenses_this_period}, $form->{decimalplaces});

  # total for income/loss
  $form->{total_this_period} = $form->{total_income_this_period} - $form->{total_expenses_this_period};
  
  if ($last_period) {
    # total for income/loss
    $form->{total_last_period} = $form->format_amount($myconfig, $form->{total_income_last_period} - $form->{total_expenses_last_period}, $form->{decimalplaces}, "- ");
    
    # totals for income and expenses for last_period
    $form->{total_income_last_period} = $form->format_amount($myconfig, $form->{total_income_last_period}, $form->{decimalplaces}, "- ");
    $form->{total_expenses_last_period} = $form->format_amount($myconfig, $form->{total_expenses_last_period}, $form->{decimalplaces}, "- ");

  }


  $form->{total_income_this_period} = $form->format_amount($myconfig,$form->{total_income_this_period}, $form->{decimalplaces}, "- ");
  $form->{total_expenses_this_period} = $form->format_amount($myconfig,$form->{total_expenses_this_period}, $form->{decimalplaces}, "- ");
  $form->{total_this_period} = $form->format_amount($myconfig,$form->{total_this_period}, $form->{decimalplaces}, "- ");

}


sub balance_sheet {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $last_period = 0;
  my @categories = qw(A C L Q);

  my $null;
  
  if (! $form->{asofdate}) {
    if ($form->{asofyear} && $form->{asofmonth}) {
      ($null, $form->{asofdate}) = $form->from_to($form->{asofyear}, $form->{asofmonth});
    }
  }
  
  # if there are any dates construct a where
  if ($form->{asofdate}) {
    
    $form->{this_period} = "$form->{asofdate}";
    $form->{period} = "$form->{asofdate}";
    
  }

  $form->{decimalplaces} *= 1;

  &get_accounts($dbh, $last_period, "", $form->{asofdate}, $form, \@categories, 1);
  
  if (! $form->{compareasofdate}) {
    if ($form->{compareasofyear} && $form->{compareasofmonth}) {
      ($null, $form->{compareasofdate}) = $form->from_to($form->{compareasofyear}, $form->{compareasofmonth});
    }
  }
  
  # if there are any compare dates
  if ($form->{compareasofdate}) {

    $last_period = 1;
    &get_accounts($dbh, $last_period, "", $form->{compareasofdate}, $form, \@categories, 1);
  
    $form->{last_period} = "$form->{compareasofdate}";

  }  

  
  # disconnect
  $dbh->disconnect;


  # now we got $form->{A}{accno}{ }    assets
  # and $form->{L}{accno}{ }           liabilities
  # and $form->{Q}{accno}{ }           equity
  # build asset accounts
  
  my $str;
  my $key;
  
  my %account  = ( 'A' => { 'label' => 'asset',
                            'labels' => 'assets',
			    'ml' => -1 },
		   'L' => { 'label' => 'liability',
		            'labels' => 'liabilities',
			    'ml' => 1 },
		   'Q' => { 'label' => 'equity',
		            'labels' => 'equity',
			    'ml' => 1 }
		);	    
			    
  foreach $category (grep { !/C/ } @categories) {

    foreach $key (sort keys %{ $form->{$category} }) {

      $str = ($form->{l_heading}) ? $form->{padding} : "";

      if ($form->{$category}{$key}{charttype} eq "A") {
	$str .= ($form->{l_accno}) ? "$form->{$category}{$key}{accno} - $form->{$category}{$key}{description}" : "$form->{$category}{$key}{description}";
      }
      if ($form->{$category}{$key}{charttype} eq "H") {
	if ($account{$category}{subtotal} && $form->{l_subtotal}) {
	  $dash = "- ";
	  push(@{$form->{"$account{$category}{label}_account"}}, "$str$form->{bold}$account{$category}{subdescription}$form->{endbold}");
	  push(@{$form->{"$account{$category}{label}_this_period"}}, $form->format_amount($myconfig, $account{$category}{subthis} * $account{$category}{ml}, $form->{decimalplaces}, $dash));
	  
	  if ($last_period) {
	    push(@{$form->{"$account{$category}{label}_last_period"}}, $form->format_amount($myconfig, $account{$category}{sublast} * $account{$category}{ml}, $form->{decimalplaces}, $dash));
	  }
	}

	$str = "$form->{bold}$form->{$category}{$key}{description}$form->{endbold}";
	
	$account{$category}{subthis} = $form->{$category}{$key}{this};
	$account{$category}{sublast} = $form->{$category}{$key}{last};
	$account{$category}{subdescription} = $form->{$category}{$key}{description};
	$account{$category}{subtotal} = 1;
	
	$form->{$category}{$key}{this} = 0;
	$form->{$category}{$key}{last} = 0;

	next unless $form->{l_heading};

	$dash = " ";
      }
      
      # push description onto array
      push(@{$form->{"$account{$category}{label}_account"}}, $str);
      
      if ($form->{$category}{$key}{charttype} eq 'A') {
	$form->{"total_$account{$category}{labels}_this_period"} += $form->{$category}{$key}{this} * $account{$category}{ml};
	$dash = "- ";
      }

      push(@{$form->{"$account{$category}{label}_this_period"}}, $form->format_amount($myconfig, $form->{$category}{$key}{this} * $account{$category}{ml}, $form->{decimalplaces}, $dash));
      
      if ($last_period) {
	$form->{"total_$account{$category}{labels}_last_period"} += $form->{$category}{$key}{last} * $account{$category}{ml};

	push(@{$form->{"$account{$category}{label}_last_period"}}, $form->format_amount($myconfig, $form->{$category}{$key}{last} * $account{$category}{ml}, $form->{decimalplaces}, $dash));
      }
    }

    $str = ($form->{l_heading}) ? $form->{padding} : "";
    if ($account{$category}{subtotal} && $form->{l_subtotal}) {
      push(@{$form->{"$account{$category}{label}_account"}}, "$str$form->{bold}$account{$category}{subdescription}$form->{endbold}");
      push(@{$form->{"$account{$category}{label}_this_period"}}, $form->format_amount($myconfig, $account{$category}{subthis} * $account{$category}{ml}, $form->{decimalplaces}, $dash));
      
      if ($last_period) {
	push(@{$form->{"$account{$category}{label}_last_period"}}, $form->format_amount($myconfig, $account{$category}{sublast} * $account{$category}{ml}, $form->{decimalplaces}, $dash));
      }
    }

  }

  
  # totals for assets, liabilities
  $form->{total_assets_this_period} = $form->round_amount($form->{total_assets_this_period}, $form->{decimalplaces});
  $form->{total_liabilities_this_period} = $form->round_amount($form->{total_liabilities_this_period}, $form->{decimalplaces});
  $form->{total_equity_this_period} = $form->round_amount($form->{total_equity_this_period}, $form->{decimalplaces});

  # calculate earnings
  $form->{earnings_this_period} = $form->{total_assets_this_period} - $form->{total_liabilities_this_period} - $form->{total_equity_this_period};

  push(@{$form->{equity_this_period}}, $form->format_amount($myconfig, $form->{earnings_this_period}, $form->{decimalplaces}, "- "));
  
  $form->{total_equity_this_period} = $form->round_amount($form->{total_equity_this_period} + $form->{earnings_this_period}, $form->{decimalplaces});
  
  # add liability + equity
  $form->{total_this_period} = $form->format_amount($myconfig, $form->{total_liabilities_this_period} + $form->{total_equity_this_period}, $form->{decimalplaces}, "- ");


  if ($last_period) {
    # totals for assets, liabilities
    $form->{total_assets_last_period} = $form->round_amount($form->{total_assets_last_period}, $form->{decimalplaces});
    $form->{total_liabilities_last_period} = $form->round_amount($form->{total_liabilities_last_period}, $form->{decimalplaces});
    $form->{total_equity_last_period} = $form->round_amount($form->{total_equity_last_period}, $form->{decimalplaces});

    # calculate retained earnings
    $form->{earnings_last_period} = $form->{total_assets_last_period} - $form->{total_liabilities_last_period} - $form->{total_equity_last_period};

    push(@{$form->{equity_last_period}}, $form->format_amount($myconfig,$form->{earnings_last_period}, $form->{decimalplaces}, "- "));
    
    $form->{total_equity_last_period} = $form->round_amount($form->{total_equity_last_period} + $form->{earnings_last_period}, $form->{decimalplaces});

    # add liability + equity
    $form->{total_last_period} = $form->format_amount($myconfig, $form->{total_liabilities_last_period} + $form->{total_equity_last_period}, $form->{decimalplaces}, "- ");

  }

  
  $form->{total_liabilities_last_period} = $form->format_amount($myconfig, $form->{total_liabilities_last_period}, $form->{decimalplaces}, "- ") if ($form->{total_liabilities_last_period} != 0);
  
  $form->{total_equity_last_period} = $form->format_amount($myconfig, $form->{total_equity_last_period}, $form->{decimalplaces}, "- ") if ($form->{total_equity_last_period} != 0);
  
  $form->{total_assets_last_period} = $form->format_amount($myconfig, $form->{total_assets_last_period}, $form->{decimalplaces}, "- ") if ($form->{total_assets_last_period} != 0);
  
  $form->{total_assets_this_period} = $form->format_amount($myconfig, $form->{total_assets_this_period}, $form->{decimalplaces}, "- ");
  
  $form->{total_liabilities_this_period} = $form->format_amount($myconfig, $form->{total_liabilities_this_period}, $form->{decimalplaces}, "- ");
  
  $form->{total_equity_this_period} = $form->format_amount($myconfig, $form->{total_equity_this_period}, $form->{decimalplaces}, "- ");

}


sub get_accounts {
  my ($dbh, $last_period, $fromdate, $todate, $form, $categories, $yearend) = @_;

  my $department_id;
  my $project_id;
  
  ($null, $department_id) = split /--/, $form->{department};
  ($null, $project_id) = split /--/, $form->{projectnumber};
  
  my $query;
  my $dpt_where;
  my $dpt_join;
  my $project;
  my $where = "1 = 1";
  my $glwhere = "";
  my $subwhere = "";
  my $yearendwhere = "1 = 1";
  my $item;
 
  my $category = "AND (";
  foreach $item (@{ $categories }) {
    $category .= qq|c.category = '$item' OR |;
  }
  $category =~ s/OR $/\)/;


  # get headings
  $query = qq|SELECT accno, description, category
	      FROM chart c
	      WHERE c.charttype = 'H'
	      $category
	      ORDER by c.accno|;

  if ($form->{accounttype} eq 'gifi')
  {
    $query = qq|SELECT g.accno, g.description, c.category
		FROM gifi g
		JOIN chart c ON (c.gifi_accno = g.accno)
		WHERE c.charttype = 'H'
		$category
		ORDER BY g.accno|;
  }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  my @headingaccounts = ();
  while ($ref = $sth->fetchrow_hashref(NAME_lc))
  {
    $form->{$ref->{category}}{$ref->{accno}}{description} = "$ref->{description}";
    $form->{$ref->{category}}{$ref->{accno}}{charttype} = "H";
    $form->{$ref->{category}}{$ref->{accno}}{accno} = $ref->{accno};
    
    push @headingaccounts, $ref->{accno};
  }

  $sth->finish;


  if ($fromdate) {
    $where .= " AND ac.transdate >= '$fromdate'";
    if ($form->{method} eq 'cash') {
      $subwhere .= " AND transdate >= '$fromdate'";
      $glwhere = " AND ac.transdate >= '$fromdate'";
    }
  }

  if ($todate) {
    $where .= " AND ac.transdate <= '$todate'";
    $subwhere .= " AND transdate <= '$todate'";
    $yearendwhere = "ac.transdate < '$todate'";
  }

  if ($yearend) {
    $ywhere = " AND ac.trans_id NOT IN
               (SELECT trans_id FROM yearend)";
	       
    if ($fromdate) {
      $ywhere = " AND ac.trans_id NOT IN
		 (SELECT trans_id FROM yearend
		  WHERE transdate >= '$fromdate')";
      if ($todate) {
	$ywhere = " AND ac.trans_id NOT IN
		   (SELECT trans_id FROM yearend
		    WHERE transdate >= '$fromdate'
		    AND transdate <= '$todate')";
      }
    }

    if ($todate) {
      $ywhere = " AND ac.trans_id NOT IN
		 (SELECT trans_id FROM yearend
		  WHERE transdate <= '$todate')";
    }
  }

  if ($department_id)
  {
    $dpt_join = qq|
               JOIN department t ON (a.department_id = t.id)
		  |;
    $dpt_where = qq|
               AND t.id = $department_id
	           |;
  }

  if ($project_id)
  {
    $project = qq|
                 AND ac.project_id = $project_id
		 |;
  }


  if ($form->{accounttype} eq 'gifi')
  {
    
    if ($form->{method} eq 'cash')
    {

	$query = qq|
	
	         SELECT g.accno, sum(ac.amount) AS amount,
		 g.description, c.category
		 FROM acc_trans ac
	         JOIN chart c ON (c.id = ac.chart_id)
	         JOIN ar a ON (a.id = ac.trans_id)
	         JOIN gifi g ON (g.accno = c.gifi_accno)
	         $dpt_join
		 WHERE $where
		 $ywhere
		 $dpt_where
		 $category
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%AR_paid%'
		     $subwhere
		   )
		 $project
		 GROUP BY g.accno, g.description, c.category
		 
       UNION ALL
       
		 SELECT '' AS accno, SUM(ac.amount) AS amount,
		 '' AS description, c.category
		 FROM acc_trans ac
	         JOIN chart c ON (c.id = ac.chart_id)
	         JOIN ar a ON (a.id = ac.trans_id)
	         $dpt_join
		 WHERE $where
		 $ywhere
		 $dpt_where
		 $category
		 AND c.gifi_accno = ''
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%AR_paid%'
		     $subwhere
		   )
		 $project
		 GROUP BY c.category

       UNION ALL

       	         SELECT g.accno, sum(ac.amount) AS amount,
		 g.description, c.category
		 FROM acc_trans ac
	         JOIN chart c ON (c.id = ac.chart_id)
	         JOIN ap a ON (a.id = ac.trans_id)
	         JOIN gifi g ON (g.accno = c.gifi_accno)
	         $dpt_join
		 WHERE $where
		 $ywhere
		 $dpt_where
		 $category
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%AP_paid%'
		     $subwhere
		   )
		 $project
		 GROUP BY g.accno, g.description, c.category
		 
       UNION ALL
       
		 SELECT '' AS accno, SUM(ac.amount) AS amount,
		 '' AS description, c.category
		 FROM acc_trans ac
	         JOIN chart c ON (c.id = ac.chart_id)
	         JOIN ap a ON (a.id = ac.trans_id)
	         $dpt_join
		 WHERE $where
		 $ywhere
		 $dpt_where
		 $category
		 AND c.gifi_accno = ''
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%AP_paid%'
		     $subwhere
		   )
		 $project
		 GROUP BY c.category

       UNION ALL

-- add gl
	
	         SELECT g.accno, sum(ac.amount) AS amount,
		 g.description, c.category
		 FROM acc_trans ac
	         JOIN chart c ON (c.id = ac.chart_id)
	         JOIN gifi g ON (g.accno = c.gifi_accno)
	         JOIN gl a ON (a.id = ac.trans_id)
	         $dpt_join
		 WHERE $where
		 $ywhere
		 $glwhere
		 $dpt_where
		 $category
		 AND NOT (c.link = 'AR' OR c.link = 'AP')
		 $project
		 GROUP BY g.accno, g.description, c.category
		 
       UNION ALL
       
		 SELECT '' AS accno, SUM(ac.amount) AS amount,
		 '' AS description, c.category
		 FROM acc_trans ac
	         JOIN chart c ON (c.id = ac.chart_id)
	         JOIN gl a ON (a.id = ac.trans_id)
	         $dpt_join
		 WHERE $where
		 $ywhere
		 $glwhere
		 $dpt_where
		 $category
		 AND c.gifi_accno = ''
		 AND NOT (c.link = 'AR' OR c.link = 'AP')
		 $project
		 GROUP BY c.category
		 |;

      if ($yearend) {

         # this is for the yearend

	 $query .= qq|

       UNION ALL
       
	         SELECT g.accno, sum(ac.amount) AS amount,
		 g.description, c.category
		 FROM yearend y
		 JOIN acc_trans ac ON (ac.trans_id = y.trans_id)
		 JOIN chart c ON (c.id = ac.chart_id)
		 JOIN gifi g ON (g.accno = c.accno)
	         $dpt_join
		 WHERE $yearendwhere
		 AND c.category = 'Q'
		 $dpt_where
		 $project
		 GROUP BY g.accno, g.description, c.category
		 |;
      }

        if ($project_id) {

	  $query .= qq|
	  
       UNION ALL
       
		 SELECT g.accno AS accno, SUM(ac.sellprice * ac.qty) AS amount,
		 g.description AS description, c.category
		 FROM invoice ac
	         JOIN ar a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.income_accno_id = c.id)
	         JOIN gifi g ON (g.accno = c.gifi_accno)
	         $dpt_join
	-- use transdate from subwhere
		 WHERE 1 = 1 $subwhere
		 $ywhere
		 AND c.category = 'I'
		 $dpt_where
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%AR_paid%'
		     $subwhere
		   )
		 $project
		 GROUP BY g.accno, g.description, c.category

       UNION ALL
       
		 SELECT g.accno AS accno, SUM(ac.sellprice * ac.qty) AS amount,
		 g.description AS description, c.category
		 FROM invoice ac
	         JOIN ap a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.expense_accno_id = c.id)
	         JOIN gifi g ON (g.accno = c.gifi_accno)
	         $dpt_join
		 WHERE 1 = 1 $subwhere
		 AND p.inventory_accno_id IS NULL
		 AND p.assembly = '0'
		 $ywhere
		 AND c.category = 'E'
		 $dpt_where
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%AP_paid%'
		     $subwhere
		   )
		 $project
		 GROUP BY g.accno, g.description, c.category

       UNION ALL
       
		 SELECT g.accno AS accno, SUM(ac.sellprice * ac.allocated) * -1 AS amount,
		 g.description AS description, c.category
		 FROM invoice ac
	         JOIN ap a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.expense_accno_id = c.id)
	         JOIN gifi g ON (g.accno = c.gifi_accno)
	         $dpt_join
		 WHERE 1 = 1 $subwhere
		 AND ac.assemblyitem = '0'
		 $ywhere
		 AND c.category = 'E'
		 $dpt_where
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%AP_paid%'
		     $subwhere
		   )
		 $project
		 GROUP BY g.accno, g.description, c.category
		 |;
	}

    } else {

      if ($department_id)
      {
	$dpt_join = qq|
	      JOIN dpt_trans t ON (t.trans_id = ac.trans_id)
	      |;
	$dpt_where = qq|
               AND t.department_id = $department_id
	      |;

      }

      $query = qq|
      
	      SELECT g.accno, SUM(ac.amount) AS amount,
	      g.description, c.category
	      FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      JOIN gifi g ON (c.gifi_accno = g.accno)
	      $dpt_join
	      WHERE $where
	      $ywhere
	      $dpt_from
	      $category
	      $project
	      GROUP BY g.accno, g.description, c.category
	      
	   UNION ALL
	   
	      SELECT '' AS accno, SUM(ac.amount) AS amount,
	      '' AS description, c.category
	      FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      $dpt_join
	      WHERE $where
	      $ywhere
	      $dpt_from
	      $category
	      AND c.gifi_accno = ''
	      $project
	      GROUP BY c.category
	      |;

	if ($yearend) {

	  # this is for the yearend

	  $query .= qq|

       UNION ALL
       
	         SELECT g.accno, sum(ac.amount) AS amount,
		 g.description, c.category
		 FROM yearend y
		 JOIN acc_trans ac ON (ac.trans_id = y.trans_id)
		 JOIN chart c ON (c.id = ac.chart_id)
		 JOIN gifi g ON (g.accno = c.accno)
	         $dpt_join
		 WHERE $yearendwhere
		 AND c.category = 'Q'
		 $dpt_where
		 $project
		 GROUP BY g.accno, g.description, c.category
	      |;
	}

       if ($project_id)
       {

	 $query .= qq|
	  
	 UNION ALL
       
		 SELECT g.accno AS accno, SUM(ac.sellprice * ac.qty) AS amount,
		 g.description AS description, c.category
		 FROM invoice ac
	         JOIN ar a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.income_accno_id = c.id)
		 JOIN gifi g ON (c.gifi_accno = g.accno)
	         $dpt_join
	-- use transdate from subwhere
		 WHERE 1 = 1 $subwhere
	         $ywhere
		 AND c.category = 'I'
		 $dpt_where
		 $project
		 GROUP BY g.accno, g.description, c.category

       UNION ALL
       
		 SELECT g.accno AS accno, SUM(ac.sellprice * ac.qty) AS amount,
		 g.description AS description, c.category
		 FROM invoice ac
	         JOIN ap a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.expense_accno_id = c.id)
		 JOIN gifi g ON (c.gifi_accno = g.accno)
	         $dpt_join
		 WHERE 1 = 1 $subwhere
		 AND p.inventory_accno_id IS NULL
		 AND p.assembly = '0'
	         $ywhere
		 AND c.category = 'E'
		 $dpt_where
		 $project
		 GROUP BY g.accno, g.description, c.category

       UNION ALL
       
		 SELECT g.accno AS accno, SUM(ac.sellprice * ac.allocated) * -1 AS amount,
		 g.description AS description, c.category
		 FROM invoice ac
	         JOIN ap a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.expense_accno_id = c.id)
		 JOIN gifi g ON (c.gifi_accno = g.accno)
	         $dpt_join
		 WHERE 1 = 1 $subwhere
		 AND ac.assemblyitem = '0'
	         $ywhere
		 AND c.category = 'E'
		 $dpt_where
		 $project
		 GROUP BY g.accno, g.description, c.category
		 |;
	}

    }
    
  } else {    # standard account

    if ($form->{method} eq 'cash')
    {

      $query = qq|
	
	         SELECT c.accno, sum(ac.amount) AS amount,
		 c.description, c.category
		 FROM acc_trans ac
		 JOIN chart c ON (c.id = ac.chart_id)
		 JOIN ar a ON (a.id = ac.trans_id)
		 $dpt_join
		 WHERE $where
	         $ywhere
		 $dpt_where
		 $category
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%AR_paid%'
		     $subwhere
		   )
		     
		 $project
		 GROUP BY c.accno, c.description, c.category
		 
	UNION ALL
	
	         SELECT c.accno, sum(ac.amount) AS amount,
		 c.description, c.category
		 FROM acc_trans ac
		 JOIN chart c ON (c.id = ac.chart_id)
		 JOIN ap a ON (a.id = ac.trans_id)
		 $dpt_join
		 WHERE $where
	         $ywhere
		 $dpt_where
		 $category
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%AP_paid%'
		     $subwhere
		   )
		     
		 $project
		 GROUP BY c.accno, c.description, c.category
		 
        UNION ALL

		 SELECT c.accno, sum(ac.amount) AS amount,
		 c.description, c.category
		 FROM acc_trans ac
		 JOIN chart c ON (c.id = ac.chart_id)
		 JOIN gl a ON (a.id = ac.trans_id)
		 $dpt_join
		 WHERE $where
	         $ywhere
		 $glwhere
		 $dpt_from
		 $category
		 AND NOT (c.link = 'AR' OR c.link = 'AP')
		 $project
		 GROUP BY c.accno, c.description, c.category
		 |;

      if ($yearend) {

        # this is for the yearend
	
	$query .= qq|

       UNION ALL
       
	         SELECT c.accno, sum(ac.amount) AS amount,
		 c.description, c.category
		 FROM yearend y
		 JOIN acc_trans ac ON (ac.trans_id = y.trans_id)
		 JOIN chart c ON (c.id = ac.chart_id)
	         $dpt_join
		 WHERE $yearendwhere
		 AND c.category = 'Q'
		 $dpt_where
		 $project
		 GROUP BY c.accno, c.description, c.category
		 |;
      }

		 
       if ($project_id)
       {

	  $query .= qq|
	  
	 UNION ALL
       
		 SELECT c.accno AS accno, SUM(ac.sellprice * ac.qty) AS amount,
		 c.description AS description, c.category
		 FROM invoice ac
	         JOIN ar a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.income_accno_id = c.id)
	         $dpt_join
	-- use transdate from subwhere
		 WHERE 1 = 1 $subwhere
	         $ywhere
		 AND c.category = 'I'
		 $dpt_where
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%AR_paid%'
		     $subwhere
		   )

		 $project
		 GROUP BY c.accno, c.description, c.category

	 UNION ALL
       
		 SELECT c.accno AS accno, SUM(ac.sellprice * ac.qty) AS amount,
		 c.description AS description, c.category
		 FROM invoice ac
	         JOIN ap a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.expense_accno_id = c.id)
	         $dpt_join
		 WHERE 1 = 1 $subwhere
		 AND p.inventory_accno_id IS NULL
		 AND p.assembly = '0'
	         $ywhere
		 AND c.category = 'E'
		 $dpt_where
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%AP_paid%'
		     $subwhere
		   )

		 $project
		 GROUP BY c.accno, c.description, c.category
		 
	 UNION ALL
       
		 SELECT c.accno AS accno, SUM(ac.sellprice * ac.allocated) * -1 AS amount,
		 c.description AS description, c.category
		 FROM invoice ac
	         JOIN ap a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.expense_accno_id = c.id)
	         $dpt_join
		 WHERE 1 = 1 $subwhere
		 AND ac.assemblyitem = '0'
	         $ywhere
		 AND c.category = 'E'
		 $dpt_where
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%AP_paid%'
		     $subwhere
		   )

		 $project
		 GROUP BY c.accno, c.description, c.category
		 |;
      }

    } else {
     
      if ($department_id)
      {
	$dpt_join = qq|
	      JOIN dpt_trans t ON (t.trans_id = ac.trans_id)
	      |;
	$dpt_where = qq|
               AND t.department_id = $department_id
	      |;
      }

	
      $query = qq|
      
		 SELECT c.accno, sum(ac.amount) AS amount,
		 c.description, c.category
		 FROM acc_trans ac
		 JOIN chart c ON (c.id = ac.chart_id)
		 $dpt_join
		 WHERE $where
	         $ywhere
		 $dpt_where
		 $category
		 $project
		 GROUP BY c.accno, c.description, c.category
		 |;

      if ($yearend) {

        # this is for the yearend
	
	$query .= qq|

       UNION ALL
       
	         SELECT c.accno, sum(ac.amount) AS amount,
		 c.description, c.category
		 FROM yearend y
		 JOIN acc_trans ac ON (ac.trans_id = y.trans_id)
		 JOIN chart c ON (c.id = ac.chart_id)
	         $dpt_join
		 WHERE $yearendwhere
		 AND c.category = 'Q'
		 $dpt_where
		 $project
		 GROUP BY c.accno, c.description, c.category
		 |;
      }


      if ($project_id)
      {

	$query .= qq|
	  
	UNION ALL
       
		 SELECT c.accno AS accno, SUM(ac.sellprice * ac.qty) AS amount,
		 c.description AS description, c.category
		 FROM invoice ac
	         JOIN ar a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.income_accno_id = c.id)
	         $dpt_join
	-- use transdate from subwhere
		 WHERE 1 = 1 $subwhere
	         $ywhere
		 AND c.category = 'I'
		 $dpt_where
		 $project
		 GROUP BY c.accno, c.description, c.category

	UNION ALL
       
		 SELECT c.accno AS accno, SUM(ac.sellprice * ac.qty) AS amount,
		 c.description AS description, c.category
		 FROM invoice ac
	         JOIN ap a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.expense_accno_id = c.id)
	         $dpt_join
		 WHERE 1 = 1 $subwhere
		 AND p.inventory_accno_id IS NULL
		 AND p.assembly = '0'
	         $ywhere
		 AND c.category = 'E'
		 $dpt_where
		 $project
		 GROUP BY c.accno, c.description, c.category
		 
	UNION ALL
       
		 SELECT c.accno AS accno, SUM(ac.sellprice * ac.allocated) * -1 AS amount,
		 c.description AS description, c.category
		 FROM invoice ac
	         JOIN ap a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.expense_accno_id = c.id)
	         $dpt_join
		 WHERE 1 = 1 $subwhere
		 AND ac.assemblyitem = '0'
	         $ywhere
		 AND c.category = 'E'
		 $dpt_where
		 $project
		 GROUP BY c.accno, c.description, c.category
		 |;

      }
    }
  }


  my @accno;
  my $accno;
  my $ref;
  
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc))
  {

    if ($ref->{category} eq 'C') {
      $ref->{category} = 'A';
    }

    # get last heading account
    @accno = grep { $_ le "$ref->{accno}" } @headingaccounts;
    $accno = pop @accno;
    if ($accno && ($accno ne $ref->{accno}) ) {
      if ($last_period)
      {
	$form->{$ref->{category}}{$accno}{last} += $ref->{amount};
      } else {
	$form->{$ref->{category}}{$accno}{this} += $ref->{amount};
      }
    }
    
    $form->{$ref->{category}}{$ref->{accno}}{accno} = $ref->{accno};
    $form->{$ref->{category}}{$ref->{accno}}{description} = $ref->{description};
    $form->{$ref->{category}}{$ref->{accno}}{charttype} = "A";
    
    if ($last_period)
    {
      $form->{$ref->{category}}{$ref->{accno}}{last} += $ref->{amount};
    } else {
      $form->{$ref->{category}}{$ref->{accno}}{this} += $ref->{amount};
    }
  }
  $sth->finish;

  
  # remove accounts with zero balance
  foreach $category (@{ $categories }) {
    foreach $accno (keys %{ $form->{$category} }) {
      $form->{$category}{$accno}{last} = $form->round_amount($form->{$category}{$accno}{last}, $form->{decimalplaces});
      $form->{$category}{$accno}{this} = $form->round_amount($form->{$category}{$accno}{this}, $form->{decimalplaces});

      delete $form->{$category}{$accno} if ($form->{$category}{$accno}{this} == 0 && $form->{$category}{$accno}{last} == 0);
    }
  }

}



sub trial_balance {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);

  my ($query, $sth, $ref);
  my %balance = ();
  my %trb = ();
  my $null;
  my $department_id;
  my $project_id;
  my @headingaccounts = ();
  my $dpt_where;
  my $dpt_join;
  my $project;

  my $where = "1 = 1";
  my $invwhere = $where;
  
  ($null, $department_id) = split /--/, $form->{department};
  ($null, $project_id) = split /--/, $form->{projectnumber};

  if ($department_id) {
    $dpt_join = qq|
                JOIN dpt_trans t ON (ac.trans_id = t.trans_id)
		  |;
    $dpt_where = qq|
                AND t.department_id = $department_id
		|;
  }
  
  
  # project_id only applies to getting transactions
  # it has nothing to do with a trial balance
  # but we use the same function to collect information
  
  if ($project_id) {
    $project = qq|
                AND ac.project_id = $project_id
		|;
  }
  
  ($form->{fromdate}, $form->{todate}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month}; 
   
  # get beginning balances
  if ($form->{fromdate}) {

    if ($form->{accounttype} eq 'gifi') {
      
      $query = qq|SELECT g.accno, c.category, SUM(ac.amount) AS amount,
                  g.description
		  FROM acc_trans ac
		  JOIN chart c ON (ac.chart_id = c.id)
		  JOIN gifi g ON (c.gifi_accno = g.accno)
		  $dpt_join
		  WHERE ac.transdate < '$form->{fromdate}'
		  $dpt_where
		  $project
		  GROUP BY g.accno, c.category, g.description
		  |;
   
    } else {
      
      $query = qq|SELECT c.accno, c.category, SUM(ac.amount) AS amount,
                  c.description
		  FROM acc_trans ac
		  JOIN chart c ON (ac.chart_id = c.id)
		  $dpt_join
		  WHERE ac.transdate < '$form->{fromdate}'
		  $dpt_where
		  $project
		  GROUP BY c.accno, c.category, c.description
		  |;
		  
    }

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
      $balance{$ref->{accno}} = $ref->{amount};

      if ($ref->{amount} != 0 && $form->{all_accounts}) {
	$trb{$ref->{accno}}{description} = $ref->{description};
	$trb{$ref->{accno}}{charttype} = 'A';
	$trb{$ref->{accno}}{category} = $ref->{category};
      }

    }
    $sth->finish;

  }


  # get headings
  $query = qq|SELECT c.accno, c.description, c.category
	      FROM chart c
	      WHERE c.charttype = 'H'
	      ORDER by c.accno|;

  if ($form->{accounttype} eq 'gifi')
  {
    $query = qq|SELECT g.accno, g.description, c.category
		FROM gifi g
		JOIN chart c ON (c.gifi_accno = g.accno)
		WHERE c.charttype = 'H'
		ORDER BY g.accno|;
  }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc))
  {
    $trb{$ref->{accno}}{description} = $ref->{description};
    $trb{$ref->{accno}}{charttype} = 'H';
    $trb{$ref->{accno}}{category} = $ref->{category};
   
    push @headingaccounts, $ref->{accno};
  }

  $sth->finish;


  if ($form->{fromdate} || $form->{todate}) {
    if ($form->{fromdate}) {
      $where .= " AND ac.transdate >= '$form->{fromdate}'";
      $invwhere .= " AND a.transdate >= '$form->{fromdate}'";
    }
    if ($form->{todate}) {
      $where .= " AND ac.transdate <= '$form->{todate}'";
      $invwhere .= " AND a.transdate <= '$form->{todate}'";
    }
  }


  if ($form->{accounttype} eq 'gifi') {

    $query = qq|SELECT g.accno, g.description, c.category,
                SUM(ac.amount) AS amount
		FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		JOIN gifi g ON (c.gifi_accno = g.accno)
		$dpt_join
		WHERE $where
		$dpt_where
		$project
		GROUP BY g.accno, g.description, c.category
		|;

    if ($project_id) {

      $query .= qq|

	-- sold items
	
	UNION ALL
	
	        SELECT g.accno, g.description, c.category,
		SUM(ac.sellprice * ac.qty) AS amount
		FROM invoice ac
		JOIN ar a ON (ac.trans_id = a.id)
		JOIN parts p ON (ac.parts_id = p.id)
		JOIN chart c ON (p.income_accno_id = c.id)
		JOIN gifi g ON (c.gifi_accno = g.accno)
		$dpt_join
		WHERE $invwhere
		$dpt_where
		$project
		GROUP BY g.accno, g.description, c.category

	UNION ALL

	-- bought services
	
	        SELECT g.accno, g.description, c.category,
		SUM(ac.sellprice * ac.qty) AS amount
		FROM invoice ac
		JOIN ap a ON (ac.trans_id = a.id)
		JOIN parts p ON (ac.parts_id = p.id)
		JOIN chart c ON (p.expense_accno_id = c.id)
		JOIN gifi g ON (c.gifi_accno = g.accno)
		$dpt_join
		WHERE $invwhere
		AND p.inventory_accno_id IS NULL
		AND p.assembly = '0'
		$dpt_where
		$project
		GROUP BY g.accno, g.description, c.category

        -- COGS

	UNION ALL
	
	        SELECT g.accno, g.description, c.category,
		SUM(ac.sellprice * ac.allocated) * -1 AS amount
		FROM invoice ac
		JOIN ap a ON (ac.trans_id = a.id)
		JOIN parts p ON (ac.parts_id = p.id)
		JOIN chart c ON (p.expense_accno_id = c.id)
		JOIN gifi g ON (c.gifi_accno = g.accno)
		$dpt_join
		WHERE $invwhere
		AND ac.assemblyitem = '0'
		$dpt_where
		$project
		GROUP BY g.accno, g.description, c.category

		|;
    }

    $query .= qq|
		ORDER BY accno|;
    
  } else {

    $query = qq|SELECT c.accno, c.description, c.category,
                SUM(ac.amount) AS amount
		FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		$dpt_join
		WHERE $where
		$dpt_where
		$project
		GROUP BY c.accno, c.description, c.category
		|;

    if ($project_id) {

      $query .= qq|

	-- sold items
	
	UNION ALL
	
	        SELECT c.accno, c.description, c.category,
		SUM(ac.sellprice * ac.qty) AS amount
		FROM invoice ac
		JOIN ar a ON (ac.trans_id = a.id)
		JOIN parts p ON (ac.parts_id = p.id)
		JOIN chart c ON (p.income_accno_id = c.id)
		$dpt_join
		WHERE $invwhere
		$dpt_where
		$project
		GROUP BY c.accno, c.description, c.category

	UNION ALL
	
	-- bought services
	
	        SELECT c.accno, c.description, c.category,
		SUM(ac.sellprice * ac.qty) AS amount
		FROM invoice ac
		JOIN ap a ON (ac.trans_id = a.id)
		JOIN parts p ON (ac.parts_id = p.id)
		JOIN chart c ON (p.expense_accno_id = c.id)
		$dpt_join
		WHERE $invwhere
		AND p.inventory_accno_id IS NULL
		AND p.assembly = '0'
		$dpt_where
		$project
		GROUP BY c.accno, c.description, c.category

        -- cogs
	
	UNION ALL
	
	        SELECT c.accno, c.description, c.category,
		SUM(ac.sellprice * ac.allocated) * -1 AS amount
		FROM invoice ac
		JOIN ap a ON (ac.trans_id = a.id)
		JOIN parts p ON (ac.parts_id = p.id)
		JOIN chart c ON (p.expense_accno_id = c.id)
		$dpt_join
		WHERE $invwhere
		AND ac.assemblyitem = '0'
		$dpt_where
		$project
		GROUP BY c.accno, c.description, c.category
 
		|;
    }

    $query .= qq|
                ORDER BY accno|;

  }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);


  # prepare query for each account
  $query = qq|SELECT (SELECT SUM(ac.amount) * -1
	      FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      $dpt_join
	      WHERE $where
	      $dpt_where
	      $project
	      AND ac.amount < 0
	      AND c.accno = ?) AS debit,
	      
	     (SELECT SUM(ac.amount)
	      FROM acc_trans ac
	      JOIN chart c ON (c.id = ac.chart_id)
	      $dpt_join
	      WHERE $where
	      $dpt_where
	      $project
	      AND ac.amount > 0
	      AND c.accno = ?) AS credit
	      |;

  if ($form->{accounttype} eq 'gifi') {

    $query = qq|SELECT (SELECT SUM(ac.amount) * -1
		FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		$dpt_join
		WHERE $where
		$dpt_where
		$project
		AND ac.amount < 0
		AND c.gifi_accno = ?) AS debit,
		
	       (SELECT SUM(ac.amount)
		FROM acc_trans ac
		JOIN chart c ON (c.id = ac.chart_id)
		$dpt_join
		WHERE $where
		$dpt_where
		$project
		AND ac.amount > 0
		AND c.gifi_accno = ?) AS credit|;
  
  }
  
  $drcr = $dbh->prepare($query);

  # calculate debit and credit for the period
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $trb{$ref->{accno}}{description} = $ref->{description};
    $trb{$ref->{accno}}{charttype} = 'A';
    $trb{$ref->{accno}}{category} = $ref->{category};
    $trb{$ref->{accno}}{amount} += $ref->{amount};
  }
  $sth->finish;

  my ($debit, $credit);
  
  foreach my $accno (sort keys %trb) {
    $ref = ();
    
    $ref->{accno} = $accno;
    map { $ref->{$_} = $trb{$accno}{$_} } qw(description category charttype amount);
    
    $ref->{balance} = $form->round_amount($balance{$ref->{accno}}, 2);

    if ($trb{$accno}{charttype} eq 'A') {
      if ($project_id) {

        if ($ref->{amount} < 0) {
	  $ref->{debit} = $ref->{amount} * -1;
	} else {
	  $ref->{credit} = $ref->{amount};
	}

      } else {
	
	# get DR/CR
	$drcr->execute($ref->{accno}, $ref->{accno}) || $form->dberror($query);
	
	($debit, $credit) = (0,0);
	while (($debit, $credit) = $drcr->fetchrow_array) {
	  $ref->{debit} += $debit;
	  $ref->{credit} += $credit;
	}
	$drcr->finish;

      }

      $ref->{debit} = $form->round_amount($ref->{debit}, 2);
      $ref->{credit} = $form->round_amount($ref->{credit}, 2);
    
    }

    # add subtotal
    @accno = grep { $_ le "$ref->{accno}" } @headingaccounts;
    $accno = pop @accno;
    if ($accno) {
      $trb{$accno}{debit} += $ref->{debit};
      $trb{$accno}{credit} += $ref->{credit};
    }

    push @{ $form->{TB} }, $ref;
    
  }

  $dbh->disconnect;

  # debits and credits for headings
  foreach $accno (@headingaccounts) {
    foreach $ref (@{ $form->{TB} }) {
      if ($accno eq $ref->{accno}) {
        $ref->{debit} = $trb{$accno}{debit};
        $ref->{credit} = $trb{$accno}{credit};
      }
    }
  }

}


sub aging {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $invoice = ($form->{arap} eq 'ar') ? 'is' : 'ir';
  
  ($null, $form->{todate}) = $form->from_to($form->{year}, $form->{month}) if $form->{year} && $form->{month};
  
  $form->{todate} = $form->current_date($myconfig) unless ($form->{todate});


  my $where = "1 = 1";
  my $name;
  my $null;
  my $ref;

  if ($form->{"$form->{ct}_id"}) {
    $where .= qq| AND ct.id = $form->{"$form->{ct}_id"}|;
  } else {
    if ($form->{$form->{ct}}) {
      $name = $form->like(lc $form->{$form->{ct}});
      $where .= qq| AND lower(ct.name) LIKE '$name'| if $form->{$form->{ct}};
    }
  }

  my $dpt_join;
  if ($form->{department}) {
    ($null, $department_id) = split /--/, $form->{department};
    $dpt_join = qq|
               JOIN department d ON (a.department_id = d.id)
	          |;

    $where .= qq| AND a.department_id = $department_id|;
  }
  
  # select outstanding vendors or customers, depends on $ct
  my $query = qq|SELECT DISTINCT ct.id, ct.name, ct.language_code
                 FROM $form->{ct} ct
		 JOIN $form->{arap} a ON (a.$form->{ct}_id = ct.id)
		 $dpt_join
		 WHERE $where
                 AND a.paid != a.amount
                 AND (a.transdate <= '$form->{todate}')
                 ORDER BY ct.name|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror;

  my $buysell = ($form->{arap} eq 'ar') ? 'buy' : 'sell';

  my %interval = ( 'Pg' => {
                        'c0' => "(date '$form->{todate}' - interval '0 days')",
			'c30' => "(date '$form->{todate}' - interval '30 days')",
			'c60' => "(date '$form->{todate}' - interval '60 days')",
			'c90' => "(date '$form->{todate}' - interval '90 days')" },
		  'DB2' => {
		        'c0' => "(date ('$form->{todate}') - 0 days)",
			'c30' => "(date ('$form->{todate}') - 30 days)",
			'c60' => "(date ('$form->{todate}') - 60 days)",
			'c90' => "(date ('$form->{todate}') - 90 days)" }
		);

  $interval{Oracle} = $interval{PgPP} = $interval{Pg};
  
		    
  # for each company that has some stuff outstanding
  my $id;
  while (($id, $null, $language_code) = $sth->fetchrow_array ) {
  
    $query = qq|
	SELECT c.id AS ctid, c.name,
	c.address1, c.address2, c.city, c.state, c.zipcode, c.country,
	c.contact, c.email,
	c.phone as customerphone, c.fax as customerfax, c.$form->{ct}number,
	a.invnumber, a.transdate, a.till, a.ordnumber, a.notes,
	(a.amount - a.paid) as c0, 0.00 as c30, 0.00 as c60, 0.00 as c90,
	a.duedate, a.invoice, a.id,
	  (SELECT $buysell FROM exchangerate e
	   WHERE a.curr = e.curr
	   AND e.transdate = a.transdate) AS exchangerate
  FROM $form->{arap} a
  JOIN $form->{ct} c ON (a.$form->{ct}_id = c.id)
	WHERE a.paid != a.amount
	AND c.id = $id
	AND (
	        a.transdate <= $interval{$myconfig->{dbdriver}}{c0}
	        AND a.transdate >= $interval{$myconfig->{dbdriver}}{c30}
	    )
	
	UNION

	SELECT c.id AS ctid, c.name,
	c.address1, c.address2, c.city, c.state, c.zipcode, c.country,
	c.contact, c.email,
	c.phone as customerphone, c.fax as customerfax, c.$form->{ct}number,
	a.invnumber, a.transdate, a.till, a.ordnumber, a.notes,
	0.00 as c0, (a.amount - a.paid) as c30, 0.00 as c60, 0.00 as c90,
	a.duedate, a.invoice, a.id,
	  (SELECT $buysell FROM exchangerate e
	   WHERE a.curr = e.curr
	   AND e.transdate = a.transdate) AS exchangerate
  FROM $form->{arap} a
  JOIN $form->{ct} c ON (a.$form->{ct}_id = c.id)
	WHERE a.paid != a.amount 
	AND c.id = $id
	AND (
		a.transdate < $interval{$myconfig->{dbdriver}}{c30}
		AND a.transdate >= $interval{$myconfig->{dbdriver}}{c60}
		)

	UNION
  
	SELECT c.id AS ctid, c.name,
	c.address1, c.address2, c.city, c.state, c.zipcode, c.country,
	c.contact, c.email,
	c.phone as customerphone, c.fax as customerfax, c.$form->{ct}number,
	a.invnumber, a.transdate, a.till, a.ordnumber, a.notes,
	0.00 as c0, 0.00 as c30, (a.amount - a.paid) as c60, 0.00 as c90,
	a.duedate, a.invoice, a.id,
	  (SELECT $buysell FROM exchangerate e
	   WHERE a.curr = e.curr
	   AND e.transdate = a.transdate) AS exchangerate
	FROM $form->{arap} a
	JOIN $form->{ct} c ON (a.$form->{ct}_id = c.id)
	WHERE a.paid != a.amount
	AND c.id = $id
	AND (
		a.transdate < $interval{$myconfig->{dbdriver}}{c60}
		AND a.transdate >= $interval{$myconfig->{dbdriver}}{c90}
		)

	UNION
  
	SELECT c.id AS ctid, c.name,
	c.address1, c.address2, c.city, c.state, c.zipcode, c.country,
	c.contact, c.email,
	c.phone as customerphone, c.fax as customerfax, c.$form->{ct}number,
	a.invnumber, a.transdate, a.till, a.ordnumber, a.notes,
	0.00 as c0, 0.00 as c30, 0.00 as c60, (a.amount - a.paid) as c90,
	a.duedate, a.invoice, a.id,
	  (SELECT $buysell FROM exchangerate e
	   WHERE a.curr = e.curr
	   AND e.transdate = a.transdate) AS exchangerate
	FROM $form->{arap} a
	JOIN $form->{ct} c ON (a.$form->{ct}_id = c.id)
	WHERE a.paid != a.amount
	AND c.id = $id
	AND a.transdate < $interval{$myconfig->{dbdriver}}{c90}

	ORDER BY
  
  ctid, transdate, invnumber
  
		|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror;

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{module} = ($ref->{invoice}) ? $invoice : $form->{arap};
      $ref->{module} = 'ps' if $ref->{till};
      $ref->{exchangerate} = 1 unless $ref->{exchangerate};
      $ref->{language_code} = $language_code;
      push @{ $form->{AG} }, $ref;
    }
    
    $sth->finish;

  }
  $sth->finish;

  # get language
  my $query = qq|SELECT *
                 FROM language
		 ORDER BY 2|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) { 
    push @{ $form->{all_language} }, $ref;
  }
  $sth->finish;

  # disconnect
  $dbh->disconnect;

}


sub get_customer {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT name, email, cc, bcc
                 FROM $form->{ct} ct
		 WHERE ct.id = $form->{"$form->{ct}_id"}|;
  ($form->{$form->{ct}}, $form->{email}, $form->{cc}, $form->{bcc}) = $dbh->selectrow_array($query);
  
  $dbh->disconnect;

}


sub get_taxaccounts {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  # get tax accounts
  my $query = qq|SELECT c.accno, c.description, t.rate, c.link
                 FROM chart c, tax t
		 WHERE c.link LIKE '%CT_tax%'
		 AND c.id = t.chart_id
                 ORDER BY c.accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror;

  my $ref = ();
  while ($ref = $sth->fetchrow_hashref(NAME_lc) ) {
    push @{ $form->{taxaccounts} }, $ref;
  }
  $sth->finish;

  # get gifi tax accounts
  my $query = qq|SELECT DISTINCT g.accno, g.description,
                 sum(t.rate) AS rate
                 FROM gifi g, chart c, tax t
		 WHERE g.accno = c.gifi_accno
		 AND c.id = t.chart_id
		 AND c.link LIKE '%CT_tax%'
		 GROUP BY g.accno, g.description
                 ORDER BY accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror;

  while ($ref = $sth->fetchrow_hashref(NAME_lc) ) {
    push @{ $form->{gifi_taxaccounts} }, $ref;
  }
  $sth->finish;

  $dbh->disconnect;

}



sub tax_report {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my ($null, $department_id) = split /--/, $form->{department};
  
  # build WHERE
  my $where = "1 = 1";
  my $cashwhere = "";

  if ($department_id) {
    $where .= qq|
                 AND a.department_id = $department_id
		|;
  }
  
  my $query;
  my $sth;
  my $accno;
  my $rate;
  
  if ($form->{accno}) {
    if ($form->{accno} =~ /^gifi_/) {
      ($null, $accno) = split /_/, $form->{accno};
      $rate = $form->{"$form->{accno}_rate"};
      $accno = qq| AND ch.gifi_accno = '$accno'|;
    } else {
      $accno = $form->{accno};
      $rate = $form->{"$form->{accno}_rate"};
      $accno = qq| AND ch.accno = '$accno'|;
    }
  }
  $rate *= 1;

  my $table;
  my $ARAP;
  
  if ($form->{db} eq 'ar') {
    $table = "customer";
    $ARAP = "AR";
  }
  if ($form->{db} eq 'ap') {
    $table = "vendor";
    $ARAP = "AP";
  }

  my $transdate = "a.transdate";

  ($form->{fromdate}, $form->{todate}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  
  # if there are any dates construct a where
  if ($form->{fromdate} || $form->{todate}) {
    if ($form->{fromdate}) {
      $where .= " AND $transdate >= '$form->{fromdate}'";
    }
    if ($form->{todate}) {
      $where .= " AND $transdate <= '$form->{todate}'";
    }
  }


  if ($form->{method} eq 'cash') {
    $transdate = "a.datepaid";

    my $todate = ($form->{todate}) ? $form->{todate} : $form->current_date($myconfig);
    
    $cashwhere = qq|
		 AND ac.trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%${ARAP}_paid%'
		     AND $transdate <= '$todate'
		   )
		  |;
  }

    
  my $ml = ($form->{db} eq 'ar') ? 1 : -1;
  
  my %ordinal = ( 'transdate' => 3,
                  'invnumber' => 4,
		  'name' => 5
		);
  
  my @a = qw(transdate invnumber name);
  my $sortorder = $form->sort_order(\@a, \%ordinal);

  $rate = 1 unless $rate;

  if ($form->{summary}) {
    
    $query = qq|SELECT a.id, '0' AS invoice, $transdate AS transdate,
		a.invnumber, n.name, a.netamount,
		ac.amount * $ml AS tax,
		a.till
		FROM acc_trans ac
	      JOIN $form->{db} a ON (a.id = ac.trans_id)
	      JOIN chart ch ON (ch.id = ac.chart_id)
	      JOIN $table n ON (n.id = a.${table}_id)
		WHERE $where
		$accno
		AND a.invoice = '0'
		$cashwhere
	      UNION ALL
		SELECT a.id, '1' AS invoice, $transdate AS transdate,
		a.invnumber, n.name,
		sum(i.sellprice * i.qty) * $ml AS netamount,
		sum(i.sellprice * i.qty) * $rate * $ml AS tax,
		a.till
		FROM acc_trans ac
	      JOIN $form->{db} a ON (a.id = ac.trans_id)
	      JOIN chart ch ON (ch.id = ac.chart_id)
	      JOIN $table n ON (n.id = a.${table}_id)
	      JOIN ${table}tax t ON (t.${table}_id = n.id AND t.chart_id = ch.id)
	      JOIN invoice i ON (i.trans_id = a.id)
	      JOIN partstax p ON (p.parts_id = i.parts_id)
		WHERE $where
		$accno
		AND a.invoice = '1'
		$cashwhere
		GROUP BY a.id, a.invoice, $transdate, a.invnumber, n.name,
		a.till
		|;
		
    } else {
      
     $query = qq|SELECT a.id, '0' AS invoice, $transdate AS transdate,
		a.invnumber, n.name, a.netamount,
		ac.amount * $ml AS tax,
		a.notes AS description, a.till
		FROM acc_trans ac
	      JOIN $form->{db} a ON (a.id = ac.trans_id)
	      JOIN chart ch ON (ch.id = ac.chart_id)
	      JOIN $table n ON (n.id = a.${table}_id)
		WHERE $where
		$accno
		AND a.invoice = '0'
		$cashwhere
	      UNION ALL
		SELECT a.id, '1' AS invoice, $transdate AS transdate,
		a.invnumber, n.name,
		i.sellprice * i.qty * $ml AS netamount,
		i.sellprice * i.qty * $rate * $ml AS tax,
		i.description, a.till
		FROM acc_trans ac
	      JOIN $form->{db} a ON (a.id = ac.trans_id)
	      JOIN chart ch ON (ch.id = ac.chart_id)
	      JOIN $table n ON (n.id = a.${table}_id)
	      JOIN ${table}tax t ON (t.${table}_id = n.id AND t.chart_id = ch.id)
	      JOIN invoice i ON (i.trans_id = a.id)
	      JOIN partstax p ON (p.parts_id = i.parts_id)
		WHERE $where
		$accno
		AND a.invoice = '1'
		$cashwhere
		GROUP BY a.id, a.invoice, $transdate, a.invnumber, n.name,
		i.sellprice, i.qty, i.description, a.till
		|;
    }


  if ($form->{report} =~ /nontaxable/) {
    
    if ($form->{summary}) {
      # only gather up non-taxable transactions
      $query = qq|SELECT a.id, '0' AS invoice, $transdate AS transdate,
		  a.invnumber, n.name, a.netamount, a.till
		  FROM acc_trans ac
		JOIN $form->{db} a ON (a.id = ac.trans_id)
		JOIN $table n ON (n.id = a.${table}_id)
		  WHERE $where
		  AND a.invoice = '0'
		  AND a.netamount = a.amount
		  $cashwhere
		GROUP BY a.id, $transdate, a.invnumber, n.name, a.netamount,
		a.till
		UNION ALL
		  SELECT a.id, '1' AS invoice, $transdate AS transdate,
		  a.invnumber, n.name,
		  sum(ac.sellprice * ac.qty) * $ml AS netamount, a.till
		  FROM invoice ac
		JOIN $form->{db} a ON (a.id = ac.trans_id)
		JOIN $table n ON (n.id = a.${table}_id)
		  WHERE $where
		  AND a.invoice = '1'
		  AND (
		    a.${table}_id NOT IN (
			  SELECT ${table}_id FROM ${table}tax t (${table}_id)
					 ) OR
		    ac.parts_id NOT IN (
			  SELECT parts_id FROM partstax p (parts_id)
				      )
		      )
		  $cashwhere
		  GROUP BY a.id, a.invnumber, $transdate, n.name, a.till
		  |;
		  
    } else {

      # gather up details for non-taxable transactions
      $query = qq|SELECT a.id, '0' AS invoice, $transdate AS transdate,
		  a.invnumber, n.name, a.netamount,
		  a.notes AS description, a.till
		  FROM acc_trans ac
		JOIN $form->{db} a ON (a.id = ac.trans_id)
		JOIN $table n ON (n.id = a.${table}_id)
		  WHERE $where
		  AND a.invoice = '0'
		  AND a.netamount = a.amount
		  $cashwhere
		GROUP BY a.id, $transdate, a.invnumber, n.name, a.netamount,
		a.notes, a.till
		UNION ALL
		  SELECT a.id, '1' AS invoice, $transdate AS transdate,
		  a.invnumber, n.name,
		  sum(ac.sellprice * ac.qty) * $ml AS netamount,
		  ac.description, a.till
		  FROM invoice ac
		JOIN $form->{db} a ON (a.id = ac.trans_id)
		JOIN $table n ON (n.id = a.${table}_id)
		  WHERE $where
		  AND a.invoice = '1'
		  AND (
		    a.${table}_id NOT IN (
			  SELECT ${table}_id FROM ${table}tax t (${table}_id)
					 ) OR
		    ac.parts_id NOT IN (
			  SELECT parts_id FROM partstax p (parts_id)
				      )
		      )
		  $cashwhere
		  GROUP BY a.id, a.invnumber, $transdate, n.name, ac.description,
		  a.till
		  |;
    }
  }

  
  $query .= qq|
	      ORDER by $sortorder|;


  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ( my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{TR} }, $ref if $ref->{netamount} != 0;
  }

  $sth->finish;
  $dbh->disconnect;

}


sub paymentaccounts {
  my ($self, $myconfig, $form) = @_;
 
  # connect to database, turn AutoCommit off
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $ARAP = uc $form->{db};
  
  # get A(R|P)_paid accounts
  my $query = qq|SELECT accno, description
                 FROM chart
                 WHERE link LIKE '%${ARAP}_paid%'
		 ORDER BY accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
 
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{PR} }, $ref;
  }
  $sth->finish;

  $form->all_years($dbh, $myconfig);
  
  $dbh->disconnect;

}

 
sub payments {
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn AutoCommit off
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $ml = 1;
  if ($form->{db} eq 'ar') {
    $table = 'customer';
    $ml = -1;
  }
  if ($form->{db} eq 'ap') {
    $table = 'vendor';
  }
     

  my $query;
  my $sth;
  my $dpt_join;
  my $where;
  my $var;

  if ($form->{department_id}) {
    $dpt_join = qq|
	         JOIN dpt_trans t ON (t.trans_id = ac.trans_id)
		 |;

    $where = qq|
		 AND t.department_id = $form->{department_id}
		|;
  }

  ($form->{fromdate}, $form->{todate}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  
  if ($form->{fromdate}) {
    $where .= " AND ac.transdate >= '$form->{fromdate}'";
  }
  if ($form->{todate}) {
    $where .= " AND ac.transdate <= '$form->{todate}'";
  }
  if (!$form->{fx_transaction}) {
    $where .= " AND ac.fx_transaction = '0'";
  }
  
  if ($form->{description}) {
    $var = $form->like(lc $form->{description});
    $where .= " AND lower(c.name) LIKE '$var'";
  }
  if ($form->{source}) {
    $var = $form->like(lc $form->{source});
    $where .= " AND lower(ac.source) LIKE '$var'";
  }
  if ($form->{memo}) {
    $var = $form->like(lc $form->{memo});
    $where .= " AND lower(ac.memo) LIKE '$var'";
  }
 
  my %ordinal = ( 'name' => 1,
		  'transdate' => 2,
		  'source' => 4,
		  'employee' => 6,
		  'till' => 7
		);

  my @a = qw(name transdate employee);
  my $sortorder = $form->sort_order(\@a, \%ordinal);
  
  my $glwhere = $where;
  $glwhere =~ s/\(c.name\)/\(g.description\)/;

  # cycle through each id
  foreach my $accno (split(/ /, $form->{paymentaccounts})) {

    $query = qq|SELECT id, accno, description
                FROM chart
		WHERE accno = '$accno'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $ref = $sth->fetchrow_hashref(NAME_lc);
    push @{ $form->{PR} }, $ref;
    $sth->finish;

    $query = qq|SELECT c.name, ac.transdate, sum(ac.amount) * $ml AS paid,
                ac.source, ac.memo, e.name AS employee, a.till, a.curr
		FROM acc_trans ac
	        JOIN $form->{db} a ON (ac.trans_id = a.id)
	        JOIN $table c ON (c.id = a.${table}_id)
		LEFT JOIN employee e ON (a.employee_id = e.id)
	        $dpt_join
		WHERE ac.chart_id = $ref->{id}
		$where|;

    if ($form->{till} && !$myconfig->{admin}) {
      $query .= " AND e.login = '$form->{login}'
                  AND NOT a.till IS NULL";
    }

    $query .= qq|
                GROUP BY c.name, ac.transdate, ac.source, ac.memo,
		e.name, a.till, a.curr
		|;
		
    if (! $form->{till}) {
# don't need gl for a till
      
      $query .= qq|
 	UNION
		SELECT g.description, ac.transdate, sum(ac.amount) * $ml AS paid, ac.source,
		ac.memo, e.name AS employee, '' AS till, '' AS curr
		FROM acc_trans ac
	        JOIN gl g ON (g.id = ac.trans_id)
		LEFT JOIN employee e ON (g.employee_id = e.id)
	        $dpt_join
		WHERE ac.chart_id = $ref->{id}
		$glwhere
		AND (ac.amount * $ml) > 0
	GROUP BY g.description, ac.transdate, ac.source, ac.memo, e.name
		|;

    }

    $query .= qq|
                ORDER BY $sortorder|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while (my $pr = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{$ref->{id}} }, $pr;
    }
    $sth->finish;

  }
  
  $dbh->disconnect;
  
}


1;


