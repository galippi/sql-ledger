#=====================================================================
# SQL-Ledger Accounting
# Copyright (c) 2003
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#  Modified by Tavugyvitel Kft. (info@tavugyvitel.hu)
#
# Contributors: Steve Doerr <sdoerr907@everestkc.net>
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
#=====================================================================
#
# Hungarian Cash Module
#
#=====================================================================

use SL::GL;
use SL::CP;
1;
# end

sub rsprint_options {
$batchprint = 1;
&print_options;
}	
sub print_options {

	$form->{copies} = 1 unless $form->{copies};

	if (%{$form->{forms}}) {

		print qq|<select name="formname">
|;
		foreach $key (keys %{$form->{forms}}) {
			print qq|  <option value="$key--| . $locale->text($form->{forms}{$key}) . qq|"| .
				(($form->{suggested_form} eq $key) ? " selected" : "") .
				">" . $locale->text($form->{forms}{$key}) . qq|</option>
|;
			}
		print qq|  </select>
|;

		print qq|<select name="format">
  <option value="html"| .
			(($form->{format} eq "html") ? " selected" : "") .
			">" . $locale->text("HTML") . qq|</option>
|;
		if ($latex) {
			print qq|  <option value="postscript"| .
				(($form->{format} eq "postscript") ? " selected" : "") .
				">" . $locale->text("Postscript") . qq|</option>
|;
			print qq|  <option value="pdf"| .
				(($form->{format} eq "pdf") ? " selected" : "") .
				">" . $locale->text("PDF") . qq|</option>
|;
			}
		print qq|  </select>
|;

		print qq|<select name="media">
  <option value="screen"| .
			(($form->{media} eq "screen") ? " selected" : "") .
			">" . $locale->text("Screen") . qq|</option>
|;
		if ($latex) {
			if ($myconfig{printer}) {
				print qq|  <option value="printer"| .
					(($form->{media} eq "printer") ? " selected" : "") .
					">" . $locale->text("Printer") . qq|</option>
|;
			}
#			print qq|  <option value="queue"| .
#				(($form->{media} eq "queue") ? " selected" : "") .
#				">" . $locale->text("Queue") . qq|</option>
#|;
		}
		print qq|  </select>
|;

		if ($latex) {
			print $locale->text('Copies') . qq|
<input name="copies" size="2" value="$form->{copies}">
|;
		}

		if($form->{id}){
		 print qq|<input class="submit" type="submit" name="action" value="| .
			$locale->text('Print Voucher') . qq|">
		 |;
		}elsif($batchprint){
		 print qq|<input class="submit" type="submit" name="action" value="| .
			$locale->text('Print All') . qq|">
		 |;			
		}else{
		 print qq|<input class="submit" type="submit" name="action" value="| .
			$locale->text('Post and Print') . qq|">
		 |;
		}	
	}
}

sub post_and_print {
  $form->error($locale->text('Select postscript or PDF!')) if $form->{format} !~ /(postscript|pdf)/;
  $form->error($locale->text('Select a Printer!')) if $form->{media} eq 'screen';
  $form->isblank("source", $locale->text('Source missing!')) if $form->{selectregsource} eq "0";
  $post_and_print = 1;
  &post;
  $form->{taxincluded} = 0;
  if ($form->{AP}){
	for my $j (1..$form->{rowcount}-1) {  
		$form->{"amount_$j"} *=-1;
	}
  }
  $form->{"paid_$form->{rsprint}"} = $form->format_amount(\%myconfig,$form->{"paid_$form->{rsprint}"}) if $form->{rsprint};
  &print_voucher;
}	
	
