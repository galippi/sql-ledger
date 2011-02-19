#=====================================================================
# SQL-Ledger, Accounting
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
# Inventory received module
#
#======================================================================


use SL::IR;
use SL::PE;
use SL::CORE2;
use SL::OE;
require "$form->{path}/io.pl";
require "$form->{path}/arap.pl";
require "$form->{path}/rs.pl";
1;
# end of main



sub add {

  $form->{title} = $locale->text('Add Vendor Invoice');

  $form->{callback} = "$form->{script}?action=add&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}" unless $form->{callback};
  &invoice_links;
  &prepare_invoice;
  &display_form;
  
}

sub add_new {#kabai
  
  map { delete $form->{$_}} qw(id invnumber printed emailed selectcurrency selectcustomer selectdepartment selectAP selectAP_paid);
  for my $sh (1..$form->{rowcount}){
      delete $form->{"ship_$sh"};
      delete $form->{"invoice_id_$sh"};
  }

  $form->{rowcount}--;

  for my $stp (1..$form->{paidaccounts}-1){
        $form->{"paid_$stp"} = $form->parse_amount(\%myconfig, $form->{"paid_$stp"});
  }
  my $transdate_orig = $form->{transdate};
  my $duedate_orig = $form->{duedate};

  $form->{title} = $locale->text('Add Vendor Invoice');
  $form->{type} = "invoice";
 
  $form->{callback} = "$form->{script}?action=add&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}" unless $form->{callback};
  
  &invoice_links;
  &prepare_invoice;
  $form->{transdate} = $transdate_orig;
  $form->{duedate} = $duedate_orig;
  &display_form;
  
}#kabai

sub edit {

  $form->{title} = $locale->text('Edit Vendor Invoice');
  &invoice_links;
#kabai
  $form->{oddordnumber} = $form->{ordnumber};
  $form->{ordnumber} = "0";
#kabai
  &prepare_invoice;
  &display_form;
  
}


