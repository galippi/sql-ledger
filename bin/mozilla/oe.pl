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
# Order entry module
# Quotation module
#
#======================================================================


use SL::OE;
use SL::IR;
use SL::IS;
use SL::PE;
use SL::CORE2;
require "$form->{path}/io.pl";
require "$form->{path}/arap.pl";


1;
# end of main


sub add {

  if ($form->{type} eq 'purchase_order') {
    $form->{title} = $locale->text('Add Purchase Order');
    $form->{vc} = 'vendor';
  }
  if ($form->{type} eq 'sales_order') {
    $form->{title} = $locale->text('Add Sales Order');
    $form->{vc} = 'customer';
  }
  if ($form->{type} eq 'request_quotation') {
    $form->{title} = $locale->text('Add Request for Quotation');
    $form->{vc} = 'vendor';
  }
  if ($form->{type} eq 'sales_quotation') {
    $form->{title} = $locale->text('Add Quotation');
    $form->{vc} = 'customer';
  }

  $form->{callback} = "$form->{script}?action=add&type=$form->{type}&vc=$form->{vc}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}" unless $form->{callback};
  
  &order_links;
  &prepare_order;
  &display_form;

}


sub edit {
  
  if ($form->{type} eq 'purchase_order') {
    $form->{title} = $locale->text('Edit Purchase Order');
    $form->{vc} = 'vendor';
  }
  if ($form->{type} eq 'sales_order') {
    $form->{title} = $locale->text('Edit Sales Order');
    $form->{vc} = 'customer';
  }
  if ($form->{type} eq 'request_quotation') {
    $form->{title} = $locale->text('Edit Request for Quotation');
    $form->{vc} = 'vendor';
  }
  if ($form->{type} eq 'sales_quotation') {
    $form->{title} = $locale->text('Edit Quotation');
    $form->{vc} = 'customer';
  }
  &order_links;
  &prepare_order;
  &display_form;
 
}



sub order_links {
  
# get customer/vendor
#pasztor
  if ($form->{type} ne 'trans_packing_list') {
    $form->all_vc(\%myconfig, $form->{vc}, ($form->{vc} eq 'customer') ? "AR" : "AP");
  }
 
  $form->get_partsgroup(\%myconfig);
  if (@{ $form->{all_partsgroup} }) {
    $form->{selectpartsgroup} = "<option>\n";
    map { $form->{selectpartsgroup} .= qq|<option value="$_->{partsgroup}--$_->{id}">$_->{partsgroup}\n| } @{ $form->{all_partsgroup} }; 
  }
#kabai
  CORE2->get_whded(\%myconfig, \%$form);
#kabai

  # retrieve order/quotation
  OE->retrieve(\%myconfig, \%$form);

  # currencies
  @curr = split /:/, $form->{currencies};
  chomp $curr[0];
  $form->{defaultcurrency} = $curr[0];
  $form->{currency} = $form->{defaultcurrency} unless $form->{currency};
  
  map { $form->{selectcurrency} .= "<option>$_\n" } @curr;

  $form->{oldlanguage_code} = $form->{language_code};
  
  $form->get_partsgroup(\%myconfig, { language_code => $form->{language_code} });
  
  if (@{ $form->{all_partsgroup} }) {
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
 
  $form->{shipto} = 1 if $form->{id};

  if (@{ $form->{"all_$form->{vc}"} }) {
    unless ($form->{"$form->{vc}_id"}) {
      $form->{"$form->{vc}_id"} = $form->{"all_$form->{vc}"}->[0]->{id};
    }
  }
  
  # get customer / vendor
  if ($form->{type} =~ /(purchase_order|request_quotation|receive_order)/ ) {
    IR->get_vendor(\%myconfig, \%$form);
  }
  if ($form->{type} =~ /(sales|ship)_(order|quotation)/) {
    IS->get_customer(\%myconfig, \%$form);
  }

  ($form->{$form->{vc}}) = split /--/, $form->{$form->{vc}};
  $form->{"old$form->{vc}"} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;

  # build selection list
  if (@{ $form->{"all_$form->{vc}"} }) {
    $form->{$form->{vc}} = qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;
    map { $form->{"select$form->{vc}"} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| } (@{ $form->{"all_$form->{vc}"} });
  }
  
  # departments
  if (@{ $form->{all_departments} }) {
    $form->{selectdepartment} = "<option>\n";
    $form->{department} = "$form->{department}--$form->{department_id}";

    map { $form->{selectdepartment} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| } (@{ $form->{all_departments} });
  }

  $form->{employee} = "$form->{employee}--$form->{employee_id}";

  # sales staff
  if (@{ $form->{all_employees} }) {
    $form->{selectemployee} = "";
    map { $form->{selectemployee} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| } (@{ $form->{all_employees} });
  }

  if (@{ $form->{all_languages} }) {
    $form->{selectlanguage} = "<option>\n";
    map { $form->{selectlanguage} .= qq|<option value="$_->{code}">$_->{description}\n| } @{ $form->{all_languages} };
  }
  
  # forex
  $form->{forex} = $form->{exchangerate};
  
}


sub prepare_order {

#kabai
  $form->{format} = "$myconfig{prformat}";
  $form->{media} = "$myconfig{prmedia}";
  $form->{formname} = $form->{type};
  $form->{oldcurrency} = $form->{currency};
 
  if ($form->{id}) {
    
    map { $form->{$_} = $form->quote($form->{$_}) } qw(ordnumber quonumber shippingpoint shipvia notes intnotes shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact);
    
    foreach $ref (@{ $form->{form_details} } ) {
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
      $form->{"ship_$i"} = $form->format_amount(\%myconfig, $form->{"ship_$i"});
      $form->{"oldqty_$i"} = $form->{"qty_$i"};
      
      map { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) } qw(partnumber sku description unit);
      $form->{rowcount} = $i;
    }
  }

  if ($form->{type} eq 'sales_quotation') {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Quotations--Quotation/;
  }
  if ($form->{type} eq 'request_quotation') {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Quotations--RFQ/;
  }
  if ($form->{type} eq 'sales_order') {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Order Entry--Sales Order/;
  }
  if ($form->{type} eq 'purchase_order') {
    $form->{readonly} = 1 if $myconfig{acs} =~ /Order Entry--Purchase Order/;
  }

}


