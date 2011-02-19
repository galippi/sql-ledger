#=====================================================================
# SQL-Ledger Accounting
# Copyright (C) 2001
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#
#  Modified by Tavugyvitel Kft. (info@tavugyvitel.hu)
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

  &get_accounts($dbh, $last_period, $form->{fromdate}, $form->{todate}, $form, \@categories, 1);
  
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
    
		if ($form->{l_subtotal} eq "bottom") {
			foreach $key (sort {
				($a =~ /^$b/) || ($b =~ /^$a/) ? (length($b) <=> length ($a)) : ($a cmp $b)
				} keys %{$form->{$category}}) {
				$account = $form->{l_heading} ? ($form->{padding} x length($key)) : "";
				if ($form->{$category}{$key}{charttype} eq "H") {
					next unless ($form->{l_heading});
					$account .= "$form->{bold}$form->{$category}{$key}{description}$form->{endbold}";
					$this = $form->{bold} . $form->format_amount ($myconfig, $form->{$category}{$key}{this} * $account{$category}{ml}, $form->{decimalplaces}, "- ") . $form->{endbold};
					$last = $form->{bold} . $form->format_amount ($myconfig, $form->{$category}{$key}{last} * $account{$category}{ml}, $form->{decimalplaces}, "- ") . $form->{endbold};
					}
				elsif ($form->{$category}{$key}{charttype} eq "A") {
					$account .= ($form->{l_accno}) ?
						"$form->{$category}{$key}{accno} - $form->{$category}{$key}{description}" :
						"$form->{$category}{$key}{description}";
					$form->{"total_$account{$category}{labels}_this_period"} += $form->{$category}{$key}{this} * $account{$category}{ml};
					$form->{"total_$account{$category}{labels}_last_period"} += $form->{$category}{$key}{last} * $account{$category}{ml} if ($last_period);
					$this = $form->format_amount ($myconfig, $form->{$category}{$key}{this} * $account{$category}{ml}, $form->{decimalplaces}, "- ");
					$last = $form->format_amount ($myconfig, $form->{$category}{$key}{last} * $account{$category}{ml}, $form->{decimalplaces}, "- ");
					}
				push (@{$form->{"$account{$category}{label}_account"}}, $account);
				push (@{$form->{"$account{$category}{labels}_this_period"}}, $this);
				push (@{$form->{"$account{$category}{labels}_last_period"}}, $last) if ($last_period);
				}
			}
		elsif ($form->{l_subtotal} eq "top") {
			foreach $key (sort { $a cmp $b } keys %{$form->{$category}}) {
				$account = $form->{l_heading} ? ($form->{padding} x length($key)) : "";
				if ($form->{$category}{$key}{charttype} eq "H") {
					next unless ($form->{l_heading});
					$account .= "$form->{bold}$form->{$category}{$key}{description}$form->{endbold}";
					$this = "";
					$last = "";
					}
				elsif ($form->{$category}{$key}{charttype} eq "A") {
					$account .= ($form->{l_accno}) ?
						"$form->{$category}{$key}{accno} - $form->{$category}{$key}{description}" :
						"$form->{$category}{$key}{description}";
					$this = $form->format_amount ($myconfig, $form->{$category}{$key}{this} * $account{$category}{ml}, $form->{decimalplaces}, "- ");
					$last = $form->format_amount ($myconfig, $form->{$category}{$key}{last} * $account{$category}{ml}, $form->{decimalplaces}, "- ");
					$form->{"total_$account{$category}{labels}_this_period"} += $form->{$category}{$key}{this} * $account{$category}{ml};
					$form->{"total_$account{$category}{labels}_last_period"} += $form->{$category}{$key}{last} * $account{$category}{ml} if ($last_period);
					}
				push (@{$form->{"$account{$category}{label}_account"}}, $account);
				push (@{$form->{"$account{$category}{labels}_this_period"}}, $this);
				push (@{$form->{"$account{$category}{labels}_last_period"}}, $last) if ($last_period);
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

  # if there are any dates construct a where
  if ($form->{asofdate}) {
    
    $form->{this_period} = "$form->{asofdate}";
    $form->{period} = "$form->{asofdate}";
    
  }

  $form->{decimalplaces} *= 1;

  &get_accounts($dbh, $last_period, "", $form->{asofdate}, $form, \@categories, 1);
  
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

		if ($form->{l_subtotal} eq "bottom") {
			foreach $key (sort {
				($a =~ /^$b/) || ($b =~ /^$a/) ? (length($b) <=> length ($a)) : ($a cmp $b)
				} keys %{$form->{$category}}) {
				$account = $form->{l_heading} ? ($form->{padding} x length($key)) : "";
				if ($form->{$category}{$key}{charttype} eq "H") {
					next unless ($form->{l_heading});
					$account .= "$form->{bold}$form->{$category}{$key}{description}$form->{endbold}";
					$this = $form->{bold} . $form->format_amount ($myconfig, $form->{$category}{$key}{this} * $account{$category}{ml}, $form->{decimalplaces}, "- ") . $form->{endbold};
					$last = $form->{bold} . $form->format_amount ($myconfig, $form->{$category}{$key}{last} * $account{$category}{ml}, $form->{decimalplaces}, "- ") . $form->{endbold};
					}
				elsif ($form->{$category}{$key}{charttype} eq "A") {
					$account .= ($form->{l_accno}) ?
						"$form->{$category}{$key}{accno} - $form->{$category}{$key}{description}" :
						"$form->{$category}{$key}{description}";
					$form->{"total_$account{$category}{labels}_this_period"} += $form->{$category}{$key}{this} * $account{$category}{ml};
					$form->{"total_$account{$category}{labels}_last_period"} += $form->{$category}{$key}{last} * $account{$category}{ml} if ($last_period);
					$this = $form->format_amount ($myconfig, $form->{$category}{$key}{this} * $account{$category}{ml}, $form->{decimalplaces}, "- ");
					$last = $form->format_amount ($myconfig, $form->{$category}{$key}{last} * $account{$category}{ml}, $form->{decimalplaces}, "- ");
					}
				push (@{$form->{"$account{$category}{label}_account"}}, $account);
				push (@{$form->{"$account{$category}{label}_this_period"}}, $this);
				push (@{$form->{"$account{$category}{label}_last_period"}}, $last) if ($last_period);
				}
			}
		elsif ($form->{l_subtotal} eq "top") {
			foreach $key (sort { $a cmp $b } keys %{$form->{$category}}) {
				$account = $form->{l_heading} ? ($form->{padding} x length($key)) : "";
				if ($form->{$category}{$key}{charttype} eq "H") {
					next unless ($form->{l_heading});
					$account .= "$form->{bold}$form->{$category}{$key}{description}$form->{endbold}";
					$this = "";
					$last = "";
					}
				elsif ($form->{$category}{$key}{charttype} eq "A") {
					$account .= ($form->{l_accno}) ?
						"$form->{$category}{$key}{accno} - $form->{$category}{$key}{description}" :
						"$form->{$category}{$key}{description}";
					$this = $form->format_amount ($myconfig, $form->{$category}{$key}{this} * $account{$category}{ml}, $form->{decimalplaces}, "- ");
					$last = $form->format_amount ($myconfig, $form->{$category}{$key}{last} * $account{$category}{ml}, $form->{decimalplaces}, "- ");
					$form->{"total_$account{$category}{labels}_this_period"} += $form->{$category}{$key}{this} * $account{$category}{ml};
					$form->{"total_$account{$category}{labels}_last_period"} += $form->{$category}{$key}{last} * $account{$category}{ml} if ($last_period);
					}
				push (@{$form->{"$account{$category}{label}_account"}}, $account);
				push (@{$form->{"$account{$category}{label}_this_period"}}, $this);
				push (@{$form->{"$account{$category}{label}_last_period"}}, $last) if ($last_period);
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
      $subwhere .= " AND transdate >= '$fromdate'";
      $glwhere = " AND ac.transdate >= '$fromdate'";
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

		$query .= qq|UNION ALL
       
		SELECT g.accno AS accno, SUM(ac.sellprice * ac.qty) AS amount,
		 g.description AS description, 'E' AS category
		 FROM invoice ac
	         JOIN ap a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.inventory_accno_id = c.id)
		 JOIN gifi g ON (c.gifi_accno = g.accno)
	         $dpt_join
		 WHERE 1 = 1 $subwhere
	         $ywhere
		 AND c.category = 'A'
		 $dpt_where
		 $project
		 GROUP BY g.accno, g.description, c.category
		
		| if (!$project);

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
	         $ywhere
		 AND c.category = 'E'
		 $dpt_where
		 $project
		 GROUP BY g.accno, g.description, c.category

	UNION ALL
       
		SELECT g.accno AS accno, SUM(ac.sellprice * ac.qty) AS amount,
		 g.description AS description, 'E' AS category
		 FROM invoice ac
	         JOIN ap a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.inventory_accno_id = c.id)
		 JOIN gifi g ON (c.gifi_accno = g.accno)
	         $dpt_join
		 WHERE 1 = 1 $subwhere
	         $ywhere
		 AND c.category = 'A'
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
       
		 SELECT c.accno AS accno, SUM(ac.sellprice) AS amount,
		 c.description AS description, c.category
		 FROM invoice ac
	         JOIN ap a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.expense_accno_id = c.id)
	         $dpt_join
		 WHERE 1 = 1 $subwhere
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
       	
	$query .= qq|UNION ALL
       
		 SELECT c.accno AS accno, SUM(ac.sellprice * ac.qty) AS amount,
		 c.description AS description, 'E' AS category
		 FROM invoice ac
	         JOIN ap a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.inventory_accno_id = c.id)
	         $dpt_join
		 WHERE 1 = 1 $subwhere
	         $ywhere
		 AND c.category = 'A'
		 $dpt_where
		 $project
		 GROUP BY c.accno, c.description, c.category
		 | if (!$project);

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
	         $ywhere
		 AND c.category = 'E'
		 $dpt_where
		 $project
		 GROUP BY c.accno, c.description, c.category
	
	UNION ALL
       
		 SELECT c.accno AS accno, SUM(ac.sellprice * ac.qty) AS amount,
		 c.description AS description, 'E' AS category
		 FROM invoice ac
	         JOIN ap a ON (a.id = ac.trans_id)
		 JOIN parts p ON (ac.parts_id = p.id)
		 JOIN chart c on (p.inventory_accno_id = c.id)
	         $dpt_join
		 WHERE 1 = 1 $subwhere
	         $ywhere
		 AND c.category = 'A'
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

		# add subtotal
		@prefix_accounts = grep { ("$ref->{accno}" =~ /^$_./) && ($_ =~ /../) } @headingaccounts;
		foreach $accno (@prefix_accounts) {
			if ($last_period) {
				$form->{$ref->{category}}{$accno}{last} += $ref->{amount};
				}
			else {
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

#kabai
      $form->{all_accounts} = 1;
#kabai
      if (abs($ref->{amount}) >= 0.01 && $form->{all_accounts}) {
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
    $query = qq|SELECT DISTINCT g.accno, g.description, c.category
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

  if ($form->{accnofrom} || $form->{accnoto}) {
    if ($form->{accnofrom}) {
     ($accno_id, $null) = split /--/, $form->{accnofrom};
      $where .= " AND c.accno >= '$accno_id'";
      $invwhere .= " AND c.accno >= '$accno_id'";
    }
    if ($form->{accnoto}) {
     ($accno_id, $null) = split /--/, $form->{accnoto};
      $where .= " AND c.accno <= '$accno_id'";
      $invwhere .= " AND c.accno <= '$accno_id'";
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

	-- add project transactions from invoice
	
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
	
	        SELECT g.accno, g.description, c.category,
		SUM(ac.sellprice * ac.qty) AS amount
		FROM invoice ac
		JOIN ap a ON (ac.trans_id = a.id)
		JOIN parts p ON (ac.parts_id = p.id)
		JOIN chart c ON (p.expense_accno_id = c.id)
		JOIN gifi g ON (c.gifi_accno = g.accno)
		$dpt_join
		WHERE $invwhere
		$dpt_where
		$project
		GROUP BY g.accno, g.description, c.category
	
	UNION ALL
	
	        SELECT g.accno, g.description, c.category,
		SUM(ac.sellprice * ac.qty) AS amount
		FROM invoice ac
		JOIN ap a ON (ac.trans_id = a.id)
		JOIN parts p ON (ac.parts_id = p.id)
		JOIN chart c ON (p.inventory_accno_id = c.id)
		JOIN gifi g ON (c.gifi_accno = g.accno)
		$dpt_join
		WHERE $invwhere
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

	-- add project transactions from invoice
	
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
	
	        SELECT c.accno, c.description, c.category,
		SUM(ac.sellprice * ac.qty) AS amount
		FROM invoice ac
		JOIN ap a ON (ac.trans_id = a.id)
		JOIN parts p ON (ac.parts_id = p.id)
		JOIN chart c ON (p.expense_accno_id = c.id)
		$dpt_join
		WHERE $invwhere
		$dpt_where
		$project
		GROUP BY c.accno, c.description, c.category

	UNION ALL
	
	        SELECT c.accno, c.description, c.category,
		SUM(ac.sellprice * ac.qty) AS amount
		FROM invoice ac
		JOIN ap a ON (ac.trans_id = a.id)
		JOIN parts p ON (ac.parts_id = p.id)
		JOIN chart c ON (p.inventory_accno_id = c.id)
		$dpt_join
		WHERE $invwhere
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

  
  if ($project_id) {
    # prepare query for each account
    $query = qq|SELECT (SELECT SUM(ac.sellprice * ac.qty) * -1
	      FROM invoice ac
	      JOIN parts p ON (ac.parts_id = p.id)
	      JOIN ap a ON (ac.trans_id = a.id)
	      JOIN chart c ON (p.expense_accno_id = c.id)
	      $dpt_join
	      WHERE $invwhere
	      $dpt_where
	      $project
	      AND c.accno = ?) AS debit,

            (SELECT SUM(ac.sellprice * ac.qty)
	      FROM invoice ac
	      JOIN parts p ON (ac.parts_id = p.id)
	      JOIN ar a ON (ac.trans_id = a.id)
	      JOIN chart c ON (p.inventory_accno_id = c.id)
	      $dpt_join
	      WHERE $invwhere
	      $dpt_where
	      $project
	      AND c.accno = ?) AS debit_inv,
	      
	     (SELECT SUM(ac.sellprice * ac.qty)
	      FROM invoice ac
	      JOIN parts p ON (ac.parts_id = p.id)
	      JOIN ar a ON (ac.trans_id = a.id)
	      JOIN chart c ON (p.income_accno_id = c.id)
	      $dpt_join
	      WHERE $invwhere
	      $dpt_where
	      $project
	      AND c.accno = ?) AS credit
	      |;

   if ($form->{accounttype} eq 'gifi'){    
    $query = qq|SELECT (SELECT SUM(ac.sellprice * ac.qty) * -1
	      FROM invoice ac
	      JOIN parts p ON (ac.parts_id = p.id)
	      JOIN ap a ON (ac.trans_id = a.id)
	      JOIN chart c ON (p.expense_accno_id = c.id)
	      $dpt_join
	      WHERE $invwhere
	      $dpt_where
	      $project
	      AND c.gifi_accno = ?) AS debit,

            (SELECT SUM(ac.sellprice * ac.qty)
	      FROM invoice ac
	      JOIN parts p ON (ac.parts_id = p.id)
	      JOIN ar a ON (ac.trans_id = a.id)
	      JOIN chart c ON (p.inventory_accno_id = c.id)
	      $dpt_join
	      WHERE $invwhere
	      $dpt_where
	      $project
	      AND c.gifi_accno = ?) AS debit_inv,
	      
	     (SELECT SUM(ac.sellprice * ac.qty)
	      FROM invoice ac
	      JOIN parts p ON (ac.parts_id = p.id)
	      JOIN ar a ON (ac.trans_id = a.id)
	      JOIN chart c ON (p.income_accno_id = c.id)
	      $dpt_join
	      WHERE $invwhere
	      $dpt_where
	      $project
	      AND c.gifi_accno = ?) AS credit
	      |;
   }
    $project_drcr = $dbh->prepare($query);
  
  }
 
  # calculate the debit and credit in the period
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
      # get DR/CR
      $drcr->execute($ref->{accno}, $ref->{accno}) || $form->dberror($query);
      
      ($debit, $credit) = (0,0);
      while (($debit, $credit) = $drcr->fetchrow_array) {
	$ref->{debit} += $debit;
	$ref->{credit} += $credit;
      }
      $drcr->finish;

      if ($project_id) {
	# get DR/CR
	$project_drcr->execute($ref->{accno}, $ref->{accno}, $ref->{accno}) || $form->dberror($query);
	
	($debit, $credit) = (0,0);
	while (($debit, $debit_inv, $credit) = $project_drcr->fetchrow_array) {
	  $ref->{debit} += $debit ? $debit : $debit_inv;
	  $ref->{credit} += $credit;
	}
	$project_drcr->finish;
      }

      $ref->{debit} = $form->round_amount($ref->{debit}, 2);
      $ref->{credit} = $form->round_amount($ref->{credit}, 2);

    }

		# add subtotal
		if ($ref->{charttype} eq "A") {
			@prefix_accounts = grep { "$ref->{accno}" =~ /^$_./ } @headingaccounts;
			foreach my $accno (@prefix_accounts) {
				$trb{$accno}{debit} += $ref->{debit};
				$trb{$accno}{credit} += $ref->{credit};
				$trb{$accno}{balance} += $ref->{balance};
			}
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
        $ref->{balance} = $trb{$accno}{balance};
      }
    }
  }

}


sub aging {
# c1 c90 c180 c365 categories by sipi

  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $invoice = ($form->{arap} eq 'ar') ? 'is' : 'ir';
  
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
                        'c1' => "(date '$form->{todate}' - interval '1 days')",
                        'c10' => "(date '$form->{todate}' - interval '10 days')",
 			'c30' => "(date '$form->{todate}' - interval '30 days')",
 			'c60' => "(date '$form->{todate}' - interval '60 days')",
			'c90' => "(date '$form->{todate}' - interval '90 days')",
			'c180' => "(date '$form->{todate}' - interval '180 days')",
			'c365' => "(date '$form->{todate}' - interval '365 days')" },
 		  'DB2' => {
 		        'c1' => "(date ('$form->{todate}') - 1 days)",
                        'c10' => "(date ('$form->{todate}') - 10 days)",
 			'c30' => "(date ('$form->{todate}') - 30 days)",
 			'c60' => "(date ('$form->{todate}') - 60 days)",
			'c90' => "(date ('$form->{todate}') - 90 days)",
			'c180' => "(date ('$form->{todate}') - 180 days)",
			'c365' => "(date ('$form->{todate}') - 365 days)" }
 		);


  $interval{Oracle} = $interval{PgPP} = $interval{Pg};
  
		    
  # for each company that has some stuff outstanding
  my $id;
  while (($id, $null, $language_code) = $sth->fetchrow_array ) {
  
    $query = qq|
	SELECT $form->{ct}.id AS ctid, $form->{ct}.name,
	address1, address2, city, state, zipcode, country, contact, email,
	phone as customerphone, fax as customerfax, $form->{ct}number,
	invnumber, transdate, till,
	(amount - paid) as c1, 0.00 as c10, 0.00 as c30, 0.00 as c60, 0.00 as c90, 0.00 as c180, 0.00 as c365,
	duedate, invoice, $form->{arap}.id,
	  (SELECT $buysell FROM exchangerate
	   WHERE $form->{arap}.curr = exchangerate.curr
	   AND exchangerate.transdate = $form->{arap}.transdate) AS exchangerate
  FROM $form->{arap}, $form->{ct} 
	WHERE paid != amount
	AND $form->{arap}.$form->{ct}_id = $form->{ct}.id
	AND $form->{ct}.id = $id
	AND (
	        duedate <= $interval{$myconfig->{dbdriver}}{c1}
	        AND duedate >= $interval{$myconfig->{dbdriver}}{c10}
	    )
	
	UNION

	SELECT $form->{ct}.id AS ctid, $form->{ct}.name,
	address1, address2, city, state, zipcode, country, contact, email,
	phone as customerphone, fax as customerfax, $form->{ct}number,
	invnumber, transdate, till,
	0.00 as c1, (amount - paid) as c10, 0.00  as c30, 0.00 as c60, 0.00 as c90, 0.00 as c180, 0.00 as c365,
	duedate, invoice, $form->{arap}.id,
	  (SELECT $buysell FROM exchangerate
	   WHERE $form->{arap}.curr = exchangerate.curr
	   AND exchangerate.transdate = $form->{arap}.transdate) AS exchangerate
  FROM $form->{arap}, $form->{ct}
	WHERE paid != amount 
	AND $form->{arap}.$form->{ct}_id = $form->{ct}.id 
	AND $form->{ct}.id = $id
	AND (
	        duedate < $interval{$myconfig->{dbdriver}}{c10}
	        AND duedate >= $interval{$myconfig->{dbdriver}}{c30}
		)

	UNION

	SELECT $form->{ct}.id AS ctid, $form->{ct}.name,
	address1, address2, city, state, zipcode, country, contact, email,
	phone as customerphone, fax as customerfax, $form->{ct}number,
	invnumber, transdate, till,
	0.00 as c1, 0.00 as c10, (amount - paid) as c30, 0.00 as c60, 0.00 as c90, 0.00 as c180, 0.00 as c365,
	duedate, invoice, $form->{arap}.id,
	  (SELECT $buysell FROM exchangerate
	   WHERE $form->{arap}.curr = exchangerate.curr
	   AND exchangerate.transdate = $form->{arap}.transdate) AS exchangerate
  FROM $form->{arap}, $form->{ct}
	WHERE paid != amount 
	AND $form->{arap}.$form->{ct}_id = $form->{ct}.id 
	AND $form->{ct}.id = $id
	AND (
		duedate < $interval{$myconfig->{dbdriver}}{c30}
		AND duedate >= $interval{$myconfig->{dbdriver}}{c60}
		)

	UNION
  
	SELECT $form->{ct}.id AS ctid, $form->{ct}.name,
	address1, address2, city, state, zipcode, country, contact, email,
	phone as customerphone, fax as customerfax, $form->{ct}number,
	invnumber, transdate, till,
	0.00 as c1, 0.00 as c10, 0.00 as c30, (amount - paid) as c60, 0.00 as c90, 0.00 as c180, 0.00 as c365,
	duedate, invoice, $form->{arap}.id,
	  (SELECT $buysell FROM exchangerate
	   WHERE $form->{arap}.curr = exchangerate.curr
	   AND exchangerate.transdate = $form->{arap}.transdate) AS exchangerate
	FROM $form->{arap}, $form->{ct} 
	WHERE paid != amount
	AND $form->{arap}.$form->{ct}_id = $form->{ct}.id 
	AND $form->{ct}.id = $id
	AND (
		duedate < $interval{$myconfig->{dbdriver}}{c60}
		AND duedate >= $interval{$myconfig->{dbdriver}}{c90}
		)

	UNION
  
	SELECT $form->{ct}.id AS ctid, $form->{ct}.name,
	address1, address2, city, state, zipcode, country, contact, email,
	phone as customerphone, fax as customerfax, $form->{ct}number,
	invnumber, transdate, till,
	0.00 as c1, 0.00 as c10, 0.00 as c30, 0.00 as c60, (amount - paid) as c90, 0.00 as c180, 0.00 as c365,
	duedate, invoice, $form->{arap}.id,
	  (SELECT $buysell FROM exchangerate
	   WHERE $form->{arap}.curr = exchangerate.curr
	   AND exchangerate.transdate = $form->{arap}.transdate) AS exchangerate
	FROM $form->{arap}, $form->{ct} 
	WHERE paid != amount
	AND $form->{arap}.$form->{ct}_id = $form->{ct}.id 
	AND $form->{ct}.id = $id
	AND (
		duedate < $interval{$myconfig->{dbdriver}}{c90}
		AND duedate >= $interval{$myconfig->{dbdriver}}{c180}
		)

	UNION
  
	SELECT $form->{ct}.id AS ctid, $form->{ct}.name,
	address1, address2, city, state, zipcode, country, contact, email,
	phone as customerphone, fax as customerfax, $form->{ct}number,
	invnumber, transdate, till,
	0.00 as c1, 0.00 as c10, 0.00 as c30, 0.00 as c60, 0.00 as c90, (amount - paid) as c180, 0.00 as c365,
	duedate, invoice, $form->{arap}.id,
	  (SELECT $buysell FROM exchangerate
	   WHERE $form->{arap}.curr = exchangerate.curr
	   AND exchangerate.transdate = $form->{arap}.transdate) AS exchangerate
	FROM $form->{arap}, $form->{ct} 
	WHERE paid != amount
	AND $form->{arap}.$form->{ct}_id = $form->{ct}.id 
	AND $form->{ct}.id = $id
	AND (
		duedate < $interval{$myconfig->{dbdriver}}{c180}
		AND duedate >= $interval{$myconfig->{dbdriver}}{c365}
		)


	UNION
  
	SELECT $form->{ct}.id AS ctid, $form->{ct}.name,
	address1, address2, city, state, zipcode, country, contact, email,
	phone as customerphone, fax as customerfax, $form->{ct}number,
	invnumber, transdate, till,
	0.00 as c1, 0.00 as c10, 0.00 as c30, 0.00 as c60,  0.00 as c90, 0.00 as c180, (amount - paid) as c365,
	duedate, invoice, $form->{arap}.id,
	  (SELECT $buysell FROM exchangerate
	   WHERE $form->{arap}.curr = exchangerate.curr
	   AND exchangerate.transdate = $form->{arap}.transdate) AS exchangerate
	FROM $form->{arap}, $form->{ct} 
	WHERE paid != amount
	AND $form->{arap}.$form->{ct}_id = $form->{ct}.id 
	AND $form->{ct}.id = $id
	AND duedate < $interval{$myconfig->{dbdriver}}{c365}

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
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror;

  ($form->{$form->{ct}}, $form->{email}, $form->{cc}, $form->{bcc}) = $sth->fetchrow_array;
  $sth->finish;
  $dbh->disconnect;

}


