#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2007
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#     Modified by  Tavugyvitel Kft. (info@tavugyvitel.hu)
#    
#======================================================================
#
# import/export
#
#======================================================================


use SL::IM;
use SL::CP;
use SL::OE;
 
1;
# end of main


sub import {

  %title = ( 
	     orders => 'Orders'
	   );


  $msg = "Import $title{$form->{type}}";
  $form->{title} = $locale->text($msg);
  
  $form->header;

  $form->{nextsub} = "im_$form->{type}";
  $form->{action} = "continue";
 
print qq|
<body>

<form enctype="multipart/form-data" method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
        $paymentaccount
        <tr>
	  <th align=right>|.$locale->text('Import File').qq|</th>
	  <td>
	    <input name=filename size=60 type="file">
	  </td>
	</tr>
	<tr valign=top>
	  <th align=right>|.$locale->text('Type of File').qq|</th>
	  <td>
	    <table>
	      <tr>
	        <td><input name=filetype type=radio class=radio value=CSV checked>&nbsp;|.$locale->text('CSV').qq|</td>
		<td width=20></td>
		<th align=right>|.$locale->text('Delimiter').qq|</th>
		<td><input name=delimiter size=2 value=","></td>
	      </tr>
	      <tr>
		<th align=right colspan=2>|.$locale->text('Tab delimited file').qq|</th>
		<td align=left><input name=tabdelimited type=checkbox class=checkbox></td>
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
|;

#not implemented yet	<tr>
#	  <th align=right>|.$locale->text('Mapfile').qq|</th>
#	  <td><input name=mapfile type=radio class=radio value=1>&nbsp;|.$locale->text('Yes').qq|&nbsp;
#	      <input name=mapfile type=radio class=radio value=0 checked>&nbsp;|.$locale->text('No').qq|
#	  </td>
#	</tr>
  $form->hide_form(qw(defaultcurrency title type action nextsub login path sessionid));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;
}

sub im_orders {
$form->error($locale->text('Import File missing!')) if ! $form->{filename};

my $filehandler = $form->{filehandler};
LINE: while (<$filehandler>) {
	#next LINE if (1 .. 1);		# skip the header line
	next LINE if (/^[\s]*$/);	# skip empty lines
	chomp;				# remove LF
	$_ =~ s/\r$//;
	if ($form->{data}){
	  $form->{data}.= "\n".$_;
	}else{
  	  $form->{data} = $_;
	}
}

  @column_index = qw(ndx transdate ordnumber customer customernumber city ordernotes total curr totalqty unit duedate employee);
  @flds = @column_index;
  shift @flds;
  push @flds, qw(ordnumber quonumber customer_id datepaid shippingpoint shipvia waybill terms notes intnotes language_code ponumber cashdiscount discountterms employee_id parts_id description sellprice discount qty unit serialnumber projectnumber deliverydate AR taxincluded);
  unshift @column_index, "runningnumber";
    
  $form->{callback} = "$form->{script}?action=import";
  for (qw(type login path)) { $form->{callback} .= "&$_=$form->{$_}" }

  &xrefhdr;
  
  $form->{vc} = 'customer';
  IM->order(\%myconfig, \%$form);

  $column_data{runningnumber} = "&nbsp;";
  $column_data{transdate} = $locale->text('Invoice Date');
  $column_data{ordnumber} = $locale->text('Order Number');
  $column_data{ordernotes} = $locale->text('Description');
  $column_data{customer} = $locale->text('Customer');
  $column_data{customernumber} = $locale->text('Customer Number');
  $column_data{city} = $locale->text('City');
  $column_data{total} = $locale->text('Total');
  $column_data{totalqty} = $locale->text('Qty');
  $column_data{curr} = $locale->text('Curr');
  $column_data{unit} = $locale->text('Unit');
  $column_data{duedate} = $locale->text('Due Date');


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
      <table width=100%>
        <tr class=listheading>
|;

  for (@column_index) { print "\n<th>$column_data{$_}</th>" }

  print qq|
        </tr>
|;

  @ndx = split / /, $form->{ndx};
  $ndx = shift @ndx;
  $k = 0;

  for $i (1 .. $form->{rowcount}) {
    
    if ($i == $ndx) {
      $k++;
      $j++; $j %= 2;
      $ndx = shift @ndx;
   
      print qq|
        <tr class=listrow$j>
|;

      $total += $form->{"total_$i"};
      
      for (@column_index) { $column_data{$_} = qq|<td>$form->{"${_}_$i"}</td>| }
      $column_data{total} = qq|<td align=right>|.$form->format_amount(\%myconfig, $form->{"total_$i"}, $form->{precision}).qq|</td>|;
      $column_data{totalqty} = qq|<td align=right>|.$form->format_amount(\%myconfig, $form->{"totalqty_$i"}).qq|</td>|;

      $column_data{runningnumber} = qq|<td align=right>$k</td>|;
      
      if ($form->{"customer_id_$i"}) {
	$column_data{ndx} = qq|<td><input name="ndx_$i" type=checkbox class=checkbox checked></td>|;
      } else {
	$column_data{ndx} = qq|<td>&nbsp;</td>|;
      }

      for (@column_index) { print $column_data{$_} }

      print qq|
	</tr>
|;
    
    }

    $form->hide_form(map { "${_}_$i" } @flds);
    
  }

  # print total
  for (@column_index) { $column_data{$_} = qq|<td>&nbsp;</td>| }
  $column_data{total} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $total, $form->{precision}, "&nbsp;")."</th>";

  print qq|
        <tr class=listtotal>