sub form_header {

  $checkedopen = ($form->{closed}) ? "" : "checked";
  $checkedclosed = ($form->{closed}) ? "checked" : "";

  if ($form->{id}) {
    $openclosed = qq|
      <tr>
	<th nowrap align=right><input name=closed type=radio class=radio value=0 $checkedopen> |.$locale->text('Open').qq|</th>
	<th nowrap align=left><input name=closed type=radio class=radio value=1 $checkedclosed> |.$locale->text('Closed').qq|</th>
      </tr>
|;
  }

  # set option selected
  $form->{selectcurrency} =~ s/ selected//;
  $form->{selectcurrency} =~ s/option>\Q$form->{currency}\E/option selected>$form->{currency}/; 
  
  foreach $item ($form->{vc}, department, employee) {
    $form->{"select$item"} = $form->unescape2($form->{"select$item"});
    $form->{"select$item"} =~ s/ selected//;
    $form->{"select$item"} =~ s/(<option value="\Q$form->{$item}\E")/$1 selected/;
  }
  
    
  $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

  $form->{creditlimit} = $form->format_amount(\%myconfig, $form->{creditlimit}, 0, "0");
  $form->{creditremaining} = $form->format_amount(\%myconfig, $form->{creditremaining}, 0, "0");
  
  $exchangerate = qq|
<input type=hidden name=forex value=$form->{forex}>
|;

  if ($form->{currency} ne $form->{defaultcurrency}) {
    if ($form->{forex}) {
      $exchangerate .= qq|<th align=right>|.$locale->text('Exchangerate').qq|</th><td>$form->{exchangerate}</td>
      <input type=hidden name=exchangerate value=$form->{exchangerate}>
|;
    } else {
      $exchangerate .= qq|<th align=right>|.$locale->text('Exchangerate').qq|</th><td><input name=exchangerate class="required validate-szam" size=10 value=$form->{exchangerate}></td>|;
    }
  }


  $vclabel = ucfirst $form->{vc};
  $vclabel = $locale->text($vclabel);

  $terms = qq|
                    <tr>
		      <th align=right nowrap>|.$locale->text('Terms').qq|</th>
		      <td nowrap><input name=terms size="3" maxlength="3" value=$form->{terms}> |.$locale->text('days').qq|</td>
                    </tr>
|;


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


  if ($form->{type} !~ /_quotation$/) {
    $ordnumber = qq|
	      <tr>
		<th width=70% align=right nowrap>|.$locale->text('Order Number').qq|</th>
                <td><input name=ordnumber size=11 value="$form->{ordnumber}"></td>
		<input type=hidden name=quonumber value="$form->{quonumber}">
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Order Date').qq|</th>
		<td><input name=transdate class="required" size=11 title="$myconfig{dateformat}" id=transdate OnBlur="return dattrans('transdate');" value=$form->{transdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap=true>|.$locale->text('Required by').qq|</th>
		<td><input name=reqdate size=11 title="$myconfig{dateformat}" id=reqdate OnBlur="return dattrans('reqdate');"  value=$form->{reqdate}></td>
	      </tr>
|;
    
    $n = ($form->{creditremaining} =~ /-/) ? "0" : "1";
   
    $creditremaining = qq|
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
|;
  } else {
    if ($form->{type} eq 'sales_quotation') {
      $ordnumber = qq|
	      <tr>
		<th width=70% align=right nowrap>|.$locale->text('Quotation Number').qq|</th>
		<td><input name=quonumber size=11 value="$form->{quonumber}"></td>
		<input type=hidden name=ordnumber value="$form->{ordnumber}">
	      </tr>
|;
    } else {
      $ordnumber = qq|
	      <tr>
		<th width=70% align=right nowrap>|.$locale->text('RFQ Number').qq|</th>
		<td><input name=quonumber size=11 value="$form->{quonumber}"></td>
		<input type=hidden name=ordnumber value="$form->{ordnumber}">
	      </tr>
|;

      $terms = "";
    }
     

    $ordnumber .= qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Quotation Date').qq|</th>
		<td><input name=transdate class="required" size=11 title="$myconfig{dateformat}" id=transdate OnBlur="return dattrans('transdate');" value=$form->{transdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap=true>|.$locale->text('Required by').qq|</th>
		<td><input name=reqdate size=11 title="$myconfig{dateformat}" id=reqdate OnBlur="return dattrans('reqdate');" value=$form->{reqdate}></td>
	      </tr>
|;

  }

  if ($form->{"select$form->{vc}"}) {
    $vc = qq|<select class="required" name=$form->{vc}>$form->{"select$form->{vc}"}</select>
             <input type=hidden name="select$form->{vc}" value="|
	     .$form->escape($form->{"select$form->{vc}"},1).qq|">|;
  } else {
    $vc = qq|<input name=$form->{vc} class="required" value="$form->{$form->{vc}}" size=35>|;
  }
  $department = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Department').qq|</th>
		<td colspan=3><select name=department>$form->{selectdepartment}</select>
		<input type=hidden name=selectdepartment value="|
		.$form->escape($form->{selectdepartment},1).qq|">
		</td>
	      </tr>
| if $form->{selectdepartment};

  $employee = qq|
              <input type=hidden name=employee value="$form->{employee}">
|;

  if ($form->{type} eq 'sales_order') {
    if ($form->{selectemployee}) {
      $employee = qq|
 	      <tr>
	        <th align=right nowrap>|.$locale->text('Salesperson').qq|</th>
		<td><select name=employee>$form->{selectemployee}</select></td>
		<input type=hidden name=selectemployee value="|.
		$form->escape($form->{selectemployee},1).qq|"
	      </tr>
|;
    }
  } else {
      $employee = qq|
 	      <tr>
	        <th align=right nowrap>|.$locale->text('Employee').qq|</th>
		<td><select name=employee>$form->{selectemployee}</select></td>
		<input type=hidden name=selectemployee value="|.
		$form->escape($form->{selectemployee},1).qq|"
	      </tr>
|;
  }
#kabai
  $i = $form->{rowcount};
  $focus = qq|onLoad="document.forms[0].qty_${i}.select();document.forms[0].qty_${i}.focus()"| if $i;
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

<input type=hidden name=type value=$form->{type}>
<input type=hidden name=formname value=$form->{formname}>
<input type=hidden name=media value=$form->{media}>
<input type=hidden name=format value=$form->{format}>

<input type=hidden name=queued value="$form->{queued}">
<input type=hidden name=printed value="$form->{printed}">
<input type=hidden name=emailed value="$form->{emailed}">

<input type=hidden name=vc value=$form->{vc}>

<input type=hidden name=title value="$form->{title}">

<input type=hidden name=discount value=$form->{discount}>
<input type=hidden name=creditlimit value=$form->{creditlimit}>
<input type=hidden name=creditremaining value=$form->{creditremaining}>

<input type=hidden name=tradediscount value=$form->{tradediscount}>
<input type=hidden name=business value="$form->{business}">

<input type=hidden name=promptshipreceive value=$form->{promptshipreceive}>
<input type=hidden name=whded value=$form->{whded}>
<input type=hidden name=oldid value=$form->{oldid}>
<input type=hidden name=oldcallback value=$form->{oldcallback}>

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width="100%">
        <tr valign=top>
	  <td>
	    <table width=100%>
	      <tr>
		<th align=right>$vclabel</th>
		<td colspan=3>$vc</td>
		<input type=hidden name=$form->{vc}_id value=$form->{"$form->{vc}_id"}>
		<input type=hidden name="old$form->{vc}" value="$form->{"old$form->{vc}"}">
	      </tr>
	      $creditremaining
	      $business
	      $department
	      <tr>
		<th align=right>|.$locale->text('Currency').qq|</th>
		<td><select class="required" name=currency>$form->{selectcurrency}</select></td>
		<input type=hidden name=selectcurrency value="$form->{selectcurrency}">
		<input type=hidden name=defaultcurrency value=$form->{defaultcurrency}>
		$exchangerate
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Shipping Point').qq|</th>
		<td colspan=3><input name=shippingpoint size=35 value="$form->{shippingpoint}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Ship via').qq|</th>
		<td colspan=3><input name=shipvia size=35 value="$form->{shipvia}"></td>
	      </tr>
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $openclosed
	      $employee
	      $ordnumber
	      $terms
	    </table>
	  </td>
	</tr>
      </table>
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
|;
  }

}


sub form_footer {

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
            <tr height="5"></tr>
            <tr>
	      <td align=right>
	      <input name=taxincluded class=checkbox type=checkbox value=1 $form->{taxincluded}></td>
	      <th align=left>|.$locale->text('Tax Included').qq|</th>
	    </tr>
|;
  }

  if (!$form->{taxincluded}) {
    
    foreach $item (split / /, $form->{taxaccounts}) {
#kabai    
    if ($form->datetonum($form->{"${item}_validfrom"},\%myconfig) > $form->datetonum($form->{transdate}, \%myconfig)
        || $form->datetonum($form->{"${item}_validto"},\%myconfig) < $form->datetonum($form->{transdate}, \%myconfig))
    {
        next;
    }   

      if ($form->{"${item}_base"}) {
#kabai 
	my $roundvalue = $form->{currency} eq "HUF" ? 0 : 2;
	$form->{invtotal} += $form->{"${item}_total"} = $form->round_amount($form->{"${item}_base"} * $form->{"${item}_rate"}, $roundvalue);
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

  $form->{oldinvtotal} = $form->{invtotal};
  $form->{invtotal} = $form->format_amount(\%myconfig, $form->{invtotal}, 2, 0);


  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr valign=top>
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
<input type=hidden name=oldinvtotal value=$form->{oldinvtotal}>
<input type=hidden name=oldtotalpaid value=$totalpaid>
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

<br>
|;
#kabai    
    my $shipval;
    for my $invacc (1 .. $form->{rowcount}) { #only services?
      $invacc_yes = 1 if ($form->{"inventory_accno_$invacc"} || $form->{"assembly_$invacc"});
      $shipval = 1 if $form->{"ship_$invacc"}; #if already shipped
    }
    $invacc_yes = 0 if $shipval;  
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
  if (! $form->{readonly}) {
    print qq|
    <input class=submit type=submit name=action value="|.$locale->text('Update').qq|">

    |;
#kabai     <input class=submit type=submit name=action value="|.$locale->text('Ship to').qq|">

   if ((!$form->{promptshipreceive} || !$invacc_yes) || $form->{id} || $form->{type}=~ /_quotation$/){
	 print qq| <input class=submit type=submit name=action onclick="return checkform();" value="|.$locale->text('Save').qq|"> |;
#KS
     if ($form->{type} eq 'sales_order' or $form->{type} eq 'sales_quotation'){
       print qq|&nbsp;&nbsp;<b>|.$locale->text('Navigation').qq|</b>
       <select name=navigate><option value=1>|.$locale->text('Customer Basic Data').qq|
       <option value=2>|.$locale->text('Opened Sales '.(($form->{type} eq 'sales_order') ? 'Orders' : 'Quotations')).qq|
       <option value=3>|.$locale->text('Opened AR Transactions');
       if(!$form->{id} and $form->{oldid}){print qq|<option value=4 selected>|.$locale->text('Previous Transaction');}
       print qq|</select>&nbsp;<input class=submit type=submit name=action value="|.$locale->text('Jump').qq|">|;
	print qq|<br><br>
        <input class=submit type=submit name=action value="|.$locale->text('New Customer').qq|">
        |;
     }  
     if ($form->{type} eq 'purchase_order' or $form->{type} eq 'request_quotation'){
       print qq|&nbsp;&nbsp;<b>|.$locale->text('Navigation').qq|</b>
       <select name=navigate><option value=1>|.$locale->text('Vendor Basic Data').qq|
       <option value=2>|.$locale->text('Opened Purchase '.(($form->{type} eq 'sales_order') ? 'Orders' : 'Quotations')).qq|
       <option value=3>|.$locale->text('Opened AP Transactions');
       if(!$form->{id} and $form->{oldid}){print qq|<option value=4 selected>|.$locale->text('Previous Transaction');}
       print qq|</select>&nbsp;<input class=submit type=submit name=action value="|.$locale->text('Jump').qq|">
	<br><br> <input class=submit type=submit name=action value="|.$locale->text('New Vendor').qq|">|;
      }  
  }else{
          my $saveandshiprec = $form->{type} eq 'purchase_order' ? "Save And Receive" : "Save And Ship";
          print qq|
          &nbsp;&nbsp;&nbsp;&nbsp;$warehouse &nbsp;&nbsp;<input class=submit type=submit name=action onclick="alert('|.$locale->text('Click OK to continue').qq|');return checkform();" value="|.$locale->text($saveandshiprec).qq|">        
           |;
   }	
    if ($form->{id}) {
      print qq|
      <br><br>
      <input class=submit type=submit name=action onclick="return checkform();" value="|.$locale->text('Save as new').qq|">
      <input class=submit type=submit name=action value="|.$locale->text('E-mail').qq|">
      <input class=submit type=submit name=action value="|.$locale->text('Print').qq|">
      <input class=submit type=submit name=action value="|.$locale->text('Delete').qq|">
      |;
  
      if ($form->{type} eq 'sales_order') {
        if ($myconfig{acs} !~ /Quotations--RFQ/) {
	  print qq|
          <input class=submit type=submit name=action value="|.$locale->text('Quotation').qq|">
          |;
	}
      }
      
      if ($form->{type} eq 'purchase_order') {
	if ($myconfig{acs} !~ /Quotations--RFQ/) {
	  print qq|
          <input class=submit type=submit name=action value="|.$locale->text('RFQ').qq|">
          |;
	}
      }
      
      if ($form->{type} eq 'sales_quotation') {
	if ($myconfig{acs} !~ /Order Entry--Sales Order/) {
	  print qq|
          <input class=submit type=submit name=action value="|.$locale->text('Sales Order').qq|">
          |;
	}
      }
      
      if ($myconfig{acs} !~ /Order Entry--Purchase Order/) {
	if ($form->{type} eq 'request_quotation') {
	  print qq|
          <input class=submit type=submit name=action value="|.$locale->text('Purchase Order').qq|">
          |;
	}
      }
    
  

      if ($form->{type} =~ /sales_/) {
	if ($myconfig{acs} !~ /AR--Sales Invoice/) {
	  print qq|<br><br>
	<input class=submit type=submit name=action value="|.$locale->text('Sales Invoice').qq|">
	|;
	}
      } else {
	if ($myconfig{acs} !~ /AP--Vendor Invoice/) {
	  print qq|
        <input class=submit type=submit name=action value="|.$locale->text('Vendor Invoice').qq|">
        |;
	}
      }
    }#form->{id}
  } #readonly
  if ($form->{id} && $form->{type} !~ /quotation/){
    my $tip=$form->{type} eq "sales_order" ? "Sales" : "Purchase";      
    $tip="New ". $tip . " Order";
    print qq|
        <br><br>
        <input class=submit type=submit name=action value="|.$locale->text($tip).qq|">
        |;     
  }
  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }
$oeid= $form->{oeid} ? $form->{oeid} : $form->{id};
  print qq| 

<input type=hidden name=rowcount value=$form->{rowcount}>
<input name=callback type=hidden value=|.(($form->{oldcallback}) ? "$form->{oldcallback}" : "$form->{callback}").qq|>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input type=hidden name=oeid value=$oeid>

</form>

</body>
</html>
|;

}


sub update {
  $oldexchangerate = $form->{exchangerate};
  map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(exchangerate creditlimit creditremaining);
  $form->error($locale->text('Bad exchangerate format').": ".$oldexchangerate) if ($form->{exchangerate} > 1000 && $form->{currency} =~ /(USD|EUR)/);

  &check_name($form->{vc});


  $buysell = 'buy';
  $buysell = 'sell' if ($form->{vc} eq 'vendor');
  $form->{exchangerate} = $exchangerate if ($form->{forex} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}, $buysell)));
  
  my $i = $form->{rowcount};
  $exchangerate = ($form->{exchangerate}) ? $form->{exchangerate} : 1;

  foreach $item (qw(partsgroup projectnumber)) {
    $form->{"select$item"} = $form->unescape($form->{"select$item"}) if $form->{"select$item"};
  }

  if (($form->{"partnumber_$i"} eq "") && ($form->{"description_$i"} eq "") && ($form->{"partsgroup_$i"} eq "")) {

    #$form->{creditremaining} += ($form->{oldinvtotal} - $form->{oldtotalpaid});
    &check_form;
    
  } else {
 
    if ($form->{type} eq 'purchase_order' || $form->{type} eq 'request_quotation') {
      IR->retrieve_item(\%myconfig, \%$form);
    }
    if ($form->{type} eq 'sales_order' || $form->{type} eq 'sales_quotation') {
      IS->retrieve_item(\%myconfig, \%$form);
    }

    my $rows = scalar @{ $form->{item_list} };
    
    $form->{"discount_$i"} = $form->format_amount(\%myconfig, $form->{discount} * 100);

    if ($rows) {
      $form->{"qty_$i"}		= 1;
      if ($form->{type} !~ /_quotation/) {
	$form->{"reqdate_$i"}	= $form->{reqdate} unless $form->{"reqdate_$i"};
      }
      
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
	
	$amount = $form->{"sellprice_$i"} * $form->{"qty_$i"} * (1 - $form->{"discount_$i"} / 100);
	map { $form->{"${_}_base"} = 0 } (split / /, $form->{taxaccounts});
	map { $form->{"${_}_base"} += $amount } (split / /, $form->{"taxaccounts_$i"});
	map { $amount += ($form->{"${_}_base"} * $form->{"${_}_rate"}) } split / /, $form->{taxaccounts} if !$form->{taxincluded};
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
	
	$form->{"sellprice_$i"} = $form->format_amount(\%myconfig, $form->{"sellprice_$i"}, $decimalplaces);
	$form->{"qty_$i"} =  $form->format_amount(\%myconfig, $form->{"qty_$i"});
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
	$form->{"reqdate_$i"}	= $form->{reqdate} if $form->{type} !~ /_quotation/;

	&new_item;

      }
    }
  }

}



