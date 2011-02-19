######################################################################
# SQL-Ledger, Accounting
# Copyright (c) 2002
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
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
#######################################################################
#
# common routines used in is, ir, oe
#
#######################################################################

# any custom scripts for this one
if (-f "$form->{path}/custom_io.pl") {
  eval { require "$form->{path}/custom_io.pl"; };
}
if (-f "$form->{path}/$form->{login}_io.pl") {
  eval { require "$form->{path}/$form->{login}_io.pl"; };
}


1;
# end of main


# this is for our long dates
# $locale->text('January')
# $locale->text('February')
# $locale->text('March')
# $locale->text('April')
# $locale->text('May ')
# $locale->text('June')
# $locale->text('July')
# $locale->text('August')
# $locale->text('September')
# $locale->text('October')
# $locale->text('November')
# $locale->text('December')

# this is for our short month
# $locale->text('Jan')
# $locale->text('Feb')
# $locale->text('Mar')
# $locale->text('Apr')
# $locale->text('May')
# $locale->text('Jun')
# $locale->text('Jul')
# $locale->text('Aug')
# $locale->text('Sep')
# $locale->text('Oct')
# $locale->text('Nov')
# $locale->text('Dec')


sub display_row {
  my $numrows = shift;

  @column_index = (runningnumber, partnumber, description, qty);

#kabai
  my $shiprec = $form->{vc} eq "customer" ? "Ship" : "Recd" ;
  if ($form->{type} !~ /quotation$/) {
    push @column_index, "ship";
    $column_data{ship} = qq|<th class=listheading align=center width="auto">|.$locale->text($shiprec).qq|</th>|;
  }

  foreach $item (qw(projectnumber partsgroup)) {
    $form->{"select$item"} = $form->unescape($form->{"select$item"}) if $form->{"select$item"};
  }
  
  push @column_index, qw(unit sellprice discount linetotal);

  my $colspan = $#column_index + 1;

  $form->{invsubtotal} = 0;
  map { $form->{"${_}_base"} = 0 } (split / /, $form->{taxaccounts});
  
  $column_data{runningnumber} = qq|<th class=listheading nowrap>|.$locale->text('No.').qq|</th>|;
  $column_data{partnumber} = qq|<th class=listheading nowrap>|.$locale->text('Number').qq|</th>|;
  $column_data{description} = qq|<th class=listheading nowrap>|.$locale->text('Description').qq|</th>|;
  $column_data{qty} = qq|<th class=listheading nowrap>|.$locale->text('Qty').qq|</th>|;
  $column_data{unit} = qq|<th class=listheading nowrap>|.$locale->text('Unit').qq|</th>|;
  $column_data{sellprice} = qq|<th class=listheading nowrap>|.$locale->text('Price').qq|</th>|;
  $column_data{discount} = qq|<th class=listheading>%</th>|;
  $column_data{linetotal} = qq|<th class=listheading nowrap>|.$locale->text('Extended').qq|</th>|;
  $column_data{bin} = qq|<th class=listheading nowrap>|.$locale->text('Bin').qq|</th>|;
  
  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  map { print "\n$column_data{$_}" } @column_index;

  print qq|
        </tr>
|;


  $deliverydate = $locale->text('Delivery Date');
  $serialnumber = $locale->text('Serial No.');
  $projectnumber = $locale->text('Project');
  $group = $locale->text('Group');
  $sku = $locale->text('SKU');

  $delvar = 'deliverydate';
  
  if ($form->{type} =~ /_(order|quotation)$/) {
    $reqdate = $locale->text('Required by');
    $delvar = 'reqdate';
  }

  $exchangerate = $form->parse_amount(\%myconfig, $form->{exchangerate});
  $exchangerate = ($exchangerate) ? $exchangerate : 1;

#kabai
#    $numrows-- if ($form->{type} eq 'invoice' && $form->{id});
#kabai    
for $i (1 .. $numrows) {
    # undo formatting
    map { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) } qw(qty ship discount sellprice);
    IS->termek_dij(\%myconfig, \%$form, $i) if $form->{tdij_van};
    $tdij_found = $form->{tdij} if !$tdij_found;
      
    ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
    $dec = length $dec;
    $decimalplaces = ($dec > 2) ? $dec : 2;
# from sl244
    if ($form->{"qty_$i"} != $form->{"oldqty_$i"}) {
      # check for a pricematrix
      @a = split / /, $form->{"pricematrix_$i"};
      if ((scalar @a) > 1) {
	foreach $item (@a) {
	  ($q, $p) = split /:/, $item;
	  if ($p != 0 && $form->{"qty_$i"} > $q) {
#kabai
	    $form->{"sellprice_$i"} = $form->round_amount($p, $decimalplaces);
	  }
	}
      }
    }
    $discount = $form->round_amount($form->{"sellprice_$i"} * $form->{"discount_$i"}/100, $decimalplaces);
    $linetotal = $form->round_amount($form->{"sellprice_$i"} - $discount, $decimalplaces);
    $linetotal = $form->round_amount($linetotal * $form->{"qty_$i"}, 2);

    map { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) } qw(partnumber sku description unit);
    
    $skunumber = qq|
                <p><b>$sku</b> $form->{"sku_$i"}| if ($form->{vc} eq 'vendor' && $form->{"sku_$i"});

    
    #if ($form->{selectpartsgroup}) {
      #if ($i < $numrows) {
	#$partsgroup = qq|
	 #     <p><b>$group</b>
	  #    <input type=hidden name="partsgroup_$i" value="$form->{"partsgroup_$i"}">|;
	#($form->{"partsgroup_$i"}) = split /--/, $form->{"partsgroup_$i"};
	#$partsgroup .= $form->{"partsgroup_$i"};
	#$partsgroup = "" unless $form->{"partsgroup_$i"};
      #}
    #}
    
    
#kabai
    $skunumber = "" if $nosecondrow_true;
    my $classreq = qq|class="required"| if ($i==1 && !$form->{id});
    if ($form->{"avprice_$i"} && $form->{type} eq "invoice"){
     $avprice_label = qq|<label class="info" title='|.$locale->text('Weighted Average Price').qq|: $form->{"avprice_$i"}'>B</label>|;
    }else{
     $avprice_label="";
    }
#kabai

	$column_data{runningnumber} = qq|<td><input name="runningnumber_$i" $readonly size=3 value=$i></td>|;
        $column_data{partnumber} = qq|<td><input name="partnumber_$i" $readonly $classreq size=15 maxlength=22 value="$form->{"partnumber_$i"}" accesskey="$i" title="[Alt-$i]">&nbsp;$avprice_label$skunumber</td>|;
        if (($rows = $form->numtextrows($form->{"description_$i"}, 35, 6)) > 1) {
	  $column_data{description} = qq|<td><textarea name="description_$i" rows=$rows cols=35 wrap=soft $readonly>$form->{"description_$i"}</textarea>$partsgroup</td>|;
        } else {
	  $column_data{description} = qq|<td><input name="description_$i" $readonly size=30 value="$form->{"description_$i"}">$partsgroup</td>|;
	}

	$column_data{qty} = qq|<td align=right><input name="qty_$i" size=5  $readonly value=|.$form->format_amount(\%myconfig, $form->{"qty_$i"}).qq|></td>|;
#kabai NOEDITSHIP	
	if ($form->{type} !~ /quotation$/){
	 $column_data{ship} = qq|<td align=right><input name="ship_$i" type=hidden size=5 value=|.$form->format_amount(\%myconfig, $form->{"ship_$i"}).qq|><span class=plus0>|.$form->format_amount(\%myconfig, $form->{"ship_$i"}).qq|</span></td>|;
        }
