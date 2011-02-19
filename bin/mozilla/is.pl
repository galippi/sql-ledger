#=====================================================================
# SQL-Ledger Accounting
# Copyright (c) 2001
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
#======================================================================
#
# Inventory invoicing module
#
#======================================================================


use SL::IS;
use SL::PE;
#kabai
use SL::CP;
use SL::OE;
use SL::CORE2;
#kabai

require "$form->{path}/io.pl";
require "$form->{path}/arap.pl";


1;
# end of main



sub add {
  $form->{title} = $locale->text('Add Sales Invoice');

  $form->{callback} = "$form->{script}?action=add&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}" unless $form->{callback};

  &invoice_links;
  &prepare_invoice;
  &display_form;
  
}

sub add_cash { #kabai #obsolete

  $form->{title} = $locale->text('Add Sales Cash Invoice');

  $form->{cash_invoice} = 1;
    
  $form->{callback} = "$form->{script}?action=add_cash&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}&cash_invoice=$form->{cash_invoice}" unless $form->{callback};

 
  &invoice_links;
  &prepare_invoice;
  &display_form;
  
}

sub add_new {#kabai

  my $stnumber = $form->{invnumber};
  $form->{old_id} = $form->{id};
  map { delete $form->{$_}} qw(id invnumber printed emailed selectcurrency selectcustomer selectdepartment selectAR selectAR_paid);
  for my $sh (1..$form->{rowcount}){
      delete $form->{"ship_$sh"};
      delete $form->{"invoice_id_$sh"};
  }

  $form->{rowcount}--;
  $form->{cash_invoice} = 1 if $form->{paid_1};
  for my $stp (1..$form->{paidaccounts}-1){
        $form->{"paid_$stp"} = $form->parse_amount(\%myconfig, $form->{"paid_$stp"});
  }
  my $transdate_orig = $form->{transdate};
  my $duedate_orig = $form->{duedate};
  my $currency_orig = $form->{currency}; 
  my $shipvia_orig = $form->{shipvia};
  my $shippingpoint_orig = $form->{shippingpoint}; 


  $form->{reversing} = "" if ($form->{reversing} && $form->{correcting});

  if ($form->{reversing} || $form->{correcting}){
      my $qstext;
      $qstext = $form->{reversing} ? "qty" : "sellprice";
      for my $st (1..$form->{rowcount}){
        $form->{"${qstext}_$st"} = $form->format_amount(\%myconfig, $form->parse_amount(\%myconfig,$form->{"${qstext}_$st"}) * -1);
      }
      for my $stp (1..$form->{paidaccounts}-1){
        $form->{"paid_$stp"} = $form->parse_amount(\%myconfig, $form->{"paid_$stp"}) * -1;
      }
  $form->{stnotes} = $stnumber." ".$locale->text('Invoice reversing');
  $form->{stnotes} = $stnumber." ".$locale->text('Invoice correcting') if $form->{correcting}; 
  }
  $form->{szeta} = $form->{szeta1};
  if ($form->{szeta}){
    $form->{title} = $locale->text('Add invoice-like document');
  }else{
    $form->{title} = $locale->text('Add Sales Invoice');
  }  
  $form->{type} = "invoice";
  $form->{callback} = "$form->{script}?action=add&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}" unless $form->{callback};
  map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(creditlimit creditremaining);  
  &invoice_links;
  &prepare_invoice;
  $form->{creditremaining} -= ($form->{oldinvtotal} - $form->{ordtotal});
  $form->{transdate} = $transdate_orig;
  $form->{duedate} = $duedate_orig;
  $form->{currency} = $currency_orig;
  $form->{shipvia} = $shipvia_orig;
  $form->{shippingpoint} = $shippingpoint_orig; 

  &display_form;
}#kabai

sub edit {

  $form->{title} = $locale->text('Edit Sales Invoice');

  &invoice_links;
#kabai
  $form->{oddordnumber} = $form->{ordnumber};
  $form->{ordnumber} = "0";
#kabai
  &prepare_invoice;
  &display_form;
  
}


sub invoice_links {

  $form->{vc} = 'customer';

  # create links
  $form->{showaccnumbers_true} = $showaccnumbers_true;
  $form->create_links("AR", \%myconfig, "customer");

  # currencies
  @curr = split /:/, $form->{currencies};
  chomp $curr[0];
  $form->{defaultcurrency} = $curr[0];

  map { $form->{selectcurrency} .= "<option>$_\n" } @curr;

  if ($form->{all_customer}) {
    unless ($form->{customer_id}) {
      $form->{customer_id} = $form->{all_customer}->[0]->{id};
    }
  }
#kabai
  CORE2->get_whded(\%myconfig, \%$form);
#kabai
  IS->get_customer(\%myconfig, \%$form);
  IS->retrieve_invoice(\%myconfig, \%$form);
  $form->get_partsgroup(\%myconfig);
  IS->invoice_address(\%myconfig, \%$form) if ($form->{id});
  if (@{ $form->{all_partsgroup} }) {
    $form->{selectpartsgroup} = "<option>\n";
    map { $form->{selectpartsgroup} .= qq|<option value="$_->{partsgroup}--$_->{id}">$_->{partsgroup}\n| } @{ $form->{all_partsgroup} };
  }

  if (@{ $form->{all_projects} }) {
    $form->{selectprojectnumber} = "<option>\n";
    map { $form->{selectprojectnumber} .= qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n| } @{ $form->{all_projects} };
  }

  $form->{oldcustomer} = "$form->{customer}--$form->{customer_id}";
  $form->{oldtransdate} = $form->{transdate};
  
  if ($form->{all_customer}) {
    $form->{customer} = "$form->{customer}--$form->{customer_id}";
    map { $form->{selectcustomer} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| } (@{ $form->{all_customer} });
  }

  # registered ordnumbers
  if (@{$form->{all_ordnumbers}}) {
     $form->{selectordnumber} = qq|<option value="0">| . $locale->text("odd number") . qq|</option>\n|;
     map { $form->{selectordnumber} .= qq|<option value="$_->{regnumber}">$_->{regnumber}</option>\n| } (@{$form->{all_ordnumbers}});
  }


  # departments
  if ($form->{all_departments}) {
    $form->{selectdepartment} = "<option>\n";
    $form->{department} = "$form->{department}--$form->{department_id}";

    map { $form->{selectdepartment} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| } (@{ $form->{all_departments} });
  }
  
  $form->{employee} = "$form->{employee}--$form->{employee_id}";
  # sales staff
  if ($form->{all_employees}) {
    $form->{selectemployee} = "";
    map { $form->{selectemployee} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| } (@{ $form->{all_employees} });
  }
  
  if (@{ $form->{all_languages} }) {
    $form->{selectlanguage} = "<option>\n";
    map { $form->{selectlanguage} .= qq|<option value="$_->{code}">$_->{description}\n| } @{ $form->{all_languages} };
  }
  
  # forex
  $form->{forex} = $form->{exchangerate};
  $exchangerate = ($form->{exchangerate}) ? $form->{exchangerate} : 1;
  

  foreach $key (keys %{ $form->{AR_links} }) {
    foreach $ref (@{ $form->{AR_links}{$key} }) {
      $form->{"select$key"} .= "<option>$ref->{accno}--$ref->{description}\n";
    }

    if ($key eq "AR_paid") {
      for $i (1 .. scalar @{ $form->{acc_trans}{$key} }) {
	$form->{"AR_paid_$i"} = "$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";
	# reverse paid
	$form->{"paid_$i"} = $form->{acc_trans}{$key}->[$i-1]->{amount} * -1;
	$form->{"datepaid_$i"} = $form->{acc_trans}{$key}->[$i-1]->{transdate};
	$form->{"forex_$i"} = $form->{"exchangerate_$i"} = $form->{acc_trans}{$key}->[$i-1]->{exchangerate};
	$form->{"source_$i"} = $form->{acc_trans}{$key}->[$i-1]->{source};
	$form->{"memo_$i"} = $form->{acc_trans}{$key}->[$i-1]->{memo};
	
	$form->{paidaccounts} = $i;
      }
    } else {
      $form->{$key} = "$form->{acc_trans}{$key}->[0]->{accno}--$form->{acc_trans}{$key}->[0]->{description}";
    }
    
  }

  $form->{paidaccounts} = 1 unless (exists $form->{paidaccounts});

  $form->{AR} = $form->{AR_1} unless $form->{id};
  
  $form->{locked} = ($form->{revtrans}) ? '1' : ($form->datetonum($form->{transdate}, \%myconfig) <= $form->datetonum($form->{closedto}, \%myconfig));

  $form->{readonly} = 1 if $myconfig{acs} =~ /AR--Sales Invoice/;
#kabai
  # registered sources

  $form->{selectregsource} = qq|<option value=0>| . $locale->text("odd number") . qq|</option>\n|;
  while ($form->{selectAR_paid} =~ /<option>(\d+)/g){
      map { $form->{selectregsource} .= qq|<option value=$_->{regnum}>$_->{regnum}</option>\n| if ($_->{regnum_accno} eq $1 && !$_->{regcheck})} (@{$form->{all_sources}});
  }					      
      map { $form->{"regacc_$_->{regnum_accno}"} = "$_->{regnum}" if !$_->{regcheck}; $form->{regaccounts} .= "$_->{regnum_accno}"." " if !$_->{regcheck}} (@{$form->{all_sources}});
#kabai

#  $form->{oldshipvia} = $form->{shipvia} = $form->{terms} ? $locale->text("Transfer") : $locale->text("Cash") ; 
}


