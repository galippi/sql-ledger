#=====================================================================
# SQL-Ledger Accounting
# Copyright (c) 2001
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#  Modified by Tavugyvitel Kft. (info@tavugyvitel.hu)
#
#  Contributors: Antonio Gallardo <agssa@ibw.com.ni>
#                Benjamin Lee <benjaminlee@consultant.com>
#		 Jozsef Kabai <kabai@tavugyvitel.hu>
#		 Istvan Sipos <Istvan.Sipos@diakont.eu>
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
# module for preparing Income Statement and Balance Sheet
# 
#======================================================================

require "$form->{path}/arap.pl";
require "$form->{path}/rs.pl";

use SL::PE;
use SL::RP;
#kabai
use SL::GL;
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

# $locale->text('Balance Sheet')
# $locale->text('Income Statement')
# $locale->text('Trial Balance')
# $locale->text('AR Aging')
# $locale->text('AP Aging')
# $locale->text('Tax collected')
# $locale->text('Tax paid')
# $locale->text('Receipts')
# $locale->text('Payments')
# $locale->text('Project Transactions')
# $locale->text('Non-taxable Sales')
# $locale->text('Non-taxable Purchases')


sub report {

  %title = ( 'balance_sheet'	=> 'Balance Sheet',
             'income_statement'	=> 'Income Statement',
             'trial_balance'	=> 'Trial Balance',
	     'ar_aging'		=> 'AR Aging',
	     'ap_aging'		=> 'AP Aging',
	     'tax_collected'	=> 'Tax collected',
	     'tax_paid'		=> 'Tax paid',
	     'nontaxable_sales'	=> 'Non-taxable Sales',
	     'nontaxable_purchases' => 'Non-taxable Purchases',
	     'receipts'		=> 'Receipts',
	     'payments'		=> 'Payments',
	     'projects'		=> 'Project Transactions',
	     'project_report'	=> 'Project Report',
	   );
  
  $form->{title} = $locale->text($title{$form->{report}}). " " .$myconfig{company};
  $form->{showaccnumbers_true}=true;
  GL->transaction(\%myconfig, \%$form);
  $form->{selectaccno}="<option>";
 map  { $form->{selectaccno} .= "<option value='$_->{accno}--$_->{description}'>$_->{accno}--$_->{description}\n" } @{ $form->{all_accno2} };
	  
  $gifi = qq|
<tr>
  <th align=right VALIGN="top">|.$locale->text('Accounts').qq|</th>
  <td><input name=accounttype class=radio type=radio value=standard checked> |.$locale->text('Standard').qq|<BR>
   
      <input name=accounttype class=radio type=radio value=gifi> |.$locale->text('GIFI').qq|
  </td>
</tr>
|;
  
  # get departments
  $form->all_departments(\%myconfig);
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


  # get projects
  $form->all_projects(\%myconfig);
  $form->{selectproject} = "<option>\n";
  map { $form->{selectproject} .= qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n| } @{ $form->{all_projects} };

 
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
<input type=hidden name=sort value=transdate>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
      $department
|;
  if ($form->{report} eq "projects") {
    print qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Project').qq|</th>
	  <td colspan=3><select name=projectnumber>$form->{selectproject}</select></td>
	</tr>
        <input type=hidden name=nextsub value=generate_projects>
        <input type=hidden name=fx_transaction value=1>
        <tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=fromdate size=11 title="$myconfig{dateformat}" id=fromdate OnBlur="return dattrans('fromdate');" value=$form->{fromdate}></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}" id=todate OnBlur="return dattrans('todate');"></td>
	  <td><input name=l_wob class=checkbox type=checkbox value="Y">
	   &nbsp;|.$locale->text('Without Open Balance').qq|</td>
	</tr>
          <tr>
          <th align=right>|.$locale->text('Account From').qq|</th>
        <td><select name=accnofrom class="shrink" 
	onClick="if(document.forms[0].accnoto.value<document.forms[0].accnofrom.value){
	document.forms[0].accnoto.value=document.forms[0].accnofrom.value}">$form->{selectaccno}</select></td>
        </tr><tr>
          <th align=right>|.$locale->text('Account To').qq|</th>
          <td><select name=accnoto class="shrink"
	  onClick="if(document.forms[0].accnoto.value<document.forms[0].accnofrom.value){
	            document.forms[0].accnoto.value=document.forms[0].accnofrom.value}">$form->{selectaccno}</select></td>
        </tr>							
    </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right VALIGN="top" nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td VALIGN="top"><input name=l_heading class=checkbox type=checkbox 
           onClick="if (this.form.l_heading.checked) {this.form.l_headingo.checked=false}" value="Y" checked>
	   &nbsp;|.$locale->text('Heading').qq|<BR>
	  <input name=l_headingo class=checkbox type=checkbox
           onClick="if (this.form.l_headingo.checked) {this.form.l_heading.checked=false;
	   this.form.l_subtotal[1].checked=true;}" value="Y">
	   &nbsp;|.$locale->text('Only Heading').qq|</td>
          <TH ALIGN="right" VALIGN="top" NOWRAP>| . $locale->text('Location') . qq|</TH>
          <TD><INPUT NAME="l_subtotal" CLASS="radio" TYPE="radio" 
           onClick="this.form.l_headingo.checked=false}" 
	   VALUE="top">&nbsp;| . $locale->text('top') . qq|<BR>
            <INPUT NAME="l_subtotal" CLASS="radio" TYPE="radio" VALUE="bottom" CHECKED>&nbsp;| . $locale->text('bottom, as subtotal') . qq|
            </TD>
	</tr>
|;
  }

  if ($form->{report} eq "income_statement") {
    print qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Project').qq|</th>
	  <td colspan=3><select name=projectnumber>$form->{selectproject}</select></td>
	</tr>
        <input type=hidden name=nextsub value=generate_income_statement>
	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=fromdate size=11 title="$myconfig{dateformat}" id=fromdate OnBlur="return dattrans('fromdate');" value=$form->{fromdate}></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}" id=todate OnBlur="return dattrans('todate');"></td>
	</tr>
	<tr>
	  <th colspan=4>|.$locale->text('Compare to').qq|</th>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=comparefromdate size=11 title="$myconfig{dateformat}" id=comparefromdate OnBlur="return dattrans('comparefromdate');"></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=comparetodate size=11 title="$myconfig{dateformat}" id=comparetodate OnBlur="return dattrans('comparetodate');"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Decimalplaces').qq|</th>
	  <td><input name=decimalplaces size=3></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Method').qq|</th>
	  <td colspan=3><input name=method class=radio type=radio value=accrual checked>|.$locale->text('Accrual').qq|</td>
	</tr>

	<tr>
	  <th ROWSPAN="2" align=right VALIGN="top" nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td VALIGN="top"><input name=l_heading class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Heading').qq|</td>
          <TH ALIGN="right" VALIGN="top" NOWRAP>| . $locale->text('Location') . qq|</TH>
          <TD><INPUT NAME="l_subtotal" CLASS="radio" TYPE="radio" VALUE="top" CHECKED>&nbsp;| . $locale->text('top') . qq|<BR>
            <INPUT NAME="l_subtotal" CLASS="radio" TYPE="radio" VALUE="bottom">&nbsp;| . $locale->text('bottom, as subtotal') . qq|
            </TD>
          </TR>
        <TR><TD>
	  <input name=l_accno class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Account Number').qq|</td>
	</tr>
|;
  }


  if ($form->{report} eq "balance_sheet") {
    print qq|
        <input type=hidden name=nextsub value=generate_balance_sheet>
	<tr>
	  <th align=right>|.$locale->text('as at').qq|</th>
	  <td><input name=asofdate size=11 title="$myconfig{dateformat}" id=asofdate OnBlur="return dattrans('asofdate');" value=$form->{asofdate}></td>
	  <th align=right nowrap>|.$locale->text('Compare to').qq|</th>
	  <td><input name=compareasofdate size=11 title="$myconfig{dateformat}" id=compareasofdate OnBlur="return dattrans('compareasofdate');" ></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Decimalplaces').qq|</th>
	  <td><input name=decimalplaces size=3></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Method').qq|</th>
	  <td colspan=3><input name=method class=radio type=radio value=accrual checked>|.$locale->text('Accrual').qq|</td>
	</tr>

	<tr>
	  <th ROWSPAN="2" align=right VALIGN="top" nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td VALIGN="top"><input name=l_heading class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Heading').qq|</td>
          <TH ALIGN="right" VALIGN="top" NOWRAP>| . $locale->text('Location') . qq|</TH>
          <TD><INPUT NAME="l_subtotal" CLASS="radio" TYPE="radio" VALUE="top" CHECKED>&nbsp;| . $locale->text('top') . qq|<BR>
            <INPUT NAME="l_subtotal" CLASS="radio" TYPE="radio" VALUE="bottom">&nbsp;| . $locale->text('bottom, as subtotal') . qq|
            </TD>
          </TR>
        <TR><TD>
	  <input name=l_accno class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Account Number').qq|</td>
	</tr>
|;
  }


  if ($form->{report} eq "trial_balance") {
    print qq|
        <input type=hidden name=nextsub value=generate_trial_balance>
        <tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=fromdate size=11 title="$myconfig{dateformat}"  id=fromdate OnBlur="return dattrans('fromdate');"value=$form->{fromdate}></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}" id=todate OnBlur="return dattrans('todate');"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td><input name=l_heading class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Heading').qq|
	  <input name=l_subtotal class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('Subtotal').qq|
	  <input name=all_accounts class=checkbox type=checkbox value=Y>&nbsp;|.$locale->text('All Accounts').qq|</td>
	</tr>
|;
  }
  
  if ($form->{report} =~ /^tax_/) {
    $gifi = "";

    $form->{db} = ($form->{report} =~ /_collected/) ? "ar" : "ap";
    
    RP->get_taxaccounts(\%myconfig, \%$form);

    print qq|
        <input type=hidden name=nextsub value=generate_tax_report>
	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=fromdate size=11 title="$myconfig{dateformat}" id=fromdate OnBlur="return dattrans('fromdate');" value=$form->{fromdate}></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}" id=todate OnBlur="return dattrans('todate');"></td>
	</tr>|;
	if ($form->{report} eq "tax_paid") {
	  print qq|
	  <tr>
	    <th align=right>|.$locale->text('Fromordnumber').qq|</th>
	    <td><input name=fromordnumber size=11 value=$form->{fromordnumber}></td>
	    <th align=right>|.$locale->text('Toordnumber').qq|</th>
	    <td><input name=toordnumber size=11></td>
	  </tr>|;
	}
	print qq|
	<tr>
	  <th align=right>|.$locale->text('Report for').qq|</th>
	  <td colspan=3>
|;


#kabai
    $tax_text = $form->{db} eq "ar" ? "FIZ" : "VIS";
#kabai
    print qq|<select name="accno" class="required">
	     <option></option>
	    |;
    foreach $ref (@{ $form->{taxaccounts} }) {
    print qq|<option value="$ref->{accno}">$ref->{accno}--$ref->{description}</option>
	    | if $ref->{taxnumber} =~ /$tax_text/;
    }
    foreach $ref (@{ $form->{gifi_taxaccounts} }) {
      print qq|<option value="gifi_$ref->{accno}">$ref->{accno}--$ref->{description}</option>
	      | if $ref->{taxnumber} =~ /$tax_text/;
    }
    print   qq|<option value="nontaxable">|.$locale->text('nontaxable').qq|</option>
	     </select>
	     <input type=checkbox name=gl_included class=checkbox value=1 checked>|.$locale->text('General Ledger included');

    foreach $ref (@{ $form->{taxaccounts} }) {
    print qq|
    <input name="$ref->{accno}_description" type=hidden value="$ref->{description}">
    <input name="$ref->{accno}_rate" type=hidden value="$ref->{rate}">| if $ref->{taxnumber} =~ /$tax_text/; #kabai
    }
    foreach $ref (@{ $form->{gifi_taxaccounts} }) {
    print qq|
    <input name="gifi_$ref->{accno}_description" type=hidden value="$ref->{description}">
    <input name="gifi_$ref->{accno}_rate" type=hidden value="$ref->{rate}">| if $ref->{taxnumber} =~ /$tax_text/;
    }

  print qq|
    <input type=hidden name=db value=$form->{db}>
    <input type=hidden name=sort value=transdate>

	  </td>
	</tr>
|;




    print qq|
	  </td>
	</tr>
|;
print qq|
	<tr>
	  <th align=right>|.$locale->text('Method').qq|</th>
	  <td colspan=3><input name=method class=radio type=radio value=accrual checked>|.$locale->text('Accrual').qq|
	  &nbsp;<input name=method class=radio type=radio value=cash>|.$locale->text('Cash').qq|</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right>|.$locale->text('Include in Report').qq|</th>
	  <td>
	    <table>
	      <tr>
		<td><input name="l_id" class=checkbox type=checkbox value=Y></td>
		<td>|.$locale->text('ID').qq|</td>
		<td><input name="l_invnumber" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Invoice').qq|</td>|;
	if ($form->{db} eq 'ap') {
		print qq|
                <td><input name="l_ordnumber" class="checkbox" type="checkbox" value="Y" checked></td>
                <td>|.$locale->text('Order Number').qq|</td>|;
		}
	print qq|
		<td><input name="l_transdate" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Date').qq|</td>
		<td><input name="l_notes" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Notes').qq|</td>
	      </tr>
	      <tr>
		<td><input name="l_name" class=checkbox type=checkbox value=Y checked></td>
		<td>|;
		
  if ($form->{db} eq 'ar') {
    print $locale->text('Customer');
  }
  if ($form->{db} eq 'ap') {
    print $locale->text('Vendor');
  }