#kabai
	$column_data{unit} = qq|<td><input name="unit_$i" $readonly size=5 value="$form->{"unit_$i"}"></td>|;
	$column_data{sellprice} = qq|<td align=right><input name="sellprice_$i" $readonly size=9 value=|.$form->format_amount(\%myconfig, $form->{"sellprice_$i"}, $decimalplaces).qq|></td>|;
	$column_data{discount} = qq|<td align=right><input name="discount_$i" $readonly size=3 value=|.$form->format_amount(\%myconfig, $form->{"discount_$i"}).qq|></td>|;
	$column_data{linetotal} = qq|<td align=right>|.$form->format_amount(\%myconfig, $linetotal, 2).qq|</td>|;
	$column_data{bin} = qq|<td>$form->{"bin_$i"}</td>|;
	
#kabai    
    print qq|
        <tr valign=top>|;

    map { print "\n$column_data{$_}" } @column_index;

    print qq|
        </tr>

<input type=hidden name="orderitems_id_$i" value=$form->{"orderitems_id_$i"}>
<input type=hidden name="invoice_id_$i" value=$form->{"invoice_id_$i"}>

<input type=hidden name="id_$i" value=$form->{"id_$i"}>
<input type=hidden name="inventory_accno_$i" value=$form->{"inventory_accno_$i"}>
<input type=hidden name="bin_$i" value="$form->{"bin_$i"}">
<input type=hidden name="partsgroup_$i" value="$form->{"partsgroup_$i"}">
<input type=hidden name="income_accno_$i" value=$form->{"income_accno_$i"}>
<input type=hidden name="expense_accno_$i" value=$form->{"expense_accno_$i"}>
<input type=hidden name="listprice_$i" value="$form->{"listprice_$i"}">
<input type=hidden name="assembly_$i" value="$form->{"assembly_$i"}">
<input type=hidden name="taxaccounts_$i" value="$form->{"taxaccounts_$i"}">
<input type=hidden name="pricematrix_$i" value="$form->{"pricematrix_$i"}">
<input type=hidden name="oldqty_$i" value="$form->{"qty_$i"}">
<input type=hidden name="sku_$i" value="$form->{"sku_$i"}">
<input type=hidden name="tdij1_$i" value="$form->{"tdij1_$i"}">
<input type=hidden name="tdij2_$i" value="$form->{"tdij2_$i"}">
<input type=hidden name="avprice_$i" value="$form->{"avprice_$i"}">
|;

    $form->{selectprojectnumber} =~ s/ selected//;
    $form->{selectprojectnumber} =~ s/(<option value="\Q$form->{"projectnumber_$i"}\E")/$1 selected/;

#kabai
    $serial = qq|<b>$serialnumber</b> <input name="serialnumber_$i" size=15 value="$form->{"serialnumber_$i"}" $readonly>| if $form->{type} !~ /_quotation/;
      $delivery = qq|
        <b>${$delvar}</b>
        <input name="${delvar}_$i" size=11 title="$myconfig{dateformat}" value="$form->{"${delvar}_$i"}" $readonly>
      |;
      $project = qq|
        <b>$projectnumber</b>
        <select name="projectnumber_$i" $readonly>$form->{selectprojectnumber}</select>
	| if $form->{selectprojectnumber};


   


    $partsgroup = "";


    if ($i == $numrows) {
      if ($form->{selectpartsgroup}) {
#kabai
     if ($form->{type} eq 'invoice' && $form->{id}){
     }else{
	$partsgroup = qq|
	        <b>$group</b>
		<select name="partsgroup_$i">$form->{selectpartsgroup}</select>|;
     }    
#kabai
      }

      $serial = "" ;
      $project = "";
      $delivery = "";
    }

#kabai
    if ($nosecondrow_true){
      $serial = "";
      $project = "";
      $delivery = "";
    }
#kabai
	
    # print second row
    print qq|
        <tr>
	  <td colspan=$colspan>
	  $delivery
	  $serial
	  $project
	  $partsgroup
	  </td>
	</tr>
	<tr>
	  <td colspan=$colspan><hr size=1 noshade></td>
	</tr>
|;

    $skunumber = "";
    
    map { $form->{"${_}_base"} += $linetotal } (split / /, $form->{"taxaccounts_$i"});
  
    $form->{invsubtotal} += $linetotal;
  }

  print qq|
      </table>
    </td>
  </tr>
|;

  print qq|

<input type=hidden name=oldcurrency value=$form->{currency}>
<input type=hidden name=audittrail value="$form->{audittrail}">

<input type=hidden name=selectpartsgroup value="|.$form->escape($form->{selectpartsgroup},1).qq|">
<input type=hidden name=selectprojectnumber value="|.$form->escape($form->{selectprojectnumber},1).qq|">
|;

  if ($tdij_found && !$form->{id} && $form->{type} eq "invoice"){    
    my $product_charge = $locale->text('Product Charge');
    my $notes = $product_charge.": ".$form->format_amount(\%myconfig,$form->{termekdij})." Ft" if $form->{termekdij};
     if ($form->{notes} =~ /\Q$product_charge\E.*Ft$/){
      $form->{notes} =~ s/\Q$product_charge\E.*Ft$/$notes/;
     }else{
      $form->{notes} = $form->{notes}."\r\n".$notes;
     }  
  }

}


sub select_item {

  if ($form->{vc} eq "vendor") {
    @column_index = qw(ndx partnumber sku description partsgroup onhand onhandwh sellprice);
  } else {
    @column_index = qw(ndx partnumber description partsgroup onhand onhandwh sellprice);
  }

  $column_data{ndx} = qq|<th>&nbsp;</th>|;
  $column_data{partnumber} = qq|<th class=listheading>|.$locale->text('Number').qq|</th>|;
  $column_data{sku} = qq|<th class=listheading>|.$locale->text('SKU').qq|</th>|;
  $column_data{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_data{partsgroup} = qq|<th class=listheading>|.$locale->text('Group').qq|</th>|;
  $column_data{sellprice} = qq|<th class=listheading>|.$locale->text('Price').qq|</th>|;
  $column_data{onhand} = qq|<th class=listheading>|.$locale->text('Qty').qq|</th>|;
  $column_data{onhandwh} = qq|<th class=listheading>|.$locale->text('Warehouse').qq|</th>|;
 
  # list items with radio button on a form
  $form->header;

  $title = $locale->text('Select from one of the items below');

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$title</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>|;

  map { print "\n$column_data{$_}" } @column_index;
  
  print qq|
        </tr>
|;

  my $i = 0;
  foreach $ref (@{ $form->{item_list} }) {
    $checked = ($i++) ? "" : "checked";

    map { $ref->{$_} = $form->quote($ref->{$_}) } qw(sku partnumber description unit);

    $ref->{sellprice} = $form->round_amount($ref->{sellprice} * (1 - $form->{tradediscount}), 2);

    $column_data{ndx} = qq|<td><input name=ndx class=radio type=radio value=$i $checked></td>|;
    $column_data{partnumber} = qq|<td>$ref->{partnumber}</td>|;
    $column_data{sku} = qq|<td>$ref->{sku}</td>|;
    $column_data{description} = qq|<td>$ref->{description}</td>|;
    $column_data{partsgroup} = qq|<td>$ref->{partsgroup}</td>|;
    $column_data{sellprice} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{sellprice}, 2, "&nbsp;").qq|</td>|;
    $column_data{onhand} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{onhand}, '', "&nbsp;").qq|</td>|;
    $column_data{onhandwh} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{onhandwh}, '', "&nbsp;").qq|</td>|;
    
    $j++; $j %= 2;
    print qq|
        <tr class=listrow$j>|;

    map { print "\n$column_data{$_}" } @column_index;

    print qq|
        </tr>