sub prepare_invoice {

  $form->{type} = "invoice";
  $form->{formname} = "invoice";
#kabai
  $form->{format} = "$myconfig{prformat}";
  $form->{media} = "$myconfig{prmedia}";
  
  $form->{oldcurrency} = $form->{currency};
  
  if ($form->{id}) {
    
    map { $form->{$_} = $form->quote($form->{$_}) } qw(invnumber ordnumber quonumber shippingpoint shipvia notes intnotes);

    foreach $ref (@{ $form->{invoice_details} } ) {
      $i++;
      map { $form->{"${_}_$i"} = $ref->{$_} } keys %{ $ref };

      $form->{"projectnumber_$i"} = qq|$ref->{projectnumber}--$ref->{project_id}|;
      $form->{"partsgroup_$i"} = qq|$ref->{partsgroup}--$ref->{partsgroup_id}|;

      $form->{"discount_$i"} = $form->format_amount(\%myconfig, $form->{"discount_$i"} * 100);

      ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
      $dec = length $dec;
      $decimalplaces = ($dec > 2) ? $dec : 2;

      $form->{"sellprice_$i"} = $form->format_amount(\%myconfig, $form->{"sellprice_$i"}, $decimalplaces);
      $form->{"qty_$i"} = $form->format_amount(\%myconfig, $form->{"qty_$i"});
      $form->{"oldqty_$i"} = $form->{"qty_$i"};
      
      map { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) } qw(partnumber sku description unit);
      $form->{rowcount} = $i;
    }
  }
  
}



