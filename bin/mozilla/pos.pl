#=====================================================================
# SQL-Ledger Accounting
# Copyright (c) 1998-2003
#
#=====================================================================
#
# POS
#
#=====================================================================


1;
# end


sub add {

  $form->{title} = $locale->text('Add POS Invoice');

  $form->{callback} = "$form->{script}?action=$form->{nextsub}&path=$form->{path}&login=$form->{login}&password=$form->{password}" unless $form->{callback};
  
  &invoice_links;

  $form->{type} =  "pos_invoice";
  $form->{format} = "txt";
  $form->{media} = "screen";
  $form->{rowcount} = 0;

  $ENV{REMOTE_ADDR} =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
  $form->{till} = $4;

  $form->get_partsgroup(\%myconfig);

  if (@{ $form->{all_partsgroup} }) {
    map { $form->{partsgroup} .= "$_->{partsgroup}\n" } @{ $form->{all_partsgroup} };
  }
  
  &display_form;

}


sub openinvoices {

 
  $ENV{REMOTE_ADDR} =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
  $form->{till} = $4;
  
  $form->{sort} = 'transdate';

  map { $form->{$_} = 'Y' } qw(open l_invnumber l_transdate l_name l_amount l_till l_subtotal);

  if ($myconfig{admin}) {
    $form->{l_employee} = 'Y';
  }

  $form->{title} = $locale->text('Open');
  &ar_transactions;
  
}


sub edit {

  $form->{title} = $locale->text('Edit POS Invoice');

  $form->{callback} = "$form->{script}?action=$form->{nextsub}&path=$form->{path}&login=$form->{login}&password=$form->{password}" unless $form->{callback};
  
  &invoice_links;
  &prepare_invoice;

  $form->{type} =  "pos_invoice";
  $form->{format} = "txt";
  $form->{media} = "screen";

  $form->get_partsgroup(\%myconfig);
  
  if (@{ $form->{all_partsgroup} }) {
    map { $form->{partsgroup} .= "$_->{partsgroup}\n" } @{ $form->{all_partsgroup} };
  }
  
  &display_form;

}