sub get_taxaccounts {

  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  # get tax accounts
#kabai 1766
  my $query = qq|SELECT c.accno, c.description, t.rate, t.taxnumber
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
#kabai 1782 1788
 my $query = qq|SELECT DISTINCT g.accno, g.description,t.taxnumber,
                 sum(t.rate) AS rate
                 FROM gifi g, chart c, tax t
		 WHERE g.accno = c.gifi_accno
		 AND c.id = t.chart_id
		 AND c.link LIKE '%CT_tax%'
		 GROUP BY g.accno, g.description,t.taxnumber
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

  if ($department_id) {
    $where .= qq|
                 AND a.department_id = $department_id
		|;
  }
		 
  my ($accno, $rate);
  
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
#kabai
  $form->{report} = "zerotax" if ($rate == 0 && $form->{accno});
  $form->{report} = "nontaxable" if ($form->{accno} eq "nontaxable");
#kabai  

  my ($table, $ARAP);
  
  if ($form->{db} eq 'ar') {
    $table = "customer";
    $ARAP = "AR";
  }
  if ($form->{db} eq 'ap') {
    $table = "vendor";
    $ARAP = "AP";
  }

  my $transdate = "a.transdate";
  my $ordnumber = "a.ordnumber";
  
  if ($form->{method} eq 'cash') {
    $transdate = "a.datepaid";

    my $todate = ($form->{todate}) ? $form->{todate} : $form->current_date($myconfig);
    
    $where .= qq|
		 AND trans_id IN
		   (
		     SELECT trans_id
		     FROM acc_trans
		     JOIN chart ON (chart_id = id)
		     WHERE link LIKE '%${ARAP}_paid%'
		     AND transdate <= '$todate'
		   )
		  |;
  }

 
  # if there are any dates construct a where
  if ($form->{fromdate} || $form->{todate}) {
    if ($form->{fromdate}) {
      $where .= " AND $transdate >= '$form->{fromdate}'";
    }
    if ($form->{todate}) {
      $where .= " AND $transdate <= '$form->{todate}'";
    }
  }
  # if there are any ordnumber construct a where
  if ($form->{fromordnumber} || $form->{toordnumber}) {
    if ($form->{fromordnumber}) {
      $where .= " AND $ordnumber >= '$form->{fromordnumber}'";
    }
    if ($form->{toordnumber}) {
      $where .= " AND $ordnumber <= '$form->{toordnumber}'";
    }
  }
  if ($form->{db} eq 'ap'){
    $eva="a.eva, ";
    $evagl = qq|NULL as eva,|;
  }  
#kabai
   my $ml = ($form->{db} eq 'ar') ? 1 : -1;
   $whereapar = $where;
   if ($form->{accno} =~ /^gifi_/){
      $rate = "tax.rate";
      $where .= " AND tax.rate >= 0";      
      $gifizerotax = qq|
		UNION ALL
		SELECT a.id, '0' AS invoice, $transdate AS transdate,
		a.invnumber, a.ordnumber, n.name, n.taxnumber, a.notes, $eva
		ac.amount * $ml as netamount,NULL AS tax, a.till, 
		(SELECT MAX(ch2.id) from ap a2 JOIN acc_trans ac2 ON (ac2.trans_id=a.id)
	        JOIN chart ch2 ON (ac2.chart_id=ch2.id) WHERE link LIKE '%ASSET%') AS link,
		0 AS taxrate
		FROM acc_trans ac
	        JOIN $form->{db} a ON (a.id = ac.trans_id)
	        JOIN $table n ON (n.id = a.${table}_id)
		WHERE $whereapar
		AND a.invoice = '0'
		AND ac.taxbase = '0.00'
		AND 
		  a.${table}_id IN (
		        SELECT ${table}_id FROM ${table}tax t 
			JOIN chart ch ON (ch.id = t.chart_id)
			WHERE 1=1 $accno
			               )

	        UNION ALL
	        SELECT a.id, '1' AS invoice, $transdate AS transdate,
	        a.invnumber, a.ordnumber, n.name, n.taxnumber, a.notes, $eva
	        i.sellprice * i.qty * $ml AS netamount, NULL AS tax, a.till,NULL AS link, 0 AS taxrate
	        FROM invoice i
	        JOIN $form->{db} a ON (a.id = i.trans_id)
	        JOIN $table n ON (n.id = a.${table}_id)
	        JOIN partstax pt ON (i.parts_id=pt.parts_id)
	        JOIN chart ch ON (ch.id=pt.chart_id)
	        JOIN tax ON (tax.chart_id=ch.id)
                JOIN ${table}tax t ON (t.${table}_id = n.id AND t.chart_id = ch.id)
 	        WHERE $whereapar AND tax.rate = 0
	        $accno
	        AND a.invoice = '1'
			|;
   }else{
      $where .= " AND tax.rate = $rate";
   }
#kabai      

  my %ordinal = ( 'transdate' => 3,
                  'invnumber' => 4,
                  'ordnumber' => 5,
		  'name' => 6
		);
  
  my @a = qw(transdate invnumber ordnumber name);
  my $sortorder = $form->sort_order(\@a, \%ordinal);
 
 my $glunion = qq|UNION ALL
		  SELECT gl.id, FALSE AS invoice, a.transdate,
		  reference, '' AS ordnumber, '' AS name, '' AS taxnumber, gl.description, $evagl
		  a.amount * $ml / $rate AS netamount,
		  a.amount * $ml AS tax, '' AS till, NULL AS link, tax.rate AS taxrate
		  FROM acc_trans a
		  JOIN gl ON (gl.id = a.trans_id)
		  JOIN chart ch ON (ch.id = a.chart_id)
		  JOIN tax ON (a.chart_id = tax.chart_id)
		  WHERE $where
		  $accno		  
		 | if $form->{gl_included};
  $query = qq|SELECT a.id, invoice, $transdate AS transdate,
              a.invnumber, a.ordnumber, n.name, n.taxnumber, a.notes, $eva
	      ac.amount * $ml / $rate AS netamount,
	      ac.amount * $ml AS tax, a.till, (SELECT MAX(ch2.id) from ap a2 JOIN acc_trans ac2 ON (ac2.trans_id=a.id)
	       JOIN chart ch2 ON (ac2.chart_id=ch2.id) WHERE link LIKE '%ASSET%') AS link, tax.rate AS taxrate
              FROM acc_trans ac
	    JOIN $form->{db} a ON (a.id = ac.trans_id) 
	    JOIN chart ch ON (ch.id = ac.chart_id)
	    JOIN $table n ON (n.id = a.${table}_id)
            JOIN tax ON (ac.chart_id = tax.chart_id)
	      WHERE $where
	      $accno
	      $glunion
	      $gifizerotax
	      ORDER by $sortorder|;

  if ($form->{report} =~ /nontaxable/) {
    # only gather up non-taxable transactions
#kabai +9
    $query = qq|SELECT a.id, '0' AS invoice, $transdate AS transdate,
		a.invnumber, a.ordnumber, n.name, n.taxnumber, a.notes, a.netamount, a.till, '' AS taxrate
		FROM acc_trans ac
	      JOIN $form->{db} a ON (a.id = ac.trans_id)
	      JOIN $table n ON (n.id = a.${table}_id)
		WHERE $whereapar
		AND a.invoice = '0'
		AND a.netamount = a.amount
		AND 
		  a.${table}_id NOT IN (
		        SELECT ${table}_id FROM ${table}tax t (${table}_id)
			               )
	      UNION ALL
		SELECT a.id, '1' AS invoice, $transdate AS transdate,
		a.invnumber, a.ordnumber, n.name, n.taxnumber, a.notes, i.sellprice * i.qty * $ml AS netamount,
		a.till, '' AS taxrate
		FROM acc_trans ac
	      JOIN $form->{db} a ON (a.id = ac.trans_id)
	      JOIN $table n ON (n.id = a.${table}_id)
	      JOIN invoice i ON (i.trans_id = a.id)
		WHERE $whereapar
		AND a.invoice = '1'
		AND (
		  a.${table}_id NOT IN (
		        SELECT ${table}_id FROM ${table}tax t (${table}_id)
			               ) OR
	          i.parts_id NOT IN (
		        SELECT parts_id FROM partstax p (parts_id)
			            )
		    )
		GROUP BY a.id, a.invnumber, a.ordnumber, $transdate, n.name, n.taxnumber, a.notes, i.sellprice, i.qty, a.till, taxrate
		ORDER by $sortorder|;
  }
#kabai
  if ($form->{report} =~ /zerotax/) {
    # only gather up  transactions with zerotax
    $query = qq|SELECT a.id, '0' AS invoice, $transdate AS transdate,
		a.invnumber, a.ordnumber, n.name, n.taxnumber, a.notes, ac.amount * $ml as netamount, a.till, 0 AS taxrate
		FROM acc_trans ac
	      JOIN $form->{db} a ON (a.id = ac.trans_id)
	      JOIN $table n ON (n.id = a.${table}_id)
		WHERE $whereapar
		AND a.invoice = '0'
		AND ac.taxbase = '0.00'
		AND 
		  a.${table}_id IN (
		        SELECT ${table}_id FROM ${table}tax t 
			JOIN chart ch ON (ch.id = t.chart_id)
			WHERE 1=1 $accno
			               )

	      UNION ALL
	      SELECT a.id, '1' AS invoice, $transdate AS transdate,
	      a.invnumber, a.ordnumber, n.name, n.taxnumber, a.notes,
	      i.sellprice * i.qty * $ml AS netamount,a.till, $rate AS taxrate
	      FROM invoice i
	      JOIN $form->{db} a ON (a.id = i.trans_id)
	      JOIN $table n ON (n.id = a.${table}_id)
	      JOIN partstax pt ON (i.parts_id=pt.parts_id)
	      JOIN chart ch ON (ch.id=pt.chart_id)
	      JOIN tax ON (tax.chart_id=ch.id)
              JOIN ${table}tax t ON (t.${table}_id = n.id AND t.chart_id = ch.id)
 	      WHERE $where
	      $accno
	      AND a.invoice = '1'
	      ORDER by $sortorder|;
  }

#kabai
my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ( my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{TR} }, $ref;
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
  $dbh->disconnect;

}