sub search {
  
  if ($form->{type} eq 'purchase_order') {
    $form->{title} = $locale->text('Purchase Orders');
    $form->{vc} = 'vendor';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Employee');
  }
  if ($form->{type} eq 'request_quotation') {
    $form->{title} = $locale->text('Request for Quotations');
    $form->{vc} = 'vendor';
    $ordlabel = $locale->text('RFQ Number');
    $ordnumber = 'quonumber';
    $employee = $locale->text('Employee');
  }
  if ($form->{type} eq 'receive_order') {
    $form->{title} = $locale->text('Receive Merchandise');
    $form->{vc} = 'vendor';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Employee');
  }
  if ($form->{type} eq 'sales_order') {
    $form->{title} = $locale->text('Sales Orders');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Salesperson');
  }
  if ($form->{type} eq 'ship_order') {
    $form->{title} = $locale->text('Ship Merchandise');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Order Number');
    $ordnumber = 'ordnumber';
    $employee = $locale->text('Salesperson');

  }
#pasztor
  if ($form->{type} eq 'trans_packing_list') {
    $form->{title} = $locale->text('Transfer Packing List');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Packing List Number');
    $ordnumber = 'szlnumber';
    $employee = $locale->text('Employee');
  }
  if ($form->{type} eq 'sales_quotation') {
    $form->{title} = $locale->text('Quotations');
    $form->{vc} = 'customer';
    $ordlabel = $locale->text('Quotation Number');
    $ordnumber = 'quonumber';
    $employee = $locale->text('Employee');
  }
#kabai
  

  if ($form->{type} =~ /(ship|receive)_order|trans_packing_list/) {
    OE->get_warehouses(\%myconfig, \%$form);
    CORE2->get_whded(\%myconfig, \%$form);
    # warehouse
    if (@{ $form->{all_warehouses} }) {
     $form->{selectwarehouse} = "<option>\n";
#kabai
      $form->{warehouse} = qq|$form->{warehouse}--$form->{warehouse_id}|;

      if ($form->{whded}) {
       map { $form->{selectwarehouse} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| if $_->{id} == $form->{whded}} (@{ $form->{all_warehouses} });
      }else{
       map { $form->{selectwarehouse} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| } (@{ $form->{all_warehouses} });
      }

    }else{
#     $form->{selectwarehouse} = "<option>\n";
     $form->{selectwarehouse} .= qq|<option value="0--0">- - - - - - - -\n|;
    
    }  
    $warehouse = qq|
	<tr>
	  <th align=right>|.$locale->text('Warehouse').qq|</th>
	  <td><select name=warehouse>$form->{selectwarehouse}</select></td>
	  <input type=hidden name=selectwarehouse value="|.
	  $form->escape($form->{selectwarehouse},1).qq|">
	</tr>
|; 
 #pasztor
   if ($form->{type} eq 'trans_packing_list') {
     $hovawarehouse = qq|
	<tr>
	  <th align=right>|.$locale->text('Warehouse (to)').qq|</th>
	  <td><select name=hhovawarehouse>$form->{selectwarehouse}</select></td>
	  <input type=hidden name=selectwarehouse value="|.
	  $form->escape($form->{selectwarehouse},1).qq|">
	</tr>
|;
     $honnanwareh=qq|
	<tr>
	  <td><input name="l_warehouse" class=checkbox type=checkbox value=Y checked>|.$locale->text('Warehouse (from)').qq|</td>
	  <td><input name="l_hovawarehouse" class=checkbox type=checkbox value=Y checked>|.$locale->text('Warehouse (to)').qq|</td>
	</tr>
|;
   }
  }

  # setup vendor / customer selection
  $form->all_vc(\%myconfig, $form->{vc}, ($form->{vc} eq 'customer') ? "AR" : "AP");

  map { $vc .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| } @{ $form->{"all_$form->{vc}"} };

  $vclabel = ucfirst $form->{vc};
  $vclabel = $locale->text($vclabel);
  
# $locale->text('Vendor')
# $locale->text('Customer')
  
  $vc = ($vc) ? qq|<select name=$form->{vc}><option>\n$vc</select>| : qq|<input name=$form->{vc} size=35>|;

  # departments  
  if (@{ $form->{all_departments} }) {
    $form->{selectdepartment} = "<option>\n";

    map { $form->{selectdepartment} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| } (@{ $form->{all_departments} });
  }

  $department = qq|  
        <tr>  
	  <th align=right nowrap>|.$locale->text('Department').qq|</th>
	  <td colspan=3><select name=department>$form->{selectdepartment}</select></td>
	</tr>
| if $form->{selectdepartment}; 

#pasztor
  $amount='';
  $shipvia='';
  if ($form->{type} eq 'trans_packing_list') {
     $vclabel = '';
     $vc      = '';
     $shipvia = qq|<td><input name="l_intnotes" class=checkbox type=checkbox value=Y> |.$locale->text('Internal Notes').qq|</td>
|;
  } else {
     $notestr = qq|
        <tr>
          <th align=right>|.$locale->text('Notes').qq|</th>
          <td colspan=3><input name=notes size=20></td>
        </tr>
|;
     $l_notestr = qq|<td><input name="l_notes" class=checkbox type=checkbox value=Y checked> |.$locale->text('Notes').qq|</td>
|;
     $shipvia = qq|<td><input name="l_shipvia" class=checkbox type=checkbox value=Y> |.$locale->text('Ship via').qq|</td>
|;
     $amount = qq|
	<tr>
	  <td><input name="l_netamount" class=checkbox type=checkbox value=Y> |.$locale->text('Amount').qq|</td>
	  <td><input name="l_tax" class=checkbox type=checkbox value=Y> |.$locale->text('Tax').qq|</td>
	  <td><input name="l_amount" class=checkbox type=checkbox value=Y checked> |.$locale->text('Total').qq|</td>
	  <td><input name="l_intnotes" class=checkbox type=checkbox value=Y> |.$locale->text('Internal Notes').qq|</td>
	</tr>
	<tr>
	  <td><input name="l_subtotal" class=checkbox type=checkbox value=Y> |.$locale->text('Subtotal').qq|</td>
	</tr>
|;
  }
  if ($form->{type} !~ /(ship_order|receive_order|trans_packing_list)/) {
    $openclosed = qq|
	      <tr>
	        <td><input name="open" class=checkbox type=checkbox value=1 checked> |.$locale->text('Open').qq|</td>
	        <td><input name="closed" class=checkbox type=checkbox value=1 $form->{closed}> |.$locale->text('Closed').qq|</td>
	      </tr>
|;
  } else {
    
     $openclosed = qq|
	        <input type=hidden name="open" value=1>
|;
  }

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

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
          <th align=right>$vclabel</th>
          <td colspan=3>$vc</td>
        </tr>
	$warehouse
        $hovawarehouse
	$department
        <tr>
          <th align=right>$ordlabel</th>
          <td colspan=3><input name="$ordnumber" size=20></td>
        </tr>
        $notestr
        <tr>
          <th align=right>|.$locale->text('Internal Notes').qq|</th>
          <td colspan=3><input name=intnotes size=20></td>
        </tr>
        <tr>
          <th align=right>|.$locale->text('From').qq|</th>
          <td><input name=transdatefrom size=11 title="$myconfig{dateformat}" id=transdatefrom OnBlur="return dattrans('transdatefrom');"></td>
          <th align=right>|.$locale->text('To').qq|</th>
          <td><input name=transdateto size=11 title="$myconfig{dateformat}" id=transdateto OnBlur="return dattrans('transdateto');"></td>
        </tr>
        <input type=hidden name=sort value=transdate>
        <tr>
          <th align=right>|.$locale->text('Include in Report').qq|</th>
          <td colspan=3>
	    <table>
	      $openclosed
	      <tr>
		<td><input name="l_id" class=checkbox type=checkbox value=Y>
		|.$locale->text('ID').qq|</td>
		<td><input name="l_$ordnumber" class=checkbox type=checkbox value=Y checked> $ordlabel</td>
		<td><input name="l_transdate" class=checkbox type=checkbox value=Y checked> |.$locale->text('Date').qq|</td>
		<td><input name="l_reqdate" class=checkbox type=checkbox value=Y checked> |.$locale->text('Required by').qq|</td>
	      </tr>
	      <tr>
	        <td><input name="l_name" class=checkbox type=checkbox value=Y checked> $vclabel</td>
	        <td><input name="l_employee" class=checkbox type=checkbox value=Y checked> $employee</td>
		$shipvia
		$l_notestr
	      </tr>
	      $amount
              $honnanwareh
	    </table>
          </td>
        </tr>
      </table>
    </td>
  </tr>
  <tr><td colspan=4><hr size=3 noshade></td></tr>
</table>

<br>
<input type=hidden name=nextsub value=transactions>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input type=hidden name=vc value=$form->{vc}>
<input type=hidden name=type value=$form->{type}>
<input type=hidden name=whded value=$form->{whded}>

<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub transactions {
  # split vendor / customer
  ($form->{$form->{vc}}, $form->{"$form->{vc}_id"}) = split(/--/, $form->{$form->{vc}});

#pasztor
  if ($form->{type} eq 'trans_packing_list') {
    $ordnumber =  'szlnumber' ;
    OE->tr_transactions(\%myconfig, \%$form);
  } else {
    $ordnumber = ($form->{type} =~ /_order/) ? 'ordnumber' : 'quonumber';
    OE->transactions(\%myconfig, \%$form);
  }
  
  

  $number = $form->escape($form->{$ordnumber});
#kabai
  $notes = $form->escape($form->{notes});
  $intnotes = $form->escape($form->{intnotes});
#kabai
  $name = $form->escape($form->{$form->{vc}});
  $department = $form->escape($form->{department});
  $warehouse = $form->escape($form->{warehouse});
  
  # construct href
  $href = qq|$form->{script}?direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&action=transactions&type=$form->{type}&vc=$form->{vc}&login=$form->{login}&sessionid=$form->{sessionid}&transdatefrom=$form->{transdatefrom}&transdateto=$form->{transdateto}&open=$form->{open}&closed=$form->{closed}&$ordnumber=$number&$form->{vc}=$name--$form->{"$form->{vc}_id"}&department=$department&warehouse=$warehouse&notes=$notes&intnotes=$intnotes|;

#pasztor
  if ($form->{type} eq 'trans_packing_list') {
    $href .= qq|&hhovawarehouse=$hhovawarehouse|;
  }
  # construct callback
  $number = $form->escape($form->{$ordnumber},1);
#kabai
  $notes = $form->escape($form->{notes},1);
  $intnotes = $form->escape($form->{intnotes},1);
#kabai
  $name = $form->escape($form->{$form->{vc}},1);
  $department = $form->escape($form->{department},1);
  $warehouse = $form->escape($form->{warehouse},1);

  # flip direction
  $form->sort_order();
    

  $callback = qq|$form->{script}?direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&action=transactions&type=$form->{type}&vc=$form->{vc}&login=$form->{login}&sessionid=$form->{sessionid}&transdatefrom=$form->{transdatefrom}&transdateto=$form->{transdateto}&open=$form->{open}&closed=$form->{closed}&$ordnumber=$number&$form->{vc}=$name--$form->{"$form->{vc}_id"}&department=$department&warehouse=$warehouse&notes=$notes&intnotes=$intnotes|;
#kabai
#pasztor
  if ($form->{type} eq 'trans_packing_list') {
    @columns = $form->sort_columns("transdate", "reqdate", "id", "$ordnumber", "employee", "notes", "intnotes", "warehouse","hovawarehouse");
  } else {
    @columns = $form->sort_columns("transdate", "reqdate", "id", "$ordnumber", "name", "netamount", "tax", "amount", "curr", "employee", "shipvia", "notes", "intnotes", "open", "closed");
  }


  $form->{l_open} = $form->{l_closed} = "Y" if ($form->{open} && $form->{closed}) ;

  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;
      
      # add column to href and callback
      $callback .= "&l_$item=Y";
      $href .= "&l_$item=Y";
    }
  }
  
  if ($form->{l_subtotal} eq 'Y') {
    $callback .= "&l_subtotal=Y";
    $href .= "&l_subtotal=Y";
  }
 
 
  $i = 1; 
  if ($form->{vc} eq 'vendor') {
    if ($form->{type} eq 'receive_order') {
      $form->{title} = $locale->text('Receive Merchandise');
    } elsif ($form->{type} eq 'purchase_order') {
      $form->{title} = $locale->text('Purchase Orders');

      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	$button{'Order Entry--Purchase Order'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Purchase Order').qq|"> |;
	$button{'Order Entry--Sales Order'}{order} = $i++;
      }

    } else {
      $form->{title} = $locale->text('Request for Quotations');

      if ($myconfig{acs} !~ /Quotations--Quotations/) {
	$button{'Quotations--RFQ'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('RFQ').qq| "> |;
	$button{'Quotations--RFQ'}{order} = $i++;
      }
      
    }
    $name = $locale->text('Vendor');
    $employee = $locale->text('Employee');
  }
  if ($form->{vc} eq 'customer') {
    if ($form->{type} eq 'sales_order') {
      $form->{title} = $locale->text('Sales Orders');
      $employee = $locale->text('Salesperson');

      if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
	$button{'Order Entry--Sales Order'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Sales Order').qq|"> |;
	$button{'Order Entry--Sales Order'}{order} = $i++;
      }

    } elsif ($form->{type} eq 'ship_order') {
      $form->{title} = $locale->text('Ship Merchandise');
      $employee = $locale->text('Salesperson');
#pasztor
    } elsif ($form->{type} eq 'trans_packing_list') {
      $form->{title} = $locale->text('Transfer Packing List');
      $employee = $locale->text('Salesperson');
    } else {
      $form->{title} = $locale->text('Quotations');
      $employee = $locale->text('Employee');

      if ($myconfig{acs} !~ /Quotations--Quotations/) {
	$button{'Quotations--Quotation'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Quotation').qq| "> |;
	$button{'Quotations--Quotation'}{order} = $i++;
      }
      
    }
    $name = $locale->text('Customer');
  }

  foreach $item (split /;/, $myconfig{acs}) {
    delete $button{$item};
  }
 
  $column_header{id} = qq|<th><a class=listheading href=$href&sort=id>|.$locale->text('ID').qq|</a></th>|;
  $column_header{transdate} = qq|<th><a class=listheading href=$href&sort=transdate>|.$locale->text('Date').qq|</a></th>|;
  $column_header{reqdate} = qq|<th><a class=listheading href=$href&sort=reqdate>|.$locale->text('Required by').qq|</a></th>|;
  $column_header{ordnumber} = qq|<th><a class=listheading href=$href&sort=ordnumber>|.$locale->text('Order').qq|</a></th>|;
  $column_header{szlnumber} = qq|<th><a class=listheading href=$href&sort=szlnumber>|.$locale->text('Packing List Number').qq|</a></th>|;
  $column_header{quonumber} = qq|<th><a class=listheading href=$href&sort=quonumber>|.$locale->text('Quotation').qq|</a></th>|;
  $column_header{name} = qq|<th><a class=listheading href=$href&sort=name>$name</a></th>|;
  $column_header{netamount} = qq|<th class=listheading>|.$locale->text('Amount').qq|</th>|;
  $column_header{tax} = qq|<th class=listheading>|.$locale->text('Tax').qq|</th>|;
  $column_header{amount} = qq|<th class=listheading>|.$locale->text('Total').qq|</th>|;
  $column_header{curr} = qq|<th class=listheading>|.$locale->text('Curr').qq|</th>|;
  $column_header{shipvia} = qq|<th><a class=listheading href=$href&sort=shipvia>|.$locale->text('Ship via').qq|</a></th>|;
#kabai
  $column_header{notes} = qq|<th><a class=listheading href=$href&sort=notes>|.$locale->text('Notes').qq|</a></th>|;
  $column_header{intnotes} = qq|<th><a class=listheading href=$href&sort=intnotes>|.$locale->text('Internal Notes').qq|</a></th>|;
#kabai
  $column_header{open} = qq|<th class=listheading>|.$locale->text('O').qq|</th>|;
  $column_header{closed} = qq|<th class=listheading>|.$locale->text('C').qq|</th>|;

  $column_header{employee} = qq|<th><a class=listheading href=$href&sort=employee>$employee</a></th>|;
#pasztor  Warehouse (from)
  $column_header{warehouse} = qq|<th><a class=listheading href=$href&sort=warehouse>|.$locale->text('Warehouse (from)').qq|</a></th>|;
  $column_header{hovawarehouse} = qq|<th><a class=listheading href=$href&sort=hovawarehouse>|.$locale->text('Warehouse (to)').qq|</a></th>|;

  
  if ($form->{$form->{vc}}) {
    $option = $locale->text(ucfirst $form->{vc});
    $option .= " : $form->{$form->{vc}}";
  }
#kabai
  if ($form->{notes}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Notes');
    $option .= " : $form->{notes}";
  }
  if ($form->{intnotes}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Internal Notes');
    $option .= " : $form->{intnotes}";
  }

#kabai
  if ($form->{warehouse}) {
    ($warehouse) = split /--/, $form->{warehouse};
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Warehouse');
    $option .= " : $warehouse";
  }
  if ($form->{department}) {
    $option .= "\n<br>" if ($option);
    ($department) = split /--/, $form->{department};
    $option .= $locale->text('Department')." : $department";
  }
  if ($form->{transdatefrom}) {
    $option .= "\n<br>".$locale->text('From')." ".$locale->date(\%myconfig, $form->{transdatefrom}, 1);
  }
  if ($form->{transdateto}) {
    $option .= "\n<br>".$locale->text('To')." ".$locale->date(\%myconfig, $form->{transdateto}, 1);
  }
  if ($form->{open}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Open');
  }
  if ($form->{closed}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Closed');
  }
  
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
	<tr class=listheading>|;

map { print "\n$column_header{$_}" } @column_index;

print qq|
	</tr>
|;

  # add sort and escape callback
  $callback .= "&sort=$form->{sort}";
  $form->{callback} = $callback;
  $callback = $form->escape($callback);

  if (@{ $form->{OE} }) {
    $sameitem = $form->{OE}->[0]->{$form->{sort}};
  }

  $action = "edit";
  $action = "ship_receive" if ($form->{type} =~ /(ship|receive)_order|packing_list/);

  $warehouse = $form->escape($form->{warehouse});

  foreach $oe (@{ $form->{OE} }) {

    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $oe->{$form->{sort}}) {
	&subtotal;
	$sameitem = $oe->{$form->{sort}};
      }
    }
    
    map { $oe->{$_} *= $oe->{exchangerate} } (qw(netamount amount));
    
    $column_data{netamount} = "<td align=right>".$form->format_amount(\%myconfig, $oe->{netamount}, 2, "&nbsp;")."</td>";
    $column_data{tax} = "<td align=right>".$form->format_amount(\%myconfig, $oe->{amount} - $oe->{netamount}, 2, "&nbsp;")."</td>";
    $column_data{amount} = "<td align=right>".$form->format_amount(\%myconfig, $oe->{amount}, 2, "&nbsp;")."</td>";

    $totalnetamount += $oe->{netamount};
    $totalamount += $oe->{amount};

    $subtotalnetamount += $oe->{netamount};
    $subtotalamount += $oe->{amount};

    $column_data{id} = "<td>$oe->{id}</td>";
    $column_data{transdate} = "<td>$oe->{transdate}&nbsp;</td>";
    $column_data{reqdate} = "<td>$oe->{reqdate}&nbsp;</td>";

    $column_data{$ordnumber} = "<td><a href=oe.pl?path=$form->{path}&action=$action&type=$form->{type}&id=$oe->{id}&warehouse=$warehouse&vc=$form->{vc}&whded=$form->{whded}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$oe->{$ordnumber}</a></td>";

    $name = $form->escape($oe->{name});
    $column_data{name} = qq|<td><a href=$href&$form->{vc}=$name--$oe->{"$form->{vc}_id"}&sort=$form->{sort}>$oe->{name}</a></td>|;

    $column_data{employee} = "<td>$oe->{employee}&nbsp;</td>";
    $column_data{shipvia} = "<td>$oe->{shipvia}&nbsp;</td>";
#kabai
    $column_data{notes} = "<td>$oe->{notes}&nbsp;</td>";
    $column_data{intnotes} = "<td>$oe->{intnotes}&nbsp;</td>";
#pasztor
    $column_data{warehouse} = "<td>$oe->{warehouse}&nbsp;</td>";
    $column_data{hovawarehouse} = "<td>$oe->{hovawarehouse}&nbsp;</td>";

#kabai
    if ($oe->{closed}) {
      $column_data{closed} = "<td align=center>X</td>";
      $column_data{open} = "<td>&nbsp;</td>";
    } else {
      $column_data{closed} = "<td>&nbsp;</td>";
      $column_data{open} = "<td align=center>X</td>";
    }

    $i++; $i %= 2;
    print "
        <tr class=listrow$i>";
    
    map { print "\n$column_data{$_}" } @column_index;

    print qq|
	</tr>
|;

  }
  
  if ($form->{l_subtotal} eq 'Y') {
    &subtotal;
  }
  
  # print totals
  print qq|
        <tr class=listtotal>|;
  
  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
  
  $column_data{netamount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalnetamount, 2, "&nbsp;")."</th>";
  $column_data{tax} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount - $totalnetamount, 2, "&nbsp;")."</th>";
  $column_data{amount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount, 2, "&nbsp;")."</th>";

  map { print "\n$column_data{$_}" } @column_index;

 
  print qq|
        </tr>
      </td>
    </table>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<form method=post action=$form->{script}>

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=type value=$form->{type}>

