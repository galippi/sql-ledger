#!/usr/bin/perl
#
######################################################################
# SQL-Ledger Accounting
# Copyright (C) 2001
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#
#  Contributors:
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
#######################################################################
#
# this script sets up the terminal and runs the scripts
# in bin/$terminal directory
# admin.pl is linked to this script
#
#######################################################################


# setup defaults, these are overidden by sql-ledger.conf
# DO NOT CHANGE
$userspath = "users";
$templates = "templates";
$memberfile = "users/members";
$sendmail = "| /usr/sbin/sendmail -t";
########## end ###########################################


$| = 1;

eval { require "sql-ledger.conf"; };

if ($ENV{CONTENT_LENGTH}) {
  read(STDIN, $_, $ENV{CONTENT_LENGTH});
}

if ($ENV{QUERY_STRING}) {
  $_ = $ENV{QUERY_STRING};
}

if ($ARGV[0]) {
  $_ = $ARGV[0];
}


%form = split /[&=]/;

# fix for apache 2.0
map { $form{$_} =~ s/\\$// } keys %form;

# name of this script
$0 =~ tr/\\/\//;
$pos = rindex $0, '/';
$script = substr($0, $pos + 1);


if (-f "$userspath/nologin" && $script ne 'admin.pl') {
  print "Content-Type: text/html\n\n" if $ENV{HTTP_USER_AGENT};
  print "\nLogin disabled!\n";
  exit 1;
}

  
if ($form{path}) {
  $form{path} =~ s/%2[fF]/\//g;
  $form{path} =~ s/\.\.\///g;

  if ($form{path} !~ /^bin\//) {
    print "Content-Type: text/html\n\n" if $ENV{HTTP_USER_AGENT};
    print "\nInvalid path!\n";
    exit;
  }


  $ARGV[0] = "$_&script=$script";
  require "$form{path}/$script";
} else {

  if (!$form{terminal}) {
    if ($ENV{HTTP_USER_AGENT}) {
      # web browser
      if ($ENV{HTTP_USER_AGENT} =~ /(mozilla|links|opera|w3m)/i) {
	$form{terminal} = "mozilla";
      }

      if ($ENV{HTTP_USER_AGENT} =~ /lynx/i) {
	$form{terminal} = "lynx";
      }
    } else {
      if ($ENV{TERM} =~ /xterm/) {
	$form{terminal} = "xterm";
      }
      if ($ENV{TERM} =~ /(console|linux|vt.*)/i) {
	$form{terminal} = "console";
      }
    }
  }


  if ($form{terminal}) {

    $ARGV[0] = "path=bin/$form{terminal}&script=$script";
    map { $ARGV[0] .= "&${_}=$form{$_}" } keys %form;

    require "bin/$form{terminal}/$script";
    
  } else {

    print "Content-Type: text/html\n\n" if $ENV{HTTP_USER_AGENT};
    print qq"\nUnknown terminal\n";
  }

}

# end of main