<input name="new_partnumber_$i" type=hidden value="$ref->{partnumber}">
<input name="new_sku_$i" type=hidden value="$ref->{sku}">
<input name="new_description_$i" type=hidden value="$ref->{description}">
<input name="new_partsgroup_$i" type=hidden value="$ref->{partsgroup}">
<input name="new_partsgroup_id_$i" type=hidden value="$ref->{partsgroup_id}">
<input name="new_bin_$i" type=hidden value="$ref->{bin}">
<input name="new_sellprice_$i" type=hidden value=$ref->{sellprice}>
<input name="new_listprice_$i" type=hidden value=$ref->{listprice}>
<input name="new_lastcost_$i" type=hidden value=$ref->{lastcost}>
<input name="new_onhand_$i" type=hidden value=$ref->{onhand}>
<input name="new_onhandwh_$i" type=hidden value=$ref->{onhandwh}>
<input name="new_inventory_accno_$i" type=hidden value=$ref->{inventory_accno}>
<input name="new_income_accno_$i" type=hidden value=$ref->{income_accno}>
<input name="new_expense_accno_$i" type=hidden value=$ref->{expense_accno}>
<input name="new_unit_$i" type=hidden value="$ref->{unit}">
<input name="new_weight_$i" type=hidden value="$ref->{weight}">
<input name="new_assembly_$i" type=hidden value="$ref->{assembly}">
<input name="new_taxaccounts_$i" type=hidden value="$ref->{taxaccounts}">
<input name="new_pricematrix_$i" type=hidden value="$ref->{pricematrix}">
<input name="new_projectnumber_$i" type=hidden value="$ref->{projectnumber}--$ref->{project_id}">
<input name="new_avprice_$i" type=hidden value="$ref->{avprice}">
<input name="new_id_$i" type=hidden value=$ref->{id}>

|;

  }
  
  print qq|
      </table>
    </td>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input name=lastndx type=hidden value=$i>

|;

  # delete action variable
  map { delete $form->{$_} } qw(action item_list header);

  $form->hide_form();
  
  print qq|
<input type=hidden name=nextsub value=item_selected>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}



sub item_selected {

  # replace the last row with the checked row
  $i = $form->{rowcount};
  $i = $form->{assembly_rows} if ($form->{item} eq 'assembly');

  # index for new item
  $j = $form->{ndx};

  # if there was a price entered, override it
  $sellprice = $form->parse_amount(\%myconfig, $form->{"sellprice_$i"});
  
  map { $form->{"${_}_$i"} = $form->{"new_${_}_$j"} } qw(id partnumber sku description sellprice listprice lastcost inventory_accno income_accno expense_accno bin unit weight assembly taxaccounts pricematrix projectnumber avprice);

  $form->{"partsgroup_$i"} = qq|$form->{"new_partsgroup_$j"}--$form->{"new_partsgroup_id_$j"}|;

  ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
  $dec = length $dec;
  $decimalplaces = ($dec > 2) ? $dec : 2;

  if ($sellprice) {
    $form->{"sellprice_$i"} = $sellprice;

  } else {
    # if there is an exchange rate adjust sellprice
    if (($form->{exchangerate} * 1) != 0) {
      #$form->{"sellprice_$i"} /= $form->{exchangerate};
      $form->{"sellprice_$i"} = $form->round_amount($form->{"sellprice_$i"}, $decimalplaces);

    }
  }

  map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(sellprice listprice weight);

  $form->{sellprice} += ($form->{"sellprice_$i"} * $form->{"qty_$i"});
  $form->{weight} += ($form->{"weight_$i"} * $form->{"qty_$i"});

  $amount = $form->{"sellprice_$i"} * (1 - $form->{"discount_$i"} / 100) * $form->{"qty_$i"};

  foreach $item (split / /, $form->{"taxaccounts_$i"}) {

    if ($form->datetonum($form->{"${item}_validfrom"},\%myconfig) > $form->datetonum($form->{transdate}, \%myconfig)
        || $form->datetonum($form->{"${item}_validto"},\%myconfig) < $form->datetonum($form->{transdate}, \%myconfig))
    {
    next;
    }
          
    $form->{"${item}_base"} += $amount;
    $amount += ($form->{"${item}_base"} * $form->{"${item}_rate"}) if !$form->{taxincluded};
  }
  $form->{creditremaining} -= $amount;

  $form->{"runningnumber_$i"} = $i;
  
  # delete all the new_ variables
  for $i (1 .. $form->{lastndx}) {
    map { delete $form->{"new_${_}_$i"} } qw(partnumber sku description sellprice bin listprice lastcost inventory_accno income_accno expense_accno unit assembly taxaccounts id pricematrix);
  }
  
  map { delete $form->{$_} } qw(ndx lastndx nextsub);

  # format amounts
  map { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $decimalplaces) } qw(sellprice listprice) if $form->{item} ne 'assembly';

  &display_form;

}


sub new_item {

  # change callback
  $form->{old_callback} = $form->escape($form->{callback},1);
  $form->{callback} = $form->escape("$form->{script}?action=display_form",1);

  # delete action
  delete $form->{action};

  # save all other form variables in a previousform variable
  if (!$form->{previousform}) {
    foreach $key (keys %$form) {
      # escape ampersands
      $form->{$key} =~ s/&/%26/g;
      $form->{previousform} .= qq|$key=$form->{$key}&|;
    }
    chop $form->{previousform};
    $form->{previousform} = $form->escape($form->{previousform}, 1);
  }

  $i = $form->{rowcount};
  map { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) } qw(partnumber description);

  $form->header;

  print qq|
<body>

<h4 class=error>|.$locale->text('Item not on file!').qq|</h4>|;

#kabai +1
  if ($myconfig{acs} !~ /(System--Services--Add Service|Goods--Parts--Add Part)/) {

    print qq|
<h4>|.$locale->text('What type of item is this?').qq|</h4>
    |;
  }
    print qq|
<form method=post action=ic.pl>

<p>
|;
  if ($myconfig{acs} !~ /Goods--Parts--Add Part/) {
   print qq|
   <input class=radio type=radio name=item value=part checked>&nbsp;|.$locale->text('Part');
  }else{
   $servicechecked = "checked";
  }  
  if ($myconfig{acs} !~ /System--Services--Add Service/) {
  print qq|
  <input class=radio type=radio name=item value=service $servicechecked>&nbsp;|.$locale->text('Service');
  }
 if ($myconfig{acs} =~ /System--Services--Add Service/ && $myconfig{acs} =~ /Goods--Parts--Add Part/) {
 }else{
  print qq|
<input type=hidden name=previousform value="$form->{previousform}">
<input type=hidden name=partnumber value="$form->{"partnumber_$i"}">
<input type=hidden name=description value="$form->{"description_$i"}">
<input type=hidden name=rowcount value=$form->{rowcount}>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input type=hidden name=nextsub value=add>

<p>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
|;
}
 

  print qq|
</form>
</body>
</html>
|;

}



sub display_form {
  # if we have a display_form
  if ($form->{display_form}) {
    &{ "$form->{display_form}" };
    exit;
  }
  &form_header;

  $numrows = ++$form->{rowcount};
  $subroutine = "display_row";
  if ($form->{item} eq 'part') {
    # create makemodel rows
    &makemodel_row(++$form->{makemodel_rows});

    &vendor_row(++$form->{vendor_rows});
    
    $numrows = ++$form->{customer_rows};
    $subroutine = "customer_row";
  }
  if ($form->{item} eq 'assembly') {
    # create makemodel rows
    &makemodel_row(++$form->{makemodel_rows});
    
    $numrows = ++$form->{customer_rows};
    $subroutine = "customer_row";
  }
  if ($form->{item} eq 'service') {
    &vendor_row(++$form->{vendor_rows});
    
    $numrows = ++$form->{customer_rows};
    $subroutine = "customer_row";
  }

  # create rows
  &{ $subroutine }($numrows) if $numrows;
  &form_footer($_[0]);

}