sub form_header {
  # set option selected
#KS
  PE->retrieve_taxreturn(\%myconfig, \%$form);
  foreach $item (qw(AR currency)) {
    $form->{"select$item"} =~ s/ selected//;
    $form->{"select$item"} =~ s/option>\Q$form->{$item}\E/option selected>$form->{$item}/;
  }

  foreach $item (qw(customer department employee ordnumber)) {
    $form->{"select$item"} = $form->unescape2($form->{"select$item"});
    $form->{"select$item"} =~ s/ selected//;
    $form->{"select$item"} =~ s/(<option value="\Q$form->{$item}\E")/$1 selected/;
  }
    
  $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

  $form->{creditlimit} = $form->format_amount(\%myconfig, $form->{creditlimit}, 0, "0");
  $form->{creditremaining} = $form->format_amount(\%myconfig, $form->{creditremaining}, 0, "0");

  
  $exchangerate = "";
  if ($form->{currency} ne $form->{defaultcurrency}) {
    if ($form->{forex}) {
      $exchangerate .= qq|<th align=right>|.$locale->text('Exchangerate').qq|</th><td>$form->{exchangerate}<input type=hidden name=exchangerate value=$form->{exchangerate}></td>|;
    } else {
      $exchangerate .= qq|<th align=right>|.$locale->text('Exchangerate').qq|</th><td><input name=exchangerate class="required validate-szam" size=10 value=$form->{exchangerate}></td>|;
    }
  }
  $exchangerate .= qq|
<input type=hidden name=forex value=$form->{forex}>
<input type=hidden name=reversing value=$form->{reversing}>
|;
#kabai
 if ($form->{type} eq 'invoice' && $form->{id}){
   if ($ischange_true){
     $classchange = qq|class=change|;
   }else{ 
     $readonly = "readonly";   
   }
 }else{
    $classchange = qq|class="required"|;
 } 
  if ($form->{selectcustomer}) {
   if($readonly) {
    ($form->{customer}) = split /--/, $form->{customer};
    $customer = qq|<input $classchange name=customer $readonly value="$form->{customer}" size=35>|;
   }else{
    $customer = qq|<select $classchange name=customer onchange="this.form.submit()">$form->{selectcustomer}</select>
                   <input type=hidden name="selectcustomer" value="|.
		   $form->escape($form->{selectcustomer},1).qq|">|;
   }
  } else {
    $customer = qq|<input $classchange name=customer $readonly value="$form->{customer}" size=35>|;
  }
  if ($form->{selectcurrency}){
    if($readonly) {
      $currency = qq|<input name=currency $readonly value="$form->{currency}" size=3>|;
    }else{
      $currency = qq|<select $classchange name=currency>$form->{selectcurrency}</select>|;
    }  
  }  
  $department = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Department').qq|</th>
		<td colspan=3><select name=department>$form->{selectdepartment}</select>
		<input type=hidden name=selectdepartment value="|.
		$form->escape($form->{selectdepartment},1).qq|">
		</td>
	      </tr>
| if $form->{selectdepartment};


  $n = ($form->{creditremaining} =~ /-/) ? "0" : "1";


  if ($form->{business}) {
    $business = qq|
	      <tr>
		<th align=right>|.$locale->text('Business').qq|</th>
		<td>$form->{business}</td>
		<th align=right>|.$locale->text('Trade Discount').qq|</th>
		<td>|.$form->format_amount(\%myconfig, $form->{tradediscount} * 100).qq| %</td>
	      </tr>
|;
  }

#kabai
  if (!$form->{id}){
  $form->{shipvia} = ($form->{oldshipvia} eq $form->{shipvia}) ? $form->{oldshipvia} : $form->{shipvia};
  
  $form->{datepaid_1} = $form->{crdate} if $form->{shipvia} eq $locale->text("Cash");
  }


  $i = $form->{rowcount};
  $focus = qq|onLoad="document.forms[0].qty_${i}.select();document.forms[0].qty_${i}.focus()"| if $i;

  if ($form->{selectordnumber} && !$form->{id}){
    $ordnumber = qq|<select name="ordnumber">$form->{selectordnumber}</select><br>\n|;
    $hiddenord = "class=noscreen" if ($form->{ordnumber} ne "0");
    $ordnumbertext = "Register Number";
  } else {
    $ordnumbertext = "Order Number";
  }  
    
   $ordnumber .= qq|<input name="oddordnumber" size="11" $hiddenord value="$form->{oddordnumber}">|; 
#kabai  
  $form->header;
#kabai 377 crdate cash_invoice

  print qq|
<body $focus />
|;
 if ($myconfig{js}) {
print qq|
<script src="js/prototype.js" type="text/javascript"></script>
<script src="js/validation.js" type="text/javascript"></script>
<script src="js/custom.js" type="text/javascript"></script>
|;
}else {
print qq|
<script> function checkform () { return true; }</script>
|;
}  
print qq|
<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>

<input type=hidden name=type value=$form->{type}>
<input type=hidden name=media value=$form->{media}>
<input type=hidden name=format value=$form->{format}>

<input type=hidden name=queued value="$form->{queued}">
<input type=hidden name=printed value="$form->{printed}">
<input type=hidden name=emailed value="$form->{emailed}">

<input type=hidden name=action value="Update">

<input type=hidden name=title value="$form->{title}">
<input type=hidden name=vc value=$form->{vc}>

<input type=hidden name=terms value=$form->{terms}>

<input type=hidden name=discount value=$form->{discount}>
<input type=hidden name=creditlimit value=$form->{creditlimit}>
<input type=hidden name=creditremaining value=$form->{creditremaining}>

<input type=hidden name=tradediscount value=$form->{tradediscount}>
<input type=hidden name=business value="$form->{business}">

<input type=hidden name=closedto value=$form->{closedto}>
<input type=hidden name=locked value=$form->{locked}>

<input type=hidden name=shipped value=$form->{shipped}>

<input type=hidden name=oldtransdate value=$form->{oldtransdate}>
<input type=hidden name=oldid value=$form->{oldid}>
<input type=hidden name=oldcallback value=$form->{oldcallback}>

<input type=hidden name=cash_invoice value=$form->{cash_invoice}>
<input type=hidden name=promptshipreceive value=$form->{promptshipreceive}>
<input type=hidden name=whded value=$form->{whded}>
<input type=hidden name=inwh value=$form->{inwh}>
<input type=hidden name="prefix" value="$form->{prefix}">
<input type=hidden name="suffix" value="$form->{suffix}">
<input type=hidden name=oldshipvia value=$form->{oldshipvia}>
<input type=hidden name=taxincluded value=$form->{taxincluded}>
<input type=hidden name=szeta value="$form->{szeta}">
<input type=hidden name=duebase value="$form->{duebase}">
<input type=hidden name=footer value="$form->{footer}">
<input type=hidden name=rcost_accno value="$form->{rcost_accno}">
<input type=hidden name=rincome_accno value="$form->{rincome_accno}">
<input type=hidden name=cash_accno value="$form->{cash_accno}">
<input type=hidden name=tdij_van value="$form->{tdij_van}">
<input type=hidden name=city value="$form->{city}">
<input type=hidden name=address1 value="$form->{address1}">
<input type=hidden name=old_id value=$form->{old_id}>
|;
my $class1 = qq|class="noscreen"| if $maccess !~ /Accountant--All/;

print qq|
<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Customer').qq|</th>
		<td colspan=3>
		$customer&nbsp;<label class="info" title='$form->{city}, $form->{address1}'>?</label>
		</td>
		<input type=hidden name=customer_id value=$form->{customer_id}>
		<input type=hidden name=oldcustomer value="$form->{oldcustomer}"> 
	      </tr>
	      <tr>
		<td></td>
		<td colspan=3>
		  <table>
		    <tr>
		      <th nowrap>|.$locale->text('Credit Limit').qq|</th>
		      <td>$form->{creditlimit}</td>
		      <td width=20%></td>
		      <th nowrap>|.$locale->text('Remaining').qq|</th>
		      <td class="plus$n">$form->{creditremaining}</td>
		    </tr>
		  </table>
		</td>
	      </tr>
	      $business
	      <tr $class1>
		<th align=right nowrap>|.$locale->text('Record in').qq|</th>
		<td colspan=3><select $classchange name=AR>$form->{selectAR}</select></td>
		<input type=hidden name=selectAR value="$form->{selectAR}">
	      </tr>
	      $department
	      <tr>
		<th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td>$currency</td>
		<input type=hidden name=selectcurrency value="$form->{selectcurrency}">
		<input type=hidden name=defaultcurrency value=$form->{defaultcurrency}>
		<input type=hidden name=fxgain_accno value=$form->{fxgain_accno}>
		<input type=hidden name=fxloss_accno value=$form->{fxloss_accno}>
		$exchangerate
	      </tr>

        |;
#kabai
	print qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Shipping Point').qq|</th>
		<td colspan=3><input name=shippingpoint $readonly size=35 value="$form->{shippingpoint}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Ship via').qq|</th>
		<td colspan=3><input name=shipvia $readonly size=35 $classchange value="$form->{shipvia}"></td>
	      </tr>
        |;
    
#kabai +1
    print qq|
    
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      <tr>
	        <th align=right nowrap>|.$locale->text('Salesperson').qq|</th>
		<td><select name=employee>$form->{selectemployee}</select></td>
		<input type=hidden name=selectemployee value="|.
		$form->escape($form->{selectemployee},1).qq|">
	      </tr>

              <tr>
		<th align=right nowrap>|.$locale->text('Invoice Number').qq|</th>
		<td><input name=invnumber type=hidden size=11 value="$form->{invnumber}">$form->{invnumber}</td>
	      </tr>
|;
#kabai
        print qq|
	      <tr>
		<th align=right>|.$locale->text('Creation Date').qq|</th>
		<td><input name=crdate readonly size=11 title="$myconfig{'dateformat'}" id=crdate OnBlur="return dattrans('crdate');"  $classchange value=$form->{crdate}></td>
	      </tr> 
	      <tr>
		<th align=right>|.$locale->text('Invoice Date').qq|</th>
		<td><input name=transdate $readonly size=11 $classchange title="$myconfig{dateformat}" id=transdate OnBlur="return dattrans('transdate');" value=$form->{transdate}></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Due Date').qq|</th>
		<td><input name=duedate $readonly size=11 $classchange title="$myconfig{dateformat}" id=duedate OnBlur="return dattrans('duedate');" value=$form->{duedate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text($ordnumbertext).qq|</th>
		<td>$ordnumber</td>
		<input type="hidden" name="selectordnumber" value="|.$form->escape($form->{selectordnumber},1).qq|">
                <input type=hidden name=quonumber value="$form->{quonumber}">
	      </tr>

        |;
    
#kabai
    print qq|
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
    </td>
  </tr>
<!-- shipto are in hidden variables -->

<input type=hidden name=shiptoname value="$form->{shiptoname}">
<input type=hidden name=shiptoaddress1 value="$form->{shiptoaddress1}">
<input type=hidden name=shiptoaddress2 value="$form->{shiptoaddress2}">
<input type=hidden name=shiptocity value="$form->{shiptocity}">
<input type=hidden name=shiptostate value="$form->{shiptostate}">
<input type=hidden name=shiptozipcode value="$form->{shiptozipcode}">
<input type=hidden name=shiptocountry value="$form->{shiptocountry}">
<input type=hidden name=shiptocontact value="$form->{shiptocontact}">
<input type=hidden name=shiptophone value="$form->{shiptophone}">
<input type=hidden name=shiptofax value="$form->{shiptofax}">
<input type=hidden name=shiptoemail value="$form->{shiptoemail}">

<!-- email variables -->
<input type=hidden name=message value="$form->{message}">
<input type=hidden name=email value="$form->{email}">
<input type=hidden name=subject value="$form->{subject}">
<input type=hidden name=cc value="$form->{cc}">
<input type=hidden name=bcc value="$form->{bcc}">

<input type=hidden name=taxaccounts value="$form->{taxaccounts}">
|;
#kabai +7
  foreach $item (split / /, $form->{taxaccounts}) {
    print qq|
<input type=hidden name="${item}_rate" value="$form->{"${item}_rate"}">
<input type=hidden name="${item}_description" value="$form->{"${item}_description"}">
<input type=hidden name="${item}_taxnumber" value="$form->{"${item}_taxnumber"}">
<input type=hidden name="${item}_validfrom" value="$form->{"${item}_validfrom"}">
<input type=hidden name="${item}_validto" value="$form->{"${item}_validto"}">
<input type=hidden name=taxreturn value="$form->{taxreturn}">
|;
  }
}



sub form_footer {
#kabai totals should be rounded to int always
  $form->{invsubtotal} = $form->round_amount($form->{invsubtotal}, 0) if $form->{currency} eq "HUF";
#kabai
  $form->{invtotal} = $form->{invsubtotal};

  if (($rows = $form->numtextrows($form->{notes}, 26, 8)) < 2) {
    $rows = 2;
  }
  if (($introws = $form->numtextrows($form->{intnotes}, 35, 8)) < 2) {
    $introws = 2;
  }
  $rows = ($rows > $introws) ? $rows : $introws;
#kabai
      $notes = qq|<textarea name=notes $readonly rows=$rows cols=26 wrap=soft>$form->{notes}</textarea>|;
     $intnotes = qq|<textarea name=intnotes rows=$rows cols=35 wrap=soft>$form->{intnotes}</textarea>|;
#kabai


#kabai get booked values instead of calculated
 if ($form->{id} && !$ischange_true){
  CORE2->get_booked(\%myconfig,\%$form);
  my ($roundvalue,$exchrate);
  if ($form->{currency} eq "HUF"){
   $roundvalue = 0;
   $exchrate = 1;
  }else{
   $roundvalue = 2;
   $exchrate = $form->parse_amount(\%myconfig,$form->{exchangerate});
  }  
    
   $form->{invsubtotal} = $form->format_amount(\%myconfig, $form->round_amount($form->{booked_income}/$exchrate, $roundvalue), 2, 0);
  $subtotal = qq|
	      <tr>
		<th align=right>|.$locale->text('Subtotal').qq|</th>
		<td align=right>$form->{invsubtotal}</td>
	      </tr>
  | if !$form->{taxincluded};
  $form->{invtotal} = $form->{booked_income};
  foreach my $ref (@{ $form->{booked_tax} }) {
   $form->{invtotal} += $ref->{amount};
   $ref->{amount} = $form->format_amount(\%myconfig, $form->round_amount($ref->{amount}/$exchrate, $roundvalue), 2, 0);

   $tax .= qq|
	      <tr>
		<th align=right>$ref->{description}</th>
		<td align=right>$ref->{amount}</td>
	      </tr>
   | if !$form->{taxincluded};
  }
  $form->{invtotal} = $form->round_amount($form->{invtotal}/$exchrate, $roundvalue);

 }else{
   if (!$form->{taxincluded}) {
    
    foreach $item (split / /, $form->{taxaccounts}) {
#kabai    
    if ($form->datetonum($form->{"${item}_validfrom"},\%myconfig) > $form->datetonum($form->{transdate}, \%myconfig)
        || $form->datetonum($form->{"${item}_validto"},\%myconfig) < $form->datetonum($form->{transdate}, \%myconfig))
    {
        next;
    }    
#kabai 
      if ($form->{"${item}_base"}) {
#kabai 
	my $roundvalue = $form->{currency} eq "HUF" ? 0 : 2;
	$form->{"${item}_total"} = $form->round_amount($form->{"${item}_base"} * $form->{"${item}_rate"}, $roundvalue);
#kabai
	$form->{invtotal} += $form->{"${item}_total"};
	$form->{"${item}_total"} = $form->format_amount(\%myconfig, $form->{"${item}_total"}, 2);
	
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

  }
 } # kabai if $form->{id}
  $form->{oldinvtotal} = $form->{invtotal};
  $form->{invtotal} = $form->format_amount(\%myconfig, $form->{invtotal}, 2, 0);

  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr valign=bottom>
	  <td>
	    <table>
	      <tr>
		<th align=left>|.$locale->text('Notes').qq|</th>
		<th align=left>|.$locale->text('Internal Notes').qq|</th>
	      </tr>
	      <tr valign=top>
		<td>$notes</td>
		<td>$intnotes</td>
	      </tr>
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $subtotal
	      $tax
	      <tr>
		<th align=right>|.$locale->text('Total').qq|</th>
		<td align=right>$form->{invtotal}</td>
	      </tr>
	      $taxincluded
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
|; #kabai +1-2

  #  if ($form->{id}) {
    print qq|
      <table width=100%>
	<tr class=listheading>
	  <th colspan=6 class=listheading>|.$locale->text('Payments')
	  .qq|</th>
	</tr>
|;

  if ($form->{currency} eq $form->{defaultcurrency}) {
    @column_index = qw(datepaid source memo paid AR_paid);
  } else {
    @column_index = qw(datepaid source memo paid exchangerate AR_paid);
  }

  $column_data{datepaid} = "<th>".$locale->text('Date')."</th>";
  $column_data{paid} = "<th>".$locale->text('Amount')."</th>";
  $column_data{exchangerate} = "<th>".$locale->text('Exch')."</th>";
  $column_data{AR_paid} = "<th>".$locale->text('Account')."</th>";
  $column_data{source} = "<th>".$locale->text('Source')."</th>";
  $column_data{memo} = "<th>".$locale->text('Memo')."</th>";
  
  print "
	<tr>
";
  map { print "$column_data{$_}\n" } @column_index;
  print "
        </tr>
";
  
  $form->{paidaccounts}++ if ($form->{"paid_$form->{paidaccounts}"});


  if (!$form->{id}){
   if ($form->{currency} eq "HUF" && $form->{shipvia} =~ /(készpénz|KÉSZPÉNZ|kp)/i){
      my $invtotal = $form->parse_amount(\%myconfig,$form->{invtotal});
      my $mod_invtotal = $invtotal % 5;
	if ($mod_invtotal < 3) {
	  $form->{paid_1} = $invtotal-$mod_invtotal;
          $form->{paid_2} = ($mod_invtotal == 0) ? "0" : $mod_invtotal;
	  $form->{AR_paid_2} = $form->{rincome_accno};
	  $form->{memo_2} = $locale->text('Rounding income');
        }else{
	  $form->{paid_1} = $invtotal-$mod_invtotal + 5;
          $form->{paid_2} = ($mod_invtotal == 0) ? "0" : $mod_invtotal-5;
	  $form->{AR_paid_2} = $form->{rcost_accno};
	  $form->{memo_2} = $locale->text('Rounding cost');
        }	  
        $form->{datepaid_1} = $form->{datepaid_2} = $form->{transdate};
	$form->{source_1} = $form->{source_2} = $form->{invnumber} ;
        $form->{paidaccounts}++ if ($form->{paidaccounts} == 1);
      $form->{AR_paid_1} = $form->{cash_accno} if $form->{cash_accno};
   }else{
      $form->{datepaid_1} = $form->{datepaid_2} = $form->{paid_1} = $form->{paid_2} = $form->{memo_2} = "";
   }  
  }

for $i (1 .. $form->{paidaccounts}) {

    print "
        <tr>\n";
    my $readonly;
    $form->{"selectAR_paid_$i"} = $form->{selectAR_paid};
    $form->{"selectAR_paid_$i"} =~ s/option>\Q$form->{"AR_paid_$i"}\E/option selected>$form->{"AR_paid_$i"}/;
#kabai
    if ($form->{"source_$i"}){
      if ($strictcash_true){
        $readonly = "readonly";
       if ($form->{id}){
        $form->{"selectregsource_$i"} = "";
       }
      }else{
       $form->{"selectregsource_$i"} =  qq|<option value=0>| . $locale->text("odd number") . qq|</option>|;
      }
    }else{
     $form->{"selectregsource_$i"} = $form->{selectregsource};
    }
      my ($ARpaidnumber) = split /--/, $form->{"AR_paid_$i"};      
      my $regsourcevalue = "regacc_".$ARpaidnumber;
      $form->{"regsource_$i"} = $form->{$regsourcevalue}; 
#kabai not default anymore $form->{"selectregsource_$i"} =~ s/(<option value=\Q$form->{"regsource_$i"}\E)/$1 selected/ if $form->{"regsource_$i"};    
#kabai    
    # format amounts
    $totalpaid += $form->{"paid_$i"};
    $form->{"paid_$i"} = $form->format_amount(\%myconfig, $form->{"paid_$i"}, 2);
    $form->{"exchangerate_$i"} = $form->format_amount(\%myconfig, $form->{"exchangerate_$i"});

    $exchangerate = qq|&nbsp;|;
    if ($form->{currency} ne $form->{defaultcurrency}) {
      if ($form->{"forex_$i"}) {
	$exchangerate = qq|<input type=hidden name="exchangerate_$i" value=$form->{"exchangerate_$i"}>$form->{"exchangerate_$i"}|;
      } else {
	$exchangerate = qq|<input name="exchangerate_$i" size=10 value=$form->{"exchangerate_$i"}>|;
      }
    }

    $exchangerate .= qq|
<input type=hidden name="forex_$i" value=$form->{"forex_$i"}>
|;

    $column_data{"paid_$i"} = qq|<td align=center><input name="paid_$i" size=11 value=$form->{"paid_$i"}></td>|;
    $column_data{"exchangerate_$i"} = qq|<td align=center>$exchangerate</td>|;
    $column_data{"AR_paid_$i"} = qq|<td align=center><select name="AR_paid_$i">$form->{"selectAR_paid_$i"}</select></td>|;
    $column_data{"datepaid_$i"} = qq|<td align=center><input name="datepaid_$i" size=11 title="$myconfig{dateformat}" 
     id=datepaid_$i OnBlur="return dattrans('datepaid_$i');" value=$form->{"datepaid_$i"}></td>|;
#kabai
    $column_data{"source_$i"} = qq|<td align=center>
				   <input name=rsprint type=radio class=radio value=$i>
				   <select name="regsource_$i">
				   $form->{"selectregsource_$i"}</select>
				   <input name="source_$i" $readonly size=11 value="$form->{"source_$i"}">
				   </td>|;
    $column_data{"memo_$i"} = qq|<td align=center><input name="memo_$i" size=11 value="$form->{"memo_$i"}"></td>|;

    map { print qq|$column_data{"${_}_$i"}\n| } @column_index;
    print "
        </tr>\n";
}
#kabai
  foreach $item (split / /, $form->{regaccounts}) {
    $hiddenregacc.= qq|<input type=hidden name="regacc_$item" value=$form->{"regacc_$item"}>\n|;
  }
#kabai  
  print qq|
<input type=hidden name=paidaccounts value=$form->{paidaccounts}>
<input type=hidden name=selectAR_paid value="$form->{selectAR_paid}">
<input type=hidden name=selectregsource value="$form->{selectregsource}">
<input type=hidden name=regaccounts value="$form->{regaccounts}">
$hiddenregacc
<input type=hidden name=oldinvsubtotal value=|.$form->parse_amount(\%myconfig,$form->{invsubtotal}).qq|>
<input type=hidden name=oldinvtotal value=$form->{oldinvtotal}>
<input type=hidden name=oldtotalpaid value=$totalpaid>
<input type=hidden name=trans_id value=$form->{trans_id}>
      </table>
|; #kabai
   # } # if it is not a new one
    print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
  <tr>
    <td>
|;

  &print_options;

  print qq|
    </td>
  </tr>
</table>
|;
#kabai    
    my $shipval;
    for my $invacc (1 .. $form->{rowcount}) { #only services?
      $invacc_yes = 1 if ($form->{"inventory_accno_$invacc"} || $form->{"assembly_$invacc"});
    }
    $invacc_yes = 0 if $form->{inwh};  
    OE->get_warehouses(\%myconfig, \%$form);

    # warehouse
    if (@{ $form->{all_warehouses} }) {
     $form->{selectwarehouse} = "<option>\n";


  $form->{warehouse} = qq|$form->{warehouse}--$form->{warehouse_id}|;

      if ($form->{whded}) {
       map { $form->{selectwarehouse} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| if $_->{id} == $form->{whded}} (@{ $form->{all_warehouses} });
      }else{
       map { $form->{selectwarehouse} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| } (@{ $form->{all_warehouses} });
      }
      

    }else{
     #$form->{selectwarehouse} = "<option>\n";
     $form->{selectwarehouse} .= qq|<option value="0--0">- - - - - - - -\n|;
    
    }  
   $warehouse = qq|
	      <tr>
		<th align=right>|.$locale->text('Warehouse').qq|</th>
		<td><select name=warehouse>$form->{selectwarehouse}</select></td>
		<input type=hidden name=selectwarehouse value="|.
		$form->escape($form->{selectwarehouse},1).qq|">
	      </tr> |;
 
#kabai

  $transdate = $form->datetonum($form->{transdate}, \%myconfig);
  $closedto = $form->datetonum($form->{closedto}, \%myconfig);

  if (! $form->{readonly}) {
    
    if ($form->{id}) {
#kabai 
      print qq|
      <input class=submit type=submit name=action onclick="return checkform();" value="|.$locale->text('Print').qq|">
      <input class=submit type=submit name=action value="|.$locale->text('Add new').qq|"> 
      &nbsp;&nbsp;|.$locale->text('Reversing').qq|&nbsp;<input type=checkbox name=reversing onclick=
      "if (document.forms[0].reversing.checked){document.forms[0].correcting.checked=false}" value=1>      
      &nbsp;&nbsp;|.$locale->text('Correcting').qq|&nbsp;<input type=checkbox name=correcting onclick=
      "if (document.forms[0].correcting.checked){document.forms[0].reversing.checked=false}" value=1>
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type=checkbox name=szeta1 value=1>|.$locale->text('Use invoice-like document');
      print qq|
      <br><br><input class=submit type=submit name=action value="|.$locale->text('E-mail').qq|">
      <input class=submit type=submit name=action value="|.$locale->text('Ship to').qq|">
      |;
      print qq|
	<input class=submit type=submit name=action value="|.$locale->text('Delete').qq|">          
      | if $isdelete_true;
      print qq|
	<input class=submit type=submit name=action value="|.$locale->text('Repost').qq|">          
      | if $isrepost_true;
      print qq|
	<input class=submit type=submit name=action value="|.$locale->text('Post as new').qq|">          
        &nbsp;|.$locale->text('New number:').qq|&nbsp;<input name="invnumber" size="10"><br />
      | if $ispostasnew_true;


#
#	<input class=submit type=submit name=action value="|.$locale->text('Delete').qq|">
#	<input class=submit type=submit name=action value="|.$locale->text('Post').qq|">
        if (! $form->{locked}) {
	  print qq|
        <input class=submit type=submit name=action value="|.$locale->text('Update').qq|">
	<input class=submit type=submit name=action value="|.$locale->text('Change').qq|">

| if $ischange_true;
	}

	print qq|
      <input class=submit type=submit name=action value="|.$locale->text('Sales Order').qq|">
| if $myconfig{acs} !~ /Order Entry--Sales Order/;

    } else {

      if ($transdate > $closedto) {
	print qq|
        <input class=submit type=submit name=action value="|.$locale->text('Update').qq|">
        <input class=submit type=submit name=action value="|.$locale->text('Print Preview').qq|">
       |;
       if (!$form->{promptshipreceive} || !$invacc_yes){
	 print qq|<input class=submit type=submit name=action onclick="return checkform2();" value="|.$locale->text('Continue2').qq|">|;
        }else{
          print qq|
          &nbsp;&nbsp;&nbsp;&nbsp;$warehouse &nbsp;&nbsp;<input class=submit type=submit name=action onclick="return checkform();" value="|.$locale->text('Post And Ship').qq|">        
          |;
        }						    
					    
	print qq|
	<br><br>
        <input class=submit type=submit name=action value="|.$locale->text('New customer').qq|">
|;
      }else{
	print qq|
        <input class=submit type=submit name=action value="|.$locale->text('Update').qq|">
       |;
      }  
    }
  }
#kabai        <input class=submit type=submit name=action value="|.$locale->text('Ship to').qq|">
#KS        
	print qq| &nbsp;&nbsp;&nbsp;&nbsp;<b> |.$locale->text('Navigation').qq|</b>
	 <select name=navigate><option value=1>|.$locale->text('Customer Basic Data').qq|
	<option value=2>|.$locale->text('Opened Sales Orders').qq|
	 <option value=3>|.$locale->text('Opened AR Transactions');
#	if(!$form->{id} and $form->{oldid}){print qq|<option value=4 selected>|.$locale->text('Previous Transaction');}
	if($form->{id}){print qq|<option value=5>|.$locale->text('Accountant Journals');}
	print qq|</select>&nbsp;<input class=submit type=submit name=action value="|.$locale->text('Jump').qq|">|;
  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }
#KS -- oldcallback
  print qq|

<input type=hidden name=rowcount value=$form->{rowcount}>

<input name=callback type=hidden value=|.(($form->{oldcallback}) ? "$form->{oldcallback}" : "$form->{callback}").qq|>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input type=hidden name=oeid value=$form->{oeid}>|;

if (!$_[0]){
 print qq|
	</form>
 |; print qq|<div id="helptext"> $helptext[$form->{hpack}][$form->{hpage}] </div>| if $form->{hpack} ne ""; print qq|
	</body>
	</html>
  |;
 }
}


sub update {

  $oldexchangerate = $form->{exchangerate};
  map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(exchangerate creditlimit creditremaining);
  $form->error($locale->text('Bad exchangerate format').": ".$oldexchangerate) if ($form->{exchangerate} > 1000 && $form->{currency} =~ /(USD|EUR)/);
  &check_name(customer);
  if ($form->{duebase} ne "none"){
   if ($form->{duebase} eq "transdate"){
    if ($form->{transdate} ne $form->{oldtransdate}) {
      $form->{duedate} = $form->current_date(\%myconfig, $form->{transdate}, $form->{terms} * 1);
      $form->{oldtransdate} = $form->{transdate};
    }
   }else{
       $form->{duedate} = $form->current_date(\%myconfig, $form->{crdate}, $form->{terms} * 1);
   } 
  }

  $form->{exchangerate} = $exchangerate if ($form->{forex} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}, 'buy')));

  for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"}) {
      map { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) } qw(paid exchangerate);

      $form->{"exchangerate_$i"} = $exchangerate if ($form->{"forex_$i"} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{"datepaid_$i"}, 'buy_paid')));
    }
  }

  $i = $form->{rowcount};
  $exchangerate = ($form->{exchangerate}) ? $form->{exchangerate} : 1;

  foreach $item (qw(partsgroup projectnumber)) {
    $form->{"select$item"} = $form->unescape($form->{"select$item"}) if $form->{"select$item"};
  }
    
  # if last row empty, check the form otherwise retrieve new item
  if (($form->{"partnumber_$i"} eq "") && ($form->{"description_$i"} eq "") && ($form->{"partsgroup_$i"} eq "")) {
    &check_form;
  } else {

    IS->retrieve_item(\%myconfig, \%$form);
  
    $rows = scalar @{ $form->{item_list} };

    $form->{"discount_$i"}	= $form->format_amount(\%myconfig, $form->{discount} * 100);

    if ($rows > 0) {
      $form->{"qty_$i"}		= ($form->{"qty_$i"} * 1) ? $form->{"qty_$i"} : 1;
      
      if ($rows > 1) {
	
	&select_item;
	exit;
	
      } else {

        $sellprice = $form->parse_amount(\%myconfig, $form->{"sellprice_$i"});
	
	map { $form->{item_list}[$i]{$_} = $form->quote($form->{item_list}[$i]{$_}) } qw(partnumber description unit);
	map { $form->{"${_}_$i"} = $form->{item_list}[0]{$_} } keys %{ $form->{item_list}[0] };

        $form->{"projectnumber_$i"} = $form->{"projectnumber_$i"}."--".$form->{"project_id_$i"};
	$s = ($sellprice) ? $sellprice : $form->{"sellprice_$i"};
	($dec) = ($s =~ /\.(\d+)/);
	$dec = length $dec;
	$decimalplaces = ($dec > 2) ? $dec : 2;

	if ($sellprice) {
	  $form->{"sellprice_$i"} = $sellprice;
	} else {
	  # if there is an exchange rate adjust sellprice
	  $form->{"sellprice_$i"} *= (1 - $form->{tradediscount});
	  #$form->{"sellprice_$i"} /= $exchangerate;
	}
	
	#$form->{"listprice_$i"} /= $exchangerate;

        $amount = $form->{"sellprice_$i"} * $form->{"qty_$i"} * (1 - $form->{"discount_$i"} / 100);
	map { $form->{"${_}_base"} = 0 } (split / /, $form->{taxaccounts});
        
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
	

	map { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $decimalplaces) } qw(sellprice listprice avprice);
	
	$form->{"qty_$i"} =  $form->format_amount(\%myconfig, $form->{"qty_$i"});

      }

      &display_form ($_[0]);

    } else {
      # ok, so this is a new part
      # ask if it is a part or service item

      if ($form->{"partsgroup_$i"} && ($form->{"partsnumber_$i"} eq "") && ($form->{"description_$i"} eq "")) {
	$form->{rowcount}--;
	$form->{"discount_$i"} = "";
	&display_form ($_[0]);
      } else {
	
	$form->{"id_$i"}          = 0;
	$form->{"unit_$i"}        = $locale->text('ea');

	&new_item;
	
      }
    }
  }
}



