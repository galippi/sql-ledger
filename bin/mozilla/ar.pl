#=====================================================================
# SQL-Ledger Accounting
# Copyright (c) 2000
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#  Modified by Tavugyvitel Kft. (info@tavugyvitel.hu)
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
# Accounts Receivable
#
#======================================================================


use SL::AR;
use SL::IS;
use SL::PE;
use SL::CP;


require "$form->{path}/arap.pl";
require "$form->{path}/rs.pl";
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


sub add {

  $form->{title} = "Add";
#kabai +1
  $form->{callback} = "$form->{script}?action=add&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&cash=$form->{cash}" unless $form->{callback};

  &create_links;
#kabai  &display_form;
  &update;
#kabai  
}


sub edit {

  $form->{title} = "Edit";

  &create_links;

  $form->{oddordnumber} = $form->{ordnumber};
  $form->{ordnumber} = "0";
  #&display_form;
  &update;
}


sub display_form {

  &form_header;
  &form_footer;

}


sub create_links {

  $form->{showaccnumbers_true} = $showaccnumbers_true;
  $form->create_links("AR", \%myconfig, "customer");
  $duedate = $form->{duedate};

  # currencies
  @curr = split /:/, $form->{currencies};
  chomp $curr[0];
  $form->{defaultcurrency} = $curr[0];

  map { $form->{selectcurrency} .= "<option>$_\n" } @curr;

  IS->get_customer(\%myconfig, \%$form);

  $form->{duedate} = $duedate if $duedate;
  $form->{notes} = $form->{intnotes} if !$form->{id};
  
  $form->{oldcustomer} = "$form->{customer}--$form->{customer_id}";
  $form->{oldtransdate} = $form->{transdate};

  # customers
  if (@{ $form->{all_customer} }) {
    $form->{customer} = "$form->{customer}--$form->{customer_id}";
    map { $form->{selectcustomer} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| } (@{ $form->{all_customer} });
  }

  # registered ordnumbers
  if (@{$form->{all_ordnumbers}}) {
    $form->{selectordnumber} = qq|<option value="0">| . $locale->text("odd number") . qq|</option>\n|;
    map { $form->{selectordnumber} .= qq|<option value="$_->{regnumber}">$_->{regnumber}</option>\n| } (@{$form->{all_ordnumbers}});
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
  
  # projects
  if (@{ $form->{all_projects} }) {
    $form->{selectprojectnumber} = "<option>\n";
    map { $form->{selectprojectnumber} .= qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n| } (@{ $form->{all_projects} });
  }

  # forex
  $form->{forex} = $form->{exchangerate};
  $exchangerate = ($form->{exchangerate}) ? $form->{exchangerate} : 1;

  foreach $key (keys %{ $form->{AR_links} }) {
       
    foreach $ref (@{ $form->{AR_links}{$key} }) {
      if ($key eq 'AR_tax') {
#kabai
        $refaccno = "$ref->{accno}--" if $showaccnumbers_true;
	$form->{"selectAR_tax_$ref->{accno}"} = "<option value=$ref->{accno}>$refaccno$ref->{description}\n";
#kabai
	$form->{"calctax_$ref->{accno}"} = 1;
#	next;
      }
#kabai      $form->{"select$key"} .= "<option>$ref->{accno}--$ref->{description}\n";
       if ($key eq "AR_paid" && !$form->{id}){
        $refaccno = "$ref->{accno}--" if $showaccnumbers_true; 
	if ($form->{cash}){
          $form->{"select$key"} .= "<option value=$ref->{accno}>$refaccno$ref->{description}\n" if $ref->{ptype} eq "pcash";
	}else{
          $form->{"select$key"} .= "<option value=$ref->{accno}>$refaccno$ref->{description}\n";	
        }
	next;
       }
       $refaccno = "$ref->{accno}--" if $showaccnumbers_true; 
       $form->{"select$key"} .= "<option value=$ref->{accno}>$refaccno$ref->{description}\n";
#kabai
    }
  
    # if there is a value we have an old entry
    for $i (1 .. scalar @{ $form->{acc_trans}{$key} }) {
      if ($key eq "AR_paid") {
	$form->{"AR_paid_$i"} = "$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";
	# reverse paid
	$form->{"paid_$i"} = $form->format_amount(\%myconfig,$form->{acc_trans}{$key}->[$i-1]->{amount} * -1);
	$form->{"datepaid_$i"} = $form->{acc_trans}{$key}->[$i-1]->{transdate};
	$form->{"source_$i"} = $form->{acc_trans}{$key}->[$i-1]->{source};
	$form->{"memo_$i"} = $form->{acc_trans}{$key}->[$i-1]->{memo};
#kabai +1	
	$form->{"forex_paid_$i"} = $form->{"exchangerate_paid_$i"} = $form->{acc_trans}{$key}->[$i-1]->{exchangerate};
	
	$form->{paidaccounts}++;
      } else {
     
	$akey = $key;
	$akey =~ s/AR_//;
	
        if ($key eq "AR_tax") {
	  $form->{"${key}_$form->{acc_trans}{$key}->[$i-1]->{accno}"} = "$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";
	  $form->{"${akey}_$form->{acc_trans}{$key}->[$i-1]->{accno}"} = $form->round_amount($form->{acc_trans}{$key}->[$i-1]->{amount} / $exchangerate, 2);
	} else {
	  $form->{"${akey}_$i"} = $form->round_amount($form->{acc_trans}{$key}->[$i-1]->{amount} / $exchangerate, 2);
	  if ($akey eq 'amount') {
	    $form->{rowcount}++;
	    $totalamount += $form->{"${akey}_$i"};

            $form->{"AR_base_$i"} = "$form->{acc_trans}{$key}->[$i-1]->{taxbase}";
            $form->{"projectnumber_$i"} = "$form->{acc_trans}{$key}->[$i-1]->{projectnumber}--$form->{acc_trans}{$key}->[$i-1]->{project_id}";
	  }
	  $form->{"${key}_$i"} = "$form->{acc_trans}{$key}->[$i-1]->{accno}--$form->{acc_trans}{$key}->[$i-1]->{description}";
	}
      }
    }
  }

  $form->{paidaccounts} = 1 if not defined $form->{paidaccounts};

  if ($form->{taxincluded} && $totalamount) {

  # add tax to amounts and invtotal
#calculated net equals to be stored?
     foreach $item (split / /, $form->{taxaccounts}) {
      if ($form->datetonum($form->{"${item}_validfrom"},\%myconfig) > $form->datetonum($form->{transdate}, \%myconfig)
         || $form->datetonum($form->{"${item}_validto"},\%myconfig) < $form->datetonum($form->{transdate}, \%myconfig))
      {
         next;
      }    

      if ($form->{"${item}_rate"} != 0) {
	my $taxbase;
        for $j (1 .. $form->{rowcount}){
	 if($form->{"AR_base_$j"}==$form->{"${item}_rate"}){
          $taxbase += $form->{"amount_$j"};
         }
	}
        $taxamount =(($taxbase + $form->{"tax_$item"}) - ($taxbase + $form->{"tax_$item"}) / (1 + $form->{"${item}_rate"}));
      }
      $taxamount = $form->round_amount($taxamount, 2);
      if ($form->{"tax_$item"} != $taxamount || $taxamount==0){
        $form->{"calctax_$item"} = 0;
	for $j (1 .. $form->{rowcount}){	
           if($form->{"AR_base_$j"}==$form->{"${item}_rate"}){
		$form->{"amount_$j"} += ($form->{"tax_$item"} - $taxamount);
		last;
	   }
	}
      }
      $form->{"tax_$item"} = $form->format_amount(\%myconfig,$form->{"tax_$item"});
      $taxamount = 0;
     }
#calculated net equals to stored?   
    for $i (1 .. $form->{rowcount}) {
      $form->{"amount_$i"} = $form->format_amount(\%myconfig, $form->{"amount_$i"} * (1 + $form->{"AR_base_$i"}),2);        
    }
  }elsif($totalamount) {
     foreach $item (split / /, $form->{taxaccounts}) {
      if ($form->datetonum($form->{"${item}_validfrom"},\%myconfig) > $form->datetonum($form->{transdate}, \%myconfig)
         || $form->datetonum($form->{"${item}_validto"},\%myconfig) < $form->datetonum($form->{transdate}, \%myconfig))
      {
         next;
      }    
      if ($form->{"${item}_rate"} != 0) {
	my $taxbase;
        for $j (1 .. $form->{rowcount}){
	 if($form->{"AR_base_$j"}==$form->{"${item}_rate"}){
          $taxbase += $form->{"amount_$j"};
         }
	}
        $taxamount = $taxbase * $form->{"${item}_rate"};
      }
      $taxamount = $form->round_amount($taxamount, 2);
      if ($form->{"tax_$item"} != $taxamount || $taxamount==0){
        $form->{"calctax_$item"} = 0;
      }
      $taxamount = 0;
      $form->{"tax_$item"} = $form->format_amount(\%myconfig,$form->{"tax_$item"},2);
     }    
     for $i (1 .. $form->{rowcount}) {
      $form->{"amount_$i"} = $form->format_amount(\%myconfig, $form->{"amount_$i"},2);        
     }
  }else{
    for $i (1 .. $form->{rowcount}) {
      $form->{"amount_$i"} = $form->format_amount(\%myconfig, $form->{"amount_$i"},2);        
     }
  }

  $form->{invtotal} = $totalamount + $totaltax + $totalwithholding;
  $form->{rowcount}++ if $form->{id};
  
  $form->{AR} = $form->{AR_1};
  $form->{rowcount} = 1 unless $form->{AR_amount_1};
  
  $form->{locked} = ($form->{revtrans}) ? '1' : ($form->datetonum($form->{transdate}, \%myconfig) <= $form->datetonum($form->{closedto}, \%myconfig));

  # readonly
  $form->{readonly} = 1 if $myconfig{acs} =~ /AR--Add Transaction/;

#kabai
  # registered sources
  $form->{selectregsource} = qq|<option value=0>| . $locale->text("odd number") . qq|</option>\n|;
  while ($form->{selectAR_paid} =~ /value=(\d+)/g){
      map { $form->{selectregsource} .= qq|<option value=$_->{regnum}>$_->{regnum}</option>\n| if ($_->{regnum_accno} eq $1 && !$_->{regcheck})} (@{$form->{all_sources}});
  }					      
      map { $form->{"regacc_$_->{regnum_accno}"} = "$_->{regnum}" if !$_->{regcheck}; $form->{regaccounts} .= "$_->{regnum_accno}"." " if !$_->{regcheck}} (@{$form->{all_sources}});
#kabai

}


sub form_header {
#KS
  PE->retrieve_taxreturn(\%myconfig, \%$form);
    
  $title = $form->{title};
  $form->{title} = $locale->text("$title Accounts Receivables Transaction");

  $form->{taxincluded} = ($form->{taxincluded}) ? "checked" : "";
  
# $locale->text('Add Accounts Receivables Transaction')
# $locale->text('Edit Accounts Receivables Transaction')

  # set option selected
#kabai
    ($form->{AR}) = split /--/, $form->{AR};
    if($form->{cash}){
     $form->{AR} = $form->{ar_accno};
     $jscash = qq|onBlur="this.form.transdate.value=this.form.crdate.value;this.form.duedate.value=this.form.crdate.value;"|;
    }
    $form->{selectAR} =~ s/ selected//;
    $form->{selectAR} =~ s/(option value=\Q$form->{AR}\E)/$1 selected/ if $form->{AR};

#kabai
#kabai +1
  foreach $item (qw(currency)) {
    $form->{"select$item"} =~ s/ selected//;
    $form->{"select$item"} =~ s/<option>\Q$form->{$item}\E/<option selected>$form->{$item}/;
  }
  
  foreach $item (qw(customer department employee ordnumber)) {
    $form->{"select$item"} = $form->unescape2($form->{"select$item"});
    $form->{"select$item"} =~ s/ selected//;
    $form->{"select$item"} =~ s/(<option value="\Q$form->{$item}\E")/$1 selected/;
  }

  $form->{selectprojectnumber} = $form->unescape($form->{selectprojectnumber});
  
  # format amounts
  $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});
  
  $form->{creditlimit} = $form->format_amount(\%myconfig, $form->{creditlimit}, 0, "0");
  $form->{creditremaining} = $form->format_amount(\%myconfig, $form->{creditremaining}, 0, "0");

  $exchangerate = qq|