sub check_form {

  my @a = ();
  my $count = 0;
  my $i;
  my $j;
  my @flds = qw(id runningnumber partnumber description partsgroup qty ship unit sellprice discount oldqty orderitems_id bin weight listprice lastcost taxaccounts pricematrix sku onhand assembly inventory_accno_id income_accno_id expense_accno_id notes reqdate deliverydate serialnumber projectnumber);

  # remove any makes or model rows
  if ($form->{item} eq 'part') {
    map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(listprice sellprice lastcost weight rop markup);
    
    &calc_markup;
    
    @flds = (make, model);
    $count = 0;
    @a = ();
    for $i (1 .. $form->{makemodel_rows}) {
      if (($form->{"make_$i"} ne "") || ($form->{"model_$i"} ne "")) {
	push @a, {};
	$j = $#a;

	map { $a[$j]->{$_} = $form->{"${_}_$i"} } @flds;
	$count++;
      }
    }

    $form->redo_rows(\@flds, \@a, $count, $form->{makemodel_rows});
    $form->{makemodel_rows} = $count;

    &check_vendor;
    &check_customer;
    
  } elsif ($form->{item} eq 'service') {
    
    map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(sellprice listprice lastcost markup);
    
    &calc_markup;
    &check_vendor;
    &check_customer;
    
  } elsif ($form->{item} eq 'assembly') {
    map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(sellprice listprice lastcost weight);

    #$form->{sellprice} = 0;
    #$form->{weight} = 0;
    #$form->{lastcost} = 0;
    #$form->{listprice} = 0;
    
           map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(rop stock markup);
   
    @flds = qw(id qty unit bom adj partnumber description sellprice listprice weight runningnumber partsgroup);
    $count = 0;
    @a = ();
    
    for my $i (1 .. ($form->{assembly_rows} - 1)) {
      if ($form->{"qty_$i"}) {
	push @a, {};
	my $j = $#a;

        $form->{"qty_$i"} = $form->parse_amount(\%myconfig, $form->{"qty_$i"});

	map { $a[$j]->{$_} = $form->{"${_}_$i"} } @flds;

            # map { $form->{$_} += ($form->{"${_}_$i"} * $form->{"qty_$i"}) } qw(sellprice listprice weight lastcost);
	$count++;
      }
    }


    #if ($form->{markup} && $form->{markup} != $form->{oldmarkup}) {

    #  $form->{sellprice} = 0;
    #  &calc_markup;
    #}
        map { $form->{$_} = $form->round_amount($form->{$_}, 2) } qw(sellprice lastcost listprice);

    $form->redo_rows(\@flds, \@a, $count, $form->{assembly_rows});

    $form->{assembly_rows} = $count;
    
    $count = 0;
    @flds = qw(make model);
    @a = ();
    
    for my $i (1 .. ($form->{makemodel_rows})) {
      if (($form->{"make_$i"} ne "") || ($form->{"model_$i"} ne "")) {
	push @a, {};
	my $j = $#a;

	map { $a[$j]->{$_} = $form->{"${_}_$i"} } @flds;
	$count++;
      }
    }

    $form->redo_rows(\@flds, \@a, $count, $form->{makemodel_rows});
    $form->{makemodel_rows} = $count;

    &check_customer;

  } else {

    # this section applies to invoices and orders
    # remove any empty numbers
    
    $count = 0;
    @a = ();
    if ($form->{rowcount}) {
      for my $i (1 .. $form->{rowcount} - 1) {
	if ($form->{"partnumber_$i"}) {
	  push @a, {};
	  my $j = $#a;

	  map { $a[$j]->{$_} = $form->{"${_}_$i"} } @flds;
	  $count++;
	}
      }
      
      $form->redo_rows(\@flds, \@a, $count, $form->{rowcount});
      $form->{rowcount} = $count;

      #$form->{creditremaining} -= &invoicetotal;
      
    }
  }

  &display_form;
}


sub calc_markup {

  if ($form->{markup}) {
    if ($form->{markup} != $form->{oldmarkup}) {
      if ($form->{lastcost}) {
	$form->{sellprice} = $form->{lastcost} * (1 + $form->{markup}/100);
	$form->{sellprice} = $form->round_amount($form->{sellprice}, 2);
      } else {
	$form->{lastcost} = $form->{sellprice} / (1 + $form->{markup}/100);
	$form->{lastcost} = $form->round_amount($form->{lastcost}, 2);
      }
    }
  } else {
    if ($form->{lastcost}) {
      $form->{markup} = $form->round_amount(((1 - $form->{sellprice} / $form->{lastcost}) * 100), 1);
    }
    $form->{markup} = "" if $form->{markup} == 0;
  }

}


sub invoicetotal {

  $form->{oldinvtotal} = 0;
  # add all parts and deduct paid
  map { $form->{"${_}_base"} = 0 } split / /, $form->{taxaccounts};

  my ($amount, $sellprice, $discount, $qty);
  
  for my $i (1 .. $form->{rowcount}) {
    $sellprice = $form->parse_amount(\%myconfig, $form->{"sellprice_$i"});
    $discount = $form->parse_amount(\%myconfig, $form->{"discount_$i"});
    $qty = $form->parse_amount(\%myconfig, $form->{"qty_$i"});

    $amount = $sellprice * (1 - $discount / 100) * $qty;
    foreach $item (split / /, $form->{"taxaccounts_$i"}) {
          if ($form->datetonum($form->{"${item}_validfrom"},\%myconfig) > $form->datetonum($form->{transdate}, \%myconfig)
            || $form->datetonum($form->{"${item}_validto"},\%myconfig) < $form->datetonum($form->{transdate}, \%myconfig))
          {
          next;
          }
          $form->{"${item}_base"} += $amount;
    }  
    $form->{oldinvtotal} += $amount;
  }

    foreach $item (split / /, $form->{taxaccounts}) {
          if ($form->datetonum($form->{"${item}_validfrom"},\%myconfig) > $form->datetonum($form->{transdate}, \%myconfig)
            || $form->datetonum($form->{"${item}_validto"},\%myconfig) < $form->datetonum($form->{transdate}, \%myconfig))
          {
          next;
          }
          $form->{oldinvtotal} += ($form->{"${item}_base"} * $form->{"${item}_rate"}) if !$form->{taxincluded};
    }

  $form->{oldtotalpaid} = 0;
  for $i (1 .. $form->{paidaccounts}) {
    $form->{oldtotalpaid} += $form->{"paid_$i"};
  }
  
  # return total
  ($form->{oldinvtotal} - $form->{oldtotalpaid});

}


sub validate_items {
  
      # check if items are valid
  if ($form->{rowcount} == 1) {
    &update;
    exit;
  }
    
  for $i (1 .. $form->{rowcount} - 1) {
    $form->isblank("partnumber_$i", $locale->text('Number missing in Row') . " $i");
  }
}



sub purchase_order {
  
  $form->{title} = $locale->text('Add Purchase Order');
  $form->{vc} = 'vendor';
  $form->{type} = 'purchase_order';
  $buysell = 'sell';
  &create_form;

}

 

sub sales_order {

  $form->{title} = $locale->text('Add Sales Order');
  $form->{vc} = 'customer';
  $form->{type} = 'sales_order';
  $buysell = 'buy';

  &create_form;

}


sub rfq {
  
  $form->{title} = $locale->text('Add Request for Quotation');
  $form->{vc} = 'vendor';
  $form->{type} = 'request_quotation';
  $buysell = 'sell';
 
  &create_form;
  
}


sub quotation {

  $form->{title} = $locale->text('Add Quotation');
  $form->{vc} = 'customer';
  $form->{type} = 'sales_quotation';
  $buysell = 'buy';

  &create_form;

}


