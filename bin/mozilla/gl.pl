#=====================================================================
# SQL-Ledger Accounting
# Copyright (c) 2001
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#  Modified by Tavugyvitel Kft. (info@tavugyvitel.hu)
#
# Contributors:
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
# Genereal Ledger
#
#======================================================================


use SL::GL;
use SL::PE;
use SL::CP;
use SL::CORE2;
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
  $form->{title} = "Edit" if ($form->{oldid});
  $form->{callback} = "$form->{script}?action=add&transfer=$form->{transfer}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&cash=$form->{cash}&sab=$form->{sab}" unless $form->{callback};

#kabai
  $form->{callback} = "$form->{script}?action=add&transfer=$form->{transfer}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&cash=$form->{cash}&lastdate=$form->{lastdate}&check=$form->{check}&reference=$form->{reference}&sab=$form->{sab}" unless $form->{callback};
  my $lastdate = $form->{lastdate};
#kabai $KS
  # we use this only to set a default date
  $form->{showaccnumbers_true} =  $showaccnumbers_true;
  GL->transaction(\%myconfig, \%$form, $form->{sab});
#kabai
  $form->{transdate} = $lastdate if ($lastdate && $form->{sab}!=2); #KS
  $form->{reference}=$form->{lastreference} if ($form->{lastdate} && $form->{sab}!=2);
  $form->{id}=$form->{oldid};
#   map { $form->{selectaccno} .= "<option>$_->{accno}--$_->{description}\n" } @{ $form->{all_accno} };
  if ($showaccnumbers_true){
   map { $form->{selectaccno} .= "<option value=$_->{accno}>$_->{accno}--$_->{description}\n" } @{ $form->{all_accno} };
   map  { $form->{selectaccno2} .= "<option value=$_->{accno}>$_->{accno}--$_->{description}\n" } @{ $form->{all_accno2} };
  }else{
   map { $form->{selectaccno} .= "<option value=$_->{accno}>$_->{description}\n" } @{ $form->{all_accno} };
   map  { $form->{selectaccno2} .= "<option value=$_->{accno}>$_->{description}\n" } @{ $form->{all_accno2} };
  }
#kabai
  if ($form->{all_projects}) {
    $form->{selectprojectnumber} = "<option>\n";
    map { $form->{selectprojectnumber} .= qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n| } @{ $form->{all_projects} };
  }
  
  $form->{rowcount} = 2;

  # departments
  $form->all_departments(\%myconfig);
  if (@{ $form->{all_departments} }) {
    $form->{selectdepartment} = "<option>\n";

    map { $form->{selectdepartment} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| } (@{ $form->{all_departments} });
  }

#kabai
   if ($form->{cash}){
    # registered sources
    my $regcheck = $form->{check} ? "1" : "0" ;
    $form->{selectregsource} = qq|<option value=0>| . $locale->text("odd number") . qq|</option>\n|;

    while ($form->{selectaccno} =~ /value=(\d+)/g){
      map { $form->{selectregsource} .= qq|<option value=$_->{regnum}>$_->{regnum}</option>\n| if ($_->{regnum_accno} eq $1 && $_->{regcheck} == $regcheck)} (@{$form->{all_sources}});
    }					      
    map { $form->{"regacc_$_->{regnum_accno}"} = "$_->{regnum}" if $_->{regcheck} == $regcheck; $form->{"vcurr_$_->{regnum_accno}"} = "$_->{vcurr}" if $_->{regcheck} == $regcheck; $form->{regaccounts} .= "$_->{regnum_accno}"." " if $_->{regcheck} == $regcheck} (@{$form->{all_sources}});
   }
#kabai 
 
#KS
  if ($form->{sab}==2) {&rows_value}
#   $form->{rowcount} = ($form->{transfer}) ? 2 : 9;
  &display_form;
  
}


sub edit {
$form->{showaccnumbers_true} =1 if $showaccnumbers_true;
  GL->transaction(\%myconfig, \%$form, , $form->{sab});
#   map { $form->{selectaccno} .= "<option>$_->{accno}--$_->{description}\n" } @{ $form->{all_accno} };
   if ($showaccnumbers_true){
    map { $form->{selectaccno} .= "<option value=$_->{accno}>$_->{accno}--$_->{description}\n" } @{ $form->{all_accno} };
    map  { $form->{selectaccno2} .= "<option value=$_->{accno}>$_->{accno}--$_->{description}\n" } @{ $form->{all_accno2} };
   }else{
    map { $form->{selectaccno} .= "<option value=$_->{accno}>$_->{description}\n" } @{ $form->{all_accno} };
    map  { $form->{selectaccno2} .= "<option value=$_->{accno}>$_->{description}\n" } @{ $form->{all_accno2} };
   }
#kabai

  # projects
  if ($form->{all_projects}) {
    $form->{selectprojectnumber} = "<option>\n";
    map { $form->{selectprojectnumber} .= qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n| } @{ $form->{all_projects} };
  }

  
  # departments
  $form->all_departments(\%myconfig);
  if (@{ $form->{all_departments} }) {

    $form->{department} = "$form->{department}--$form->{department_id}";

    $form->{selectdepartment} = "<option>\n";

    map { $form->{selectdepartment} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| } (@{ $form->{all_departments} });
  }
#kabai
   if ($form->{cash}){
    # registered sources
    my $regcheck = $form->{check} ? "1" : "0" ;
    $form->{selectregsource} = qq|<option value=0>| . $locale->text("odd number") . qq|</option>\n|;

    while ($form->{selectaccno} =~ /value=(\d+)/g){
      map { $form->{selectregsource} .= qq|<option value=$_->{regnum}>$_->{regnum}</option>\n| if ($_->{regnum_accno} eq $1 && $_->{regcheck} == $regcheck)} (@{$form->{all_sources}});
    }					      
    map { $form->{"regacc_$_->{regnum_accno}"} = "$_->{regnum}" if $_->{regcheck} == $regcheck; $form->{"vcurr_$_->{regnum_accno}"} = "$_->{vcurr}" if $_->{regcheck} == $regcheck; $form->{regaccounts} .= "$_->{regnum_accno}"." " if $_->{regcheck} == $regcheck} (@{$form->{all_sources}});
    (my $code, my $regnumber) = $form->{reference}=~ /^(\p{IsAlpha}+)\p{IsDigit}+$/;
    foreach $item (split / /, $form->{regaccounts}) {
      if ($form->{"regacc_$item"} =~/$code/){
        $form->{currency} = $form->{"vcurr_$item"};
      }
    }
   }
#kabai 
  $form->{locked} = ($form->{revtrans}) ? '1' : 
   (($form->datetonum($form->{transdate}, \%myconfig) <= $form->datetonum($form->{closedto}, \%myconfig)) && $form->{sab}!=1);

  # readonly
#kabai +1
  $form->{readonly} = 1 if $myconfig{acs} =~ /Accountant--Add Transaction/; 

  $form->{title} = "Edit";
  
  &form_header;

  $i = 1;
  foreach $ref (@{ $form->{GL} }) {

#kabai    $form->{"accno_$i"} = "$ref->{accno}--$ref->{description}";
    $form->{"accno_$i"} = $ref->{accno};
#kabai
    $form->{"projectnumber_$i"} = "$ref->{projectnumber}--$ref->{project_id}";
    $form->{"fx_transaction_$i"} = $ref->{fx_transaction};
    
    if ($ref->{amount} < 0) {
      $form->{totaldebit} -= $ref->{amount};
      $form->{"debit_$i"} = $form->format_amount(\%myconfig, $ref->{amount} * -1, 2);
    } else {
      $form->{totalcredit} += $ref->{amount};
      $form->{"credit_$i"} = ($ref->{amount} > 0) ? $form->format_amount(\%myconfig, $ref->{amount}, 2) : "";
    }

    $i++;
  }

  $form->{rowcount} = $i;
 &rows_value;     
  &display_rows;
  &form_footer;
}