sub continue2 {
&update(1);
my ($customer, $null) = split /--/, $form->{customer};
my $invsubtotal = $form->{taxincluded} ? "" : $form->{invsubtotal};
print qq|
<br>
<br>
<table width=100>
  <tr>
  <th class=listheading nowrap>|.$locale->text('All right?').qq|</th>
  </tr>
  <tr>
   <th align=left>|.$locale->text('Customer').qq|</th>
   <th align=left>|.$customer.qq|</th>
  </tr>
  <tr>
   <th align=left>|.$locale->text('Currency').qq|</th>
   <th align=left>|.$form->{currency}.qq|</th>
  </tr>
  <tr>
   <th align=left>|.$locale->text('Ship via').qq|</th>
   <th align=left>|.$form->{shipvia}.qq|</th>
  </tr>
  <tr>
   <th align=left>|.$locale->text('Creation Date').qq|</th>
   <th align=left>|.$form->{crdate}.qq|</th>
  </tr>
  <tr>
   <th align=left>|.$locale->text('Invoice Date').qq|</th>
   <th align=left>|.$form->{transdate}.qq|</th>
  </tr>
  <tr>
   <th align=left>|.$locale->text('Due Date').qq|</th>
   <th align=left>|.$form->{duedate}.qq|</th>
  </tr>
  <tr>
   <th align=left>|.$locale->text('Netto').qq|</th>
   <th align=left>|.$invsubtotal.qq|</th>
  </tr>
  <tr>
   <th align=left>|.$locale->text('Brutto').qq|</th>
   <th align=left>|.$form->{invtotal}.qq|</th>
  </tr>
</table>
<br>
|;										
print qq|
<input type=hidden name=taxreturn value=$form->{taxreturn}>
|;
#<input name=callback type=hidden value="$form->{callback}">

#<input type=hidden name=path value=$form->{path}>
#<input type=hidden name=login value=$form->{login}>
#<input type=hidden name=sessionid value=$form->{sessionid}>
#|;
 print qq|<input class=submit type=submit name=action onclick="return checkform2();" value="|.$locale->text('Post').qq|">|;
 print qq|
	</form>
	</body>
	</html>
  |;
}