<input type=hidden name=forex value=$form->{forex}>
|;
  if ($form->{currency} ne $form->{defaultcurrency}) {
    if ($form->{forex}) {
      $exchangerate .= qq|
	<th align=right>|.$locale->text('Exchangerate').qq|</th>
	<td><input type=hidden name=exchangerate value=$form->{exchangerate}>$form->{exchangerate}</td>
|;
    } else {
      $exchangerate .= qq|
        <th align=right>|.$locale->text('Exchangerate').qq|</th>
        <td><input name=exchangerate class="required validate-szam" size=10 value=$form->{exchangerate}></td>
|;
    }
  }
  
  $taxincluded = "";
  if ($form->{taxaccounts}) {
    $taxincluded = qq|
	      <tr>
		<td align=right><input name=taxincluded class=checkbox type=checkbox value=1 $form->{taxincluded}></td>
		<th align=left nowrap>|.$locale->text('Tax Included').qq|</th>
	      </tr>
|;
  }

 
  if (($rows = $form->numtextrows($form->{notes}, 50)) < 2) {
    $rows = 2;
  }
  $notes = qq|<textarea name=notes rows=$rows cols=50 wrap=soft>$form->{notes}</textarea>|;
  
  $department = qq|
	      <tr>
		<th align="right" nowrap>|.$locale->text('Department').qq|</th>
		<td colspan=3><select name=department>$form->{selectdepartment}</select>
		<input type=hidden name=selectdepartment value="|.$form->escape($form->{selectdepartment},1).qq|">
		</td>
	      </tr>
| if $form->{selectdepartment};

 
  $n = ($form->{creditremaining} =~ /-/) ? "0" : "1";

#kabai +1
  $customer = ($form->{selectcustomer}) ? qq|<select class="required" name=customer onchange="this.form.submit()">$form->{selectcustomer}</select>| : qq|<input name=customer class="required" value="$form->{customer}" size=35>|;

   if ($form->{selectordnumber} && !$form->{id}){
	$ordnumber = qq|<select name="ordnumber">$form->{selectordnumber}</select><br>\n|;
        $hiddenord = "class=noscreen" if ($form->{ordnumber}  ne "0");
   }
	$ordnumber .= qq|<input name="oddordnumber" $hiddenord size="11" value="$form->{oddordnumber}">|; 
   $ordnumbertext =  ($form->{selectordnumber}) ? "Register Number" : "Order Number";

  $employee = qq|
                <input type=hidden name=employee value="$form->{employee}">
|;

  $employee = qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Salesperson').qq|</th>
		<td><select name=employee>$form->{selectemployee}</select></td>
		<input type=hidden name=selectemployee value="|.$form->escape($form->{selectemployee},1).qq|">
	      </tr>
| if $form->{selectemployee};

  $form->header;
#kabai  369-370,441
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
<input type=hidden name=sort value=$form->{sort}>
<input type=hidden name=closedto value=$form->{closedto}>
<input type=hidden name=locked value=$form->{locked}>
<input type=hidden name=title value="$title">
<input type=hidden name=action value="Update">
<input type=hidden name=cash value=$form->{cash}>
<input type=hidden name=ar_accno value=$form->{ar_accno}>
<input type=hidden name=rcost_accno value=$form->{rcost_accno}>
<input type=hidden name=rincome_accno value=$form->{rincome_accno}>
<input type=hidden name=oldtransdate value=$form->{oldtransdate}>
<input type=hidden name=readonly value=$form->{readonly}>
<input type=hidden name=oldid value=$form->{oldid}>
<input type=hidden name=oldcallback value=$form->{oldcallback}>
<input type=hidden name=city value="$form->{city}">
<input type=hidden name=address1 value="$form->{address1}">
|;
  foreach $item (split / /, $form->{taxaccounts}) {
   print qq|
<input type=hidden name="${item}_validfrom" value="$form->{"${item}_validfrom"}">
<input type=hidden name="${item}_validto" value="$form->{"${item}_validto"}">
<input type=hidden name="${item}_rate" value="$form->{"${item}_rate"}">
<input type=hidden name="${item}_description" value="$form->{"${item}_description"}">
<input type=hidden name="selectAR_tax_$item" value="$form->{"selectAR_tax_$item"}">
   |;
  }
  print qq|
