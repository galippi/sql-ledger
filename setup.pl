#!/usr/bin/perl
#
######################################################################
# SQL-Ledger, Accounting Software Installer
# Copyright (c) 2002, Dieter Simader
#
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#
#######################################################################

$| = 1;

if ($ENV{HTTP_USER_AGENT}) {
  print "
This does not work yet!
use $0 from the command line";
  exit;
}

$lynx = `lynx -version`;      # if LWP is not installed use lynx
$gzip = `gzip -V 2>&1`;            # gz decompression utility
$tar = `tar --version 2>&1`;       # tar archiver
$latex = `latex -version`;

@source = ( "http://www.sql-ledger.org/source",
            "http://www.sql-ledger.com/source",
            "http://abacus.sql-ledger.org/source",
	    "http://pluto.sql-ledger.org/source" );

$userspath = "users";         # default for new installation

eval { require "sql-ledger.conf"; };

$filename = shift;

# is LWP installed
eval { require LWP::Simple; };
$lwp = !($@);

unless ($lwp || $lynx || $filename) {
  die "You must have either lynx or LWP installed
or specify a filename.
perl $0 filename\n";
}

if ($filename) {
  # extract version
  die "Not a SQL-Ledger archive\n" if ($filename !~ /^sql-ledger/);
  
  $version = $filename;
  $version =~ s/sql-ledger-(\d+\.\d+\.\d+).*$/$1/;

  $newinstall = 1;
}
  
if (!$filename && -f "VERSION") {
  # get installed version from VERSION file
  open(FH, "VERSION");
  @a = <FH>;
  close(FH);
  $version = $a[0];
  chomp $version;

  $newinstall = !$version;
} else {
  $newinstall = 1;
}


# is this windows? only used for downloading the right code
$windows = ($^O =~ /MS/) ? '/windows' : '';