sub form_header {

  # set option selected
  foreach $item (qw(AR customer currency)) {
    $form->{"select$item"} =~ s/ selected//;
    $form->{"select$item"} =~ s/option>\Q$form->{$item}\E/option selected>$form->{$item}/;
  }
    
  $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

  $form->{creditlimit} = $form->format_amount(\%myconfig, $form->{creditlimit}, 0, "0");

  if ($form->{oldtotalpaid} > $form->{oldinvtotal}) {
    $adj = $form->{oldtotalpaid} - $form->{oldinvtotal};
  }
  $form->{creditremaining} = $form->format_amount(\%myconfig, $form->{creditremaining} - $adj + $form->{oldchange}, 0, "0");
  
  $exchangerate = "";
  if ($form->{currency} ne $form->{defaultcurrency}) {
    if ($form->{forex}) {
      $exchangerate .= qq|<th align=right>|.$locale->text('Exchangerate').qq|</th><td>$form->{exchangerate}<input type=hidden name=exchangerate value=$form->{exchangerate}></td>|;
    } else {
      $exchangerate .= qq|<th align=right>|.$locale->text('Exchangerate').qq|</th><td><input name=exchangerate size=10 value=$form->{exchangerate}></td>|;
    }
  }
  $exchangerate .= qq|
<input type=hidden name=forex value=$form->{forex}>
|;

  $customer = ($form->{selectcustomer}) ? qq|<select name=customer>$form->{selectcustomer}</select>\n<input type=hidden name="selectcustomer" value="$form->{selectcustomer}">| : qq|<input name=customer value="$form->{customer}" size=35>|;
  
  $n = ($form->{creditremaining} =~ /-/) ? "0" : "1";

  $form->header;

 
  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>

<input type=hidden name=till value=$form->{till}>

<input type=hidden name=type value=$form->{type}>
<input type=hidden name=media value=$form->{media}>
<input type=hidden name=format value=$form->{format}>

<input type=hidden name=title value="$form->{title}">
<input type=hidden name=vc value="customer">
<input type=hidden name=employee value="$form->{employee}">

<input type=hidden name=discount value=$form->{discount}>
<input type=hidden name=creditlimit value=$form->{creditlimit}>
<input type=hidden name=creditremaining value=$form->{creditremaining}>

<input type=hidden name=closedto value=$form->{closedto}>
<input type=hidden name=locked value=$form->{locked}>

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</font></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Record in').qq|</th>
		<td><select name=AR>$form->{selectAR}</select></td>
		<input type=hidden name=selectAR value="$form->{selectAR}">
	      </tr>     
	      <tr>
		<th align=right nowrap>|.$locale->text('Customer').qq|</th>
		<td>$customer</td>
		<input type=hidden name=customer_id value=$form->{customer_id}>
		<input type=hidden name=oldcustomer value="$form->{oldcustomer}"> 
	      </tr>
	      $discount
	    </table>
	  </td>
	  <td>
	    <table>
	      <tr>
		<td></td>
		<td>
		  <table width=100%>
		    <tr>
		      <th align=left nowrap>|.$locale->text('Credit Limit').qq|</th>
		      <td>$form->{creditlimit}</td>
		      <th align=left nowrap>|.$locale->text('Remaining').qq|</th>
		      <td class="plus$n">$form->{creditremaining}</font></td>
		    </tr>
		  </table>
		</td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td><select name=currency>$form->{selectcurrency}</select></td>
		<input type=hidden name=selectcurrency value="$form->{selectcurrency}">
		<input type=hidden name=defaultcurrency value=$form->{defaultcurrency}>
		<input type=hidden name=fxgain_accno value=$form->{fxgain_accno}>
		<input type=hidden name=fxloss_accno value=$form->{fxloss_accno}>
		$exchangerate
	      </tr>
	    </table>
	  </td>
	<input type=hidden name=invnumber value=$form->{invnumber}>
	<input type=hidden name=invdate value=$form->{invdate}>
	<input type=hidden name=duedate value=$form->{duedate}>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
    </td>
  </tr>


<input type=hidden name=taxaccounts value="$form->{taxaccounts}">
|;

  foreach $item (split / /, $form->{taxaccounts}) {
    print qq|
<input type=hidden name="${item}_rate" value="$form->{"${item}_rate"}">
<input type=hidden name="${item}_description" value="$form->{"${item}_description"}">
<input type=hidden name="${item}_taxnumber" value="$form->{"${item}_taxnumber"}">
|;
  }

}