<font color='red'> $form->{sabment} </font>
<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table width=100%>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align="right" nowrap>|.$locale->text('Customer').qq|</th>
		<td colspan=3>$customer&nbsp;<label class="info" title='$form->{city},$form->{address1}'>?</label></td>
		<input type=hidden name=selectcustomer value="|.$form->escape($form->{selectcustomer},1).qq|">
		<input type=hidden name=oldcustomer value="$form->{oldcustomer}">
		<input type=hidden name=customer_id value="$form->{customer_id}">
		<input type=hidden name=terms value=$form->{terms}>
	      </tr>
	      <tr>
		<td></td>
		<td colspan=3>
		  <table width=100%>
		    <tr>
		      <th align=left nowrap>|.$locale->text('Credit Limit').qq|</th>
		      <td>$form->{creditlimit}</td>
		      <th align=left nowrap>|.$locale->text('Remaining').qq|</th>
		      <td class="plus$n">$form->{creditremaining}</td>
		      <input type=hidden name=creditlimit value=$form->{creditlimit}>
		      <input type=hidden name=creditremaining value=$form->{creditremaining}>
		    </tr>
		  </table>
		</td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Currency').qq|</th>
		<td><select class="required" name=currency>$form->{selectcurrency}</select></td>
		<input type=hidden name=selectcurrency value="$form->{selectcurrency}">
		<input type=hidden name=defaultcurrency value=$form->{defaultcurrency}>
		<input type=hidden name=fxgain_accno value=$form->{fxgain_accno}>
		<input type=hidden name=fxloss_accno value=$form->{fxloss_accno}>
		$exchangerate
	      </tr>
	      $department
	      $taxincluded
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $employee
	      <tr>
		<th align=right nowrap>|.$locale->text('Invoice Number').qq|</th>
		<td><input name=invnumber class="required" size=11 value="$form->{invnumber}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text($ordnumbertext).qq|</th>
		<td>$ordnumber</td>
		<input type="hidden" name="selectordnumber" value="|.$form->escape($form->{selectordnumber},1).qq|">
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Creation Date').qq|</th>
		<td><input name=crdate class="required" size=11 title="($myconfig{'dateformat'})" id=crdate OnBlur="return dattrans('crdate',|.(($form->{cash})?1:0).qq|);" value=$form->{crdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Invoice Date').qq|</th>
		<td><input name=transdate class="required" size=11 title="($myconfig{'dateformat'})" id=transdate OnBlur="return dattrans('transdate');" value=$form->{transdate}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Due Date').qq|</th>
		<td><input name=duedate class="required" size=11 title="$myconfig{'dateformat'}" id=duedate OnBlur="return dattrans('duedate');" value=$form->{duedate}></td>
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
    
<input type=hidden name=selectAR_amount value="$form->{selectAR_amount}">
<input type=hidden name=selectprojectnumber value="|.$form->escape($form->{selectprojectnumber},1).qq|">
<input type=hidden name=rowcount value=$form->{rowcount}>
|;

  $amount = $locale->text('Amount');

  for $i (1 .. $form->{rowcount}) {

    $selectAR_amount = $form->{selectAR_amount};
#kabai    $selectAR_amount =~ s/option>\Q$form->{"AR_amount_$i"}\E/option selected>$form->{"AR_amount_$i"}/;
    ($form->{"AR_amount_$i"}) = split /--/, $form->{"AR_amount_$i"};
    $selectAR_amount =~ s/(<option value=\Q$form->{"AR_amount_$i"}\E)/$1 selected/ if $form->{"AR_amount_$i"};
#kabai
    $selectprojectnumber = $form->{selectprojectnumber};
    $selectprojectnumber =~ s/(<option value="\Q$form->{"projectnumber_$i"}\E")/$1 selected/;
 
#kabai
    if($form->{taxincluded}) {
       $form->{"netamount_$i"} = $form->format_amount(\%myconfig,($form->{"amount_$i"} /(1 + $form->{"AR_base_$i"})), 2);	
       $form->{"amount_$i"} = $form->format_amount(\%myconfig, $form->{"amount_$i"}, 2);
    }else{
       $form->{"netamount_$i"} = $form->{"amount_$i"} = $form->format_amount(\%myconfig, $form->{"amount_$i"}, 2);
    }


    $project = qq|
	  <td align=right><select name="projectnumber_$i">$selectprojectnumber</select></td>
| if $form->{selectprojectnumber};
	  
#kabai
    $selectAR_base = $form->{selectAR_base};
    $selectAR_base =~ s/(<option value=\Q$form->{"AR_base_$i"}\E)/$1 selected/ if $form->{"AR_base_$i"};
     if ($i == 1){
        $classreq = qq|class="required"|;
	$classreqs = qq|class="required shrink"|;
     } else {
        $classreq = "";
     } 
#kabai    
#kabai +4
    print qq|
	<tr>
	  <th align=right>$amount</th>
	  <td><input name="amount_$i" $classreq size=10 value=$form->{"amount_$i"}></td>
	  <td><select  $classreq name="AR_base_$i">$selectAR_base</select>
	  $form->{"netamount_$i"}
	  <input type=hidden name="netamount_$i" value='$form->{"netamount_$i"}'>
          </td>
	  <td><select $classreqs name="AR_amount_$i">$selectAR_amount</select></td>
	  $project
	</tr>
|;
    $amount = "";
  }

#calculated net equals to be stored?
  foreach $item (split / /, $form->{taxaccounts}) {
    if ($form->datetonum($form->{"${item}_validfrom"},\%myconfig) > $form->datetonum($form->{transdate}, \%myconfig)
        || $form->datetonum($form->{"${item}_validto"},\%myconfig) < $form->datetonum($form->{transdate}, \%myconfig))
    {
        next;
    }    

    if ($form->{taxincluded}) {
      if ($form->{"${item}_rate"} > 0) {
	for $j (1 .. $form->{rowcount}){
	 if($form->{"AR_base_$j"}==$form->{"${item}_rate"}){
	  $taxamount += ($form->parse_amount(\%myconfig, $form->{"amount_$j"})-($form->parse_amount(\%myconfig, $form->{"amount_$j"})/(1+$form->{"AR_base_$j"})));
         }
	}
      }
    $taxamount = $form->round_amount($taxamount, 2);
    if ($form->{"tax_$item"} != $taxamount){
	for $j (1 .. $form->{rowcount}){	
           if($form->{"AR_base_$j"}==$form->{"${item}_rate"}){
		$form->{"netamount_$j"} = $form->parse_amount(\%myconfig, $form->{"netamount_$j"});
		$form->{"netamount_$j"} -= ($form->{"tax_$item"} - $taxamount);
	        $form->{"netamount_$j"} = $form->format_amount(\%myconfig, $form->{"netamount_$j"}, 2); 
		last;
	   }
	}
    }
   $taxamount = 0;
   }
  }
#calculated net equals to stored?  
#kabai    
#kabai +1
  $taxlabel = ($form->{taxincluded}) ? $locale->text('Tax') : $locale->text('Tax');
  
  foreach $item (split / /, $form->{taxaccounts}) {
#kabai    
    if ($form->datetonum($form->{"${item}_validfrom"},\%myconfig) > $form->datetonum($form->{transdate}, \%myconfig)
        || $form->datetonum($form->{"${item}_validto"},\%myconfig) < $form->datetonum($form->{transdate}, \%myconfig))
    {
        next;
    }    
#kabai 
    $form->{"calctax_$item"} = ($form->{"calctax_$item"}) ? "checked" : "";

    $form->{"tax_$item"} = $form->format_amount(\%myconfig, $form->{"tax_$item"}, 2);
    print qq|
        <tr>
	  <th align=right nowrap>$taxlabel</th>
	  <td><input name="tax_$item" size=10 value=$form->{"tax_$item"}></td>
	  <td align=right><input name="calctax_$item" class=checkbox type=checkbox value=1 $form->{"calctax_$item"}></td>
	  <td><select class="required" name="AR_tax_$item">$form->{"selectAR_tax_$item"}</select></td>
	</tr>

    |;
  
  }

  $form->{invtotal} = $form->format_amount(\%myconfig, $form->{invtotal}, 2);
#kabai +13
  print qq|
        <tr>

	  <th align=right>|.$locale->text('Total').qq|</th>
	  <th align=left>$form->{invtotal}</th>
	  <td></td>

	  <input type=hidden name=oldinvtotal value=$form->{oldinvtotal}>
	  <input type=hidden name=oldtotalpaid value=$form->{oldtotalpaid}>

	  <input type=hidden name=taxaccounts value="$form->{taxaccounts}">

	  <td><select class="required" name=AR $hidden>$form->{selectAR}</select></td>
          <input type=hidden name=selectAR value="$form->{selectAR}">
  
        </tr>
        <tr>
	  <th align=right>|.$locale->text('Notes').qq|</th>
	  <td colspan=4>$notes</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
	  <th colspan=6 class=listheading>|.$locale->text('Payments').qq|</th>
	</tr>
|;

  if ($form->{currency} eq $form->{defaultcurrency}) {
    @column_index = qw(datepaid source memo paid AR_paid);
  } else {
#kabai +1
    @column_index = qw(datepaid source memo paid exchangerate_paid AR_paid);
  }

  $column_data{datepaid} = "<th>".$locale->text('Date')."</th>";
  $column_data{paid} = "<th>".$locale->text('Amount')."</th>";
#kabai +1
  $column_data{exchangerate_paid} = "<th>".$locale->text('Exch')."</th>";
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
  for $i (1 .. $form->{paidaccounts}) {
    print "
        <tr>
";
    my $readonly;
    $form->{"selectAR_paid_$i"} = $form->{selectAR_paid};
#kabai    $form->{"selectAR_paid_$i"} =~ s/option>\Q$form->{"AR_paid_$i"}\E/option selected>$form->{"AR_paid_$i"}/;
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
    ($form->{"AR_paid_$i"}) = split /--/, $form->{"AR_paid_$i"};
    my $regsourcevalue = "regacc_".$form->{"AR_paid_$i"};
    $form->{"regsource_$i"} = $form->{$regsourcevalue}; 
    $form->{"selectAR_paid_$i"} =~ s/(<option value=\Q$form->{"AR_paid_$i"}\E)/$1 selected/ if $form->{"AR_paid_$i"} ;
    $form->{"selectregsource_$i"} =~ s/(<option value=\Q$form->{"regsource_$i"}\E)/$1 selected/ if $form->{"regsource_$i"};    

#kabai
    # format amounts
    $form->{"paid_$i"} = $form->format_amount(\%myconfig, $form->{"paid_$i"}, 2);
    $form->{"exchangerate_$i"} = $form->format_amount(\%myconfig, $form->{"exchangerate_$i"});

    $exchangerate = qq|&nbsp;|;
    if ($form->{currency} ne $form->{defaultcurrency}) {
#kabai +1 +2 +4
      if ($form->{"forex_paid_$i"}) {
	$exchangerate = qq|<input type=hidden name="exchangerate_paid_$i" value=$form->{"exchangerate_paid_$i"}>$form->{"exchangerate_paid_$i"}|;
      } else {
	$exchangerate = qq|<input name="exchangerate_paid_$i" size=10 value=$form->{"exchangerate_paid_$i"}>|;
      }
    }
    
#kabai +2
    $exchangerate .= qq|
<input type=hidden name="forex_paid_$i" value=$form->{"forex_paid_$i"}>
|;

    $column_data{paid} = qq|<td align=center><input name="paid_$i" size=11 value=$form->{"paid_$i"}></td>|;
    $column_data{AR_paid} = qq|<td align=center><select name="AR_paid_$i">$form->{"selectAR_paid_$i"}</select></td>|;
#kabai +1
    $column_data{exchangerate_paid} = qq|<td align=center>$exchangerate</td>|;
    $column_data{datepaid} = qq|<td align=center><input name="datepaid_$i"
     size=11 title="$myconfig{'dateformat'}" id=datepaid_$i OnBlur="return dattrans('datepaid_$i');"  value=$form->{"datepaid_$i"}></td>|;
#kabai
    $column_data{source} = qq|<td align=center>|;
    $column_data{source}.= qq|<input name=rsprint type=radio class=radio value=$i>
				   <select name="regsource_$i">
				   $form->{"selectregsource_$i"}</select> | if ($cashapar_true);
    $column_data{source}.= qq|<input name="source_$i" $readonly size=11 value="$form->{"source_$i"}">
				   </td>|;
    $column_data{memo} = qq|<td align=center><input name="memo_$i" size=11 value="$form->{"memo_$i"}"></td>|;

    map { print qq|$column_data{$_}\n| } @column_index;
    
    print "
        </tr>
";
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
<input type=hidden name=taxreturn value="$form->{taxreturn}">
    $hiddenregacc
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;
}


sub form_footer {
#KS
  print qq|

<input name=callback type=hidden value=|.(($form->{oldcallback}) ? "$form->{oldcallback}" : "$form->{callback}").qq|>
<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<br>
|;

  $transdate = $form->datetonum($form->{transdate}, \%myconfig);
  $closedto = $form->datetonum($form->{closedto}, \%myconfig);
  
  if (! $form->{readonly}) {
    if ($form->{id}) {
    
      print qq|<input class=submit type=submit name=action value="|.$locale->text('Update').qq|">
|;

      if (!$form->{locked}) {
	print qq|
	<input class=submit type=submit name=action onclick="return checkform();" value="|.$locale->text('Post').qq|">
	<input class=submit type=submit name=action value="|.$locale->text('Delete').qq|">
|;
      }

      print qq|
<input class=submit type=submit name=action onclick="return checkform();" value="|.$locale->text('Post as new').qq|">
<br><br>|;
    } else {
      if ($transdate > $closedto) {
	print qq|<input class=submit type=submit name=action value="|.$locale->text('Update').qq|">
	<input class=submit type=submit name=action onclick="return checkform();" value="|.$locale->text('Post').qq|">
	<br><br><input class=submit type=submit name=action value="|.$locale->text('New customer').qq|">&nbsp;&nbsp;&nbsp;&nbsp;|;
      }
    }
#kabai

#KS
      print qq|<b> |.$locale->text('Navigation').qq|</b>
      <select name=navigate><option value=1>|.$locale->text('Customer Basic Data').qq|
      <option value=2>|.$locale->text('Opened Sales Orders').qq|
      <option value=3>|.$locale->text('Opened AR Transactions');
      if(!$form->{id} and $form->{oldid}){print qq|<option value=4 selected>|.$locale->text('Previous Transaction');}
      if($form->{id}){print qq|<option value=5>|.$locale->text('Accountant Journals');}
      print qq|</select>&nbsp;<input class=submit type=submit name=action value="|.$locale->text('Jump').qq|">|;									      
									      
#kabai
  }
#kabai
   if ($cashapar_true) {
		$form->{forms}{cash_voucher} = "Cash Voucher" unless ($form->{forms});
		$form->{format} = $myconfig{prformat} unless ($form->{format});
		$form->{media} = $myconfig{prmedia} unless ($form->{media});
		$form->{copies} = $myconfig{copies}unless ($form->{copies});
		print "<br> <br>";
		&print_options;
   }
#kabai
  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print "
</form>

</body>
</html>
";

}


sub update {
  my $display = shift;

  if ($display) {
    goto TAXCALC;
  }

  $form->{invtotal} = 0;
  
  map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) } qw(exchangerate creditlimit creditremaining);

  @flds = qw(amount AR_amount projectnumber);
  $count = 0;
  @a = ();
  for $i (1 .. $form->{rowcount}) {
#kabai
    $form->{"amount_$i"} = "" if (!$form->{id} && $form->{oldcustomer} !~ /\Q$form->{customer}\E/);
#kabai    

    $form->{"amount_$i"} = $form->parse_amount(\%myconfig, $form->{"amount_$i"});

    if ($form->{"amount_$i"}) {
      push @a, {};
      $j = $#a;

      map { $a[$j]->{$_} = $form->{"${_}_$i"} } @flds;
      $count++;
    }
  }

