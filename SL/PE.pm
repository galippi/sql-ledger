#=====================================================================
# SQL-Ledger Accounting
# Copyright (C) 1998-2002
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
# Project module
# also used for partsgroups
#
#======================================================================

package PE;


sub projects {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $sortorder = ($form->{sort}) ? $form->{sort} : "projectnumber";

  my $query = qq|SELECT id, projectnumber, description
                 FROM project
		 WHERE 1 = 1|;

  if ($form->{projectnumber}) {
    my $projectnumber = $form->like(lc $form->{projectnumber});
    $query .= " AND lower(projectnumber) LIKE '$projectnumber'";
  }
  if ($form->{projectdescription}) {
    my $description = $form->like(lc $form->{projectdescription});
    $query .= " AND lower(description) LIKE '$description'";
  }
  if ($form->{status} eq 'orphaned') {
    $query .= " AND id NOT IN (SELECT p.id
                               FROM project p, acc_trans a
			       WHERE p.id = a.project_id)
                AND id NOT IN (SELECT p.id
		               FROM project p, invoice i
			       WHERE p.id = i.project_id)
		AND id NOT IN (SELECT p.id
		               FROM project p, orderitems o
			       WHERE p.id = o.project_id)";
  }

  $query .= qq|
		 ORDER BY $sortorder|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $i = 0;
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{project_list} }, $ref;
    $i++;
  }

  $sth->finish;
  $dbh->disconnect;
  
  $i;

}


sub get_project {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT *
                 FROM project
	         WHERE id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
  
  map { $form->{$_} = $ref->{$_} } keys %$ref;

  $sth->finish;

  # check if it is orphaned
  $query = qq|SELECT count(*)
              FROM acc_trans
	      WHERE project_id = $form->{id}|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  ($form->{orphaned}) = $sth->fetchrow_array;
  $form->{orphaned} = !$form->{orphaned};
       
  $sth->finish;
  
  $dbh->disconnect;

}


sub save_project {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  map { $form->{$_} =~ s/'/''/g } (projectnumber, description);

  if ($form->{id}) {
    $query = qq|UPDATE project SET
                projectnumber = '$form->{projectnumber}',
		description = '$form->{description}'
		WHERE id = $form->{id}|;
  } else {
    $query = qq|INSERT INTO project
                (projectnumber, description)
                VALUES ('$form->{projectnumber}', '$form->{description}')|;
  }
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}


sub partsgroups {
  my ($self, $myconfig, $form) = @_;
  
  my $var;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $sortorder = ($form->{sort}) ? $form->{sort} : "partsgroup";

  my $query = qq|SELECT g.*
                 FROM partsgroup g|;

  my $where = "1 = 1";
  
  if ($form->{partsgroup}) {
    $var = $form->like(lc $form->{partsgroup});
    $where .= " AND lower(partsgroup) LIKE '$var'";
  }
  $query .= qq|
               WHERE $where
	       ORDER BY $sortorder|;
  
  if ($form->{status} eq 'orphaned') {
    $query = qq|SELECT g.*
                FROM partsgroup g
                LEFT JOIN parts p ON (p.partsgroup_id = g.id)
		WHERE $where
                EXCEPT
                SELECT g.*
	        FROM partsgroup g
	        JOIN parts p ON (p.partsgroup_id = g.id)
	        WHERE $where
		ORDER BY $sortorder|;
  }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $i = 0;
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{item_list} }, $ref;
    $i++;
  }

  $sth->finish;
  $dbh->disconnect;
  
  $i;

}


sub save_partsgroup {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  map { $form->{$_} =~ s/'/''/g } (partsgroup);


  if ($form->{id}) {
    $query = qq|UPDATE partsgroup SET
                partsgroup = '$form->{partsgroup}'
		WHERE id = $form->{id}|;
  } else {
    $query = qq|INSERT INTO partsgroup
                (partsgroup)
                VALUES ('$form->{partsgroup}')|;
  }
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}


sub get_partsgroup {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT *
                 FROM partsgroup
	         WHERE id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
 
  map { $form->{$_} = $ref->{$_} } keys %$ref;

  $sth->finish;

  # check if it is orphaned
  $query = qq|SELECT count(*)
              FROM parts
	      WHERE partsgroup_id = $form->{id}|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  ($form->{orphaned}) = $sth->fetchrow_array;
  $form->{orphaned} = !$form->{orphaned};
       
  $sth->finish;
  
  $dbh->disconnect;

}



sub delete_tuple {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  $query = qq|DELETE FROM $form->{type}
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $dbh->disconnect;

}



1;