sub form_footer {

  $form->{invtotal} = $form->{invsubtotal};
  
  foreach $item (split / /, $form->{taxaccounts}) {
    if ($form->{"${item}_base"}) {
      $form->{"${item}_total"} = $form->round_amount($form->{"${item}_base"} * $form->{"${item}_rate"}, 2);
      $form->{invtotal} += $form->{"${item}_total"};
      $form->{"${item}_total"} = $form->format_amount(\%myconfig, $form->{"${item}_total"}, 2, 0);
      
      $tax .= qq|
	    <tr>
	      <th align=right>$form->{"${item}_description"}</th>
	      <td align=right>$form->{"${item}_total"}</td>
	    </tr>
|;
    }
  }



  $form->{invsubtotal} = $form->format_amount(\%myconfig, $form->{invsubtotal}, 2, 0);

  $subtotal = qq|
	      <tr>
		<th align=right>|.$locale->text('Subtotal').qq|</th>
		<td align=right>$form->{invsubtotal}</td>
	      </tr>
|;


  $totalpaid = 0;
  
  $form->{paidaccounts} = 1;
  $i = 1;
  
  $form->{"selectAR_paid_$i"} = $form->{selectAR_paid};
  $form->{"selectAR_paid_$i"} =~ s/option>\Q$form->{"AR_paid_$i"}\E/option selected>$form->{"AR_paid_$i"}/;
  
  # format amounts
  $totalpaid += $form->{"paid_$i"};
  $form->{"paid_$i"} = $form->format_amount(\%myconfig, $form->{"paid_$i"}, 2);
  $form->{"exchangerate_$i"} = $form->format_amount(\%myconfig, $form->{"exchangerate_$i"});
  
  $form->{change} = 0;
  if ($totalpaid > $form->{invtotal}) {
    $form->{change} = $totalpaid - $form->{invtotal};
  }
  $form->{oldchange} = $form->{change};
  $form->{change} = $form->format_amount(\%myconfig, $form->{change}, 2, 0);
  $form->{totalpaid} = $form->format_amount(\%myconfig, $totalpaid, 2);

 
  $form->{oldinvtotal} = $form->{invtotal};
  $form->{invtotal} = $form->format_amount(\%myconfig, $form->{invtotal}, 2, 0);
  
 
  print qq|

<input type=hidden name="exchangerate_$i" value=$form->{"exchangerate"}>
<input type=hidden name="forex_$i" value=$form->{"forex_$i"}>

  <tr>
    <td>
      <table width=100%>
	<tr valign=bottom>
	  <td>
	    <table>
	      <tr>
                <th align=right>|.$locale->text('Paid').qq|</th>
		<td><input name="paid_$i" size=11 value=$form->{"paid_$i"}></td>
		<td><input name="source_$i" size=10 value="$form->{"source_$i"}"></td>
	        <td><select name="AR_paid_$i">$form->{"selectAR_paid_$i"}</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Change').qq|</th>
		<th>$form->{change}</th>
	      </tr>
	    </table>
	  </td>
	  <td align=right>
	    $taxincluded
	    <table>
	      $subtotal
	      $tax
	      <tr>
		<th align=right>|.$locale->text('Total').qq|</th>
		<td align=right>$form->{invtotal}</td>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
 
<input type=hidden name=paidaccounts value=$form->{paidaccounts}>
<input type=hidden name=selectAR_paid value="$form->{selectAR_paid}">
<input type=hidden name=oldinvtotal value=$form->{oldinvtotal}>
<input type=hidden name=oldtotalpaid value=$totalpaid>

<input type=hidden name=change value=$form->{change}>
<input type=hidden name=oldchange value=$form->{oldchange}>

<input type=hidden name=datepaid value=$form->{invdate}>
<input type=hidden name=invtotal value=$form->{invtotal}>

<tr>
  <td>
|;

  &print_options;

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $invdate = $form->datetonum($form->{invdate}, \%myconfig);
  $closedto = $form->datetonum($form->{closedto}, \%myconfig);
 
  if ($invdate > $closedto) {
    print qq|
      <input class=submit type=submit name=action value="|.$locale->text('Update').qq|">
      <input class=submit type=submit name=action value="|.$locale->text('Print').qq|">
      <input class=submit type=submit name=action value="|.$locale->text('Post').qq|">|;

    if ($form->{id} && $myconfig{admin}) {
      print qq|
      <input class=submit type=submit name=action value="|.$locale->text('Delete').qq|">|;
    }
  }

  print "<p>\n";
  
  if ($form->{partsgroup}) {
    print qq|
<input type=hidden name=nextsub value=lookup_partsgroup>
<input type=hidden name=partsgroup value="$form->{partsgroup}">|;

    foreach $item (split /\n/, $form->{partsgroup}) {
      $item =~ s///;
      print qq| <input class=submit type=submit name=action value=" $item">\n|;
    }
  }

  print qq|

<input type=hidden name=rowcount value=$form->{rowcount}>

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=password value=$form->{password}>

</form>

</body>
</html>
|;

}


sub post {

  $form->isblank("customer", $locale->text('Customer missing!'));

  # if oldcustomer ne customer redo form
  $customer = $form->{customer};
  $customer =~ s/--.*//g;
  $customer .= "--$form->{customer_id}";
  if ($customer ne $form->{oldcustomer}) {
    &update;
    exit;
  }
 
  &validate_items;

  $form->isblank("exchangerate", $locale->text('Exchangerate missing!')) if ($form->{currency} ne $form->{defaultcurrency});
  
  $paid = $form->parse_amount(\%myconfig, $form->{"paid_1"});
  $total = $form->parse_amount(\%myconfig, $form->{invtotal});

  $form->{"paid_1"} = $form->{invtotal} if $paid > $total;
  
  ($form->{AR}) = split /--/, $form->{AR};
  
  $form->redirect($locale->text('Posted!')) if (IS->post_invoice(\%myconfig, \%$form));
  $form->error($locale->text('Cannot post transaction!'));
    
}


