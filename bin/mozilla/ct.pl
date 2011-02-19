#=====================================================================
# SQL-Ledger Accounting
# Copyright (c) 2001
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#
#  Contributors: Reed White <alta@alta-research.com>
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
# customer/vendor module
#
#======================================================================

use SL::CT;

1;
# end of main



sub add {

  $form->{title} = "Add";
# $locale->text('Add Customer')
# $locale->text('Add Vendor')

  $form->{callback} = "$form->{script}?action=add&db=$form->{db}&path=$form->{path}&login=$form->{login}&password=$form->{password}" unless $form->{callback};

  CT->create_links(\%myconfig, \%$form);
  
  &form_header;
  &form_footer;
  
}


sub history {

# $locale->text('Customer History')
# $locale->text('Vendor History')

  $history = 1;
  $label = ucfirst $form->{db};
  $label .= " History";

  if ($form->{db} eq 'customer') {
    $invlabel = $locale->text('Sales Invoices');
    $ordlabel = $locale->text('Sales Orders');
    $quolabel = $locale->text('Quotations');
  } else {
    $invlabel = $locale->text('Vendor Invoices');
    $ordlabel = $locale->text('Purchase Orders');
    $quolabel = $locale->text('Request for Quotations');
  }
  
  $form->{title} = $locale->text($label);
  
  $form->{nextsub} = "list_history";

  $transactions = qq|
 	<tr>
	  <td></td>
	  <td>
	    <table>
	      <tr>
	        <td>
		  <table>
		    <tr>
		      <td><input name=type type=radio class=radio value=invoice checked> $invlabel</td>
		    </tr>
		    <tr>
		      <td><input name=type type=radio class=radio value=order> $ordlabel</td>
		    </tr>
		    <tr>
		      <td><input name="type" type=radio class=radio value=quotation> $quolabel</td>
		    </tr>
		  </table>
		</td>
		<td>
		  <table>
		    <tr>
		      <th>|.$locale->text('From').qq|</th>
		      <td><input name=transdatefrom size=11 title="$myconfig{dateformat}"></td>
		      <th>|.$locale->text('To').qq|</th>
		      <td><input name=transdateto size=11 title="$myconfig{dateformat}"></td>
		    </tr>
		    <tr>
		      <td></td>
		      <td colspan=3>
	              <input name="open" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Open').qq|
	              <input name="closed" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Closed').qq|
		      </td>
		    </tr>
		  </table>
		</td>
	      </tr>
 	    </table>
	  </td>
	</tr>
|;

  $include = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td>
	    <table>
	      <tr>
		<td><input name=history type=radio class=radio value=summary checked> |.$locale->text('Summary').qq|</td>
		<td><input name=history type=radio class=radio value=detail> |.$locale->text('Detail').qq|
		</td>
	      </tr>
	      <tr>
		<td>
		<input name="l_partnumber" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Part Number').qq|
		</td>
		<td>
		<input name="l_description" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Description').qq|
		</td>
		<td>
		<input name="l_sellprice" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Price').qq|
		</td>
		<td>
		<input name="l_curr" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Currency').qq|
		</td>
	      </tr>
	      <tr>
		<td>
		<input name="l_qty" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Qty').qq|
		</td>
		<td>
		<input name="l_unit" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Unit').qq|
		</td>
		<td>
		<input name="l_discount" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Discount').qq|
		</td>
	      <tr>
	      </tr>
		<td>
		<input name="l_deliverydate" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Delivery Date').qq|
		</td>
		<td>
		<input name="l_projectnumber" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Project Number').qq|
		</td>
		<td>
		<input name="l_serialnumber" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Serial Number').qq|
		</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;

  &search_name;

}


sub transactions {

  if ($form->{db} eq 'customer') {
    $translabel = $locale->text('AR Transactions');
    $invlabel = $locale->text('Sales Invoices');
    $ordlabel = $locale->text('Sales Orders');
    $quolabel = $locale->text('Quotations');
  } else {
    $translabel = $locale->text('AP Transactions');
    $invlabel = $locale->text('Vendor Invoices');
    $ordlabel = $locale->text('Purchase Orders');
    $quolabel = $locale->text('Request for Quotations');
  }

 
  $transactions = qq|
 	<tr>
	  <td></td>
	  <td>
	    <table>
	      <tr>
	        <td>
		  <table>
		    <tr>
		      <td><input name="l_transnumber" type=checkbox class=checkbox value=Y> $translabel</td>
		    </tr>
		    <tr>
		      <td><input name="l_invnumber" type=checkbox class=checkbox value=Y> $invlabel</td>
		    </tr>
		    <tr>
		      <td><input name="l_ordnumber" type=checkbox class=checkbox value=Y> $ordlabel</td>
		    </tr>
		    <tr>
		      <td><input name="l_quonumber" type=checkbox class=checkbox value=Y> $quolabel</td>
		    </tr>
		  </table>
		</td>
		<td>
		  <table>
		    <tr>
		      <th>|.$locale->text('From').qq|</th>
		      <td><input name=transdatefrom size=11 title="$myconfig{dateformat}"></td>
		      <th>|.$locale->text('To').qq|</th>
		      <td><input name=transdateto size=11 title="$myconfig{dateformat}"></td>
		    </tr>
		    <tr>
		      <td></td>
		      <td colspan=3>
	              <input name="open" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Open').qq|
	              <input name="closed" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Closed').qq|
		      </td>
		    </tr>
		    <tr>
		      <td></td>
		      <td colspan=3>
	              <input name="l_amount" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Amount').qq|
	              <input name="l_tax" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Tax').qq|
	              <input name="l_total" type=checkbox class=checkbox value=Y checked>&nbsp;|.$locale->text('Total').qq|
	              <input name="l_subtotal" type=checkbox class=checkbox value=Y>&nbsp;|.$locale->text('Subtotal').qq|
		      </td>
		    </tr>
		  </table>
		</td>
	      </tr>
 	    </table>
	  </td>
	</tr>
|;

}


