######################################################################
# SQL-Ledger Accounting
# Copyright (c) 2000
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
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
######################################################################
#
# login frontend
#
#######################################################################


use DBI;
use SL::User;
use SL::Form;


$form = new Form;

$locale = new Locale $language, "login";

# customization
if (-f "$form->{path}/custom_$form->{script}") {
  eval { require "$form->{path}/custom_$form->{script}"; };
  $form->error($@) if ($@);
}

# per login customization
if (-f "$form->{path}/$form->{login}_$form->{script}") {
  eval { require "$form->{path}/$form->{login}_$form->{script}"; };
  $form->error($@) if ($@);
}

# window title bar, user info
$form->{titlebar} = "SQL-Ledger ".$locale->text('Version'). " $form->{version}";

if ($form->{action}) {
  $form->{titlebar} .= " - $myconfig{name} - $myconfig{dbname}";
  &{ $locale->findsub($form->{action}) };
} else {
  &login_screen;
}


1;


sub login_screen {
  
  if (-f "css/sql-ledger.css") {
    $form->{stylesheet} = "sql-ledger.css";
  }

  $form->header;

  print qq|
<body class=login>

<pre>

</pre>

<center>
<table class=login border=3 cellpadding=20>
  <tr>
    <td class=login align=center><a href="http://www.sql-ledger.org" target=_top><img src=sql-ledger.gif border=0></a>
<h1 class=login align=center>|.$locale->text('Version').qq| $form->{version}
</h1>

<p>

<form method=post action=$form->{script}>

      <table width=100%>
	<tr>
	  <td align=center>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Name').qq|</th>
		<td><input class=login name=login size=30></td>
	      </tr> 
	      <tr>
		<th align=right>|.$locale->text('Password').qq|</th>
		<td><input class=login type=password name=password size=30></td>
	      </tr>
	      <input type=hidden name=path value=$form->{path}>
	    </table>

	    <br>
	    <input type=submit name=action value="|.$locale->text('Login').qq|">
	  </td>
	</tr>
      </table>

</form>

    </td>
  </tr>
</table>
  
</body>
</html>
|;

}


sub selectdataset {
  my ($login) = @_;
  
  if (-f "css/sql-ledger.css") {
    $form->{stylesheet} = "sql-ledger.css";
  }

  $form->header;

  print qq|
<body class=login>

<pre>

</pre>

<center>
<table class=login border=3 cellpadding=20>
  <tr>
    <td class=login align=center><a href="http://www.sql-ledger.org" target=_top><img src=sql-ledger.gif border=0></a>
<h1 class=login align=center>|.$locale->text('Version').qq| $form->{version}
</h1>

<p>

<form method=post action=$form->{script}>

<input type=hidden name=beenthere value=1>

      <table width=100%>
	<tr>
	  <td align=center>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Name').qq|</th>
		<td>$form->{login}</td>
	      </tr> 
	      <tr>
		<th align=right>|.$locale->text('Password').qq|</th>
		<td><input class=login type=password name=password size=30 value=$form->{password}></td>
	      </tr>
	      <input type=hidden name=path value=$form->{path}>
	      <tr>
		<th align=right>|.$locale->text('Company').qq|</th>
		<td>|;
		
		$checked = "checked";
		foreach $login (sort { $login{$a} cmp $login{$b} } keys %{ $login }) {
		  print qq|
		  <br><input class=login type=radio name=login value=$login $checked>$login{$login}
		  |;
		  $checked = "";
		}

		print qq|
		  </td>
	      </tr>
	    </table>
	    <br>
	    <input type=submit name=action value="|.$locale->text('Login').qq|">
	  </td>
	</tr>
      </table>

</form>

    </td>
  </tr>
</table>
  
</body>
</html>
|;


}


sub login {

  $form->error($locale->text('You did not enter a name!')) unless ($form->{login});

  if (! $form->{beenthere}) {
    open(FH, "$memberfile") or $form->error("$memberfile : $!");
    @a = <FH>;
    close(FH);

    @login = grep { s/\[(.*)\]/$1/ } @a;
    @company = grep { s/company=(.*)/$1/ } @a;
    shift @login;

    for ($i = 0; $i <= $#login; $i++) {
      chop $login[$i];
      if (($form->{login} eq $login[$i]) || ($login[$i] =~ /$form->{login}@/)) {
	chop $company[$i];
	$login{$login[$i]} = $company[$i];
      }
    }

    if (keys %login > 1) {
      &selectdataset(\%login);
      exit;
    }
  }

  $user = new User $memberfile, $form->{login};

  # if we get an error back, bale out
  if (($errno = $user->login(\%$form, $userspath)) <= -1) {
    $errno *= -1;
    $err[1] = $locale->text('Incorrect Password!');
    $err[2] = $locale->text('Incorrect Dataset version!');
    $err[3] = qq|$form->{login} |.$locale->text('is not a member!');
    $err[4] = $locale->text('Dataset is newer than version!');
    
    if ($errno == 5) {
      # upgrade dataset and log in again
      open FH, ">$userspath/nologin" or $form->error($!);

      map { $form->{$_} = $user->{$_} } qw(dbname dbhost dbport dbdriver dbuser dbpasswd);

      $form->{dbpasswd} = unpack 'u', $form->{dbpasswd};
      
      $form->{dbupdate} = "db$user->{dbname}";
      $form->{$form->{dbupdate}} = 1;

      $form->header;
      print $locale->text('Upgrading to Version')." $form->{version} ... ";

      # required for Oracle
      $form->{dbdefault} = $sid;

      $user->dbupdate(\%$form);

      # remove lock file
      unlink "$userspath/nologin";

      print $locale->text('done');

      print "<p><a href=menu.pl?login=$form->{login}&password=$form->{password}&path=$form->{path}&action=display>".$locale->text('Continue')."</a>";

      exit;
    }

    $form->error($err[$errno]);
  }
  
  # made it this far, execute the menu
  $form->{callback} = "menu.pl?login=$form->{login}&password=$form->{password}&path=$form->{path}&action=display";

  $form->redirect;
  
}



sub logout {

  unlink "$userspath/$form->{login}.conf";
  
  # remove the callback to display the message
  $form->{callback} = "login.pl?path=$form->{path}&action=&login=";
  $form->redirect($locale->text('You are logged out!'));

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

  print qq|
<body>

<pre>

</pre>
<center>
<a href="http://www.sql-ledger.org" target=_top><img src=sql-ledger.gif border=0></a>
<h1 class=login>|.$locale->text('Version').qq| $form->{version}</h1>

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