sub rows_value {
  $i = 1;
  foreach $ref (@{ $form->{GL} }) {
    
    #kabai    $form->{"accno_$i"} = "$ref->{accno}--$ref->{description}";
    $form->{"accno_$i"} = $ref->{accno};
#kabai
    $form->{"projectnumber_$i"} = "$ref->{projectnumber}--$ref->{project_id}";
    $form->{"fx_transaction_$i"} = $ref->{fx_transaction};
	
    if ($ref->{amount} < 0) {
      $form->{totaldebit} -= $ref->{amount};
      $form->{"debit_$i"} = $form->format_amount(\%myconfig, $ref->{amount} * -1, 2);
    } else {
      $form->{totalcredit} += $ref->{amount};
      $form->{"credit_$i"} = ($ref->{amount} > 0) ? $form->format_amount(\%myconfig, $ref->{amount}, 2) : "";
    }
						    
    $i++;
  }
				  
  $form->{rowcount} = $i;
				    
}
							    							    

sub search {

#KS
 # $form->{title} = $locale->text('General Ledger')." ".$locale->text('Reports');
 ($form->{title}, $null)=reverse split /--/, $form->{level};
# $form->{title} = $locale->text((($form->{listtype} eq "T") ? 'GL Templates' : 'General Ledger'))." ".$locale->text('Reports');
 $form->{title}=$locale->text($form->{title})." ".$locale->text('Reports');    
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
#kabai
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

<input type=hidden name=journal value="$form->{journal}">
<input type=hidden name=sort value=transdate>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Reference').qq|</th>
	  <td><input name=reference size=20></td>
	  <th align=right>|.$locale->text('Source').qq|</th>
	  <td><input name=source size=20></td>
	</tr>
	$department
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td colspan=3><input name=description size=40></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Notes').qq|</th>
	  <td colspan=3><input name=notes size=40></td>
	</tr>

	<tr>
	  <th align=right>|.$locale->text('Order Number').qq|</th>
	  <td><input name=ordnumberfrom size=11 ></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=ordnumberto size=11></td>
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
	  <th align=right>|.$locale->text('ID').qq| >=</th>
	  <td><input name=idfrom size=11></td>
	  <th align=right>|.$locale->text('ID').qq| <=</th>
	  <td><input name=idto size=11></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Include in Report').qq|</th>
	  <td colspan=3>
	    <table>    
	      <tr>
		<td>
		  <input name="category" type=hidden value=X>|;
	if (!$form->{listtype}!='T') { print qq|		  
		  <input name="journal" class=radio type=radio value=all checked>&nbsp;|.$locale->text('All').qq|
		  <input name="journal" class=radio type=radio value=gl>&nbsp;|.$locale->text('GL').qq|
		  <input name="journal" class=radio type=radio value=cash>&nbsp;|.$locale->text('CASH').qq|
		  <input name="journal" class=radio type=radio value=ar>&nbsp;|.$locale->text('AR').qq|
		  <input name="journal" class=radio type=radio value=ap>&nbsp;|.$locale->text('AP').qq|
	    |;}
	    print qq|  
		</td>
	      </tr>
	      <tr>
		<table>
		  <tr>
		    <td align=right><input name="l_id" class=checkbox type=checkbox value=Y></td>
		    <td>|.$locale->text('ID').qq|</td>
		    <td align=right><input name="l_transdate" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Date').qq|</td>
		    <td align=right><input name="l_reference" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Reference').qq|</td>
		    <td align=right><input name="l_description" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Description').qq|</td>
		    <td align=right><input name="l_notes" class=checkbox type=checkbox value=Y></td>
		    <td>|.$locale->text('Notes').qq|</td>
		  </tr>
		  <tr>
		    <td align=right><input name="l_debit" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Debit').qq|</td>
		    <td align=right><input name="l_credit" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Credit').qq|</td>
		    <td align=right><input name="l_source" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Source').qq|</td>
		    <td align=right><input name="l_ordnumber" class=checkbox type=checkbox value=Y></td>
		    <td>|.$locale->text('Order Number').qq|</td>
		    <td align=right><input name="l_duedate" class=checkbox type=checkbox value=Y></td>
		    <td>|.$locale->text('Due Date').qq|</td>
		  </tr>
		  <tr>
		    <td align=right><input name="l_accno" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Account').qq|</td>
		    <td align=right><input name="l_acc_descr" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Account Description').qq|</td>
		    <td align=right><input name="l_gifi_accno" class=checkbox type=checkbox value=Y></td>
		    <td>|.$locale->text('GIFI').qq|</td>
		    <td align=right><input name="l_gifi_descr" class=checkbox type=checkbox value=Y></td>
		    <td>|.$locale->text('GIFI Description').qq|</td>
		  </tr>
		  <tr>
		    <td align=right><input name="l_curr" class=checkbox type=checkbox value=Y></td>
		    <td>|.$locale->text('Currency').qq|</td>
		    <td align=right><input name="l_fxamount" class=checkbox type=checkbox value=Y></td>
		    <td>|.$locale->text('FX amount').qq|</td>
		  </tr>
		  <tr>
		    <td align=right><input name="l_subtotal" class=checkbox type=checkbox 
		    onClick="if (this.form.l_subtotal.checked) {this.form.l_subtotalo.checked=false;}" value=Y></td>
		    <td>|.$locale->text('Subtotal').qq|</td>
		    <td align=right><input name="l_subtotalo" class=checkbox type=checkbox
		    onClick="if (this.form.l_subtotalo.checked) {this.form.l_subtotal.checked=false;}" value=Y></td>
		    <td>|.$locale->text('Subtotal Only').qq|</td>
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

<input type=hidden name=nextsub value=generate_report>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
<input type=hidden name=listtype value="$form->{listtype}">
<input type=hidden name=tip value="$form->{tip}">
<input type=hidden name=title value="$form->{title}">
<input type=hidden name=cash value="$form->{cash}">

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;
}