|;

  for (@column_index) { print "\n$column_data{$_}" }
  
  print qq|
        </tr>
      </table>
    </td>
  </tr>
|;

  if ($form->{missingparts}) {
    print qq|
    <tr>
      <td>|;
      $form->info($locale->text('The following parts could not be found:')."\n\n");
      for (split /\n/, $form->{missingparts}) {
	$form->info("$_\n");
      }
    print qq|
      </td>
    </tr>
|;
  }

  print qq|
  <tr>
    <td><hr size=3 noshade></td>
  </tr>

</table>
|;
  $form->hide_form(qw(vc rowcount ndx type login path callback sessionid));

  print qq|
<input name=action class=submit type=submit value="|.$locale->text('Import Orders').qq|">
</form>

</body>
</html>
|;

}


sub xrefhdr {
  
  $form->{delimiter} ||= ',';
  $i = 0;

  if ($form->{mapfile}) {
    open(FH, "$myconfig{templates}/import.map") or $form->error($!);

    while (<FH>) {
      next if /^(#|;|\s)/;
      chomp;

      s/\s*(#|;).*//g;
      s/^\s*(.*?)\s*$/$1/;

      last if $xrefhdr && $_ =~ /^\[/;

      if (/^\[$form->{type}\]/) {
	$xrefhdr = 1;
	next;
      }

      if ($xrefhdr) {
	($key, $value) = split /=/, $_;
	@a = split /,/, $value;
	$form->{$form->{type}}{$a[0]} = { field => $key, length => $a[1], ndx => $i++ };
      }
    }
    close FH;
    
  } else {
    # get first line
    @a = split /\n/, $form->{data};

    if ($form->{tabdelimited}) {
      $form->{delimiter} = '\t';
    } else {
      $a[0] =~ s/(^"|"$)//g;
      $a[0] =~ s/"$form->{delimiter}"/$form->{delimiter}/g;
    }
      
    for (split /$form->{delimiter}/, $a[0]) {
      $form->{$form->{type}}{$_} = { field => $_, length => "", ndx => $i++ };
    }
  }

}

sub import_orders {
  
  $form->{header}=0;
  $form->header;

 my $rowsz=$form->{rowcount};
 my $ssz=1;
 $form->{vc}="customer";
 $form->{defaultcurrency} = "HUF";
 $form->{noexch_update} = 1;
 $form->{type}="_order";
 while ($ssz <=$rowsz) {
   $form->{customer_id}=$form->{"customer_id_$ssz"};
   $form->{ordnumber}=$form->{"ordnumber_$ssz"};
   $form->{id}=0;
   $form->{currency}=$form->{"curr_$ssz"};
   $form->{transdate}=$form->{"transdate_$ssz"};
   $form->{reqdate}=$form->{"duedate_$ssz"};
   $form->{amount}=$form->{"total_$ssz"};
   $form->{id_1}=$form->{"parts_id_$ssz"};
   $form->{description_1}=$form->{"description_$ssz"};
   $form->{qty_1}=$form->{"qty_$ssz"};
   $form->{notes}=$form->{"ordernotes_$ssz"};
   $form->{sellprice_1}=$form->{"sellprice_$ssz"};
   $sszv=$ssz+1;
   while ($sszv<=$rowsz & !$form->{"customer_$sszv"}) {
     my $ssk=$sszv-$ssz+1;
     $form->{"id_$ssk"}=$form->{"parts_id_$sszv"};
     $form->{"description_$ssk"}=$form->{"description_$sszv"};
     $form->{"qty_$ssk"}=$form->{"qty_$sszv"};
     $form->{"sellprice_$ssk"}=$form->{"sellprice_$sszv"};
     $sszv+=1;
   }
   $form->{rowcount}=$sszv-$ssz;      
   if ($form->{"ndx_$ssz"}){
     if (OE->save(\%myconfig, \%$form)) {
	$form->info(qq|$form->{ordnumber}|); 
	$myconfig{numberformat} = $numberformat;
	$myconfig{numberformat} = "1000,00";
	$form->info(" ... ".$locale->text('ok')."\n");
      } else {
	$form->error($locale->text('Posting failed!'));
      }
    }
    $ssz=$sszv;
  }
}

sub continue {&{ $form->{nextsub} } };