#taxnumber by Sipos
  print qq|</td>
		<td><input name="l_taxnumber" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Tax number').qq|</td>

		<td><input name="l_netamount" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Amount').qq|</td>
		
		<td><input name="l_tax" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Tax').qq|</td>
		
                <td><input name="l_total" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Total').qq|</td>

                <td><input name="l_taxrate" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Tax rate').qq|</td>

	      </tr>|;
	    if($form->{report} eq "tax_paid") {
	      print qq|
	       <tr>
                <td><input name="l_link" class=checkbox type=checkbox value=Y></td>
		<td>|.$locale->text('Invest/Asset').qq|</td>

                <td><input name="l_eva" class=checkbox type=checkbox value=Y></td>
		<td>|.$locale->text('EVA').qq|</td>
	       </tr>
	      |;
	    }
	      print qq|
	      <tr>
	        <td><input name="l_subtotal" class=checkbox type=checkbox value=Y></td>
		<td>|.$locale->text('Subtotal').qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;

  }

  
  if ($form->{report} =~ /^nontaxable_/) {
    $gifi = "";

    $form->{db} = ($form->{report} =~ /_sales/) ? "ar" : "ap";
    
    print qq|
        <input type=hidden name=nextsub value=generate_tax_report>

        <input type=hidden name=db value=$form->{db}>
        <input type=hidden name=sort value=transdate>
        <input type=hidden name=report value=$form->{report}>

	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=fromdate size=11 title="$myconfig{dateformat}"  id=fromdate OnBlur="return dattrans('fromdate');"value=$form->{fromdate}></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}" id=todate OnBlur="return dattrans('todate');"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Method').qq|</th>
	  <td colspan=3><input name=method class=radio type=radio value=accrual checked>|.$locale->text('Accrual').qq|
	  &nbsp;<input name=method class=radio type=radio value=cash>|.$locale->text('Cash').qq|</td>
	</tr>
        <tr>
	  <th align=right>|.$locale->text('Include in Report').qq|</th>
	  <td colspan=3>
	    <table>
	      <tr>
		<td><input name="l_id" class=checkbox type=checkbox value=Y></td>
		<td>|.$locale->text('ID').qq|</td>
		<td><input name="l_invnumber" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Invoice').qq|</td>
		<td><input name="l_transdate" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Date').qq|</td>
	      </tr>
	      <tr>
		<td><input name="l_name" class=checkbox type=checkbox value=Y checked></td>
		<td>|;
		
  if ($form->{db} eq 'ar') {
    print $locale->text('Customer');
  }
  if ($form->{db} eq 'ap') {
    print $locale->text('Vendor');
  }
  
  print qq|</td>
                <td><input name="l_netamount" class=checkbox type=checkbox value=Y checked></td>
		<td>|.$locale->text('Amount').qq|</td>
	      </tr>
	      <tr>
	        <td><input name="l_subtotal" class=checkbox type=checkbox value=Y></td>
		<td>|.$locale->text('Subtotal').qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;

  }



  if (($form->{report} eq "ar_aging") || ($form->{report} eq "ap_aging")) {
    $gifi = "";

    if ($form->{report} eq 'ar_aging') {
      $label = $locale->text('Customer');
      $form->{vc} = 'customer';
    } else {
      $label = $locale->text('Vendor');
      $form->{vc} = 'vendor';
    }
      
    $nextsub = "generate_$form->{report}";
    
    # setup vc selection
    $form->all_vc(\%myconfig, $form->{vc}, ($form->{vc} eq 'customer') ? "AR" : "AP");

    map { $vc .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| } @{ $form->{"all_$form->{vc}"} };
    
    $vc = ($vc) ? qq|<select name=$form->{vc}><option>\n$vc</select>| : qq|<input name=$form->{vc} size=35>|;
    
    print qq|
	<tr>
	  <th align=right>|.$locale->text($label).qq|</th>
	  <td>$vc</td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}" id=todate OnBlur="return dattrans('todate');"></td>
	</tr>
        <input type=hidden name=type value=statement>
        <input type=hidden name=format value="$myconfig{prformat}">
	<input type=hidden name=media value="$myconfig{prmedia}">

	<input type=hidden name=nextsub value=$nextsub>
	<input type=hidden name=action value=$nextsub>
	<tr>
	  <th></th>
	  <td><input name=summary type=radio class=radio value=1> |.$locale->text('Summary').qq|
	  <input name=summary type=radio class=radio value=0 checked> |.$locale->text('Detail').qq|
	  </td>
	</tr>
|;
  }

# above action can be removed if there is more than one input field


  if ($form->{report} =~ /(receipts|payments)$/) {
    $gifi = "";

    $form->{db} = ($form->{report} =~ /payments$/) ? "ap" : "ar";

    RP->paymentaccounts2(\%myconfig, \%$form);

#kabai    $selection = "<option>\n";
    foreach $ref (@{ $form->{PR} }) {
      $paymentaccounts .= "$ref->{accno} ";
      $selection .= "<option>$ref->{accno}--$ref->{description}\n";
    }
    
    chop $paymentaccounts;

    print qq|
        <input type=hidden name=nextsub value=list_payments>
        <input type=hidden name=cash value="$form->{cash}">
        <tr>
	  <th align=right nowrap>|.$locale->text('Account').qq|</th>
          <td colspan=3><select name=account>$selection</select>
	    <input type=hidden name=paymentaccounts value="$paymentaccounts">
	  </td>
	</tr>
        <tr>
	  <th align=right nowrap>|.$locale->text('Description').qq|</th>
          <td colspan=3><input name=description size=35></td>
	</tr>
        <tr>
	  <th align=right nowrap>|.$locale->text('Source').qq|</th>
          <td colspan=3><input name=source></td>
	</tr>
        <tr>
	  <th align=right nowrap>|.$locale->text('Memo').qq|</th>
          <td colspan=3><input name=memo size=30></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=fromdate size=11 title="$myconfig{dateformat}" id=fromdate OnBlur="return dattrans('fromdate');" value=$form->{fromdate}></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}" id=todate OnBlur="return dattrans('todate');"></td>
	</tr>
        <tr>
	  <td align=right><input type=checkbox style=checkbox name=fx_transaction value=1 checked></td>
	  <td colspan=3>|.$locale->text('Include Exchangerate Difference').qq|</td>
	</tr>
        <tr>
	  <td align=right><input name=l_subtotal class=checkbox type=checkbox value=Y></td>
	  <td align=left colspan=3>|.$locale->text('Subtotal').qq|</th>
	</tr>
	  
	  <input type=hidden name=db value=$form->{db}>
	  <input type=hidden name=sort value=transdate>
|;

  }

  if ($form->{report} eq "project_report") {
    print qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Project Number').qq|</th>
	  <td colspan=3><input name=projectnumber0>&nbsp;<select name=projectnumber>$form->{selectproject}</select></td>
	</tr>
        <input type=hidden name=sort value=projectnumber>
        <input type=hidden name=nextsub value=project_report>
        <input type=hidden name=fx_transaction value=1>
        <tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=fromdate size=11 title="$myconfig{dateformat}" id=fromdate OnBlur="return dattrans('fromdate');" value=$form->{fromdate}></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}" id=todate OnBlur="return dattrans('todate');"></td>
	</tr>
    </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  &nbsp;
	</tr>
	<tr>
	  <th align=left colspan=9 nowrap>|.$locale->text('Include in Report').qq|</th>
	</tr>
	<tr>
		<td align=right><input name="l_projectnumber" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Project Number').qq|</td>
		<td align=right><input name="l_transdate" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Transdate').qq|</td>
		<td align=right><input name="l_invnumber" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Invoice Number').qq|</td>
	      </tr>
	      <tr>
		<td align=right><input name="l_customer" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Customer').qq|</td>
		<td align=right><input name="l_netincome" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Net Income').qq|</td>
		<td align=right><input name="l_incomeaccno" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Income Account').qq|</td>
	      </tr>
	      <tr>
		<td align=right><input name="l_vendor" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Vendor').qq|</td>
		<td align=right><input name="l_netcost" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Net Cost').qq|</td>
		<td align=right><input name="l_costaccno" class=checkbox type=checkbox value=Y></td>
		<td nowrap>|.$locale->text('Cost Account').qq|</td>
	      </tr>
	      <tr>
		<td align=right><input name="l_profit" class=checkbox type=checkbox value=Y checked></td>
		<td nowrap>|.$locale->text('Profit').qq|</td>
		<td align=right><input name="l_margin" class=checkbox type=checkbox value=Y checked></td>
		<td colspan=5 nowrap>|.$locale->text('Margin').qq|</td>
	      </tr>
	      <tr>
                <td align=right><input name="l_subtotal" class=checkbox type=checkbox
                onClick="if (this.form.l_subtotal.checked) {this.form.l_osubtotal.checked=false}" value=Y checked></td>
                <td nowrap>|.$locale->text('Subtotal').qq|</td>
                <td align=right><input name="l_osubtotal" class=checkbox type=checkbox
                onClick="if (this.form.l_osubtotal.checked) {this.form.l_subtotal.checked=false;}" value=Y></td>
                <td colspan=5 nowrap>|.$locale->text('Only subtotal').qq|</td>
              </tr>
|;
  }
  print qq|$gifi| if $form->{report} ne "project_report";
  print qq|

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
<input type=hidden name=sessionid value=$form->{sessionid}>

<input type=submit class=submit name=action onclick="return checkform()" value="|.$locale->text('Continue').qq|">

</form>

</body>
</html>
|;
}


sub continue {&{$form->{nextsub}} };


sub generate_income_statement {

  $form->{padding} = "&nbsp;&nbsp;";
  $form->{bold} = "<b>";
  $form->{endbold} = "</b>";
  $form->{br} = "<br>";
  
  RP->income_statement(\%myconfig, \%$form);

  ($form->{department}) = split /--/, $form->{department};
  ($form->{projectnumber}) = split /--/, $form->{projectnumber};
  
  $form->{period} = $locale->date(\%myconfig, $form->current_date(\%myconfig), 1);
  $form->{todate} = $form->current_date(\%myconfig) unless $form->{todate};

  # if there are any dates construct a where
  if ($form->{fromdate} || $form->{todate}) {
    
    unless ($form->{todate}) {
      $form->{todate} = $form->current_date(\%myconfig);
    }

    $longtodate = $locale->date(\%myconfig, $form->{todate}, 1);
    $shorttodate = $locale->date(\%myconfig, $form->{todate}, 0);
    
    $longfromdate = $locale->date(\%myconfig, $form->{fromdate}, 1);
    $shortfromdate = $locale->date(\%myconfig, $form->{fromdate}, 0);
    
    $form->{this_period} = "$shortfromdate<br>\n$shorttodate";
    $form->{period} = $locale->text('for Period').qq|<br>\n$longfromdate |.$locale->text('to').qq| $longtodate|;
  }

  if ($form->{comparefromdate} || $form->{comparetodate}) {
    $longcomparefromdate = $locale->date(\%myconfig, $form->{comparefromdate}, 1);
    $shortcomparefromdate = $locale->date(\%myconfig, $form->{comparefromdate}, 0);
    
    $longcomparetodate = $locale->date(\%myconfig, $form->{comparetodate}, 1);
    $shortcomparetodate = $locale->date(\%myconfig, $form->{comparetodate}, 0);
    
    $form->{last_period} = "$shortcomparefromdate<br>\n$shortcomparetodate";
    $form->{period} .= "<br>\n$longcomparefromdate ".$locale->text('to').qq| $longcomparetodate|;
  }

  # setup variables for the form
  @a = qw(company address businessnumber);
  map { $form->{$_} = $myconfig{$_} } @a;
  $form->{address} =~ s/\\n/<br>/g;

  $form->{templates} = $myconfig{templates};

  $form->{IN} = "income_statement.html";
  
#  $form->parse_template;
  $form->old_parse_template;

}


sub generate_balance_sheet {

  $form->{padding} = "&nbsp;&nbsp;";
  $form->{bold} = "<b>";
  $form->{endbold} = "</b>";
  $form->{br} = "<br>";
  
  RP->balance_sheet(\%myconfig, \%$form);

  $form->{asofdate} = $form->current_date(\%myconfig) unless $form->{asofdate};
  $form->{period} = $locale->date(\%myconfig, $form->current_date(\%myconfig), 1);
  
  ($form->{department}) = split /--/, $form->{department};
  
  # define Current Earnings account
  $padding = ($form->{l_heading}) ? $form->{padding} : "";
  push(@{$form->{equity_account}}, $padding.$locale->text('Current Earnings'));

  $form->{this_period} = $locale->date(\%myconfig, $form->{asofdate}, 0);
  $form->{last_period} = $locale->date(\%myconfig, $form->{compareasofdate}, 0);

  $form->{IN} = "balance_sheet.html";

  # setup company variables for the form
  map { $form->{$_} = $myconfig{$_} } (qw(company address businessnumber nativecurr));
  $form->{address} =~ s/\\n/<br>/g;

  $form->{templates} = $myconfig{templates};
	  
#  $form->parse_template;
  $form->old_parse_template;

}