<input type=hidden name=$form->{vc} value="$form->{$form->{vc}}">
<input type=hidden name="$form->{vc}_id" value=$form->{"$form->{vc}_id"}>
<input type=hidden name=vc value=$form->{vc}>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
|;

  if ($form->{type} !~ /(ship|receive)_order/) {
    foreach $item (sort { $a->{order} <=> $b->{order} } %button) {
      print $item->{code};
    }
  }

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



sub subtotal {

  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
  
  $column_data{netamount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalnetamount, 2, "&nbsp;")."</th>";
  $column_data{tax} = "<td class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalamount - $subtotalnetamount, 2, "&nbsp;")."</th>";
  $column_data{amount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalamount, 2, "&nbsp;")."</th>";

  $subtotalnetamount = 0;
  $subtotalamount = 0;

  print "
        <tr class=listsubtotal>
";
  
  map { print "\n$column_data{$_}" } @column_index;

  print qq|
        </tr>
|;

}


sub save {
  
  $form->close_oe(\%myconfig) if ($form->{id} ne $form->{oeid});
  if ($form->{type} =~ /_order$/) {
    $form->isblank("transdate", $locale->text('Order Date missing!'));
  } else {
    $form->isblank("transdate", $locale->text('Quotation Date missing!'));
  }
  
  $msg = ucfirst $form->{vc};
  $form->isblank($form->{vc}, $locale->text($msg . " missing!"));

# $locale->text('Customer missing!');
# $locale->text('Vendor missing!');
  
  $form->isblank("exchangerate", $locale->text('Exchangerate missing!')) if ($form->{currency} ne $form->{defaultcurrency});
  
  &validate_items;

  # if the name changed get new values
  if (&check_name($form->{vc})) {
    &update;
    exit;
  }


  # this is for the internal notes section for the [email] Subject
  if ($form->{type} =~ /_order$/) {
    if ($form->{type} eq 'sales_order') {
      $form->{label} = $locale->text('Sales Order');

      $numberfld = "sonumber";
      $ordnumber = "ordnumber";
    } else {
      $form->{label} = $locale->text('Purchase Order');
      
      $numberfld = "ponumber";
      $ordnumber = "ordnumber";
    }

    $err = $locale->text('Cannot save order!');
    
  } else {
    if ($form->{type} eq 'sales_quotation') {
      $form->{label} = $locale->text('Quotation');
      
      $numberfld = "sqnumber";
      $ordnumber = "quonumber";
    } else {
      $form->{label} = $locale->text('Request for Quotation');

      $numberfld = "rfqnumber";
      $ordnumber = "quonumber";
    }
      
    $err = $locale->text('Cannot save quotation!');
 
  }

  
  $form->{id} = 0 if $form->{saveasnew};
 
  $form->{$ordnumber} = $form->update_defaults(\%myconfig, $numberfld) unless $form->{$ordnumber};
#kabai
  $form->isblank($ordnumber, $locale->text('Order Number missing!'))   if ($form->{type} =~ /_order$/) ;
  $form->isblank($ordnumber, $locale->text('Quotation Number missing!'))   if ($form->{type} =~ /_quotation$/) ;
#kabai
  if (OE->save(\%myconfig, \%$form)){
#KS
    $form->{callback}.="&oldid=$form->{id}" if ($form->{callback});
    $form->redirect if !$redirectsign_oe;
  }else{
   $form->error($err);
  }  
}