#kabai BUG (? deletes AR_amount projectnumber)
  #$form->redo_rows(\@flds, \@a, $count, $form->{rowcount});
  $form->{rowcount} = $count + 1;

  map { $form->{invtotal} += $form->{"amount_$_"} } (1 .. $form->{rowcount});

  $form->{exchangerate} = $exchangerate if ($form->{forex} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}, 'buy')));

  &check_name(customer);

  if ($form->{transdate} ne $form->{oldtransdate}) {
#kabai NODUESET    $form->{duedate} = $form->current_date(\%myconfig, $form->{transdate}, $form->{terms} * 1);
    $form->{calctax} = 1;
    $form->{oldtransdate} = $form->{transdate};
  }
  


TAXCALC:
  # recalculate taxes

  @taxaccounts = split / /, $form->{taxaccounts};
  
  map { $form->{"tax_$_"} = $form->parse_amount(\%myconfig, $form->{"tax_$_"}) } @taxaccounts;
  
  if ($form->{taxincluded}) {
    foreach $item (@taxaccounts) {
#kabai    
    if ($form->datetonum($form->{"${item}_validfrom"},\%myconfig) > $form->datetonum($form->{transdate}, \%myconfig)
        || $form->datetonum($form->{"${item}_validto"},\%myconfig) < $form->datetonum($form->{transdate}, \%myconfig))
    {
        next;
    }    
#kabai
       $form->{"calctax_$item"} = 1 if $form->{calctax};
       if ($form->{"calctax_$item"}) {
          my $sumbase = 0;
	  for $i (1.. $form->{rowcount}) {
            if ($form->{"AR_base_$i"} == $form->{"${item}_rate"}){
               $sumbase += $form->{"amount_$i"}; 
            }
	  }   

	if ($form->{"${item}_rate"} >= 0) {
#kabai
	  $amount = $form->round_amount($sumbase - $sumbase / (1 + $form->{"${item}_rate"}), 2);
#kabai	  $amount = $form->round_amount($form->{invtotal} * $taxrate / (1 + $taxrate), 2) * $form->{"${item}_rate"} / $taxrate;
	  $form->{"tax_$item"} = $form->round_amount($amount, 2);
	  $taxdiff += ($amount - $form->{"tax_$item"});
	} else {
	  #$amount = $form->round_amount($form->{invtotal} * $withholdingrate / (1 - $withholdingrate), 2) * $form->{"${item}_rate"} / $withholdingrate;
	  $amount = $form->round_amount(($sumbase / (1 + $form->{"${item}_rate"})) * $form->{"${item}_rate"}, 2);
	  $form->{"tax_$item"} = $form->round_amount($amount, 2);
	  $taxdiff += ($amount - $form->{"tax_$item"});
	}

	if (abs($taxdiff) >= 0.005) {
	  $form->{"tax_$item"} += $form->round_amount($taxdiff, 2);
	  $taxdiff = 0;
	}
      }
#kabai      $form->{"selectAR_tax_$item"} = qq|<option>$item--$form->{"${item}_description"}|;
        $refaccno = "$item--" if $showaccnumbers_true;
	$form->{"selectAR_tax_$item"} = qq|<option value=$item>$refaccno$form->{"${item}_description"}|;
        $totaltax += $form->{"tax_$item"};
        $form->{"${item}_rate"} = "0.00" if !$form->{"${item}_rate"};
        $form->{"${item}_rate"} .= "0" if length($form->{"${item}_rate"}) == 3;
	$form->{selectAR_base} .= qq|<option value=$form->{"${item}_rate"}>$form->{"${item}_rate"} alap|;
#kabai	
    }
  } else {
    foreach $item (@taxaccounts) {
#kabai    
    if ($form->datetonum($form->{"${item}_validfrom"},\%myconfig) > $form->datetonum($form->{transdate}, \%myconfig)
        || $form->datetonum($form->{"${item}_validto"},\%myconfig) < $form->datetonum($form->{transdate}, \%myconfig))
    {
        next;
    }    
#kabai 
      $form->{"calctax_$item"} = 1 if $form->{calctax};
#kabai      
      $form->{"${item}_rate"} = "0.00" if !$form->{"${item}_rate"};
      $form->{"${item}_rate"} .= "0" if length($form->{"${item}_rate"}) == 3;
      $form->{selectAR_base} .= qq|<option value=$form->{"${item}_rate"}>$form->{"${item}_rate"} alap|;
#kabai      
      if ($form->{"calctax_$item"}) {
#kabai
	my $sumbase = 0;
	
	for $i (1.. $form->{rowcount}){
	    $sumbase += $form->{"amount_$i"} if abs($form->{"AR_base_$i"}) == abs($form->{"${item}_rate"});
	}
	$form->{"tax_$item"} = $form->round_amount($sumbase * $form->{"${item}_rate"}, 2);
#kabai	$form->{"tax_$item"} = $form->round_amount($form->{invtotal} * $form->{"${item}_rate"}, 2);
      }
#kabai      $form->{"selectAR_tax_$item"} = qq|<option>$item--$form->{"${item}_description"}|;
        $refaccno = "$item--" if $showaccnumbers_true; 
        $form->{"selectAR_tax_$item"} = qq|<option value=$item>$refaccno$form->{"${item}_description"}|;
#kabai
      $totaltax += $form->{"tax_$item"};
    }
  }

  $form->{invtotal} = ($form->{taxincluded}) ? $form->{invtotal} : $form->{invtotal} + $totaltax;