sub include_in_report {
  
  $label = ucfirst $form->{db};
  
  if ($myconfig{role} =~ /(admin|manager)/) {
    $bcc = qq|
		<td><input name="l_bcc" type=checkbox class=checkbox value=Y> |.$locale->text('Bcc').qq|</td>
|;
  }

  if ($form->{db} eq 'customer') {
    $employee = qq|
		<td><input name="l_employee" type=checkbox class=checkbox value=Y> |.$locale->text('Salesperson').qq|</td>
|;

    $pricegroup = qq|
		<td><input name="l_pricegroup" type=checkbox class=checkbox value=Y> |.$locale->text('Pricegroup').qq|</td>
|;

  } else {
    $employee = qq|
		<td><input name="l_employee" type=checkbox class=checkbox value=Y> |.$locale->text('Employee').qq|</td>
|;
  }

  $employee .= qq|
                <td><input name="l_manager" type=checkbox class=checkbox value=Y> |.$locale->text('Manager').qq|</td>
|;
    
  $include = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Include in Report').qq|</th>
	  <td>
	    <table>
	      <tr>
	        <td><input name="l_id" type=checkbox class=checkbox value=Y> |.$locale->text('ID').qq|</td>
		<td><input name="l_$form->{db}number" type=checkbox class=checkbox value=Y> |.$locale->text($label . ' Number').qq|</td>
		<td><input name="l_name" type=checkbox class=checkbox value=Y $form->{l_name}> |.$locale->text('Company Name').qq|</td>
		<td><input name="l_contact" type=checkbox class=checkbox value=Y $form->{l_contact}> |.$locale->text('Contact').qq|</td>
		<td><input name="l_email" type=checkbox class=checkbox value=Y $form->{l_email}> |.$locale->text('E-mail').qq|</td>
	      </tr>
	      <tr>
		<td><input name="l_address" type=checkbox class=checkbox value=Y> |.$locale->text('Address').qq|</td>
		<td><input name="l_city" type=checkbox class=checkbox value=Y> |.$locale->text('City').qq|</td>
		<td><input name="l_state" type=checkbox class=checkbox value=Y> |.$locale->text('State/Province').qq|</td>
		<td><input name="l_zipcode" type=checkbox class=checkbox value=Y> |.$locale->text('ZIP/Code').qq|</td>
		<td><input name="l_country" type=checkbox class=checkbox value=Y> |.$locale->text('Country').qq|</td>
	      </tr>
	      <tr>
		<td><input name="l_phone" type=checkbox class=checkbox value=Y $form->{l_phone}> |.$locale->text('Phone').qq|</td>
		<td><input name="l_fax" type=checkbox class=checkbox value=Y> |.$locale->text('Fax').qq|</td>
		<td><input name="l_cc" type=checkbox class=checkbox value=Y> |.$locale->text('Cc').qq|</td>
		$bcc
		<td><input name="l_notes" type=checkbox class=checkbox value=Y> |.$locale->text('Notes').qq|</td>
	      </tr>
	      <tr>
		<td><input name="l_taxnumber" type=checkbox class=checkbox value=Y> |.$locale->text('Tax Number').qq|</td>
		$gifi
		<td><input name="l_sic_code" type=checkbox class=checkbox value=Y> |.$locale->text('SIC').qq|</td>
		<td><input name="l_iban" type=checkbox class=checkbox value=Y> |.$locale->text('IBAN').qq|</td>
		<td><input name="l_bic" type=checkbox class=checkbox value=Y> |.$locale->text('BIC').qq|</td>
	      </tr>
	      <tr>
		$employee
		<td><input name="l_business" type=checkbox class=checkbox value=Y> |.$locale->text('Type of Business').qq|</td>
		$pricegroup
		<td><input name="l_language" type=checkbox class=checkbox value=Y> |.$locale->text('Language').qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;

}


sub search {

# $locale->text('Customers')
# $locale->text('Vendors')

  $form->{title} = $locale->text('Search') unless $form->{title};
  
  map { $form->{"l_$_"} = 'checked' } qw(name contact phone email);

  $form->{nextsub} = "list_names";

  $orphan = qq|
	<tr>
	  <td></td>
	  <td><input name=status class=radio type=radio value=all checked>&nbsp;|.$locale->text('All').qq|
	  <input name=status class=radio type=radio value=orphaned>&nbsp;|.$locale->text('Orphaned').qq|</td>
	</tr>
|;

  if ($form->{db} eq 'vendor') {
    $gifi = qq|
		<td><input name="l_gifi_accno" type=checkbox class=checkbox value=Y> |.$locale->text('GIFI').qq|</td>
|;
  }
 
  &transactions;
  &include_in_report;
  &search_name;

}


sub search_name {

  $label = ucfirst $form->{db};
  
 
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=db value=$form->{db}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text($label . ' Number').qq|</th>
	  <td><input name=$form->{db}number size=35></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Company Name').qq|</th>
	  <td><input name=name size=35></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Contact').qq|</th>
	  <td><input name=contact size=35></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('E-mail').qq|</th>
	  <td><input name=email size=35></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Notes').qq|</th>
	  <td><input name=notes size=35></td>
	</tr>

        $invnumber
	$orphan
	$transactions
	$include

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
<input type=hidden name=password value=$form->{password}>

<br>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;
}