$webowner = $<;
$webgroup = $(;

if ($httpd = `find /etc /usr/local/etc -type f -name 'httpd.conf'`) {
  chomp $httpd;
  $webowner = `grep "^User " $httpd`;
  $webgroup = `grep "^Group " $httpd`;

  chomp $webowner;
  chomp $webgroup;
  
  ($null, $webowner) = split / /, $webowner;
  ($null, $webgroup) = split / /, $webgroup;

}

system("tput clear");

if ($filename) {
  $install = "\ninstall $version from (f)ile\n";
}

# check for latest version
&get_latest_version;

if (!$newinstall) {

  $install .= "\n(r)einstall $version\n";
  
}

if ($version && $latest_version) {
  if (!$filename && $version le $latest_version) {
    if (substr($version, 0, rindex($version, ".")) eq substr($latest_version, 0, rindex($latest_version, "."))) {
      $install .= "\n(u)pgrade to $latest_version\n";
    }
  }
}


$install .= "\n(i)nstall $latest_version (from Internet)\n" if $latest_version;

$install .= "\n(d)ownload $latest_version (no installation)" unless $filename;

  print qq|


               SQL-Ledger Accounting Installation



$install


Enter: |;

$a = <STDIN>;
chomp $a;

exit unless $a;
$a = lc $a;

  if ($newinstall && ($a =~ /(i|r|f)/)) {

    print qq|\nEnter httpd owner [$webowner] : |;
    $web = <STDIN>;
    chomp $web;
    $webowner = $web if $web;

    print qq|\nEnter httpd group [$webgroup] : |;
    $web = <STDIN>;
    chomp $web;
    $webgroup = $web if $web;
    
  }

if ($a eq 'd') {
  &download;
}
if ($a =~ /(i|u)/) {
  &install;
}
if ($a eq 'r') {
  $latest_version = $version;
  &install;
}
if ($a eq 'f') {
  &install;
}

exit;
# end main


sub download {

  &get_source_code;

}


sub get_latest_version {
  
  print "Checking for latest version number .... ";

  if ($filename) {
    print "skipping, filename supplied\n";
    return;
  }

  if ($lwp) {
    foreach $source (@source) {
      $host = $source;
      $host =~ s/(\w\/).*/$1/g;
      chop $host;
      print "\nTrying $host ... ";

      $latest_version = LWP::Simple::get("$source/latest_version");
      
      if ($latest_version) {
	last;
      } else {
	print "not found";
      }
    }
  } else {
    if (!$lynx) {
      print "\nYou must have either lynx or LWP installed";
      exit 1;
    }

    foreach $source (@source) {
      $host = $source;
      $host =~ s/(\w\/).*/$1/g;
      chop $host;
      print "\nTrying $host ... ";
      $ok = `lynx -dump -head $source/latest_version`;
      if ($ok = ($ok =~ s/HTTP.*?200 OK//g)) {
	$latest_version = `lynx -dump $source/latest_version`;
	chomp $latest_version;
	last;
      } else {
	print "not found";
      }
    }
    die unless $ok;
  }

  chomp $latest_version;
  if ($latest_version) {
    print "ok\n";
    1;
  }

}


sub get_source_code {

  $err = 0;
 
  if ($latest_version) {
    # download it
    $latest_version = "sql-ledger-${latest_version}.tar.gz";
    
    print "\nStatus\n";
    print "Downloading $latest_version .... ";

    foreach $source (@source) {
      $host = $source;
      $host =~ s/(\w\/).*/$1/g;
      chop $host;
      print "\nTrying $host .... ";
    
      if ($lwp) {
	$err = LWP::Simple::getstore("$source$windows/$latest_version", "$latest_version");
	$err -= 200;
      } else {
	$ok = `lynx -dump -head $source$windows/$latest_version`;
	$err = !($ok =~ s/HTTP.*?200 OK//);

	if (!$err) {
	  $err = system("lynx -dump $source$windows/$latest_version > $latest_version");
	}
      }

      last unless $err;

    }
    
  } else {
    $err = -1;
  }
  
  if ($err) {
    die "Cannot get $latest_version";
  } else {
    print "ok\n";
  }

  $latest_version;

}


sub install {

  if ($filename) {
    $latest_version = $filename;
  } else {
    $latest_version = &get_source_code;
  }

  &decompress;

  if ($newinstall) {
    open(FH, "sql-ledger.conf.default");
    @f = <FH>;
    close(FH);
    unless ($latex) {
      grep { s/^\$latex.*/\$latex = 0;/ } @f;
    }
    open(FH, ">sql-ledger.conf");
    print FH @f;
    close(FH);

    $alias = $absolutealias = $ENV{'PWD'};
    $alias =~ s/.*\///g;
    
    $httpddir = `dirname $httpd`;
    chomp $httpddir;
    $filename = "sql-ledger-httpd.conf";

    # do we have write permission?
    if (!open(FH, ">>$httpddir/$filename")) {
      open(FH, ">$filename");
      $norw = 1;
    }

    $directives = qq|
Alias /$alias/ $absolutealias/
<Directory $absolutealias>
  AllowOverride All
  AddHandler cgi-script .pl
  Options ExecCGI Includes FollowSymlinks
  Order Allow,Deny
  Allow from All
</Directory>

<Directory $absolutealias/users>
  Order Deny,Allow
  Deny from All
</Directory>
  
|;

    print FH $directives;
    close(FH);
    
    print qq|
This is a new installation.

|;

    if ($norw) {
      print qq|
Webserver directives were written to $filename
      
Copy $filename to $httpddir and add
|;

      print qq|
# SQL-Ledger
Include $httpddir/$filename

to $httpd

Don't forget to restart your webserver!
|;

      if (!$permset) {
	print qq|
WARNING: permissions for templates, users, css and spool directory
could not be set. Login as root and set permissions

# chown :$webgroup users templates css spool
# chmod 771 users templates css spool

|;
      }

    } else {
      
      if (!(`grep "^# SQL-Ledger" $httpd`)) {

	open(FH, ">>$httpd");

	print FH qq|

# SQL-Ledger
Include $httpddir/$filename
|;
	close(FH);
        
        print qq|
Webserver directives were written to

  $httpddir/$filename
|;
      }
    }

    if (!$>) {
      # send SIGHUP to httpd
      if ($f = `find /var -type f -name 'httpd.pid'`) {
	$pid = `cat $f`;
	chomp $pid;
	if ($pid) {
	  system("kill -s HUP $pid");
	}
      }
    }
  }
  
  # if this is not root, check if user is part of $webgroup
  if ($>) {
    if ($permset = ($) =~ getgrnam $webgroup)) {
      `chown :$webgroup users templates css spool`;
      chmod 0771, 'users', 'templates', 'css', 'spool';
    }
  } else {
    # root
    `chown -hR 0:0 *`;
    `chown $webowner:$webgroup users templates css spool`;
    chmod 0771, 'users', 'templates', 'css', 'spool';
  }
  
  unlink "sql-ledger.conf.default";

  &cleanup;

  while ($a !~ /(Y|N)/) {
    print qq|\nDisplay README (Y/n) : |;
    $a = <STDIN>;
    chomp $a;
    $a = ($a) ? uc $a : 'Y';
    
    if ($a eq 'Y') {
      @args = ("more", "doc/README");
      system(@args);
    }
  }
  
}


sub decompress {
  
  die "Error: gzip not installed\n" unless ($gzip);
  die "Error: tar not installed\n" unless ($tar);
  
  &create_lockfile;

  # ungzip and extract source code
  print "Decompressing $latest_version ... ";
    
  if (system("gzip -df $latest_version")) {
    print "Error: Could not decompress $latest_version\n";
    &remove_lockfile;
    exit;
  } else {
    print "done\n";
  }

  # strip gz from latest_version
  $latest_version =~ s/\.gz//;
  
  # now untar it
  print "Unpacking $latest_version ... ";
  if (system("tar -xf $latest_version")) {
    print "Error: Could not unpack $latest_version\n";
    &remove_lockfile;
    exit;
  } else {
    # now we have a copy in sql-ledger
    if (system("tar -cf $latest_version -C sql-ledger .")) {
      print "Error: Could not create archive for $latest_version\n";
      &remove_lockfile;
      exit;
    } else {
      if (system("tar -xf $latest_version")) {
        print "Error: Could not unpack $latest_version\n";
	&remove_lockfile;
	exit;
      } else {
        print "done\n";
        print "cleaning up ... ";
        `rm -rf sql-ledger`;
        print "done\n";

        # replace shebang if this is windows
        &shebang if $windows;
	
      }
    }
  }
}


sub create_lockfile {

  if (-d "$userspath") {
    open(FH, ">$userspath/nologin");
    close(FH);
  }
  
}


sub cleanup {

  unlink "$latest_version";
  unlink "$userspath/members.default" if (-f "$userspath/members.default");

  &remove_lockfile;
  
}


sub remove_lockfile { unlink "$userspath/nologin" if (-f "$userspath/nologin") };


sub shebang {

  opendir DIR, ".";
  @perlfiles = grep /\.pl/, readdir DIR;
  closedir DIR;

  foreach $file (@perlfiles) {
    open FH, "+<$file";
    
    @file = <FH>;

    seek(FH, 0, 0);
    truncate(FH, 0);

    $line = shift @file;

    print FH "#!c:\\perl\\bin\\perl\n";
    print FH @file;

    close(FH);

  }
}