#kabai
    if ($form->{cash}) {
      if ($form->{currency} eq "HUF"){
	my $mod_invtotal = $form->{invtotal} % 5;
	if ($mod_invtotal < 3) {
	  $form->{paid_1} = $form->format_amount(\%myconfig,$form->{invtotal}-$mod_invtotal);
          $form->{paid_2} = ($mod_invtotal == 0) ? "0" : $form->format_amount(\%myconfig,$mod_invtotal);
	  $form->{AR_paid_2} = $form->{rcost_accno};
	  $form->{memo_2} = $locale->text('Rounding cost');
        }else{
	  $form->{paid_1} = $form->format_amount(\%myconfig,$form->{invtotal}-$mod_invtotal + 5);
          $form->{paid_2} = ($mod_invtotal == 0) ? "0" : $form->format_amount(\%myconfig,$mod_invtotal-5);
	  $form->{AR_paid_2} = $form->{rincome_accno};
	  $form->{memo_2} = $locale->text('Rounding income');
        }	  
        $form->{datepaid_1} = $form->{datepaid_2} = $form->{transdate};
	$form->{source_1} = $form->{source_2} = $form->{invnumber} ;
      }else{
	 $form->{paid_1} = $form->format_amount(\%myconfig,$form->{invtotal});
         $form->{datepaid_1} = $form->{transdate};
	 $form->{source_1} = $form->{invnumber};
      }  
    #    $hidden = "id=hidden";
    }
#kabai    	

  for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"}) {
#kabai +1
      map { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) } qw(paid);

      $totalpaid += $form->{"paid_$i"};
#kabai +1
      $form->{"exchangerate_paid_$i"} = $exchangerate if ($form->{"forex_paid_$i"} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{"datepaid_$i"}, 'buy_paid')));
    }
  }
 
  $form->{creditremaining} -= ($form->{invtotal} - $totalpaid + $form->{oldtotalpaid} - $form->{oldinvtotal});
  $form->{oldinvtotal} = $form->{invtotal};
  $form->{oldtotalpaid} = $totalpaid;
  
  &display_form;
  
}


sub post {
  if ($form->{mod_save}) {goto friss};
  if ($form->{transdate} le $form->{taxreturn}) 
  {$form->error($locale->text('Cannot post invoice for a tax returned period!'))} 
  
   
  # check if there is an invoice number, invoice and due date
  $form->isblank("transdate", $locale->text('Invoice Date missing!'));
  $form->isblank("duedate", $locale->text('Due Date missing!'));
  $form->isblank("customer", $locale->text('Customer missing!'));
#kabai
  $form->isblank("crdate", $locale->text('Creation Date missing!'));
  $form->error($locale->text('Invoice Number missing!')) if !$form->{invnumber};


  if ($strictcash_true){
   for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"regsource_$i"} ne "" && $form->{"paid_$i"}){
    $regsourcevalue = $form->{"AR_paid_$i"};
      if ($form->{"regacc_$regsourcevalue"} ne $form->{"regsource_$i"} || $form->{"source_$i"}){
	$form->error($locale->text('This source number does not belong to the selected cash account!'));
      }	
    }  
   }
  }  
#kabai
  $closedto = $form->datetonum($form->{closedto}, \%myconfig);
  $transdate = $form->datetonum($form->{transdate}, \%myconfig);
  
  $form->error($locale->text('Cannot post transaction for a closed period!')) if ($transdate <= $closedto);

  $form->isblank("exchangerate", $locale->text('Exchangerate missing!')) if ($form->{currency} ne $form->{defaultcurrency});
  
  for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"}) {
      $datepaid = $form->datetonum($form->{"datepaid_$i"}, \%myconfig);
      
      $form->isblank("datepaid_$i", $locale->text('Payment date missing!'));

      $form->error($locale->text('Cannot post payment for a closed period!')) if ($datepaid <= $closedto);

      if ($form->{currency} ne $form->{defaultcurrency}) {
#kabai	$form->{"exchangerate_$i"} = $form->{exchangerate} if ($transdate == $datepaid);
	$form->isblank("exchangerate_paid_$i", $locale->text('Exchangerate for payment missing!'));
#kabai
      }
    }
  }

  # if oldcustomer ne customer redo form
  ($customer) = split /--/, $form->{customer};
  if ($form->{oldcustomer} ne "$customer--$form->{customer_id}"  || !$form->{netamount_1} ) {
    $form->info($locale->text('Datas updated, please continue posting'));
    &update;
    exit;
  }
#kabai
  $form->error($locale->text('VAT base missing!')) if !$form->{AR_base_1};
#kabai 

  $form->{invnumber} = $form->update_defaults(\%myconfig, "invnumber") unless $form->{invnumber};

  $form->{id} = 0 if $form->{postasnew};
  for $i (1 .. $form->{rowcount}) {
    my $debt=$form->parse_amount(\%myconfig, $form->{"debit_$i"});
    my $cret += $form->parse_amount(\%myconfig, $form->{"credit_$i"});
    $debit +=$debt;
    $credit += $cret;
    my $ii=$form->{"accno_$i"};
    $form->{"sum_$ii"}+=$debt-$cret;
  }


  # add up debits and credits
