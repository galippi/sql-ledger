
require 'SL/Template.pm';
use CGI::Carp qw(fatalsToBrowser);

# SQL Reports

$username=$form->{login}; $username=~s/[\\\/\:\'\"]//g;
$userdir='directsql/';
opendir(TEMPLATESDIR,$userdir); @templates=grep /.tmpl$/, readdir(TEMPLATESDIR); closedir(TEMPLATESDIR);

sub save {
  local $tfile = $form->{tfile}; local $sqltemplate = $tfile; $sqltemplate=~s/\'/\\\'/g;
  local $query = $form->{query}; local $sqlquery = $query; $sqlquery=~s/\'/\\\'/g;
  local $name = $form->{name}; local $sqlname = $name; $sqlname=~s/\'/\\\'/g;

  local $dbh = $form->dbconnect(\%myconfig);

  local $sth = $dbh->prepare("SELECT * FROM ds WHERE usr='$username' and name='$sqlname'");
  $sth->execute || $form->dberror($query);
  if ($sth->fetchrow_array) {
    $sth->finish;
    local $sth = $dbh->prepare("UPDATE ds SET query='$sqlquery',template='$sqltemplate' WHERE usr='$username' and name='$sqlname'");
    $sth->execute || $form->dberror($query);
  } else {
    $sth->finish;
    local $sth = $dbh->prepare("INSERT INTO ds (usr,name,query,template) VALUES ('$username','$sqlname','$sqlquery','$sqltemplate')");
    $sth->execute || $form->dberror($query);
  }
  $sth->finish;
  
  list();
}

sub del {
  local $id = $form->{id}; $id+=0;
  local ($name,$query,$tfile)=w_getpar($id);
  local $sqlname = $name; $sqlname=~s/\'/\\\'/g;
  screen_areyousure();
}

sub realdel {
  local $id = $form->{id}; $id+=0;
  local $dbh = $form->dbconnect(\%myconfig);
  local $sth = $dbh->prepare("DELETE FROM ds WHERE id='$id' AND usr='$username'");
  $sth->execute || $form->dberror($query);
  $sth->finish;
  list();
}

sub list {

  local $dbh = $form->dbconnect(\%myconfig);

  local $sth = $dbh->prepare("SELECT * FROM ds WHERE usr='$username' ORDER BY id");
  $sth->execute || $form->dberror($query);
  while ($row=$sth->fetchrow_hashref) { push @queries,$row; }
  $sth->finish;

  screen_list();

}

sub edit {
  local $id = $form->{id};
  local $tfile = $form->{tfile};
  local $query = $form->{query};
  local $name = $form->{name};
  ($name,$query,$tfile)=w_getpar($id) if $id>0;
  $tfile=$templates[0] if $tfile eq '' or $tfile=~/[\/\\\:\"\']/ or !-e $userdir.$tfile;
  screen_query();
}

sub run {
  $form->error($locale->text('Database can not be modified!')) if $form->{query} =~ /(UPDATE|DELETE|ALTER|DROP|CREATE|SET|INSERT)/i;
  local $dbh = $form->dbconnect(\%myconfig);

  local $id = $form->{id};
  local $tfile = $form->{tfile};
  local $query = $form->{query};
  local ($result)='';

  ($name,$query,$tfile)=w_getpar($id) if $id>0;

  if ($query) {

    local $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    
    local @row;
    local @rows;
    local $colnames = $sth -> {NAME};
    foreach $name (@$colnames) {
      push @colnames, {
              name => $name,
              isnotlast => ++$num<@$colnames
      }
    }
    while (@row = $sth->fetchrow) {
      local @columns;
      foreach $name (@$colnames) {
        local $value = shift @row;
        local $type;
        $type = 'string';
        $type = 'num' if ($value =~ /^[\d\,\.]+$/);
        $type = 'date' if ($value =~ /^\d{4}-\d{2}-\d{2}$/);
        $csvvalue = $value; $csvvalue =~ s/\"/\"\"/g;
        push @columns,{
              value => $value,
              csvvalue => $csvvalue,
              string => $type eq 'string',
              num => $type eq 'num',
              date => $type eq 'date',
              isnotlast => @row>0
        };
      }
      push( @rows,{ columns => \@columns } );
    }

    $tfile=$templates[0] if $tfile eq '' or $tfile=~/[\/\\\:\"\']/ or !-e $userdir.$tfile;
    local $template = HTML::Template->new(filename => $userdir.$tfile, die_on_bad_params => 0);
    $template->param(result_cols => \@colnames, result_data => \@rows);
    $result = $template->output;

    $sth->finish;
  }
  screen_result();
}

sub screen_list {
  $form->{title} = $locale->text('SQL Reports');
  $form->header();

  print qq|
<head>
<style>
  .string { color: #800000; }
  .num { color: #000080; }
  .date { color: #008000; }
</style>
</head>
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
    <form method=post action=$form->{script}>
    <input type='hidden' name='path' value=$form->{path}>
    <input type='hidden' name='login' value=$form->{login}>
    <input type='hidden' name='sessionid' value=$form->{sessionid}>
    <select name="id">
|; foreach $query (@queries) {
    local $shorttemplate=${$query}{'template'}; $shorttemplate=~s/\.tmpl$//;
    local $disp=w_htmlquotevalue(${$query}{'name'}).' ('.$shorttemplate.')';
    print qq|<option value="|.w_htmlquotevalue(${$query}{'id'}).qq|">$disp</option>|;
}
print qq|</select>
      <input type=submit class=submit name=action value="|.$locale->text('Edit').qq|">
      <input type=submit class=submit name=action value="|.$locale->text('Delete').qq|">
      <input type=submit class=submit name=action value="|.$locale->text('Run').qq|">
      </form>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

      <form method=post action=$form->{script}>
      <input type='hidden' name='path' value=$form->{path}>
      <input type='hidden' name='login' value=$form->{login}>
      <input type='hidden' name='sessionid' value=$form->{sessionid}>
      <input type='hidden' name='id' value="0">
      <td><input type=submit class=submit name=action value="|.$locale->text('New').qq|"></td>
      </form>


</body></html>
|;
}

sub screen_query {
  $form->{title} = $locale->text('SQL Reports');
  $form->header();

  print qq|
<body>
<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table width="100%">
	<tr>
	  <th align=right nowrap>|.$locale->text('Report name').qq|</th>
	  <td colspan=3><input name=name size=35 value="|.w_htmlquotevalue($name).qq|"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('SQL query').qq|</th>
	  <td colspan=3><textarea name=query style="width: 100%" rows=10>|.w_htmlquotevalue($query).qq|</textarea></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Result type').qq|</th>
	  <td colspan=3><select name="tfile">|; 
        foreach $template (@templates) {
          local $shorttemplate=$template; $shorttemplate=~s/\.tmpl$//;
          print "<option value=\"$template\"".($template eq $tfile?' selected="selected"':'').">$shorttemplate</option>\n";
        }
      print qq|</select></td>
	</tr>
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
<input type=submit class=submit name=action value="|.$locale->text('Run').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Ment').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Back').qq|">
</form>

</body>
</html>
|;
}

sub screen_areyousure {
  $form->{title} = $locale->text('SQL Reports');
  $form->header();

  print qq|
<body>
<form method=post action=$form->{script}>

Biztosan törölni szeretné a(z) "$name" nevû lekérdezést?<br><br>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
<input type=hidden name=id value=$id>
<input type=submit class=submit name=action value="|.$locale->text('ReallyDelete').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Back').qq|">
</form>

</body>
</html>
|;
}

sub screen_result {
  #$form->error(length($result));
  local $filename=$tfile; $filename=~s/\.tmpl$//;
  print "Accept-Ranges: bytes\n";
  print "Content-Length: ".length($result)."\n";
  #print "Content-Length: 25000\n";
  print "Content-Disposition: inline; filename=$filename\n";
  if ($tfile=~/txt.tmpl$/) { print "Content-type: text/plain;\n\n"; }
  elsif ($tfile=~/csv.tmpl$/) { print "Content-type: text/comma-separated-values;\n\n"; }
  elsif ($tfile=~/html.tmpl$/) { print "Content-type: text/html;\n\n"; }
  elsif ($tfile=~/xls.tmpl$/) { print "Content-type: application/ms-excel;\n\n"; }
  else { print "Content-type: text/plain;\n\n"; }
  print $result;
}

sub w_htmlquote {

  foreach(@_) {
    $form->{$_}=~s/\&/&amp;/g;
    $form->{$_}=~s/\"/&quot;/g;
    $form->{$_}=~s/\</&lt;/g;
    $form->{$_}=~s/\>/&gt;/g;
  }

}

sub w_htmlquotevalue {
  local $value=$_[0];
  $value=~s/\&/&amp;/g;
  $value=~s/\"/&quot;/g;
  $value=~s/\</&lt;/g;
  $value=~s/\>/&gt;/g;
  return($value);
}

sub w_getpar {
  my($id)=$_[0];
  local $dbh = $form->dbconnect(\%myconfig);
  my $sth = $dbh->prepare("SELECT name,query,template FROM ds WHERE usr='$username' AND id='$id'");
  $sth->execute || $form->dberror($query);
  my($row)=$sth->fetchrow_hashref;
  $sth->finish;
  return(${$row}{'name'},${$row}{'query'},${$row}{'template'});
}
1;
# end