sub search_accno {

  $form->{title} = $locale->text('Accounts')." ".$locale->text('Reports');

  $form->{showaccnumbers_true} =1 if $showaccnumbers_true;
  GL->transaction(\%myconfig, \%$form);
#   $form->{selectaccno}="<option>";
   if ($showaccnumbers_true){
    map  { $form->{selectaccno} .= "<option value=$_->{accno}>$_->{accno}--$_->{description}\n" } @{ $form->{all_accno2} };
   }else{
    map  { $form->{selectaccno} .= "<option value=$_->{accno}>$_->{description}\n" } @{ $form->{all_accno2} };
   }
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

<input type=hidden name=sort value=transdate>
<input type=hidden name=category value=X>
<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Account From').qq|</th>
	  <td><select name=accnofrom class="shrink" 
	  onClick="if(document.forms[0].accnoto.value<document.forms[0].accnofrom.value){
	  document.forms[0].accnoto.value=document.forms[0].accnofrom.value}">
	   $form->{selectaccno}</select></td>
        </tr><tr>
	  <th align=right>|.$locale->text('Account To').qq|</th>
	  <td><select name=accnoto class="shrink" 
	  onClick="if(document.forms[0].accnoto.value<document.forms[0].accnofrom.value){
	  document.forms[0].accnoto.value=document.forms[0].accnofrom.value}">
	  $form->{selectaccno}</select></td>
	</tr>

	<tr>
	  <th align=right>|.$locale->text('GIFI').qq|</th>
	  <td><input name=gifi_accno size=20></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Reference').qq|</th>
	  <td><input name=reference size=20></td>
	  <th align=right>|.$locale->text('Source').qq|</th>
	  <td><input name=source size=20></td>
	</tr>
	$department
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td colspan=3><input name=description size=40></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Notes').qq|</th>
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
		    <td align=right><input name="l_reference" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Reference').qq|</td>
		    <td align=right><input name="l_description" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Description').qq|</td>
		    <td align=right><input name="l_notes" class=checkbox type=checkbox value=Y></td>
		    <td>|.$locale->text('Notes').qq|</td>
		  </tr>
		  <tr>
		    <td align=right><input name="l_debit" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Debit').qq|</td>
		    <td align=right><input name="l_credit" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Credit').qq|</td>
		    <td align=right><input name="l_source" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Source').qq|</td>
		    <td align=right><input name="l_counteraccno" class=checkbox type=checkbox value=Y checked></td>
		    <td>|.$locale->text('Counter Accno').qq|</td>

		  </tr>
		  <tr>
		    <td align=right><input name="l_subtotal" class=checkbox type=checkbox 
		    onClick="if (this.form.l_subtotal.checked) {this.form.l_subtotalo.checked=false;
		      this.form.l_totalo.checked=false;}" value=Y></td>
		    <td>|.$locale->text('Subtotal').qq|</td>
		    <td align=right><input name="l_subtotalo" class=checkbox type=checkbox
		    onClick="if (this.form.l_subtotalo.checked) {this.form.l_subtotal.checked=false;
		      this.form.l_totalo.checked=false;}" value=Y></td>
		    <td>|.$locale->text('Subtotal Only').qq|</td>
		    <td align=right><input name="l_totalo" class=checkbox type=checkbox
		    onClick="if (this.form.l_totalo.checked) {this.form.l_subtotalo.checked=false;
		      this.form.l_subtotal.checked=false;}" value=Y></td>
		    <td>|.$locale->text('Total Only').qq|</td>
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

<input type=hidden name=nextsub value=whatreport>

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
sub whatreport {
  if ($form->{gifi_accno}) {
    &generate_report;
  }else {
    &generate_accountreport;
  }  
}  

sub generate_accountreport {
if($form->{l_subtotalo} eq 'Y') {$form->{l_subtotal}='Y'};
  $form->{sort} = "transdate" unless $form->{sort};
  
  CORE2->get_accnos(\%myconfig, \%$form);
  $j = 0;
#Test
#$form->header;
#foreach $accnos (@{ $form->{get_accnos} }) {
#  print $accnos->{accno}; 
#}
#exit;
#Test
foreach $accnos (@{ $form->{get_accnos} }) {
  $form->{accno} = $accnos->{accno};
  $j++;
  @column_index = ();
  $subtotaldebit = 0;
  $subtotalcredit = 0;
  $totaldebit = 0;
  $totalcredit = 0;
  $form->{balance} = 0;
  delete $form->{GL};
  GL->all_transactions(\%myconfig, \%$form);
    
  $href = "$form->{script}?action=generate_accountreport&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $form->sort_order();

  $callback = "$form->{script}?action=generate_accountreport&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  %acctype = ( 'A' => $locale->text('Asset'),
               'C' => $locale->text('Contra'),
               'L' => $locale->text('Liability'),
	       'Q' => $locale->text('Equity'),
	       'I' => $locale->text('Income'),
	       'E' => $locale->text('Expense'),
	     );
  
  $form->{title} = $locale->text('Accounts')." ".$locale->text('Reports'). "&nbsp;&nbsp;&nbsp;&nbsp;" .$locale->text('Printed'). ": " .$form->current_date(\%myconfig);;
  
  $ml = ($form->{ml} =~ /(A|E)/) ? -1 : 1;

  unless ($form->{category} eq 'X') {
    $form->{title} .= " : ".$locale->text($acctype{$form->{category}});
  }
  if ($form->{accnofrom}) {
    $href .= "&accnofrom=".$form->escape($form->{accnofrom});
    $callback .= "&accnofrom=".$form->escape($form->{accnofrom},1);
    $option = $locale->text('Account')." : $form->{accno} $form->{account_description}";
  }
  if ($form->{accnoto}) {
    $href .= "&accnoto=".$form->escape($form->{accnoto});
    $callback .= "&accnoto=".$form->escape($form->{accnoto},1);
    $option = $locale->text('Account')." : $form->{accno} $form->{account_description}";
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
#KS
  $form->{l_tempname}="Y"  if( $form->{listtype} eq "T");
  
  
  @columns = $form->sort_columns(qw(transdate id reference description notes source debit credit accno gifi_accno ordnumber curr fxamount duedate acc_descr gifi_descr));

  if ($form->{link} =~ /_paid/) {
    @columns = $form->sort_columns(qw(transdate id reference description notes source cleared debit credit accno gifi_accno));
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
  if ($form->{l_subtotalo} eq 'Y') {
    $callback .= "&l_subtotalo=Y";
    $href .= "&l_subtotalo=Y";
  }
  if ($form->{l_totalo} eq 'Y') {
    $callback .= "&l_totalo=Y";
    $href .= "&l_totalo=Y";
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
  $column_header{notes} = "<th class=listheading>".$locale->text('Notes')."</th>";
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
if ($j == 1){ 
  $form->header;

  print qq|
<body>
<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
   <tr>
    <td>
|;
}
print qq|
  <table>
   <tr>
    <td>$option</td>
  </tr>
  </table>
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

    # if item ne sort print subtotal
    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $ref->{$form->{sort}}) {
	&gl_subtotal;
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
    $column_data{transdate} = "<td>$ref->{transdate}</td>";
    $column_data{reference} = "<td><a href=$ref->{module}.pl?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{reference}</a></td>";
    $column_data{description} = "<td>$ref->{description}&nbsp;</td>";
    $column_data{source} = "<td>$ref->{source}&nbsp;</td>";
    $column_data{notes} = "<td>$ref->{notes}&nbsp;</td>";
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
    if (!$form->{l_subtotalo} && !$form->{l_totalo}) {
      print "
        <tr class=listrow$i>";
      map { print "$column_data{$_}\n" } @column_index;
      print "</tr>";
    }
  }


  &gl_subtotal if ($form->{l_subtotal} eq 'Y');


  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
  
  $column_data{debit} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $totaldebit, 2, "&nbsp;")."</th>";
  $column_data{credit} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $totalcredit, 2, "&nbsp;")."</th>";
  $column_data{balance} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $form->{balance} * $ml, 2, 0)."</th>";
  
  print qq|
	<tr class=listtotal>