sub invoice_links {
  
  $form->{vc} = "vendor";

  # create links
  $form->{showaccnumbers_true} = $showaccnumbers_true;
  $form->create_links("AP", \%myconfig, "vendor");
  
  # currencies
  @curr = split /:/, $form->{currencies};
  chomp $curr[0];
  $form->{defaultcurrency} = $curr[0];

  map { $form->{selectcurrency} .= "<option>$_\n" } @curr;

  if ($form->{all_vendor}) {
    unless ($form->{vendor_id}) {
      $form->{vendor_id} = $form->{all_vendor}->[0]->{id};
    }
  }
#kabai
  CORE2->get_whded(\%myconfig, \%$form);
#kabai
  IR->get_vendor(\%myconfig, \%$form);
  delete $form->{notes};
  IR->retrieve_invoice(\%myconfig, \%$form);

  $form->{oldlanguage_code} = $form->{language_code};

  $form->get_partsgroup(\%myconfig, { language_code => $form->{language_code} });
  if (@ { $form->{all_partsgroup} }) {
    $form->{selectpartsgroup} = "<option>\n";
    foreach $ref (@ { $form->{all_partsgroup} }) {
      if ($ref->{translation}) {
	$form->{selectpartsgroup} .= qq|<option value="$ref->{partsgroup}--$ref->{id}">$ref->{translation}\n|;
      } else {
        $form->{selectpartsgroup} .= qq|<option value="$ref->{partsgroup}--$ref->{id}">$ref->{partsgroup}\n|;
      }
    }
  }

  if (@{ $form->{all_projects} }) { 
    $form->{selectprojectnumber} = "<option>\n";
    map { $form->{selectprojectnumber} .= qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n| } @{ $form->{all_projects} };
  }

  $form->{oldvendor} = "$form->{vendor}--$form->{vendor_id}";
  $form->{oldtransdate} = $form->{transdate};

  # vendors
  if ($form->{all_vendor}) {
    $form->{vendor} = "$form->{vendor}--$form->{vendor_id}";
    map { $form->{selectvendor} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| } (@{ $form->{all_vendor} });
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

  if (@{ $form->{all_languages} }) {
    $form->{selectlanguage} = "<option>\n";
    map { $form->{selectlanguage} .= qq|<option value="$_->{code}">$_->{description}\n| } @{ $form->{all_languages} };
  }
  
  # forex
  $form->{forex} = $form->{exchangerate};
  $exchangerate = ($form->{exchangerate}) ? $form->{exchangerate} : 1;

#kabai
  #scanned docs
  if ($myconfig{docspath}){
   opendir DOCS, "$myconfig{docspath}/.";
   @alldocs =  grep !/^\.\.?$/, readdir DOCS;
   closedir DOCS;
   #further filter
   @docs = grep !/_archiv/, @alldocs;

   $form->{selectscanned} = $form->{scanned} ? "<option value='$form->{scanned}'>$form->{scanned}\n" : "<option>\n" ;

   foreach $item (@docs) {
      $form->{selectscanned} .= qq|<option value="$item">$item\n|;
   }
  }
#kabai  
  
  foreach $key (keys %{ $form->{AP_links} }) {

    foreach $ref (@{ $form->{AP_links}{$key} }) {
      $form->{"select$key"} .= "<option>$ref->{accno}--$ref->{description}\n";
    }

    if ($key eq "AP_paid") {
      for $i (1 .. scalar @{ $form->{acc_trans}{$key} }) {
	$form->{"AP_paid_$i"} = "$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";
	# reverse paid
	$form->{"paid_$i"} = $form->{acc_trans}{$key}->[$i-1]->{amount};
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

  $form->{AP} = $form->{AP_1} unless $form->{id};

  $form->{locked} = ($form->{revtrans}) ? '1' : ($form->datetonum($form->{transdate}, \%myconfig) <= $form->datetonum($form->{closedto}, \%myconfig));

  $form->{readonly} = 1 if $myconfig{acs} =~ /AP--Vendor Invoice/;
#kabai
  # registered sources

  $form->{selectregsource} = qq|<option value=0>| . $locale->text("odd number") . qq|</option>\n|;
  while ($form->{selectAP_paid} =~ /<option>(\d+)/g){
      map { $form->{selectregsource} .= qq|<option value=$_->{regnum}>$_->{regnum}</option>\n| if ($_->{regnum_accno} eq $1 && $_->{regcheck})} (@{$form->{all_sources}});
  }					      
      map { $form->{"regacc_$_->{regnum_accno}"} = "$_->{regnum}" if $_->{regcheck}; $form->{regaccounts} .= "$_->{regnum_accno}"." " if $_->{regcheck}} (@{$form->{all_sources}});
#kabai
  
}



sub prepare_invoice {

  $form->{oldcurrency} = $form->{currency};

  if ($form->{id}) {
        
    map { $form->{$_} = $form->quote($form->{$_}) } qw(invnumber ordnumber quonumber);

    foreach $ref (@{ $form->{invoice_details} }) {
      $i++;
      map { $form->{"${_}_$i"} = $ref->{$_} } keys %{ $ref };
      $form->{"discount_$i"} = $form->format_amount(\%myconfig, $form->{"discount_$i"} * 100);

#kabai BUG
     $form->{"projectnumber_$i"} = qq|$ref->{projectnumber}--$ref->{project_id}|; 
#kabai BUG      
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
#KS
  PE->retrieve_taxreturn(\%myconfig, \%$form);
   
  # set option selected
  foreach $item (qw(AP currency)) {
    $form->{"select$item"} =~ s/ selected//;
    $form->{"select$item"} =~ s/option>\Q$form->{$item}\E/option selected>$form->{$item}/;
  }
  
  foreach $item (qw(vendor department scanned ordnumber)) {
    $form->{"select$item"} = $form->unescape2($form->{"select$item"});
    $form->{"select$item"} =~ s/ selected//;
    $form->{"select$item"} =~ s/(<option value="\Q$form->{$item}\E")/$1 selected/;
  }

  if ($form->{selectlanguage}) {
    $form->{"selectlanguage"} = $form->unescape($form->{"selectlanguage"});
    $form->{"selectlanguage"} =~ s/ selected//;
    $form->{"selectlanguage"} =~ s/(<option value="\Q$form->{language_code}\E")/$1 selected/;

    $language = qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Language').qq|</th>
		<td><select name=language_code>$form->{selectlanguage}</select></td>
		<input type=hidden name=oldlanguage_code value=$form->{oldlanguage_code}>
                <input type=hidden name="selectlanguage" value="|.
		$form->escape($form->{selectlanguage},1).qq|">
	      </tr>
|;

  }
  

  $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

  $form->{creditlimit} = $form->format_amount(\%myconfig, $form->{creditlimit}, 0, "0");
  $form->{creditremaining} = $form->format_amount(\%myconfig, $form->{creditremaining}, 0, "0");
  

  $exchangerate = "";
  if ($form->{currency} ne $form->{defaultcurrency}) {
    if ($form->{forex}) {
      $exchangerate .= qq|
                <th align=right nowrap>|.$locale->text('Exchangerate').qq|</th>
                <td>$form->{exchangerate}<input type=hidden name=exchangerate value=$form->{exchangerate}></td>
|;
    } else {
      $exchangerate .= qq|
                <th align=right nowrap>|.$locale->text('Exchangerate').qq|</th>
                <td><input name=exchangerate class="required validate-szam" size=10 value=$form->{exchangerate}></td>
|;
    }
  }
  $exchangerate .= qq|
<input type=hidden name=forex value=$form->{forex}>
|;
  
  if ($form->{selectvendor}) {
    $vendor = qq|<select class="required" name=vendor>$form->{selectvendor}</select>
                 <input type=hidden name="selectvendor" value="|.
		 $form->escape($form->{selectvendor},1).qq|">|;
  } else {
    $vendor = qq|<input name=vendor class="required" value="$form->{vendor}" size=35>|;
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

#kabai
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
<input type=hidden name=title value="$form->{title}">
<input type=hidden name=vc value="vendor">
<input type=hidden name=type value=$form->{type}>

<input type=hidden name=terms value=$form->{terms}>

<input type=hidden name=creditlimit value=$form->{creditlimit}>
<input type=hidden name=creditremaining value=$form->{creditremaining}>

<input type=hidden name=closedto value=$form->{closedto}>
<input type=hidden name=locked value=$form->{locked}>

<input type=hidden name=shipped value=$form->{shipped}>
<input type=hidden name=whded value=$form->{whded}>
<input type=hidden name=oldtransdate value=$form->{oldtransdate}>
<input type=hidden name=promptshipreceive value=$form->{promptshipreceive}>
<input type=hidden name=inwh value=$form->{inwh}>
<input type=hidden name=oldid value=$form->{oldid}>
<input type=hidden name=oldcallback value=$form->{oldcallback}>
<input type=hidden name=rcost_accno value="$form->{rcost_accno}">
<input type=hidden name=rincome_accno value="$form->{rincome_accno}">
<input type=hidden name=cash_accno value="$form->{cash_accno}">
<font color='red'> $form->{sabment} </font>
<table width=100%>
  <tr class=listtop>
    <th>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Vendor').qq|</th>
		<td colspan=3>$vendor</td>
		
		<input type=hidden name=vendor_id value=$form->{vendor_id}>
		<input type=hidden name=oldvendor value="$form->{oldvendor}">

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
	      <tr>
		<th align=right>|.$locale->text('Record in').qq|</th>
		<td colspan=3><select class="required" name=AP>$form->{selectAP}</select></td>
		<input type=hidden name=selectAP value="$form->{selectAP}">
	      </tr>
              $department
	      <tr>
		<th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td><select class="required" name=currency>$form->{selectcurrency}</select></td>
		$exchangerate
	      </tr>
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Invoice Number').qq|</th>
		<td><input name=invnumber class="required" size=11 value="$form->{invnumber}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Creation Date').qq|</th>
		<td><input name=crdate class="required" size=11 title="$myconfig{dateformat}" id=crdate OnBlur="return dattrans('crdate');" value=$form->{crdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Invoice Date').qq|</th>
		<td><input name=transdate class="required" size=11 title="$myconfig{dateformat}" id=transdate OnBlur="return dattrans('transdate');" value=$form->{transdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Due Date').qq|</th>
		<td><input name=duedate class="required" size=11 title="$myconfig{dateformat}" id=duedate OnBlur="return dattrans('duedate');" value=$form->{duedate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text($ordnumbertext).qq|</th>
		<td>$ordnumber</td>
		<input type="hidden" name="selectordnumber" value="|.$form->escape($form->{selectordnumber},1).qq|">
                <input type=hidden name=quonumber value="$form->{quonumber}">
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
<input type=hidden name=selectcurrency value="$form->{selectcurrency}">
<input type=hidden name=defaultcurrency value=$form->{defaultcurrency}>
<input type=hidden name=fxgain_accno value=$form->{fxgain_accno}>
<input type=hidden name=fxloss_accno value=$form->{fxloss_accno}>

<input type=hidden name=taxpart value="$form->{taxpart}">
<input type=hidden name=taxservice value="$form->{taxservice}">

<input type=hidden name=taxaccounts value="$form->{taxaccounts}">
|;

  foreach $item (split / /, $form->{taxaccounts}) {
    print qq|
<input type=hidden name="${item}_rate" value="$form->{"${item}_rate"}">
<input type=hidden name="${item}_description" value="$form->{"${item}_description"}">
<input type=hidden name="${item}_validfrom" value="$form->{"${item}_validfrom"}">
<input type=hidden name="${item}_validto" value="$form->{"${item}_validto"}">
<input type=hidden name=taxreturn value="$form->{taxreturn}">
|;
  }

}


sub form_footer {
#kabai
   $scanned =  qq| <br><br>
		<select name=scanned>$form->{selectscanned}</select>
		<input type=hidden name=selectscanned value="|.$form->escape($form->{selectscanned},1).qq|">
                <input class=submit type=button
                onclick="if(document.forms[0].scanned.options[document.forms[0].scanned.selectedIndex].text){window.location='$myconfig{docspath}/' +document.forms[0].scanned.options[document.forms[0].scanned.selectedIndex].text}";
                value="|.$locale->text('Show Document').qq|">
   | if $form->{selectscanned};


#                onclick="window.open('$myconfig{docspath}/' +document.forms[0].scanned.options[document.forms[0].scanned.selectedIndex].text,'toolbar=no')";


#kabai totals should be rounded to int always
  $form->{invsubtotal} = $form->round_amount($form->{invsubtotal}, 0) if $form->{currency} eq "HUF";
#kabai
  $form->{invtotal} = $form->{invsubtotal};
  
  if (($rows = $form->numtextrows($form->{notes}, 25, 8)) < 2) {
    $rows = 2;
  }
  if (($introws = $form->numtextrows($form->{intnotes}, 35, 8)) < 2) {
    $introws = 2;
  }
  $rows = ($rows > $introws) ? $rows : $introws;
  $notes = qq|<textarea name=notes rows=$rows cols=25 wrap=soft>$form->{notes}</textarea>|;
  $intnotes = qq|<textarea name=intnotes rows=$rows cols=35 wrap=soft>$form->{intnotes}</textarea>|;
  
  $form->{taxincluded} = ($form->{taxincluded}) ? "checked" : "";

  $taxincluded = "";
  if ($form->{taxaccounts}) {
    $taxincluded = qq|
		<input name=taxincluded class=checkbox type=checkbox value=1 $form->{taxincluded}> <b>|.$locale->text('Tax Included').qq|</b>
|;
  }
#kabai get booked values instead of calculated
 if ($form->{id} && $form->{action} eq "edit"){
  CORE2->get_booked(\%myconfig,\%$form);
  my ($roundvalue,$exchrate);
  if ($form->{currency} eq "HUF"){
   $roundvalue = 0;
   $exchrate = -1;
  }else{
   $roundvalue = 2;
   $exchrate = $form->parse_amount(\%myconfig,$form->{exchangerate})*-1;
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
	$form->{invtotal} += $form->{"${item}_total"} = $form->round_amount($form->{"${item}_base"} * $form->{"${item}_rate"}, $roundvalue);
#kabai
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
	    $taxincluded
	    <br>
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
  <tr>
    <td>
      <table width=100%>
        <tr>
	  <th colspan=6 class=listheading>|.$locale->text('Payments').qq|</th>
	</tr>
|;

    if ($form->{currency} eq $form->{defaultcurrency}) {
      @column_index = qw(datepaid source memo paid AP_paid);
    } else {
      @column_index = qw(datepaid source memo paid exchangerate AP_paid);
    }

    $column_data{datepaid} = "<th>".$locale->text('Date')."</th>";
    $column_data{paid} = "<th>".$locale->text('Amount')."</th>";
    $column_data{exchangerate} = "<th>".$locale->text('Exch')."</th>";
    $column_data{AP_paid} = "<th>".$locale->text('Account')."</th>";
    $column_data{source} = "<th>".$locale->text('Source')."</th>";
    $column_data{memo} = "<th>".$locale->text('Memo')."</th>";

    print qq|
	<tr>
|;
    map { print "$column_data{$_}\n" } @column_index;
    print qq|
	</tr>
|;

    $form->{paidaccounts}++ if ($form->{"paid_$form->{paidaccounts}"});
  
    if ($form->{currency} eq "HUF" && $form->{AP} =~ /(készpénz|Készpénz)/ && !$form->{id}){
        my $invtotal = $form->parse_amount(\%myconfig, $form->{invtotal});
        my $mod_invtotal = $invtotal % 5;
      	if ($mod_invtotal < 3) {
	  $form->{paid_1} = $invtotal-$mod_invtotal;
          $form->{paid_2} = ($mod_invtotal == 0) ? "0" : $mod_invtotal;
	  $form->{AP_paid_2} = $form->{rincome_accno};
	  $form->{memo_2} = $locale->text('Rounding income');
        }else{
	  $form->{paid_1} = $invtotal-$mod_invtotal + 5;
          $form->{paid_2} = ($mod_invtotal == 0) ? "0" : $mod_invtotal - 5;
	  $form->{AP_paid_2} = $form->{rcost_accno};
	  $form->{memo_2} = $locale->text('Rounding cost');
        }	  
        $form->{datepaid_1} = $form->{datepaid_2} = $form->{transdate};
	$form->{source_1} = $form->{source_2} = $form->{invnumber} ;
        $form->{paidaccounts}++ if ($form->{paidaccounts} == 1);
      $form->{AP_paid_1} = $form->{cash_accno} if $form->{cash_accno};
    }


    for $i (1 .. $form->{paidaccounts}) {

      print qq|
	<tr>
|;

      $form->{"selectAP_paid_$i"} = $form->{selectAP_paid};
      $form->{"selectAP_paid_$i"} =~ s/option>\Q$form->{"AP_paid_$i"}\E/option selected>$form->{"AP_paid_$i"}/;
#kabai
#kabai
      my $readonly;
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
      $form->{"selectregsource_$i"} =~ s/(<option value=\Q$form->{"regsource_$i"}\E)/$1 selected/ if $form->{"regsource_$i"};    
#kabai
      my ($APpaidnumber) = split /--/, $form->{"AP_paid_$i"};      
      my $regsourcevalue = "regacc_".$APpaidnumber;
      $form->{"regsource_$i"} = $form->{$regsourcevalue}; 
      $form->{"selectregsource_$i"} =~ s/(<option value=\Q$form->{"regsource_$i"}\E)/$1 selected/ if $form->{"regsource_$i"};    
#kabai
      # format amounts
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
      $column_data{"AP_paid_$i"} = qq|<td align=center><select name="AP_paid_$i">$form->{"selectAP_paid_$i"}</select></td>|;
      $column_data{"datepaid_$i"} = qq|<td align=center><input name="datepaid_$i" size=11
       title="$myconfig{dateformat}" id=datepaid_$i OnBlur="return dattrans('datepaid_$i');" value=$form->{"datepaid_$i"}></td>|;
#kabai
    $column_data{"source_$i"} = qq|<td align=center>|;
    $column_data{"source_$i"} .= qq|<input name=rsprint type=radio class=radio value=$i>
				   <select name="regsource_$i">
				   $form->{"selectregsource_$i"}</select>| if ($cashapar_true);
    $column_data{"source_$i"} .= qq|<input name="source_$i" $readonly size=11 value="$form->{"source_$i"}">
				   </td>|;
      $column_data{"memo_$i"} = qq|<td align=center><input name="memo_$i" size=11 value='$form->{"memo_$i"}'></td>|;

      map { print qq|$column_data{"${_}_$i"}\n| } @column_index;

      print qq|
	</tr>
|;
    }
#kabai
  foreach $item (split / /, $form->{regaccounts}) {
    $hiddenregacc.= qq|<input type=hidden name="regacc_$item" value=$form->{"regacc_$item"}>\n|;
  }
#kabai     
    print qq|
	    <input type=hidden name=paidaccounts value=$form->{paidaccounts}>
	    <input type=hidden name=selectAP_paid value="$form->{selectAP_paid}">
	    <input type=hidden name=selectregsource value="$form->{selectregsource}">
	    <input type=hidden name=regaccounts value="$form->{regaccounts}">
	    $hiddenregacc
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
<br>
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
      print qq|<input class=submit type=submit name=action value="|.$locale->text('Update').qq|">
|;

      if (!$form->{locked}) {
    
	print qq|
	<input class=submit type=submit name=action value="|.$locale->text('Post').qq|">
        |;
	print qq|
	<input class=submit type=submit name=action value="|.$locale->text('Delete').qq|">
|;
      }
      print qq|
      	<input class=submit type=submit name=action value="|.$locale->text('Purchase Order').qq|">
      |	 if $myconfig{acs} !~ /Order Entry--Purchase Order/;
      print qq|
	<input class=submit type=submit name=action value="|.$locale->text('Add new').qq|">|;
     
    } else {
      if ($transdate > $closedto) {
	print qq|<input class=submit type=submit name=action value="|.$locale->text('Update').qq|">
	|;
        if (!$form->{promptshipreceive} || !$invacc_yes){
	 print qq|<input class=submit type=submit name=action onclick="return checkform();" value="|.$locale->text('Post').qq|">|;
        }else{
          print qq|
          &nbsp;&nbsp;&nbsp;&nbsp;$warehouse &nbsp;&nbsp;<input class=submit type=submit name=action onclick="return checkform();" value="|.$locale->text('Post And Receive').qq|">        
          |;
        }
      }
    }
#kabai
      print qq| <input class=submit type=submit name=action value="|.$locale->text('New vendor').qq|">|;
#KS
      print qq|<th align=right nowrap><b> |.$locale->text('Navigation').qq|</b></th>
              <select name=navigate><option value=1>|.$locale->text('Vendor Basic Data').qq|
              <option value=2>|.$locale->text('Opened Purchase Orders').qq|
              <option value=3>|.$locale->text('Opened AP Transactions');
              if(!$form->{id} and $form->{oldid}){print qq|<option value=4 selected>|.$locale->text('Previous Transaction');}
	      if($form->{id}){print qq|<option value=5>|.$locale->text('Accountant Journals');}
	      print qq|</select><input class=submit type=submit name=action value="|.$locale->text('Jump').qq|">|;
  print qq|
	      $scanned
            |;
#kabai
      
  }
#kabai
  if ($cashapar_true) {
		$form->{forms}{cash_voucher} = "Cash Voucher" unless ($form->{forms});
		$form->{format} = "postscript" unless ($form->{format});
		$form->{media} = "printer" unless ($form->{media});
		$form->{copies} = 3 unless ($form->{copies});
		print "<br> <br>";
		&print_options;
  }
#kabai
  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }
 #KS -- oldcallback 
print qq|
<input name=callback type=hidden value=|.(($form->{oldcallback}) ? "$form->{oldcallback}" : "$form->{callback}").qq|>


<input type=hidden name=rowcount value=$form->{rowcount}>


<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
<input type=hidden name=oeid value=$form->{oeid}>

</form>

</body>
</html>
|;
}



sub update {
  $oldexchangerate = $form->{exchangerate};
  map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(exchangerate creditlimit creditremaining);
  $form->error($locale->text('Bad exchangerate format').": ".$oldexchangerate) if ($form->{exchangerate} > 1000 && $form->{currency} =~ /(USD|EUR)/);
  
  &check_name(vendor);

  if ($form->{transdate} ne $form->{oldtransdate}) {
    $form->{duedate} = $form->current_date(\%myconfig, $form->{transdate}, $form->{terms} * 1);
    $form->{oldtransdate} = $form->{transdate};
  }

  $form->{exchangerate} = $exchangerate if ($form->{forex} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}, 'sell')));

  for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"}) {
      map { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) } qw(paid exchangerate);

      $form->{"exchangerate_$i"} = $exchangerate if ($form->{"forex_$i"} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{"datepaid_$i"}, 'sell_paid')));
    }
  }
  
  $i = $form->{rowcount};
  $exchangerate = ($form->{exchangerate}) ? $form->{exchangerate} : 1;

  foreach $item (qw(partsgroup projectnumber)) {
    $form->{"select$item"} = $form->unescape($form->{"select$item"}) if $form->{"select$item"};
  }
  
  if (($form->{"partnumber_$i"} eq "") && ($form->{"description_$i"} eq "") && ($form->{"partsgroup_$i"} eq "")) {
    &check_form;
  } else {
   
    #$form->{transdate} = $form->{oldtransdate};
    IR->retrieve_item(\%myconfig, \%$form);

    my $rows = scalar @{ $form->{item_list} };

    if ($rows) {
      $form->{"qty_$i"}                     = 1 unless ($form->{"qty_$i"});
      
      if ($rows > 1) {
	
	&select_item;
	exit;
	
      } else {
        # override sellprice if there is one entered
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
	  #$form->{"sellprice_$i"} /= $exchangerate;
	}
     
        $amount = $form->{"sellprice_$i"} * (1 - $form->{"discount_$i"} / 100) * $form->{"qty_$i"};
	$form->{"sellprice_$i"} = $form->format_amount(\%myconfig, $form->{"sellprice_$i"}, $decimalplaces);
	$form->{"qty_$i"} =  $form->format_amount(\%myconfig, $form->{"qty_$i"});
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
      }

      &display_form;

    } else {
      # ok, so this is a new part
      # ask if it is a part or service item

      if ($form->{"partsgroup_$i"} && ($form->{"partsnumber_$i"} eq "") && ($form->{"description_$i"} eq "")) {
	$form->{rowcount}--;
	$form->{"discount_$i"} = "";
	&display_form;
      } else {
	
	$form->{"id_$i"}	= 0;
	$form->{"unit_$i"}	= $locale->text('ea');

	&new_item;

      }
    }
  }
}