sub post{
$form->close_oe(\%myconfig) if $form->{oeid}; 
if ($form->{transdate} le $form->{taxreturn})
   {$form->error($locale->text('Cannot post invoice for a tax returned period!'));}
  $form->isblank("transdate", $locale->text('Invoice Date missing!'));
#kabai
  $form->isblank("crdate", $locale->text('Creation Date missing!'));

  if ($strictcash_true){
   for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"regsource_$i"} ne "" && $form->{"paid_$i"}){
    ($regsourcevalue, $null) = split /--/, $form->{"AR_paid_$i"};
      if ($form->{"regacc_$regsourcevalue"} ne $form->{"regsource_$i"} || $form->{"source_$i"}){
	$form->error($locale->text('This source number does not belong to the selected cash account!'));
      }	
    }  
   }
  }  
#kabai
  $form->isblank("customer", $locale->text('Customer missing!'));
  
#kabai
  # if oldcustomer ne customer redo form
  if (&check_name(customer)) {
    &update;
    exit;
  }
 
  &validate_items;

  $closedto = $form->datetonum($form->{closedto}, \%myconfig);
  $transdate = $form->datetonum($form->{transdate}, \%myconfig);
  
  $form->error($locale->text('Cannot post invoice for a closed period!')) if ($transdate <= $closedto);

  $form->isblank("exchangerate", $locale->text('Exchangerate missing!')) if ($form->{currency} ne $form->{defaultcurrency});
  
  for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"}) {
      $datepaid = $form->datetonum($form->{"datepaid_$i"}, \%myconfig);

      $form->isblank("datepaid_$i", $locale->text('Payment date missing!'));
      
      $form->error($locale->text('Cannot post payment for a closed period!')) if ($datepaid <= $closedto);

      if ($form->{currency} ne $form->{defaultcurrency}) {
	$form->{"exchangerate_$i"} = $form->{exchangerate} if ($transdate == $datepaid);
	$form->isblank("exchangerate_$i", $locale->text('Exchangerate for payment missing!'));
      }
    }
  }

  
  ($form->{AR}) = split /--/, $form->{AR};
  ($form->{AR_paid}) = split /--/, $form->{AR_paid};
  
  $form->{label} = $locale->text('Invoice');

  $form->{id} = 0 if $form->{postasnew};
  $form->{szeta} = 0 if $form->{repost};
