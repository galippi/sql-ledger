#=====================================================================
# SQL-Ledger Accounting
# Copyright (c) 2002
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
# common routines for gl, ar, ap, is, ir, oe
#

# any custom scripts for this one
if (-f "$form->{path}/custom_arap.pl") {
  eval { require "$form->{path}/custom_arap.pl"; };
}
if (-f "$form->{path}/$form->{login}_arap.pl") {
  eval { require "$form->{path}/$form->{login}_arap.pl"; };
}


1;
# end of main


sub check_name {
  my ($name) = @_;

  my ($new_name, $new_id) = split /--/, $form->{$name};
  my $i = 0;
  
  # if we use a selection
  if ($form->{"select$name"}) {
    if ($form->{"old$name"} ne $form->{$name}) {
      # this is needed for is, ir and oe
      map { delete $form->{"${_}_rate"} } (split / /, $form->{taxaccounts});
      
      # for credit calculations
      $form->{oldinvtotal} = 0;
      $form->{oldtotalpaid} = 0;
      
      $form->{"${name}_id"} = $new_id;
      $form->{"old$name"} = "$new_name--$new_id";

      IS->get_customer(\%myconfig, \%$form) if ($name eq 'customer');
      IR->get_vendor(\%myconfig, \%$form) if ($name eq 'vendor');

      $i = 1;
    }
  } else {

    # check name, combine name and id
    if ($form->{"old$name"} ne qq|$form->{$name}--$form->{"${name}_id"}|) {
      # this is needed for is, ir and oe
      map { delete $form->{"${_}_rate"} } (split / /, $form->{taxaccounts});

      # for credit calculations
      $form->{oldinvtotal} = 0;
      $form->{oldtotalpaid} = 0;

      # return one name or a list of names in $form->{name_list}
      if (($i = $form->get_name(\%myconfig, $name)) > 1) {
	&select_name($name);
	exit;
      }

      if ($i == 1) {
	# we got one name
	$form->{"${name}_id"} = $form->{name_list}[0]->{id};
	$form->{$name} = $form->{name_list}[0]->{name};
	$form->{"old$name"} = qq|$form->{$name}--$form->{"${name}_id"}|;
	
	IS->get_customer(\%myconfig, \%$form) if ($name eq 'customer');
	IR->get_vendor(\%myconfig, \%$form) if ($name eq 'vendor');
	
      } else {
	# name is not on file
	$msg = ucfirst $name . " not on file!";
	$form->error($locale->text($msg));
      }
    }
  }

  $i;

}

# $locale->text('Customer not on file!')
# $locale->text('Vendor not on file!')



sub select_name {
  my ($table) = @_;
  
  @column_index = qw(ndx name address);

  $label = ucfirst $table;
  $column_data{ndx} = qq|<th>&nbsp;</th>|;
  $column_data{name} = qq|<th>|.$locale->text($label).qq|</th>|;
  $column_data{address} = qq|<th>|.$locale->text('Address').qq|</th>|;
  
  # list items with radio button on a form
  $form->header;

  $title = $locale->text('Select from one of the names below');

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$title</th>
  </tr>
  <tr space=5></tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  map { print "\n$column_data{$_}" } @column_index;
  
  print qq|
	</tr>
|;

  my $i = 0;
  foreach $ref (@{ $form->{name_list} }) {
    $checked = ($i++) ? "" : "checked";

    $ref->{name} =~ s/"/&quot;/g;
    
   $column_data{ndx} = qq|<td><input name=ndx class=radio type=radio value=$i $checked></td>|;
   $column_data{name} = qq|<td><input name="new_name_$i" type=hidden value="$ref->{name}">$ref->{name}</td>|;
   $column_data{address} = qq|<td>$ref->{address}</td>|;
    
    $j++; $j %= 2;
    print qq|
	<tr class=listrow$j>|;

    map { print "\n$column_data{$_}" } @column_index;

    print qq|
	</tr>

<input name="new_id_$i" type=hidden value=$ref->{id}>

|;

  }
  
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input name=lastndx type=hidden value=$i>

|;

  # delete action variable
  delete $form->{action};
  delete $form->{name_list};
    
  # save all other form variables
  foreach $key (keys %${form}) {
    $form->{$key} =~ s/"/&quot;/g;
    print qq|<input name=$key type=hidden value="$form->{$key}">\n|;
  }

  print qq|
<input type=hidden name=nextsub value=name_selected>

<input type=hidden name=vc value=$table>
<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}



sub name_selected {

  # replace the variable with the one checked

  # index for new item
  $i = $form->{ndx};
  
  $form->{$form->{vc}} = $form->{"new_name_$i"};
  $form->{"$form->{vc}_id"} = $form->{"new_id_$i"};
  $form->{"old$form->{vc}"} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;

  # delete all the new_ variables
  for $i (1 .. $form->{lastndx}) {
    map { delete $form->{"new_${_}_$i"} } (id, name);
  }
  
  map { delete $form->{$_} } qw(ndx lastndx nextsub);

  IS->get_customer(\%myconfig, \%$form) if ($form->{vc} eq 'customer');
  IR->get_vendor(\%myconfig, \%$form) if ($form->{vc} eq 'vendor');

  &update(1);

}


sub add_transaction {
  my ($module) = @_;

  delete $form->{script};
  $form->{action} = "add";
  $form->{type} = "invoice" if $module =~ /(is|ir)/;

  $form->{callback} = $form->escape($form->{callback},1);
  map { $argv .= "$_=$form->{$_}&" } keys %$form;

  exec ("perl", "$module.pl", $argv);

}


sub continue { &{ $form->{nextsub} } };
sub gl_transaction { &add };
sub ar_transaction { &add_transaction(ar) };
sub ap_transaction { &add_transaction(ap) };
sub sales_invoice { &add_transaction(is) };
sub vendor_invoice { &add_transaction(ir) };