sub post {
if ($form->{mod_save}) {goto friss};
 $form->close_oe(\%myconfig) if $form->{oeid};

  if ($form->{transdate} le $form->{taxreturn})
     {$form->error($locale->text('Cannot post invoice for a tax returned period!'));}
      
  $form->isblank("transdate", $locale->text('Invoice Date missing!'));
#kabai
  $form->isblank("crdate", $locale->text('Creation Date missing!'));

  if ($strictcash_true){
   for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"regsource_$i"} ne "" && $form->{"paid_$i"}){
    ($regsourcevalue, $null) = split /--/, $form->{"AP_paid_$i"};
      if ($form->{"regacc_$regsourcevalue"} ne $form->{"regsource_$i"} || $form->{"source_$i"}){
	$form->error($locale->text('This source number does not belong to the selected cash account!'));
      }	
    }  
   }
  }  
#kabai
  $form->isblank("vendor", $locale->text('Vendor missing!'));
  
  # if the vendor changed get new values
  if (&check_name(vendor)) {
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
  
  
  ($form->{AP}) = split /--/, $form->{AP};
  ($form->{AP_paid}) = split /--/, $form->{AP_paid};
  
  $form->{id} = 0 if $form->{postasnew};

#kabai   $form->redirect($locale->text('Invoice')." $form->{invnumber} ".$locale->text('posted!')) if (IR->post_invoice(\%myconfig, \%$form));
  $form->{promptcogs_true} = $promptcogs_true;
  $form->{cogsinorder_true} = $cogsinorder_true;
  # add up debits and credits
if (!$form->{adjustment}) {
  my $felso, $felsoh;
  for $i (1 .. $form->{rowcount}) {
    my ($ii, $null)=split /--/, $form->{"AP_paid_$i"};
    $form->{cashaccount}=$ii;
    undef $form->{chart_id};
    AM->get_cashlimit(\%myconfig, \%$form);
    if ($form->{chart_id} and $form->{"paid_$i"}){
      AM->get_sumcash(\%myconfig, \%$form, $form->{"datepaid_$i"});
      my $ossz=$form->{sumamount}-$form->parse_amount(\%myconfig, $form->{"paid_$i"});
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
    $form->{sabment}=$locale->text('Item saved') if !$form->{id};
    if ($form->{id}){
        &post_modify;
        exit;
    }
friss:
			      																								  
  if (IR->post_invoice(\%myconfig, \%$form)){
    $form->{callback}.="&sabment=".$form->escape($form->{sabment});
    if ($form->{scanned} && $form->{scanned} !~ /_archiv/){
      use File::Copy;
      copy("$myconfig{docspath}/$form->{scanned}","$myconfig{docspath}/$form->{archive}");
      unlink "$myconfig{docspath}/$form->{scanned}";
   }
    IR->update_lastcost(\%myconfig, \%$form) if $lastcostupdate_true;
    $form->{callback}.="&oldid=$form->{id}" if ($form->{callback});
    $form->redirect if !$redirectsign && !$post_and_print;
  } else{
   $form->error($locale->text('Cannot post invoice!'));
  } 
#kabai

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
												
sub post_modify {
  $form->header;
  
   print qq|
    <body>
	
    <form method=post action=$form->{script}>
	    
    <input type=hidden name=mod_save value=1>
	  |;
      #$form->error($_[0]);
     $form->hide_form();
      my $szov= $locale->text('Are you sure you want to modify transaction?');
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

<h4>|.$locale->text('Are you sure you want to delete Invoice Number').qq| $form->{invnumber}</h4>
<p>
<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>
|;


}

sub new_vendor { #kabai
    $form->{callback} = $form->escape($form->{callback},1);
    $form->{callback} = "ct.pl?path=bin/mozilla&action=add&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}&db=vendor";
    $form->redirect;
}
	    

sub yes {
    $form->{promptcogs_true} = $promptcogs_true;
    
  if (IR->delete_invoice(\%myconfig, \%$form)){
    $form->redirect($locale->text('Invoice deleted!'));
  }
  $form->error($locale->text('Cannot delete invoice!'));

}

sub post_and_receive {

  if (!$form->{partnumber_1}){
    &update;
    exit;
  }
  $form->error($locale->text('Raktár nincs kiválasztva!')) unless $form->{warehouse};
  $form->{shippingdate} = $form->{transdate};
  $form->isblank("shippingdate", $locale->text('Shipping Date missing!'));
  
  local $redirectsign = 1;

  &post;  

  CORE2->get_ship(\%myconfig, \%$form);

  my $dbh = $form->dbconnect(\%myconfig);
  ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  $dbh->disconnect;
  $form->{employee} = $form->{employee}."--".$form->{employee_id};
  $form->{notes} = $locale->text('RECEIVE')." ".$form->{notes};

 
  $form->redirect($locale->text('Inventory saved!')) if OE->save_inventory(\%myconfig, \%$form);
  $form->error($locale->text('Could not save!'));

}

#KS
sub jump{
  if ($form->{navigate}==1){
    $form->{oldcallback} = $form->escape($form->{callback},1);
    $form->{callback} ="ir.pl?action=edit&id=$form->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&oldcallback=$form->{oldcallback}";
    $form->{callback} =$form->escape($form->{callback},1);
    $form->{callback}="ct.pl?action=edit&id=$form->{vendor_id}&db=vendor&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}";
    $form->redirect;
  }
  if ($form->{navigate}==2){
    $callback="oe.pl?action=transactions&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&direction=DESC&oldsort=transdate&type=purchase_order&vc=vendor&open=1&l_transdate=Y&l_reqdate=Y&l_ordnumber=Y&l_name=Y&l_amount=Y&l_employee=Y&l_notes=Y&sort=transdate&vendor_id=$form->{vendor_id}&vendor=";
    $callback.=$form->escape($form->{vendor});
    $form->{callback} = $callback;
    $form->redirect;
  }
  if ($form->{navigate}==3){
    $callback="ap.pl?action=ap_transactions&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&direction=DESC&oldsort=transdate&type=purchase_order&vc=vendor&open=Y&l_transdate=Y&l_invnumber=Y&l_ordnumber=Y&l_name=Y&l_amount=Y&l_paid=Y&l_duedate=Y&l_notes=Y&l_scanned=Y&sort=transdate&vendor_id=$form->{vendor_id}&vendor=";
    $callback.=$form->escape($form->{vendor});
    $form->{callback} = $callback;
    $form->redirect;
  }
  if ($form->{navigate}==4){
    $form->{oldcallback} = $form->escape($form->{callback},1);
    $form->{callback} ="ir.pl?action=edit&id=$form->{id}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&oldcallback=$form->{oldcallback}";
    $form->{callback} =$form->escape($form->{callback},1);
    $form->{callback} ="ir.pl?action=edit&id=$form->{oldid}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}";
    $form->redirect;
  }
  if ($form->{navigate}==5){
    $callback="gl.pl?action=generate_report&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&direction=DESC&oldsort=transdate&l_transdate=Y&l_reference=Y&l_description=Y&l_source=Y&l_debit=Y&l_credit=Y&l_accno=Y&l_acc_descr=Y&category=X&journal=all&sort=transdate&id=$form->{id}";
    $form->{callback} = $callback;
    $form->redirect;
  }
}		     		     			 