if (!$form->{adjustment}) {
  my $felso, $felsoh;
  for $i (1 .. $form->{rowcount}) {
    my $ii=$form->{"AR_paid_$i"};
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
    $form->{sabment}=$locale->text('Item saved') if !$form->{id};
    $form->{sabment}=$locale->text('Item saved') if !$form->{id};
    if ($form->{id}){
      &post_modify;
      exit;
    }
friss:
			          
  if (AR->post_transaction(\%myconfig, \%$form)){
      $form->{callback}.="&sabment=".$form->escape($form->{sabment});
      if(!$post_and_print){
#KS
      $form->{callback}.="&oldid=$form->{id}" if ($form->{callback});
      $form->redirect($locale->text('Transaction posted!')) if (!$_[0]);
     }
   }else{
     $form->error($locale->text('Cannot post transaction!'));
  }
}


sub post_as_new {

  $form->{postasnew} = 1;
  &post;

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
  {$form->error($locale->text('Cannot delete invoice for a tax returned period!'))} 

  $form->{title} = $locale->text('Confirm!');
  
  $form->header;

  delete $form->{header};

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  foreach $key (keys %$form) {
    print qq|<input type=hidden name=$key value="$form->{$key}">\n|;
  }

  print qq|
<h2 class=confirm>$form->{title}</h2>

<h4>|.$locale->text('Are you sure you want to delete Transaction').qq| $form->{invnumber}</h4>

<input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
</form>

</body>
</html>
|;

}



sub yes {

  $form->redirect($locale->text('Transaction deleted!')) if (AR->delete_transaction(\%myconfig, \%$form, $spool));
  $form->error($locale->text('Cannot delete transaction!'));

}


sub search {

  $form->create_links("AR", \%myconfig, "customer");
  
  $form->{selectAR} = "<option>\n";
  map { $form->{selectAR} .= "<option>$_->{accno}--$_->{description}\n" } @{ $form->{AR_links}{AR} };
  
  if (@{ $form->{all_customer} }) { 
    map { $customer .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| } @{ $form->{all_customer} };
    $customer = qq|<select name=customer><option>\n$customer</select>|;
  } else {
    $customer = qq|<input name=customer size=35>|;
  }

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


  $form->{title} = $locale->text('AR Transactions');

  $invnumber = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Invoice Number').qq|</th>
	  <td colspan=3><input name=invnumber size=20></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Order Number').qq|</th>
	  <td colspan=3><input name=ordnumber size=20></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Notes').qq|</th>
	  <td colspan=3><input name=notes size=40></td>
	</tr>
|;

  $openclosed = qq|
	      <tr>
		<td align=right><input name=open class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Open').qq|</td>
		<td align=right><input name=closed class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Closed').qq|</td>
	      </tr>
              <tr height="10"></tr>
|;

  if ($form->{outstanding}) {
    $form->{title} = $locale->text('AR Outstanding');
    $invnumber = "";
    $openclosed = "";
    $hibhat=qq|<tr>
    <th align=right nowrap>|.$locale->text('Difference').qq|<=</th>
    <td><input name=marginerr1 size=11></td>
    <th align=right nowrap>|.$locale->text('Difference').qq|>=</th>
    <td><input name=marginerr2 size=11></td>
    </tr>|;
  }
  my $class1 = qq|class="noscreen"| if $maccess !~ /Accountant--All/;
#kabai    +35, +97
  $form->header;
  
  print qq|
<body>|;
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
<input type=hidden name=outstanding value=$form->{outstanding}>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr $class1>
	  <th align=right>|.$locale->text('Account').qq|</th>
	  <td colspan=3><select name=AR>$form->{selectAR}</select></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Customer').qq|</th>
	  <td colspan=3>$customer</td>
	</tr>
	$department
	$invnumber
	<tr>
	  <th align=right nowrap>|.$locale->text('From').qq|</th>
	  <td><input name=transdatefrom size=11 title="$myconfig{dateformat}" id=transdatefrom OnBlur="return dattrans('transdatefrom');"></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=transdateto size=11 title="$myconfig{dateformat}" id=transdateto OnBlur="return dattrans('transdateto');"></td>
	</tr>
	<input type=hidden name=sort value=transdate>
	<tr>
	  <th align=right nowrap>|.$locale->text('Crdate From').qq|</th>
	  <td><input name=crdatefrom size=11 title="$myconfig{dateformat}" id=crdatefrom OnBlur="return dattrans('crdatefrom');"></td>
	  <th align=right>|.$locale->text('Crdate To').qq|</th>
	  <td><input name=crdateto size=11 title="$myconfig{dateformat}" id=crdateto OnBlur="return dattrans('crdateto');"></td>
	</tr>

	<tr>
	  <th align=right nowrap>|.$locale->text('Due From').qq|</th>
	  <td><input name=duefrom size=11 title="$myconfig{dateformat}" id=duefrom OnBlur="return dattrans('duefrom');"></td>
	  <th align=right>|.$locale->text('Due To').qq|</th>
	  <td><input name=dueto size=11 title="$myconfig{dateformat}" id=dueto OnBlur="return dattrans('dueto');"></td>
	</tr>
	$hibhat
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td>
	    <table width=100%>
	      $openclosed
              <tr>
                <td align="right"><input name="payment_list" class="checkbox" type="checkbox"
                onClick="if (this.form.payment_list.checked) {this.form.l_osubtotal.checked=false}" value="Y"></td>
                <td nowrap>|.$locale->text('List payments').qq|</td>
                <td align="right"><input name="l_account" class="checkbox" type="checkbox"
                onClick="if (this.form.l_account.checked) {this.form.l_osubtotal.checked=false}" value="Y"></td>
                <td nowrap>|.$locale->text('with accounts').qq|</td>
                <td align="right"><input name="l_pmfxamount" class="checkbox" type="checkbox"
                onClick="if (this.form.l_pmfxamount.checked) {this.form.l_osubtotal.checked=false}" value="Y"></td>
                <td nowrap>|.$locale->text('with payment FX amounts').qq|</td>
                <td align="right"><input name="l_bankrate" class="checkbox" type="checkbox"
                onClick="if (this.form.l_bankrate.checked) {this.form.l_osubtotal.checked=false}" value="Y"></td>
                <td nowrap>|.$locale->text('with bankrates').qq|</td>
                </tr>
              <tr height="10"></tr>
	      <tr>
		<td align=right><input name="l_id" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('ID').qq|</td>
		<td align=right><input name="l_invnumber" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Invoice Number').qq|</td>
		<td align=right><input name="l_ordnumber" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Order Number').qq|</td>
		<td align=right><input name="l_transdate" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Invoice Date').qq|</td>
	      </tr>
	      <tr>
		<td align=right><input name="l_name" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Customer').qq|</td>
		<td align=right><input name="l_netamount" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Amount').qq|</td>
		<td align=right><input name="l_tax" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Tax').qq|</td>
		<td align=right><input name="l_amount" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Total').qq|</td>
	      </tr>
	      <tr>
		<td align=right><input name="l_datepaid" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Date Paid').qq|</td>
		<td align=right><input name="l_paid" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Paid').qq|</td>
		<td align=right><input name="l_duedate" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Due Date').qq|</td>
		<td align=right><input name="l_due" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Amount Due').qq|</td>
	      </tr>
	      <tr>
		<td align=right><input name="l_notes" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Notes').qq|</td>
		<td align=right><input name="l_till" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Till').qq|</td>
		<td align=right><input name="l_shippingpoint" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Shipping Point').qq|</td>
		<td align=right><input name="l_shipvia" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Ship via').qq|</td>
	      </tr>
              <tr>
		<td align=right><input name="l_employee" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Salesperson').qq|</td>
		<td align=right><input name="l_manager" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Manager').qq|</td>
		<td align=right><input name="l_crdate" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Creation Date').qq|</td>
		<td align=right><input name="l_lastcost" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Last Cost').qq|</td>
	      </tr>
	      <tr>
		<td align=right><input name="l_curr" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Currency').qq|</td>
		<td align=right><input name="l_fxamount" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('FX amount').qq|</td>
		<td align=right><input name="l_exchrate" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Exch rate').qq|</td>
	      </tr>
	      <tr>
                <td align=right><input name="l_subtotal" class=checkbox type=checkbox
                onClick="if (this.form.l_subtotal.checked) {this.form.l_osubtotal.checked=false}" value=Y></td>
                <td nowrap>|.$locale->text('Subtotal').qq|</td>
                <td align=right><input name="l_osubtotal" class=checkbox type=checkbox
                onClick="if (this.form.l_osubtotal.checked) {this.form.l_subtotal.checked=false;
                this.form.payment_list.checked=false;this.form.l_account.checked=false;
                this.form.l_pmfxamount.checked=false}this.form.l_bankrate.checked=false}"  value=Y></td>
                <td nowrap>|.$locale->text('Only subtotal').qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=nextsub value=$form->{nextsub}>

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