sub print_voucher {
	(my $formname, my $hr_formname) = split (/--/, $form->{formname});

	if ($form->{script} eq "gl.pl"){
		GL->first_cash(\%myconfig, \%$form);
		$form->error($locale->text('No payment selected!')) if !$form->{rsprint} || ($form->{"credit_$form->{rsprint}"} && $form->{"debit_$form->{rsprint}"});
		$form->{datepaid} = $form->{transdate};
                $form->{check} = $form->{"credit_$form->{rsprint}"};
                $form->{receipt} = $form->{"debit_$form->{rsprint}"};
                $form->{partner} = $form->{notes};
		$form->{source} = $form->{reference};
		$form->{memo} = $form->{description};
	}else {
         $form->error($locale->text('No payment selected!')) if !$form->{rsprint} || !$form->{"paid_$form->{rsprint}"} || !$form->{"datepaid_$form->{rsprint}"};
	 if ($formname eq "cash_voucher") {
          if ($form->{script} eq "ap.pl" || $form->{script} eq "ir.pl"){
		$form->{check} = $form->{"paid_$form->{rsprint}"};
		$form->{datepaid} = $form->{"datepaid_$form->{rsprint}"};
		($form->{partner}) = split /--/, $form->{vendor};                
          }elsif($form->{script} eq "ar.pl" || $form->{script} eq "is.pl"){
		$form->{datepaid} = $form->{"datepaid_$form->{rsprint}"};
		$form->{receipt} = $form->{"paid_$form->{rsprint}"};
		($form->{partner}) = split /--/, $form->{customer};        
          }       
          $form->{memo} = $form->{"memo_$form->{rsprint}"};
          $form->{source} = $form->{"source_$form->{rsprint}"};

	  for my $j (1..$form->{rowcount}-1) {
            $form->{"vmemo_$j"} = $form->{"vmemo_$j"} ? $form->{"vmemo_$j"} : $form->{"vdescr_$j"} ;
	    push(@{ $form->{number} }, $j);
	    push(@{ $form->{vmemo} }, qq|$form->{"vmemo_$j"}|);
    	    if (!$form->{taxincluded}){
	     $form->{"amount_$j"} =$form->format_amount(\%myconfig, $form->round_amount($form->parse_amount (\%myconfig, $form->{"amount_$j"}) * (1 +$form->{"AP_base_$j"}),0));
	    }
	    push(@{ $form->{vamount} }, $form->{"amount_$j"});
	  }
	 } #cash voucher
        } # not gl

          $form->isblank("source",$locale->text('Source missing!'));
          $ntt =  new CP $myconfig{countrycode};
	  $ntt->init;
	  $form->{amount_text} = $ntt->num2text ($form->parse_amount (\%myconfig, $form->{receipt})
	                         + $form->parse_amount (\%myconfig, $form->{check}));
          $form->{fx_transaction} = $form->{"fx_transaction_$form->{rsprint}"};

          @a = qw (source datepaid receipt check amount_text partner memo);
     
	$form->{company} = $myconfig{company};
        $form->isblank("company",$locale->text('Company missing!'));
	$form->{address} = $myconfig{address};
	$form->{employee} = $myconfig{name};
	push @a, qw(company address employee);
	$form->format_string (@a);
	undef @{$form->{copy}};
	for $i (1 .. $form->{copies}) {
		push  @{$form->{copy}}, $i;
	}

	$form->{templates} = "$myconfig{templates}";
	$form->{IN} = "$formname";
	if ($form->{format} =~ /postscript|pdf/) {
		$form->{IN} .= ".tex";
	}
	elsif ($form->{format} eq 'html') {
		$form->{IN} .= ".html";
	}
	if ($form->{media} eq 'printer') {
		$form->{OUT} = "| $myconfig{printer}";
	}

	$form->parse_template (\%myconfig, $userspath);
	$form->redirect if ($post_and_print || $form->{media} ne "screen");

}
sub print_all {
	my $j = 1;
	while ($form->{"datepaid_$j"}) {
		$checked++ if $form->{"printcheck_$j"};
		$j++;
		next;
	}
	$form->error($locale->text('Nothing selected!')) if !$checked;
	my $i = 1;
	(my $formname, my $hr_formname) = split (/--/, $form->{formname});
	$copies = $form->{copies};
	while ($form->{"datepaid_$i"}) {
	 if (!$form->{"printcheck_$i"}){
	  $i++;
          next;
	 }	
	 map { $form->{$_} = $form->{"${_}_$i"} } qw(source datepaid receipt check partner memo);
         $ntt =  new CP $myconfig{countrycode};
	 $ntt->init;
	 $form->{amount_text} = $ntt->num2text ($form->parse_amount (\%myconfig, $form->{receipt})
	                         + $form->parse_amount (\%myconfig, $form->{check}));

         @a = qw (source datepaid receipt check amount_text partner memo);
     
	 $form->{company} = $myconfig{company};
	 $form->{address} = $myconfig{address};
	 $form->{employee} = $myconfig{name};
	 my $v = 1;
	 foreach my $vitem (split /::/, $form->{"vmemo_$i"}){
	    push(@{ $form->{number} }, $v);
	    push(@{ $form->{vmemo} }, qq|$vitem|) if $vitem;
	    push @a, $vitem;
	    $v++;
	 }
	 $v = 1;
	 @vtaxbases = split /::/, $form->{"taxbase_$i"};
	 foreach my $aitem (split /::/, $form->{"vamount_$i"}){
    	    push(@{ $form->{vamount} }, $form->format_amount(\%myconfig, $form->round_amount($aitem * (1 + $vtaxbases[$v-1]),0))) if $aitem;
	    $v++;
	 }
	 
	 push @a, qw(company address employee);
	 $form->{copies} = $copies;
	 $form->format_string (@a);
	 undef @{$form->{copy}};
	 for $i (1 .. $form->{copies}) {
		push  @{$form->{copy}}, $i;
	 }
	 $form->{templates} = "$myconfig{templates}";
	 $form->{IN} = "$formname";
	 if ($form->{format} =~ /postscript|pdf/) {
		$form->{IN} .= ".tex";
	 }
	 elsif ($form->{format} eq 'html') {
		$form->{IN} .= ".html";
		#page break
		print qq|<p class="pb"></p>\n| if ($form->{media} eq "screen" && $printhtml==3);
		$printhtml++;
	 }
	 if ($form->{media} eq 'printer') {
		$form->{OUT} = "| $myconfig{printer}";
	 }
	 $form->parse_template (\%myconfig, $userspath);
         $i++;
	 next;
	}
	$form->redirect if $form->{media} ne "screen";
}	
sub recount {
	my $i = 1;
	my $dbh = $form->dbconnect_noauto(\%myconfig);
	(my $regaccount) = split /--/, $form->{account};
        $form->isblank("recountval",$locale->text("Starting Number missing!"));
	my $recountval = $form->{recountval};
	my $regcheck = $form->{db} eq "ar" ? "f" : "t";
	my $query = qq|SELECT code FROM regnum WHERE chart_id =
		      (SELECT id FROM chart WHERE accno = '$regaccount') AND
		       regcheck = '$regcheck'|; 

        my $sth = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);
	(my $regcode) = $sth->fetchrow_array;
        $sth->finish;

	while ($form->{"datepaid_$i"}) {
	   if (!$form->{"printcheck_$i"}){
	     $i++;
             next;
	   }
           if ($form->{"db_$i"} eq "gl"){
	     $query = "UPDATE gl SET reference = '$regcode' || '$recountval'
			  WHERE id = " . $form->{"id_$i"}; 
	     $dbh->do($query) || $form->dberror($query);	   
	     $query = "UPDATE acc_trans SET source = '$regcode' || '$recountval'
		       WHERE trans_id = " . $form->{"id_$i"};
	     $dbh->do($query) || $form->dberror($query);
	   }else{
	    if ($form->{onlygl}){
	     $query = qq|UPDATE acc_trans SET source = (SELECT invnumber FROM $form->{"db_$i"} WHERE id=$form->{"id_$i"}) 
		       WHERE trans_id = $form->{"id_$i"} 
		       AND chart_id = (SELECT id FROM chart WHERE accno = '$regaccount')|;
             $recountval--;
            }else{
	     $query = "UPDATE acc_trans SET source = '$regcode' || '$recountval'
		       WHERE trans_id = " . $form->{"id_$i"} .
		     " AND chart_id = (SELECT id FROM chart WHERE accno = '$regaccount')";
	    }
	     $dbh->do($query) || $form->dberror($query);	   
	   }
	   $updatedregnum = 1 if !$updatedregnum;
	   $i++;
	   $recountval++;
	   next;
	}
	if ($updatedregnum){
	     $query = "UPDATE regnum SET number = '$recountval'
		       WHERE code = '$regcode'
		       AND chart_id = (SELECT id FROM chart WHERE accno = '$regaccount')";
	     $dbh->do($query) || $form->dberror($query);	
	}	
	$dbh->commit;
	$dbh->disconnect;
	$form->redirect;
}