sub generate_projects {
#KS
  $form->{l_heading}='Y' if ($form->{l_headingo} eq 'Y');
#$form->debug2; 
  
  $form->{nextsub} = "generate_projects";
  $form->{title} = $locale->text('Project Transactions'). " " .$myconfig{company}. "&nbsp;&nbsp;&nbsp;&nbsp;" .$locale->text('Printed'). ": " .$form->current_date(\%myconfig);
  RP->trial_balance(\%myconfig, \%$form);
  
  &list_accounts;

}


# Antonio Gallardo
#
# D.S. Feb 16, 2001
# included links to display transactions for period entered
# added headers and subtotals
#
sub generate_trial_balance {
  # get for each account initial balance, debits and credits
  RP->trial_balance(\%myconfig, \%$form);

  $form->{nextsub} = "generate_trial_balance";
  $form->{title} = $locale->text('Trial Balance');
  &list_accounts;

}


sub list_accounts {
  $title = $form->escape($form->{title});

  if ($form->{department}) {
    ($department) = split /--/, $form->{department};
    $options = $locale->text('Department')." : $department<br>";
    $department = $form->escape($form->{department});
  }
  if ($form->{projectnumber}) {
    ($projectnumber) = split /--/, $form->{projectnumber};
    $options .= $locale->text('Project Number')." : $projectnumber<br>";
    $projectnumber = $form->escape($form->{projectnumber});
  }

  # if there are any dates
  if ($form->{fromdate} || $form->{todate}) {
    if ($form->{fromdate}) {
      $fromdate = $locale->date(\%myconfig, $form->{fromdate}, 1);
    }
    if ($form->{todate}) {
      $todate = $locale->date(\%myconfig, $form->{todate}, 1);
    }
    
    $form->{period} = "$fromdate - $todate";
  } else {
    $form->{period} = $locale->date(\%myconfig, $form->current_date(\%myconfig), 1);

  }
  $options .= $form->{period};
  if ($form->{accnofrom} || $form->{accnoto}) {
    $options .=qq|<br>$form->{accnofrom} - $form->{accnoto}|;  
  }
  @column_index = qw(accno description begbalance debit credit endbalance);

  $column_header{accno} = qq|<th class=listheading>|.$locale->text('Account').qq|</th>|;
  $column_header{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_header{debit} = qq|<th class=listheading>|.$locale->text('Debit').qq|</th>|;
  $column_header{credit} = qq|<th class=listheading>|.$locale->text('Credit').qq|</th>|;
  $column_header{begbalance} = qq|<th class=listheading>|.$locale->text('Balance').qq|</th>| if (!$form->{l_wob});
  $column_header{endbalance} = qq|<th class=listheading>|.$locale->text('Balance').qq|</th>|;


  if ($form->{accounttype} eq 'gifi') {
    $column_header{accno} = qq|<th class=listheading>|.$locale->text('GIFI').qq|</th>|;
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
    <td>$options</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
       <thead>    
	<tr>|;

  map { print "$column_header{$_}\n" } @column_index;

  print qq|
        </tr>
       </thead>
       <tfoot>
        <tr><td>&nbsp;
        </td></tr>
       </tfoot>
       <tbody>
|;

  # sort the whole thing by account numbers and display
	if ($form->{l_subtotal} eq "bottom") {
		foreach $ref (sort {
                	$ref->{balance}=0 if $form->{l_wob};
			($a->{accno} =~ /^$b->{accno}/) || ($b->{accno} =~ /^$a->{accno}/) ?
				(length($b->{accno}) <=> length ($a->{accno})) :
				($a->{accno} cmp $b->{accno})
			} @{$form->{TB}}) {
			$description = $form->escape($ref->{description});
                        $href = qq|ca.pl?path=$form->{path}&action=list_transactions&accounttype=$form->{accounttype}&login=$form->{login}&sessionid=$form->{sessionid}&fromdate=$form->{fromdate}&todate=$form->{todate}&sort=transdate&l_headingo=$form->{l_headingo}&l_heading=$form->{l_heading}&l_subtotal=$form->{l_subtotal}&department=$department&projectnumber=$projectnumber&project_id=$form->{project_id}&title=$title&nextsub=$form->{nextsub}&fx_transaction=$form->{fx_transaction}&l_wob=$form->{l_wob}|;
			if ($form->{accounttype} eq 'gifi') {
				$href .= "&gifi_accno=$ref->{accno}&gifi_description=$description";
				$na = $locale->text('N/A');
				map { $ref->{$_} = $na } qw(accno description) unless $ref->{accno};
				}
			else {
				$href .= "&accno=$ref->{accno}&description=$description";
				}
			$ref->{balance}=0 if $form->{l_wob};
			$ml = ($ref->{category} =~ /(A|E)/) ? -1 : 1;
			$debit = $form->format_amount(\%myconfig, $ref->{debit}, 2);
			$credit = $form->format_amount(\%myconfig, $ref->{credit}, 2);
			$begbalance = $form->format_amount(\%myconfig, $ref->{balance} * $ml, 2);
			$ref->{amount} = $ref->{credit} - $ref->{debit} if $ref->{charttype} eq "H";

			$endbalance = $form->format_amount(\%myconfig, ($ref->{balance} + $ref->{amount}) * $ml, 2);
			if ($ref->{charttype} eq "H") {
				next unless ($form->{l_heading} && ($begbalance || $endbalance || $debit || $credit));
				$column_data{accno} = "<th align='left'>$ref->{accno}</th>";
				$column_data{description} = "<th class=listsubtotal>$ref->{description}</th>";
				$column_data{begbalance} = "<th align=right class=listsubtotal>$begbalance</th>" if !$form->{l_wob};
				$column_data{endbalance} = "<th align=right class=listsubtotal>$endbalance</th>";
				$column_data{debit} = "<th align=right class=listsubtotal>$debit</th>";
				$column_data{credit} = "<th align=right class=listsubtotal>$credit</th>";
                                    if ($ref->{accno}*1 <= 4) {
                                        $mp = $ref->{accno} == 4 ? -1 : 1;   
                                        $lo_begbalance += $form->parse_amount(\%myconfig, $begbalance)*$mp;
                                        $lo_endbalance += $form->parse_amount(\%myconfig, $endbalance)*$mp;
                                        $lo_debit += $form->parse_amount(\%myconfig, $debit);
                                        $lo_credit += $form->parse_amount(\%myconfig, $credit);
                                    } elsif($ref->{accno}*1 > 4 && $ref->{accno}*1 <= 9){
                                        $mp = $ref->{accno} == 9 ? 1 : -1; 
                                        $hi_begbalance += $form->parse_amount(\%myconfig, $begbalance)*$mp;
                                        $hi_endbalance += $form->parse_amount(\%myconfig, $endbalance)*$mp;
                                        $hi_debit += $form->parse_amount(\%myconfig, $debit);
                                        $hi_credit += $form->parse_amount(\%myconfig, $credit);
                                    }    
				print qq|  <tr class=listsubtotal>|;
				}
			elsif ($ref->{charttype} eq "A") {
				$column_data{accno} = "<td><a href=$href>$ref->{accno}</a></td>";
				$column_data{description} = "<td>$ref->{description}</td>";
				$column_data{debit} = "<td align=right>$debit</td>";
				$column_data{credit} = "<td align=right>$credit</td>";
				$column_data{begbalance} = "<td align=right>$begbalance</td>" if !$form->{l_wob};
				$column_data{endbalance} = "<td align=right>$endbalance</td>";
				$totaldebit += $ref->{debit};
				$totalcredit += $ref->{credit};
				$i++;
				$i %= 2;
				print qq|  <tr class=listrow$i>| if (!$form->{l_headingo});

				}
			   if (!$form->{l_headingo} || $ref->{charttype} eq "H"){map { print "    $column_data{$_}\n" } @column_index;
			    print qq|  </tr>

    |;
			 }		    
    			}
		}
	elsif ($form->{l_subtotal} eq "top") {
		foreach $ref (sort { $a->{accno} cmp $b->{accno} } @{ $form->{TB} }) {
			$description = $form->escape($ref->{description});
			$href = qq|ca.pl?path=$form->{path}&action=list_transactions&accounttype=$form->{accounttype}&login=$form->{login}&sessionid=$form->{sessionid}&fromdate=$form->{fromdate}&todate=$form->{todate}&sort=transdate&l_heading=$form->{l_heading}&l_subtotal=$form->{l_subtotal}&department=$department&projectnumber=$projectnumber&project_id=$form->{project_id}&title=$title&nextsub=$form->{nextsub}&fx_transaction=$form->{fx_transaction}|;
			if ($form->{accounttype} eq 'gifi') {
				$href .= "&gifi_accno=$ref->{accno}&gifi_description=$description";
				$na = $locale->text('N/A');
				map { $ref->{$_} = $na } qw(accno description) unless $ref->{accno};
				}
			else {
				$href .= "&accno=$ref->{accno}&description=$description";
				}
			$ml = ($ref->{category} =~ /(A|E)/) ? -1 : 1;
			$debit = $form->format_amount(\%myconfig, $ref->{debit}, 2);
			$credit = $form->format_amount(\%myconfig, $ref->{credit}, 2);
			$begbalance = $form->format_amount(\%myconfig, $ref->{balance} * $ml, 2);
			$endbalance = $form->format_amount(\%myconfig, ($ref->{balance} + $ref->{amount}) * $ml, 2);
			if ($ref->{charttype} eq "H") {
				next unless ($form->{l_heading} && ($begbalance || $endbalance || $debit || $credit));
				map { $column_data{$_} = "<th>&nbsp;</th>" } qw(accno debit credit begbalance endbalance) if !$form->{l_wob};
				map { $column_data{$_} = "<th>&nbsp;</th>" } qw(accno debit credit endbalance) if $form->{l_wob};
				$column_data{description} = "<th class=listheading>$ref->{description}</th>";
				print qq|  <tr class=listheading>
|;
				}
			elsif ($ref->{charttype} eq "A") {
				$column_data{accno} = "<td><a href=$href>$ref->{accno}</a></td>";
				$column_data{description} = "<td>$ref->{description}</td>";
				$column_data{debit} = "<td align=right>$debit</td>";
				$column_data{credit} = "<td align=right>$credit</td>";
				$column_data{begbalance} = "<td align=right>$begbalance</td>" if !$form->{l_wob};

				$column_data{endbalance} = "<td align=right>$endbalance</td>";
				$totaldebit += $ref->{debit};
				$totalcredit += $ref->{credit};
				$i++;
				$i %= 2;
				print qq|  <tr class=listrow$i>
|;
				}
			map { print "    $column_data{$_}\n" } @column_index;
			print qq|  </tr>
|;
			}
		}

  $totaldebit = $form->format_amount(\%myconfig, $totaldebit, 2, "&nbsp;");
  $totalcredit = $form->format_amount(\%myconfig, $totalcredit, 2, "&nbsp;");

  if ($form->{l_wob}){
      map { $column_data{$_} = "<th>&nbsp;</th>" } qw(accno description endbalance);
  }else{
      map { $column_data{$_} = "<th>&nbsp;</th>" } qw(accno description begbalance endbalance);
  } 
  $column_data{debit} = qq|<th align=right class=listtotal>$totaldebit</th>|;
  $column_data{credit} = qq|<th align=right class=listtotal>$totalcredit</th>|;
  
  print qq|
        <tr class=listtotal>
|;

  map { print "$column_data{$_}\n" } @column_index;

#hi, lo
  print qq|
	</tr>|;
 if($lo_debit || $lo_credit || $hi_debit || $hi_credit){ 
  print qq|<tr><td>&nbsp;</td></tr>|;
  $column_data{accno} = qq|<th align=left class=listsubtotal>1-4</th>|;
  $column_data{description} = qq|<th align=left class=listsubtotal>|.$locale->text('Summary').qq|</th>|;
  $column_data{begbalance} = qq|<th align=right class=listsubtotal>|.$form->format_amount(\%myconfig, $lo_begbalance,2, "&nbsp;").qq|</th>|;  
  $column_data{debit} = qq|<th align=right class=listsubtotal>|.$form->format_amount(\%myconfig, $lo_debit,2, "&nbsp;").qq|</th>|; 
  $column_data{credit} = qq|<th align=right class=listsubtotal>|.$form->format_amount(\%myconfig,$lo_credit,2, "&nbsp;").qq|</th>|; 
  $column_data{endbalance} = qq|<th align=right class=listsubtotal>|.$form->format_amount(\%myconfig,$lo_endbalance,2, "&nbsp;").qq|</th>|; 
  print qq|
        <tr class=listtotal>
|;

  map { print "$column_data{$_}\n" } @column_index;
  print qq|
	</tr>|;
  $column_data{accno} = qq|<th align=left class=listsubtotal>5-9</th>|;
  $column_data{description} = qq|<th align=left class=listsubtotal>|.$locale->text('Summary').qq|</th>|;
  $column_data{begbalance} = qq|<th align=right class=listsubtotal>|.$form->format_amount(\%myconfig, $hi_begbalance,2, "&nbsp;").qq|</th>|;  
  $column_data{debit} = qq|<th align=right class=listsubtotal>|.$form->format_amount(\%myconfig, $hi_debit,2, "&nbsp;").qq|</th>|; 
  $column_data{credit} = qq|<th align=right class=listsubtotal>|.$form->format_amount(\%myconfig,$hi_credit,2, "&nbsp;").qq|</th>|; 
  $column_data{endbalance} = qq|<th align=right class=listsubtotal>|.$form->format_amount(\%myconfig,$hi_endbalance,2, "&nbsp;").qq|</th>|; 
  print qq|
        <tr class=listtotal>
|;

  map { print "$column_data{$_}\n" } @column_index;
#hi, lo
 }#*_debit, _credit
  print qq|
	</tr>

       </tbody>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

</body>
</html>
|;

}


sub generate_ar_aging {

  # split customer
  ($form->{customer}) = split(/--/, $form->{customer});
  $customer = $form->escape($form->{customer},1);
  $title = $form->escape($form->{title},1);
  $media = $form->escape($form->{media},1);

  $form->{ct} = "customer";
  $form->{arap} = "ar";

  $form->{callback} = qq|$form->{script}?path=$form->{path}&action=generate_ar_aging&login=$form->{login}&sessionid=$form->{sessionid}&todate=$form->{todate}&customer=$customer&title=$title&type=$form->{type}&format=$form->{format}&media=$media|;

  RP->aging(\%myconfig, \%$form);
  &aging;
  
}


sub generate_ap_aging {
  
  # split vendor
  ($form->{vendor}) = split(/--/, $form->{vendor});
  $vendor = $form->escape($form->{vendor},1);
  $title = $form->escape($form->{title},1);
  $media = $form->escape($form->{media},1);

  $form->{ct} = "vendor";
  $form->{arap} = "ap";
  
  $form->{callback} = qq|$form->{script}?path=$form->{path}&action=generate_ap_aging&login=$form->{login}&sessionid=$form->{sessionid}&todate=$form->{todate}&vendor=$vendor&title=$title&type=$form->{type}&format=$form->{format}&media=$media|;

  RP->aging(\%myconfig, \%$form);
  &aging;
  
}


sub aging {
# c1 c90 c180 c365 categories by sipi
  $form->header;
  
  $column_header{statement} = qq|<th class=listheading width=1%>&nbsp;</th>|;
  $column_header{ct} = qq|<th class=listheading width=30%>|.$locale->text(ucfirst $form->{ct}).qq|</th>|;
  $column_header{language} = qq|<th class=listheading>|.$locale->text('Template').qq|</th>|;
  $column_header{invnumber} = qq|<th class=listheading>|.$locale->text('Invoice').qq|</th>|;
  $column_header{transdate} = qq|<th class=listheading>|.$locale->text('Date').qq|</th>|;
  $column_header{duedate} = qq|<th class=listheading>|.$locale->text('Due Date').qq|</th>|;
  $column_header{c1} = qq|<th class=listheading width=10%>|.$locale->text('1-10').qq|</th>|;
  $column_header{c10} = qq|<th class=listheading width=10%>|.$locale->text('11-30').qq|</th>|;
  $column_header{c30} = qq|<th class=listheading width=10%>|.$locale->text('31-60').qq|</th>|;
  $column_header{c60} = qq|<th class=listheading width=10%>|.$locale->text('61-90').qq|</th>|;
  $column_header{c90} = qq|<th class=listheading width=10%>|.$locale->text('91-180').qq|</th>|;
  $column_header{c180} = qq|<th class=listheading width=10%>|.$locale->text('181-365').qq|</th>|;
  $column_header{c365} = qq|<th class=listheading width=10%>|.$locale->text('365+').qq|</th>|;
  
  @column_index = qw(statement ct);

  if (@{ $form->{all_language} } && $form->{arap} eq 'ar') {
    push @column_index, "language";
    $form->{selectlanguage} = qq|<option>\n|;

    map { $form->{selectlanguage} .= qq|<option value="$_->{code}">$_->{description}\n| } @{ $form->{all_language} };
  }
  
  if ($form->{summary}) {
    push @column_index, qw(c1 c10 c30 c60 c90 c180 c365);
  } else {
    push @column_index, qw(invnumber transdate duedate c1 c10 c30 c60 c90 c180 c365);
  }

  if ($form->{department}) {
      $option .= "\n<br>" if $option;
      ($department) = split /--/, $form->{department};
      $option .= $locale->text('Department')." : $department";
      $department = $form->escape($form->{department},1);
      $form->{callback} .= "&department=$department";
  }
    
  if ($form->{arap} eq 'ar') {
    if ($form->{customer}) {
      $option .= "\n<br>" if $option;
      $option .= $form->{customer};
    }
  }
  if ($form->{arap} eq 'ap') {
    shift @column_index;
    if ($form->{vendor}) {
      $option .= "\n<br>" if $option;
      $option .= $form->{vendor};
    }
  }

  $todate = $locale->date(\%myconfig, $form->{todate}, 1);
  $option .= "\n<br>" if $option;
  $option .= $locale->text('for Period')." ".$locale->text('to')." $todate";

  print qq|
<body>

<form method=post action=$form->{script}>

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


  $ctid = 0;
  $i = 0;
  $k = 0;
  $l = $#{ $form->{AG} };

  foreach $ref (@{ $form->{AG} }) {

    $k++;
    
    if ($ctid != $ref->{ctid}) {

      $i++;

      $column_data{ct} = qq|<td>$ref->{name}</td>|;
      
      if ($form->{selectlanguage}) {
	$form->{"selectlanguage_$i"} = $form->{selectlanguage};
	$form->{"selectlanguage_$i"} =~ s/(<option value="\Q$ref->{language_code}\E")/$1 selected/;
	$column_data{language} = qq|<td><select name="language_code_$i">$form->{"selectlanguage_$i"}</select></td>|;
      }
      
      $column_data{statement} = qq|<td><input name="statement_$i" type=checkbox class=checkbox value=1 $ref->{checked}>
      <input type=hidden name="$form->{ct}_id_$i" value=$ref->{ctid}>
      </td>|;

    }
	    
    $ctid = $ref->{ctid};

     $c1subtotal += $ref->{c1};
     $c10subtotal += $ref->{c10};
     $c30subtotal += $ref->{c30};
     $c60subtotal += $ref->{c60};
     $c90subtotal += $ref->{c90};
     $c180subtotal += $ref->{c180};
     $c365subtotal += $ref->{c365};
 
     $c1total += $ref->{c1};
     $c10total += $ref->{c10};
     $c30total += $ref->{c30};
     $c60total += $ref->{c60};
     $c90total += $ref->{c90};
     $c180total += $ref->{c180};
     $c365total += $ref->{c365};
 
     $ref->{c1} = $form->format_amount(\%myconfig, $ref->{c1}, 2, "&nbsp;");
     $ref->{c10} = $form->format_amount(\%myconfig, $ref->{c10}, 2, "&nbsp;");
     $ref->{c30} = $form->format_amount(\%myconfig, $ref->{c30}, 2, "&nbsp;");
     $ref->{c60} = $form->format_amount(\%myconfig, $ref->{c60}, 2, "&nbsp;");
     $ref->{c90} = $form->format_amount(\%myconfig, $ref->{c90}, 2, "&nbsp;");
     $ref->{c180} = $form->format_amount(\%myconfig, $ref->{c180}, 2, "&nbsp;");
     $ref->{c365} = $form->format_amount(\%myconfig, $ref->{c365}, 2, "&nbsp;");
 
     $href = qq|$ref->{module}.pl?path=$form->{path}&action=edit&id=$ref->{id}&login=$form->{login}&sessionid=$form->{sessionid}&callback=|.$form->escape($form->{callback});
     
     $column_data{invnumber} = qq|<td><a href=$href>$ref->{invnumber}</a></td>|;
     map { $column_data{$_} = qq|<td>$ref->{$_}</td>| } qw(transdate duedate);
     map { $column_data{$_} = qq|<td align=right>$ref->{$_}</td>| } qw(c1 c10 c30 c60 c90 c180 c365);

    
    if (!$form->{summary}) {

      $j++; $j %= 2;
      print qq|
        <tr class=listrow$j>
|;

      map { print "$column_data{$_}\n" } @column_index;

      print qq|
        </tr>
|;

      map { $column_data{$_} = qq|<td>&nbsp;</td>| } qw(ct statement language);
      
    }
   
    # print subtotal
    $nextid = ($k <= $l) ? $form->{AG}->[$k]->{ctid} : 0;
     if ($ctid != $nextid) {
 
       $c1subtotal = $form->format_amount(\%myconfig, $c1subtotal, 2, "&nbsp");
       $c10subtotal = $form->format_amount(\%myconfig, $c10subtotal, 2, "&nbsp");
       $c30subtotal = $form->format_amount(\%myconfig, $c30subtotal, 2, "&nbsp");
       $c60subtotal = $form->format_amount(\%myconfig, $c60subtotal, 2, "&nbsp");
       $c90subtotal = $form->format_amount(\%myconfig, $c90subtotal, 2, "&nbsp");
       $c180subtotal = $form->format_amount(\%myconfig, $c180subtotal, 2, "&nbsp");
       $c365subtotal = $form->format_amount(\%myconfig, $c365subtotal, 2, "&nbsp");
       
       if ($form->{summary}) {
 	$column_data{c1} = qq|<td align=right>$c1subtotal</th>|;
	$column_data{c10} = qq|<td align=right>$c10subtotal</th>|;
 	$column_data{c30} = qq|<td align=right>$c30subtotal</th>|;
 	$column_data{c60} = qq|<td align=right>$c60subtotal</th>|;
 	$column_data{c90} = qq|<td align=right>$c90subtotal</th>|;
	$column_data{c180} = qq|<td align=right>$c180subtotal</th>|;
	$column_data{c365} = qq|<td align=right>$c365subtotal</th>|;

	$j++; $j %= 2;
	print qq|
	<tr class=listrow$j>
|;

        map { print "$column_data{$_}\n" } @column_index;

	print qq|
	</tr>
|;

      } else {

	map { $column_data{$_} = qq|<th>&nbsp;</th>| } @column_index;

 	$column_data{c1} = qq|<th class=listsubtotal align=right>$c1subtotal</th>|;
 	$column_data{c10} = qq|<th class=listsubtotal align=right>$c10subtotal</th>|;
 	$column_data{c30} = qq|<th class=listsubtotal align=right>$c30subtotal</th>|;
 	$column_data{c60} = qq|<th class=listsubtotal align=right>$c60subtotal</th>|;
 	$column_data{c90} = qq|<th class=listsubtotal align=right>$c90subtotal</th>|;
	$column_data{c180} = qq|<th class=listsubtotal align=right>$c180subtotal</th>|;
	$column_data{c365} = qq|<th class=listsubtotal align=right>$c365subtotal</th>|;

        # print subtotals
        print qq|
	<tr class=listsubtotal>
|;
        map { print "$column_data{$_}\n" } @column_index;

	print qq|
	</tr>
|;

      }
      
       $c1subtotal = 0;
       $c10subtotal = 0;
       $c30subtotal = 0;
       $c60subtotal = 0;
       $c90subtotal = 0;
       $c180subtotal = 0;
       $c365subtotal = 0;
      
    }
  }
  
  print qq|
        </tr>
        <tr class=listtotal>
|;

  map { $column_data{$_} = qq|<th>&nbsp;</th>| } @column_index;

   $c1total = $form->format_amount(\%myconfig, $c1total, 2, "&nbsp;");
   $c10total = $form->format_amount(\%myconfig, $c10total, 2, "&nbsp;");
   $c30total = $form->format_amount(\%myconfig, $c30total, 2, "&nbsp;");
   $c60total = $form->format_amount(\%myconfig, $c60total, 2, "&nbsp;");
   $c90total = $form->format_amount(\%myconfig, $c90total, 2, "&nbsp;");
   $c180total = $form->format_amount(\%myconfig, $c180total, 2, "&nbsp;");
   $c365total = $form->format_amount(\%myconfig, $c365total, 2, "&nbsp;");
   
   $column_data{c1} = qq|<th align=right class=listtotal>$c1total</th>|;
   $column_data{c10} = qq|<th align=right class=listtotal>$c10total</th>|;
   $column_data{c30} = qq|<th align=right class=listtotal>$c30total</th>|;
   $column_data{c60} = qq|<th align=right class=listtotal>$c60total</th>|;
   $column_data{c90} = qq|<th align=right class=listtotal>$c90total</th>|;
   $column_data{c180} = qq|<th align=right class=listtotal>$c180total</th>|;
   $column_data{c365} = qq|<th align=right class=listtotal>$c365total</th>|;

  map { print "$column_data{$_}\n" } @column_index;
  
  print qq|
          <input type=hidden name=rowcount value=$i>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
|;

  &st_print_options if ($form->{arap} eq 'ar');

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  if ($form->{arap} eq 'ar') {
    print qq|
<input type=hidden name=todate value=$form->{todate}>

<input type=hidden name=title value="$form->{title}">

<input type=hidden name=callback value=$form->{callback}>

<input type=hidden name=arap value=$form->{arap}>
<input type=hidden name=ct value=$form->{ct}>
<input type=hidden name=$form->{ct} value="$form->{$form->{ct}}">

<input type=hidden name=department value="$form->{department}">

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
  
<br>
<input class=submit type=submit name=action value="|.$locale->text('Select all').qq|">
<input class=submit type=submit name=action value="|.$locale->text('Print').qq|">
<input class=submit type=submit name=action value="|.$locale->text('E-mail').qq|">
|;
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


sub select_all {

  RP->aging(\%myconfig, \%$form);

  map { $_->{checked} = "checked" } @{ $form->{AG} };

  &aging;

}


sub st_print_options {

  $form->{sendmode} = "attachment";
  $form->{copies} = 2 unless $form->{copies};
  
  $form->{PD}{$form->{type}} = "selected";
  $form->{DF}{$form->{format}} = "selected";
  $form->{SM}{$form->{sendmode}} = "selected";
  
  $format = qq|
            <option value=html $form->{PD}{format}>html|;
	    
  $type = qq|
	    <option value=statement $form->{PD}{statement}>|.$locale->text('Statement');

  if ($form->{media} eq 'email') {
    $media = qq|
	    <option value=attachment $form->{SM}{attachment}>|.$locale->text('Attachment').qq|
	    <option value=inline $form->{SM}{inline}>|.$locale->text('In-line');
  } else {
    $media = qq|
	    <option value=screen>|.$locale->text('Screen');
    if ($myconfig{printer} && $latex) {
      map { $media .= qq|
            <option value="$_">$printer{$_}| } keys %printer;
    }
  }

  $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;

  if ($latex) {
    $format .= qq|
            <option value=postscript $form->{DF}{postscript}>|.$locale->text('Postscript').qq|
	    <option value=pdf $form->{DF}{pdf}>|.$locale->text('PDF');
  }

  print qq|
<table>
  <tr>
    <td><select name=type>$type</select></td>
    <td><select name=format>$format</select></td>
    <td><select name=media>$media</select></td>
|;

  if ($myconfig{printer} && $latex && $form->{media} ne 'email') {
    print qq|
      <td>|.$locale->text('Copies').qq|
      <input name=copies size=2 value=$form->{copies}></td>
|;
  }
  
  print qq|
  </tr>
</table>
|;

}


sub e_mail {

  # get name and email addresses
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"statement_$i"}) {
      $form->{"$form->{ct}_id"} = $form->{"$form->{ct}_id_$i"};
      RP->get_customer(\%myconfig, \%$form);
      $selected = 1;
      last;
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $selected;

  if ($myconfig{role} =~ /(admin|manager)/) {
    $bcc = qq|
          <th align=right nowrap=true>|.$locale->text('Bcc').qq|</th>
	  <td><input name=bcc size=30 value="$form->{bcc}"></td>
|;
  }

  $title = $locale->text('E-mail Statement to')." $form->{$form->{ct}}";

  $form->{media} = "email";
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr class=listtop>
    <th>$title</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr>
	  <th align=right nowrap>|.$locale->text('E-mail').qq|</th>
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

  &st_print_options;

  map { delete $form->{$_} } qw(action email cc bcc subject message type sendmode format header);

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

  $form->{OUT} = "$sendmail";

  $form->{subject} = $locale->text('Statement').qq| - $form->{todate}| unless $form->{subject};
  $form->isblank("email", $locale->text('E-mail address missing!'));
  
  RP->aging(\%myconfig, \%$form);
  
  $form->{"statement_1"} = 1;

  &print_form;
  
  $form->redirect($locale->text('Statement sent to')." $form->{$form->{ct}}");

}



sub print {

  if ($form->{media} !~ /(screen|email)/) {
    $form->error($locale->text('Select postscript or PDF!')) if ($form->{format} !~ /(postscript|pdf)/);
  }
  
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"statement_$i"}) {
      $form->{"$form->{ct}_id"} = $form->{"$form->{ct}_id_$i"};
      $language_code = $form->{"language_code_$i"};
      $selected = 1;
      last;
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $selected;
     
 
  if ($form->{media} !~ /(screen|email)/) {
    $form->{OUT} = "| $form->{media}";
    $form->{"$form->{ct}_id"} = "";
    $SIG{INT} = 'IGNORE';
  } else {
    $form->{"statement_1"} = 1;
    $form->{"language_code_1"} = $language_code;
  }

  RP->aging(\%myconfig, \%$form);
 
  &print_form;

  $form->redirect($locale->text('Statements sent to printer!')) if ($form->{media} !~ /(screen|email)/);

}


sub print_form {
  
  $form->{statementdate} = $locale->date(\%myconfig, $form->{todate}, 1);

  $form->{templates} = "$myconfig{templates}";

  # setup variables for the form
  @a = qw(company address businessnumber tel fax);
  map { $form->{$_} = $myconfig{$_} } @a;
  $form->format_string(@a);
  
  $form->{IN} = "$form->{type}.html";

  if ($form->{format} eq 'postscript') {
    $form->{IN} =~ s/html$/tex/;
  }
  if ($form->{format} eq 'pdf') {
    $form->{IN} =~ s/html$/tex/;
  }

  @a = qw(name address1 address2 city state zipcode country contact);
  push @a, "$form->{ct}phone", "$form->{ct}fax";
  push @a, 'email' if ! $form->{media} eq 'email';

  $i = 0;
  while (@{ $form->{AG} }) {

    $ref = shift @{ $form->{AG} };
    
    if ($ctid != $ref->{ctid}) {
      
      $ctid = $ref->{ctid};
      $i++;

      if ($form->{"statement_$i"}) {
	
	map { $form->{$_} = $ref->{$_} } @a;
	$form->format_string(@a);

	$form->{$form->{ct}} = $form->{name};
	$form->{"$form->{ct}_id"} = $ref->{ctid};
	$form->{language_code} = $form->{"language_code_$i"};
	
	map { $form->{$_} = () } qw(invnumber invdate duedate);
	$form->{total} = 0;
	foreach $item (qw(c1 c10 c30 c60 c90 c180 c365)) {
	  $form->{$item} = ();
	  $form->{"${item}total"} = 0;
	}

	&statement_details($ref);

        while ($ref) {

	  if (scalar (@{ $form->{AG} }) > 0) {
	    # one or more left to go
	    if ($ctid == $form->{AG}->[0]->{ctid}) {
	      $ref = shift @{ $form->{AG} };
	      &statement_details($ref);
	      # any more?
	      $ref = scalar (@{ $form->{AG} });
	    } else {
	      $ref = 0;
	    }
	  } else {
	    # set initial ref to 0
	    $ref = 0;
	  }

	}
	
	map { $form->{"${_}total"} = $form->format_amount(\%myconfig, $form->{"${_}total"}, 2) } (c1, c10, c30, c60, c90, c180, c365, "");

#	$form->parse_template(\%myconfig, $userspath);
	$form->old_parse_template(\%myconfig, $userspath);
	
      }
    }
  }

}


sub statement_details {
  my ($ref) = @_;

  push @{ $form->{invnumber} }, $ref->{invnumber};
  push @{ $form->{invdate} }, $ref->{transdate};
  push @{ $form->{duedate} }, $ref->{duedate};
  
  foreach $item (qw(c1 c10 c30 c60 c90 c180 c365)) {
    eval { $ref->{$item} = $form->round_amount($ref->{$item} / $ref->{exchangerate}, 2) };
    $form->{"${item}total"} += $ref->{$item};
    $form->{total} += $ref->{$item};
    push @{ $form->{$item} }, $form->format_amount(\%myconfig, $ref->{$item}, 2);
  }

}
 

sub generate_tax_report {

  RP->tax_report(\%myconfig, \%$form);

  $descvar = "$form->{accno}_description";
  $description = $form->escape($form->{$descvar});
  $ratevar = "$form->{accno}_rate";
  $taxrate = $form->{"$form->{accno}_rate"};
  
# kabai BUG if ($form->{accno} =~ /^gifi_/) {
#    $descvar = "gifi_$form->{accno}_description";
#    $description = $form->escape($form->{$descvar});
#    $ratevar = "gifi_$form->{accno}_rate";
#    $taxrate = $form->{"gifi_$form->{accno}_rate"};
# kabai }
  
  $department = $form->escape($form->{department});
  
  # construct href
  $href = "$form->{script}?path=$form->{path}&direction=$form->{direction}&oldsort=$form->{oldsort}&action=generate_tax_report&login=$form->{login}&sessionid=$form->{sessionid}&fromdate=$form->{fromdate}&todate=$form->{todate}&fromordnumber=$form->{fromordnumber}&toordnumber=$form->{toordnumber}&db=$form->{db}&method=$form->{method}&accno=$form->{accno}&$descvar=$description&department=$department&$ratevar=$taxrate&report=$form->{report}&gl_included=$form->{gl_included}";

  # construct callback
  $description = $form->escape($form->{$descvar},1);
  $department = $form->escape($form->{department},1);

  $form->sort_order();

  $callback = "$form->{script}?path=$form->{path}&direction=$form->{direction}&oldsort=$form->{oldsort}&action=generate_tax_report&login=$form->{login}&sessionid=$form->{sessionid}&fromdate=$form->{fromdate}&todate=$form->{todate}&fromordnumber=$form->{fromordnumber}&toordnumber=$form->{toordnumber}&db=$form->{db}&method=$form->{method}&accno=$form->{accno}&$descvar=$description&department=$department&$ratevar=$taxrate&report=$form->{report}&gl_included=$form->{gl_included}";

  $form->{title} = $locale->text('GIFI')." - " if ($form->{accno} =~ /^gifi_/);

  $title = $form->escape($form->{title});
  $href .= "&title=$title";
  $title = $form->escape($form->{title},1);
  $callback .= "&title=$title";
  
  $form->{title} = qq|$form->{title} $form->{"$form->{accno}_description"} |;

#kabai
  @columns = $form->sort_columns(qw(id transdate invnumber ordnumber name taxnumber netamount tax total taxrate notes link eva));
 
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
  
  
  if ($form->{department}) {
    ($department) = split /--/, $form->{department};
    $option = $locale->text('Department')." : $department";
  }
  
  # if there are any dates
  if ($form->{fromdate} || $form->{todate}) {
    if ($form->{fromdate}) {
      $fromdate = $locale->date(\%myconfig, $form->{fromdate}, 1);
    }
    if ($form->{todate}) {
      $todate = $locale->date(\%myconfig, $form->{todate}, 1);
    }
    
    $form->{period} = "$fromdate - $todate";
  } else {
    $form->{period} = $locale->date(\%myconfig, $form->current_date(\%myconfig), 1);
  }
  
  if ($form->{fromordnumber} || $form->{toordnumber}) {
    if ($form->{fromordnumber}) {
      $fromordnumber = $form->{fromordnumber}
    }
    if ($form->{toordnumber}) {
      $toordnumber = $form->{toordnumber}
    }
    $form->{ordperiod}="$fromordnumber - $toordnumber";
  }

  if ($form->{db} eq 'ar') {
    $name = $locale->text('Customer');
    $invoice = 'is.pl';
    $arap = 'ar.pl';
  }
  if ($form->{db} eq 'ap') {
    $name = $locale->text('Vendor');
    $invoice = 'ir.pl';
    $arap = 'ap.pl';
  }

  $option .= "<br>" if $option;
  $option .= "$form->{period}";
  $option .= "<br>" if $option;
  $option .= "$form->{ordperiod}";
  
 
  $column_header{id} = qq|<th><a class=listheading href=$href&sort=id>|.$locale->text('ID').qq|</th>|;
  $column_header{invnumber} = qq|<th><a class=listheading href=$href&sort=invnumber>|.$locale->text('Invoice').qq|</th>|;
  $column_header{ordnumber} = qq|<TH><a class="listheading" href="$href&sort=ordnumber">|.$locale->text('Order Number').qq|</th>|;
  $column_header{transdate} = qq|<th><a class=listheading href=$href&sort=transdate>|.$locale->text('Date').qq|</th>|;
  $column_header{netamount} = qq|<th class=listheading>|.$locale->text('Amount').qq|</th>|;
  $column_header{tax} = qq|<th class=listheading>|.$locale->text('Tax').qq|</th>|;
  $column_header{total} = qq|<th class=listheading>|.$locale->text('Total').qq|</th>|;
  
  $column_header{name} = qq|<th><a class=listheading href=$href&sort=name>$name</th>|;
  $column_header{taxnumber} = qq|<th><a class=listheading href=$href&sort=taxnumber>|.$locale->text('Tax number').qq|</th>|;
#kabai
  $column_header{taxrate} = qq|<th><a class=listheading href=$href&sort=taxrate>|.$locale->text('Tax rate').qq|</th>|;
  $column_header{notes} = qq|<th><a class=listheading href=$href&sort=notes>|.$locale->text('Notes').qq|</th>|;
  $column_header{link} = qq|<th><a class=listheading href=$href&sort=link>|.$locale->text('Invest/Asset').qq|</th>|;
  $column_header{eva} = qq|<th><a class=listheading href=$href&sort=eva>|.$locale->text('EVA').qq|</th>|;
#kabai  
  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop colspan=$colspan>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
       <thead>
	<tr class=listheading>
|;

  map { print "$column_header{$_}\n" } @column_index;
  
  print qq|
	</tr>
       </thead>
       <tfoot>
        <tr><td>&nbsp;
        </td></tr>
       </tfoot>
       <tbody>
|;

  # add sort and escape callback
  $callback = $form->escape($callback . "&sort=$form->{sort}");
    
  if (@{ $form->{TR} }) {
    $sameitem = $form->{TR}->[0]->{$form->{sort}};
  }
  foreach $ref (@{ $form->{TR} }) {
    $module = ($ref->{invoice}) ? $invoice : $arap;
    $module = 'ps.pl' if $ref->{till};
    $module = 'gl.pl' if !$ref->{name};

    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $ref->{$form->{sort}}) {
	&tax_subtotal;
	$sameitem = $ref->{$form->{sort}};
      }
    }

    $totalnetamount += $ref->{netamount};
    $totaltax += $ref->{tax};
    $ref->{total} = $ref->{netamount} + $ref->{tax};

    $subtotalnetamount += $ref->{netamount};
    $subtotaltax += $ref->{tax};
    
    map { $ref->{$_} = $form->format_amount(\%myconfig, $ref->{$_}, 2, "&nbsp;"); } qw(netamount tax total);

    $column_data{id} = qq|<td>$ref->{id}</td>|;
    $column_data{invnumber} = qq|<td><a href=$module?path=$form->{path}&action=edit&id=$ref->{id}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{invnumber}</a></td>|;
    $column_data{ordnumber} = qq|<td>$ref->{ordnumber}</td>|;
    $column_data{transdate} = qq|<td>$ref->{transdate}</td>|;
    $column_data{name} = qq|<td>$ref->{name}&nbsp;</td>|;
    $column_data{taxnumber} = qq|<td>$ref->{taxnumber}&nbsp;</td>|;
    $column_data{notes} = qq|<td>$ref->{notes}&nbsp;</td>|;
    my $link=($ref->{link}) ? 'X' : '' ;
    $column_data{link} = qq|<td>$link&nbsp;</td>|;
    my $eva=($ref->{eva}) ? 'X' : '' ;
    $column_data{eva} = qq|<td>$eva&nbsp;</td>|;
#kabai    
    $column_data{taxrate} = qq|<td align=right>$ref->{taxrate}</td>|;
#kabai
   
 map { $column_data{$_} = qq|<td align=right>$ref->{$_}</td>| } qw(netamount tax total);

    $i++; $i %= 2;
    print qq|
	<tr class=listrow$i>
|;

    map { print "$column_data{$_}\n" } @column_index;

    print qq|
	</tr>
|;
 
  }
 
  if ($form->{l_subtotal} eq 'Y') {
    &tax_subtotal;
  }

  
  map { $column_data{$_} = qq|<th>&nbsp;</th>| } @column_index;
  
  print qq|
        </tr>
	<tr class=listtotal>
|;

  $total = $form->format_amount(\%myconfig, $totalnetamount + $totaltax, 2, "&nbsp;");
  $totalnetamount = $form->format_amount(\%myconfig, $totalnetamount, 2, "&nbsp;");
  $totaltax = $form->format_amount(\%myconfig, $totaltax, 2, "&nbsp;");
  
  $column_data{netamount} = qq|<th class=listtotal align=right>$totalnetamount</th>|;
  $column_data{tax} = qq|<th class=listtotal align=right>$totaltax</th>|;
  $column_data{total} = qq|<th class=listtotal align=right>$total</th>|;
 
  map { print "$column_data{$_}\n" } @column_index;
 
    
  print qq|
        </tr>
       </tbody>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

</body>
</html>
|;

}


