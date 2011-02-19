#======================================================================
#
# Account reconciliation module
#
#======================================================================


use SL::RC;


1;
# end of main


sub reconciliation {
  
  RC->paymentaccounts(\%myconfig, \%$form);

  $selection = "";
  map { $selection .= "<option>$_->{accno}--$_->{description}\n" } @{ $form->{PR} };

  $form->{title} = $locale->text('Reconciliation');

  $form->header;

  print qq|
<body>

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
	  <th align=right nowrap>|.$locale->text('Account').qq|</th>
	  <td colspan=3><select name=accno>$selection</select>
	  </td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=fromdate size=11 title="$myconfig{dateformat}"></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}"></td>
	</tr>
	<tr>
	  <td align=right><input type=checkbox style=checkbox name=fx_transaction value=1 checked></td>
	  <th align=left colspan=3>|.$locale->text('Include Exchangerate Difference').qq|</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input type=hidden name=nextsub value=get_payments>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=password value=$form->{password}>

<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">

</form>

</body>
</html>
|;

}


sub continue { &{ $form->{nextsub} } };


sub get_payments {

  ($form->{accno}, $form->{account}) = split /--/, $form->{accno};

  RC->payment_transactions(\%myconfig, \%$form);
 
  &display_form;

}


sub display_form {
  
  @column_index = qw(cleared transdate source name credit debit balance);
  
  $column_header{cleared} = "<th>&nbsp;</th>";
  $column_header{source} = "<th class=listheading>".$locale->text('Source')."</a></th>";
  $column_header{name} = "<th class=listheading>".$locale->text('Description')."</a></th>";
  $column_header{transdate} = "<th class=listheading>".$locale->text('Date')."</a></th>";

  if ($form->{category} eq 'A') {
    $column_header{debit} = "<th class=listheading>".$locale->text('Deposit')."</a></th>";
    $column_header{credit} = "<th class=listheading>".$locale->text('Payment')."</a></th>";
  } else {
    $column_header{debit} = "<th class=listheading>".$locale->text('Decrease')."</a></th>";
    $column_header{credit} = "<th class=listheading>".$locale->text('Increase')."</a></th>";
  }

  $column_header{balance} = "<th class=listheading>".$locale->text('Balance')."</a></th>";

  if ($form->{fromdate}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{fromdate}, 1);
  }
  if ($form->{todate}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{todate}, 1);
  }

  $form->{title} = "$form->{accno}--$form->{account}";
  
  $form->header;

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

  map { print "\n$column_header{$_}" } @column_index;

  print qq|
        </tr>
|;

  $ml = ($form->{category} eq 'A') ? -1 : 1;
  $form->{beginningbalance} *= $ml;
  $form->{fx_balance} *= $ml;

  if (! $form->{fx_transaction}) {
    $form->{beginningbalance} -= $form->{fx_balance};
  }
  $balance = $form->{beginningbalance};
  
  $i = 0;
  $id = 0;

  $j = 0;
  
  map { $column_data{$_} = "<td>&nbsp;</td>" } qw(cleared transdate source debit credit);

  $column_data{name} = qq|<td>|.$locale->text('Beginning Balance').qq|</td>|;
  $column_data{balance} = "<td align=right>".$form->format_amount(\%myconfig, $balance, 2, 0)."</td>";
  print qq|
	<tr class=listrow$j>
|;

  map { print "\n$column_data{$_}" } @column_index;

  print qq|
	</tr>
