######################################################################
# SQL-Ledger Accounting
# Copyright (c) 2000
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
$form->{titlebar} = "Ledger ".$locale->text('Open source accounting software');

if ($form->{action}) {
  $form->{titlebar} .= " - $myconfig{name} - $myconfig{dbname}";
  &{ $locale->findsub($form->{action}) };
} else {
  $form->{charset} = "ISO-8859-2";
  &login_screen;
}


1;


sub login_screen {
  
  if (-f "css/ledger.css") {
    $form->{stylesheet} = "ledger.css";
  }

  if ($form->{login}) {
   $sf = qq|function sf() { document.login.password.focus(); }|;
  } else {
   $sf = qq|function sf() { document.login.login.focus(); }|;
  }

  $form->{endsession} = 1;
  $form->header(1);

  print qq|
<script language="JavaScript" type="text/javascript">
<!--
var agt = navigator.userAgent.toLowerCase();
var is_major = parseInt(navigator.appVersion);
var is_nav = ((agt.indexOf('mozilla') != -1) && (agt.indexOf('spoofer') == -1)
           && (agt.indexOf('compatible') == -1) && (agt.indexOf('opera') == -1)
	   && (agt.indexOf('webtv') == -1));
var is_nav4lo = (is_nav && (is_major <= 4));

function jsp() {
  if (is_nav4lo)
    document.login.js.value = "0"
  else
    document.login.js.value = "1"

}
$sf
// End -->
</script>
|;


#kabai
  print qq|
<body class=login onload="jsp(); sf()">
<script src="js/prototype.js" type="text/javascript"></script>
<script src="js/validation.js" type="text/javascript"></script>
<script src="js/custom.js" type="text/javascript"></script>
<pre>

</pre>

<center>
<table border=2 cellpadding=20>
  <tr>
    <td class=login align=center><a href="http://www.tavugyvitel.hu" target=_top><img src=icons/ledger_logo.gif border=0></a>
<form method=post action=$form->{script} name=login>

      <table width=100%>
	<tr>
	  <td align=center>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Name').qq|</th>
		<td><input class="required" name=login></td>
	      </tr> 
	      <tr>
		<th align=right>|.$locale->text('Password').qq|</th>
		<td><input type=password name=password></td>
	      </tr>
	      <input type=hidden name=path value=$form->{path}>
	      <input type=hidden name=js value=$form->{js}>
	    </table>

	    <br>
	      |.$locale->text('Dynamic pages').qq|<input type=checkbox class=checkbox name=cjs checked>
	    <br><br>
	    <input type=submit name=action onclick="return checkform();" value="|.$locale->text('Login').qq|">

	  </td>
	</tr>
      </table>

</form>
    </td>
  </tr>
</table>
 |.$locale->text('Open source accounting software').qq|&nbsp;&nbsp;&nbsp;<a href="http://www.tavugyvitel.hu">http://www.tavugyvitel.hu</a>  
</body>
</html>
|;
}


sub login {

  $form->error($locale->text('You did not enter a name!')) unless ($form->{login});
    
  $user = new User $memberfile, $form->{login};

  $user->{js} = $form->{js} = $form->{cjs} ? 1 : 0;
  # if we get an error back, bale out
  if (($errno = $user->login(\%$form, $userspath)) <= -1) {
    $errno *= -1;
    $err[1] = $locale->text('Incorrect Password!');
    $err[2] = $locale->text('Incorrect Dataset version!');
    $err[3] = qq|$form->{login} |.$locale->text('is not a member!');
    $err[4] = $locale->text('Dataset is newer than version!');
    
    if ($errno == 5) {
      # upgrade dataset and log in again
      open FH, ">$userspath/nologin" or $form->($!);
#kabai BUG
      close FH;
      map { $form->{$_} = $user->{$_} } qw(dbname dbhost dbport dbdriver dbuser dbpasswd);

      $form->{dbpasswd} = unpack 'u', $form->{dbpasswd};
      
      $form->{dbupdate} = "db$user->{dbname}";
      $form->{$form->{dbupdate}} = 1;

      $form->header;
      print $locale->text('Upgrading to Version')."... ";

      # required for Oracle
      $form->{dbdefault} = $sid;

      $user->dbupdate(\%$form);
      
      # remove lock file
      unlink "$userspath/nologin";

      print $locale->text('done');

      print "<p><a href=menu.pl?login=$form->{login}&sessionid=$form->{sessionid}&path=$form->{path}&action=display&js=$form->{js}>".$locale->text('Continue')."</a>";

      exit;
    }

    $form->error($err[$errno]);
  }

  # made it this far, execute the menu
  $form->{callback} = "menu.pl?login=$form->{login}&sessionid=$form->{sessionid}&path=$form->{path}&action=display&js=$form->{js}";

  $form->redirect;
  
}



sub logout {

  unlink "$userspath/$form->{login}.conf";
  
  # remove the callback to display the message
  $form->{callback} = "login.pl?path=$form->{path}&action=&login=";
  $form->redirect($locale->text('You are logged out!'));

}


    