#kabai

  my $invnumber;
  $invnumber = $form->{szeta} ? "invnumber_st" : "invnumber";
  $form->{$invnumber} = $form->update_defaults(\%myconfig, $invnumber, "do_not_update") unless $form->{$invnumber};

  $form->{promptcogs_true} = $promptcogs_true;
  $form->{cogsinorder_true} = $cogsinorder_true;
  # add up debits and credits
  if (!$form->{adjustment}) {
    my $felso, $felsoh;
    for $i (1 .. $form->{rowcount}) {
      my ($ii, $null)=split /--/, $form->{"AR_paid_$i"};
      $form->{cashaccount}=$ii;
      undef $form->{chart_id};
      AM->get_cashlimit(\%myconfig, \%$form);
      if ($form->{chart_id} and $form->{"paid_$i"}){
        AM->get_sumcash(\%myconfig, \%$form, $form->{"datepaid_$i"});
        my $ossz=$form->{sumamount}+$form->parse_amount(\%myconfig, $form->{"paid_$i"});
        if ($ossz < $form->{mincash}){
          $form->error(qq|$ii |.$locale->text ('Under the Limit!')
           .qq| ($form->{"datepaid_$i"}, |.$form->format_amount(\%myconfig, $ossz,2 ,0).qq| < |.$form->format_amount(\%myconfig, $form->{mincash},2 ,0).qq|)|);
        }
        if ($ossz > $form->{maxcash}){
          $felso =~s/$ii //;
          $felso.=qq|$ii |;
          $fh=$ii.': '.$form->format_amount(\%myconfig, $form->{maxcash},2 ,0).' ';
          $felsoh =~s/$fh//;
          $felsoh.=qq|$fh |}
        }
      }
      if (($form->round_amount($debit, 2) != $form->round_amount($credit, 2)) || $felso) {
        &post_adjustment ($felso, $felsoh);
        exit;
     }
}

 if (IS->post_invoice(\%myconfig, \%$form)){
   $form->{callback} = "is.pl?action=edit&id=$form->{id}&path=bin/mozilla&login=$form->{login}&sessionid=$form->{sessionid}";
#KS
     $form->{callback}.="&oldid=$form->{id}" if ($form->{callback});
     $form->redirect if (!$form->{remotecall} && !$redirectsign);
 }else{
  $form->error($locale->text('Cannot post invoice!'));
 }   
}

sub post_adjustment {
  $form->header;
  
  print qq|
    <body>
	
    <form method=post action=$form->{script}>
	    
    <input type=hidden name=adjustment value=1>
  |;
		        #$form->error($_[0]);
    $form->hide_form();
    my $szov= $_[0].' '.$locale->text('Over the Limit!').' ('.$_[1].')<br>' if ($_[0]);
    $szov.= $locale->text('Out of balance transaction!')
    if ($form->round_amount($debit, 2) != $form->round_amount($credit, 2));
      print qq|
       <h2 class=confirm>|.$locale->text('Warning!').qq|</h2>
					   
       <h4>$szov</h4>
					  
       <input name=action class=submit type=submit value="|.$locale->text('Post').qq|">
      </form>
     |;
}
									   


sub delete {
  if ($form->{transdate} lt $form->{taxreturn})
   {$form->error($locale->text('Cannot delete invoice for a tax returned period!'));}

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  # delete action variable
  map { delete $form->{$_} } qw(action header);

  $form->hide_form();

  print qq|
<h2 class=confirm>|.$locale->text('Confirm!').qq|</h2>

<h4>|.$locale->text('Are you sure you want to delete Invoice Number').qq| $form->{invnumber}
</h4>

<p>
<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>
|;


}



sub yes {
    $form->{promptcogs_true} = $promptcogs_true;
    $form->{cogsinorder_true} = $cogsinorder_true;
	
    if (IS->delete_invoice(\%myconfig, \%$form)){
      $form->redirect($locale->text('Invoice deleted!'));
    }
    $form->error($locale->text('Cannot delete invoice!'));
}


sub redirect {

  $form->redirect;
  $form->error($locale->text('Invoice processed!'));

}

	    
sub new_customer { #kabai
    $form->{callback} = $form->escape($form->{callback},1);
    $form->{callback} = "ct.pl?path=bin/mozilla&action=add&login=$form->{login}&sessionid=$form->{sessionid}&cash_invoice=$form->{cash_invoice}&callback=$form->{callback}&db=customer";
    $form->redirect;
}
		    

#kabai 

sub change {
      CORE2->ischange(\%myconfig, \%$form);
#      $form->{callback} = $form->escape($form->{callback},1);
      $form->redirect;
}

sub add_withship { #kabai 

  $form->{title} = $locale->text('Add Sales Invoice');

  $form->{shipbutton} = 1;
  $form->{callback} = "$form->{script}?action=add&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}" unless $form->{callback};
  
  &invoice_links;
  &prepare_invoice;
  &display_form;
  
}

sub allocdate {

$form->header;
my $nextsub = $form->{calc_cogs} ? "calc_cogs" : "show_alloc";
print qq|
<body>
|;
 if ($myconfig{js}) {
print qq|
<script src="js/prototype.js" type="text/javascript"></script>
<script src="js/validation.js" type="text/javascript"></script>
<script src="js/custom.js" type="text/javascript"></script>
|;
}else {
print qq|
<script> function checkform () { return true; }</script>
|;
}
print qq|
<form method=post action=$form->{script}>
<table width="100%">
  <tr><th class=listtop>|.$locale->text('Limit date for allocation').qq|</th></tr>
</table>
<table width="35%">
  <tr><td align=left>|.$locale->text('Calculate COGS up to').qq|</td>
  <td align=left><input type=text class="required" size=11 name=allocdate title="$myconfig{'dateformat'}" id=allocdate OnBlur="return dattrans('allocdate');" value=|.$form->current_date(\%myconfig).qq|> </td>
  </tr> |;
  print qq|
  <tr><td colspan=2> |.$locale->text('Delete everything calculated so far, and start from the very first invoice').qq|<input type=checkbox name=cogsfromthestart></td></tr> 
  <tr><td colspan=2><span class="plus0">|.$locale->text('Warning! This function should be used in a another (test) database only!').qq|</span></td></tr> 
  | if $form->{calc_cogs};
  print qq|
</table>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
<input type=hidden name=nextsub value=$nextsub>
<br>
<input class=submit type=submit name=action onclick="return checkform();" value="|.$locale->text('Continue').qq|">
</form>
</body></html>|;
}

sub show_alloc { #kabai

  $title = $form->escape($form->{title},1);
  
  $callback = "$form->{script}?action=show_alloc&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&title=$title";
    
  @columns = $form->sort_columns(qw(partnumber bought sold bs_diff ballocated sallocated  basa_diff));

  foreach $item (@columns) {
    push @column_index, $item;
    $callback .= "&l_$item=Y";
  }

  CORE2->get_allocated(\%myconfig, \%$form);

  $href = $callback;
  
   
  $column_header{partnumber} = qq|<th class=listheading nowrap>|.$locale->text('Partnumber').qq|</th>|;
  $column_header{bought} = qq|<th class=listheading nowrap>|.$locale->text('Bought').qq|</th>|;
  $column_header{sold} = qq|<th class=listheading nowrap>|.$locale->text('Sold').qq|</th>|;
  $column_header{bs_diff} = qq|<th class=listheading nowrap>|.$locale->text('Diff').qq|</th>|;
  $column_header{ballocated} = qq|<th class=listheading nowrap>|.$locale->text('Allocated Purchases').qq|</th>|;
  $column_header{sallocated} = qq|<th class=listheading nowrap>|.$locale->text('Allocated Sales').qq|</th>|;
  $column_header{basa_diff} = qq|<th class=listheading nowrap>|.$locale->text('Needed').qq|</th>|;

  $form->header;

  $i = 1;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>

  <tr><td>$option</td></tr>

  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  map { print "\n$column_header{$_}" } @column_index;
  
  print qq|
        </tr>
  |;


  
  # escape callback for href
  $callback = $form->escape($callback);


    foreach $ref (@{ $form->{get_allocated} }) {
  
    
    $column_data{partnumber} = "<td>$ref->{partnumber}&nbsp;</td>";
    $column_data{bought} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{bought}, '', "&nbsp;")."</td>";
    $column_data{sold} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{sold}, '', "&nbsp;")."</td>";
    $column_data{bs_diff} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{bs_diff}, '', "&nbsp;")."</td>";
    $column_data{ballocated} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{ballocated}, '', "&nbsp;")."</td>";
    $column_data{sallocated} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{sallocated}, '', "&nbsp;")."</td>";
    $column_data{basa_diff} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{basa_diff}, '', "&nbsp;")."</td>";
        $i++; $i %= 2;
    print "<tr class=listrow$i>";

    map { print "\n$column_data{$_}" } @column_index;

    print qq|
   