|;

  
  foreach $ref (@{ $form->{PR} }) {

    $column_data{name} = "<td>$ref->{name}&nbsp;</td>";
    $column_data{source} = qq|<td>$ref->{source}&nbsp;</td>|;
    $column_data{transdate} = "<td>$ref->{transdate}&nbsp;</td>";
    
    $column_data{debit} = "<td>&nbsp;</td>";
    $column_data{credit} = "<td>&nbsp;</td>";
    
    if ($form->{fx_transaction}) {
      $balance += $ref->{amount} * $ml;
    } else {
      if (! $ref->{fx_transaction}) {
	$balance += $ref->{amount} * $ml;
      }
    }

    $cleared += $ref->{amount} * $ml if $ref->{cleared};
      
    if ($ref->{amount} < 0) {

      if ($form->{fx_transaction}) {
	$totaldebits += $ref->{amount} * -1;
      } else {
	if (! $ref->{fx_transaction}) {
	  $totaldebits += $ref->{amount} * -1;
	}
      }
      
      $column_data{debit} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount} * -1, 2, "&nbsp;")."</td>";
    } else {

      if ($form->{fx_transaction}) {
	$totalcredits += $ref->{amount};
      } else {
	if (! $ref->{fx_transaction}) {
	  $totalcredits += $ref->{amount};
	}
      }
      
      $column_data{credit} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount}, 2, "&nbsp;")."</td>";
    }
    
    $column_data{balance} = "<td align=right>".$form->format_amount(\%myconfig, $balance, 2, 0)."</td>";

    if ($ref->{fx_transaction}) {
      $i++ unless $id == $ref->{id};
      $fx_transaction = 1;

      $fx{$ref->{id}} = $ref->{amount};
      
      if ($form->{fx_transaction}) {
	$column_data{cleared} = qq|<td>&nbsp;<input type=hidden name="fxoid_$i" value=$ref->{oid}></td>|;
      } else {
	print qq|<input type=hidden name="fxoid_$i" value=$ref->{oid}>|;
	$id = $ref->{id};
	next;
      }
      
    } else {
      $i++ unless ($fx_transaction && $id == $ref->{id});
      $fx_transaction = 0;
      $column_data{cleared} = qq|<td><input name="cleared_$i" type=checkbox class=checkbox value=1 $ref->{cleared}>
      <input type=hidden name="oid_$i" value=$ref->{oid}></td>|;
    }
    $id = $ref->{id};

    $j++; $j %= 2;
    print qq|
	<tr class=listrow$j>
|;

    map { print "\n$column_data{$_}" } @column_index;

    print qq|
	</tr>
|;

  }

  $form->{rowcount} = $i;
  
  # figure out exchangerate difference to add
  if ($form->{fx_transaction}) {
    map { $fx += $fx{$_->{id}} * $ml if $_->{cleared} } @{ $form->{PR} };
  }

  # print totals
  map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;

  $column_data{debit} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totaldebits, 2, "&nbsp;")."</th>";
  $column_data{credit} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalcredits, 2, "&nbsp;")."</th>";
   
  print qq|
	<tr class=listtotal>
|;

  map { print "\n$column_data{$_}" } @column_index;

  $form->{statementbalance} = $form->parse_amount(\%myconfig, $form->{statementbalance});
  $difference = $form->format_amount(\%myconfig, $form->{statementbalance} - $form->{beginningbalance} - $cleared - $fx, 2, 0);
  
  $form->{statementbalance} = $form->format_amount(\%myconfig, $form->{statementbalance}, 2, 0);

  print qq|
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width=100%>
        <tr>
	  <td align=right>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Statement Balance').qq|</th>
		<td width=10%></td>
		<td align=right><input name=statementbalance size=11 value=$form->{statementbalance}></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Difference').qq|</th>
		<td width=10%></td>
		<td align=right><input name=null size=11 value=$difference></td>
		<input type=hidden name=difference value=$difference>
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

<input type=hidden name=fx_transaction value=$form->{fx_transaction}>

<input type=hidden name=rowcount value=$form->{rowcount}>
<input type=hidden name=accno value=$form->{accno}>
<input type=hidden name=account value="$form->{account}">

<input type=hidden name=fromdate value=$form->{fromdate}>
<input type=hidden name=todate value=$form->{todate}>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=password value=$form->{password}>

<br>
<input type=submit class=submit name=action value="|.$locale->text('Update').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Select all').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Done').qq|">|;

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


sub update {
  
  RC->payment_transactions(\%myconfig, \%$form);

  foreach $ref (@{ $form->{PR} }) {
    if (!$ref->{fx_transaction}) {
      $i++;
      $ref->{cleared} = ($form->{"cleared_$i"}) ? "checked" : "";
    }
  }

  &display_form;
  
}


sub select_all {
  
  RC->payment_transactions(\%myconfig, \%$form);

  map { $_->{cleared} = "checked" unless $_->{fx_transaction} } @{ $form->{PR} };

  &display_form;
  
}


sub done {

  $form->{callback} = "$form->{script}?path=$form->{path}&action=reconciliation&login=$form->{login}&password=$form->{password}";

  $form->error($locale->text('Out of balance!')) if ($form->{difference} *= 1);

  RC->reconcile(\%myconfig, \%$form);
  $form->redirect;
  
}