sub create_form {

  map { delete $form->{$_} } qw(id printed emailed queued);
 
  $form->{script} = 'oe.pl';

  $form->{shipto} = 1;
  
#kabai +1
  $form->{rowcount}-- if $form->{partnumber_1};

  require "$form->{path}/$form->{script}";

  map { $form->{"select$_"} = "" } ($form->{vc}, currency);
  
  map { $temp{$_} = $form->{$_} } qw(currency employee department intnotes);

  &order_links;

  map { $form->{$_} = $temp{$_} } keys %temp;

  $form->{exchangerate} = "";
  $form->{forex} = "";
  $form->{exchangerate} = $exchangerate if ($form->{forex} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}, $buysell))); 
  
  &prepare_order;
  &display_form;

}



sub e_mail {

  if ($myconfig{role} =~ /(admin|manager)/) {
    $bcc = qq|
 	  <th align=right nowrap=true>|.$locale->text('Bcc').qq|</th>
	  <td><input name=bcc size=30 value="$form->{bcc}"></td>
|;
  }

  if ($form->{formname} =~ /(pick|packing|bin)_list/) {
    $form->{email} = $form->{shiptoemail} if $form->{shiptoemail};
  }

  $name = $form->{$form->{vc}};
  $name =~ s/--.*//g;
  $title = $locale->text('E-mail')." $name";
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$title</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th align=right nowrap>|.$locale->text('E-mail to').qq|</th>
	  <td><input name=email size=30 value="$form->{email}"></td>
	  <th align=right nowrap>|.$locale->text('Cc').qq|</th>
	  <td><input name=cc size=30 value="$form->{cc}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Subject').qq|</th>
	  <td><input name=subject size=30 value="$form->{subject}"></td>
	  $bcc
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th align=left nowrap>|.$locale->text('Message').qq|</th>
	</tr>
	<tr>
	  <td><textarea name=message rows=15 cols=60 wrap=soft>$form->{message}</textarea></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
|;

  $form->{oldmedia} = $form->{media};
  $form->{media} = "email";
  $form->{format} = "pdf";
  
  &print_options;
  
  map { delete $form->{$_} } qw(action email cc bcc subject message formname sendmode format header);
  
  $form->hide_form();

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=nextsub value=send_email>

<br>
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub send_email {

  $old_form = new Form;
  
  map { $old_form->{$_} = $form->{$_} } keys %$form;
  $old_form->{media} = $old_form->{oldmedia};
#kabai
  $form->{e_mail} = 1;
  $form->{windows} = $windows;

 if ($windows){
  $form->error($locale->text("SMTP server missing!")) if !$smtpserver;
  $form->error($locale->text("Sender e-mail address is missing!")) if !$myconfig{email};
  $form->{smtpserver} = $smtpserver;
 }
#kabai
  
  &print_form($old_form);
  
}
  

 
sub print_options {

  $form->{sendmode} = "attachment";
  $form->{copies} = 1 unless $form->{copies};
  
  $form->{PD}{$form->{formname}} = "selected";
  $form->{DF}{$form->{format}} = "selected";
  $form->{OP}{$form->{media}} = "selected";
  $form->{SM}{$form->{sendmode}} = "selected";

  if ($form->{selectlanguage}) {
    $form->{"selectlanguage"} = $form->unescape($form->{"selectlanguage"});
    $form->{"selectlanguage"} =~ s/ selected//;
    $form->{"selectlanguage"} =~ s/(<option value="\Q$form->{language_code}\E")/$1 selected/;
    $language = qq|<td><select name=language_code>$form->{selectlanguage}</select></td>
    <input type=hidden name=selectlanguage value="|.
    $form->escape($form->{selectlanguage},1).qq|">|;
  } else {  #pasztor
   $language = '';
  }
  
  if ($form->{type} eq 'purchase_order') {
    $type = qq|<td><select name=formname>
	    <option value=purchase_order $form->{PD}{purchase_order}>|.$locale->text('Purchase Order').qq|
	    <option value=bin_list $form->{PD}{bin_list}>|.$locale->text('Bin List').qq|</select></td>|;
  }
  
  if ($form->{type} eq 'sales_order') {
    $type = qq|<td><select name=formname>
	    <option value=sales_order $form->{PD}{sales_order}>|.$locale->text('Sales Order').qq|
	    <option value=packing_list $form->{PD}{packing_list}>|.$locale->text('Packing List').qq|
	    <option value=proforma $form->{PD}{proforma}>|.$locale->text('Proforma Invoice').qq|
	    <option value=pick_list $form->{PD}{pick_list}>|.$locale->text('Pick List').qq|</select></td>|;
  }
  
  if ($form->{type} =~ /_quotation$/) {
    $type = qq|<td><select name=formname>
	    <option value="$`_quotation" $form->{PD}{"$`_quotation"}>|.$locale->text('Quotation').qq|</select></td>|;
  }
  
  if ($form->{type} eq 'invoice') {
    $type = qq|<td><select name=formname>|;
    if ($form->{promptshipreceive}){
     $type.= qq|<option value=packing_list $form->{PD}{packing_list}>|.$locale->text('Packing List');
    }
    $type.= qq|<option value=cash_voucher $form->{PD}{cash_voucher}>|.$locale->text('Cash Voucher').qq|
               <option value=invoice $form->{PD}{invoice}>|.$locale->text('Invoice').qq|</select></td>
    |;
  }
  
  if ($form->{type} eq 'ship_order') {
    $type = qq|<td><select name=formname>
	    <option value=pick_list $form->{PD}{pick_list}>|.$locale->text('Pick List').qq|
	    <option value=packing_list $form->{PD}{packing_list}>|.$locale->text('Packing List').qq|</select></td>|;
  }
  
  if ($form->{type} eq 'receive_order') {
    $type = qq|<td><select name=formname>
	    <option value=bin_list $form->{PD}{bin_list}>|.$locale->text('Bin List').qq|</select></td>|;
  }

#pasztor
  if ($form->{type} eq 'trans_packing_list') {
      $type = qq|<td><select name=formname>
            <option value=trans_packing_list $form->{PD}{trans_packing_list}>|.$locale->text('Transfer Packing List').qq|</select></td>|;
  }
 
  if ($form->{media} eq 'email') {
    $media = qq|<td><select name=sendmode>
	    <option value=attachment $form->{SM}{attachment}>|.$locale->text('Attachment').qq|
	    <option value=inline $form->{SM}{inline}>|.$locale->text('In-line').qq|</select></td>|;
  } else {
    $media = qq|<td><select name=media>
	    <option value=screen $form->{OP}{screen}>|.$locale->text('Screen');
    if ($myconfig{printer} && $latex) {
      $media .= qq|
            <option value=printer $form->{OP}{printer}>|.$locale->text('Printer');
    }
     if ($latex) {
      $media .= qq|
            <option value=queue $form->{OP}{queue}>|.$locale->text('Queue');
    }
    $media .= qq|</select></td>|;
  }

  if ($latex) {
    $format = qq|<td><select name=format>
	    <option value=pdf $form->{DF}{pdf}>|.$locale->text('PDF').qq|
            <option value=postscript $form->{DF}{postscript}>|.$locale->text('Postscript');
  }
  $format .= qq|<option value=html $form->{DF}{html}>html</select></td>|;
#kabai
  if ($form->{action} ne "e_mail"){
   if ((!$ismediachange_true && $form->{type} eq "invoice") || !$form->{id}){
    $format = "" ;
    $media = "" ;
    $type = "" ;
   }
  }
#kabai
  print qq|
<table width=100% cellspacing=0 cellpadding=0>
  <tr>
    <td>
      <table>
	<tr>
	  $type
	  $language
	  $format
	  $media
|;
#kabai
  if ($latex && $form->{media} ne 'email' && $form->{id}) {
    print qq|
	  <td>|.$locale->text('Copies').qq|
	  <input name=copies class="required" size=2 value=$myconfig{copies}></td>
|;
  }

  $form->{groupprojectnumber} = "checked" if $form->{groupprojectnumber};
  $form->{grouppartsgroup} = "checked" if $form->{grouppartsgroup};
#kabai
#  print qq|
#          <td>|.$locale->text('Group Items').qq|</td>
#          <td>
#	  <input name=groupprojectnumber type=checkbox class=checkbox $form->{groupprojectnumber}>
#	  |.$locale->text('Project').qq|
#	  <input name=grouppartsgroup type=checkbox class=checkbox $form->{grouppartsgroup}>
#	  |.$locale->text('Group').qq|
#	  </td>
#kabai
  print qq|
        </tr>
      </table>
    </td>
    <td align=right>
      <table>
        <tr>
|;

  if ($form->{printed} =~ /$form->{formname}/) {
    print qq|
	  <th>\||.$locale->text('Printed').qq|\|</th>
|;
  }
  
  if ($form->{emailed} =~ /$form->{formname}/) {
    print qq|
	  <th>\||.$locale->text('E-mailed').qq|\|</th>
|;
  }
  
  if ($form->{queued} =~ /$form->{formname}/) {
    print qq|
	  <th>\||.$locale->text('Queued').qq|\|</th>
|;
  }
  
  print qq|
        </tr>
      </table>
    </td>
  </tr>
</table>
|;


}

sub print_preview { #kabai
#kabai
$form->{media} = "screen";
$form->{format} = "pdf";
$form->{formname} = "invoice";
$form->{print_preview} = 1;
$form->{copies} = 1;
#kabai
    #Taxamount in HUF
    if($form->{currency} ne "HUF") {
      if (my $huftaxamount = ($form->{oldinvtotal}-$form->{oldinvsubtotal})){
          $form->{notes} .= "\n\r>>>ÁFA: ".$form->format_amount(\%myconfig,$huftaxamount*$form->parse_amount(\%myconfig,$form->{exchangerate}),2)." Ft<<<";
      }
    }
  &print_form($old_form);

}#kabai


sub print {
#kabai 
  $form->error($locale->text('Company name or text missing! Please fill the name and address fields in the Preferences menu!')) if (!$myconfig{company} || !$myconfig{address});
  $form->error($locale->text('Copy number is missing!')) if !$form->{copies};
  if ($form->{formname} eq "cash_voucher") {
    require "$form->{path}/rs.pl";
    &print_voucher; 
  }
  if (!$ismediachange_true && $form->{type} eq "invoice"){
       $form->{media} = "printer";
       $form->{format} = "postscript";
  }
#kabai
  # if this goes to the printer pass through
  if ($form->{media} eq 'printer' || $form->{media} eq 'queue') {
#kabai
	   $form->error($locale->text('Printing to printer/Queue is not recommended under windows! Please choose Screen option with PDF!')) if $windows;
	   $form->error($locale->text('Printing Queue is disabled!')) if ($form->{type} eq "invoice" && $form->{media} eq 'queue');

#kabai
	   $form->error($locale->text('Select postscript or PDF!')) if ($form->{format} !~ /(postscript|pdf)/);

    $old_form = new Form;
    map { $old_form->{$_} = $form->{$_} } keys %$form;
    
  }
  &print_form($old_form);

}


sub print_form {
  my ($old_form) = @_;
  $inv = "inv";
  $due = "due";

  $numberfld = "invnumber";

  $display_form = ($form->{display_form}) ? $form->{display_form} : "display_form";

  if ($form->{formname} eq "invoice") {
    $form->{label} = $locale->text('Invoice');
####################
####################
#kabai
    $form->{ordnumber} = $form->{oddordnumber};
    $form->{roundtoint_true} = 0;
    $invtotal_hu = 0;
    $taxbase_zero = 0;
    for $i(1..$form->{rowcount}) {
    my $linetaxrate = 0;
#    map { $linetaxrate = $form->{"${_}_rate"} } split / /, $form->{"taxaccounts_$i"};    
    foreach $item (split / /, $form->{"taxaccounts_$i"}) {

      if ($form->{"${item}_rate"}){
          if ($form->datetonum($form->{transdate}, \%myconfig) >= $form->datetonum($form->{"${item}_validfrom"}, \%myconfig)
              && $form->datetonum($form->{transdate}, \%myconfig) <= $form->datetonum($form->{"${item}_validto"}, \%myconfig)){
             $linetaxrate = $form->{"${item}_rate"};
          }  
      }  
    }

        my $sellprice = $form->parse_amount(\%myconfig, $form->{"sellprice_$i"});
        my $discount = $form->parse_amount(\%myconfig, $form->{"discount_$i"});
        my $newsellprice = $sellprice - $form->round_amount($sellprice * $discount/100,2);
	
    if($form->{taxincluded}) {
        $netprice_hu = $newsellprice / (1 +$linetaxrate);
	$grosstotal_hu = $form->round_amount($form->parse_amount(\%myconfig,$form->{"qty_$i"}) * $newsellprice,2);
    }else{
        $netprice_hu = $newsellprice;
	$grosstotal_hu = $form->round_amount($form->parse_amount(\%myconfig,$form->{"qty_$i"}) * $newsellprice * (1 + $linetaxrate),2);
    }
    $nettotal_hu = $form->round_amount($form->parse_amount(\%myconfig,$form->{"qty_$i"}) * $netprice_hu,2);
    $taxamount = $grosstotal_hu - $nettotal_hu; 

    $invtotal_hu += $grosstotal_hu;
    $taxbase_zero += $grosstotal_hu if !$linetaxrate;
    push(@{ $form->{netprice_hu} }, $form->format_amount(\%myconfig,$netprice_hu,2,0));
    push(@{ $form->{nettotal_hu} }, $form->format_amount(\%myconfig,$nettotal_hu,2,0));
    !$linetaxrate ? push(@{ $form->{linetaxrate} }, "am") : push(@{ $form->{linetaxrate} }, $linetaxrate*100);
    !$linetaxrate ? push(@{ $form->{taxamount} }, 0) :push(@{ $form->{taxamount} }, $form->format_amount(\%myconfig,$taxamount,2,0));
    push(@{ $form->{grosstotal_hu} }, $form->format_amount(\%myconfig,$grosstotal_hu,));
    }

    $form->{invtotal_hu} = $form->format_amount(\%myconfig,$invtotal_hu,0);
    $form->{taxbase_zero} = $form->format_amount(\%myconfig,$taxbase_zero,0);
    $form->{currency_text} = $form->{currency};
    $form->{currency_text} =~ s/HUF/Ft/g;
#####################
#####################
#kabai
  }

  if ($form->{formname} eq "packing_list") {
    # this is from an invoice
    $form->{label} = $locale->text('Packing List');
  }
  if ($form->{formname} eq 'sales_order' || $form->{formname} eq 'proforma') {
    $inv = "ord";
    $due = "req";
    $form->{"${inv}date"} = $form->{transdate};
    $form->{label} = $locale->text('Sales Order');
    $numberfld = "sonumber";
    $order = 1;
  }
  if ($form->{formname} eq 'packing_list' && $form->{type} ne 'invoice') {
    # we use the same packing list as from an invoice
    $inv = "ord";
    $due = "req";
    $form->{invdate} = $form->{"${inv}date"} = $form->{transdate};
    $form->{label} = $locale->text('Packing List');
    $order = 1;
  }
  if ($form->{formname} eq 'pick_list') {
    $inv = "ord";
    $due = "req";
    $form->{"${inv}date"} = $form->{transdate};
    $form->{label} = $locale->text('Pick List');
    $order = 1 unless $form->{type} eq 'invoice';
  }
  if ($form->{formname} eq 'purchase_order') {
    $inv = "ord";
    $due = "req";
    $form->{"${inv}date"} = $form->{transdate};
    $form->{label} = $locale->text('Purchase Order');
    $numberfld = "ponumber";
    $order = 1;
  }
  if ($form->{formname} eq 'bin_list') {
    $inv = "ord";
    $due = "req";
    $form->{"${inv}date"} = $form->{transdate};
    $form->{label} = $locale->text('Bin List');
    $order = 1;
  }
  if ($form->{formname} eq 'sales_quotation') {
    $inv = "quo";
    $due = "req";
    $form->{"${inv}date"} = $form->{transdate};
    $form->{label} = $locale->text('Quotation');
    $numberfld = "sqnumber";
    $order = 1;
  }
  if ($form->{formname} eq 'request_quotation') {
    $inv = "quo";
    $due = "req";
    $form->{"${inv}date"} = $form->{transdate};
    $form->{label} = $locale->text('Quotation');
    $numberfld = "rfqnumber";
    $order = 1;
  }
#pasztor
  if ($form->{formname} eq 'trans_packing_list') {
    $inv = "szl";
    $due = "req";
    $form->{label} = $locale->text('Transfer Packing List');
    $numberfld = "szlnumber";
    $order = 1;
    push @a,warehouse;
  }
  
  $form->{"${inv}date"} = $form->{transdate};

  $form->isblank("email", $locale->text('E-mail address missing!')) if ($form->{media} eq 'email');
  $form->isblank("${inv}date", $locale->text($form->{label} .' Date missing!'));

  # get next number
#kabai +1
  if (! $form->{"${inv}number"} && $form->{media} ne 'screen') {
    $form->{"${inv}number"} = $form->update_defaults(\%myconfig, $numberfld);
#    if ($form->{media} eq 'screen') {
#      &update;
#      exit;
#    }
  }


# $locale->text('Invoice Number missing!')
# $locale->text('Invoice Date missing!')
# $locale->text('Packing List Number missing!')
# $locale->text('Packing List Date missing!')
# $locale->text('Order Number missing!')
# $locale->text('Order Date missing!')
# $locale->text('Quotation Number missing!')
# $locale->text('Quotation Date missing!')

  &validate_items;

#pasztor
  if ($form->{formname} ne "trans_packing_list") {
    &{ "$form->{vc}_details" };
  }

  @a = ();
  foreach $i (1 .. $form->{rowcount}) {
    $form->{"description_$i"} =~ s/[\t\n\r]+//g;
    push @a, ("partnumber_$i", "description_$i", "projectnumber_$i", "partsgroup_$i", "serialnumber_$i", "bin_$i", "unit_$i");
  }
  map { push @a, "${_}_description" } split / /, $form->{taxaccounts};

  $ARAP = ($form->{vc} eq 'customer') ? "AR" : "AP";
  push @a, $ARAP;
  
  # format payment dates
  for $i (1 .. $form->{paidaccounts} - 1) {
    $form->{"datepaid_$i"} = $locale->date(\%myconfig, $form->{"datepaid_$i"});
    push @a, "${ARAP}_paid_$i", "source_$i", "memo_$i";
  }
  
  $form->format_string(@a);
  
  ($form->{employee}) = split /--/, $form->{employee};
  ($form->{warehouse}, $form->{warehouse_id}) = split /--/, $form->{warehouse};
  
  # this is a label for the subtotals
  $form->{groupsubtotaldescription} = $locale->text('Subtotal') if not exists $form->{groupsubtotaldescription};

  # create the form variables
  if ($order) {
    OE->order_details(\%myconfig, \%$form);
  } else {
    IS->invoice_details(\%myconfig, \%$form);
     if(!$form->{print_preview} or $form->{reversing}) {
      $form->{id} = $form->{trans_id};
      IS->invoice_address(\%myconfig, \%$form);    	
    }
  }

#kabai  map { $form->{$_} = $locale->date(\%myconfig, $form->{$_}, 1) } ("${inv}date", "${due}date", "shippingdate");

  @a = qw(name address1 address2 city state zipcode country contact);
 
  $shipto = 1;
  # if there is no shipto fill it in from billto
  foreach $item (@a) {
   $form->{"shipto$item"} =~ s/^\s+//g; 
   if ($form->{"shipto$item"}) {
      $shipto = 0;
      last;
    }
  }

  if ($shipto) {
    if ($form->{formname} eq 'purchase_order' || $form->{formname} eq 'request_quotation') {
	$form->{shiptoname} = $myconfig{company};
	$form->{shiptoaddress1} = $myconfig{address};
    } else {
      if ($form->{formname} !~ /bin_list/) {
	map { $form->{"shipto$_"} = $form->{$_} } @a;
      }
    }
  }

  $form->{notes} =~ s/^\s+//g;
  $form->{footer} = $form->unescape($form->{footer});

  # some of the stuff could have umlauts so we translate them
  push @a, qw(contact shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptoemail shippingpoint shipvia company address signature notes employee ordnumber footer);

  push @a, ("${inv}number", "${inv}date", "${due}date", "email", "cc", "bcc");

# before we format replace <%var%>
  map { $form->{$_} =~ s/<%(.*?)%>/$form->{$1}/g } qw(notes footer);
#kabai

  $form->format_string(@a);

  $form->{templates} = "$myconfig{templates}";
  $form->{IN} = "$form->{formname}.html";

  if ($form->{format} =~ /(postscript|pdf)/) {
    $form->{IN} =~ s/html$/tex/;
   }

  if ($form->{media} eq 'printer') {
    $form->{OUT} = "| $myconfig{printer}";
  }

  if ($form->{media} eq 'email') {
    $form->{subject} = qq|$form->{label} $form->{"${inv}number"}| unless $form->{subject};

    $form->{plainpaper} = 1;
    $form->{OUT} = "$sendmail";

    if ($form->{emailed} !~ /$form->{formname}/) {
      $form->{emailed} .= " $form->{formname}";
      $form->{emailed} =~ s/^ //;

      # save status
      $form->update_status(\%myconfig);
    }

    $now = scalar localtime;
    $cc = $locale->text('Cc').qq|: $form->{cc}\n| if $form->{cc};
    $bcc = $locale->text('Bcc').qq|: $form->{bcc}\n| if $form->{bcc};
    
    $old_form->{intnotes} = qq|$old_form->{intnotes}\n\n| if $old_form->{intnotes};
    $old_form->{intnotes} .= qq|[email]
|.$locale->text('Date').qq|: $now
|.$locale->text('E-mail to').qq| $form->{email}
$cc${bcc}|.$locale->text('Subject').qq|: $form->{subject}\n|;

    $old_form->{intnotes} .= qq|\n|.$locale->text('Message').qq|: |;
    $old_form->{intnotes} .= ($form->{message}) ? $form->{message} : $locale->text('sent');

    $old_form->{message} = $form->{message};
    $old_form->{emailed} = $form->{emailed};

    $old_form->{format} = "postscript";
    $old_form->{media} = "printer";

    $old_form->save_intnotes(\%myconfig, ($order) ? 'oe' : lc $ARAP);
    
    %audittrail = ( tablename	=> ($order) ? 'oe' : lc $ARAP,
                    reference	=> $form->{"${inv}number"},
		    formname	=> $form->{formname},
		    action	=> 'emailed',
		    id		=> $form->{id} );
 
    $old_form->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);
  }


  if ($form->{media} eq 'queue') {
    %queued = split / /, $form->{queued};
    
    if ($filename = $queued{$form->{formname}}) {
      $form->{queued} =~ s/$form->{formname} $filename//;
      unlink "$spool/$filename";
      $filename =~ s/\..*$//g;
    } else {
      $filename = time;
      $filename .= $$;
    }

    $filename .= ($form->{format} eq 'postscript') ? '.ps' : '.pdf';
    $form->{OUT} = ">$spool/$filename";

    $form->{queued} .= " $form->{formname} $filename";
    $form->{queued} =~ s/^ //;

    # save status
    $form->update_status(\%myconfig);

    $old_form->{queued} = $form->{queued};
    
    %audittrail = ( tablename	=> ($order) ? 'oe' : lc $ARAP,
                    reference	=> $form->{"${inv}number"},
		    formname	=> $form->{formname},
		    action	=> 'queued',
		    id		=> $form->{id} );
 
    $old_form->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);
    
  }

  $form->{fileid} = $form->{"${inv}number"};
  $form->{fileid} =~ s/(\s|\W)+//g;

	# check the 'printed' status directly from the database
	if (!$form->{print_preview} && ($form->{media} =~ /^(printer|screen)$/ && $form->{format} =~ /^(postscript|pdf)$/)) {
		my $dbh = $form->dbconnect_noauto (\%myconfig);
		$query = "SELECT printed, formname FROM status WHERE trans_id = '$form->{id}';";
		$sth = $dbh->prepare ($query);
		$sth->execute || $form->dberror ($query);
		while ($ref = $sth->fetchrow_hashref (NAME_lc) ) {
			$form->{printed} .= "$ref->{formname} " if $ref->{printed};
			}
		$sth->finish;
		$form->{printed} =~ s/ +$//;
		}