sub list_names {

  CT->search(\%myconfig, \%$form);
  
  $href = "$form->{script}?action=list_names&direction=$form->{direction}&oldsort=$form->{oldsort}&db=$form->{db}&path=$form->{path}&login=$form->{login}&password=$form->{password}&status=$form->{status}&l_subtotal=$form->{l_subtotal}";
  
  $form->sort_order();
  
  $callback = "$form->{script}?action=list_names&direction=$form->{direction}&oldsort=$form->{oldsort}&db=$form->{db}&path=$form->{path}&login=$form->{login}&password=$form->{password}&status=$form->{status}&l_subtotal=$form->{l_subtotal}";
  
  @columns = $form->sort_columns(id, name, "$form->{db}number", address,
                                 city, state, zipcode, country, contact,
				 phone, fax, email, cc, bcc, employee,
				 manager, notes,
				 taxnumber, gifi_accno, sic_code, business,
				 pricegroup, language, iban, bic,
				 invnumber, invamount, invtax, invtotal,
				 ordnumber, ordamount, ordtax, ordtotal,
				 quonumber, quoamount, quotax, quototal);

  foreach $item (qw(inv ord quo)) {
    if ($form->{"l_${item}number"}) {
      map { $form->{"l_$item$_"} = $form->{"l_$_"} } qw(amount tax total);
      $removeemployee = 1;
      $openclosed = 1;
    }
  }
  $form->{open} = $form->{closed} = "" if !$openclosed;

  if ($form->{l_transnumber}) {
    map { $form->{"l_inv$_"} = $form->{"l_$_"} } qw(amount tax total);
    $removeemployee = 1;
  }

  if ($removeemployee) {
    @columns = grep !/(employee|manager)/, @columns;
  }


  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;

      # add column to href and callback
      $callback .= "&l_$item=Y";
      $href .= "&l_$item=Y";
    }
  }
  
  foreach $item (qw(amount tax total transnumber)) {
    if ($form->{"l_$item"} eq "Y") { 
      $callback .= "&l_$item=Y"; 
      $href .= "&l_$item=Y"; 
    }
  }


  if ($form->{status} eq 'all') {
    $option = $locale->text('All');
  }
  if ($form->{status} eq 'orphaned') {
    $option .= $locale->text('Orphaned');
  }
  if ($form->{name}) {
    $callback .= "&name=".$form->escape($form->{name},1);
    $href .= "&name=".$form->escape($form->{name});
    $option .= "\n<br>".$locale->text('Name')." : $form->{name}";
  }
  if ($form->{contact}) {
    $callback .= "&contact=".$form->escape($form->{contact},1);
    $href .= "&contact=".$form->escape($form->{contact});
    $option .= "\n<br>".$locale->text('Contact')." : $form->{contact}";
  }
  if ($form->{"$form->{db}number"}) {
    $callback .= qq|&$form->{db}number=|.$form->escape($form->{"$form->{db}number"},1);
    $href .= "&$form->{db}number=".$form->escape($form->{"$form->{db}number"});
    $option .= "\n<br>".$locale->text('Number').qq| : $form->{"$form->{db}number"}|;
  }
  if ($form->{email}) {
    $callback .= "&email=".$form->escape($form->{email},1);
    $href .= "&email=".$form->escape($form->{email});
    $option .= "\n<br>".$locale->text('E-mail')." : $form->{email}";
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
    if ($form->{transdatefrom}) {
      $option .= " ";
    } else {
      $option .= "\n<br>" if ($option);
    }
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{transdateto}, 1);
  }
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
  

  $form->{callback} = "$callback&sort=$form->{sort}";
  $callback = $form->escape($form->{callback});
  
  $column_header{id} = qq|<th class=listheading>|.$locale->text('ID').qq|</th>|;
  $column_header{"$form->{db}number"} = qq|<th><a class=listheading href=$href&sort=$form->{db}number>|.$locale->text('Number').qq|</a></th>|;
  $column_header{name} = qq|<th><a class=listheading href=$href&sort=name>|.$locale->text('Name').qq|</a></th>|;
  $column_header{address} = qq|<th class=listheading>|.$locale->text('Address').qq|</th>|;
  $column_header{city} = qq|<th><a class=listheading href=$href&sort=city>|.$locale->text('City').qq|</a></th>|;
  $column_header{state} = qq|<th><a class=listheading href=$href&sort=state>|.$locale->text('State/Province').qq|</a></th>|;
  $column_header{zipcode} = qq|<th><a class=listheading href=$href&sort=zipcode>|.$locale->text('ZIP/Code').qq|</a></th>|;
  $column_header{country} = qq|<th><a class=listheading href=$href&sort=country>|.$locale->text('Country').qq|</a></th>|;
  $column_header{contact} = qq|<th><a class=listheading href=$href&sort=contact>|.$locale->text('Contact').qq|</a></th>|;
  $column_header{phone} = qq|<th><a class=listheading href=$href&sort=phone>|.$locale->text('Phone').qq|</a></th>|;
  $column_header{fax} = qq|<th><a class=listheading href=$href&sort=fax>|.$locale->text('Fax').qq|</a></th>|;
  $column_header{email} = qq|<th><a class=listheading href=$href&sort=email>|.$locale->text('E-mail').qq|</a></th>|;
  $column_header{cc} = qq|<th><a class=listheading href=$href&sort=cc>|.$locale->text('Cc').qq|</a></th>|;
  $column_header{bcc} = qq|<th><a class=listheading href=$href&sort=cc>|.$locale->text('Bcc').qq|</a></th>|;
  $column_header{notes} = qq|<th><a class=listheading href=$href&sort=notes>|.$locale->text('Notes').qq|</a></th>|;
  
  $column_header{taxnumber} = qq|<th><a class=listheading href=$href&sort=taxnumber>|.$locale->text('Tax Number').qq|</a></th>|;
  $column_header{gifi_accno} = qq|<th><a class=listheading href=$href&sort=gifi_accno>|.$locale->text('GIFI').qq|</a></th>|;
  $column_header{sic_code} = qq|<th><a class=listheading href=$href&sort=sic_code>|.$locale->text('SIC').qq|</a></th>|;
  $column_header{business} = qq|<th><a class=listheading href=$href&sort=business>|.$locale->text('Type of Business').qq|</a></th>|;
  $column_header{iban} = qq|<th class=listheading>|.$locale->text('IBAN').qq|</th>|;
  $column_header{bic} = qq|<th class=listheading>|.$locale->text('BIC').qq|</th>|;
  
  $column_header{invnumber} = qq|<th><a class=listheading href=$href&sort=invnumber>|.$locale->text('Invoice').qq|</a></th>|;
  $column_header{ordnumber} = qq|<th><a class=listheading href=$href&sort=ordnumber>|.$locale->text('Order').qq|</a></th>|;
  $column_header{quonumber} = qq|<th><a class=listheading href=$href&sort=quonumber>|.$locale->text('Quotation').qq|</a></th>|;

  if ($form->{db} eq 'customer') {
    $column_header{employee} = qq|<th><a class=listheading href=$href&sort=employee>|.$locale->text('Salesperson').qq|</a></th>|;
  } else {
    $column_header{employee} = qq|<th><a class=listheading href=$href&sort=employee>|.$locale->text('Employee').qq|</a></th>|;
  }
  $column_header{manager} = qq|<th><a class=listheading href=$href&sort=manager>|.$locale->text('Manager').qq|</a></th>|;

  $column_header{pricegroup} = qq|<th><a class=listheading href=$href&sort=pricegroup>|.$locale->text('Pricegroup').qq|</a></th>|;
  $column_header{language} = qq|<th><a class=listheading href=$href&sort=language>|.$locale->text('Language').qq|</a></th>|;
  

  $amount = $locale->text('Amount');
  $tax = $locale->text('Tax');
  $total = $locale->text('Total');
  
  $column_header{invamount} = qq|<th class=listheading>$amount</th>|;
  $column_header{ordamount} = qq|<th class=listheading>$amount</th>|;
  $column_header{quoamount} = qq|<th class=listheading>$amount</th>|;
  
  $column_header{invtax} = qq|<th class=listheading>$tax</th>|;
  $column_header{ordtax} = qq|<th class=listheading>$tax</th>|;
  $column_header{quotax} = qq|<th class=listheading>$tax</th>|;
  
  $column_header{invtotal} = qq|<th class=listheading>$total</th>|;
  $column_header{ordtotal} = qq|<th class=listheading>$total</th>|;
  $column_header{quototal} = qq|<th class=listheading>$total</th>|;
 

  if ($form->{status}) {
    $label = ucfirst $form->{db}."s";
    $form->{title} = $locale->text($label);
  } else {
    $label = ucfirst $form->{db};
    $form->{title} = $locale->text($label ." Transactions");
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
	<tr class=listheading>
|;

  map { print "$column_header{$_}\n" } @column_index;

  print qq|
        </tr>
|;

  $ordertype = ($form->{db} eq 'customer') ? 'sales_order' : 'purchase_order';
  $quotationtype = ($form->{db} eq 'customer') ? 'sales_quotation' : 'request_quotation';
  $subtotal = 0;

  foreach $ref (@{ $form->{CT} }) {

    if ($ref->{$form->{sort}} ne $sameitem && $form->{l_subtotal}) {
      # print subtotal
      if ($subtotal) {
	map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
	&list_subtotal;
      }
    }

    if ($ref->{$form->{sort}} eq $sameitem && $form->{sort} eq 'name') {
      map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
    } else {
      
      map { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" } @column_index;
      $column_data{$form->{sort}} = "<td>&nbsp;</td>" if $ref->{$form->{sort}} eq $sameitem && $form->{l_subtotal};
      
      $column_data{address} = "<td>$ref->{address1} $ref->{address2}&nbsp;</td>";
      $column_data{name} = "<td><a href=$form->{script}?action=edit&id=$ref->{id}&db=$form->{db}&path=$form->{path}&login=$form->{login}&password=$form->{password}&status=$form->{status}&callback=$callback>$ref->{name}&nbsp;</td>";

      $email = "";
      if ($form->{sort} =~ /(email|cc)/) {
	if ($ref->{$form->{sort}} ne $sameitem) {
	  $email = 1;
	}
      } else {
	$email = 1;
      }
      
      if ($email) {
      foreach $item (qw(email cc bcc)) {
	if ($ref->{$item}) {
	  $email = $ref->{$item};
	  $email =~ s/</\&lt;/;
	  $email =~ s/>/\&gt;/;
	  
	  $column_data{$item} = qq|<td><a href="mailto:$ref->{$item}">$email</a></td>|;
	}
      }
      }
    }
    
    if ($ref->{formtype} eq 'invoice') {
      $column_data{invnumber} = "<td><a href=$ref->{module}.pl?action=edit&id=$ref->{invid}&path=$form->{path}&login=$form->{login}&password=$form->{password}&callback=$callback>$ref->{invnumber}&nbsp;</td>";
      
      $column_data{invamount} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{netamount}, 2, "&nbsp;")."</td>";
      $column_data{invtax} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount} - $ref->{netamount}, 2, "&nbsp;")."</td>";
      $column_data{invtotal} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount}, 2, "&nbsp;")."</td>";

      $invamountsubtotal += $ref->{netamount};
      $invtaxsubtotal += ($ref->{amount} - $ref->{netamount});
      $invtotalsubtotal += $ref->{amount};
    }
     
    if ($ref->{formtype} eq 'order') {
      $column_data{ordnumber} = "<td><a href=$ref->{module}.pl?action=edit&id=$ref->{invid}&type=$ordertype&path=$form->{path}&login=$form->{login}&password=$form->{password}&callback=$callback>$ref->{ordnumber}&nbsp;</td>";
      
      $column_data{ordamount} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{netamount}, 2, "&nbsp;")."</td>";
      $column_data{ordtax} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount} - $ref->{netamount}, 2, "&nbsp;")."</td>";
      $column_data{ordtotal} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount}, 2, "&nbsp;")."</td>";

      $ordamountsubtotal += $ref->{netamount};
      $ordtaxsubtotal += ($ref->{amount} - $ref->{netamount});
      $ordtotalsubtotal += $ref->{amount};
    }

    if ($ref->{formtype} eq 'quotation') {
      $column_data{quonumber} = "<td><a href=$ref->{module}.pl?action=edit&id=$ref->{invid}&type=$quotationtype&path=$form->{path}&login=$form->{login}&password=$form->{password}&callback=$callback>$ref->{quonumber}&nbsp;</td>";
      
      $column_data{quoamount} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{netamount}, 2, "&nbsp;")."</td>";
      $column_data{quotax} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount} - $ref->{netamount}, 2, "&nbsp;")."</td>";
      $column_data{quototal} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount}, 2, "&nbsp;")."</td>";

      $quoamountsubtotal += $ref->{netamount};
      $quotaxsubtotal += ($ref->{amount} - $ref->{netamount});
      $quototalsubtotal += $ref->{amount};
    }
    
   
    $i++; $i %= 2;
    print "
        <tr class=listrow$i>