sub tax_subtotal {

  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;

  $subtotal = $form->format_amount(\%myconfig, $subtotalnetamount + $subtotaltax, 2, "&nbsp;");
  $subtotalnetamount = $form->format_amount(\%myconfig, $subtotalnetamount, 2, "&nbsp;");
  $subtotaltax = $form->format_amount(\%myconfig, $subtotaltax, 2, "&nbsp;");
  
  $column_data{netamount} = "<th class=listsubtotal align=right>$subtotalnetamount</th>";
  $column_data{tax} = "<th class=listsubtotal align=right>$subtotaltax</th>";
  $column_data{total} = "<th class=listsubtotal align=right>$subtotal</th>";

  $subtotalnetamount = 0;
  $subtotaltax = 0;
  
  print qq|
	<tr class=listsubtotal>
|;
  map { print "\n$column_data{$_}" } @column_index;

  print qq|
        </tr>
|;
  
}



sub list_payments {

  if ($form->{account}) {
    ($form->{paymentaccounts}) = split /--/, $form->{account};
  }
  if ($form->{department}) {
    ($department, $form->{department_id}) = split /--/, $form->{department};
    $option = $locale->text('Department')." : $department";
  }

  RP->payments(\%myconfig, \%$form);

 if ($form->{cash}) {
  @columns = $form->sort_columns(qw(printcheck transdate source name memo paid notes));
 }else{
  @columns = $form->sort_columns(qw(transdate source name memo paid notes));
 } 
  if ($form->{till}) {
    @columns = $form->sort_columns(qw(transdate name paid source till));
    if ($myconfig{role} ne 'user') {
      @columns = $form->sort_columns(qw(transdate name paid source till employee));
    }
  }
  
  # construct href
  $account = $form->escape($form->{account});
  $title = $form->escape($form->{title});
  $department = $form->escape($form->{department});
  $form->{paymentaccounts} =~ s/ /%20/g;
  $source = $form->escape($form->{source});
  $memo = $form->escape($form->{memo});
  
  $href = "$form->{script}?path=$form->{path}&direction=$form->{direction}&oldsort=$form->{oldsort}&action=list_payments&till=$form->{till}&login=$form->{login}&sessionid=$form->{sessionid}&fromdate=$form->{fromdate}&todate=$form->{todate}&fx_transaction=$form->{fx_transaction}&db=$form->{db}&l_subtotal=$form->{l_cubtotal}&prepayment=$form->{prepayment}&title=$title&account=$account&department=$department&paymentaccounts=$form->{paymentaccounts}&source=$source&memo=$memo&cash=$form->{cash}&onlygl=$form->{onlygl}";
  $href1 = "$form->{script}?path=$form->{path}&oldsort=$form->{oldsort}&action=list_payments&till=$form->{till}&login=$form->{login}&sessionid=$form->{sessionid}&fromdate=$form->{fromdate}&todate=$form->{todate}&fx_transaction=$form->{fx_transaction}&db=$form->{db}&l_subtotal=$form->{l_cubtotal}&prepayment=$form->{prepayment}&title=$title&account=$account&department=$department&paymentaccounts=$form->{paymentaccounts}&source=$source&memo=$memo&cash=$form->{cash}&onlygl=$form->{onlygl}";
  # construct callback
  $account = $form->escape($form->{account},1);
  $title = $form->escape($form->{title},1);
  $department = $form->escape($form->{department},1);
  $source = $form->escape($form->{source},1);
  $memo = $form->escape($form->{memo},1);
  
  $form->sort_order();

  $form->{callback} = "$form->{script}?path=$form->{path}&direction=$form->{direction}&oldsort=$form->{oldsort}&action=list_payments&till=$form->{till}&login=$form->{login}&sessionid=$form->{sessionid}&fromdate=$form->{fromdate}&todate=$form->{todate}&fx_transaction=$form->{fx_transaction}&db=$form->{db}&l_subtotal=$form->{l_subtotal}&prepayment=$form->{prepayment}&title=$title&account=$account&department=$department&paymentaccounts=$form->{paymentaccounts}&source=$source&memo=$memo&sort=$form->{sort}&cash=$form->{cash}&onlygl=$form->{onlygl}";
  $callback = $form->escape($form->{callback});

  $column_header{printcheck} = "<th width=3%><a class=listheading href=$href1&sort=transdate&printchecked=1>".$locale->text('C')."</a><a class=listheading href=$href1&sort=transdate&printonlygl=1>".$locale->text('V')."</a></th>";
  $column_header{name} = "<th><a class=listheading href=$href&sort=name>".$locale->text('Partner')."</a></th>";
  $column_header{transdate} = "<th><a class=listheading href=$href&sort=transdate>".$locale->text('Date')."</a></th>";
  $column_header{paid} = "<th class=listheading>".$locale->text('Amount')."</a></th>";
  $column_header{source} = "<th><a class=listheading href=$href&sort=source>".$locale->text('Source')."</a></th>";
  $column_header{memo} = "<th><a class=listheading href=$href&sort=memo>".$locale->text('Description')."</a></th>";

  $column_header{employee} = "<th><a class=listheading href=$href&sort=employee>".$locale->text('Salesperson')."</a></th>";
  $column_header{till} = "<th><a class=listheading href=$href&sort=till>".$locale->text('Till')."</a></th>";
  $column_header{notes} = "<th><a class=listheading href=$href&sort=notes>".$locale->text('Notes')."</a></th>";
  if ($form->{fromdate}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{fromdate}, 1);
  }
  if ($form->{todate}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('to')."&nbsp;".$locale->date(\%myconfig, $form->{todate}, 1);
  }

  @column_index = @columns;
  $colspan = $#column_index + 1;

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
      <form method="post" action="rp.pl">
       <table width=100%>
	<tr class=listheading>