#mEGYA. ==============innentõl csúnyán elágaztatva==========
	if ($form->{IN} eq "invoice.tex") {
		undef @{$form->{copy}};
		for $i (1 .. $form->{copies}) {
			push  @{$form->{copy}}, $i;
                }
                $form->{substr($form->{path},0,1)} = $locale->text(substr($form->{path},0,1));
                $form->parse_template(\%myconfig, $userspath);
	}else {
#kabai

  my $copy = $form->{copies};
  $form->{copies} = 1;
  $form->{ordtotal}=$form->format_amount(\%myconfig, $form->{oldinvtotal});
  $form->{subtotal}=$form->format_amount(\%myconfig, $form->parse_amount(\%myconfig, $form->{subtotal}),0);
  $i=0;
  foreach $j (@{ $form->{tax}}){
    $form->{tax}[0]=$form->format_amount(\%myconfig, $form->parse_amount(\%myconfig, $form->{tax}[0]),0);
    $i++;
  }  
  if ($form->{printed} || $form->{media} eq "screen" || $form->{e_mail}){
    $form->{copysum} = "";
    $form->{copynumber} = "Az eredetivel megegyezõ példány";
    #$form->parse_template(\%myconfig, $userspath);
    $form->old_parse_template(\%myconfig, $userspath);
  }else{

    for $k (1..$copy){

	$form->{copynumber} = "$k. példány";
        $form->{copysum} = "A számla $copy példányban készült";
        #$form->parse_template(\%myconfig, $userspath);
	$form->old_parse_template(\%myconfig, $userspath);
    }

  }
#kabai
		}