sub display_row {
  my $numrows = shift;

  @column_index = qw(partnumber description partsgroup qty unit sellprice discount linetotal);
    
  $form->{invsubtotal} = 0;

  map { $form->{"${_}_base"} = 0 } (split / /, $form->{taxaccounts});
  
  $column_data{partnumber} = qq|<th class=listheading nowrap>|.$locale->text('Number').qq|</th>|;
  $column_data{description} = qq|<th class=listheading nowrap>|.$locale->text('Description').qq|</th>|;
  $column_data{qty} = qq|<th class=listheading nowrap>|.$locale->text('Qty').qq|</th>|;
  $column_data{unit} = qq|<th class=listheading nowrap>|.$locale->text('Unit').qq|</th>|;
  $column_data{sellprice} = qq|<th class=listheading nowrap>|.$locale->text('Price').qq|</th>|;
  $column_data{linetotal} = qq|<th class=listheading nowrap>|.$locale->text('Extended').qq|</th>|;
  $column_data{discount} = qq|<th class=listheading nowrap>|.$locale->text('Disc').qq|</th>|;
  
  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  map { print "\n$column_data{$_}" } @column_index;

  print qq|
        </tr>
|;

  
  for $i (1 .. $numrows) {
    # undo formatting
    map { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) } qw(qty discount sellprice);

    ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
    $dec = length $dec;
    $decimalplaces = ($dec > 2) ? $dec : 2;

    if ($i < $numrows) {
      if ($form->{"discount_$i"} != $form->{discount} * 100) {
	$form->{"discount_$i"} = $form->{discount} * 100;
      }
    }
    
    $discount = $form->round_amount($form->{"sellprice_$i"} * $form->{"discount_$i"}/100, $decimalplaces);
    $linetotal = $form->round_amount($form->{"sellprice_$i"} - $discount, $decimalplaces);
    $linetotal = $form->round_amount($linetotal * $form->{"qty_$i"}, 2);

    # convert " to &quot;
    map { $form->{"${_}_$i"} =~ s/"/&quot;/g } qw(partnumber description partsgroup unit);
    
    $column_data{partnumber} = qq|<td><input name="partnumber_$i" size=20 value="$form->{"partnumber_$i"}"></td>|;

    if (($rows = $form->numtextrows($form->{"description_$i"}, 30, 6)) > 1) {
      $column_data{description} = qq|<td><textarea name="description_$i" rows=$rows cols=30 wrap=soft>$form->{"description_$i"}</textarea></td>|;
    } else {
      $column_data{description} = qq|<td><input name="description_$i" size=30 value="$form->{"description_$i"}"></td>|;
    }

    $column_data{partsgroup} = qq|<input type=hidden name="partsgroup_$i" value="$form->{"partsgroup_$i"}">|;

    $column_data{qty} = qq|<td align=right><input name="qty_$i" size=5 value=|.$form->format_amount(\%myconfig, $form->{"qty_$i"}).qq|></td>|;
    $column_data{unit} = qq|<td><input type=hidden name="unit_$i" value="$form->{"unit_$i"}">$form->{"unit_$i"}</td>|;
    $column_data{sellprice} = qq|<td align=right><input name="sellprice_$i" size=9 value=|.$form->format_amount(\%myconfig, $form->{"sellprice_$i"}, $decimalplaces).qq|></td>|;
    $column_data{linetotal} = qq|<td align=right>|.$form->format_amount(\%myconfig, $linetotal, 2).qq|</td>|;
    

    $discount = $form->format_amount(\%myconfig, $form->{"discount_$i"});
    $column_data{discount} = qq|<td align=right>$discount</td>
    <input type=hidden name="discount_$i" value=$discount>|;
    
    print qq|
        <tr valign=top>|;

    map { print "\n$column_data{$_}" } @column_index;
  
    print qq|
        </tr>

<input type=hidden name="id_$i" value=$form->{"id_$i"}>
<input type=hidden name="inventory_accno_$i" value=$form->{"inventory_accno_$i"}>
<input type=hidden name="income_accno_$i" value=$form->{"income_accno_$i"}>
<input type=hidden name="expense_accno_$i" value=$form->{"expense_accno_$i"}>
<input type=hidden name="listprice_$i" value="$form->{"listprice_$i"}">
<input type=hidden name="assembly_$i" value="$form->{"assembly_$i"}">
<input type=hidden name="taxaccounts_$i" value="$form->{"taxaccounts_$i"}">

|;

    map { $form->{"${_}_base"} += $linetotal } (split / /, $form->{"taxaccounts_$i"});
  
    $form->{invsubtotal} += $linetotal;
  }

  print qq|
      </table>
    </td>
  </tr>
|;

}