sub paymentaccounts2 { #kabai can be limited to Petty cash/Bank accounts
  my ($self, $myconfig, $form) = @_;
 
  # connect to database, turn AutoCommit off
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $ARAP = uc $form->{db};

  my $cashbank = $form->{cash} ? "pcash" : "bank";
  
  # get A(R|P)_paid accounts
  my $query = qq|SELECT accno, description
                 FROM chart
                 WHERE link LIKE '%${ARAP}_paid%'
		 AND ptype = '$cashbank'
		 ORDER BY accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
 
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{PR} }, $ref;
  }

  $sth->finish;
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
                ac.source, ac.memo, e.name AS employee, a.till, a.id, '$form->{db}' AS db,
		a.invoice
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
		e.name, a.till, a.id, db, a.invoice
		|;
		
    if (! $form->{till}) {
# don't need gl for a till
      
      $query .= qq|
 	UNION
		SELECT g.notes, ac.transdate, sum(ac.amount) * $ml AS paid, ac.source,
		g.description, e.name AS employee, '' AS till, g.id, 'gl' AS db, FALSE AS invoice
		FROM acc_trans ac
	        JOIN gl g ON (g.id = ac.trans_id)
		LEFT JOIN employee e ON (g.employee_id = e.id)
	        $dpt_join
		WHERE ac.chart_id = $ref->{id}
		$glwhere
		AND (ac.amount * $ml) > 0
	GROUP BY g.notes, ac.transdate, ac.source, g.description, e.name, g.id, db, invoice
		|;

    }

    $query .= qq|
                ORDER BY $sortorder|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $query = qq|SELECT amount, memo, taxbase
	       FROM acc_trans a, chart c WHERE
	       a.chart_id = c.id AND c.link='AP_amount'
	       AND a.trans_id = ? |;
    $wth = $dbh->prepare($query) || $form->dberror($query);

    while (my $pr = $sth->fetchrow_hashref(NAME_lc)) {
      $wth->execute($pr->{id});
     while (my $vm = $wth->fetchrow_hashref(NAME_lc)) {
      $pr->{amount} .= $vm->{amount}*-1 . "::";
      $pr->{vmemo} .= $vm->{memo}. "::";
      $pr->{taxbase} .= $vm->{taxbase}. "::";
     }
     $wth->finish;
    
    push @{ $form->{$ref->{id}} }, $pr;
    }
    $sth->finish;
