#=====================================================================
# SQL-Ledger Accounting
# Copyright (c) 1998-2002
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#
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
# project administration
# partsgroup administration
#
#======================================================================


use SL::PE;

1;
# end of main



sub add {
  
  $form->{title} = "Add";

  # construct callback
  $form->{callback} = "$form->{script}?action=add&type=$form->{type}&path=$form->{path}&login=$form->{login}&password=$form->{password}" unless $form->{callback};

  &{ "form_$form->{type}_header" };
  &{ "form_$form->{type}_footer" };
  
}


sub edit {
  
  $form->{title} = "Edit";

  if ($form->{type} eq 'project') {
    PE->get_project(\%myconfig, \%$form);
  }
  if ($form->{type} eq 'partsgroup') {
    PE->get_partsgroup(\%myconfig, \%$form);
  }

  &{ "form_$form->{type}_header" };
  &{ "form_$form->{type}_footer" };
  
}


sub search {

  if ($form->{type} eq 'project') {
    $report = "project_report";
    $sort = 'projectnumber';
    $form->{title} = $locale->text('Projects');

    $number = qq|
	<tr>
	  <th align=right width=1%>|.$locale->text('Number').qq|</th>
	  <td><input name=projectnumber size=20></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td><input name=description size=60></td>
	</tr>
|;

  }
  if ($form->{type} eq 'partsgroup') {
    $report = "partsgroup_report";
    $sort = 'partsgroup';
    $form->{title} = $locale->text('Groups');
    
    $number = qq|
	<tr>
	  <th align=right width=1%>|.$locale->text('Group').qq|</th>
	  <td><input name=partsgroup size=20></td>
	</tr>
|;

  }

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=sort value=$sort>
<input type=hidden name=type value=$form->{type}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        $number
	<tr>
	  <td></td>
	  <td><input name=status class=radio type=radio value=all checked>&nbsp;|.$locale->text('All').qq|
	  <input name=status class=radio type=radio value=orphaned>&nbsp;|.$locale->text('Orphaned').qq|</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=nextsub value=$report>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=password value=$form->{password}>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}