sub print {
  
  $paid = $form->parse_amount(\%myconfig, $form->{"paid_1"});
  $total = $form->parse_amount(\%myconfig, $form->{invtotal});

  $form->{change} = 0;
  if ($paid > $total) {
    $form->{paid} = $total - $paid;
    $form->{"paid_1"} = $form->format_amount(\%myconfig, $paid, 2, 0);
    $form->{change} = $form->format_amount(\%myconfig, $paid - $total, 2, 0);
  }


  $old_form = new Form;
  map { $old_form->{$_} = $form->{$_} } keys %$form;

  $form->{invtime} = scalar localtime;

  &print_form($old_form);

}


sub print_form {
  my $old_form = shift;

  # if oldcustomer ne customer redo form
  $customer = $form->{customer};
  $customer =~ s/--.*//g;
  $customer .= "--$form->{customer_id}";
  if ($customer ne $form->{oldcustomer}) {
    &update;
    exit;
  }
  
 
  &validate_items;

  &{ "$form->{vc}_details" };

  @a = ();
  map { push @a, ("partnumber_$_", "description_$_") } (1 .. $form->{rowcount});
  map { push @a, "${_}_description" } split / /, $form->{taxaccounts};
  $form->format_string(@a);

  # format payment dates
  map { $form->{"datepaid_$_"} = $locale->date(\%myconfig, $form->{"datepaid_$_"}) } (1 .. $form->{paidaccounts});
  
  map { $myconfig{$_} =~ s/\\n/ /g } qw(company address);
  
  IS->invoice_details(\%myconfig, \%$form);

  $form->{templates} = "$myconfig{templates}";
  $form->{IN} = "$form->{type}.$form->{format}";

  if ($form->{media} eq 'printer') {
    $form->{OUT} = "| $myconfig{printer}";
  }

  $form->{discount} = $form->format_amount(\%myconfig, $form->{discount} * 100);
  
  $form->{rowcount}--;
  $form->{pre} = "<body>\n<pre>";
  $form->parse_template(\%myconfig, $userspath);

  # if we got back here restore the previous form
  if ($form->{media} eq 'printer') {
    if ($old_form) {
      # restore and display form
      map { $form->{$_} = $old_form->{$_} } keys %$old_form;
      map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(exchangerate creditlimit creditremaining);

      $form->{rowcount}--;
      for $i (1 .. $form->{paidaccounts}) {
	map { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) } qw(paid exchangerate);
      }
      
      delete $form->{pre};

      &display_form;
      exit;
    }
  }

}


sub lookup_partsgroup {

  $form->{action} =~ s///;
  $form->{"partsgroup_$form->{rowcount}"} = substr($form->{action}, 1);
  &update;

}



sub print_options {

  $form->{PD}{$form->{type}} = "checked";
  $form->{OP}{$form->{media}} = "checked";
  
  print qq|
<input type=hidden name=format value=txt>

<table>
  <tr valign=top>

    <td align=right><input class=radio type=radio name=media value=screen $form->{OP}{screen}></td>
    <td>|.$locale->text('Screen').qq|</td>
|;

  if ($myconfig{printer}) {
    print qq|
    <td align=right><input class=radio type=radio name=media value=printer $form->{OP}{printer}></td>
    <td>|.$locale->text('Printer')
    .qq|</td>
|;
  }

  print qq|
  </tr>
</table>
|;

}


sub receipts {

  $form->{title} = $locale->text('Receipts');

  $form->{db} = 'ar';
  RP->paymentaccounts(\%myconfig, \%$form);
  
  map { $paymentaccounts .= "$_->{accno} " } @{ $form->{PR} };

  $form->{till} = ($myconfig{admin}) ? '0' : '1';

  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=title value="$form->{title}">
<input type=hidden name=paymentaccounts value="$paymentaccounts">

<input type=hidden name=till value=1>
<input type=hidden name=subtotal value=1>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
      
        <input type=hidden name=nextsub value=list_payments>
	
        <tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=fromdate size=11 title="$myconfig{dateformat}" value=$form->{fromdate}></td>
	  <th align=right>|.$locale->text('to').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}"></td>
	</tr>
	  <input type=hidden name=sort value=transdate>
	  <input type=hidden name=db value=$form->{db}>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=password value=$form->{password}>

<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">

</form>

</body>
</html>
|;

}