|;

  }
  
  print qq|
      </table>
    </td>
  </tr>
  <tr><td><hr size=3 noshade></td></tr>
</table>

|;
 
  print qq|

<br>

<form method=post action=$form->{script}>

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=item value=$form->{searchitems}>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
|;

  
  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
  </form>

</body>
</html>
|;
}
sub calc_cogs { #kabai
  $form->isblank("allocdate", $locale->text('Invoice Date missing!'));
  $form->header;
  print qq|<body>Kérem várjon...|;
  $form->{onlyminusalloc} = 1;
  $form->{remotecall} = 1;
  CORE2->get_allocated(\%myconfig, \%$form);
  $form->error("Egyes cikkeknél az eladások meghaladják a beszerzéseket") if $form->{get_allocated};
  if ($form->{cogsfromthestart}){
      CORE2->init_cogs(\%myconfig, \%$form);
      print qq|<br>ELÁBÉ tételek törlése|;
      $form->{initcogs} = 1;
      foreach $ref (@{ $form->{get_allinvoice} }) {
        $form->{id} = $ref->{trans_id};
        &invoice_links;
        $i = 0;
        &prepare_invoice;
        $form->{paid} = 0;
        #delete $form->{taxincluded};
        #display_form variables
        #$form->header
        $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

        $form->{creditlimit} = $form->format_amount(\%myconfig, $form->{creditlimit}, 0, "0");
        $form->{creditremaining} = $form->format_amount(\%myconfig, $form->{creditremaining}, 0, "0");
        #display_form
        ++$form->{rowcount};
        #display_row
        $form->{invsubtotal} = 0;
        map { $form->{"${_}_base"} = 0 } (split / /, $form->{taxaccounts});

        $exchangerate = $form->parse_amount(\%myconfig, $form->{exchangerate});
        $exchangerate = ($exchangerate) ? $exchangerate : 1;
        for $i (1 .. $form->{rowcount}) {
          # undo formatting
          map { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) } qw(qty discount sellprice);
    
          ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
          $dec = length $dec;
          $decimalplaces = ($dec > 2) ? $dec : 2;

    
    
          $discount = $form->round_amount($form->{"sellprice_$i"} * $form->{"discount_$i"}/100, $decimalplaces);
          $linetotal = $form->round_amount($form->{"sellprice_$i"} - $discount, $decimalplaces);
          $linetotal = $form->round_amount($linetotal * $form->{"qty_$i"}, 2);

          map { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) } qw(partnumber sku description unit);
          map { $form->{"${_}_base"} += $linetotal } (split / /, $form->{"taxaccounts_$i"});
          $form->{invsubtotal} += $linetotal;

          # do formatting
          map { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $decimalplaces) } qw(qty discount sellprice);

        }
        #$form->footer
        $form->{invtotal} = $form->{invsubtotal};
        $form->{taxincluded} = ($form->{taxincluded}) ? 1 : 0;
       if (!$form->{taxincluded}) {
    
          foreach $item (split / /, $form->{taxaccounts}) {
            if ($form->{"${item}_base"}) {
        	$form->{"${item}_total"} = $form->round_amount($form->{"${item}_base"} * $form->{"${item}_rate"}, 2);
        	$form->{invtotal} += $form->{"${item}_total"};
        	$form->{"${item}_total"} = $form->format_amount(\%myconfig, $form->{"${item}_total"}, 2);
	
            }
          }

        $form->{invsubtotal} = $form->format_amount(\%myconfig, $form->{invsubtotal}, 2, 0);
    
       }
 
       $form->{oldinvtotal} = $form->{invtotal};
       $form->{invtotal} = $form->format_amount(\%myconfig, $form->{invtotal}, 2, 0);
       $form->{paidaccounts}++ if ($form->{"paid_$form->{paidaccounts}"});
       for $i (1 .. $form->{paidaccounts}) {

        # format amounts
       $form->{oldtotalpaid} += $form->{"paid_$i"};
       $form->{"paid_$i"} = $form->format_amount(\%myconfig, $form->{"paid_$i"}, 2);
       $form->{"exchangerate_$i"} = $form->format_amount(\%myconfig, $form->{"exchangerate_$i"});

    
       }

       #display_form variables
       print qq|.|;
       &post;
       foreach my $key (keys %$form){
         if ($key !~ /login|sessionid|path|stylesheet|charset|remotecall|allocdate|initcogs/){
          delete $form->{"$key"};
         }
       }

     }
  print qq|vége|;
  $form->{initcogs} = 0;

######DELETE COGS FROM BOOKS
  }
  $form->{header} = 1;
  CORE2->get_nonallocated(\%myconfig, \%$form);
  foreach $ref (@{ $form->{get_nonallocated} }) {
    $form->{id} = $ref->{trans_id};
    &invoice_links;
    $i = 0;
    &prepare_invoice;
    $form->{paid} = 0;
    #delete $form->{taxincluded};
    #display_form variables
    #$form->header
  $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

  $form->{creditlimit} = $form->format_amount(\%myconfig, $form->{creditlimit}, 0, "0");
  $form->{creditremaining} = $form->format_amount(\%myconfig, $form->{creditremaining}, 0, "0");
    #display_form
  ++$form->{rowcount};
   #display_row
   $form->{invsubtotal} = 0;
  map { $form->{"${_}_base"} = 0 } (split / /, $form->{taxaccounts});

  $exchangerate = $form->parse_amount(\%myconfig, $form->{exchangerate});
  $exchangerate = ($exchangerate) ? $exchangerate : 1;
   for $i (1 .. $form->{rowcount}) {
    # undo formatting
    map { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) } qw(qty discount sellprice);
    
    ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
    $dec = length $dec;
    $decimalplaces = ($dec > 2) ? $dec : 2;

    
    
    $discount = $form->round_amount($form->{"sellprice_$i"} * $form->{"discount_$i"}/100, $decimalplaces);
    $linetotal = $form->round_amount($form->{"sellprice_$i"} - $discount, $decimalplaces);
    $linetotal = $form->round_amount($linetotal * $form->{"qty_$i"}, 2);

    map { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) } qw(partnumber sku description unit);
    map { $form->{"${_}_base"} += $linetotal } (split / /, $form->{"taxaccounts_$i"});
    $form->{invsubtotal} += $linetotal;

    # do formatting
    map { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $decimalplaces) } qw(qty discount sellprice);

   }
  #$form->footer
  $form->{invtotal} = $form->{invsubtotal};
  $form->{taxincluded} = ($form->{taxincluded}) ? 1 : 0;
   if (!$form->{taxincluded}) {
    
    foreach $item (split / /, $form->{taxaccounts}) {
      if ($form->{"${item}_base"}) {
	$form->{"${item}_total"} = $form->round_amount($form->{"${item}_base"} * $form->{"${item}_rate"}, 2);
	$form->{invtotal} += $form->{"${item}_total"};
	$form->{"${item}_total"} = $form->format_amount(\%myconfig, $form->{"${item}_total"}, 2);
	
      }
    }

    $form->{invsubtotal} = $form->format_amount(\%myconfig, $form->{invsubtotal}, 2, 0);
    
   }

  $form->{oldinvtotal} = $form->{invtotal};
  $form->{invtotal} = $form->format_amount(\%myconfig, $form->{invtotal}, 2, 0);
  $form->{paidaccounts}++ if ($form->{"paid_$form->{paidaccounts}"});
   for $i (1 .. $form->{paidaccounts}) {

     # format amounts
    $form->{oldtotalpaid} += $form->{"paid_$i"};
    $form->{"paid_$i"} = $form->format_amount(\%myconfig, $form->{"paid_$i"}, 2);
    $form->{"exchangerate_$i"} = $form->format_amount(\%myconfig, $form->{"exchangerate_$i"});

    
   }

#display_form variables
print qq|<br>$form->{invnumber} feldolgozása|;
&post;

    foreach my $key (keys %$form){
     if ($key !~ /login|sessionid|path|stylesheet|charset|remotecall/){
      delete $form->{"$key"};
     }
    }
  }
  print qq|<br>Feldolgozás vége</body></html>|;
}