sub delete {

  $form->header;

  if ($form->{type} =~ /_order$/) {
    $msg = $locale->text('Are you sure you want to delete Order Number');
    $ordnumber = 'ordnumber';
  } else {
    $msg = $locale->text('Are you sure you want to delete Quotation Number');
    $ordnumber = 'quonumber';
  }
  
  print qq|
<body>

<form method=post action=$form->{script}>
|;

  # delete action variable
  map { delete $form->{$_} } qw(action header);

  $form->hide_form();

  print qq|
<h2 class=confirm>|.$locale->text('Confirm!').qq|</h2>

<h4>$msg $form->{$ordnumber}</h4>
<p>
<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>

</body>
</html>
|;


}



sub yes {

  if ($form->{type} =~ /_order$/) {
    $msg = $locale->text('Order deleted!');
    $err = $locale->text('Cannot delete order!');
  } else {
    $msg = $locale->text('Quotation deleted!');
    $err = $locale->text('Cannot delete quotation!');
  }
    
  $form->redirect($msg) if (OE->delete(\%myconfig, \%$form, $spool));
  $form->error($err);

}


sub vendor_invoice { &invoice };
sub sales_invoice { &invoice };

sub invoice {
$form->{invoice_zar}="1";
  if ($form->{type} =~ /_order$/) {
    $form->isblank("ordnumber", $locale->text('Order Number missing!'));
    $form->isblank("transdate", $locale->text('Order Date missing!'));

  } else {
    $form->isblank("quonumber", $locale->text('Quotation Number missing!'));
    $form->isblank("transdate", $locale->text('Quotation Date missing!'));
    $form->{ordnumber} = "";
  }

  # if the name changed get new values
  if (&check_name($form->{vc})) {
    &update;
    exit;
  }

  if ($form->{type} =~ /_order/ && $form->{currency} ne $form->{defaultcurrency}) {
    # check if we need a new exchangerate
    $buysell = ($form->{type} eq 'sales_order') ? "buy" : "sell";
#kabai    
    #$orddate = $form->current_date(\%myconfig);
    $orddate = $form->{transdate};;
#kabai
    $exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $orddate, $buysell);

    if (!$exchangerate) {
      &backorder_exchangerate($orddate, $buysell);
      exit;
    }
  }
  my $oldshipvia = $form->{shipvia};


  #$form->{transdate} = $form->current_date(\%myconfig);
  $form->{duedate} = $form->current_date(\%myconfig, $form->{transdate}, $form->{terms} * 1);
 
  $form->{id} = '';
  $form->{closed} = 0;
  $form->{rowcount}--;
  $form->{shipto} = 1;

 
  if ($form->{type} =~ /_order$/) {
    $form->{exchangerate} = $exchangerate;
    &create_backorder;
  }


  if ($form->{type} eq 'purchase_order' || $form->{type} eq 'request_quotation') {
    $form->{title} = $locale->text('Add Vendor Invoice');
    $form->{script} = 'ir.pl';
    $script = "ir";
    $buysell = 'sell';
  }
  if ($form->{type} eq 'sales_order' || $form->{type} eq 'sales_quotation') {
    $form->{title} = $locale->text('Add Sales Invoice');
    $form->{script} = 'is.pl';
    $script = "is";
    $buysell = 'buy';
  }
 
  map { delete $form->{$_} } qw(id subject message cc bcc printed emailed queued);
  $form->{$form->{vc}} =~ s/--.*//g;
  $form->{type} = "invoice";
 
  # locale messages
  $locale = new Locale "$myconfig{countrycode}", "$script";

  require "$form->{path}/$form->{script}";

  map { $form->{"select$_"} = "" } ($form->{vc}, currency);

  map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(creditlimit creditremaining);

  map { $temp{$_} = $form->{$_} } qw(currency employee department notes intnotes);

  &invoice_links;

  $form->{exchangerate} = "";
  $form->{forex} = "";
  $form->{exchangerate} = $exchangerate if ($form->{forex} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}, $buysell)));

  $form->{shipvia} = $oldshipvia;
  $form->{creditremaining} -= ($form->{oldinvtotal} - $form->{ordtotal});

  &prepare_invoice;
  
  map { $form->{$_} = $temp{$_} } keys %temp;

  for $i (1 .. $form->{rowcount}) {

#kabai
    $form->{inwh}=1 if $form->{"ship_$i"};
    delete $form->{"ship_$i"};
#kabai
    $form->{"deliverydate_$i"} = $form->{"reqdate_$i"};
    map { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}) } qw(discount);
  }

  map { delete $form->{$_} } qw(id subject message cc bcc printed emailed queued audittrail);
  $form->{selectordnumber} ="";
  $form->{oddordnumber} = $form->{ordnumber};
  &display_form;

}



sub backorder_exchangerate {
  my ($orddate, $buysell) = @_;

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  # delete action variable
  map { delete $form->{$_} } qw(action header exchangerate);

  $form->hide_form();

  $form->{title} = $locale->text('Add Exchange Rate');
  
  print qq|

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input type=hidden name=exchangeratedate value=$orddate>
<input type=hidden name=buysell value=$buysell>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right>|.$locale->text('Currency').qq|</th>
	  <td>$form->{currency}</td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Date').qq|</th>
	  <td>$orddate</td>
	</tr>
        <tr>
	  <th align=right>|.$locale->text('Exchange Rate').qq|</th>
	  <td><input name=exchangerate size=11></td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<br>
<input type=hidden name=nextsub value=save_exchangerate>

<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">

</form>

</body>
</html>
|;


}


sub save_exchangerate {

  $form->isblank("exchangerate", $locale->text('Exchangerate missing!'));
  $form->{exchangerate} = $form->parse_amount(\%myconfig, $form->{exchangerate});
  $form->save_exchangerate(\%myconfig, $form->{currency}, $form->{exchangeratedate}, $form->{exchangerate}, $form->{buysell});
  
  &invoice;

}


sub create_backorder {

  $form->{shipped} = 1;
 
  # figure out if we need to create a backorder
  # items aren't saved if qty != 0

  $dec1 = $dec2 = 0;
  for $i (1 .. $form->{rowcount}) {
     
   if ($form->{"inventory_accno_$i"}){
 
    ($dec) = ($form->{"qty_$i"} =~ /\.(\d+)/);
    $dec = length $dec;
    $dec1 = ($dec > $dec1) ? $dec : $dec1;
    
    ($dec) = ($form->{"ship_$i"} =~ /\.(\d+)/);
    $dec = length $dec;
    $dec2 = ($dec > $dec2) ? $dec : $dec2;
    
    $totalqty += $qty = $form->parse_amount(\%myconfig, $form->{"qty_$i"});
    $totalship += $ship = $form->parse_amount(\%myconfig, $form->{"ship_$i"});

    $form->{"qty_$i"} = $form->format_amount(\%myconfig, $qty - $ship);
   }else{
    $form->{"ship_$i"} = $form->{"qty_$i"};
   }
  }
 
  $totalqty = $form->round_amount($totalqty, $dec1);
  $totalship = $form->round_amount($totalship, $dec2);

  if ($totalship == 0) {
    map { $form->{"ship_$_"} = $form->{"qty_$_"} } (1 .. $form->{rowcount});
    $form->{ordtotal} = 0;
    $form->{shipped} = 0;
    return;
  }

  if ($totalqty == $totalship) {
    map { $form->{"qty_$_"} = $form->{"ship_$_"} } (1 .. $form->{rowcount});
    $form->{ordtotal} = 0;
    return;
  }

  @flds = qw(partnumber sku description qty oldqty ship unit sellprice discount id inventory_accno bin income_accno expense_accno listprice assembly taxaccounts partsgroup reqdate pricematrix);

  for $i (1 .. $form->{rowcount}) {
    $form->{"oldship_$i"} = $form->parse_amount(\%myconfig,$form->{"ship_$i"});
    $form->{"ship_$i"} = 0;
    $form->{"qty_$i"} = 0 if !$form->{"inventory_accno_$i"};
    delete $form->{"orderitems_id_$i"};
  }

  # clear flags
  map { delete $form->{$_} } qw(id subject message cc bcc printed emailed queued audittrail);
 
  my $oldordnumber = $form->{ordnumber};
  $form->{ordnumber} .= "BO";

  OE->save(\%myconfig, \%$form);

  $form->{ordnumber} = $oldordnumber;
  # rebuild rows for invoice
  @a = ();
  $count = 0;

  for $i (1 .. $form->{rowcount}) {
    $form->{"qty_$i"} = $form->{"oldship_$i"};
    $form->{"oldqty_$i"} = $form->{"qty_$i"};
    #$form->{"discount_$i"} *= 100;
    map { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}) } qw(qty sellprice discount);
    
    if ($form->{"qty_$i"}) {
      push @a, {};
      $j = $#a;
      map { $a[$j]->{$_} = $form->{"${_}_$i"} } @flds;
      $count++;
    }
  }

  $form->redo_rows(\@flds, \@a, $count, $form->{rowcount});
  $form->{rowcount} = $count;
  
}



sub save_as_new {

  $form->{saveasnew} = 1;
  $form->{closed} = 0;
# ==>> INBUSS
# BUGFIX: Egy meglévõ ajánlatra/rendelésre kattintva és új ajánlatként/rendelésként elmentve, az ajánlat/rendelés nem kap új Ajánlati/Rendelési számot, hanem ugyanazzal kerül elmentésre.
#  map { delete $form->{$_} } qw(printed emailed queued);
  map { delete $form->{$_} } qw(printed emailed queued quonumber ordnumber);
# <<== INBUSS
  &save;

}