|;

  map { print "\n$column_header{$_}" } @column_index;

  print qq|
        </tr>
|;

  my $pc = 1;
  foreach $ref (sort { $a->{accno} cmp $b->{accno} } @{ $form->{PR} }) {

    next unless @{ $form->{$ref->{id}} };

    print qq|
        <tr>
	  <th colspan=$colspan align=left>$ref->{accno}--$ref->{description}</th>
	</tr>
|;

    if (@{ $form->{$ref->{id}} }) {
      $sameitem = $form->{$ref->{id}}[0]->{$form->{sort}};
    }
    
    foreach $payment (@{ $form->{$ref->{id}} }) {

      if ($form->{l_subtotal}) {
	if ($payment->{$form->{sort}} ne $sameitem) {
	  # print subtotal
	  &payment_subtotal;
	}
      }
      
      next if ($form->{till} && ! $payment->{till});
      my $reccheck = $form->{db} eq "ar" ? "receipt" : "check";
      $form->{"printchecked_$pc"} = "checked" if $form->{printchecked};    
      if ($form->{printonlygl}){
	$form->{"printchecked_$pc"} = "checked" if $payment->{db} eq "gl";
      }	
      if ($payment->{invoice}){
        $paymentdb = $payment->{db} eq "ar" ? "is" : "ir";
      }else{
	$paymentdb = $payment->{db};
      }	
      $column_data{printcheck} = qq|
      <td>
      <input name="printcheck_$pc" type=checkbox class=checkbox value=1 $form->{"printchecked_$pc"}>
      <input type="hidden" name="source_$pc" value="$payment->{source}">
      <input type="hidden" name="datepaid_$pc" value="$payment->{transdate}">
      <input type="hidden" name="${reccheck}_$pc" value="|.$form->format_amount(\%myconfig, $payment->{paid}, 2).qq|">
      <input type="hidden" name="partner_$pc" value="$payment->{name}">
      <input type="hidden" name="memo_$pc" value="$payment->{memo}">
      <input type="hidden" name="id_$pc" value="$payment->{id}">
      <input type="hidden" name="db_$pc" value="$payment->{db}">
      <input type="hidden" name="vamount_$pc" value="$payment->{amount}">
      <input type="hidden" name="vmemo_$pc" value="$payment->{vmemo}">
      <input type="hidden" name="taxbase_$pc" value="$payment->{taxbase}">
      </td>|;
      $pc++;
      $column_data{name} = "<td>$payment->{name}&nbsp;</td>";
      $column_data{transdate} = qq|<td><a href="${paymentdb}.pl?action=edit&id=$payment->{id}&path=bin/mozilla&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback">$payment->{transdate}</a>&nbsp;</td>|;
      $column_data{paid} = "<td align=right>".$form->format_amount(\%myconfig, $payment->{paid}, 2, "&nbsp;")."</td>";
      $column_data{source} = "<td>$payment->{source}&nbsp;</td>";
      $column_data{memo} = "<td>$payment->{memo}&nbsp;</td>";
      $column_data{employee} = "<td>$payment->{employee}&nbsp;</td>";
      $column_data{till} = "<td>$payment->{till}&nbsp;</td>";

      $subtotalpaid += $payment->{paid};
      $accounttotalpaid += $payment->{paid};
      $totalpaid += $payment->{paid};
       
      $i++; $i %= 2;
      print qq|
	<tr class=listrow$i>
|;

      map { print "\n$column_data{$_}" } @column_index;

      print qq|
        </tr>
|;

      $sameitem = $payment->{$form->{sort}};
      
    }

    &payment_subtotal if $form->{l_subtotal};
    
    # print account totals
    map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;

    $column_data{paid} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $accounttotalpaid, 2, "&nbsp;")."</th>";
     
    print qq|
	<tr class=listtotal>