";

    map { print "$column_data{$_}\n" } @column_index;

    print qq|
        </tr>
|;
    
    $sameitem = $ref->{$form->{sort}};
    $subtotal = 1;

  }

  if ($form->{l_subtotal}) {
    map { $column_data{$_} = "<td>&nbsp;</td>" } @column_index;
    &list_subtotal;
  }
  
  $i = 1;
  if ($myconfig{acs} !~ /AR--AR/) {
    if ($form->{db} eq 'customer') {
      $button{'AR--Customers-Add Customer'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Customer').qq|"> |;
      $button{'AR--Customers--Add Customer'}{order} = $i++;
    }
  }
  if ($myconfig{acs} !~ /AP--AP/) {
    if ($form->{db} eq 'vendor') {
      $button{'AP--Vendors--Add Vendor'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Add Vendor').qq|"> |;
      $button{'AP--Vendors--Add Vendor'}{order} = $i++;
    }
  }
  
  foreach $item (split /;/, $myconfig{acs}) {
    delete $button{$item};
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
<input name=db type=hidden value=$form->{db}>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=password value=$form->{password}>
|;

  if ($form->{status}) {
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


sub list_subtotal {

	$column_data{invamount} = "<td align=right>".$form->format_amount(\%myconfig, $invamountsubtotal, 2, "&nbsp;")."</td>";
	$column_data{invtax} = "<td align=right>".$form->format_amount(\%myconfig, $invtaxsubtotal, 2, "&nbsp;")."</td>";
	$column_data{invtotal} = "<td align=right>".$form->format_amount(\%myconfig, $invtotalsubtotal, 2, "&nbsp;")."</td>";

	$invamountsubtotal = 0;
	$invtaxsubtotal = 0;
	$invtotalsubtotal = 0;

	$column_data{ordamount} = "<td align=right>".$form->format_amount(\%myconfig, $ordamountsubtotal, 2, "&nbsp;")."</td>";
	$column_data{ordtax} = "<td align=right>".$form->format_amount(\%myconfig, $ordtaxsubtotal, 2, "&nbsp;")."</td>";
	$column_data{ordtotal} = "<td align=right>".$form->format_amount(\%myconfig, $ordtotalsubtotal, 2, "&nbsp;")."</td>";

	$ordamountsubtotal = 0;
	$ordtaxsubtotal = 0;
	$ordtotalsubtotal = 0;

	$column_data{quoamount} = "<td align=right>".$form->format_amount(\%myconfig, $quoamountsubtotal, 2, "&nbsp;")."</td>";
	$column_data{quotax} = "<td align=right>".$form->format_amount(\%myconfig, $quotaxsubtotal, 2, "&nbsp;")."</td>";
	$column_data{quototal} = "<td align=right>".$form->format_amount(\%myconfig, $quototalsubtotal, 2, "&nbsp;")."</td>";

	$quoamountsubtotal = 0;
	$quotaxsubtotal = 0;
	$quototalsubtotal = 0;
	
	print "
        <tr class=listsubtotal>
";
	map { print "$column_data{$_}\n" } @column_index;

	print qq|
        </tr>
|;
 

}


sub list_history {
  
  CT->get_history(\%myconfig, \%$form);
  
  $href = "$form->{script}?action=list_history&direction=$form->{direction}&oldsort=$form->{oldsort}&db=$form->{db}&path=$form->{path}&login=$form->{login}&password=$form->{password}&type=$form->{type}&transdatefrom=$form->{transdatefrom}&transdateto=$form->{transdateto}&history=$form->{history}";

  $form->sort_order();
  
  $callback = "$form->{script}?action=list_history&direction=$form->{direction}&oldsort=$form->{oldsort}&db=$form->{db}&path=$form->{path}&login=$form->{login}&password=$form->{password}&type=$form->{type}&transdatefrom=$form->{transdatefrom}&transdateto=$form->{transdateto}&history=$form->{history}";
  
  $form->{l_fxsellprice} = $form->{l_curr};
  @columns = $form->sort_columns(partnumber, description, qty, unit, sellprice, fxsellprice, curr, discount, deliverydate, projectnumber, serialnumber);

  if ($form->{history} eq 'summary') {
    @columns = $form->sort_columns(partnumber, description, qty, unit, sellprice, curr);
  }

  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;

      # add column to href and callback
      $callback .= "&l_$item=Y";
      $href .= "&l_$item=Y";
    }
  }
  
  if ($form->{history} eq 'detail') {
    $option = $locale->text('Detail');
  }
  if ($form->{history} eq 'summary') {
    $option .= $locale->text('Summary');
  }
  if ($form->{name}) {
    $callback .= "&name=".$form->escape($form->{name},1);
    $href .= "&name=".$form->escape($form->{name});
    $option .= "\n<br>".$locale->text('Name')." : $form->{name}";
  }
  if ($form->{contact}) {
    $callback .= "&contact=".$form->escape($form->{contact},1);
    $href .= "&contact=".$form->escape($form->{contact});
    $option .= "\n<br>".$locale->text('Contact')." : $form->{contact}";
  }
  if ($form->{"$form->{db}number"}) {
    $callback .= qq|&$form->{db}number=|.$form->escape($form->{"$form->{db}number"},1);
    $href .= "&$form->{db}number=".$form->escape($form->{"$form->{db}number"});
    $option .= "\n<br>".$locale->text('Number').qq| : $form->{"$form->{db}number"}|;
  }
  if ($form->{email}) {
    $callback .= "&email=".$form->escape($form->{email},1);
    $href .= "&email=".$form->escape($form->{email});
    $option .= "\n<br>".$locale->text('E-mail')." : $form->{email}";
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
    if ($form->{transdatefrom}) {
      $option .= " ";
    } else {
      $option .= "\n<br>" if ($option);
    }
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{transdateto}, 1);
  }
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


  $form->{callback} = "$callback&sort=$form->{sort}";
  $callback = $form->escape($form->{callback});

  $column_header{partnumber} = qq|<th><a class=listheading href=$href&sort=partnumber>|.$locale->text('Part Number').qq|</a></th>|;
  $column_header{description} = qq|<th><a class=listheading href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;

  if ($form->{history} eq 'summary') {
    $column_header{sellprice} = qq|<th class=listheading>|.$locale->text('Total').qq|</th>|;
  } else {
    $column_header{sellprice} = qq|<th class=listheading>|.$locale->text('Price').qq|</th>|;
  }
  $column_header{fxsellprice} = qq|<th>&nbsp;</th>|;
  
  $column_header{curr} = qq|<th class=listheading>|.$locale->text('Curr').qq|</th>|;
  $column_header{discount} = qq|<th class=listheading>|.$locale->text('Disc').qq|</th>|;
  $column_header{qty} = qq|<th class=listheading>|.$locale->text('Qty').qq|</th>|;
  $column_header{unit} = qq|<th class=listheading>|.$locale->text('Unit').qq|</th>|;
  $column_header{deliverydate} = qq|<th><a class=listheading href=$href&sort=deliverydate>|.$locale->text('Delivery Date').qq|</a></th>|;
  $column_header{projectnumber} = qq|<th><a class=listheading href=$href&sort=projectnumber>|.$locale->text('Project Number').qq|</a></th>|;
  $column_header{serialnumber} = qq|<th><a class=listheading href=$href&sort=serialnumber>|.$locale->text('Serial Number').qq|</a></th>|;
  

# $locale->text('Customer History')
# $locale->text('Vendor History')

  $label = ucfirst $form->{db};
  $form->{title} = $locale->text($label." History");

  $colspan = $#column_index + 1;

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

  print qq|
        </tr>
|;


  $module = 'oe';
  if ($form->{db} eq 'customer') {
    $invlabel = $locale->text('Sales Invoice');
    $ordlabel = $locale->text('Sales Order');
    $quolabel = $locale->text('Quotation');
    
    $ordertype = 'sales_order';
    $quotationtype = 'sales_quotation';
    if ($form->{type} eq 'invoice') {
      $module = 'is';
    }
  } else {
    $invlabel = $locale->text('Vendor Invoice');
    $ordlabel = $locale->text('Purchase Order');
    $quolabel = $locale->text('RFQ');
    
    $ordertype = 'purchase_order';
    $quotationtype = 'request_quotation';
    if ($form->{type} eq 'invoice') {
      $module = 'ir';
    }
  }
    
  
  foreach $ref (@{ $form->{CT} }) {

    if ($ref->{id} ne $sameid) {
      # print the header
      print qq|
        <tr class=listheading>
	  <th colspan=$colspan><a class=listheading href=$form->{script}?action=edit&id=$ref->{ctid}&db=$form->{db}&path=$form->{path}&login=$form->{login}&password=$form->{password}&callback=$callback>$ref->{name} $ref->{address}</a></th>
	</tr>
|;
    }

    if ($form->{type} ne 'invoice') {
      $ref->{fxsellprice} = $ref->{sellprice};
      $ref->{sellprice} *= $ref->{exchangerate};
    }
	
    if ($form->{history} eq 'detail' and $ref->{invid} ne $sameinvid) {
      # print inv, ord, quo number
      $i++; $i %= 2;
      
      print qq|
	  <tr class=listrow$i>
|;

      if ($form->{type} eq 'invoice') {
	print qq|<th align=left colspan=$colspan><a href=${module}.pl?action=edit&id=$ref->{invid}&path=$form->{path}&login=$form->{login}&password=$form->{password}&callback=$callback>$invlabel $ref->{invnumber} / $ref->{employee}</a></th>|;
      }
       
      if ($form->{type} eq 'order') {
	print qq|<th align=left colspan=$colspan><a href=${module}.pl?action=edit&id=$ref->{invid}&type=$ordertype&path=$form->{path}&login=$form->{login}&password=$form->{password}&callback=$callback>$ordlabel $ref->{ordnumber} / $ref->{employee}</a></th>|;
      }

      if ($form->{type} eq 'quotation') {
	print qq|<th align=left colspan=$colspan><a href=${module}.pl?action=edit&id=$ref->{invid}&type=$quotationtype&path=$form->{path}&login=$form->{login}&password=$form->{password}&callback=$callback>$quolabel $ref->{quonumber} / $ref->{employee}</a></th>|;
      }

      print qq|
          </tr>
|;
    }

    map { $column_data{$_} = "<td>$ref->{$_}&nbsp;</td>" } @column_index;

    if ($form->{l_curr}) {
      $column_data{fxsellprice} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{fxsellprice}, 2)."</td>";
    }
    $column_data{sellprice} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{sellprice}, 2)."</td>";
      
    $column_data{qty} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{qty})."</td>";
    $column_data{discount} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{discount} * 100, "", "&nbsp;")."</td>";
    $column_data{partnumber} = qq|<td><a href=ic.pl?action=edit&id=$ref->{pid}&path=$form->{path}&login=$form->{login}&password=$form->{password}&callback=$callback>$ref->{partnumber}</td>|;
    
   
    $i++; $i %= 2;
    print qq|
        <tr class=listrow$i>