sub ship_receive {

  &order_links;
  &prepare_order;

#pasztor
  if ($form->{type} ne 'trans_packing_list') {

    OE->get_warehouses(\%myconfig, \%$form);

    # warehouse

#kabai
    if (@{ $form->{all_warehouses} }) {
      $form->{selectwarehouse} = "<option>\n";
#kabai
      if ($form->{whded}) {
        map { $form->{selectwarehouse} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| if $_->{id} == $form->{whded}} (@{ $form->{all_warehouses} });
      }else{
        map { $form->{selectwarehouse} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| } (@{ $form->{all_warehouses} });
      }
#kabai
    }else{
      $form->{selectwarehouse} .= qq|<option value="0--0">- - - - - - - -\n|;
    }
  }

  $form->{shippingdate} = $form->current_date(\%myconfig);
  $form->{"$form->{vc}"} =~ s/--.*//;
  $form->{"old$form->{vc}"} = qq|$form->{"$form->{vc}"}--$form->{"$form->{vc}_id"}|;
  
#pasztor
  if ($form->{type} ne 'trans_packing_list') {
    @flds = ();
    @a = ();
    $count = 0;
    foreach $key (keys %$form) {
      if ($key =~ /_1$/) {
        $key =~ s/_1//;
        push @flds, $key;
      }
    }
  
    for $i (1 .. $form->{rowcount}) {
      # undo formatting from prepare_order
      map { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) } qw(qty ship);
    
      $n = ($form->{"qty_$i"} -= $form->{"ship_$i"});

      if (abs($n) > 0 && ($form->{"inventory_accno_$i"} || $form->{"assembly_$i"})) {
        $form->{"ship_$i"} = "";
        $form->{"serialnumber_$i"} = "";

        push @a, {};
        $j = $#a;

        map { $a[$j]->{$_} = $form->{"${_}_$i"} } @flds;
        $count++;
      }
    }
  
    $form->redo_rows(\@flds, \@a, $count, $form->{rowcount});
    $form->{rowcount} = $count;
  }
  &display_ship_receive;
  
}


sub display_ship_receive {

  $vclabel = ucfirst $form->{vc};
  $vclabel = $locale->text($vclabel);

  $form->{rowcount}++;
  if ($form->{vc} eq 'customer') {
    $form->{title} = $locale->text('Ship Merchandise');
    $shipped = $locale->text('Shipping Date');
  } else {
    $form->{title} = $locale->text('Receive Merchandise');
    $shipped = $locale->text('Date Received');
  }
#pasztor
  if ($form->{type} eq 'trans_packing_list') {
    $form->{title} = $locale->text('Transfer Packing List');
    $shipped = $locale->text('Shipping Date');
  }

  # set option selected
  foreach $item (warehouse, employee) {
    $form->{"select$item"} = $form->unescape($form->{"select$item"});
    $form->{"select$item"} =~ s/ selected//;
    $form->{"select$item"} =~ s/(<option value="\Q$form->{$item}\E")/$1 selected/;
  }

#pasztor
  if ($form->{type} eq 'trans_packing_list') {
   $warehouse = qq|
	      <tr>
		<th align=right>|.$locale->text('Warehouse (from)').qq|</th>
		<td>
		  <input type=hidden name=warehousefrom value="$form->{warehousefrom}">$form->{warehousefrom}
		</td>
		</tr>
		  <th align=right>|.$locale->text('Warehouse (to)').qq|</th>
		  <td>
		    <input type=hidden name=warehouse value="$form->{warehouse}">$form->{warehouse}
		  </td>
	        <tr>|;
  ($employee) = split(/--/, $form->{employee});
   $employee = qq|
 	      <tr>
	        <th align=right nowrap>|.$locale->text('Contact').qq|</th>
		<td>$employee</td>
		<input type=hidden name=employee value="$form->{employee}">
	      </tr>|;
   $form->{shippingdate}=$form->{reqdate};
   $ord = qq|
              <tr>
		<th align=right nowrap>|.$locale->text('Packing List Number').qq|</th>
		<td>$form->{szlnumber}</td>
		<input type=hidden name=szlnumber value="$form->{szlnumber}">
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Packing List Date').qq|</th>
		<td>$form->{transdate}</td>
		<input type=hidden name=transdate value=$form->{transdate}>
	      </tr>
              <tr>
		<th align=right nowrap>$shipped</th>
		<td>$form->{shippingdate}</td>
		<td><input type=hidden  name=shippingdate value=$form->{shippingdate}></td>
                <td><input type=hidden  name=reqdate value=$form->{reqdate}></td>
	      </tr>|;
  } else { 
   $vctxt = qq|
	      <tr>
		<th align=right>$vclabel</th>
		<td colspan=3>$form->{$form->{vc}}</td>
		<input type=hidden name=$form->{vc} value="$form->{$form->{vc}}">
		<input type=hidden name="$form->{vc}_id" value=$form->{"$form->{vc}_id"}>
	      </tr>|;
   $warehouse = qq|
	      <tr>
		<th align=right>|.$locale->text('Warehouse').qq|</th>
		<td><select name=warehouse>$form->{selectwarehouse}</select></td>
		<input type=hidden name=selectwarehouse value="|.
		$form->escape($form->{selectwarehouse},1).qq|">
	      </tr>
| if $form->{selectwarehouse};
#pasztor
   $shipvia = qq|
	      <tr>
		<th align=right>|.$locale->text('Shipping Point').qq|</th>
		<td colspan=3>
		<input name=shippingpoint size=35 value="$form->{shippingpoint}">
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Ship via').qq|</th>
		<td colspan=3>
		<input name=shipvia size=35 value="$form->{shipvia}">
	      </tr>|;
   $employee = qq|
 	      <tr>
	        <th align=right nowrap>|.$locale->text('Contact').qq|</th>
		<td><select name=employee>$form->{selectemployee}</select></td>
		<input type=hidden name=selectemployee value="|.
		$form->escape($form->{selectemployee},1).qq|">
	      </tr>|;
   $ord = qq|
              <tr>
		<th align=right nowrap>|.$locale->text('Order Number').qq|</th>
		<td>$form->{ordnumber}</td>
		<input type=hidden name=ordnumber value="$form->{ordnumber}">
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Order Date').qq|</th>
		<td>$form->{transdate}</td>
		<input type=hidden name=transdate value=$form->{transdate}>
	      </tr>
              <tr>
		<th align=right nowrap>$shipped</th>
		<td><input name=shippingdate size=11 value=$form->{shippingdate}></td>
	      </tr>|;
  }


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

<input type=hidden name=id value=$form->{id}>

<input type=hidden name=display_form value=display_ship_receive>

<input type=hidden name=type value=$form->{type}>
<input type=hidden name=media value=$form->{media}>
<input type=hidden name=format value=$form->{format}>

<input type=hidden name=queued value="$form->{queued}">
<input type=hidden name=printed value="$form->{printed}">
<input type=hidden name=emailed value="$form->{emailed}">

<input type=hidden name=vc value=$form->{vc}>
<input type=hidden name="old$form->{vc}" value="$form->{"old$form->{vc}"}">

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width="100%">
        <tr valign=top>
	  <td>
	    <table width=100%>
	      $vctxt
	      $department
	      $shipvia
	      $warehouse
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $employee
	      $ord
	    </table>
	  </td>
	</tr>
      </table>
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

|;

  if ($form->{type} eq "ship_order") {
   print qq| <input type=hidden name=notes value="|.$locale->text('SHIP').qq|">|;
  }else{
   print qq| <input type=hidden name=notes value="|.$locale->text('RECEIVE').qq|">|;
  } 

  @column_index = qw(partnumber);
  
  if ($form->{type} eq "ship_order") {
    $column_data{ship} = qq|<th class=listheading>|.$locale->text('Ship').qq|</th>|;
  }
  if ($form->{type} eq 'trans_packing_list') {
    $column_data{ship} = qq|<th class=listheading>|.$locale->text('Qty').qq|</th>|;
  }
  if ($form->{type} eq "receive_order") {
      $column_data{ship} = qq|<th class=listheading>|.$locale->text('Recd').qq|</th>|;
      $column_data{sku} = qq|<th class=listheading>|.$locale->text('SKU').qq|</th>|;
      push @column_index, "sku";
  }
#pasztor
  if ($form->{type} eq 'trans_packing_list') {
    push @column_index, qw(description ship unit);
  } else {
    push @column_index, qw(description qty ship unit bin serialnumber);
  }

  my $colspan = $#column_index + 1;
 
  $column_data{partnumber} = qq|<th class=listheading nowrap>|.$locale->text('Number').qq|</th>|;
  $column_data{description} = qq|<th class=listheading nowrap>|.$locale->text('Description').qq|</th>|;
  $column_data{qty} = qq|<th class=listheading nowrap>|.$locale->text('Qty').qq|</th>|;
  $column_data{unit} = qq|<th class=listheading nowrap>|.$locale->text('Unit').qq|</th>|;
  $column_data{bin} = qq|<th class=listheading nowrap>|.$locale->text('Bin').qq|</th>|;
  $column_data{serialnumber} = qq|<th class=listheading nowrap>|.$locale->text('Serial No.').qq|</th>|;
  
  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  map { print "\n$column_data{$_}" } @column_index;

  print qq|
        </tr>
|;

  for $i (1 .. $form->{rowcount} - 1) {
    
    # undo formatting
    $form->{"ship_$i"} = $form->parse_amount(\%myconfig, $form->{"ship_$i"});

    map { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) } qw(partnumber sku description unit bin serialnumber);

    $description = $form->{"description_$i"};
    $description =~ s//<br>/g;
    
    $column_data{partnumber} = qq|<td>$form->{"partnumber_$i"}<input type=hidden name="partnumber_$i" value="$form->{"partnumber_$i"}"></td>|;
    $column_data{sku} = qq|<td>$form->{"sku_$i"}<input type=hidden name="sku_$i" value="$form->{"sku_$i"}"></td>|;
    $column_data{description} = qq|<td>$description<input type=hidden name="description_$i" value="$form->{"description_$i"}"></td>|;
    $column_data{qty} = qq|<td align=right>|.$form->format_amount(\%myconfig, $form->{"qty_$i"}).qq|<input type=hidden name="qty_$i" value="$form->{"qty_$i"}"></td>|;
#pasztor
    if ($form->{type} ne 'trans_packing_list') {
      $column_data{ship} = qq|<td align=right><input name="ship_$i" size=5 value=|.$form->format_amount(\%myconfig, $form->{"ship_$i"}).qq|></td>|;
    } else {
      $column_data{ship} = qq|<td align=right>|.$form->format_amount(\%myconfig, $form->{"ship_$i"}).qq|<input  type=hidden name="ship_$i" size=5 value=|.$form->format_amount(\%myconfig, $form->{"ship_$i"}).qq|>
<input  type=hidden name="qty_$i" size=5 value=|.$form->format_amount(\%myconfig, $form->{"ship_$i"}).qq|></td>|; 
    }
    $column_data{unit} = qq|<td>$form->{"unit_$i"}<input type=hidden name="unit_$i" value="$form->{"unit_$i"}"></td>|;
    $column_data{bin} = qq|<td>$form->{"bin_$i"}<input type=hidden name="bin_$i" value="$form->{"bin_$i"}"></td>|;
    $column_data{serialnumber} = qq|<td><input name="serialnumber_$i" size=15 value="$form->{"serialnumber_$i"}"></td>|;

    print qq|
        <tr valign=top>|;

    map { print "\n$column_data{$_}" } @column_index;
  
    print qq|
        </tr>

<input type=hidden name="orderitems_id_$i" value=$form->{"orderitems_id_$i"}>
<input type=hidden name="id_$i" value=$form->{"id_$i"}>
<input type=hidden name="assembly_$i" value="$form->{"assembly_$i"}">
<input type=hidden name="partsgroup_$i" value="$form->{"partsgroup_$i"}">
<input type=hidden name="inventory_accno_$i" value="$form->{"inventory_accno_$i"}">
|;

  }