#mEGYA. ==============idáig========================

  if (!$form->{print_preview} && ($form->{media} =~ /^(printer|screen)$/ && $form->{format} =~ /^(postscript|pdf)$/)) {
    if ($form->{printed} !~ /$form->{formname}/) {
    
      $form->{printed} .= " $form->{formname}";
      $form->{printed} =~ s/^ //;

      $form->update_status(\%myconfig);
    }

    %audittrail = ( tablename	=> ($order) ? 'oe' : lc $ARAP,
                    reference	=> $form->{"${inv}number"},
		    formname	=> $form->{formname},
		    action	=> 'printed',
		    id		=> $form->{id} );
 
    if (defined ($old_form)) {
      $old_form->{printed} = $form->{printed};
      $old_form->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);
      }
    
  }

  # if we got back here restore the previous form
  if ($old_form) {
    
    $old_form->{"${inv}number"} = $form->{"${inv}number"};
    
    # restore and display form
    map { $form->{$_} = $old_form->{$_} } keys %$old_form;
    
    $form->{rowcount}--;
    map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(exchangerate creditlimit creditremaining);
    
    for $i (1 .. $form->{paidaccounts}) {
      map { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) } qw(paid exchangerate);
    }
    &{ "$display_form" };
    
  }

}


sub customer_details {

  IS->customer_details(\%myconfig, \%$form);

}