|;

    map { print "\n$column_data{$_}" } @column_index;

    print qq|
        </tr>
|;

    $accounttotalpaid = 0;
     
  }


  # print total
  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;

  $column_data{paid} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalpaid, 2, "&nbsp;")."</th>";
     
  print qq|
        <tr class=listtotal>
|;

  map { print "\n$column_data{$_}" } @column_index;

  print qq|
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
  <tr>
    <td>
    <input type="hidden" name="db" value="$form->{db}">
    <input type="hidden" name="currency" value='$form->{"vcurr_$form->{paymentaccounts}"}'>
    <input type="hidden" name="fx_transaction" value="$form->{fx_transaction}">
    <input type="hidden" name="account" value="$form->{account}">
    <input type="hidden" name="login" value="$form->{login}">
    <input type="hidden" name="path" value="$form->{path}">
    <input type="hidden" name="sessionid" value="$form->{sessionid}">
    <input type="hidden" name="callback" value="$form->{callback}">
    |;
  if ($form->{cash}){ 
    $form->{forms}{cash_voucher} = "Cash Voucher" unless ($form->{forms});
    $form->{format} = "html" unless ($form->{format});
    $form->{media} = "screen" unless ($form->{media});
    $form->{copies} = 1 unless ($form->{copies});
     &rsprint_options;
    if ($myconfig{role} eq "admin"){
        print qq| <br /><br />
                  |.$locale->text('Starting Number').qq|:&nbsp;<input name="recountval" class="required" size="8"> 
                  &nbsp;<input type=checkbox name=onlygl value=1>|.$locale->text('Only general ledger transactions').
		  qq|&nbsp;<input class="submit" type="submit" name="action" onclick="return checkform();" value="|.
		  $locale->text('Recount').qq|">|;
    }    
  }
  print qq|
    </form>
    </td>
  </tr>  