#pasztor
  if ($form->{type} eq 'trans_packing_list') {
    if (($rows = $form->numtextrows($form->{intnotes}, 30, 8)) < 2) {
      $rows = 2;
    }
    $intnotes = qq|<textarea name=intnotes rows=$rows cols=35 wrap=soft>$form->{intnotes}</textarea>|;
    $note = qq|
      <tr>
	<table>
	      <tr>
		<th align=left>|.$locale->text('Notes').qq|</th>
	      </tr>
	      <tr valign=top>
		<td>$intnotes</td>
	      </tr>
	      $hiba
	</table>
      </tr>|;
  }
  print qq|
      </table>
    </td>
  </tr>
  $note
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
  <tr>
    <td>
|;

  $form->{copies} = 1;
  
  &print_options;

  print qq|
    </td>
  </tr>
</table>
<br>
|;
    print qq|
     <input class=submit type=submit name=action value="|.$locale->text('Update').qq|">
     <input class=submit type=submit name=action value="|.$locale->text('Print').qq|">
     |;
#pasztor
  if ($form->{type} ne 'trans_packing_list') {

     if ($form->{type} eq 'ship_order') {
     print qq|
       <input class=submit type=submit name=action value="|.$locale->text('Ship to').qq|">
       <input class=submit type=submit name=action value="|.$locale->text('E-mail').qq|">
     |;
    }

    print qq|

<input class=submit type=submit onClick="alert('|.$locale->text('Click OK to continue').qq|');" name=action value="|.$locale->text('Done').qq|">
<br><br>
<input type=button name=action onClick= "return tolt($form->{rowcount});" value="|.$locale->text('Fill all').qq|">
|;
}
  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
  
<input type=hidden name=rowcount value=$form->{rowcount}>

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

</form>

</body>
</html>
|;


}


sub done {
  $form->error($locale->text('Raktár nincs kiválasztva!')) unless $form->{warehouse};
  if ($form->{type} eq 'ship_order') {
    $form->isblank("shippingdate", $locale->text('Shipping Date missing!'));
  } else {
    $form->isblank("shippingdate", $locale->text('Date received missing!'));
  }
  
  $total = 0;
  map { $total += $form->{"ship_$_"} = $form->parse_amount(\%myconfig, $form->{"ship_$_"}) } (1 .. $form->{rowcount} - 1);
  
  $form->error($locale->text('Nothing entered!')) unless $total;
  
  $form->{nonegativestock_true} = $nonegativestock_true;
  if ($nonegativestock_true) {   
    for my $s (1..$form->{rowcount} -1 ){
     $form->{"reqship_$s"} = $form->{"ship_$s"};      
    }
   if (CORE2->check_inventory(\%myconfig, \%$form)==-1){
    my ($whname, $null) = split /--/, $form->{warehouse};
    $form->error($locale->text('No negative stock allowed for ').$form->{"partnumber_$form->{stockid}"}." (".$whname.": ".$form->{stockqty}." db)");
   } 
  }

  $form->redirect($locale->text('Inventory saved!')) if OE->save_inventory(\%myconfig, \%$form);
  $form->error($locale->text('Could not save!'));
}



sub rfq_ { &add };
sub quotation_ { &add };


sub redirect {
   
  $form->redirect; 
  $form->error($locale->text('Order processed!'));
        
}
sub save_and_ship {

  if (!$form->{partnumber_1}){
    &update;
    exit;
  }
  $form->error($locale->text('Raktár nincs kiválasztva!')) unless $form->{warehouse};
  $form->{shippingdate} = $form->{reqdate};
  $form->isblank("reqdate", $locale->text('Shipping Date missing!'));

  local $redirectsign_oe = 1;

  if ($nonegativestock_true) {   
    for my $s (1..$form->{rowcount} -1 ){
     $form->{"reqship_$s"} = $form->{"qty_$s"};      
    }
   if (CORE2->check_inventory(\%myconfig, \%$form)==-1){
    my ($whname, $null) = split /--/, $form->{warehouse};
    $form->error($locale->text('No negative stock allowed for ').$form->{"partnumber_$form->{stockid}"}." (".$whname.": ".$form->{stockqty}." db)");
   } 
  }
  
  &save;
  CORE2->get_ship(\%myconfig, \%$form);
  $form->{type} = 'ship_order';
  $buysell = 'buy';
  $form->{vc} = 'customer'; 
  ($form->{customer}) = split /--/, $form->{customer};
  
  my $dbh = $form->dbconnect(\%myconfig);
  ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  $dbh->disconnect;
  $form->{employee} = $form->{employee}."--".$form->{employee_id};
  $form->{notes} = $locale->text('SHIP')." ".$form->{notes};

 
  $form->redirect($locale->text('Inventory saved!')) if OE->save_inventory(\%myconfig, \%$form);
  $form->error($locale->text('Could not save!'));

}

sub save_and_receive {

  if (!$form->{partnumber_1}){
    &update;
    exit;
  }
  $form->error($locale->text('Raktár nincs kiválasztva!')) unless $form->{warehouse};
  $form->{shippingdate} = $form->{reqdate};
  $form->isblank("reqdate", $locale->text('Shipping Date missing!'));
  
  local $redirectsign_oe = 1;
  
  &save;
  CORE2->get_ship(\%myconfig, \%$form);
  $form->{type} = 'receive_order';
  $form->{vc} = 'vendor'; 
  ($form->{vendor}) = split /--/, $form->{vendor};


  my $dbh = $form->dbconnect(\%myconfig);
  ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  $dbh->disconnect;
  $form->{employee} = $form->{employee}."--".$form->{employee_id};
  $form->{notes} = $locale->text('RECEIVE')." ".$form->{notes};

  $form->redirect($locale->text('Inventory saved!')) if OE->save_inventory(\%myconfig, \%$form);
  $form->error($locale->text('Could not save!'));

}

sub jump{
if ($form->{vc} eq 'customer'){

  if ($form->{navigate}==1){
    $form->{oldcallback} = $form->escape($form->{callback},1);
    $form->{callback} ="oe.pl?action=edit&id=$form->{id}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&oldcallback=$form->{oldcallback}";
    $form->{callback} =$form->escape($form->{callback},1);
    $form->{callback}="ct.pl?action=edit&type=$form->{type}&id=$form->{customer_id}&db=customer&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}";
    $form->redirect;
  }
  if ($form->{navigate}==2){
    $callback="oe.pl?action=transactions&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&direction=DESC&oldsort=transdate&vc=customer&open=1&l_transdate=Y&l_reqdate=Y&l_ordnumber=Y&l_name=Y&l_amount=Y&l_employee=Y&l_notes=Y&sort=transdate&customer_id=$form->{customer_id}&customer=";
    $callback.=$form->escape($form->{customer});
    $form->{callback} = $callback;
    $form->redirect;
  }
  if ($form->{navigate}==3){
    $callback="ar.pl?action=ar_transactions&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&direction=DESC&oldsort=transdate&vc=$form->{vc}&open=Y&l_transdate=Y&l_invnumber=Y&l_name=Y&l_amount=Y&l_paid=Y&l_duedate=Y&l_notes=Y&sort=transdate&customer_id=$form->{customer_id}&customer=";
    $callback.=$form->escape($form->{customer});
    $form->{callback} = $callback;
    $form->redirect;
  }
  if ($form->{navigate}==4){
    $form->{oldcallback} = $form->escape($form->{callback},1);
    $form->{callback} ="oe.pl?action=edit&id=$form->{id}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&oldcallback=$form->{oldcallback}";
    $form->{callback} =$form->escape($form->{callback},1);
    $form->{callback} ="oe.pl?action=edit&id=$form->{oldid}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}";
    $form->redirect;
  }
 } 
 else {
 if ($form->{navigate}==1){
    $form->{oldcallback} = $form->escape($form->{callback},1);
    $form->{callback} ="oe.pl?action=edit&id=$form->{id}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&oldcallback=$form->{oldcallback}";
    $form->{callback} =$form->escape($form->{callback},1);
    $form->{callback}="ct.pl?action=edit&type=$form->{type}&id=$form->{vendor_id}&db=vendor&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}";
    $form->redirect;
  }
  if ($form->{navigate}==2){
    $callback="oe.pl?action=transactions&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&direction=DESC&oldsort=transdate&vc=vendor&open=1&l_transdate=Y&l_reqdate=Y&l_ordnumber=Y&l_name=Y&l_amount=Y&l_employee=Y&l_notes=Y&sort=transdate&vendor_id=$form->{vendor_id}&vendor=";
    $callback.=$form->escape($form->{vendor});
    $form->{callback} = $callback;
    $form->redirect;
  }
  if ($form->{navigate}==3){
    $callback="ap.pl?action=ap_transactions&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&direction=DESC&oldsort=transdate&vc=$form->{vc}&open=Y&l_transdate=Y&l_invnumber=Y&l_name=Y&l_amount=Y&l_paid=Y&l_duedate=Y&l_notes=Y&sort=transdate&vendor_id=$form->{vendor_id}&vendor=";
    $callback.=$form->escape($form->{vendor});
    $form->{callback} = $callback;
    $form->redirect;
  }
  if ($form->{navigate}==4){
    $form->{oldcallback} = $form->escape($form->{callback},1);
    $form->{callback} ="oe.pl?action=edit&id=$form->{id}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&oldcallback=$form->{oldcallback}";
    $form->{callback} =$form->escape($form->{callback},1);
    $form->{callback} ="oe.pl?action=edit&id=$form->{oldid}&type=$form->{type}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}";
    $form->redirect;
  }
  
 } 
}		

  	       	       		  
sub new_sales_order{
  delete $form->{id};
  delete $form->{ordnumber};
  delete $form->{oeid};
  $form->{rowcount}--;
  for my $i (1..$form->{rowcount}){
    delete $form->{"ship_$i"};
    delete $form->{"orderitems_id_$i"};
  }    
  &add;
}

sub new_purchase_order{
  delete $form->{id};
  delete $form->{ordnumber};
  delete $form->{oeid};
  $form->{rowcount}--;
  for my $i (1..$form->{rowcount}){
    delete $form->{"ship_$i"};
    delete $form->{"orderitems_id_$i"};
  }    
  &add;
}

#pasztor