|;

    map { print "$column_data{$_}\n" } @column_index;

    print qq|
        </tr>
|;
    
    $sameid = $ref->{id};
    $sameinvid = $ref->{invid};

  }

 
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

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



sub edit {

# $locale->text('Edit Customer')
# $locale->text('Edit Vendor')

  CT->create_links(\%myconfig, \%$form);

  map { $form->{$_} = $form->quote($form->{$_}) } keys %$form;

  $form->{title} = "Edit";

  # format discount
  $form->{discount} *= 100;
  
  &form_header;
  &form_footer;

}


sub form_header {

  $form->{taxincluded} = ($form->{taxincluded}) ? "checked" : "";
  $form->{creditlimit} = $form->format_amount(\%myconfig, $form->{creditlimit}, 0);
  
  if ($myconfig{role} =~ /(admin|manager)/) {
    $bcc = qq|
        <tr>
	  <th align=right nowrap>|.$locale->text('Bcc').qq|</th>
	  <td><input name=bcc size=35 value="$form->{bcc}"></td>
	</tr>
|;
  }
  
  # currencies
  map { $form->{selectcurrency} .= "<option>$_\n" } split /:/, $form->{currencies};
  $form->{selectcurrency} =~ s/option>($form->{currency})/option selected>$1/;
  
  foreach $item (split / /, $form->{taxaccounts}) {
    if ($form->{tax}{$item}{taxable}) {
      $taxable .= qq| <input name="tax_$item" value=1 class=checkbox type=checkbox checked>&nbsp;<b>$form->{tax}{$item}{description}</b>|;
    } else {
      $taxable .= qq| <input name="tax_$item" value=1 class=checkbox type=checkbox>&nbsp;<b>$form->{tax}{$item}{description}</b>|;
    }
  }

  if ($taxable) {
    $tax = qq|
	<tr>
	  <th align=right>|.$locale->text('Taxable').qq|</th>
	  <td colspan=5>
	    <table>
	      <tr>
		<td>$taxable</td>
		<td><input name=taxincluded class=checkbox type=checkbox value=1 $form->{taxincluded}></td>
		<th align=left>|.$locale->text('Tax Included').qq|</th>
	      </tr>
	    </table>
	  </td>
	</tr>
|;
  }

  $typeofbusiness = qq|
          <th></th>
	  <td></td>
|;

  if (@{ $form->{all_business} }) {
    $form->{selectbusiness} = qq|<option>\n|;
    map { $form->{selectbusiness} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| } @{ $form->{all_business} };

    $form->{selectbusiness} =~ s/(<option value="\Q$form->{business}--$form->{business_id}\E")>/$1 selected>/;

    $typeofbusiness = qq|
 	  <th align=right>|.$locale->text('Type of Business').qq|</th>
	  <td><select name=business>$form->{selectbusiness}</select></td>
|;


  }

  $pricegroup = qq|
          <th></th>
	  <td></td>
|;

  if (@{ $form->{all_pricegroup} } && $form->{db} eq 'customer') {
    $form->{selectpricegroup} = qq|<option>\n|;
    map { $form->{selectpricegroup} .= qq|<option value="$_->{pricegroup}--$_->{id}">$_->{pricegroup}\n| } @{ $form->{all_pricegroup} };
    
    $form->{selectpricegroup} =~ s/(<option value="\Q$form->{pricegroup}--$form->{pricegroup_id}\E")/$1 selected/;

    $pricegroup = qq|
 	  <th align=right>|.$locale->text('Pricegroup').qq|</th>
	  <td><select name=pricegroup>$form->{selectpricegroup}</select></td>
|;
  }
  
  $lang = qq|
          <th></th>
	  <td></td>
|;

  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = qq|<option>\n|;
    map { $form->{selectlanguage} .= qq|<option value="$_->{description}--$_->{code}">$_->{description}\n| } @{ $form->{all_language} };
    
    $form->{selectlanguage} =~ s/(<option value="\Q$form->{language}--$form->{language_code}\E")/$1 selected/;

    $lang = qq|
 	  <th align=right>|.$locale->text('Language').qq|</th>
	  <td><select name=language>$form->{selectlanguage}</select></td>
|;
  }

 
  $employeelabel = $locale->text('Salesperson');
  
  $form->{selectemployee} = qq|<option>\n|;
  map { $form->{selectemployee} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| } @{ $form->{all_employee} };
  
  $form->{selectemployee} =~ s/(<option value="\Q$form->{employee}--$form->{employee_id}\E")/$1 selected/;
  
  if ($form->{db} eq 'vendor') {
    $gifi = qq|
    	  <th align=right>|.$locale->text('Sub-contract GIFI').qq|</th>
	  <td><input name=gifi_accno size=9 value="$form->{gifi_accno}"></td>
|;
    $employeelabel = $locale->text('Employee');
  }


  if (@{ $form->{all_employee} }) {
    $employee = qq|
	        <th align=right>$employeelabel</th>|;
		
    if ($myconfig{role} ne 'user' || !$form->{id}) {
      $employee .= qq|
		<td><select name=employee>$form->{selectemployee}</select></td>
|;
    } else {
      $employee .= qq|
                <td>$form->{employee}</td>|;
    }
  }