</table>

</body>
</html>
|;

}


sub payment_subtotal {

  if ($subtotalpaid != 0) {
    map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;

    $column_data{paid} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalpaid, 2, "&nbsp;")."</th>";

    print qq|
  <tr class=listsubtotal>
|;

    map { print "\n$column_data{$_}" } @column_index;

    print qq|
  </tr>
|;
  }

  $subtotalpaid = 0;

}

#kabai
sub search_cashreport {

  $form->{title} = $form->{cash} ? $locale->text('Cash Report') : $locale->text('Bank Report');

#kabai
    RP->paymentaccounts2(\%myconfig, \%$form);

#    $paymentselection = "<option>\n";
    foreach $ref (@{ $form->{PR} }) {
      $paymentaccounts .= "$ref->{accno} ";
      $paymentselection .= "<option value=$ref->{accno}>$ref->{accno}--$ref->{description}\n";
    }
    
    chop $paymentaccounts;
#kabai  
  $form->all_departments(\%myconfig);
  # departments
  if (@{ $form->{all_departments} }) {
    $form->{selectdepartment} = "<option>\n";

    map { $form->{selectdepartment} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| } (@{ $form->{all_departments} });
 
    $department = qq|
  	<tr>
	  <th align=right nowrap>|.$locale->text('Department').qq|</th>
	  <td colspan=3><select name=department>$form->{selectdepartment}</select></td>
	</tr>
|;
  }
  
  $form->header;
#kabai +6, +16-21
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

<input type=hidden name=sort value=transdate>
<input type=hidden name=category value=X>
<input type=hidden name=cash value="$form->{cash}">
<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <th align=right nowrap>|.$locale->text('Account').qq|</th>
          <td colspan=3><select name=accno>$paymentselection</select>
	    <input type=hidden name=paymentaccounts value="$paymentaccounts">
	  </td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Source').qq|</th>
	  <td><input name=source size=20></td>
	  <th align=right><!--|.$locale->text('Reference').qq|--></th>
	  <td><!--<input name=reference size=20>--></td>
	</tr>
	$department
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td colspan=3><input name=description size=40></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Partner').qq|</th>
	  <td colspan=3><input name=notes size=40></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=datefrom size=11 title="$myconfig{dateformat}" id=datefrom OnBlur="return dattrans('datefrom');"></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=dateto size=11 title="$myconfig{dateformat}" id=dateto OnBlur="return dattrans('dateto');"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Amount').qq| >=</th>
	  <td><input name=amountfrom size=11></td>
	  <th align=right>|.$locale->text('Amount').qq| <=</th>
	  <td><input name=amountto size=11></td>
	</tr>
        <tr>
	  <td align=right><input type=checkbox style=checkbox name=fx_transaction value=1 checked></td>
	  <td colspan=3>|.$locale->text('Include Exchangerate Difference').qq|</td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Include in Report').qq|</th>
	  <td colspan=3>
	    <table>
	      <tr>
		<table>
		  <tr>
		    <td align=right><input name="l_id" class=checkbox type=checkbox value=Y></td>
		    <td>|.$locale->text('ID').qq|</td>
		    <td align=right><input name="l_transdate" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Date').qq|</td>
		    <td align=right><input name="l_description" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Description').qq|</td>
		    <td align=right><input name="l_notes" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Partner').qq|</td>
		    <td align=right><!--<input name="l_reference" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Reference').qq|--></td>
		  </tr>
		  <tr>
		    <td align=right><input name="l_debit" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Debit').qq|</td>
		    <td align=right><input name="l_credit" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Credit').qq|</td>
		    <td align=right><input name="l_source" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Source').qq|</td>
		    <td align=right></td>

		  </tr>
		  <tr>
		    <td align=right><input name="l_subtotal" class=checkbox type=checkbox value=Y></td>
		    <td>|.$locale->text('Subtotal').qq|</td>
		  </tr>
		</table>
	      </tr>
	    </table>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=nextsub value=generate_cashreport>

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
sub generate_cashreport {

  $form->{sort} = "transdate" unless $form->{sort};

  GL->all_transactions(\%myconfig, \%$form);
    
  $href = "$form->{script}?action=generate_cashreport&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $form->sort_order();

  $callback = "$form->{script}?action=generate_cashreport&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  %acctype = ( 'A' => $locale->text('Asset'),
               'C' => $locale->text('Contra'),
               'L' => $locale->text('Liability'),
	       'Q' => $locale->text('Equity'),
	       'I' => $locale->text('Income'),
	       'E' => $locale->text('Expense'),
	     );
  
  $form->{title} = $form->{cash} ? $locale->text('Cash Report') : $locale->text('Bank Report');
  
  $ml = ($form->{ml} =~ /(A|E)/) ? -1 : 1;

  unless ($form->{category} eq 'X') {
    $form->{title} .= " : ".$locale->text($acctype{$form->{category}});
  }
  if ($form->{accno}) {
    $href .= "&accno=".$form->escape($form->{accno});
    $callback .= "&accno=".$form->escape($form->{accno},1);
    $option = $locale->text('Account')." : $form->{accno} $form->{account_description}";
  }
  if ($form->{gifi_accno}) {
    $href .= "&gifi_accno=".$form->escape($form->{gifi_accno});
    $callback .= "&gifi_accno=".$form->escape($form->{gifi_accno},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('GIFI')." : $form->{gifi_accno} $form->{gifi_account_description}";
  }
  if ($form->{source}) {
    $href .= "&source=".$form->escape($form->{source});
    $callback .= "&source=".$form->escape($form->{source},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Source')." : $form->{source}";
  }
  if ($form->{reference}) {
    $href .= "&reference=".$form->escape($form->{reference});
    $callback .= "&reference=".$form->escape($form->{reference},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Reference')." : $form->{reference}";
  }
  if ($form->{department}) {
    $href .= "&department=".$form->escape($form->{department});
    $callback .= "&department=".$form->escape($form->{department},1);
    ($department) = split /--/, $form->{department};
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Department')." : $department";
  }

  if ($form->{description}) {
    $href .= "&description=".$form->escape($form->{description});
    $callback .= "&description=".$form->escape($form->{description},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Description')." : $form->{description}";
  }
  if ($form->{notes}) {
    $href .= "&notes=".$form->escape($form->{notes});
    $callback .= "&notes=".$form->escape($form->{notes},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Notes')." : $form->{notes}";
  }

#kabai
  if ($form->{ordnumberfrom}) {
    $href .= "&ordnumberfrom=".$form->escape($form->{ordnumberfrom});
    $callback .= "&ordnumberfrom=".$form->escape($form->{ordnumberfrom},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Order Number')." : $form->{ordnumberfrom}";
  }

  if ($form->{ordnumberto}) {
    $href .= "&ordnumberto=".$form->escape($form->{ordnumberto});
    $callback .= "&ordnumberto=".$form->escape($form->{ordnumberto},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Order Number')." : $form->{ordnumberto}";
  }
#kabai
   
  if ($form->{datefrom}) {
    $href .= "&datefrom=$form->{datefrom}";
    $callback .= "&datefrom=$form->{datefrom}";
    $option .= "\n<br>" if $option;
    $option .= $locale->text('From')." ".$locale->date(\%myconfig, $form->{datefrom}, 1);
  }
  if ($form->{dateto}) {
    $href .= "&dateto=$form->{dateto}";
    $callback .= "&dateto=$form->{dateto}";
    if ($form->{datefrom}) {
      $option .= " ";
    } else {
      $option .= "\n<br>" if $option;
    }
    $option .= $locale->text('To')." ".$locale->date(\%myconfig, $form->{dateto}, 1);
  }
  
  if ($form->{amountfrom}) {
    $href .= "&amountfrom=$form->{amountfrom}";
    $callback .= "&amountfrom=$form->{amountfrom}";
    $option .= "\n<br>" if $option;
    $option .= $locale->text('Amount')." >= ".$form->format_amount(\%myconfig, $form->{amountfrom}, 2);
  }
  if ($form->{amountto}) {
    $href .= "&amountto=$form->{amountto}";
    $callback .= "&amountto=$form->{amountto}";
    if ($form->{amountfrom}) {
      $option .= " <= ";
    } else {
      $option .= "\n<br>" if $option;
      $option .= $locale->text('Amount')." <= ";
    }
    $option .= $form->format_amount(\%myconfig, $form->{amountto}, 2);
  }

  @columns = $form->sort_columns(qw(transdate source id reference notes description debit credit accno gifi_accno ordnumber curr fxamount duedate acc_descr gifi_descr));

  if ($form->{link} =~ /_paid/) {
    @columns = $form->sort_columns(qw(transdate source id reference notes description cleared debit credit accno gifi_accno));
    $form->{l_cleared} = "Y";
  }

  if ($form->{accno} || $form->{gifi_accno}) {
    @columns = grep !/(accno|gifi_accno)/, @columns;
    push @columns, "balance";
#kabai
    push @columns, "counteraccno";
#kabai    
    $form->{l_balance} = "Y";
  }
  
  
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

  $callback .= "&category=$form->{category}";
  $href .= "&category=$form->{category}";
#kabai
  $callback .= "&journal=$form->{journal}";
  $href .= "&journal=$form->{journal}";
#kabai
  $column_header{id} = "<th><a class=listheading href=$href&sort=id>".$locale->text('ID')."</a></th>";
  $column_header{transdate} = "<th><a class=listheading href=$href&sort=transdate>".$locale->text('Date')."</a></th>";
  $column_header{reference} = "<th><a class=listheading href=$href&sort=reference>".$locale->text('Reference')."</a></th>";
  $column_header{source} = "<th><a class=listheading href=$href&sort=source>".$locale->text('Source')."</a></th>";
  $column_header{description} = "<th><a class=listheading href=$href&sort=description>".$locale->text('Description')."</a></th>";
  $column_header{notes} = "<th class=listheading>".$locale->text('Partner')."</th>";
  $column_header{debit} = "<th class=listheading>".$locale->text('Debit')."</th>";
  $column_header{credit} = "<th class=listheading>".$locale->text('Credit')."</th>";
  $column_header{accno} = "<th><a class=listheading href=$href&sort=accno>".$locale->text('Account')."</a></th>";
  $column_header{gifi_accno} = "<th><a class=listheading href=$href&sort=gifi_accno>".$locale->text('GIFI')."</a></th>";
  $column_header{balance} = "<th>".$locale->text('Balance')."</th>";
  $column_header{cleared} = qq|<th>|.$locale->text('R').qq|</th>|;
#kabai
  $column_header{ordnumber} = "<th><a class=listheading href=$href&sort=ordnumber>".$locale->text('Order Number')."</a></th>";
  $column_header{curr} = "<th><a class=listheading href=$href&sort=curr>".$locale->text('Currency')."</a></th>";
  $column_header{fxamount} = qq|<th>|.$locale->text('Fx amount').qq|</th>|;
  $column_header{duedate} = "<th><a class=listheading href=$href&sort=duedate>".$locale->text('Due Date')."</a></th>";

  $column_header{acc_descr} = "<th><a class=listheading href=$href&sort=acc_descr>".$locale->text('Account Description')."</a></th>";
  $column_header{gifi_descr} = "<th><a class=listheading href=$href&sort=gifi_descr>".$locale->text('GIFI Description')."</a></th>";

  $column_header{counteraccno} = qq|<th>|.$locale->text('Counter Accno').qq|</th>|;
#kabai
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

print "
        </tr>
";
  
  # add sort to callback
  $form->{callback} = "$callback&sort=$form->{sort}";
  $callback = $form->escape($form->{callback});
  
  # initial item for subtotals
  if (@{ $form->{GL} }) {
    $sameitem = $form->{GL}->[0]->{$form->{sort}};
  }
  
  if (($form->{accno} || $form->{gifi_accno}) && $form->{balance}) {

    map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
    $column_data{balance} = "<td align=right>".$form->format_amount(\%myconfig, $form->{balance} * $ml, 2, 0)."</td>";
    
    $i++; $i %= 2;
    print qq|
        <tr class=listrow$i>
|;
    map { print "$column_data{$_}\n" } @column_index;
    
    print qq|
        </tr>
|;
  }
   
  foreach $ref (@{ $form->{GL} }) {

#kabai
    if (!$form->{fx_transaction}){
        next if $ref->{fx_transaction};
    }
#kabai        
    # if item ne sort print subtotal
    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $ref->{$form->{sort}}) {
	&cash_subtotal;
      }
    }
    
    $form->{balance} += $ref->{amount};
    
    $subtotaldebit += $ref->{debit};
    $subtotalcredit += $ref->{credit};

    
    $totaldebit += $ref->{debit};
    $totalcredit += $ref->{credit};

    $ref->{debit} = $form->format_amount(\%myconfig, $ref->{debit}, 2, "&nbsp;");
    $ref->{credit} = $form->format_amount(\%myconfig, $ref->{credit}, 2, "&nbsp;");

    $column_data{id} = "<td>$ref->{id}</td>";
    $column_data{transdate} = "<td><a href=$ref->{module}.pl?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{transdate}</a></td>";
    $column_data{reference} = "<td>$ref->{reference}</td>";
    if ($ref->{module} eq "gl"){
     $column_data{description} = "<td>$ref->{description}&nbsp;</td>";
    }else{
     $column_data{description} = "<td>$ref->{notes}&nbsp;</td>";
    }	
    $column_data{source} = "<td>$ref->{source}&nbsp;</td>";
    if ($ref->{module} eq "gl"){
	$column_data{notes} = "<td>$ref->{notes}&nbsp;</td>";
    }else{
	$column_data{notes} = "<td>$ref->{description}&nbsp;</td>";
    }	
    $column_data{debit} = "<td align=right>$ref->{debit}</td>";
    $column_data{credit} = "<td align=right>$ref->{credit}</td>";
    $column_data{accno} = "<td><a href=$href&accno=$ref->{accno}&callback=$callback>$ref->{accno}</a></td>";
    $column_data{gifi_accno} = "<td><a href=$href&gifi_accno=$ref->{gifi_accno}&callback=$callback>$ref->{gifi_accno}</a>&nbsp;</td>";
    $column_data{balance} = "<td align=right>".$form->format_amount(\%myconfig, $form->{balance} * $ml, 2, 0)."</td>";
    $column_data{cleared} = ($ref->{cleared}) ? "<td>*</td>" : "<td>&nbsp;</td>";
#kabai
    $column_data{ordnumber} = "<td align=right>$ref->{ordnumber}</td>";
    $column_data{curr} = "<td align=right>$ref->{curr}</td>";
    $column_data{fxamount} = "<td align=right>$ref->{fxamount}</td>";
    $column_data{duedate} = "<td>$ref->{duedate}</td>";

    $column_data{acc_descr} = "<td>$ref->{acc_descr}&nbsp;</td>";
    $column_data{gifi_descr} = "<td>$ref->{gifi_descr}&nbsp;</td>";

    $column_data{counteraccno} = "<td align=right>$ref->{counteraccno}</td>";
#kabai
    $i++; $i %= 2;
    print "
        <tr class=listrow$i>";
    map { print "$column_data{$_}\n" } @column_index;
    print "</tr>";
    
  }


  &cash_subtotal if ($form->{l_subtotal} eq 'Y');


  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
  
  $column_data{debit} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $totaldebit, 2, "&nbsp;")."</th>";
  $column_data{credit} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $totalcredit, 2, "&nbsp;")."</th>";
  $column_data{balance} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $form->{balance} * $ml, 2, 0)."</th>";
  
  print qq|
	<tr class=listtotal>
|;

  map { print "$column_data{$_}\n" } @column_index;

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

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
|;

  foreach $item (sort { $a->{order} <=> $b->{order} } %button) {
    print $item->{code};
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


sub cash_subtotal {
      
  $subtotaldebit = $form->format_amount(\%myconfig, $subtotaldebit, 2, "&nbsp;");
  $subtotalcredit = $form->format_amount(\%myconfig, $subtotalcredit, 2, "&nbsp;");

  
  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;

  $column_data{debit} = "<th align=right class=listsubtotal>$subtotaldebit</td>";
  $column_data{credit} = "<th align=right class=listsubtotal>$subtotalcredit</td>";

  
  print "<tr class=listsubtotal>";
  map { print "$column_data{$_}\n" } @column_index;
  print "</tr>";

  $subtotaldebit = 0;
  $subtotalcredit = 0;


  $sameitem = $ref->{$form->{sort}};

}

sub project_report {

  $form->{l_subtotal}='Y' if ($form->{l_osubtotal} eq 'Y');

  ($form->{projectnumber}) = $form->{projectnumber0} ? $form->{projectnumber0} : split /--/, $form->{projectnumber};

  $form->sort_order();
  RP->project_report(\%myconfig, \%$form);

  $href = "$form->{script}?action=project_report&direction=$form->{direction}&oldsort=$form->{oldsort}&outstanding=$form->{outstanding}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  $callback = "$form->{script}?action=project_report&direction=$form->{direction}&oldsort=$form->{oldsort}&outstanding=$form->{outstanding}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $callback .= "&title=".$form->escape($form->{title},1);
  $href .= "&title=".$form->escape($form->{title});

  if ($form->{projectnumber}) {
    $callback .= "&projectnumber=".$form->escape($form->{projectnumber},1);
    $href .= "&projectnumber=".$form->escape($form->{projectnumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Project Number')." : $form->{projectnumber}";
  }
  
  if ($form->{fromdate}) {
    $callback .= "&fromdate=$form->{fromdate}";
    $href .= "&fromdate=$form->{fromdate}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('From')." ".$locale->date(\%myconfig, $form->{fromdate}, 1);
  }
  if ($form->{todate}) {
    $callback .= "&todate=$form->{todate}";
    $href .= "&todate=$form->{todate}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('To')." ".$locale->date(\%myconfig, $form->{todate}, 1);
  }

  @columns = $form->sort_columns(qw(projectnumber transdate invnumber customer netincome incomeaccno vendor netcost costaccno profit margin));

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

  $direction = ($form->{direction} eq 'ASC') ? "DESC" : "ASC";
  $href =~ s/&direction=(\w+)&/&direction=$direction&/;  

  $column_header{projectnumber} = qq|<th><a class=listheading href=$href&sort=projectnumber>|.$locale->text('Project Number').qq|</a></th>|;
  $column_header{transdate} = qq|<th><a class=listheading href=$href&sort=transdate>|.$locale->text('Date').qq|</a></th>|;
  $column_header{invnumber} = qq|<th><a class=listheading href=$href&sort=invnumber>|.$locale->text('Invoice').qq|</a></th>|;
  $column_header{customer} = "<th><a class=listheading href=$href&sort=customer>".$locale->text('Customer')."</th>";
  $column_header{netincome} = qq|<th class=listheading>|.$locale->text('Net Income').qq|</th>|;
  $column_header{incomeaccno} = qq|<th class=listheading>|.$locale->text('Income Account').qq|</th>|;
  $column_header{vendor} = "<th><a class=listheading href=$href&sort=vendor>".$locale->text('Vendor')."</th>";
  $column_header{netcost} = qq|<th class=listheading>|.$locale->text('Net Cost').qq|</th>|;
  $column_header{costaccno} = qq|<th class=listheading>|.$locale->text('Cost Account').qq|</th>|;
  $column_header{profit} = qq|<th class=listheading>|.$locale->text('Profit').qq|</th>|;
  $column_header{margin} = qq|<th class=listheading>|.$locale->text('Margin').qq| %</th>|;
  $form->{title} = ($form->{title}) ? $form->{title} : $locale->text('AP Transactions');

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

  # add sort and escape callback
  $form->{callback} = "$callback&sort=$form->{sort}";
  $callback = $form->escape($form->{callback});


	$subtotal = 0;
	undef ($sameitem);
        $groupby = $form->{sort};
	foreach $ap (@{ $form->{transactions} }) { 

		if ( ($sameitem eq $ap->{$groupby})) {
			map { $column_data{$_} = "<td></td>" } @column_index;
			}
		else {
			if ($sameitem ne $ap->{$groupby}) {
				if (($form->{l_subtotal} eq 'Y') && $subtotal) {
					&pr_subtotal;
					}
				$sameitem = $ap->{$groupby};
				}

			$due = $ap->{amount};
		}
    $totalnetincome += $ap->{netincome};
    $subtotalnetincome += $ap->{netincome};
    $totalnetcost += $ap->{netcost};
    $subtotalnetcost += $ap->{netcost};



    $column_data{projectnumber} = "<td>$ap->{projectnumber}&nbsp;</td>";
    $column_data{transdate} = "<td>$ap->{transdate}&nbsp;</td>";
    $column_data{invnumber} = qq|<td><a href= $ap->{tip}.pl?action=edit&path=$form->{path}&id=$ap->{id}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ap->{invnumber}</a></td>|;
    $column_data{customer} = "<td>$ap->{customer}&nbsp;</td>";
    $column_data{netincome} ="<td align=right>".$form->format_amount(\%myconfig, $ap->{netincome}, 2, "&nbsp;") . "</td>";
    $column_data{incomeaccno} = $ap->{customer} ? "<td>$ap->{accno}--$ap->{description}&nbsp;</td>" : "<td>&nbsp;</td>";
    $column_data{vendor} = "<td>$ap->{vendor}&nbsp;</td>";
    $column_data{netcost} ="<td align=right>".$form->format_amount(\%myconfig, $ap->{netcost}, 2, "&nbsp;") . "</td>";
    $column_data{costaccno} = $ap->{vendor} ? "<td>$ap->{accno}--$ap->{description}&nbsp;</td>" : "<td>&nbsp;</td>";
    $column_data{profit}="<td></td>";
    $column_data{margin}="<td></td>";

    $i++;
    $i %= 2;
    if($form->{l_osubtotal} ne 'Y') {
      print "<tr class=listrow$i >";    
      map { print "\n$column_data{$_}" } @column_index;
      print qq|
	</tr>
      |;
    }
    $subtotal = 1;
      $ap=$apnext;

  }
  
  if (($form->{l_subtotal} eq 'Y') && $subtotal) {
    &pr_subtotal;
  }
  
  # print totals
  print qq|
        <tr class=listtotal>
|;
  

  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;

 $column_data{netincome} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalnetincome, 2, "&nbsp;")."</th>";
  $column_data{netcost} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalnetcost, 2, "&nbsp;")."</th>";
  $column_data{profit} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalnetincome-$totalnetcost, 2, "&nbsp;")."</th>";
  $column_data{margin} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, 
   $totalnetcost ? (($totalnetincome-$totalnetcost)/$totalnetcost) * 100 : 0, 2, "&nbsp;")."</th>";
  
  $column_data{due} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totaldue, 2, "&nbsp;")."</th>";

  map { print "$column_data{$_}\n" } @column_index;


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

<input type=hidden name=vendor value="$form->{vendor}">
<input type=hidden name=vendor_id value=$form->{vendor_id}>
<input type=hidden name=vc value=vendor>

<input name=callback type=hidden value="$form->{callback}">
  
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

sub pr_subtotal {
  my $elso=$column_data{@column_index[0]};
  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
  $column_data{@column_index[0]}=$elso if ($form->{l_osubtotal} eq 'Y');
  $column_data{netincome} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalnetincome, 2, "&nbsp;")."</th>";
  $column_data{netcost} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalnetcost, 2, "&nbsp;")."</th>";
  $column_data{profit} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, $subtotalnetincome-$subtotalnetcost, 2, "&nbsp;")."</th>";
  $column_data{margin} = "<th class=listsubtotal align=right>".$form->format_amount(\%myconfig, 
  $subtotalnetcost ? (($subtotalnetincome-$subtotalnetcost)/$subtotalnetcost) * 100 : 0, 2, "&nbsp;")."</th>";
  $subtotalnetincome = 0;
  $subtotalnetcost = 0;
                            
  print "<tr class=listsubtotal>";
                              
  map { print "\n$column_data{$_}" } @column_index;
                                
  print qq|
        </tr>
|;
}
                                    