sub search_transfer {
 
  $sumtransfer = 0;
  if (!$form->{rowcount}) {
    $form->{rowcount} = 0;

    OE->get_warehouses(\%myconfig, \%$form);

    # warehouse
    if (@{ $form->{all_warehouses} }) {
      $form->{warehouse} = qq|$form->{warehouse}--$form->{warehouse_id}|;
      map { $form->{selectwarehouse} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| } (@{ $form->{all_warehouses} });
    } else {
      $form->error($locale->text('Nothing to transfer!'));
    }
    $form->{transdate} = $form->current_date(\%myconfig);
    $form->{shipdate}  = $form->current_date(\%myconfig);


    $form->{title} = $locale->text('Transfer Inventory');
    $transf=qq|
        <tr>
          <th align=right nowrap>|.$locale->text('Transfer From').qq|</th>
          <td><select name=warehousefrom>$form->{selectwarehouse}</select></td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Transfer to').qq|</th>
          <td><select name=warehouse>$form->{selectwarehouse}</select></td>
        </tr>
	<tr>
          <th align=right nowrap>|.$locale->text('Shipping Date').qq|</th>
          <td><input name=shipdate size=11 title="$myconfig{dateformat}" value=$form->{shipdate}>
	  <input type=hidden name=transdate value=$form->{transdate}></td>
	</tr>|;
    $tovabb = '';
  } else {
    $form->{title} = $locale->text('Transfer Inventory (cont)');
    $transf=qq|
        <tr>
          <th align=right nowrap>|.$locale->text('Transfer From').qq|</th>
	  <td><input type=hidden name=warehousefrom value='$form->{warehousefrom}'>$form->{warehousefrom}</td>
        </tr>
        <tr>
          <th align=right nowrap>|.$locale->text('Transfer to').qq|</th>
          <td><input type=hidden name=warehouse value='$form->{warehouse}'>$form->{warehouse}</td></td>
        </tr>
	<tr>
          <th align=right nowrap>|.$locale->text('Shipping Date').qq|</th>
          <td><input type=hidden name=shipdate size=11 title="$myconfig{dateformat}" value='$form->{shipdate}'>
	  <input type=hidden name=transdate value='$form->{transdate}'>$form->{shipdate}</td>
	</tr>|;

    $tovabb = '';
    $j = 0;
    for ($i=1; $i<=$form->{rowcount}; $i++) {
      if ($form->{"transfer_$i"}) {
        $j++;
        $tovabb .= qq|
          <input type=hidden  name="id_$j"          value=$form->{"id_$i"}>
          <input type=hidden  name="qty_$j"         value=$form->{"qty_$i"}>
          <input type=hidden  name="transfer_$j"    value=$form->{"transfer_$i"}>
          <input type=hidden  name="partnumber_$j"  value="$form->{"partnumber_$i"}">
          <input type=hidden  name="description_$j" value="$form->{"description_$i"}">
          <input type=hidden  name="partsgroup_$j"  value="$form->{"partsgroup_$i"}">|;
        $sumtransfer += $form->{"transfer_$i"}
      }
    }
    $form->{rowcount} = $j;
  }

  $form->get_partsgroup(\%myconfig, { all => 0, searchitems => 'part'});
  if (@{ $form->{all_partsgroup} }) {
    $form->{selectpartsgroup} = "<option>\n";
    map { $form->{selectpartsgroup} .= qq|<option value="$_->{partsgroup}--$_->{id}">$_->{partsgroup}\n| } @{ $form->{all_partsgroup} };
  }

  $form->header;

  print qq|
<body Onload="document.myform1.partnumber.focus()">
<form name="myform1" method=post action=$form->{script}>
<table width=100%>
  <tr>
    <th colspan=2 class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        $transf
        $tovabb
	<tr>
	  <th align="right" nowrap="true">|.$locale->text('Part Number').qq|</th>
	  <td><input name=partnumber size=20></td>
	</tr>
	<tr>
	  <th align="right" nowrap="true">|.$locale->text('Description').qq|</th>
	  <td><input name=description size=40></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Group').qq|</th>
	  <td><select name=partsgroup>$form->{selectpartsgroup}</select></td>
	</tr>	
	<tr>
	  <th align=right>|.$locale->text('Notes').qq|</th>
          <td><textarea name=intnotes rows=3 cols=25 wrap=soft >$form->{intnotes}</textarea></td>
        </tr>
        <tr height="15"></tr>
        <tr>
	  <th align=left colspan=2 >$sumtransfer |.$locale->text('piece(s) of article are contained in this delivery note until now.').qq|</th>
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input type=hidden name=sort value=partnumber>
<input type=hidden name=nextsub value=list_transfer>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
<input type=hidden name=rowcount value=$form->{rowcount}>

<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub list_transfer {

  if ($form->{warehouse} eq $form->{warehousefrom}){
    $form->error($locale->text('It is not possible to transfer to the same warehouse!'));
  }

  OE->get_inventory(\%myconfig, \%$form);

  $partnumber = $form->escape($form->{partnumber});
  $warehouse = $form->escape($form->{warehouse});
  $description = $form->escape($form->{description});
  $partsgroup = $form->escape($form->{partsgroup});

  # construct href
  $href = "$form->{script}?path=$form->{path}&action=list_transfer&partnumber=$partnumber&warehouse=$warehouse&description=$description&partsgroup=$partsgroup&login=$form->{login}&sessionid=$form->{sessionid}";

  # construct callback
  $partnumber = $form->escape($form->{partnumber},1);
  $warehouse = $form->escape($form->{warehouse},1);
  $description = $form->escape($form->{description},1);
  $partsgroup = $form->escape($form->{partsgroup},1);

  $callback = "$form->{script}?path=$form->{path}&action=list_transfer&partnumber=$partnumber&warehouse=$warehouse&description=$description&partsgroup=$partsgroup&login=$form->{login}&sessionid=$form->{sessionid}";

  @column_index = $form->sort_columns(qw(partnumber description partsgroup qty transfer));

  $column_header{partnumber} = qq|<th><a class=listheading href=$href&sort=partnumber>|.$locale->text('Part Number').qq|</a></th>|;
  $column_header{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;
  $column_header{partsgroup} = qq|<th><a class=listheading href=$href&sort=partsgroup>|.$locale->text('Group').qq|</a></th>|;
  $column_header{qty} = qq|<th class=listheading>|.$locale->text('Qty').qq|</a></th>|;
  $column_header{transfer} = qq|<th class=listheading>|.$locale->text('Qty of Transfer').qq|</a></th>|;

  $option = $locale->text('Transfer to');
  ($warehouse, $warehouse_id) = split /--/, $form->{warehouse};
  if ($form->{warehouse}) {
    $option .= " : $warehouse";
  }

  $option .= "\n<br>" if ($option);
  $option .= $locale->text('Transfer From');
  ($warehousefrom, $warehousefrom_id) = split /--/, $form->{warehousefrom};

  if ($form->{warehousefrom}) {
    $option .= " : $warehousefrom";
  }
  if ($form->{partnumber}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Part Number')." : $form->{partnumber}";
  }
  if ($form->{description}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Description')." : $form->{description}";
  }
  if ($form->{partsgroup}) {
    ($partsgroup) = split /--/, $form->{partsgroup};
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Group')." : $partsgroup";
  }

  $form->{title} = $locale->text('Transfer Inventory');

  my $focusdbi=0;
  for ($i=1;$i<=$form->{rowcount}+1;$i++) {
    if (!$form->{"transfer_$i"}) {
      $focusdbi=$i;
      last;
    }
  }
  $form->header;
  print qq|

<body Onload="document.myform.transfer_$focusdbi.focus()">
<form name="myform" method=post action=$form->{script}>
<input type=hidden name=notes value="|.$locale->text('TRANSFER').qq|">
<input type=hidden name=warehouse_id value=$warehouse_id>
<input type=hidden name=warehousefrom_id value=$warehousefrom_id>
<input type=hidden name=warehouse value='$form->{warehouse}'>
<input type=hidden name=warehousefrom value='$form->{warehousefrom}'>
<input type=hidden name=transdate value=$form->{transdate}>
<input type=hidden name=shipdate value=$form->{shipdate}>
<input type=hidden name=intnotes value='$form->{intnotes}'>

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
	<tr class=listheading>|;

  map { print "\n$column_header{$_}" } @column_index;

  print qq|
	</tr>
|;


  $tovabb = '';
  $j = 0;
  for ($i=1; $i<=$form->{rowcount}; $i++) {
    if ($form->{"transfer_$i"}) {
      $j++;
      $tovabb .= qq|
          <input type=hidden  name="id_$j"  value=$form->{"id_$i"}>
          <input type=hidden  name="qty_$j"  value=$form->{"qty_$i"}>
          <input type=hidden  name="transfer_$j"  value=$form->{"transfer_$i"}>|;

      $column_data{partnumber} = qq|
        <td><input type=hidden name="id_$j" value="$form->{"id_$i"}">
            <input type=hidden name="partnumber_$j" value=$form->{"partnumber_$i"}>$form->{"partnumber_$i"}</td>|;
      $column_data{description} = qq|
        <td><input type=hidden name="description_$j" value="$form->{"description_$i"}"> $form->{"description_$i"} </td>|;
      $column_data{partsgroup} =  qq|
        <td><input type=hidden name="partsgroup_$j" value="$form->{"partsgroup_$i"}"> $form->{"partsgroup_$i"} </td>|;
      $column_data{qty} = qq|
        <td><input type=hidden name="qty_$j" value=$form->{"qty_$i"}>|.$form->format_amount(\%myconfig, $form->{"qty_$i"}).qq|</td>|;
      $column_data{transfer} = qq|
        <td><input  name="transfer_$j" size=4 value=$form->{"transfer_$i"}></td>|;
      $jj++; $jj %= 2;
      print "<tr class=listrow$jj>";
      map { print "\n$column_data{$_}" } @column_index;

      print qq|</tr>|;
    }
  }

# 2. rÄ‚Å sz, most adjuk be a transzfer db-ot
  $j = 0;
  $i = $form->{rowcount};
  foreach $ref (@{ $form->{all_inventory} }) {
    $mehet = 0;
    for ($ii=1; $ii<=$form->{rowcount}; $ii++) {
      if ($form->{"transfer_$ii"} and ($ref->{id} == $form->{"id_$ii"})) {
        $mehet = 1;
        last;
      }
    }
    if (!$mehet) {
      $i++;
      $column_data{partnumber} = qq|<td><input type=hidden name="id_$i" value=$ref->{id}>
           <input type=hidden name="partnumber_$i" value="$ref->{partnumber}"> $ref->{partnumber}</td>|;
      $column_data{description} = qq|<td><input type=hidden name="description_$i" value="$ref->{description}">$ref->{description}</td>|;
      $column_data{partsgroup} = qq|<td><input type=hidden name="partsgroup_$i" value="$ref->{partsgroup}">$ref->{partsgroup}</td>|;
      $column_data{qty} = qq|<td><input type=hidden name="qty_$i" value=$ref->{qty}>|.$form->format_amount(\%myconfig, $ref->{qty}).qq|</td>|;
      $column_data{transfer} = qq|<td><input name="transfer_$i" size=4 value=$form->{"transfer_$i"}></td>|;

      $j++; $j %= 2;
      print "<tr class=listrow$j>";

      map { print "\n$column_data{$_}" } @column_index;

      print qq|</tr>|;
    }

  }
  $form->{rowcount} += $i;

  print qq|
      </table>
    </td>
  </tr>

  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input name=callback type=hidden value="$callback">
<input type=hidden name=rowcount value=$form->{rowcount}>
<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
<input class=submit type=submit name=action value="|.$locale->text('Transfer OK cont').qq|">
<input class=submit type=submit name=action value="|.$locale->text('Transfer OK end').qq|">|;


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

#pasztor
sub transfer_ok_cont {
  &search_transfer;
}

#pasztor
sub transfer_ok_end {

  $form->isblank("transdate", $locale->text('Shipping Date missing!'));
  $form->isblank("shipdate", $locale->text('Shipping Date missing!'));

  $form->{szlnumber} = $form->update_defaults(\%myconfig, "transnumber");

  if (OE->save_transfer(\%myconfig, \%$form)) {
     if (OE->transfer(\%myconfig, \%$form)) {
        $form->{type} = "trans_packing_list";
        $form->{callback} = "$form->{script}?action=ship_receive&type=$form->{type}&vc=$form->{vc}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}&id=$form->{id}";
        $form->redirect($locale->text('Inventory saved!').' Transfer : '. $form->{szlnumber} );
     }
  }
  $form->error($locale->text('Could not transfer Inventory!'));

}
sub new_customer { #kabai
    $form->{callback} = $form->escape($form->{callback},1);
        $form->{callback} = "ct.pl?path=bin/mozilla&action=add&login=$form->{login}&sessionid=$form->{sessionid}&cash_invoice=$for->{cash_invoice}&callback=$form->{callback}&db=customer";
        $form->redirect;
    }
sub new_vendor { #kabai
    $form->{callback} = $form->escape($form->{callback},1);
        $form->{callback} = "ct.pl?path=bin/mozilla&action=add&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}&db=vendor&cash=$form->{cash}";
        $form->redirect;
    }
                        


1;