sub project_report {

  map { $form->{$_} = $form->unescape($form->{$_}) } (projectnumber, description);
  PE->projects(\%myconfig, \%$form);

  $callback = "$form->{script}?action=project_report&type=$form->{type}&path=$form->{path}&login=$form->{login}&password=$form->{password}&status=$form->{status}";
  $href = $callback;
  
  if ($form->{status} eq 'all') {
    $option = $locale->text('All');
  }
  if ($form->{status} eq 'orphaned') {
    $option .= $locale->text('Orphaned');
  }
  if ($form->{projectnumber}) {
    $href .= "&projectnumber=".$form->escape($form->{projectnumber});
    $callback .= "&projectnumber=$form->{projectnumber}";
    $option .= "\n<br>".$locale->text('Project')." : $form->{projectnumber}";
  }
  if ($form->{description}) {
    $href .= "&description=".$form->escape($form->{description});
    $callback .= "&description=$form->{description}";
    $option .= "\n<br>".$locale->text('Description')." : $form->{description}";
  }
    

  @column_index = $form->sort_columns(qw(projectnumber description));

  $column_header{projectnumber} = qq|<th><a class=listheading href=$href&sort=projectnumber>|.$locale->text('Number').qq|</a></th>|;
  $column_header{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;

  $form->{title} = $locale->text('Projects');

  $form->header;
 
  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
|;

  map { print "$column_header{$_}\n" } @column_index;
  
  print qq|
        </tr>
|;

  # escape callback
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);
  
  foreach $ref (@{ $form->{project_list} }) {
    
    $i++; $i %= 2;
    
    print qq|
        <tr valign=top class=listrow$i>
|;
    
    $column_data{projectnumber} = qq|<td><a href=$form->{script}?action=edit&type=$form->{type}&status=$form->{status}&id=$ref->{id}&path=$form->{path}&login=$form->{login}&password=$form->{password}&callback=$callback>$ref->{projectnumber}</td>|;
    $column_data{description} = qq|<td>$ref->{description}&nbsp;</td>|;
    
    map { print "$column_data{$_}\n" } @column_index;
    
    print "
        </tr>
";
  }
  
  $i = 1;
  if ($myconfig{acs} !~ /Projects--Projects/) {
    $button{'Projects--Add Project'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Project').qq|"> |;
    $button{'Projects--Add Project'}{order} = $i++;

    foreach $item (split /;/, $myconfig{acs}) {
      delete $button{$item};
    }
  }
  
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<form method=post action=$form->{script}>

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=type value=$form->{type}>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=password value=$form->{password}>
|;

  foreach $item (sort { $a->{order} <=> $b->{order} } %button) {
    print $item->{code};
  }

  print qq|
</form>

</body>
</html>
|;

}


sub form_project_header {

  $form->{title} = $locale->text("$form->{title} Project");
  
# $locale->text('Add Project')
# $locale->text('Edit Project')

  $form->{description} =~ s/"/&quot;/g;

  if (($rows = $form->numtextrows($form->{description}, 60)) > 1) {
    $description = qq|<textarea name="description" rows=$rows cols=60 style="width: 100%" wrap=soft>$form->{description}</textarea>|;
  } else {
    $description = qq|<input name=description size=60 value="$form->{description}">|;
  }
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=project>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Number').qq|</th>
	  <td><input name=projectnumber size=20 value="$form->{projectnumber}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td>$description</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub form_project_footer {

  print qq|

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=password value=$form->{password}>
<br>
|;

  if ($myconfig{acs} !~ /Projects--Add Project/) {
    print qq|
<input type=submit class=submit name=action value="|.$locale->text('Save').qq|">
|;

    if ($form->{id} && $form->{orphaned}) {
      print qq|
<input type=submit class=submit name=action value="|.$locale->text('Delete').qq|">|;
    }
  }

  print qq|
</form>

</body>
</html>
|;

}


sub save {

  if ($form->{type} eq 'project') {
    $form->isblank("projectnumber", $locale->text('Project Number missing!'));
    PE->save_project(\%myconfig, \%$form);
    $form->redirect($locale->text('Project saved!'));
  }
  if ($form->{type} eq 'partsgroup') {
    $form->isblank("partsgroup", $locale->text('Group missing!'));
    PE->save_partsgroup(\%myconfig, \%$form);
    $form->redirect($locale->text('Group saved!'));
  }

}


sub delete {

  PE->delete_tuple(\%myconfig, \%$form);
  
  if ($form->{type} eq 'project') { 
    $form->redirect($locale->text('Project deleted!'));
  }
  if ($form->{type} eq 'partsgroup') {
    $form->redirect($locale->text('Group deleted!'));
  }

}


sub continue { &{ $form->{nextsub} } };


sub partsgroup_report {

  map { $form->{$_} = $form->unescape($form->{$_}) } (partsgroup);
  PE->partsgroups(\%myconfig, \%$form);

  $callback = "$form->{script}?action=partsgroup_report&type=$form->{type}&path=$form->{path}&login=$form->{login}&password=$form->{password}&status=$form->{status}";
  
  if ($form->{status} eq 'all') {
    $option = $locale->text('All');
  }
  if ($form->{status} eq 'orphaned') {
    $option .= $locale->text('Orphaned');
  }
  if ($form->{partsgroup}) {
    $callback .= "&partsgroup=$form->{partsgroup}";
    $option .= "\n<br>".$locale->text('Group')." : $form->{partsgroup}";
  }
   

  @column_index = (partsgroup);

  $column_header{partsgroup} = qq|<th class=listheading width=90%>|.$locale->text('Group').qq|</th>|;

  $form->{title} = $locale->text('Groups');

  $form->header;
 
  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
|;

  map { print "$column_header{$_}\n" } @column_index;
  
  print qq|
        </tr>
|;

  # escape callback
  $form->{callback} = $callback;

  # escape callback for href
  $callback = $form->escape($callback);
  
  foreach $ref (@{ $form->{item_list} }) {
    
    $i++; $i %= 2;
    
    print qq|
        <tr valign=top class=listrow$i>
|;
    

    $column_data{partsgroup} = qq|<td><a href=$form->{script}?action=edit&type=$form->{type}&status=$form->{status}&id=$ref->{id}&path=$form->{path}&login=$form->{login}&password=$form->{password}&callback=$callback>$ref->{partsgroup}</td>|;
    
    map { print "$column_data{$_}\n" } @column_index;
    
    print "
        </tr>
";
  }
  
  $i = 1;
  if ($myconfig{acs} !~ /Goods \& Services--Goods \& Services/) { 
    $button{'Goods & Services--Add Group'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Group').qq|"> |;
    $button{'Goods & Services--Add Group'}{order} = $i++;

    foreach $item (split /;/, $myconfig{acs}) {
      delete $button{$item};
    }
  }
  
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<form method=post action=$form->{script}>

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=type value=$form->{type}>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=password value=$form->{password}>
|;

  foreach $item (sort { $a->{order} <=> $b->{order} } %button) {
    print $item->{code};
  }

  print qq|
</form>

</body>
</html>
|;

}


sub form_partsgroup_header {

  $form->{title} = $locale->text("$form->{title} Group");
  
# $locale->text('Add Group')
# $locale->text('Edit Group')

  $form->{partsgroup} =~ s/"/&quot;/g;

  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=$form->{type}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th align=right>|.$locale->text('Group').qq|</th>
          <td><input name=partsgroup size=30 value="$form->{partsgroup}"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub form_partsgroup_footer {

  print qq|

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=password value=$form->{password}>
<br>
|;

  if ($myconfig{acs} !~ /Goods \& Services--Add Group/) {
    print qq|
<input type=submit class=submit name=action value="|.$locale->text('Save').qq|">
|;

    if ($form->{id} && $form->{orphaned}) {
      print qq|
<input type=submit class=submit name=action value="|.$locale->text('Delete').qq|">|;
    }
  }

  print qq|
</form>

</body>
</html>
|;

}


sub add_group { &add };
sub add_project { &add };