sub ar_transactions {
#KS
  $form->{l_subtotal}='Y' if ($form->{l_osubtotal} eq 'Y');
   
  if ($form->{customer}) {
    $form->{customer} = $form->unescape($form->{customer});
    ($form->{customer}, $form->{customer_id}) = split(/--/, $form->{customer});
  }
  
  AR->ar_transactions(\%myconfig, \%$form);

  $href = "$form->{script}?action=ar_transactions&direction=$form->{direction}&oldsort=$form->{oldsort}&till=$form->{till}&outstanding=$form->{outstanding}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&payment_list=$form->{payment_list}";
  
  $href .= "&title=".$form->escape($form->{title});
  
  $form->sort_order();
  

  $callback = "$form->{script}?action=ar_transactions&direction=$form->{direction}&oldsort=$form->{oldsort}&till=$form->{till}&outstanding=$form->{outstanding}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&payment_list=$form->{payment_list}";

  $callback .= "&title=".$form->escape($form->{title},1);

  if ($form->{AR}) {
    $callback .= "&AR=".$form->escape($form->{AR},1);
    $href .= "&AR=".$form->escape($form->{AR});
    $form->{AR} =~ s/--/ /;
    $option = $locale->text('Account')." : $form->{AR}";
  }
  
  if ($form->{customer}) {
    $callback .= "&customer=".$form->escape($form->{customer},1)."--$form->{customer_id}";
    $href .= "&customer=".$form->escape($form->{customer})."--$form->{customer_id}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Customer')." : $form->{customer}";
  }
  if ($form->{department}) {
    $callback .= "&department=".$form->escape($form->{department},1);
    $href .= "&department=".$form->escape($form->{department});
    ($department) = split /--/, $form->{department};
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Department')." : $department";
  }
  if ($form->{invnumber}) {
    $callback .= "&invnumber=".$form->escape($form->{invnumber},1);
    $href .= "&invnumber=".$form->escape($form->{invnumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Invoice Number')." : $form->{invnumber}";
  }
  if ($form->{ordnumber}) {
    $callback .= "&ordnumber=".$form->escape($form->{ordnumber},1);
    $href .= "&ordnumber=".$form->escape($form->{ordnumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Order Number')." : $form->{ordnumber}";
  }
  if ($form->{notes}) {
    $callback .= "&notes=".$form->escape($form->{notes},1);
    $href .= "&notes=".$form->escape($form->{notes});
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Notes')." : $form->{notes}";
  }
  
  if ($form->{transdatefrom}) {
    $callback .= "&transdatefrom=$form->{transdatefrom}";
    $href .= "&transdatefrom=$form->{transdatefrom}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{transdatefrom}, 1);
  }
  if ($form->{transdateto}) {
    $callback .= "&transdateto=$form->{transdateto}";
    $href .= "&transdateto=$form->{transdateto}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{transdateto}, 1);
  }
#kabai
  if ($form->{crdatefrom}) {
    $callback .= "&crdatefrom=$form->{crdatefrom}";
    $href .= "&crdatefrom=$form->{crdatefrom}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Crdate From')."&nbsp;".$locale->date(\%myconfig, $form->{crdatefrom}, 1);
  }
  if ($form->{crdateto}) {
    $callback .= "&crdateto=$form->{crdateto}";
    $href .= "&crdateto=$form->{crdateto}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Crdate To')."&nbsp;".$locale->date(\%myconfig, $form->{crdateto}, 1);
  }
  if ($form->{duefrom}) {
    $callback .= "&duefrom=$form->{duefrom}";
    $href .= "&duefrom=$form->{duefrom}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Due From')."&nbsp;".$locale->date(\%myconfig, $form->{duefrom}, 1);
  }
  if ($form->{dueto}) {
    $callback .= "&dueto=$form->{dueto}";
    $href .= "&dueto=$form->{dueto}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Due To')."&nbsp;".$locale->date(\%myconfig, $form->{dueto}, 1);
  }
  if ($form->{marginerr1}) {
    $callback .= "&marginerr1=$form->{marginerr1}";
    $href .= "&marginerr1=$form->{marginerr1}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Difference')."<= ".$form->{marginerr1};
 }
  if ($form->{marginerr2}) {
    $callback .= "&marginerr2=$form->{marginerr2}";
    $href .= "&marginerr2=$form->{marginerr2}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Difference').">= ".$form->{marginerr2};
 }
		     
#kabai
  if ($form->{open}) {
    $callback .= "&open=$form->{open}";
    $href .= "&open=$form->{open}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Open');
  }
  if ($form->{closed}) {
    $callback .= "&closed=$form->{closed}";
    $href .= "&closed=$form->{closed}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Closed');
  }
#kabai +1
  if ($form->{payment_list} ne "Y") {
	delete $form->{l_account};
	delete $form->{l_pmfxamount};
	delete $form->{l_bankrate};
  }

  @columns = $form->sort_columns(qw(transdate id invnumber ordnumber name netamount tax amount paid pmfxamount bankrate due account datepaid duedate notes till employee manager shippingpoint shipvia crdate curr fxamount exchrate lastcost));
  
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
  if ($form->{l_osubtotal} eq 'Y') {
    $callback .= "&l_osubtotal=Y";
    $href .= "&l_osubtotal=Y";
  }
	      

#kabai +1 BUG
  $column_header{id} = "<th><a class=listheading href=$href&sort=id>".$locale->text('ID')."</a></th>";
  $column_header{transdate} = "<th><a class=listheading href=$href&sort=transdate>".$locale->text('Date')."</a></th>";
  $column_header{duedate} = "<th><a class=listheading href=$href&sort=duedate>".$locale->text('Due Date')."</a></th>";
  $column_header{invnumber} = "<th><a class=listheading href=$href&sort=invnumber>".$locale->text('Invoice')."</a></th>";
  $column_header{ordnumber} = "<th><a class=listheading href=$href&sort=ordnumber>".$locale->text('Order')."</a></th>";
  $column_header{name} = "<th><a class=listheading href=$href&sort=name>".$locale->text('Customer')."</a></th>";
  $column_header{netamount} = "<th class=listheading>" . $locale->text('Amount') . "</th>";
  $column_header{tax} = "<th class=listheading>" . $locale->text('Tax') . "</th>";
  $column_header{amount} = "<th class=listheading>" . $locale->text('Total') . "</th>";
  $column_header{paid} = "<th class=listheading>" . $locale->text('Paid') . "</th>";
  $column_header{pmfxamount} = qq|<th class=listheading>|.$locale->text('Payment FX amount').qq|</th>|;
  $column_header{bankrate} = qq|<th class=listheading>|.$locale->text('Bank rate').qq|</th>|;
  $column_header{account} = qq|<th class=listheading>|.$locale->text('Account').qq|</th>|;
  $column_header{datepaid} = "<th><a class=listheading href=$href&sort=datepaid>" . $locale->text('Date Paid') . "</a></th>";
  $column_header{due} = "<th class=listheading>" . $locale->text('Amount Due') . "</th>";
  $column_header{notes} = "<th class=listheading>".$locale->text('Notes')."</th>";
  $column_header{employee} = "<th><a class=listheading href=$href&sort=employee>".$locale->text('Salesperson')."</th>";
  $column_header{manager} = "<th><a class=listheading href=$href&sort=manager>".$locale->text('Manager')."</th>";
  $column_header{till} = "<th class=listheading><a class=listheading href=$href&sort=till>".$locale->text('Till')."</th>";
  $column_header{lastcost} = qq|<th class=listheading>|.$locale->text('Last Cost')."</th>";
  
  $column_header{shippingpoint} = "<th><a class=listheading href=$href&sort=shippingpoint>" . $locale->text('Shipping Point') . "</a></th>";
  $column_header{shipvia} = "<th><a class=listheading href=$href&sort=shipvia>" . $locale->text('Ship via') . "</a></th>";
#kabai
  $column_header{crdate} = "<th><a class=listheading href=$href&sort=crdate>".$locale->text('Creation Date')."</a></th>";
  $column_header{curr} = qq|<th><a class=listheading href=$href&sort=curr>|.$locale->text('Currency').qq|</a></th>|;  
  $column_header{fxamount} = qq|<th class=listheading>|.$locale->text('FX amount').qq|</th>|;
  $column_header{exchrate} = qq|<th class=listheading>|.$locale->text('Exch rate').qq|</th>|;
#kabai
#kabai
  $form->{title} = ($form->{title}) ? $form->{title} : $locale->text('AR Transactions');

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

  map { print "\n$column_header{$_}" } @column_index;

  print qq|
	</tr>
|;


  # add sort and escape callback, this one we use for the add sub
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);
  
  # flip direction
  $direction = ($form->{direction} eq 'ASC') ? "ASC" : "DESC";
  $href =~ s/&direction=(\w+)&/&direction=$direction&/;
  
	$subtotal = 0;
	undef ($sameitem);
	if ($form->{payment_list} eq "Y") {
		$groupby = "id";
		}
	else {
		$groupby = $form->{sort};
		}

  # sums and tax on reports by Antonio Gallardo
  #
  foreach $ar (@{ $form->{transactions} }) {

		if (($form->{payment_list} eq "Y") && ($sameitem eq $ar->{$groupby})) {
			map { $column_data{$_} = "<TD></TD>" } @column_index;
			}
		else {
			if ($sameitem ne $ar->{$groupby}) {
				if (($form->{l_subtotal} eq 'Y') && $subtotal) {
					&ar_subtotal;
					}
				$sameitem = $ar->{$groupby};
			}

    $column_data{netamount} = "<td align=right>".$form->format_amount(\%myconfig, $ar->{netamount}, 2, "&nbsp;")."</td>";
    $column_data{tax} = "<td align=right>".$form->format_amount(\%myconfig, $ar->{amount} - $ar->{netamount}, 2, "&nbsp;")."</td>";
    $column_data{amount} = "<td align=right>".$form->format_amount(\%myconfig, $ar->{amount}, 2, "&nbsp;")."</td>";
			$due = $ar->{amount};
    
    $subtotalnetamount += $ar->{netamount};
    $subtotalamount += $ar->{amount};
    $subtotaldue += $ar->{amount};
    
    $totalnetamount += $ar->{netamount};
    $totalamount += $ar->{amount};
    $totaldue += $ar->{amount};
    
    $column_data{transdate} = "<td>$ar->{transdate}&nbsp;</td>";
#kabai
    $column_data{crdate} = "<td>$ar->{crdate}&nbsp;</td>";
#kabai
    $column_data{id} = "<td>$ar->{id}</td>";
    $column_data{duedate} = "<td>$ar->{duedate}&nbsp;</td>";

    $module = ($ar->{invoice}) ? "is.pl" : $form->{script};
    $module = ($ar->{till}) ? "ps.pl" : $module;

    $column_data{invnumber} = "<td><a href=$module?action=edit&id=$ar->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ar->{invnumber}</a></td>";
    $column_data{ordnumber} = "<td>$ar->{ordnumber}&nbsp;</td>";
    

    $name = $form->escape($ar->{name});
    $column_data{name} = "<td><a href=$href&customer=$name--$ar->{customer_id}&sort=$form->{sort}>$ar->{name}</a></td>";
    
    $ar->{notes} =~ s/\r\n/<br>/g;
    $column_data{notes} = "<td>$ar->{notes}&nbsp;</td>";
    $column_data{shippingpoint} = "<td>$ar->{shippingpoint}&nbsp;</td>";
    $column_data{shipvia} = "<td>$ar->{shipvia}&nbsp;</td>";
    $column_data{employee} = "<td>$ar->{employee}&nbsp;</td>";
    $column_data{manager} = "<td>$ar->{manager}&nbsp;</td>";
    $column_data{till} = "<td>$ar->{till}&nbsp;</td>";
    $column_data{lastcost} = "<td align=right>".$form->format_amount(\%myconfig, $ar->{lastcost}, 2, "&nbsp;") . "</td>";
    $totallastcost += $ar->{lastcost};  
    $subtotallastcost += $ar->{lastcost};
#kabai
    $column_data{curr} = "<td>$ar->{curr}&nbsp;</td>";
    $column_data{fxamount} = "<td align=right>".$form->format_amount(\%myconfig, $ar->{fxamount}, 2, "&nbsp;") . "</td>";
    $column_data{exchrate} = "<td>".$form->format_amount(\%myconfig, $ar->{exchrate}, 2, "&nbsp;") . "</td>";
    $totalfxamount += $ar->{fxamount};
    $subtotalfxamount += $ar->{fxamount};
#kabai  
    }
		$due -= $ar->{paid};
		$totaldue -= $ar->{paid};
		$subtotaldue -= $ar->{paid};

    $column_data{paid} = "<td align=right>".$form->format_amount(\%myconfig, $ar->{paid}, 2, "&nbsp;")."</td>";
		$column_data{pmfxamount} = qq|<td align="right">|.$form->format_amount (\%myconfig, $ar->{pmfxamount}, 2).qq|</td>|;
		$column_data{bankrate} = qq|<td align="right">|.$form->format_amount (\%myconfig, $ar->{bankrate}, 2,).qq|</td>|;
    $column_data{due} = "<td align=right>".$form->format_amount(\%myconfig, $due, 2, "&nbsp;")."</td>";

    $totalpaid += $ar->{paid};

    $subtotalpaid += $ar->{paid};

		$column_data{account} = "<TD>$ar->{account}</TD>";

    $column_data{datepaid} = "<td>$ar->{datepaid}&nbsp;</td>";

    $i++; $i %= 2;
    if($form->{l_osubtotal} ne 'Y') {print "
        <tr class=listrow$i>
";

    map { print "\n$column_data{$_}" } @column_index;

    print qq|
        </tr>
|;
    }
	 $subtotal = 1;
  
  }

  if (($form->{l_subtotal} eq 'Y') && $subtotal) {
    &ar_subtotal;
  }

  # print totals
  print qq|
        <tr class=listtotal>
|;

  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
  
  $column_data{netamount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalnetamount, 2, "&nbsp;")."</th>";
  $column_data{tax} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount - $totalnetamount, 2, "&nbsp;")."</th>";
  $column_data{amount} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalamount, 2, "&nbsp;")."</th>";
  $column_data{paid} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalpaid, 2, "&nbsp;")."</th>";
  $column_data{due} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totaldue, 2, "&nbsp;")."</th>";
  $column_data{lastcost} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totallastcost, 2, "&nbsp;")."</th>";


  map { print "\n$column_data{$_}" } @column_index;

  if ($myconfig{acs} !~ /AR--AR/) {
    $i = 1;
    $button{'AR--Add Transaction'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('AR Transaction').qq|"> |;
    $button{'AR--Add Transaction'}{order} = $i++;
    $button{'AR--Sales Invoice'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Sales Invoice').qq|."> |;
    $button{'AR--Sales Invoice'}{order} = $i++;

    foreach $item (split /;/, $myconfig{acs}) {
      delete $button{$item};
    }
  }
 
  print qq|
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<form method=post action=$form->{script}>

<input name="callback" type=hidden value="$form->{callback}">

<input type=hidden name="customer" value="$form->{customer}">
<input type=hidden name="customer_id" value="$form->{customer_id}">
<input type=hidden name="vc" value="customer">

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
|;

  if (! $form->{till}) {
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


sub ar_subtotal {
  my $elso=$column_data{@column_index[0]};
  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
  $column_data{@column_index[0]}=$elso if ($form->{l_osubtotal} eq 'Y');  
  $column_data{tax} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalamount - $subtotalnetamount, 2, "&nbsp;")."</th>";
  $column_data{amount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalamount, 2, "&nbsp;")."</th>";
  $column_data{paid} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalpaid, 2, "&nbsp;")."</th>";
  $column_data{due} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotaldue, 2, "&nbsp;")."</th>";
#kabai
  $column_data{fxamount} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalfxamount, 2, "&nbsp;")."</th>";
  $column_data{lastcost} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotallastcost, 2, "&nbsp;")."</th>";

  $subtotalfxamount = 0;