sub cogs_results { #kabai

  # setup $form->{sort}
  unless ($form->{sort}) {
      $form->{sort} = "invdate";
  }

  $title = $form->escape($form->{title},1);
  
  $callback = "$form->{script}?action=cogs_results&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";


    if ($form->{invdatefrom}) {
      $callback .= "&invdatefrom=$form->{invdatefrom}";
      $option .= "\n<br>".$locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{invdatefrom}, 1);
    }
    if ($form->{invdateto}) {
      $callback .= "&invdateto=$form->{invdateto}";
      $option .= "\n<br>".$locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{invdateto}, 1);
    }
  
  
  $option .= "<br>";
  
  if ($form->{partnumber}) {
    $callback .= "&partnumber=$form->{partnumber}";
    $option .= $locale->text('Number').qq| : $form->{partnumber}<br>|;
  }
  if ($form->{invnumber}) {
    $callback .= "&invnumber=$form->{invnumber}";
    $option .= $locale->text('Invoice Number').qq| : $form->{invnumber}<br>|;
  }
  
  @columns = $form->sort_columns(qw(invdate partnumber invnumber allocated sellprice costprice margin));

      foreach $item (@columns) {
        push @column_index, $item;
      }

  if ($form->{l_subtotal} eq 'Y') {
    $callback .= "&l_subtotal=Y";
  }


  CORE2->cogs_history(\%myconfig, \%$form);

  $callback .= "&direction=$form->{direction}&oldsort=$form->{oldsort}";
  
  $href = $callback;
  $form->sort_order();
  
  $callback =~ s/(direction=).*\&{1}/$1$form->{direction}\&/;

  $column_header{invdate} = qq|<th nowrap><a class=listheading href=$href&sort=invdate>|.$locale->text('Invoice Date').qq|</a></th>|;  
  $column_header{partnumber} = qq|<th nowrap colspan=$colspan><a class=listheading href=$href&sort=partnumber>|.$locale->text('Number').qq|</a></th>|;
  $column_header{invnumber} = qq|<th nowrap colspan=$colspan><a class=listheading href=$href&sort=invnumber>|.$locale->text('Invoice Number').qq|</a></th>|;
  $column_header{allocated} = qq|<th class=listheading nowrap>|.$locale->text('Qty').qq|</th>|;
  $column_header{sellprice} = qq|<th class=listheading nowrap>|.$locale->text('Sellprice').qq|</th>|;  
  $column_header{costprice} = qq|<th class=listheading nowrap>|.$locale->text('Cost').qq|</th>|;
  $column_header{margin} = qq|<th class=listheading nowrap>|.$locale->text('Total').qq|</th>|;

  $form->header;

  $i = 1;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>

  <tr><td>$option</td></tr>

  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  map { print "\n$column_header{$_}" } @column_index;
  
  print qq|
        </tr>
  |;


  # add order to callback
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);


    foreach $ref (@{ $form->{cogs_history} }) {
    $ref->{margin} = $form->round_amount($ref->{margin},2);
    $ref->{costprice} = $form->round_amount($ref->{costprice},2);
    
    if ($form->{l_subtotal} eq 'Y' ) {
      if ($sameitem ne $ref->{$form->{sort}}) {
	&cogs_subtotal;
	$sameitem = $ref->{$form->{sort}};
      }
    }
   $subtotalqty += $ref->{allocated};
   $totalqty += $ref->{allocated};
   $subtotalmargin += $ref->{margin};
   $totalmargin += $ref->{margin};

     
   
   $column_data{invdate} = "<td>$ref->{invdate}&nbsp;</td>";
   $column_data{partnumber} = "<td><a href=ic.pl?action=edit&id=$ref->{parts_id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}>$ref->{partnumber}&nbsp;</a></td>";
   $column_data{invnumber} = "<td><a href=is.pl?action=edit&id=$ref->{ar_id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}>$ref->{invnumber}&nbsp;</a></td>";
   $column_data{allocated} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{allocated}, '', "&nbsp;")."</td>";
   $column_data{sellprice} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{sellprice}, '', "&nbsp;")."</td>";   
   $column_data{costprice} = "<td align=right><a href=ir.pl?action=edit&id=$ref->{ap_id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}>".$form->format_amount(\%myconfig, $ref->{costprice}, '', "&nbsp;")."</td>";
   $column_data{margin} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{margin}, '', "&nbsp;")."</td>";   
   
        $i++; $i %= 2;
    print "<tr class=listrow$i>";

    map { print "\n$column_data{$_}" } @column_index;

    print qq|
    </tr>
|;

  }
  
  

  if ($form->{l_subtotal} eq 'Y') {
    &cogs_subtotal;
  }

  
    map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
    $column_data{allocated} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalqty, 0, "&nbsp;")."</th>";
    $column_data{margin} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalmargin, 0, "&nbsp;")."</th>";    
    print "<tr class=listtotal>";

    map { print "\n$column_data{$_}" } @column_index;

    print qq|</tr>
    |;
  

  print qq|
      </table>
    </td>
  </tr>
  <tr><td><hr size=3 noshade></td></tr>
</table>

|;
 
  print qq|

<br>

<form method=post action=$form->{script}>

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=item value=$form->{searchitems}>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
|;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
  </form>

</body>
</html>
|;

}

sub cogs_subtotal { #kabai

  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
  
  $column_data{allocated} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalqty, '', "&nbsp;")."</th>";
  $column_data{margin} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalmargin, '', "&nbsp;")."</th>";
  
  $subtotalqty = 0;
  $subtotalmargin = 0;

  print "<tr class=listsubtotal>";
  map { print "\n$column_data{$_}" } @column_index;

  print qq|
  </tr>
|;

}

sub search_cogs { #kabai 

  $form->{title} = "Show COGS History";
  $form->{title} = $locale->text($form->{title});
 

  $form->header;
  
  print qq|
<body>
|;
 if ($myconfig{js}) {
 print qq|
 <script src="js/prototype.js" type="text/javascript"></script>
 <script src="js/validation.js" type="text/javascript"></script>
 <script src="js/custom.js" type="text/javascript"></script>
 |;
 }else {
 print qq|
 <script> function checkform () { return true; }</script>
 |;
 }
 print qq|
<form method=post action=$form->{script}>

<input type=hidden name=title value="$form->{title}">

<table width="100%">
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
        <tr>
          <th align=right nowrap>|.$locale->text('Number').qq|</th>
          <td><input name=partnumber size=20></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Invoice Number').qq|</th>
          <td colspan=3><input name=invnumber size=20></td>
        </tr>
	<tr>
  		<th>|.$locale->text('Invoice Date From').qq|</th>
		<td><input name=invdatefrom size=11 title="$myconfig{dateformat}" id=invdatefrom OnBlur="return dattrans('invdatefrom');" ></td>
		<th>|.$locale->text('Invoice Date To').qq|</th>
		<td><input name=invdateto size=11 title="$myconfig{dateformat}" id=invdateto OnBlur="return dattrans('invdateto');" ></td>
 	</tr>
	<tr>
	  <td></td>
          <td colspan=3>
	    <hr size=1 noshade>
	  </td>
	</tr>
	<tr>
          <td colspan=3>
            <table>
              <tr>
                <td><input name=l_subtotal class=checkbox type=checkbox value=Y checked>&nbsp;|.$locale->text('Subtotal').qq|</td>
	      </tr>
            </table>
          </td>
        </tr>
      </table>
    </td>
  </tr>
  <tr><td colspan=4><hr size=3 noshade></td></tr>
</table>

<input type=hidden name=nextsub value=cogs_results>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}
sub post_and_ship {

  if (!$form->{partnumber_1}){
    &update;
    exit;
  }
  $form->error($locale->text('Raktár nincs kiválasztva!')) unless $form->{warehouse};
  $form->{shippingdate} = $form->{transdate};
  $form->isblank("shippingdate", $locale->text('Shipping Date missing!'));
  
  local $redirectsign = 1;

  if ($nonegativestock_true) {   
   for my $s (1..$form->{rowcount} -1 ){
    $form->{"reqship_$s"} = $form->{"qty_$s"};      
   }
   if (CORE2->check_inventory(\%myconfig, \%$form)==-1){
    my ($whname, $null) = split /--/, $form->{warehouse};
    $form->error($locale->text('No negative stock allowed for ').$form->{"partnumber_$form->{stockid}"}." (".$whname.": ".$form->{stockqty}." db)");
   } 
  }
  &post;  

  CORE2->get_ship(\%myconfig, \%$form);

  my $dbh = $form->dbconnect(\%myconfig);
  ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  $dbh->disconnect;
  $form->{employee} = $form->{employee}."--".$form->{employee_id};
  $form->{notes} = $locale->text('SHIP')." ".$form->{notes};

  $form->redirect($locale->text('Inventory saved!')) if OE->save_inventory(\%myconfig, \%$form);
  $form->error($locale->text('Could not save!'));


}
sub repost {
  $form->{repost} = 1;
  IS->oldtax(\%myconfig, \%$form);
  $form->{taxaccounts} = $form->{oldtax};
  foreach $item (split / /, $form->{oldtax}) {
    $form->{"${item}_validfrom"} = $form->{transdate};
    $form->{"${item}_validto"} = $form->{transdate};
  }
  &post;
}

sub jump{
 if ($form->{navigate}==1){
   $form->{oldcallback} = $form->escape($form->{callback},1);
   $form->{callback} ="is.pl?action=edit&id=$form->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&oldcallback=$form->{oldcallback}";
   $form->{callback} =$form->escape($form->{callback},1);
   $form->{callback}="ct.pl?action=edit&id=$form->{customer_id}&db=customer&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}";
   $form->redirect;
 }
 if ($form->{navigate}==2){
    $callback="oe.pl?action=transactions&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&direction=DESC&oldsort=transdate&type=sales_order&vc=customer&open=1&l_transdate=Y&l_reqdate=Y&l_ordnumber=Y&l_name=Y&l_amount=Y&l_employee=Y&l_notes=Y&sort=transdate&customer_id=$form->{customer_id}&customer=";
    $callback.=$form->escape($form->{customer});
    $form->{callback} = $callback;
    $form->redirect;
  }
  if ($form->{navigate}==3){
    $callback="ar.pl?action=ar_transactions&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&direction=DESC&oldsort=transdate&type=purchase_order&vc=customer&open=Y&l_transdate=Y&l_invnumber=Y&l_name=Y&l_amount=Y&l_paid=Y&l_duedate=Y&l_notes=Y&sort=transdate&customer_id=$form->{customer_id}&customer=";
    $callback.=$form->escape($form->{customer});
    $form->{callback} = $callback;
    $form->redirect;
  }
 if ($form->{navigate}==5){
    $callback="gl.pl?action=generate_report&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&direction=DESC&oldsort=transdate&l_transdate=Y&l_reference=Y&l_description=Y&l_source=Y&l_debit=Y&l_credit=Y&l_accno=Y&l_acc_descr=Y&category=X&journal=all&sort=transdate&id=$form->{id}";
    $form->{callback} = $callback;
    $form->redirect;
  }
}					      