#kabai
    $query = qq | SELECT vcurr FROM regnum WHERE chart_id = $ref->{id} LIMIT 1|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    ($form->{"vcurr_$accno"}) = $sth->fetchrow_array;
    $sth->finish;
#kabai    
  }
  $dbh->disconnect;
  
}

sub project_report {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $where="1=1" ;
  $where.=qq| AND p.projectnumber LIKE '%|.$form->{projectnumber}.qq|%'| if $form->{projectnumber};
  $where .= " AND a.transdate >= '$form->{fromdate}'" if $form->{fromdate};
  $where .= " AND a.transdate <= '$form->{todate}'" if $form->{todate};

  my $query =qq| SELECT 'ar' AS tip, a.id, a.transdate, p.projectnumber, a.invnumber, c.name AS customer,
		 '' AS vendor, 0 AS netcost, ac.amount AS netincome, ch.accno, ch.description
		 FROM project p 
		 JOIN acc_trans ac ON (p.id=ac.project_id) 
		 JOIN ar a  ON (a.id=ac.trans_id) 
		 JOIN customer c ON (c.id=a.customer_id) 
		 JOIN chart ch ON (ch.id=ac.chart_id)
		 WHERE $where
	   UNION ALL
		 SELECT 'is' AS tip, a.id, a.transdate, p.projectnumber, a.invnumber, c.name AS customer,
		 '' AS vendor, 0 AS netcost, i.sellprice * i.qty AS netincome,
		 (SELECT accno FROM chart WHERE chart.id=income_accno_id) AS accno,
		 (SELECT description FROM chart WHERE chart.id=income_accno_id) AS description
		 FROM project p
		 JOIN invoice i ON (p.id=i.project_id) 
		 JOIN ar a  ON (a.id=i.trans_id) 
		 JOIN customer c ON (c.id=a.customer_id) 
		 JOIN parts pa ON (pa.id=i.parts_id)
		 WHERE $where
           UNION ALL
    		SELECT 'ap' AS tip, a.id, a.transdate, p.projectnumber, a.invnumber, '' AS customer,
		v.name, ac.amount*-1 AS netcost, 0 AS netincome, ch.accno, ch.description
    		FROM project p 
		JOIN acc_trans ac ON (p.id=ac.project_id) 
		JOIN ap a ON(a.id=ac.trans_id) 
		JOIN vendor v ON (v.id=a.vendor_id) 
		JOIN chart ch ON (ch.id=ac.chart_id)
		WHERE $where 
	   UNION ALL
		 SELECT 'ir' AS tip, a.id, a.transdate, p.projectnumber, a.invnumber, '' AS customer,
		 v.name, i.sellprice * i.qty*-1 AS netcost, 0 AS netincome, 
		 CASE WHEN inventory_accno_id IS NOT NULL THEN (SELECT accno FROM chart WHERE chart.id=inventory_accno_id)
		 ELSE (SELECT accno FROM chart WHERE chart.id=expense_accno_id) END AS accno,
		 CASE WHEN inventory_accno_id IS NOT NULL THEN (SELECT description FROM chart WHERE chart.id=inventory_accno_id)
		 ELSE (SELECT description FROM chart WHERE chart.id=expense_accno_id) END AS description
		 FROM project p
		 JOIN invoice i ON (p.id=i.project_id) 
		 JOIN ap a  ON (a.id=i.trans_id) 
		 JOIN vendor v ON (v.id=a.vendor_id) 
		 JOIN parts pa ON (pa.id=i.parts_id)
		 WHERE $where
		|;

  my %ordinal = ( 'transdate' => 3,
            'projectnumber' => 4,
            'invnumber' => 5,
	    'customer' => 6,
            'vendor' => 7,
        );
                                
                my @a = (transdate, projectnumber, invnumber, customer, vendor);
                my $sortorder = $form->sort_order(\@a, \%ordinal);
                $query.=qq| ORDER BY $sortorder|;

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