#kabai  
  $subtotalnetamount = 0;
  $subtotalamount = 0;
  $subtotalpaid = 0;
  $subtotaldue = 0;
  $subtotallastcost = 0;

  print "<tr class=listsubtotal>";

  map { print "\n$column_data{$_}" } @column_index;

print "
</tr>
";
 
}
sub new_customer { #kabai
    $form->{callback} = $form->escape($form->{callback},1);
    $form->{callback} = "ct.pl?path=bin/mozilla&action=add&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}&db=customer";
    $form->redirect;
}

#KS
sub jump{
 if ($form->{navigate}==1){
   $form->{oldcallback} = $form->escape($form->{callback},1);
   $form->{callback} ="ar.pl?action=edit&id=$form->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&oldcallback=$form->{oldcallback}";
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
 if ($form->{navigate}==4){
   $form->{oldcallback} = $form->escape($form->{callback},1);
   $form->{callback} ="ar.pl?action=edit&id=$form->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&oldcallback=$form->{oldcallback}";
   $form->{callback} =$form->escape($form->{callback},1);
   $form->{callback} ="ar.pl?action=edit&id=$form->{oldid}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}";
   $form->redirect;
 }
 if ($form->{navigate}==5){
   $callback="gl.pl?action=generate_report&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&direction=DESC&oldsort=transdate&l_transdate=Y&l_reference=Y&l_description=Y&l_source=Y&l_debit=Y&l_credit=Y&l_accno=Y&l_acc_descr=Y&category=X&journal=all&sort=transdate&id=$form->{id}"; 
   $form->{callback} = $callback;
   $form->redirect;
 }
}
	
1;										    							    