# $locale->text('Customer Number')
# $locale->text('Vendor Number')

  $label = ucfirst $form->{db};
  $form->{title} = $locale->text("$form->{title} $label");
 
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
        <tr valign=top>
	  <td width=50%>
	    <table width=100%>
	      <tr class=listheading>
		<th class=listheading colspan=2 width=50%>|.$locale->text('Billing Address').qq|</th>
	      <tr>
		<th align=right nowrap>|.$locale->text($label .' Number').qq|</th>
		<td><input name="$form->{db}number" size=35 maxlength=32 value="$form->{"$form->{db}number"}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Company Name').qq|</th>
		<td><input name=name size=35 maxlength=64 value="$form->{name}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Address').qq|</th>
		<td><input name=address1 size=35 maxlength=32 value="$form->{address1}"></td>
	      </tr>
	      <tr>
		<th></th>
		<td><input name=address2 size=35 maxlength=32 value="$form->{address2}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('City').qq|</th>
		<td><input name=city size=35 maxlength=32 value="$form->{city}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('State/Province').qq|</th>
		<td><input name=state size=35 maxlength=32 value="$form->{state}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('ZIP/Code').qq|</th>
		<td><input name=zipcode size=10 maxlength=10 value="$form->{zipcode}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Country').qq|</th>
		<td><input name=country size=35 maxlength=32 value="$form->{country}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Contact').qq|</th>
		<td><input name=contact size=35 maxlength=64 value="$form->{contact}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Phone').qq|</th>
		<td><input name=phone size=20 maxlength=20 value="$form->{phone}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Fax').qq|</th>
		<td><input name=fax size=20 maxlength=20 value="$form->{fax}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('E-mail').qq|</th>
		<td><input name=email size=35 value="$form->{email}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Cc').qq|</th>
		<td><input name=cc size=35 value="$form->{cc}"></td>
	      </tr>
	      $bcc
	    </table>
	  </td>
	  <td width=50%>
	    <table width=100%>
	      <tr>
		<th class=listheading colspan=2>|.$locale->text('Shipping Address').qq|</th>
	      </tr>
	      <tr>
		<td><input name=none size=35 value=|. ("=" x 35) .qq|></td>
	      </tr>
	      <tr>
		<td><input name=shiptoname size=35 maxlength=64 value="$form->{shiptoname}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptoaddress1 size=35 maxlength=32 value="$form->{shiptoaddress1}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptoaddress2 size=35 maxlength=32 value="$form->{shiptoaddress2}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptocity size=35 maxlength=32 value="$form->{shiptocity}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptostate size=35 maxlength=32 value="$form->{shiptostate}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptozipcode size=10 maxlength=10 value="$form->{shiptozipcode}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptocountry size=35 maxlength=32 value="$form->{shiptocountry}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptocontact size=35 maxlength=64 value="$form->{shiptocontact}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptophone size=20 maxlength=20 value="$form->{shiptophone}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptofax size=20 maxlength=20 value="$form->{shiptofax}"></td>
	      </tr>
	      <tr>
		<td><input name=shiptoemail size=35 value="$form->{shiptoemail}"></td>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table>
	$tax
	<tr>
	  <th align=right>|.$locale->text('Credit Limit').qq|</th>
	  <td><input name=creditlimit size=9 value="$form->{creditlimit}"></td>
	  <th align=right>|.$locale->text('Terms').qq|</th>
	  <td><input name=terms size=2 value="$form->{terms}"> <b>|.$locale->text('days').qq|</b></td>
	  <th align=right>|.$locale->text('Discount').qq|</th>
	  <td><input name=discount size=4 value="$form->{discount}">
	  <b>%</b></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('Tax Number / SSN').qq|</th>
	  <td><input name=taxnumber size=20 value="$form->{taxnumber}"></td>
	  $gifi
	  <th align=right>|.$locale->text('SIC').qq|</th>
	  <td><input name=sic size=6 maxlength=6 value="$form->{sic}"></td>
	</tr>
	<tr>
	  $typeofbusiness
	  <th align=right>|.$locale->text('BIC').qq|</th>
	  <td><input name=bic size=11 maxlength=11 value="$form->{bic}"></td>
	  <th align=right>|.$locale->text('IBAN').qq|</th>
	  <td><input name=iban size=24 maxlength=34 value="$form->{iban}"></td>
	</tr>
	<tr>
	  $pricegroup
	  $lang
	  <th>|.$locale->text('Currency').qq|</th>
	  <td><select name=currency>$form->{selectcurrency}</select></td>
	</tr>
	<tr valign=top>
	  $employee
    <td colspan=4>
      <table>
	<tr valign=top>
	  <th align=left nowrap>|.$locale->text('Notes').qq|</th>
	  <td><textarea name=notes rows=3 cols=40 wrap=soft>$form->{notes}</textarea></td>
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

}