sub vendor_details {

  IR->vendor_details(\%myconfig, \%$form);

}


sub post_as_new {

  $form->{postasnew} = 1;
  map { delete $form->{$_} } qw(printed emailed queued);
#kabai
  $form->isblank("invnumber",$locale->text('Invoice Number missing!'));
  for my $i(0..$form->{rowcount} -1){
   $form->{"sellprice_$i"} = 0;
  }
#kabai
  &post;

}


sub ship_to {

  $title = $form->{title};
  $form->{title} = $locale->text('Ship to');

  map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(exchangerate creditlimit creditremaining);

  # get details for name
  &{ "$form->{vc}_details" };

  $number = ($form->{vc} eq 'customer') ? $locale->text('Customer Number') : $locale->text('Vendor Number');

  $nextsub = ($form->{display_form}) ? $form->{display_form} : "display_form";

  $form->{rowcount}--;

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <td>
      <table>
	<tr class=listheading>
	  <th class=listheading colspan=2 width=50%>|.$locale->text('Billing Address').qq|</th>
	  <th class=listheading width=50%>|.$locale->text('Shipping Address').qq|</th>
	</tr>
	<tr height="5"></tr>
	<tr>
	  <th align=right nowrap>$number</th>
	  <td>$form->{"$form->{vc}number"}</td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Company Name').qq|</th>
	  <td>$form->{name}</td>
	  <td><input name=shiptoname size=35 maxlength=64 value="$form->{shiptoname}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Address').qq|</th>
	  <td>$form->{address1}</td>
	  <td><input name=shiptoaddress1 size=35 maxlength=32 value="$form->{shiptoaddress1}"></td>
	</tr>
	<tr>
	  <th></th>
	  <td>$form->{address2}</td>
	  <td><input name=shiptoaddress2 size=35 maxlength=32 value="$form->{shiptoaddress2}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('City').qq|</th>
	  <td>$form->{city}</td>
	  <td><input name=shiptocity size=35 maxlength=32 value="$form->{shiptocity}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('State/Province').qq|</th>
	  <td>$form->{state}</td>
	  <td><input name=shiptostate size=35 maxlength=32 value="$form->{shiptostate}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('ZIP/Code').qq|</th>
	  <td>$form->{zipcode}</td>
	  <td><input name=shiptozipcode size=10 maxlength=10 value="$form->{shiptozipcode}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Country').qq|</th>
	  <td>$form->{country}</td>
	  <td><input name=shiptocountry size=35 maxlength=32 value="$form->{shiptocountry}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Contact').qq|</th>
	  <td>$form->{contact}</td>
	  <td><input name=shiptocontact size=35 maxlength=64 value="$form->{shiptocontact}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Phone').qq|</th>
	  <td>$form->{"$form->{vc}phone"}</td>
	  <td><input name=shiptophone size=20 value="$form->{shiptophone}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Fax').qq|</th>
	  <td>$form->{"$form->{vc}fax"}</td>
	  <td><input name=shiptofax size=20 value="$form->{shiptofax}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('E-mail').qq|</th>
	  <td>$form->{email}</td>
	  <td><input name=shiptoemail size=35 value="$form->{shiptoemail}"></td>
	</tr>
      </table>
    </td>
  </tr>
</table>

<input type=hidden name=nextsub value=$nextsub>
|;

  # delete shipto
  map { delete $form->{$_} } qw(shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail header);
  $form->{title} = $title;
  
  $form->hide_form();

  print qq|

<hr size=3 noshade>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;
}




