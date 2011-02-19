# Copyright (c) 2001
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#  Modified by Tavugyvitel Kft. (info@tavugyvitel.hu)
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
# administration
#
#======================================================================


use SL::AM;
use SL::CA;
use SL::Form;
use SL::User;
use SL::RP;
use SL::GL;

1;
# end of main



sub add { &{ "add_$form->{type}" } };
sub edit { &{ "edit_$form->{type}" } };
sub save { &{ "save_$form->{type}" }};
sub delete { &{ "delete_$form->{type}" } };



sub add_account {
  
  $form->{title} = "Add";
  $form->{charttype} = "A";
  
  $form->{callback} = "$form->{script}?action=list_account&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};

  &account_header;
  &form_footer;
  
}


sub edit_account {
  
  $form->{title} = "Edit";
  
  $form->{accno} =~ s/\\'/'/g;
  $form->{accno} =~ s/\\\\/\\/g;
 
  AM->get_account(\%myconfig, \%$form);
#kabai
  $form->{link} =~ s/paid/paid_bank/g if $form->{ptype} eq "bank";  
#kabai
  foreach my $item (split(/:/, $form->{link})) {
    $form->{$item} = "checked";
  }

  &account_header;
  &form_footer;

}


sub account_header {

  $form->{title} = $locale->text("$form->{title} Account");
  
  $checked{$form->{charttype}} = "checked";
  $checked{"$form->{category}_"} = "checked";
  $checked{CT_tax} = ($form->{CT_tax}) ? "" : "checked";
  
  map { $form->{$_} = $form->quote($form->{$_}) } qw(accno description);

# this is for our parser only!
# type=submit $locale->text('Add Account')
# type=submit $locale->text('Edit Account')

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
<input type=hidden name=type value=account>

<input type=hidden name=inventory_accno_id value=$form->{inventory_accno_id}>
<input type=hidden name=income_accno_id value=$form->{income_accno_id}>
<input type=hidden name=expense_accno_id value=$form->{expense_accno_id}>
<input type=hidden name=fxgain_accno_id values=$form->{fxgain_accno_id}>
<input type=hidden name=fxloss_accno_id values=$form->{fxloss_accno_id}>

<table border=0 width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Account Number').qq|</th>
	  <td><input name=accno size=20 value="$form->{accno}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td><input name=description size=40 value="$form->{description}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Account Type').qq|</th>
	  <td>
	    <table border=1>
	      <tr valign=top>
		<td><input name=category type=radio class=radio value=A $checked{A_}>&nbsp;|.$locale->text('Asset').qq|\n<br>
		<input name=category type=radio class=radio value=L $checked{L_}>&nbsp;|.$locale->text('Liability').qq|\n<br>
		<input name=category type=radio class=radio value=Q $checked{Q_}>&nbsp;|.$locale->text('Equity').qq|\n<br>
		<input name=category type=radio class=radio value=I $checked{I_}>&nbsp;|.$locale->text('Income').qq|\n<br>
		<input name=category type=radio class=radio value=E $checked{E_}>&nbsp;|.$locale->text('Expense')
		.qq|</td>
		<td width=50>&nbsp;</td>
		<td>
		<input name=charttype type=radio class=radio value="H" $checked{H}>&nbsp;|.$locale->text('Heading').qq|<br>
		<input name=charttype type=radio class=radio value="A" $checked{A}>&nbsp;|.$locale->text('Account')
		.qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;

if ($form->{charttype} eq "A") {
  print qq|
	<tr>
	  <td colspan=2>
	    <table>
	      <tr>
		<th align=left>|.$locale->text('Is this a summary account to record').qq|</th>
		<td>
		<input name=AR type=checkbox class=checkbox value=AR $form->{AR}>&nbsp;|.$locale->text('AR')
		.qq|&nbsp;<input name=AP type=checkbox class=checkbox value=AP $form->{AP}>&nbsp;|.$locale->text('AP')
		.qq|&nbsp;<input name=IC type=checkbox class=checkbox value=IC $form->{IC}>&nbsp;|.$locale->text('Inventory')
		.qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
	<tr>
	  <th colspan=2>|.$locale->text('Include in drop-down menus').qq|</th>
	</tr>
	<tr valign=top>
	  <td colspan=2>
	    <table width=100% border=1>
	      <tr>
		<th align=left>|.$locale->text('Receivables').qq|</th>
		<th align=left>|.$locale->text('Payables').qq|</th>
		<th align=left>|.$locale->text('Parts Inventory').qq|</th>
		<th align=left>|.$locale->text('Service Items').qq|</th>
		<th align=left>|.$locale->text('Cash & Bank Forms').qq|</th>
	      </tr>
	      <tr>
		<td>
		<input name=AR_amount type=checkbox class=checkbox value=AR_amount $form->{AR_amount}>&nbsp;|.$locale->text('Income').qq|\n<br>
		<input name=AR_paid type=checkbox class=checkbox value=AR_paid $form->{AR_paid}>&nbsp;|.$locale->text('Cash2').qq|\n<br>
		<input name=AR_paid type=checkbox class=checkbox value=AR_paid_bank $form->{AR_paid_bank}>&nbsp;|.$locale->text('Bank').qq|\n<br>
		<input name=AR_tax type=checkbox class=checkbox value=AR_tax $form->{AR_tax}>&nbsp;|.$locale->text('Tax')
		.qq|
		</td>
		<td>
		<input name=AP_amount type=checkbox class=checkbox
		onClick="if(document.forms[0].ASSET.checked && !document.forms[0].AP_amount.checked){document.forms[0].ASSET.checked=false}"
		 value=AP_amount $form->{AP_amount}>&nbsp;|.$locale->text('Expense').qq|\n<br>
		<input name=ASSET type=checkbox class=checkbox 
		onClick="if(document.forms[0].ASSET.checked){document.forms[0].AP_amount.checked=true}"
		value=ASSET $form->{ASSET}>&nbsp;|.$locale->text('Invest/Asset').qq|\n<br>
		<input name=AP_paid type=checkbox class=checkbox value=AP_paid $form->{AP_paid}>&nbsp;|.$locale->text('Cash2').qq|\n<br>
		<input name=AP_paid type=checkbox class=checkbox value=AP_paid_bank $form->{AP_paid_bank}>&nbsp;|.$locale->text('Bank').qq|\n<br>
		<input name=AP_tax type=checkbox class=checkbox value=AP_tax $form->{AP_tax}>&nbsp;|.$locale->text('Tax')
		.qq|
		</td>
		<td>
		<input name=IC_sale type=checkbox class=checkbox value=IC_sale $form->{IC_sale}>&nbsp;|.$locale->text('Income').qq|\n<br>
		<input name=IC_taxpart type=checkbox class=checkbox value=IC_taxpart $form->{IC_taxpart}>&nbsp;|.$locale->text('Tax')
		.qq|
		</td>
		<td>
		<input name=IC_income type=checkbox class=checkbox value=IC_income $form->{IC_income}>&nbsp;|.$locale->text('Income').qq|\n<br>
		<input name=IC_expense type=checkbox class=checkbox value=IC_expense $form->{IC_expense}>&nbsp;|.$locale->text('Expense').qq|\n<br>
		<input name=IC_taxservice type=checkbox class=checkbox value=IC_taxservice $form->{IC_taxservice}>&nbsp;|.$locale->text('Tax')
		.qq|
		</td>
                <td>
		<input name=BANK type=checkbox class=checkbox value=BANK $form->{BANK}>&nbsp;|.$locale->text('Bank Counter Account').qq|\n<br>
		<input name=CASH type=checkbox class=checkbox value=CASH $form->{CASH}>&nbsp;|.$locale->text('Cash Counter Account').qq|\n<br>
                </td>
              </tr>
	    </table>
	  </td>  
	</tr>  
	<tr>
	  <td colspan=2>
	    <table>
	      <tr>
		<th align=left>|.$locale->text('Include this account on the customer/vendor forms to flag customer/vendor as taxable?').qq|</th>
		<td>
		  <input name=CT_tax type=radio class=radio value=CT_tax $form->{CT_tax}>&nbsp;|.$locale->text('Yes').qq|&nbsp;
		  <input name=CT_tax type=radio class=radio value="" $checked{CT_tax}>&nbsp;|.$locale->text('No')
		.qq|
		</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;
}
  AM->gifi_accounts(\%myconfig, \%$form);
  $form->{gifi_accno_list}="";
    map { $form->{gifi_accno_list} .= "<option value=$_->{accno}>$_->{accno}--$_->{description}\n" } @{ $form->{ALL} };
 if ($form->{gifi_accno}){$form->{gifi_accno_list} =~s/=$form->{gifi_accno}>/=$form->{gifi_accno} selected>/}       

print qq|
        <tr>
	  <th align=right>|.$locale->text('GIFI').qq|</th>|;
#	  <td><input name=gifi_accno size=9 value=$form->{gifi_accno}></td>
print qq|<td><select name=gifi_accno> <option>$form->{gifi_accno_list}</select></td></tr>
        <tr>
	  <th align=right>|.$locale->text('Notes').qq|</th>
	  <td><textarea name=notes rows=2 cols=50 wrap=soft>$form->{notes}</textarea></td>
	</tr>
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
  print qq|

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<br>

<input type=submit class=submit name=action onclick="return checkform();" value="|.$locale->text('Save').qq|">
|;

  if ($form->{id}){
      print qq|<input type=submit class=submit name=action onclick="return checkform();" value="|.$locale->text("Save As New").qq|"> |;
  }

  if ($form->{id} && $form->{orphaned}) {
    print qq|&nbsp;<input type=submit class=submit name=action value="|.$locale->text('Delete').qq|">|;
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

  
sub save_account {
  $form->isblank("accno", $locale->text('Account Number missing!'));
  $form->isblank("description", $locale->text('Description missing!'));
  $form->isblank("category", $locale->text('Account Type missing!'));
  
  # check for conflicting accounts
  if ($form->{AR} || $form->{AP} || $form->{IC}) {
    map { $a .= $form->{$_} } qw(AR AP IC);
    $form->error($locale->text('Cannot set account for more than one of AR, AP or IC')) if length $a > 2;

    map { $form->error("$form->{AR}$form->{AP}$form->{IC} ". $locale->text('account cannot be set to any other type of account')) if $form->{$_} } qw(AR_amount AR_tax AR_paid AP_amount AP_tax AP_paid IC_sale IC_cogs IC_taxpart IC_income IC_expense IC_taxservice BANK CASH);
  }
#kabai
    if(($form->{AR_paid} eq "AR_paid_bank" && $form->{AP_paid} eq "AP_paid") || ($form->{AP_paid} eq "AP_paid_bank" && $form->{AR_paid} eq "AR_paid")){
        $form->error($locale->text('account cannot be set to Bank && Petty Cash at the same time'));
    }
    if ($form->{AR_paid} eq "AR_paid_bank"){
	$form->{AR_paid} =~ s/_bank//;
	$form->{ptype} = "bank";
    }elsif($form->{AR_paid} eq "AR_paid"){
	$form->{ptype} = "pcash";    
    }
    if ($form->{AP_paid} eq "AP_paid_bank"){
	$form->{AP_paid} =~ s/_bank//;
	$form->{ptype} = "bank";
    }elsif($form->{AP_paid} eq "AP_paid"){
	$form->{ptype} = "pcash";    
    }
#kabai
  $form->redirect($locale->text('Account saved!')) if (AM->save_account(\%myconfig, \%$form));
  $form->error($locale->text('Cannot save account!'));

}


sub list_account {

  CA->all_accounts(\%myconfig, \%$form);

  $form->{title} = $locale->text('Chart of Accounts');
  
  # construct callback
  $callback = "$form->{script}?action=list_account&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  @column_index = qw(accno gifi_accno description debit credit link);

  $column_header{accno} = qq|<th class=listtop>|.$locale->text('Account').qq|</a></th>|;
  $column_header{gifi_accno} = qq|<th class=listtop>|.$locale->text('GIFI').qq|</a></th>|;
  $column_header{description} = qq|<th class=listtop>|.$locale->text('Description').qq|</a></th>|;
  $column_header{debit} = qq|<th class=listtop>|.$locale->text('Debit').qq|</a></th>|;
  $column_header{credit} = qq|<th class=listtop>|.$locale->text('Credit').qq|</a></th>|;
  $column_header{link} = qq|<th class=listtop>|.$locale->text('Link').qq|</a></th>|;


  $form->header;
  $colspan = $#column_index + 1;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop colspan=$colspan>$form->{title}</th>
  </tr>
  <tr height=5></tr>
  <tr class=listheading>
|;

  map { print "$column_header{$_}\n" } @column_index;
  
  print qq|
</tr>
|;

  # escape callback
  $callback = $form->escape($callback);
  
  foreach $ca (@{ $form->{CA} }) {
    
    $ca->{debit} = "&nbsp;";
    $ca->{credit} = "&nbsp;";

    if ($ca->{amount} > 0) {
      $ca->{credit} = $form->format_amount(\%myconfig, $ca->{amount}, 2, "&nbsp;");
    }
    if ($ca->{amount} < 0) {
      $ca->{debit} = $form->format_amount(\%myconfig, -$ca->{amount}, 2, "&nbsp;");
    }

    $ca->{link} =~ s/:/<br>/og;

    if ($ca->{charttype} eq "H") {
      print qq|<tr class=listheading>|;

      $column_data{accno} = qq|<th><a class=listheading href=$form->{script}?action=edit_account&id=$ca->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ca->{accno}</a></th>|;
      $column_data{gifi_accno} = qq|<th class=listheading><a class=listheading href=$form->{script}?action=edit_gifi&accno=$ca->{gifi_accno}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ca->{gifi_accno}</a>&nbsp;</th>|;
      $column_data{description} = qq|<th class=listheading>$ca->{description}&nbsp;</th>|;
      $column_data{debit} = qq|<th>&nbsp;</th>|;
      $column_data{credit} = qq| <th>&nbsp;</th>|;
      $column_data{link} = qq|<th>&nbsp;</th>|;

    } else {
      $i++; $i %= 2;
      print qq|
<tr valign=top class=listrow$i>|;
      $column_data{accno} = qq|<td><a href=$form->{script}?action=edit_account&id=$ca->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ca->{accno}</a></td>|;
      $column_data{gifi_accno} = qq|<td><a href=$form->{script}?action=edit_gifi&accno=$ca->{gifi_accno}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ca->{gifi_accno}</a>&nbsp;</td>|;
      $column_data{description} = qq|<td>$ca->{description}&nbsp;</td>|;
      $column_data{debit} = qq|<td align=right>$ca->{debit}</td>|;
      $column_data{credit} = qq|<td align=right>$ca->{credit}</td>|;
      $column_data{link} = qq|<td>$ca->{link}&nbsp;</td>|;
      
    }

    map { print "$column_data{$_}\n" } @column_index;
    
    print "</tr>\n";
  }
  
  print qq|
  <tr><td colspan=$colspan><hr size=3 noshade></td></tr>
</table>

</body>
</html>
|;

}


sub delete_account {

  $form->{title} = $locale->text('Delete Account');

  foreach $id (qw(inventory_accno_id income_accno_id expense_accno_id fxgain_accno_id fxloss_accno_id)) {
    if ($form->{id} == $form->{$id}) {
      $form->error($locale->text('Cannot delete default account!'));
    }
  }

  $form->redirect($locale->text('Account deleted!')) if (AM->delete_account(\%myconfig, \%$form));
  $form->error($locale->text('Cannot delete account!'));

}


sub list_gifi {

  @{ $form->{fields} } = qw(accno description);
  $form->{table} = "gifi";
  
  AM->gifi_accounts(\%myconfig, \%$form);

  $form->{title} = $locale->text('GIFI');
  
  # construct callback
  $callback = "$form->{script}?action=list_gifi&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  @column_index = qw(accno description);

  $column_header{accno} = qq|<th class=listheading>|.$locale->text('GIFI').qq|</a></th>|;
  $column_header{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</a></th>|;


  $form->header;
  $colspan = $#column_index + 1;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop colspan=$colspan>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr class=listheading>
|;

  map { print "$column_header{$_}\n" } @column_index;
  
  print qq|
</tr>
|;

  # escape callback
  $callback = $form->escape($callback);
  
  foreach $ca (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
<tr valign=top class=listrow$i>|;
    
    $column_data{accno} = qq|<td><a href=$form->{script}?action=edit_gifi&coa=1&accno=$ca->{accno}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ca->{accno}</td>|;
    $column_data{description} = qq|<td>$ca->{description}&nbsp;</td>|;
    
    map { print "$column_data{$_}\n" } @column_index;
    
    print "</tr>\n";
  }
  
  print qq|
  <tr>
    <td colspan=$colspan><hr size=3 noshade></td>
  </tr>
</table>

</body>
</html>
|;

}


sub add_gifi {
  $form->{title} = "Add";
  
  # construct callback
  $form->{callback} = "$form->{script}?action=list_gifi&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  $form->{coa} = 1;
  
  &gifi_header;
  &gifi_footer;
  
}


sub edit_gifi {
  
  $form->{title} = "Edit";
  
  AM->get_gifi(\%myconfig, \%$form);

  $form->error($locale->text('Account does not exist!')) unless $form->{accno};
  
  &gifi_header;
  &gifi_footer;
  
}


sub gifi_header {

  $form->{title} = $locale->text("$form->{title} GIFI");
  
# $locale->text('Add GIFI')
# $locale->text('Edit GIFI')

  map { $form->{$_} = $form->quote($form->{$_}) } qw(accno description);

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

<input type=hidden name=id value="$form->{accno}">
<input type=hidden name=type value=gifi>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('GIFI').qq|</th>
	  <td><input name=accno class="required" size=20 value="$form->{accno}"></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td><input name=description size=60 value="$form->{description}"></td>
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


sub gifi_footer {

#kabai 559
  print qq|

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
<input type=hidden name=auto value=$form->{auto}>

<br><input type=submit class=submit name=action onclick="return checkform();" value="|.$locale->text('Save').qq|">|;

  if ($form->{coa}) {
    print qq|
<input type=submit class=submit name=action value="|.$locale->text('Copy to COA').qq|">
|;

    if ($form->{accno} && $form->{orphaned}) {
      print qq|<input type=submit class=submit name=action value="|.$locale->text('Delete').qq|">|;
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


sub save_gifi {

  $form->isblank("accno", $locale->text('GIFI missing!'));
  AM->save_gifi(\%myconfig, \%$form);
  $form->redirect($locale->text('GIFI saved!'));

}


sub copy_to_coa {

  $form->isblank("accno", $locale->text('GIFI missing!'));

  AM->save_gifi(\%myconfig, \%$form);

  delete $form->{id};
  $form->{gifi_accno} = $form->{accno};
  
  $form->{title} = "Add";
  $form->{charttype} = "A";
#kabai
#$form->{auto} = 1;
  if ($form->{auto}){
      $form->{category} = "E";
      $form->{AP_amount} = "AP_amount";
      AM->save_account(\%myconfig,\%$form);
      $form->redirect($locale->text('Rendben'));
  }else{
      &account_header;
      &form_footer;
  }
#kabai      
}


sub delete_gifi {

  AM->delete_gifi(\%myconfig, \%$form);
  $form->redirect($locale->text('GIFI deleted!'));

}


sub add_department {

  $form->{title} = "Add";
  $form->{role} = "P";
  
  $form->{callback} = "$form->{script}?action=add_department&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};

  &department_header;
  &form_footer;

}


sub edit_department {

  $form->{title} = "Edit";

  AM->get_department(\%myconfig, \%$form);

  &department_header;
  &form_footer;

}


sub list_department {

  AM->departments(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_department&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  $form->sort_order();
  
  $form->{callback} = "$form->{script}?action=list_department&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Departments');

  @column_index = qw(description cost profit);

  $column_header{description} = qq|<th width=90%><a class=listheading href=$href>|.$locale->text('Description').qq|</a></th>|;
  $column_header{cost} = qq|<th class=listheading nowrap>|.$locale->text('Cost Center').qq|</th>|;
  $column_header{profit} = qq|<th class=listheading nowrap>|.$locale->text('Profit Center').qq|</th>|;

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  map { print "$column_header{$_}\n" } @column_index;

  print qq|
        </tr>
|;

  foreach $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
        <tr valign=top class=listrow$i>
|;

   $costcenter = ($ref->{role} eq "C") ? "X" : "&nbsp;";
   $profitcenter = ($ref->{role} eq "P") ? "X" : "&nbsp;";
   
   $column_data{description} = qq|<td><a href=$form->{script}?action=edit_department&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{description}</td>|;
   $column_data{cost} = qq|<td align=center>$costcenter</td>|;
   $column_data{profit} = qq|<td align=center>$profitcenter</td>|;

   map { print "$column_data{$_}\n" } @column_index;

   print qq|
	</tr>
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

<br>
<form method=post action=$form->{script}>

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=type value=department>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input class=submit type=submit name=action value="|.$locale->text('Add Department').qq|">|;

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


sub department_header {

  $form->{title} = $locale->text("$form->{title} Department");

# $locale->text('Add Department')
# $locale->text('Edit Department')

  $form->{description} = $form->quote($form->{description});

  if (($rows = $form->numtextrows($form->{description}, 60)) > 1) {
    $description = qq|<textarea name="description" class="required" rows=$rows cols=60 wrap=soft>$form->{description}</textarea>|;
  } else {
    $description = qq|<input name=description class="required" size=60 value="$form->{description}">|;
  }

  $costcenter = "checked" if $form->{role} eq "C";
  $profitcenter = "checked" if $form->{role} eq "P";
  
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
<input type=hidden name=type value=department>

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align=right>|.$locale->text('Description').qq|</th>
    <td>$description</td>
  </tr>
  <tr>
    <td></td>
    <td><input type=radio class="radio" name=role value="C" $costcenter> |.$locale->text('Cost Center').qq|
        <input type=radio class="radio" name=role value="P" $profitcenter> |.$locale->text('Profit Center').qq|
    </td>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_department {

  $form->isblank("description", $locale->text('Description missing!'));
  AM->save_department(\%myconfig, \%$form);
  $form->redirect($locale->text('Department saved!'));

}


sub delete_department {

  AM->delete_department(\%myconfig, \%$form);
  $form->redirect($locale->text('Department deleted!'));

}


sub add_business {

  $form->{title} = "Add";
  
  $form->{callback} = "$form->{script}?action=add_business&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};

  &business_header;
  &form_footer;

}


sub edit_business {

  $form->{title} = "Edit";

  AM->get_business(\%myconfig, \%$form);

  &business_header;

  $form->{orphaned} = 1;
  &form_footer;

}


sub list_business {

  AM->business(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_business&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  $form->sort_order();
  
  $form->{callback} = "$form->{script}?action=list_business&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Type of Business');

  @column_index = qw(description discount tdij1 tdij2);

  $column_header{description} = qq|<th width=90%><a class=listheading href=$href>|.$locale->text('Description').qq|</a></th>|;
  $column_header{discount} = qq|<th class=listheading>|.$locale->text('Discount').qq| %</th>|;
  $column_header{tdij1} = qq|<th class=listheading>|.$locale->text('Product Charge').qq| 1</th>|;
  $column_header{tdij2} = qq|<th class=listheading>|.$locale->text('Product Charge').qq| 2</th>|;

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  map { print "$column_header{$_}\n" } @column_index;

  print qq|
        </tr>
|;

  foreach $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
        <tr valign=top class=listrow$i>
|;

   $discount = $form->format_amount(\%myconfig, $ref->{discount} * 100, 2, "&nbsp");
   $tdij1 = $form->format_amount(\%myconfig, $ref->{tdij1}, 2, "&nbsp");
   $tdij2 = $form->format_amount(\%myconfig, $ref->{tdij2}, 2, "&nbsp");
   
   $column_data{description} = qq|<td><a href=$form->{script}?action=edit_business&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{description}</td>|;
   $column_data{discount} = qq|<td align=right>$discount</td>|;
   $column_data{tdij1} = qq|<td align=right>$tdij1</td>|;
   $column_data{tdij2} = qq|<td align=right>$tdij2</td>|;
   
   map { print "$column_data{$_}\n" } @column_index;

   print qq|
	</tr>
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

<br>
<form method=post action=$form->{script}>

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=type value=business>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input class=submit type=submit name=action value="|.$locale->text('Add Business').qq|">|;

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


sub business_header {
  $form->{title} = $locale->text("$form->{title} Business");

# $locale->text('Add Business')
# $locale->text('Edit Business')

  $form->{description} = $form->quote($form->{description});
  $form->{discount} = $form->format_amount(\%myconfig, $form->{discount} * 100);
  $form->{tdij1} = $form->format_amount(\%myconfig, $form->{tdij1});
  $form->{tdij2} = $form->format_amount(\%myconfig, $form->{tdij2});

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
<input type=hidden name=type value=business>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Type of Business').qq|</th>
	  <td><input name=description class="required" size=30 value="$form->{description}"></td>
	<tr>
	<tr>
	  <th align=right>|.$locale->text('Discount').qq| %</th>
	  <td><input name=discount size=5 value=$form->{discount}></td>
	<tr>
	  <th align=right>|.$locale->text('Product Charge').qq| 1</th>
	  <td><input name=tdij1 size=5 value=$form->{tdij1}></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Product Charge').qq| 2</th>
	  <td><input name=tdij2 size=5 value=$form->{tdij2}></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;
}


sub save_business {
  $form->isblank("description", $locale->text('Description missing!'));
  AM->save_business(\%myconfig, \%$form);
  $form->redirect($locale->text('Business saved!'));

}


sub delete_business {

  AM->delete_business(\%myconfig, \%$form);
  $form->redirect($locale->text('Business deleted!'));

}



sub add_sic {

  $form->{title} = "Add";
  
  $form->{callback} = "$form->{script}?action=add_sic&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};

  &sic_header;
  &form_footer;

}


sub edit_sic {

  $form->{title} = "Edit";

  $form->{code} =~ s/\\'/'/g;
  $form->{code} =~ s/\\\\/\\/g;
  
  AM->get_sic(\%myconfig, \%$form);
  $form->{id} = $form->{code};

  &sic_header;

  $form->{orphaned} = 1;
  &form_footer;

}


sub list_sic {

  AM->sic(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_sic&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $form->sort_order();

  $form->{callback} = "$form->{script}?action=list_sic&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Standard Industrial Codes');

  @column_index = $form->sort_columns(qw(code description));

  $column_header{code} = qq|<th><a class=listheading href=$href&sort=code>|.$locale->text('Code').qq|</a></th>|;
  $column_header{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;

  $form->header;

  print qq|
<body>
<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  map { print "$column_header{$_}\n" } @column_index;

  print qq|
        </tr>
|;

  foreach $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    if ($ref->{sictype} eq 'H') {
      print qq|
        <tr valign=top class=listheading>
|;
      $column_data{code} = qq|<th><a href=$form->{script}?action=edit_sic&code=$ref->{code}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{code}</th>|;
      $column_data{description} = qq|<th>$ref->{description}</th>|;
     
    } else {
      print qq|
        <tr valign=top class=listrow$i>
|;

      $column_data{code} = qq|<td><a href=$form->{script}?action=edit_sic&code=$ref->{code}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{code}</td>|;
      $column_data{description} = qq|<td>$ref->{description}</td>|;

   }
    
   map { print "$column_data{$_}\n" } @column_index;

   print qq|
	</tr>
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

<br>
<form method=post action=$form->{script}>

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=type value=sic>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input class=submit type=submit name=action value="|.$locale->text('Add SIC').qq|">|;

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


sub sic_header {

  $form->{title} = $locale->text("$form->{title} SIC");

# $locale->text('Add SIC')
# $locale->text('Edit SIC')

  map { $form->{$_} = $form->quote($form->{$_}) } qw(code description);

  $checked = ($form->{sictype} eq 'H') ? "checked" : "";

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

<input type=hidden name=type value=sic>
<input type=hidden name=id value="$form->{code}">

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align=right>|.$locale->text('Code').qq|</th>
    <td><input name=code class="required" size=10 value="$form->{code}"></td>
  <tr>
  <tr>
    <td></td>
    <th align=left><input name=sictype type=checkbox style=checkbox value="H" $checked> |.$locale->text('Heading').qq|</th>
  <tr>
  <tr>
    <th align=right>|.$locale->text('Description').qq|</th>
    <td><input name=description size=60 value="$form->{description}"></td>
  </tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_sic {

  $form->isblank("code", $locale->text('Code missing!'));
  $form->isblank("description", $locale->text('Description missing!'));
  AM->save_sic(\%myconfig, \%$form);
  $form->redirect($locale->text('SIC saved!'));

}


sub delete_sic {

  AM->delete_sic(\%myconfig, \%$form);
  $form->redirect($locale->text('SIC deleted!'));

}


sub add_language {

  $form->{title} = "Add";
  
  $form->{callback} = "$form->{script}?action=add_language&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};

  &language_header;
  &form_footer;

}


sub edit_language {

  $form->{title} = "Edit";

  $form->{code} =~ s/\\'/'/g;
  $form->{code} =~ s/\\\\/\\/g;
  
  AM->get_language(\%myconfig, \%$form);
  $form->{id} = $form->{code};

  &language_header;

  $form->{orphaned} = 1;
  &form_footer;

}


sub list_language {

  AM->language(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_language&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $form->sort_order();

  $form->{callback} = "$form->{script}?action=list_language&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Languages');

  @column_index = $form->sort_columns(qw(code description));

  $column_header{code} = qq|<th><a class=listheading href=$href&sort=code>|.$locale->text('Code').qq|</a></th>|;
  $column_header{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  map { print "$column_header{$_}\n" } @column_index;

  print qq|
        </tr>
|;

  foreach $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;

    print qq|
        <tr valign=top class=listrow$i>
|;

    $column_data{code} = qq|<td><a href=$form->{script}?action=edit_language&code=$ref->{code}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{code}</td>|;
    $column_data{description} = qq|<td>$ref->{description}</td>|;
    
   map { print "$column_data{$_}\n" } @column_index;

   print qq|
	</tr>
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

<br>
<form method=post action=$form->{script}>

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=type value=language>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input class=submit type=submit name=action value="|.$locale->text('Add Language').qq|">|;

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


sub language_header {

  $form->{title} = $locale->text("$form->{title} Language");

# $locale->text('Add Language')
# $locale->text('Edit Language')

  map { $form->{$_} = $form->quote($form->{$_}) } qw(code description);

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

<input type=hidden name=type value=language>
<input type=hidden name=id value="$form->{code}">

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align=right>|.$locale->text('Code').qq|</th>
    <td><input name=code class="required" size=10 value="$form->{code}"></td>
  <tr>
  <tr>
    <th align=right>|.$locale->text('Description').qq|</th>
    <td><input name=description size=60 value="$form->{description}"></td>
  </tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_language {

  $form->isblank("code", $locale->text('Code missing!'));
  $form->isblank("description", $locale->text('Description missing!'));
  AM->save_language(\%myconfig, \%$form);
  $form->redirect($locale->text('Language saved!'));

}


sub delete_language {

  AM->delete_language(\%myconfig, \%$form);
  $form->redirect($locale->text('Language deleted!'));

}


sub add_regnum {

	$form->{title} = "Add";

	$form->{callback} = "$form->{script}?action=add_regnum&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&cash=1" unless $form->{callback};

	&regnum_header;
	&form_footer;
	}


sub edit_regnum {

	$form->{title} = "Edit";

	$form->{code} =~ s/\\'/'/g;
	$form->{code} =~ s/\\\\/\\/g;

	AM->get_regnum(\%myconfig, \%$form);
	$form->{id} = $form->{code};
	$form->{orphaned} = 1;

	&regnum_header;
	&form_footer;
	}


sub list_regnum {

	AM->regnum(\%myconfig, \%$form);

	$href = "$form->{script}?action=list_regnum&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&cash=$form->{cash}";

	$form->sort_order();

	$form->{callback} = "$form->{script}?action=list_regnum&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&cash=$form->{cash}";
	$callback = $form->escape($form->{callback});

	$form->{title} = $locale->text('Voucher Numbers');

	@column_index = $form->sort_columns(qw(description regnum cashaccount regcheck));

	$column_header{description} = qq|<TH><A CLASS="listheading" HREF="$href&sort=description">|.$locale->text('Description').qq|</A></TH>|;
	$column_header{regnum} = qq|<TH><A CLASS="listheading" HREF="$href&sort=regnum">|.$locale->text('Number').qq|</A></TH>|;
	$column_header{cashaccount} = qq|<TH><A CLASS="listheading" HREF="$href&sort=cashaccount">|.$locale->text('Cash Account').qq|</A></TH>|;
	$column_header{regcheck} = qq|<TH><A CLASS="listheading" HREF="$href&sort=regcheck">|.$locale->text('Type').qq|</A></TH>|;

	$form->header;
	print qq|
<BODY>

<TABLE WIDTH="100%">
  <TR>
    <TH CLASS="listtop">$form->{title}</TH>
    </TR>
  <TR HEIGHT="5"></TR>
  <TR>
    <TD>
      <TABLE WIDTH="100%">
        <TR CLASS="listheading">|;

	map { print "\n            $column_header{$_}" } @column_index;

	print qq|
          </TR>
|;

	foreach $ref (@{ $form->{ALL} }) {
		$i++; $i %= 2;
		print qq|
        <TR VALIGN="top" CLASS="listrow$i">
|;


	$column_data{description} = qq|<TD>$ref->{description}</TD>|;
	$column_data{regnum} = qq|<TD><A HREF="$form->{script}?action=edit_regnum&code=$ref->{code}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback&cash=$form->{cash}">$ref->{regnum}</A></TD>|;
	$column_data{cashaccount} = qq|<TD>$ref->{cashaccount}</TD>|;
        my $regcheck = $ref->{regcheck} ? $locale->text('Check') : $locale->text('Receipt');
	$column_data{regcheck} = qq|<TD>$regcheck</TD>|;

	map { print "$column_data{$_}\n" } @column_index;

		print qq|
	</TR>|;
		}

	print qq|
        </TABLE>
      </TD>
    </TR>
  <TR>
    <TD><HR SIZE="3" NOSHADE></TD>
    </TR>
  </TABLE>

<BR>
<FORM METHOD="post" ACTION="$form->{script}">
  <input type="hidden" name="cash" value="1">
  <INPUT TYPE="hidden" NAME="callback" VALUE="$form->{callback}">
  <INPUT TYPE="hidden" NAME="type" VALUE="regnum">
  <INPUT TYPE="hidden" NAME="path" VALUE="$form->{path}">
  <INPUT TYPE="hidden" NAME="login" VALUE="$form->{login}">
  <INPUT TYPE="hidden" NAME="sessionid" VALUE="$form->{sessionid}">
  <INPUT CLASS="submit" TYPE="submit" NAME="action" VALUE="|.$locale->text('Add Number').qq|">|;

	if ($form->{menubar}) {
		require "$form->{path}/menu.pl";
		&menubar;
		}

	print qq|
  </FORM>

</BODY>
</HTML> 
|;
  	}


sub regnum_header {

	$form->{title} = $locale->text("$form->{title} Number");

	map { $form->{$_} = $form->quote($form->{$_}) } qw(code number description cashaccount);
#kabai
    
    RP->paymentaccounts2(\%myconfig, \%$form);# if(!$_[0]);
#    $paymentselection = "<option>\n";
    foreach $ref (@{ $form->{PR} }) {
      $paymentselection .= "<option value=$ref->{accno}>$ref->{accno}--$ref->{description}\n";
      if (!$form->{cashaccount}) {$form->{cashaccount}=$ref->{accno}}
    }
AM->get_cashlimit(\%myconfig, \%$form);
    $paymentselection =~ s/(<option value=$form->{cashaccount})/$1 selected/ if $form->{cashaccount};
#set type 
    my $regcheck_t, $regcheck_f;
    if (($form->{regcheck} eq "1") || ($form->{regcheck} eq "t")){
      $regcheck_t = "checked";
    }elsif(($form->{regcheck} eq "0") || ($form->{regcheck} eq "f")){
      $regcheck_f = "checked";
    }  
#kabai  

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
<form method="post" action="$form->{script}">

<input type="hidden" name="type" value="regnum">
<INPUT TYPE="hidden" NAME="id" VALUE="$form->{code}">
<input type=hidden name=action value="Update">

<TABLE WIDTH="100%">
  <TR>
    <TH CLASS="listtop" COLSPAN="2">$form->{title}</TH>
    </TR>
  <TR HEIGHT="5"></TR>
  <TR>
    <TH ALIGN="right">|.$locale->text('Code').qq|</TH>
    <TD><INPUT NAME="code" class="required" SIZE="9" VALUE="$form->{code}"></TD>
    </TR>
  <TR>
    <TH ALIGN="right">|.$locale->text('Number').qq|</TH>
    <TD><INPUT NAME="number" class="required" SIZE="9" MAXLENGTH="9" VALUE="$form->{number}"></TD>
    </TR>
  <TR>
    <TH ALIGN="right">|.$locale->text('Description').qq|</TH>
    <TD><INPUT NAME="description" SIZE="60" VALUE="$form->{description}"></TD>
    </TR>
  <TR>
    <TH ALIGN="right">|.$locale->text('Currency').qq|</TH>
    <TD><INPUT NAME="vcurr" class="required" SIZE="3" MAXLENGTH="3" VALUE="$form->{vcurr}"></TD>
    </TR>
    <TR>
      <TH align=right nowrap>|.$locale->text('Cash Account').qq|</TH>
          <TD colspan=3><select class="required" name=cashaccount onchange="this.form.submit();">$paymentselection</select>
	    <input type=hidden name=paymentaccounts value="$paymentaccounts">
    <b>|.$locale->text('Min. value').qq|
	 <input name=mincash size=14 value=|.$form->format_amount(\%myconfig,$form->{mincash},2,0).qq|>
    |.$locale->text('Max. value').qq|</b>
	 <input name=maxcash size=14 value=|.$form->format_amount(\%myconfig,$form->{maxcash},2,0).qq|>
	  </TD>
	</TR>
    <TR>
      <TH align=right nowrap>|.$locale->text('Type').qq|</TH>
          <TD colspan=3>
          |.$locale->text('Receipt').qq|&nbsp;<input type="radio" class="radio" name="regcheck" value="f" $regcheck_f>
          |.$locale->text('Check').qq|&nbsp;<input type="radio" class="radio" name="regcheck" value="t" $regcheck_t>
         </TD>
   </TR>
    <TR>
     <TD COLSPAN="2"><HR SIZE="3" NOSHADE></TD>
    </TR>
  </TABLE>
|;
  	}


sub save_regnum {

	$form->isblank("code", $locale->text('Code missing!'));
	$form->isblank("vcurr", $locale->text('Currency missing!'));
	$form->isblank("regcheck", $locale->text('Register type missing!'));
	$form->isnotonlyletters("code", $locale->text('Code is incorrect!'));
	$form->isnotonlydigits("number", $locale->text('Number is incorrect!'));

	AM->save_regnum(\%myconfig, \%$form);

	$form->redirect($locale->text('Number saved!'));
	}


sub delete_regnum {

	AM->delete_regnum(\%myconfig, \%$form);
	$form->redirect($locale->text('Number deleted!'));
	}


sub add_regnumber {

	$form->{title} = "Add";
	$form->{callback} = "$form->{script}?action=add_regnumber&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};
	&regnumber_header;
	&form_footer;
	}


sub edit_regnumber {

	$form->{title} = "Edit";

	$form->{code} =~ s/\\'/'/g;
	$form->{code} =~ s/\\\\/\\/g;

	AM->get_regnumber(\%myconfig, \%$form);
	$form->{id} = $form->{code};
	$form->{orphaned} = 1;

	&regnumber_header;
	&form_footer;
	}


sub list_regnumber {

	AM->regnumber(\%myconfig, \%$form);

	$href = "$form->{script}?action=list_regnumber&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

	$form->sort_order();

	$form->{callback} = "$form->{script}?action=list_regnumber&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
	$callback = $form->escape($form->{callback});

	$form->{title} = $locale->text('Register Numbers');

	@column_index = $form->sort_columns(qw(description regnumber aparcheck));

	$column_header{description} = qq|<th><a class="listheading" href="$href&sort=description">|.$locale->text('Description').qq|</a></th>|;
	$column_header{regnumber} = qq|<th><a class="listheading" href="$href&sort=regnumber">|.$locale->text('Regnumber').qq|</a></th>|;
	$column_header{aparcheck} = qq|<th><a class="listheading" href="$href&sort=aparcheck">|.$locale->text('Type').qq|</a></th>|;

	$form->header;
	print qq|
<body>

<table width="100%">
  <tr>
    <th class="listtop">$form->{title}</th>
    </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width="100%">
        <tr class="listheading">|;

	map { print "\n            $column_header{$_}" } @column_index;

	print qq|
          </tr>
|;

	foreach $ref (@{ $form->{ALL} }) {
		$i++; $i %= 2;
		print qq|
        <tr valign="top" class="listrow$i">
|;

		$column_data{description} = qq|<td>$ref->{description}</td>|;
		$column_data{regnumber} = qq|<td><a href="$form->{script}?action=edit_regnumber&code=$ref->{code}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback">$ref->{regnumber}</a></td>|;
                my $aparcheck = $ref->{aparcheck} ? $locale->text('AR') : $locale->text('AP');
                $column_data{aparcheck} = qq|<td>$aparcheck</td>|;

		map { print "$column_data{$_}\n" } @column_index;

		print qq|
	</tr>|;
		}

	print qq|
        </table>
      </td>
    </tr>
  <tr>
    <td><hr size="3" noshade></td>
    </tr>
  </table>

<br>
<form method="post" action="$form->{script}">
  <input type="hidden" name="callback" value="$form->{callback}">
  <input type="hidden" name="type" value="regnumber">
  <input type="hidden" name="path" value="$form->{path}">
  <input type="hidden" name="login" value="$form->{login}">
  <input type="hidden" name="sessionid" value="$form->{sessionid}">
  <input class="submit" type="submit" name="action" value="|.$locale->text('Add Regnumber').qq|">|;

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


sub regnumber_header {

	$form->{title} = $locale->text("$form->{title} Regnumber");

	map { $form->{$_} = $form->quote($form->{$_}) } qw(code regnumber description);

#set type 
        my $aparcheck_t, $aparcheck_f;
        if (($form->{aparcheck} eq "1") || ($form->{aparcheck} eq "t")){
          $aparcheck_t = "checked";
        }elsif(($form->{aparcheck} eq "0") || ($form->{aparcheck} eq "f")){
          $aparcheck_f = "checked";
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

<form method="post" action="$form->{script}">

<input type="hidden" name="type" value="regnumber">
<input type="hidden" name="id" value="$form->{code}">

<table width="100%">
  <tr>
    <th class="listtop" colspan="2">$form->{title}</th>
    </tr>
  <tr height="5"></tr>
  <tr>
    <th align="right">|.$locale->text('Code').qq|</th>
    <td><input name="code" class="required" size="9" value="$form->{code}"></td>
    </tr>
  <tr>
    <th align="right">|.$locale->text('Regnumber').qq|</th>
    <td><input name="regnumber" class="required" size="9" maxlength="9" value="$form->{regnumber}"></td>
    </tr>
  <tr>
    <th align="right">|.$locale->text('Description').qq|</th>
    <td><input name="description" size="60" value="$form->{description}"></td>
    </tr>
  <tr>
      <th align=right nowrap>|.$locale->text('Type').qq|</th>
          <td colspan=3>
          |.$locale->text('AP').qq|&nbsp;<input type="radio" class="radio" name="aparcheck" value="f" $aparcheck_f>
          |.$locale->text('AR').qq|&nbsp;<input type="radio" class="radio" name="aparcheck" value="t" $aparcheck_t>
          </td>
  </tr>
  <tr>
    <td colspan="2"><hr size="3" noshade></td>
    </tr>
  </table>
|;
  	}


sub save_regnumber {

	$form->isblank("code", $locale->text('Code missing!'));
	$form->isblank("aparcheck", $locale->text('Register type missing!'));
	$form->isnotonlyletters("code", $locale->text('Code is incorrect!'));
	$form->isnotonlydigits("regnumber", $locale->text('Regnumber is incorrect!'));

	AM->save_regnumber(\%myconfig, \%$form);

	$form->redirect($locale->text('Regnumber saved!'));
	}


sub delete_regnumber {

	AM->delete_regnumber(\%myconfig, \%$form);
	$form->redirect($locale->text('Regnumber deleted!'));
	}


sub display_stylesheet {
  
  $form->{file} = "css/$myconfig{stylesheet}";
  &display_form;
  
}


sub display_form {

  $form->{file} =~ s/^(.:)*?\/|\.\.\///g; 
  $form->{file} =~ s/^\/*//g;
  $form->{file} =~ s/$userspath//;

  $form->error("$!: $form->{file}") unless -f $form->{file};

  AM->load_template(\%$form);

  $form->{title} = $form->{file};

  # if it is anything but html
  if ($form->{file} !~ /\.html$/) {
    $form->{body} = "<pre>\n$form->{body}\n</pre>";
  }
    
  $form->header;

  print qq|
<body>

$form->{body}

<form method=post action=$form->{script}>

<input name=file type=hidden value=$form->{file}>
<input name=type type=hidden value=template>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input name=action type=submit class=submit value="|.$locale->text('Edit').qq|">|;

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


sub edit_template {

  AM->load_template(\%$form);

  $form->{title} = $locale->text('Edit Template');
  # convert &nbsp to &amp;nbsp;
  $form->{body} =~ s/&nbsp;/&amp;nbsp;/gi;
  

  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input name=file type=hidden value=$form->{file}>
<input name=type type=hidden value=template>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input name=callback type=hidden value="$form->{script}?action=display_form&file=$form->{file}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}">

<textarea name=body rows=25 cols=70>
$form->{body}
</textarea>

<br>
<input type=submit class=submit name=action value="|.$locale->text('Save').qq|">|;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print q|
  </form>


</body>
</html>
|;

}


sub save_template {

  AM->save_template(\%$form);
  $form->redirect($locale->text('Template saved!'));
  
}


sub defaults {
  
  # get defaults for account numbers and last numbers
  AM->defaultaccounts(\%myconfig, \%$form);
  foreach $key (keys %{ $form->{IC} }) {
    foreach $accno (sort keys %{ $form->{IC}{$key} }) {
      $form->{account}{$key} .= ($form->{IC}{$key}{$accno}{id} == $form->{defaults}{$key}) ? "<option selected>$accno--$form->{IC}{$key}{$accno}{description}\n" : "<option>$accno--$form->{IC}{$key}{$accno}{description}\n";
    }
  }

  $form->{title} = $locale->text('System Defaults');
#kabai
  my $lastinvnumber = $invnumberinit_true ? qq|<input name=invnumber class="required" value="|.$form->{defaults}{invnumber}.qq|">|: qq|<input name=invnumber type=hidden value="|.$form->{defaults}{invnumber}.qq|">|.$form->{defaults}{invnumber};
  my $lastinvnumber_st = $invnumberinit_true ? qq|<input name=invnumber_st class="required" value="|.$form->{defaults}{invnumber_st}.qq|">|: qq|<input name=invnumber_st type=hidden value="|.$form->{defaults}{invnumber_st}.qq|">|.$form->{defaults}{invnumber_st};

  $form->{defaults}{promptshipreceive} = "checked" if $form->{defaults}{promptshipreceive};
#kabai  
  my $class1 = qq|class="noscreen"| if $maccess !~ /Goods--All/;
  my $class2 = qq|class="noscreen"| if $maccess !~ /Accountant--All/;
  my $class3 = qq|class="noscreen"| if $maccess !~ /Quotations--All/;

  $form->header;
#kabai +54  +75
#pasztor Last Transfer Number
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

<input type=hidden name=type value=defaults>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr>
    <td>
      <table $class1>
        <tr>
	  <th align=right>|.$locale->text('Weight Unit').qq|</th>
	  <td><input name=weightunit size=5 value="$form->{defaults}{weightunit}"></td>
	</tr>
        <tr>
	  <td align=right><input type=checkbox class=checkbox name=promptshipreceive value=1 $form->{defaults}{promptshipreceive}></td>
	  <td align=left>|.$locale->text('Prompt warehouse moves when sales order/invoice is posted').qq|</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <th class=listheading>|.$locale->text('Last Numbers & Default Accounts').qq|</th>
  </tr>
  <tr $class2>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Inventory Account').qq|</th>
	  <td><select class="required" name=inventory_accno>$form->{account}{IC}</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Income Account').qq|</th>
	  <td><select class="required" name=income_accno>$form->{account}{IC_income}</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Foreign Exchange Gain').qq|</th>
	  <td><select class="required" name=fxgain_accno>$form->{account}{FX_gain}</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Foreign Exchange Loss').qq|</th>
	  <td><select class="required" name=fxloss_accno>$form->{account}{FX_loss}</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Cash AR').qq|</th>
	  <td><select class="required" name=ar_accno>$form->{account}{AR}</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Cash AP').qq|</th>
	  <td><select class="required" name=ap_accno>$form->{account}{AP}</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Cash Paid').qq|</th>
	  <td><select class="required" name=cash_accno>$form->{account}{Cash}</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Rounding Income').qq|</th>
	  <td><select class="required" name=rincome_accno>$form->{account}{Rounding_income}</select></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Rounding Cost').qq|</th>
	  <td><select class="required" name=rcost_accno>$form->{account}{Rounding_cost}</select></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <th align=left>|.$locale->text('Enter up to 3 letters separated by a colon (i.e CAD:USD:EUR) for your native and foreign currencies').qq|</th>
  </tr>
  <tr>
    <td>
    <input name=curr class="required" size=40 value="$form->{defaults}{curr}">
    </td>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Last Invoice Number').qq|</th>
	  <td><input type=text name="prefix" size="7" maxlength="7" value="$form->{defaults}{prefix}">&nbsp;$lastinvnumber&nbsp;<input type=text name="suffix" size="3" maxlength="3" value="$form->{defaults}{suffix}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Last Invoice-like Document Number').qq|</th>
	  <td>ST-$form->{defaults}{prefix}$lastinvnumber_st$form->{defaults}{suffix}</td>
	</tr>
	<tr $class3>
	  <th align=right nowrap>|.$locale->text('Last Sales Order Number').qq|</th>
	  <td><input name=sonumber size=40 value="$form->{defaults}{sonumber}"></td>
	</tr>
	<tr $class3>
	  <th align=right nowrap>|.$locale->text('Last Purchase Order Number').qq|</th>
	  <td><input name=ponumber size=40 value="$form->{defaults}{ponumber}"></td>
	</tr>
	<tr $class3>
	  <th align=right nowrap>|.$locale->text('Last Sales Quotation Number').qq|</th>
	  <td><input name=sqnumber size=40 value="$form->{defaults}{sqnumber}"></td>
	</tr>
	<tr $class3>
	  <th align=right nowrap>|.$locale->text('Last RFQ Number').qq|</th>
	  <td><input name=rfqnumber size=40 value="$form->{defaults}{rfqnumber}"></td>
	</tr>
        <tr $class3>
	  <th align=right nowrap>|.$locale->text('Last Transfer Number').qq|</th>
	  <td><input name=transnumber size=40 value="$form->{defaults}{transnumber}"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <th class=listheading>|.$locale->text('Tax Accounts').qq|</th>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th></th>
	  <th>|.$locale->text('Rate').qq| (%)</th>
	  <th>|.$locale->text('Identifier').qq|</th>
          <th>|.$locale->text('Valid from').qq|</th>
          <th>|.$locale->text('Valid to').qq|</th>
          <th>|.$locale->text('Base').qq|<label class="info super" title='|.$locale->text('Base is always checked').qq|'>?</label></th>
	</tr>
|;

  foreach $accno (sort keys %{ $form->{taxrates} }) {
    $form->{taxrates}{$accno}{base} = "checked" if $form->{taxrates}{$accno}{base};
    $class1 = "" if $form->{taxrates}{$accno}{taxnumber} eq "FIZ";
    print qq|
	<tr $class1>
	  <th align=right>$form->{taxrates}{$accno}{description}</th>
	  <td><input name=$form->{taxrates}{$accno}{id} size=6 value=$form->{taxrates}{$accno}{rate}></td>
	  <td><input name="taxnumber_$form->{taxrates}{$accno}{id}" class="required" size=3 value="$form->{taxrates}{$accno}{taxnumber}"></td>
	  <td><input name="validfrom_$form->{taxrates}{$accno}{id}" class="required" size=11 title="$myconfig{'dateformat'}" id="validfrom_$form->{taxrates}{$accno}{id}" 
	   OnBlur="return dattrans('validfrom_$form->{taxrates}{$accno}{id}');" value=$form->{taxrates}{$accno}{validfrom}></td>
	  <td><input name="validto_$form->{taxrates}{$accno}{id}" class="required" size=11 title="$myconfig{'dateformat'}" id="validto_$form->{taxrates}{$accno}{id}"
	            OnBlur="return dattrans('validto_$form->{taxrates}{$accno}{id}');" value=$form->{taxrates}{$accno}{validto}></td>
	  <td align=center><input name="base_$form->{taxrates}{$accno}{id}" type=checkbox value=1 $form->{taxrates}{$accno}{base}></td>
	</tr>
|;
    $form->{taxaccounts} .= "$form->{taxrates}{$accno}{id} ";
  }

  chop $form->{taxaccounts};

  print qq|
      </table>
    </td>
  </tr>
<input name=taxaccounts type=hidden value="$form->{taxaccounts}">
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<br>
<input type=submit class=submit name=action onclick="return checkform();" value="|.$locale->text('Save').qq|">|;

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


sub config {

  foreach $item (qw(mm-dd-yy mm/dd/yy dd-mm-yy dd/mm/yy dd.mm.yy yyyy-mm-dd)) {
    $dateformat .= ($item eq $myconfig{dateformat}) ? "<option selected>$item\n" : "<option>$item\n";
  }

  foreach $item (qw(1,000.00 1000.00 1.000,00 1000,00 1'000.00)) {
    $numberformat .= ($item eq $myconfig{numberformat}) ? "<option selected>$item\n" : "<option>$item\n";
  }

  map { $myconfig{$_} = $form->quote($myconfig{$_}) } qw(name company address signature);
  map { $myconfig{$_} =~ s/\\n/\r\n/g } qw(address signature footer);

  %countrycodes = User->country_codes;
  $countrycodes = '';
  
  foreach $key (sort { $countrycodes{$a} cmp $countrycodes{$b} } keys %countrycodes) {
    $countrycodes .= ($myconfig{countrycode} eq $key) ? "<option selected value=$key>$countrycodes{$key}\n" : "<option value=$key>$countrycodes{$key}\n";
  }
  $countrycodes = qq|<option value="">English\n$countrycodes|;

  opendir CSS, "css/.";
  @all = grep /.*\.css$/, readdir CSS;
  closedir CSS;

  foreach $item (@all) {
    if ($item eq $myconfig{stylesheet}) {
      $selectstylesheet .= qq|<option selected>$item\n|;
    } else {
      $selectstylesheet .= qq|<option>$item\n|;
    }
  }
  $selectstylesheet .= "<option>\n";
  
  $selectprinter = "<option>\n";
  foreach $item (sort keys %printer) {
    if ($myconfig{printer} eq $item) {
      $selectprinter .= qq|<option value="$item" selected>$printer{$item}\n|;
    } else {
      $selectprinter .= qq|<option value="$item">$printer{$item}\n|;
    }
  }
#kabai  
  $selectprformat = "<option>\n";
  foreach $item qw(html postscript pdf) {
    if ($myconfig{prformat} eq $item) {
      $selectprformat .= qq|<option value="$item" selected>$item\n|;
    } else {
      $selectprformat .= qq|<option value="$item">$item\n|;
    }
  }
  $selectprmedia = "<option>\n";
  foreach $item qw(screen printer queue) {
    if ($myconfig{prmedia} eq $item) {
      $selectprmedia .= qq|<option value="$item" selected>|.$locale->text($item).qq|\n|;
    } else {
      $selectprmedia .= qq|<option value="$item">|.$locale->text($item).qq|\n|;
    }
  }

#kabai

  $form->{title} = $locale->text('Edit Preferences for').qq| $form->{login}|;
  
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

<input type=hidden name=old_password value=$myconfig{password}>
<input type=hidden name=type value=preferences>
<input type=hidden name=role value=$myconfig{role}>
<input type=hidden name=js value="$myconfig{js}">

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr>
    <td>
      <table width=100%>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Name').qq|</th>
		<td><input name=name class="required" size=20 value="$myconfig{name}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Password (max. 8 character)').qq|</th>
		<td><input type=password name=new_password size=10 value=$myconfig{password}></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('E-mail').qq|</th>
		<td><input name=email size=35 value="$myconfig{email}"></td>
	      </tr>
	      <tr valign=top>
		<th align=right>|.$locale->text('Signature').qq|</th>
		<td><textarea name=signature rows=3 cols=35>$myconfig{signature}</textarea></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Phone').qq|</th>
		<td><input name=tel size=14 value="$myconfig{tel}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Fax').qq|</th>
		<td><input name=fax size=14 value="$myconfig{fax}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Company').qq|</th>
		<td><input name=company class="required" size=35 value="$myconfig{company}"></td>
	      </tr>
	      <tr valign=top>
		<th align=right>|.$locale->text('Address').qq|</th>
		<td><textarea name=address class="required" rows=4 cols=35>$myconfig{address}</textarea></td>
	      </tr>
	      <tr valign=top>
		<th align=right>|.$locale->text('Footer on Invoice (3 rows max.)').qq|</th>
		<td><textarea name=footer rows=3 cols=75 wrap=off>$myconfig{footer}</textarea></td>
	      </tr>

	    </table>
	  </td>
	  <td>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Date Format').qq|</th>
		<td><select name=dateformat>$dateformat</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Number Format').qq|</th>
		<td><select name=numberformat>$numberformat</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Dropdown Limit').qq|</th>
		<td><input name=vclimit size=10 value="$myconfig{vclimit}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Menu Width').qq|</th>
		<td><input name=menuwidth class="required" size=10 value="$myconfig{menuwidth}"></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Language2').qq|</th>
		<td><select name=countrycode>$countrycodes</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Character Set').qq|</th>
		<td><input name=charset type=hidden value="$myconfig{charset}">$myconfig{charset}</td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Stylesheet').qq|</th>
		<td><select name=usestylesheet>$selectstylesheet</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Printer').qq|</th>
		<td><select name=printer>$selectprinter</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Document Format').qq|</th>
		<td><select name=prformat>$selectprformat</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Document Media').qq|</th>
		<td><select name=prmedia>$selectprmedia</select></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Copies').qq|</th>
		<td><input name=copies size=2 value="$myconfig{copies}"></td>
	      </tr>

	    </table>
	  </td>
	</tr>
      </table>
    </td>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<br>
<input type=submit class=submit name=action onclick="return checkform();" value="|.$locale->text('Save').qq|">|;

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


sub save_defaults {

  $form->redirect($locale->text('Defaults saved!')) if (AM->save_defaults(\%myconfig, \%$form));
  $form->error($locale->text('Cannot save defaults!'));

}


sub save_preferences {
#kabai
  if (my $footerrows = $form->{footer} =~ s/\r\n/\\n/g > 2){
    $form->error($locale->text('Footer may contain maximum 3 rows!'));
  }
#kabai  

  $form->{stylesheet} = $form->{usestylesheet};

#kabai
  if (my $addressrows = $form->{address} =~ s/\r\n/\\n/g > 7){
    $form->error($locale->text('Address field may contain maximum 8 rows!'));
  }
#kabai 
  
  $form->redirect($locale->text('Preferences saved!')) if (AM->save_preferences(\%myconfig, \%$form, $memberfile, $userspath));
  $form->error($locale->text('Cannot save preferences!'));

}


sub backup {

  if ($form->{media} eq 'email') {
    $form->error($locale->text('No email address for')." $myconfig{name}") unless ($myconfig{email});

    $form->{windows} = $windows;

   if ($windows){
	  $form->error($locale->text("SMTP server missing!")) if !$smtpserver;
  	  $form->error($locale->text("User e-mail address is missing!")) if !$myconfig{email};
	  $form->{smtpserver} = $smtpserver;
	  $form->{userspath} = $userspath;
   }
#kabai    
    $form->{OUT} = "$sendmail";

  }

  $SIG{INT} = 'IGNORE';
  AM->backup(\%myconfig, \%$form, $userspath, $gzip);

  if ($form->{media} eq 'email') {
    $form->redirect($locale->text('Backup sent to').qq| $myconfig{email}|);
  }

}



sub audit_control {

  $form->{title} = $locale->text('Audit Control');

  AM->closedto(\%myconfig, \%$form);
  
  if ($form->{revtrans}) {
    $checked{revtransY} = "checked";
  } else {
    $checked{revtransN} = "checked";
  }
  
  if ($form->{audittrail}) {
    $checked{audittrailY} = "checked";
  } else {
    $checked{audittrailN} = "checked";
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

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Enforce transaction reversal for all dates').qq|</th>
	  <td><input name=revtrans class=radio type=radio value="1" $checked{revtransY}> |.$locale->text('Yes').qq| <input name=revtrans class=radio type=radio value="0" $checked{revtransN}> |.$locale->text('No').qq|</td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Close Books up to').qq|</th>
	  <td><input name=closedto size=11 title="$myconfig{dateformat}" id=closedto OnBlur="return dattrans('closedto');" value=$form->{closedto}></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Closed term by tax return up to').qq|</th>
	  <td><input name=taxreturn size=11 title="$myconfig{dateformat}" id=taxreturn OnBlur="return dattrans('taxreturn');" title="$myconfig{dateformat}" value=$form->{taxreturn}></td>
	</tr>
<tr><td colspan=2>&nbsp;</td></tr>
      <tr>
	  <th align=right>|.$locale->text('Activate Audit trails').qq|</th>
	  <td><input name=audittrail class=radio type=radio value="1" $checked{audittrailY}> |.$locale->text('Yes').qq| 
	  <input name=audittrail class=radio type=radio value="0" $checked{audittrailN}> |.$locale->text('No').qq|</td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Remove Audit trails up to').qq|</th>
	  <td><input name=removeaudittrail size=11 title="$myconfig{dateformat}" id=removeaudittrail OnBlur="return dattrans('removeaudittrail');" ></td>
      </tr>
      </table>
    </td>
  </tr>

</table>

<hr size=3 noshade>

<br>
<input type=hidden name=nextsub value=doclose>

<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">

</form>

</body>
</html>
|;

}


sub doclose {

  AM->closebooks(\%myconfig, \%$form);
  
  if ($form->{revtrans}) {
    $msg = $locale->text('Transaction reversal enforced for all dates');
  } else {
    if ($form->{closedto}) {
      $msg = $locale->text('Transaction reversal enforced up to')
      ." ".$locale->date(\%myconfig, $form->{closedto}, 1);
    } else {
      $msg = $locale->text('Books are open');
    }
  }

  $msg .= "<p>";
  if ($form->{audittrail}) {
    $msg .= $locale->text('Audit trails enabled');
  } else {
    $msg .= $locale->text('Audit trails disabled');
  }

  $msg .= "<p>";
  if ($form->{removeaudittrail}) {
    $msg .= $locale->text('Audit trail removed up to')
    ." ".$locale->date(\%myconfig, $form->{removeaudittrail}, 1);
  }

  $msg .= "<p>";
  if ($form->{taxreturn}) {
    $msg .= $locale->text('Closed term by tax return up to')
    ." ".$locale->date(\%myconfig, $form->{taxreturn}, 1);
  }
    
  $form->redirect($msg);
  
}


sub add_warehouse {

  $form->{title} = "Add";
  
  $form->{callback} = "$form->{script}?action=add_warehouse&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};

  &warehouse_header;
  &form_footer;

}


sub edit_warehouse {

  $form->{title} = "Edit";

  AM->get_warehouse(\%myconfig, \%$form);

  &warehouse_header;
  &form_footer;

}


sub list_warehouse {

  AM->warehouses(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_warehouse&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  $form->sort_order();
  
  $form->{callback} = "$form->{script}?action=list_warehouse&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Warehouses');

  @column_index = qw(description);

  $column_header{description} = qq|<th width=100%><a class=listheading href=$href>|.$locale->text('Description').qq|</a></th>|;

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>
|;

  map { print "$column_header{$_}\n" } @column_index;

  print qq|
        </tr>
|;

  foreach $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
        <tr valign=top class=listrow$i>
|;

   $column_data{description} = qq|<td><a href=$form->{script}?action=edit_warehouse&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{description}</td>|;

   map { print "$column_data{$_}\n" } @column_index;

   print qq|
	</tr>
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

<br>
<form method=post action=$form->{script}>

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=type value=warehouse>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input class=submit type=submit name=action value="|.$locale->text('Add Warehouse').qq|">|;

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



sub warehouse_header {

  $form->{title} = $locale->text("$form->{title} Warehouse");

# $locale->text('Add Warehouse')
# $locale->text('Edit Warehouse')

  $form->{description} = $form->quote($form->{description});

  if (($rows = $form->numtextrows($form->{description}, 60)) > 1) {
    $description = qq|<textarea name="description" rows=$rows cols=60 wrap=soft>$form->{description}</textarea>|;
  } else {
    $description = qq|<input name=description size=60 value="$form->{description}">|;
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
<input type=hidden name=type value=warehouse>

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align=right>|.$locale->text('Description').qq|</th>
    <td>$description</td>
  </tr>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_warehouse {

  $form->isblank("description", $locale->text('Description missing!'));
  AM->save_warehouse(\%myconfig, \%$form);
  $form->redirect($locale->text('Warehouse saved!'));

}


sub delete_warehouse {

  AM->delete_warehouse(\%myconfig, \%$form);
  $form->redirect($locale->text('Warehouse deleted!'));

}


sub yearend {

  AM->earningsaccounts(\%myconfig, \%$form);
  map { $chart .= "<option>$_->{accno}--$_->{description}" } @{ $form->{chart} };
  
  $form->{title} = $locale->text('Close Accounts');
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

<input type=hidden name=decimalplaces value=2>
<input type=hidden name=l_accno value=Y>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text('Yearend').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}" id=todate OnBlur="return dattrans('todate');" value=$todate></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Reference').qq|</th>
	  <td><input name=reference class="required" size=20></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Description').qq|</th>
	  <td><textarea name=description rows=3 cols=50 wrap=soft></textarea></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Retained Earnings').qq|</th>
	  <td><select class="required" name=accno>$chart</select></td>
	</tr>
	<tr>
          <th align=right>|.$locale->text('Method').qq|</th>
          <td><input name=method class=radio type=radio value=accrual checked>&nbsp;|.$locale->text('Accrual').qq|&nbsp;<input name=method class=radio type=radio value=cash>&nbsp;|.$locale->text('Cash').qq|</td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<input type=hidden name=nextsub value=generate_yearend>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input class=submit type=submit name=action onclick="return checkform();" 	value="|.$locale->text('Continue').qq|">|;

}


sub generate_yearend {

  $form->isblank("todate", $locale->text('Yearend date missing!'));
  $form->isblank("reference", $locale->text('Reference missing!'));

  RP->yearend_statement(\%myconfig, \%$form);
  
  $form->{transdate} = $form->{todate};

  $earnings = 0;
#kabai BUG
  ($form->{accno}) = split /--/, $form->{accno};

  $form->{rowcount} = 1;
  foreach $key (keys %{ $form->{I} }) {
    if ($form->{I}{$key}{charttype} eq "A") {
      $form->{"debit_$form->{rowcount}"} = $form->{I}{$key}{this};
      $earnings += $form->{I}{$key}{this};
      $form->{"accno_$form->{rowcount}"} = $key;
      $form->{rowcount}++;
      $ok = 1;
    }
  }

  foreach $key (keys %{ $form->{E} }) {
    if ($form->{E}{$key}{charttype} eq "A") {
      $form->{"credit_$form->{rowcount}"} = $form->{E}{$key}{this} * -1;
      $earnings += $form->{E}{$key}{this};
      $form->{"accno_$form->{rowcount}"} = $key;
      $form->{rowcount}++;
      $ok = 1;
    }
  }
  if ($earnings > 0) {
    $form->{"credit_$form->{rowcount}"} = $earnings;
    $form->{"accno_$form->{rowcount}"} = $form->{accno}
  } else {
    $form->{"debit_$form->{rowcount}"} = $earnings * -1;
    $form->{"accno_$form->{rowcount}"} = $form->{accno}
  }

  if ($ok) {
    if (AM->post_yearend(\%myconfig, \%$form)) {
      $form->redirect($locale->text('Yearend posted!'));
    }
    $form->error($locale->text('Yearend posting failed!'));
  } else {
    $form->error('Nothing to do!');
  }
  
}


sub continue {
  &{ $form->{nextsub} };

}

sub company_logo {
  
  require "$userspath/$form->{login}.conf";
  $locale = new Locale $myconfig{countrycode}, "login" unless ($language eq $myconfig{countrycode});

  $myconfig{address} =~ s/\\n/<br>/g;
  $myconfig{dbhost} = $locale->text('localhost') unless $myconfig{dbhost};

  map { $form->{$_} = $myconfig{$_} } qw(charset stylesheet);
  
  $form->{title} = $locale->text('About');
  
 
  # create the logo screen
  $form->header unless $form->{noheader};

#kabai
  print qq|
<body>

<pre>

</pre>
<center>
<a href="http://www.tavugyvitel.hu" target=_top><img src=icons/ledger_logo.gif border=0></a>
<br>
|.$locale->text('Open source accounting software').qq|&nbsp;&nbsp;<a href="http://www.tavugyvitel.hu">http://www.tavugyvitel.hu</a>
<p>
<b>
|.$locale->text('Version Number').qq|</b>: $form->{version}
<p>

|.$locale->text('Licensed to').qq|
<p>
<b>
$myconfig{company}
<br>$myconfig{address}
</b>

<p>
<table border=0>
  <tr>
    <th align=right>|.$locale->text('User').qq|</th>
    <td>$myconfig{name}</td>
  </tr>
  <tr>
    <th align=right>|.$locale->text('Dataset').qq|</th>
    <td>$myconfig{dbname}</td>
  </tr>
  <tr>
    <th align=right>|.$locale->text('Database Host').qq|</th>
    <td>$myconfig{dbhost}</td>
  </tr>
</table>

</center>

</body>

</html>
|;

}

sub show_curr {#kabai

  
  $form->{transdate} = $form->current_date(\%myconfig) if $form->{start};
  $form->isblank("transdate", $locale->text('Currency Date missing!'));
  
  AM->get_basecurr(\%myconfig, \%$form);
  # currencies
  @curr = split /:/, $form->{currencies};
  shift @curr;
  map { $form->{selectcurrency} .= "<option>$_\n" } @curr;
  chomp $curr[0];
  $form->{currency} = $curr[0] if $form->{start};
  AM->get_curr(\%myconfig, \%$form);

  &curr_header;
  &curr_footer;

}

sub curr_header { #kabai

  $form->{title} = $locale->text('Show Currencies');
  
  map { ${"${_}text"} = $form->{"${_}_noedit"} ? "<input type=hidden name=$_ value=".$form->format_amount(\%myconfig,$form->{$_}).">".$form->format_amount(\%myconfig,$form->{$_}) : "<input size=6 name=$_ value=".$form->format_amount(\%myconfig,$form->{$_}).">"} qw(buy sell buy_paid sell_paid);
  
  $form->{selectcurrency} =~ s/ selected//;
  $form->{selectcurrency} =~ s/option>\Q$form->{currency}\E/option selected>$form->{currency}/;

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
<input name=currency0 type=hidden value="$form->{currency0}">
<input name=transdate0 type=hidden value="$form->{transdate0}">

<table width=100%>
  <tr>
    <th class=listtop colspan=4>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>

   <td align=right width=8%>
   |.$locale->text('Date').qq|
   </td><td>
      <input name=transdate value=$form->{transdate} size=11 title="$myconfig{dateformat}" id=transdate OnBlur="return dattrans('transdate');">
   </td>
  <td colspan=2>&nbsp;</td>
  </tr>
  <tr>
   <td align=right>
    |.$locale->text('Currency').qq|
   </td><td>
    <select name=currency>$form->{selectcurrency}</select>
   </td>
  <td colspan=3>&nbsp;</td>
  </tr>
  <tr><td colspan=4>&nbsp;</td></tr>
</table>
<table width=40%>
  <tr class=listheading>
  <td class=listheading>|.$locale->text('AR rate').qq|</td>
  <td class=listheading>|.$locale->text('AP rate').qq|</td>
  <td class=listheading>|.$locale->text('AR bankrate').qq|</td>
  <td class=listheading>|.$locale->text('AP bankrate').qq|</td>
  </tr>
  <tr>
  
  <td>$buytext</td>
  <td>$selltext</td>
  <td>$buy_paidtext</td>
  <td>$sell_paidtext</td>
  </tr>
</table> |;

}

sub curr_footer {

  print qq|

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<br>
<input type=submit class=submit name=action value="|.$locale->text('Show Currencies').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Save Currencies').qq|">
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
sub save_curr {

  $form->isblank("transdate", $locale->text('Currency Date missing!'));

  if($form->{transdate0} && $form->{currency0}) { 
	if (($form->{currency0} ne $form->{currency}) || ($form->{transdate0} ne $form->{transdate})){
		$form->error($locale->text('If you change currency or date press Show Currencies first!')); 
        }
  }
  map { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_})} qw(buy sell buy_paid sell_paid);
  map { $form->{$_} = 0 if !$form->{$_}} qw(buy sell buy_paid sell_paid);

  AM->save_curr(\%myconfig, \%$form);
  &show_curr;

}  

sub update {
#  AM->get_cashlimit(\%myconfig,\%$form); 
  $form->{cash}=1;
  $form->{type}="regnum";
 &regnum_header;
 &form_footer;
}


sub save_account2 {

  $form->isblank("accno", $locale->text('Account Number missing!'));
  $form->isblank("description", $locale->text('Description missing!'));
  $form->isblank("category", $locale->text('Account Type missing!'));
  
  
  AM->save_account(\%myconfig, \%$form);
  

}

sub save_as_new{
  $form->{id}=0;
  &save;
}

