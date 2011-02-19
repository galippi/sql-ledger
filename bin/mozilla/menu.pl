######################################################################
# SQL-Ledger Accounting
# Copyright (c) 2001
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#  Modified by Tavugyvitel Kft. (info@tavugyvitel.hu)
#
#  Contributors: Christopher Browne
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
# two frame layout with refractured menu
#
#######################################################################

$menufile = "menu.ini";


use SL::Menu;


1;
# end of main


sub display {

  $menuwidth = ($ENV{HTTP_USER_AGENT} =~ /links/i) ? "240" : "155";
  $menuwidth = $myconfig{menuwidth} if $myconfig{menuwidth};

  $form->header(!$form->{duplicate});

  print qq|

<FRAMESET COLS="$menuwidth,*" BORDER="1">

  <FRAME NAME="acc_menu" SRC="$form->{script}?login=$form->{login}&sessionid=$form->{sessionid}&action=acc_menu&path=$form->{path}&js=$form->{js}">
  <FRAME NAME="main_window" SRC="am.pl?login=$form->{login}&sessionid=$form->{sessionid}&action=company_logo&path=$form->{path}">

</FRAMESET>

</BODY>
</HTML>
|;

}



sub acc_menu {

#kabai BUG
#  my $menu = new Menu "$menufile";
 # $menu = new Menu "custom_$menufile" if (-f "custom_$menufile");
 # $menu = new Menu "$form->{login}_$menufile" if (-f "$form->{login}_$menufile");
    if (-f "custom_$menufile"){
	$menu = new Menu "custom_$menufile";
    }elsif  (-f "$form->{login}_$menufile"){
        $menu = new Menu "$form->{login}_$menufile";
    }else{
        $menu = new Menu "$menufile";	
    }
#kabai
  $form->{title} = $locale->text('Accounting Menu');
  
  $form->header;
  print qq|
<script type="text/javascript">
function SwitchMenu(obj, obj2) {
if (document.getElementById) {
    var el = document.getElementById(obj);
    var ar = document.getElementById("cont").getElementsByTagName("DIV");
    var cs = document.getElementById(obj2);

    if (el.style.display == "none") {
      el.style.display = "block"; //display the block of info
      cs.className = 'menuOut2';
    		        
    } else {
      el.style.display = "none";
     cs.className = 'menuOut';
}
  }
}

function ChangeClass(menu, newClass) {
if(document.getElementById(menu).className=="menuOut2"){newClass=newClass+"2";};  
if(document.getElementById(menu).className=="menuOver2"){newClass=newClass+"2";};  
if (document.getElementById) {
    document.getElementById(menu).className = newClass;
  }
}
document.onselectstart = new Function("return false");
</script>
 <body class=menu>
|;
  if ($form->{js}) {
    &js_menu($menu);
  } else {
    &section_menu($menu);
  }

  print qq|
</body>
</html>
|;

}


sub section_menu {
  my ($menu, $level) = @_;

  # build tiered menus
  my @menuorder = $menu->access_control(\%myconfig, $level);

  while (@menuorder) {
    $item = shift @menuorder;
    $label = $item;
    $label =~ s/$level--//g;

    my $spacer = "&nbsp;" x (($item =~ s/--/--/g) * 2);

    $label =~ s/.*--//g;
    $label = $locale->text($label);
    $label =~ s/ /&nbsp;/g;

    $menu->{$item}{target} = "main_window" unless $menu->{$item}{target};
    
    if ($menu->{$item}{submenu}) {

      $menu->{$item}{$item} = !$form->{$item};

      if ($form->{level} && $item =~ $form->{level}) {

        # expand menu
#kabai
	$label = "<img border=0 src=icons/down.gif align=right><span class=menuopen>$label</span>";

#kabai
#kabai +1
	print qq|<br>\n$spacer|.$menu->menuitem(\%myconfig, \%$form, $item, $level, $label).qq|$label</a>|;
	# remove same level items
	map { shift @menuorder } grep /^$item/, @menuorder;
	
	&section_menu($menu, $item);

	print qq|<br>\n|;

      } else {
#kabai +1
	print qq|<br>\n$spacer|.$menu->menuitem(\%myconfig, \%$form, $item, $level, $label).qq|$label&nbsp;...</a>|;

        # remove same level items
	map { shift @menuorder } grep /^$item/, @menuorder;

      }
      
    } else {
    
      if ($menu->{$item}{module}) {
#kabai +1
	print qq|<br>\n$spacer|.$menu->menuitem(\%myconfig, \%$form, $item, $level, $label).qq|$label</a>|;
	
      } else {
	
	print qq|<p><b>$label</b>|;
	
	&section_menu($menu, $item);

	print qq|<br>\n|;

      }
    }
  }
}

sub js_menu {
  my ($menu, $level) = @_;

 print qq|
	<div id="cont">
	|;

  # build tiered menus
  my @menuorder = $menu->access_control(\%myconfig, $level);

  while (@menuorder){
    $i++;
    $item = shift @menuorder;
    $label = $item;
    $label =~ s/.*--//g;
    $label = $locale->text($label);

    $menu->{$item}{target} = "main_window" unless $menu->{$item}{target};

    if ($menu->{$item}{submenu}) {
      
	$display = "display: none;" unless $level eq ' ';

	print qq|
<div id="menu$i" class="menuOut" onclick="SwitchMenu('sub$i', 'menu$i')" onmouseover="ChangeClass('menu$i','menuOver')" onmouseout="ChangeClass('menu$i','menuOut')">$label</div>
	<div class="submenu" id="sub$i" style="$display">|;
	
	# remove same level items
	map { shift @menuorder } grep /^$item/, @menuorder;

	&js_menu($menu, $item);
	
	print qq|

		</div>
		|;

    } else {

      if ($menu->{$item}{module}) {
	if ($level eq "") {
	  print qq|<div id="menu$i" class="menuOut3" onmouseover="ChangeClass('menu$i','menuOver3')" onmouseout="ChangeClass('menu$i','menuOut3')"> |. 
	  $menu->menuitem(\%myconfig, \%$form, $item, $level, $label).qq|$label</a></div>|;

	  # remove same level items
	  map { shift @menuorder } grep /^$item/, @menuorder;

          &js_menu($menu, $item);

	} else {
	
	  print qq|<div class="submenu"> |.
          $menu->menuitem(\%myconfig, \%$form, $item, $level, $label).qq|$label</a></div>|;
	}

      } else {

	$display = "display: none;" unless $item eq ' ';

	print qq|
<div id="menu$i" class="menuOut" onclick="SwitchMenu('sub$i', 'menu$i')" onmouseover="ChangeClass('menu$i','menuOver')" onmouseout="ChangeClass('menu$i','menuOut')">$label</div>
	<div class="submenu" id="sub$i" style="$display">|;
	
	&js_menu($menu, $item);
	
	print qq|

		</div>
		|;

      }

    }

  }

  print qq|
	</div>
	|;
}



sub menubar {

  1;

}