|;

  map { print "$column_data{$_}\n" } @column_index;

  $i = 1;
#kabai +1
  if ($myconfig{acs} !~ /Accountant--Add GL Transaction/) {
    $button{'GL--Add Transaction'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('GL Transaction').qq|"> |;
    $button{'GL--Add Transaction'}{order} = $i++;
  }
  if ($myconfig{acs} !~ /AR--AR/) {
    $button{'AR--Add Transaction'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('AR Transaction').qq|"> |;
    $button{'AR--Add Transaction'}{order} = $i++;
    $button{'AR--Sales Invoice'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Sales Invoice').qq|"> |;
    $button{'AR--Sales Invoice'}{order} = $i++;
  }
  if ($myconfig{acs} !~ /AP--AP/) {
    $button{'AP--Add Transaction'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('AP Transaction').qq|"> |;
    $button{'AP--Add Transaction'}{order} = $i++;
    $button{'AP--Vendor Invoice'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Vendor Invoice').qq|"> |;
    $button{'AP--Vendor Invoice'}{order} = $i++;
  }

  foreach $item (split /;/, $myconfig{acs}) {
    delete $button{$item};
  }
  
  print qq|
        </tr>
      </table>
|;
} # foreach get_accnos
print qq|
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

sub generate_report {
$form->{sort} = "transdate" unless $form->{sort};

  GL->all_transactions(\%myconfig, \%$form);
    
  $href = "$form->{script}?action=generate_report&listtype=$form->{listtype}&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $form->sort_order();

  $callback = "$form->{script}?action=generate_report&listtype=$form->{listtype}&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  %acctype = ( 'A' => $locale->text('Asset'),
               'C' => $locale->text('Contra'),
               'L' => $locale->text('Liability'),
	       'Q' => $locale->text('Equity'),
	       'I' => $locale->text('Income'),
	       'E' => $locale->text('Expense'),
	     );
#  $form->{title} = $locale->text('General Ledger');
  
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

  if ($form->{idfrom}) {
    $href .= "&idfrom=".$form->escape($form->{idfrom});
    $callback .= "&idfrom=".$form->escape($form->{idfrom},1);
    $option .= "\n<br>" if $option;
    $option .= $locale->text('ID from')." : $form->{idfrom}";
  }

  if ($form->{idto}) {
    $href .= "&idto=".$form->escape($form->{idto});
    $callback .= "&idto=".$form->escape($form->{idto},1);
    if ($form->{idfrom}) {
      $option .= " ";
    } else {
      $option .= "\n<br>" # if $option;
    }
    $option .= $locale->text('ID to')." : $form->{idto}";
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

  @columns = $form->sort_columns(qw(transdate id reference description tempname notes source debit credit accno gifi_accno ordnumber curr fxamount duedate acc_descr gifi_descr));
#KS
  $form->{l_tempname}="Y"  if( $form->{listtype} eq "T");
  
  if ($form->{link} =~ /_paid/) {
    @columns = $form->sort_columns(qw(transdate id reference description tempname notes source cleared debit credit accno gifi_accno));
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
  if ($form->{l_subtotalo} eq 'Y') {
    $callback .= "&l_subtotalo=Y";
    $href .= "&l_subtotalo=Y";
  }
  if ($form->{l_totalo} eq 'Y') {
    $callback .= "&l_totalo=Y";
    $href .= "&l_totalo=Y";
  }

  $callback .= "&category=$form->{category}";
  $href .= "&category=$form->{category}";
#kabai
  $callback .= "&journal=$form->{journal}";
  $href .= "&journal=$form->{journal}";
  $callback .= "&sab=$form->{sab}";
  $callback .= "&cash=$form->{cash}";
  $callback .= "&tip=$form->{tip}";
  $callback .= "&title=".$form->escape($form->{title});
  $href .= "&sab=$form->{sab}";
  $href .= "&cash=$form->{cash}";
  $href .= "&tip=$form->{tip}";
  $href .= "&title=".$form->escape($form->{title});
#kabai
  $column_header{id} = "<th><a class=listheading href=$href&sort=id>".$locale->text('ID')."</a></th>";
  $column_header{transdate} = "<th><a class=listheading href=$href&sort=transdate>".$locale->text('Date')."</a></th>";
  $column_header{reference} = "<th><a class=listheading href=$href&sort=reference>".$locale->text('Reference')."</a></th>";
  $column_header{tempname} = "<th><a class=listheading href=$href&sort=tempname>".$locale->text('Template name')."</a></th>";
  $column_header{source} = "<th><a class=listheading href=$href&sort=source>".$locale->text('Source')."</a></th>";
  $column_header{description} = "<th><a class=listheading href=$href&sort=description>".$locale->text('Description')."</a></th>";
  $column_header{notes} = "<th class=listheading>".$locale->text('Notes')."</th>";
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

    # if item ne sort print subtotal
    if ($form->{l_subtotal} eq 'Y') {
      if ($sameitem ne $ref->{$form->{sort}}) {
      &gl_subtotal;
      }
    }
    
    $form->{balance} += $ref->{amount};
    
    $subtotaldebit += $ref->{debit};
    $subtotalcredit += $ref->{credit};
    
    $totaldebit += $ref->{debit};
    $totalcredit += $ref->{credit};

    $ref->{debit} = $form->format_amount(\%myconfig, $ref->{debit}, 2, "&nbsp;");
    $ref->{credit} = $form->format_amount(\%myconfig, $ref->{credit}, 2, "&nbsp;");
#    $ref->{tempname}=escape($ref->{tempname});
    $column_data{id} = "<td>$ref->{id}</td>";
    $column_data{transdate} = "<td>$ref->{transdate}</td>";
#KS
    if ($form->{listtype} ne "T") {
      $column_data{reference} ="<td><a href=$ref->{module}.pl?action=edit&id=$ref->{id}&cash=$form->{cash}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{reference}</td>";     
      $column_data{tempname} = "<td>$ref->{tempname}&nbsp;</td>";
     }else{
      $column_data{tempname} ="<td><a href=$ref->{module}.pl?action=edit&id=$ref->{id}&template=$ref->{id}&cash=$form->{cash}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback&sab=1>$ref->{tempname}</td>";
      $column_data{reference} = "<td>$ref->{reference}&nbsp;</td>";
    }
#/KS
#    $column_data{reference} = "<td><a href=$ref->{module}.pl?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{reference}</td>";
    $column_data{description} = "<td>$ref->{description}&nbsp;</td>";
    $column_data{source} = "<td>$ref->{source}&nbsp;</td>";
    $column_data{notes} = "<td>$ref->{notes}&nbsp;</td>";
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
    if (!$form->{l_subtotalo} && !$form->{l_totalo}){ 
      print "
        <tr class=listrow$i>";
      map { print "$column_data{$_}\n" } @column_index;
      print "</tr>";
    }
  }


  &gl_subtotal if ($form->{l_subtotal} eq 'Y');


  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
  
  $column_data{debit} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $totaldebit, 2, "&nbsp;")."</th>";
  $column_data{credit} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $totalcredit, 2, "&nbsp;")."</th>";
  $column_data{balance} = "<th align=right class=listtotal>".$form->format_amount(\%myconfig, $form->{balance} * $ml, 2, 0)."</th>";
  
  print qq|
	<tr class=listtotal>
|;

  map { print "$column_data{$_}\n" } @column_index;

  $i = 1;
#kabai +1 #KS
if ($form->{listtype} ne "T") {
  if ($myconfig{acs} !~ /Accountant--Add GL Transaction/) {
    $button{'GL--Add Transaction'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('GL Transaction').qq|"> |;
    $button{'GL--Add Transaction'}{order} = $i++;
  }
  if ($myconfig{acs} !~ /AR--AR/) {
    $button{'AR--Add Transaction'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('AR Transaction').qq|"> |;
    $button{'AR--Add Transaction'}{order} = $i++;
    $button{'AR--Sales Invoice'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Sales Invoice').qq|"> |;
    $button{'AR--Sales Invoice'}{order} = $i++;
  }
  if ($myconfig{acs} !~ /AP--AP/) {
    $button{'AP--Add Transaction'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('AP Transaction').qq|"> |;
    $button{'AP--Add Transaction'}{order} = $i++;
    $button{'AP--Vendor Invoice'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Vendor Invoice').qq|"> |;
    $button{'AP--Vendor Invoice'}{order} = $i++;
  }

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

sub gl_subtotal {
 if ($sameitem){
    my $elso=$column_data{@column_index[0]};
    map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
    $column_data{@column_index[0]}=$elso if ($form->{l_subtotalo} eq 'Y');
             
    $subtotaldebit = $form->format_amount(\%myconfig, $subtotaldebit, 2, "&nbsp;");
    $subtotalcredit = $form->format_amount(\%myconfig, $subtotalcredit, 2, "&nbsp;");
  
#  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;

    $column_data{debit} = "<th align=right class=listsubtotal>$subtotaldebit</td>";
    $column_data{credit} = "<th align=right class=listsubtotal>$subtotalcredit</td>";

  
    print "<tr class=listsubtotal>";
    map { print "$column_data{$_}\n" } @column_index;
    print "</tr>";
  }
  $subtotaldebit = 0;
  $subtotalcredit = 0;

  $sameitem = $ref->{$form->{sort}};

}


sub update {

  @a = ();
  $count = 0;
  @flds = qw(accno debit credit projectnumber);

  for $i (1 .. $form->{rowcount}) {

    unless (($form->{"debit_$i"} eq "") && ($form->{"credit_$i"} eq "")) {
      # take accno apart
#kabai      ($form->{"accno_$i"}) = split(/--/, $form->{"accno_$i"});
      
      push @a, {};
      $j = $#a;
      
      map { $a[$j]->{$_} = $form->{"${_}_$i"} } @flds;
      $count++;
    }
  }
#kabai
   for my $r (1..$form->{rowcount}){ # which is the first cash account?

     if ($form->{regaccounts}=~ /$form->{"accno_$r"}/){
       $regsourcevalue = "regacc_".$form->{"accno_$r"};
       my $vcurrvalue = "vcurr_".$form->{"accno_$r"};
       $form->{currency} =  $form->{$vcurrvalue};
       last;
     }
   }
    $form->{regsource} = $form->{reference} ? "0" : $form->{$regsourcevalue};
   $form->{selectregsource} =~ s/ selected//;
   $form->{selectregsource} =~ s/(<option value=\Q$form->{regsource}\E)/$1 selected/ if $form->{regsource}; 
#kabai
  for $i (1 .. $count) {
    $j = $i - 1;
    map { $form->{"${_}_$i"} = $a[$j]->{$_} } @flds;
  }

  for $i ($count + 1 .. $form->{rowcount}) {
    map { delete $form->{"${_}_$i"} } @flds;
  }
  $form->{rowcount} = $count + 1;
  $form->{rowcount} = 2 if $count==0;
  
#kabai
 if ($form->{callback} =~ /gl.pl/){
  $form->{callback} = "$form->{script}?action=add&transfer=$form->{transfer}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&cash=$form->{cash}&lastdate=$form->{transdate}&lastreference=$form->{reference}&accno_1=$form->{accno_1}&check=$form->{check}";
 }
#kabai
&display_form;
  
}


sub display_form {

  &form_header;
  &display_rows;
  &form_footer;

}


sub display_rows {
  $form->{selectprojectnumber} = $form->unescape($form->{selectprojectnumber});
	  
  $form->{totaldebit} = 0;
  $form->{totalcredit} = 0;
  $form->{param}=$form->format_amount(\%myconfig, $form->parse_amount(\%myconfig,$form->{param}), 2);
  for $i (1 .. $form->{rowcount}) {
 
    $form->{totaldebit} += $form->parse_amount(\%myconfig, $form->{"debit_$i"});
    $form->{totalcredit} += $form->parse_amount(\%myconfig, $form->{"credit_$i"});

    $selectaccno = $form->{selectaccno};
#kabai

#    if ($form->{transfer}){
    $selectaccno =~ s/(<option value=$form->{"accno_$i"})/$1 selected/ if $form->{"accno_$i"};
#$form->error($selectaccno);
#    }else{
#    $selectaccno =~ s/option>\Q$form->{"accno_$i"}\E/option selected>$form->{"accno_$i"}/ if $form->{"accno_$i"};
#    }
#kabai
    if ($form->{selectprojectnumber}) {
      $selectprojectnumber = $form->{selectprojectnumber};
      $selectprojectnumber =~ s/(<option value="$form->{"projectnumber_$i"}")/$1 selected/;
      
      $project = qq|
  <td><select name="projectnumber_$i">$selectprojectnumber</select></td>|;
    }
    
  
    if ($form->{transfer}) {
      $form->{"fx_transaction_$i"} = ($form->{"fx_transaction_$i"}) ? "checked" : "";
      $fx_transaction = qq|
  <td align=center><input name="fx_transaction_$i" class=checkbox type=checkbox value=1 $form->{"fx_transaction_$i"}></td>
|;
    } else {
      $fx_transaction = qq|
    <input type=hidden name="fx_transaction_$i" value=$form->{"fx_transaction_$i"}>
|;
    }

#kabai
 if ($form->{transfer}){
  if(!$form->{id}){
   if($i == 1){
     if ($form->{sab}!=1){
       $balance = $form->get_balance(\%myconfig, \%$form) if $form->{sab} !=1;
       $balance += ($form->parse_amount(\%myconfig, $form->{debit_1}) - $form->parse_amount(\%myconfig, $form->{credit_1}));
       $balance = $form->format_amount(\%myconfig, $balance, 2);   
      }
    }else{
      $balance = "";
      $selectaccno = $form->{selectaccno2};
      $selectaccno =~ s/(<option value=$form->{"accno_$i"})/$1 selected/ if $form->{"accno_$i"};
    }
  }else{
     $selectaccno = $form->{selectaccno2};
     $selectaccno =~ s/(<option value=$form->{"accno_$i"})/$1 selected/ if $form->{"accno_$i"};
  }
 }
#kabai
#kabai +2
my $accn=$form->{accno_1};
#$accn=$form->{"regacc_$accn"};
my $noid = $form->{id} ? 0 : 1;
my $och= ($i==1) ? qq| Onchange="return regaccall();"| : null;
print qq|<tr>
  <td><select class="shrink" name="accno_$i"$och>$selectaccno</select>&nbsp;$balance</t d>
  $fx_transaction|;
  if ($form->{sab}==2 && $form->{"debit_$i"} && $form->{param}) {$form->{"debit_$i"}=$form->{param}}
  if ($form->{sab}==2 && $form->{"credit_$i"} && $form->{param}) {$form->{"credit_$i"}=$form->{param}}

  print qq|
  <td align=center><input name="debit_$i" 
  onchange="if ($i==$noid){document.forms[0].credit_2.value=document.forms[0].debit_1.value}" 
  size=12 value=|.$form->format_amount(\%myconfig, $form->parse_amount(\%myconfig, $form->{"debit_$i"}), 2).qq|></td>
  <td align=center><input name="credit_$i" 
  onchange="if ($i==$noid){document.forms[0].debit_2.value=document.forms[0].credit_1.value}" 
  size=12 value=|.$form->format_amount(\%myconfig, $form->parse_amount(\%myconfig, $form->{"credit_$i"}), 2).qq|></td>
  $project
</tr>

|;
  }

#kabai +4
  print qq|
<input type=hidden name=rowcount value=$form->{rowcount}>
<input type=hidden name=selectaccno value="$form->{selectaccno}">
<input type=hidden name=selectaccno2 value="$form->{selectaccno2}">
<input type=hidden name=selectprojectnumber value="|.$form->escape($form->{selectprojectnumber},1).qq|">|;

}


sub form_header {
$title = $form->{title};
  if ($form->{transfer}) {
    $form->{title} = $locale->text("$title Bank Transfer " .(($form->{sab}==1) ? "Template" : "Transaction"));
    $reference_text = "Bank source";
    $notes_text = "Notes";
  } else { #if transfer
    $form->{title} = $locale->text("$title General Ledger ".(($form->{sab}==1) ? "Template" : "Transaction"));
    $reference_text = "Reference";
    $notes_text = "Notes";
  }
  if ($form->{cash}) {
    $form->{title} = $locale->text("$title Cash Transfer ".(($form->{sab}==1) ? "Template" : "Transaction"));
    $reference_text = "Cash voucher number";
    $notes_text = "Partner";
    $vcurr= qq|
	<tr>
	  <th align=right>|.$locale->text('Currency').qq|</th>
	  <td colspan=2><input name=currency size=3 maxlength="3" value="$form->{currency}"></td>
	</tr>
    |;
   if (!$form->{id} && $form->{sab}!=1){
    $form->{regsource} = $form->{reference} ? "0" : $form->{regsource};
    $form->{selectregsource} =~ s/ selected//;
    $form->{selectregsource} =~ s/(<option value=\Q$form->{regsource}\E)/$1 selected/ if $form->{regsource}; 
    $selectregsource = qq|<select name="regsource" OnChange="return refall();"> $form->{selectregsource}</select>|;
   }
  }
# $locale->text('Add Cash Transfer Transaction')
# $locale->text('Edit Cash Transfer Transaction')
# $locale->text('Add General Ledger Transaction')
# $locale->text('Edit General Ledger Transaction')

  $form->{selectdepartment} = $form->unescape($form->{selectdepartment});
  $form->{selectdepartment} =~ s/ selected//;
  $form->{selectdepartment} =~ s/(<option value="\Q$form->{department}\E")/$1 selected/;

  map { $form->{$_} = $form->quote($form->{$_}) } qw(reference description notes);

  if (($rows = $form->numtextrows($form->{description}, 50)) > 1) {
    $description = qq|<textarea name=description rows=$rows cols=50 wrap=soft>$form->{description}</textarea>|;
  } else {
    $description = qq|<input name=description size=50 value="$form->{description}">|;
  }
#KS
  my $clr=($form->{sab}==1) ? "" : "required";  
  my $classreq = qq|class="required"| if ($form->{cash} && ($form->{sab}!=1)) ;
  my $classreq2 = qq|class="required"| if (!$form->{cash} && ($form->{sab}!=1)) ;
  if (($rows = $form->numtextrows($form->{notes}, 50)) > 1) {
    $notes = qq|<textarea name=notes $classreq rows=$rows cols=50 wrap=soft>$form->{notes}</textarea>|;
  } else {
    $notes = qq|<input name=notes $classreq size=50 value="$form->{notes}">|;
  }
  
  $department = qq|
  	<tr>
	  <th align=right nowrap>|.$locale->text('Department').qq|</th>
	  <td colspan=3><select name=department>$form->{selectdepartment}</select></td>
	  <input type=hidden name=selectdepartment value="|.$form->escape($form->{selectdepartment},1).qq|">
	</tr>
| if $form->{selectdepartment};

  $project = qq| 
	  <th class=listheading>|.$locale->text('Project').qq|</th>
| if $form->{selectprojectnumber};

  if ($form->{transfer}) {
    $fx_transaction = qq|
	  <th class=listheading>|.$locale->text('FX').qq|</th>
|;
  }
    
#kabai
  foreach $item (split / /, $form->{regaccounts}) {
#KS
    $hiddenregacc.= qq|<input type=hidden id="regacc_$item" name="regacc_$item" value=$form->{"regacc_$item"}>\n|;
    $hiddenvcurr.= qq|<input type=hidden name="vcurr_$item" value="$form->{"vcurr_$item"}">\n|;
  }
  my $readonly;
  if ($strictcash_true && $form->{cash}) {
    $readonly = "readonly";
    if ($form->{id}){
      $form->{selectregsource} = "";
    }  
  }  
  $hidden = "class=noscreen" if ($form->{regsource} && $form->{sab}!=1);
#kabai 

  $form->header;

  print qq|
<body onload="return regaccall();">
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

<input name=id type=hidden value=$form->{id}>

<input type=hidden name=transfer value=$form->{transfer}>

<input type=hidden name=selectaccno value="$form->{selectaccno}">

<input type=hidden name=closedto value=$form->{closedto}>
<input type=hidden name=locked value=$form->{locked}>
<input type=hidden name=title value="$title">
<input type=hidden name=cash value=$form->{cash}>
<input type=hidden name=check value=$form->{check}>
<input type=hidden name=selectregsource value="$form->{selectregsource}">
<input type=hidden name=regaccounts value="$form->{regaccounts}">
<input type=hidden name=sab value="$form->{sab}">
<input type=hidden name=transfer value=$form->{transfer}>
<input type=hidden name=cash value=$form->{cash}>
$hiddenregacc
$hiddenvcurr
<font color='red'> $form->{sabment} </font>
<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th align=right>|.$locale->text($reference_text).qq|</th>
                <td>
                $selectregsource
                <input name=reference $classreq2 $readonly $hidden size=20 value="$form->{reference}">
                </td>  
	  <td align=right>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Date').qq|</th>
		<td><input name=transdate class="$clr" size=11 title="$myconfig{dateformat}" id=transdate OnBlur="return dattrans('transdate');" value=$form->{transdate}></td>
	      </tr>
	    </table>
	  </td>
	</tr>
	$department
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td colspan=2>$description</td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text($notes_text).qq|</th>
	  <td colspan=2>$notes</td>
	</tr>
        $vcurr|;
#KS
	
if ($form->{sab}==1) {
	  print qq|
	  <tr>
          <th align=right><b>|.$locale->text('Template name').qq|</b></th>
          <td><input name="tempname" class="required" size=50 value="$form->{tempname}"></td>
          </tr>|;
        }
      print qq|    
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
	  <th class=listheading>|.$locale->text('Account').qq|</th>
	  $fx_transaction
	  <th class=listheading>|.$locale->text('Debit (+)').qq|</th>
	  <th class=listheading>|.$locale->text('Credit (-)').qq|</th>
	  $project
	</tr>
|;

}


sub form_footer {
  ($dec) = ($form->{totaldebit} =~ /\.(\d+)/);
  $dec = length $dec;
  $decimalplaces = ($dec > 2) ? $dec : 2;
  
  map { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, $decimalplaces, "&nbsp;") } qw(totaldebit totalcredit);

  $project = qq|
	  <th>&nbsp;</th>
| if $form->{selectprojectnumber};

  if ($form->{transfer}) {
    $fx_transaction = qq|
	  <th>&nbsp;</th>
|;
  }
    
  print qq|
        <tr class=listtotal>
	  <th>&nbsp;</th>
	  $fx_transaction
	  <th class=listtotal align=center>$form->{totaldebit}</th>
	  <th class=listtotal align=center>$form->{totalcredit}</th>
	  $project
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input name=callback type=hidden value="$form->{callback}">

<br>
|;

  $transdate = $form->datetonum($form->{transdate}, \%myconfig);
  $closedto = $form->datetonum($form->{closedto}, \%myconfig);
  
  if (! $form->{readonly}) {
#KS
    if ($form->{id} ) {
       
      print qq|<input class=submit type=submit name=action value="|.$locale->text('Update').qq|">
      |;
	      
      if (!$form->{locked}) {
        print qq|
        <input class=submit type=submit name=action|;
#KS
	if ($form->{sab}!=1) {print qq| onclick="return checkform()"|}
        print qq| value="|
	  .$locale->text((($form->{sab}==1) ? 'Templatesave' : 'Post')).qq|">|;
	  print qq|
	   <input class=submit type=submit name=action value="|.$locale->text('Delete').qq|">
	  |;
      }						  
#KS
       if ($form->{sab}!=1){

         print qq|
	  <input class=submit type=submit name=action onclick="return checkform();" value="|.$locale->text('Post as new').qq|">
|;
       }

#kabai
	if ($form->{cash} && !$form->{sab}) {
		$form->{forms}{cash_voucher} = "Cash Voucher" unless ($form->{forms});
		$form->{format} = $myconfig{prformat} unless ($form->{format});
		$form->{media} = $myconfig{prmedia} unless ($form->{media});
		$form->{copies} = $myconfig{copies} unless ($form->{copies});
                print "<br><br>";
		&print_options;
	}
#kabai    
    }else{
#KS
      if ($transdate > $closedto || $form->{sab}!=0) {
	print qq|<input class=submit type=submit name=action value="|.$locale->text('Update').qq|">
	<input class=submit type=submit name=action|;
#KS
        if ($form->{sab}!=1) {print qq| onclick="return checkform()"|} print qq| value="|
	               .$locale->text((($form->{sab}==1) ? 'Templatesave' : 'Post')).qq|">|;
		       
       
      }
#KS
#NOT IMPLEMENTED YET
#<input class=submit type=submit name=action value="|.$locale->text('Save as template').qq|">
#    <th align=right nowrap><b>|.$locale->text('Template name').qq|</b></th>
#   <input name='tempname' value ='$form->{tempname}'>
#NOT IMPLEMENTED YET
  if ($form->{sab}!=1) {
    $form->{tip}=0;
    $form->{tip}=1 if ($form->{transfer}); 
    $form->{tip}=2 if ($form->{cash});
    GL->template_list(\%myconfig, \%$form);
    if ($form->{GL}){
      print qq|
      <br><br>
      <td align=right><th align=right nowrap><b>|.$locale->text('Select template').qq|</b><th>|;
      $selection="<option>";
      foreach $ref (@{ $form->{GL} }) {
        $selection .= "<option value=" . $ref->{id};
        $selection .=">".$ref->{tempname}."\n"
      }
      if ($form->{template}){
        my $si="value=".$form->{template};
        $selection =~s/$si/$si selected/;
      }
      print qq| <select name=template>$selection</select>
      <th align=right nowrap><b>|.$locale->text('Parameter').qq|</b></th>
      <input name=param value ='$form->{param}' size=12>
      <input type='submit' class='submit' 
      onclick= "if(document.forms[0].template.value==''){return false} else {return true}"
      value="|.$locale->text('Adopttemplate').qq|" name=action><td>
      </td>
      |;
    }
  }
#kabai
     if ($form->{sab}*1 !=1) {
	if ($form->{transfer}){
         if($form->{cash}){
          if($form->{check}){
          print qq|<br><br><input class="submit" type="submit" name="action" value="|
		. $locale->text ('AP_payment'). qq|">
              |;
          }else{
          print qq|<br><br><input class="submit" type="submit" name="action" value="|
		. $locale->text ('AR_payment'). qq|">
              |;
          }  
         }else{ 
           print qq|<br><br><input class="submit" type="submit" name="action" onclick="return checkform();" value="|
		. $locale->text ('AR_payment'). qq|">
                |;
           print qq|<input class="submit" type="submit" name="action" onclick="return checkform();" value="|
		. $locale->text ('AP_payment'). qq|">
                |;
         }
       }
     } #sab
#kabai	
       if ($form->{menubar}) {
         require "$form->{path}/menu.pl";
         &menubar;
       }
     }#form->id
   } #readonly    
  print "
  </form>

</body>
</html>
";


}


sub delete {

  $form->header;
  delete $form->{header};
  
  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->hide_form();  
  print qq|
<h2 class=confirm>|.$locale->text('Confirm!').qq|</h2>|;
#KS
   my $text1=($form->{sab}==1) ? ('Template') : ('Transaction');
   my $text2=($form->{sab}==1) ? $form->{tempname} : $form->{reference};
      
  print qq|
   <h4>|.$locale->text('Are you sure you want to delete '. $text1). qq| $text2</h4>

   <input name=action class=submit type=submit value="|.$locale->text('Yes').qq|">
  </form>
  </body>
  </html>
|;
    $form->{callback}="";

}


sub yes {
#KS
    #$form->{callback}="";
    my $text1=($form->{sab}==1) ? ('Template deleted!') : ('Transaction deleted!');
    my $text2=($form->{sab}==1) ? "Cannot delete template!" : "Cannot delete transaction!";
    my $tip= 1 if ($form->{sab}==1);
    $form->redirect($locale->text($text1)) if (GL->delete_transaction(\%myconfig, \%$form, $tip));
    $form->error($locale->text($text2));
}


sub post {
  if ($form->{mod_save}) {goto friss};
  $title = $form->{title};
  if ($form->{transfer}) {
		if ($form->{cash}) {
			$form->{title} = $locale->text("$title Cash Transfer Transaction");
			$reference_text = "Cash voucher number";
                         $form->isblank("notes", $locale->text('Partner missing!'));
			}
		else {
			$form->{title} = $locale->text("$title Bank Transfer Transaction");
			$reference_text = "Reference";
			}
  } else {
    $form->{title} = $locale->text("$title General Ledger Transaction");
		$reference_text = "Reference";
  }

  # check if there is something in reference and date
  $form->isblank("reference", $locale->text("$reference_text missing!")) if !$form->{regsource};
  $form->isblank("transdate", $locale->text('Transaction Date missing!'));

  $transdate = $form->datetonum($form->{transdate}, \%myconfig);
  $closedto = $form->datetonum($form->{closedto}, \%myconfig);

  
  $form->error($locale->text('Cannot post transaction for a closed period!')) if ($transdate <= $closedto);

  # add up debits and credits
  if (!$form->{adjustment}) {
    for $i (1 .. $form->{rowcount}) {
      my $debt=$form->parse_amount(\%myconfig, $form->{"debit_$i"});
      my $cret += $form->parse_amount(\%myconfig, $form->{"credit_$i"});
      $debit +=$debt; 
      $credit += $cret;
      my $ii=$form->{"accno_$i"};
      $form->{"sum_$ii"}+=$debt-$cret;
    }
    my $felso, $felsoh;
    for $i (1 .. $form->{rowcount}) {
      my $ii=$form->{"accno_$i"};
      $form->{cashaccount}=$ii;
      undef $form->{chart_id};
      AM->get_cashlimit(\%myconfig, \%$form);
      if ($form->{chart_id}){
        AM->get_sumcash(\%myconfig, \%$form);
        my $ossz=$form->{sumamount}+$form->{"sum_$ii"};
	if ($ossz < $form->{mincash}){
	  $form->error(qq|$ii |.$locale->text ('Under the Limit!')
	   .qq| (|.$form->format_amount(\%myconfig, $form->{mincash},2 ,0).qq|)|);
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
		    
  if (GL->post_transaction (\%myconfig, \%$form)) {
   if (!$post_and_print){
    if ($form->{cash} && $form->{callback} =~ /^gl/) {
      $form->{callback} = "$form->{script}?action=edit&id=$form->{id}&path=bin/mozilla&login=$form->{login}&sessionid=$form->{sessionid}&check=$form->{check}&callback=" . $form->escape($form->{callback});
      $form->{callback}.="&sabment=".$form->escape($form->{sabment});
    } else {
      $form->{callback}.="&sabment=".$form->escape($form->{sabment});
    }
    $form->redirect ($locale->text ('Transaction posted!'));
   }
  }else{
    $form->error($locale->text('Cannot post transaction!'));
  }   
  
}


sub post_as_new {

  $form->{id} = 0;
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
					   
#kabai
sub add_payments {
  $form->{callback}.= "&accno_1=$form->{accno_1}&lastdate=$form->{transdate}&lastreference=$form->{reference}";
  $form->{callback} = $form->escape($form->{callback},1);
  $form->{callback} = "cp.pl?all_vc=0&source=$form->{reference}&account=$form->{accno_1}&datepaid=$form->{transdate}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}&action=payment&vc=$form->{vc}&type=$form->{type}&cash=$form->{cash}&callback=$form->{callback}";
  $form->redirect;
  
}

sub ap_payment {
  $form->{vc} = "vendor";
  $form->{type} = "check";  
  &add_payments;

}

sub ar_payment {
  $form->{vc} = "customer";
  $form->{type} = "receipt";  
  &add_payments;

}

#kabai

#KS
sub save_as_template {
if(!$form->{tip}) {
   $form->{tip}=0;
   $form->{tip}=1 if ($form->{transfer}); 
   $form->{tip}=2 if ($form->{cash});
}  
  $form->isblank("tempname", $locale->text("Template name missing!"));
$form->{oldid}=$form->{id};
  GL->post_transaction(\%myconfig, \%$form, 1);
#  $form->redirect($locale->text('Template posted!'));
$form->{sabment}=qq|Sablon elmentve -- |.$form->{tempname};
$form->{callback}.="&sabment=".$form->escape($form->{sabment});
if ($form->{sab}==1) {$form->redirect};
$form->{template}=$form->{id};
&alkalmaz (1);
}
		 
sub alkalmaz {
#  if (!$form->{template}) {$form->header; &edit}
$form->{oldid}=$form->{id} if (!$_[0]);
   $callback = $form->escape ($form->{callback}, 1);
   
   $form->{callback} = "gl.pl?action=add&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&sab=2&template=$form->{template}&id=$form->{template}&transfer=$form->{transfer}&cash=$form->{cash}&oldid=$form->{oldid}&sabment=$form->{sabment}&param=$form->{param}";
   $form->{callback}.= "&transdate=$form->{transdate}&check=$form->{check}&reference=$form->{reference}"; 
   $form->{callback}.= "&callback=$callback"; 
#   $form->{callback} = $form->escape ($form->{callback});
   $form->redirect;
}