sub form_footer {

  $i = 1;
  if ($form->{db} eq 'customer') {
    if ($myconfig{acs} !~ /AR--AR/) {
      $button{'AR--Add Transaction'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('AR Transaction').qq|"> |;
      $button{'AR--Add Transaction'}{order} = $i++;
      $button{'AR--Sales Invoice'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Sales Invoice').qq|"> |;
      $button{'AR--Sales Invoice'}{order} = $i++;
    }
    if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
      $button{'Order Entry--Sales Order'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Sales Order').qq|"> |;
      $button{'Order Entry--Sales Order'}{order} = $i++;
    }
    if ($myconfig{acs} !~ /Quotations--Quotations/) {
      $button{'Quotations--Quotation'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Quotation').qq|"> |;
      $button{'Quotations--Quotation'}{order} = $i++;
    }
  }
  if ($form->{db} eq 'vendor') {
    if ($myconfig{acs} !~ /AP--AP/) {
      $button{'AP--Add Transaction'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('AP Transaction').qq|"> |;
      $button{'AP--Add Transaction'}{order} = $i++;
      $button{'AP--Vendor Invoice'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Vendor Invoice').qq|"> |;
      $button{'AP--Vendor Invoice'}{order} = $i++;
    }
    if ($myconfig{acs} !~ /Order Entry--Order Entry/) {
      $button{'Order Entry--Purchase Order'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('Purchase Order').qq|"> |;
      $button{'Order Entry--Purchase Order'}{order} = $i++;
    }
    if ($myconfig{acs} !~ /Quotations--Quotations/) {
      $button{'Quotations--RFQ'}{code} = qq|<input class=submit type=submit name=action value="|.$locale->text('RFQ').qq|"> |;
      $button{'Quotations--RFQ'}{order} = $i++;
    }
  }
  
  foreach $item (split /;/, $myconfig{acs}) {
    delete $button{$item};
  }
 
  print qq|
<input name=id type=hidden value=$form->{id}>
<input name=taxaccounts type=hidden value="$form->{taxaccounts}">

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=password value=$form->{password}>

<input type=hidden name=callback value="$form->{callback}">
<input type=hidden name=db value=$form->{db}>

<br>
|;

  if ($form->{db} eq 'customer') {
    $item = 'AR--Customers--Add Customer';
  } 
  if ($form->{db} eq 'vendor') {
    $item = 'AP--Vendors--Add Vendor';
  } 
  
  if ($myconfig{acs} !~ /$item/) {
    print qq|
<input class=submit type=submit name=action value="|.$locale->text("Save").qq|">
|;
    if ($form->{id} && $form->{status} eq 'orphaned') {
      print qq|<input class=submit type=submit name=action value="|.$locale->text('Delete').qq|">\n|;
    }
  }

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


sub add_transaction {
  
  $form->isblank("name", $locale->text("Name missing!"));
  &{ "CT::save_$form->{db}" }("", \%myconfig, \%$form);
  
  $form->{callback} = $form->escape($form->{callback},1);
  $name = $form->escape($form->{name},1);

  $form->{callback} = "$form->{script}?login=$form->{login}&path=$form->{path}&password=$form->{password}&action=add&vc=$form->{db}&$form->{db}_id=$form->{id}&$form->{db}=$name&type=$form->{type}&callback=$form->{callback}";

  $form->redirect;
  
}

sub ap_transaction {

  $form->{script} = "ap.pl";
  &add_transaction;

}


sub ar_transaction {

  $form->{script} = "ar.pl";
  &add_transaction;

}


sub sales_invoice {

  $form->{script} = "is.pl";
  $form->{type} = "invoice";
  &add_transaction;
  
}


sub vendor_invoice {

  $form->{script} = "ir.pl";
  $form->{type} = "invoice";
  &add_transaction;
  
}


sub rfq {

  $form->{script} = "oe.pl";
  $form->{type} = "request_quotation";
  &add_transaction;

}


sub quotation {
  
  $form->{script} = "oe.pl";
  $form->{type} = "sales_quotation";
  &add_transaction;

}


sub sales_order {
  
  $form->{script} = "oe.pl";
  $form->{type} = "sales_order";
  &add_transaction;

}


sub purchase_order {

  $form->{script} = "oe.pl";
  $form->{type} = "purchase_order";
  &add_transaction;
  
}


sub save {

# $locale->text('Customer saved!')
# $locale->text('Vendor saved!')

  $msg = ucfirst $form->{db};
  $msg .= " saved!";
  
  $form->isblank("name", $locale->text("Name missing!"));
  &{ "CT::save_$form->{db}" }("", \%myconfig, \%$form);
  
  $form->redirect($locale->text($msg));
  
}


sub delete {

# $locale->text('Customer deleted!')
# $locale->text('Cannot delete customer!')
# $locale->text('Vendor deleted!')
# $locale->text('Cannot delete vendor!')

  CT->delete(\%myconfig, \%$form);
  
  $msg = ucfirst $form->{db};
  $msg .= " deleted!";
  $form->redirect($locale->text($msg));
  
  $msg = "Cannot delete $form->{db}";
  $form->error($locale->text($msg));

}


sub continue { &{ $form->{nextsub} } };

sub add_customer { &add };
sub add_vendor { &add };

