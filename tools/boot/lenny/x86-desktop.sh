# Functions to convert isolinux config to allow selection of desktop
# environment for certain images.

# All config file names need to be in 8.3 format!
# For that reason files that get a desktop postfix are renamed as follows:
# adtxt->at, adgtk->ag.
# With two characters to identify the desktop environment this will leave
# as maximum for example: amdatlx.cfg or amdtxtlx.cfg.

# FIXME: Various statements include Lenny RC1 compatability code:
# '(amd)?', 'te?xt' in regexps and anything with 'text' config files

make_desktop_template() {
	# Split rescue labels out of advanced options files
	for file in boot$N/isolinux/*ad*.cfg; do
		rq_file="$(echo "$file" | sed -r "s:/(amd)?ad:/\1rq:; s:text:txt:")"
		sed -rn "s:desktop=[^ ]*::
			 /^label (amd64-)?rescue/,+3 p" $file >$rq_file
		sed -ri "/^label (amd64-)?rescue/ i\include $(basename $rq_file)
			 /^label (amd64-)?rescue/,+3 d" $file
	done

	mkdir -p boot$N/isolinux/desktop

	cp boot$N/isolinux/menu.cfg boot$N/isolinux/desktop/menu.cfg
	sed -i "/^menu hshift/,/^include stdmenu/ d
		s:include :include %desktop%/:
		/include .*stdmenu/ s:%desktop%/::
		s:config :config %desktop%/:" \
		boot$N/isolinux/desktop/menu.cfg
	cp boot$N/isolinux/desktop/menu.cfg boot$N/isolinux/desktop/prmenu.cfg
	sed -ri "s:(include.*(te?xt|gtk))(\.cfg):\1dt\3:
		 /include.*(te?xt|gtk)/ {s:ad(amd)?te?xt:\1at:; s:ad(amd)?gtk:\1ag:; s:text:txt:}" \
		boot$N/isolinux/desktop/menu.cfg
	sed -i "/menu begin advanced/ s:ced:ced-%desktop%:
		/Advanced options/ i\    menu label Advanced options
		/label mainmenu/ s:mainmenu:dtmenu-%desktop%:
		/label help/ s:help:help-%desktop%:" \
		boot$N/isolinux/desktop/menu.cfg
	sed -i "/^[[:space:]]*menu/ d
		/label mainmenu/ d
		/include stdmenu/ d
		s:^[[:space:]]*::
		/label help/,+5 d" \
		boot$N/isolinux/desktop/prmenu.cfg

	cp boot$N/isolinux/prompt.cfg boot$N/isolinux/desktop/prompt.cfg
	sed -i "/include menu/ a\default install
		s:include menu:include %desktop%/prmenu:" \
		boot$N/isolinux/desktop/prompt.cfg

	for file in boot$N/isolinux/*txt.cfg boot$N/isolinux/*gtk.cfg \
		    boot$N/isolinux/*text.cfg; do
		[ -e "$file" ] || continue
		# Skip rescue include files
		if $(echo $file | grep -Eq "/(amd)?rq"); then
			continue
		fi

		# Create two types of desktop include files: for vesa menu and
		# for prompt; the latter keep the original name, the former
		# get a 'dt' postfix and the name is shortened if needed
		dt_prfile="$(dirname "$file")/desktop/$(basename "$file")"
		dt_file="${dt_prfile%.cfg}dt.cfg"
		dt_file="$(echo "$dt_file" | \
			sed -r "s:ad(amd)?te?xt:\1at:
				s:ad(amd)?gtk:\1ag:
				s:text:txt:")"
		cp $file $dt_file
		sed -ri "/^default/ s:^:#:
			 /include (amd)?rq/ d
			 s:desktop=[^ ]*:desktop=%desktop%:" \
			$dt_file
		cp $dt_file $dt_prfile
		sed -i "/^label/ s:[[:space:]]*$:-%desktop%:" \
			$dt_file
	done
}

modify_for_light_desktop() {
	make_desktop_template

	cp -r boot$N/isolinux/desktop boot$N/isolinux/xfce
	sed -i "s:%desktop%:xfce:g" boot$N/isolinux/xfce/*.cfg
	sed -i "/Advanced options/ s:title:title Xfce:" \
		boot$N/isolinux/xfce/menu.cfg

	cp -r boot$N/isolinux/desktop boot$N/isolinux/lxde
	sed -i "s:%desktop%:lxde:g" boot$N/isolinux/lxde/*.cfg
	sed -i "/Advanced options/ s:title:title LXDE:" \
		boot$N/isolinux/lxde/menu.cfg

	# Cleanup
	rm -r boot$N/isolinux/desktop
	for file in boot$N/isolinux/*txt.cfg boot$N/isolinux/*gtk.cfg \
		    boot$N/isolinux/prompt.cfg \
		    boot$N/isolinux/*text.cfg; do
		[ -e "$file" ] || continue
		# Skip rescue include files
		if $(echo $file | grep -q "/rq"); then
			continue
		fi

		rm $file
	done

	# Create new "top level" menu file
	cat >boot$N/isolinux/menu.cfg <<EOF
menu hshift 13
menu width 49

include stdmenu.cfg
menu title Desktop environment menu
menu begin lxde-desktop
    include stdmenu.cfg
    menu label ^LXDE
    menu title LXDE desktop boot menu
    text help
   Select the 'Lightweight X11 Desktop Environment' for the Desktop task
    endtext
    label mainmenu-lxde
        menu label ^Back..
        menu exit
    include lxde/menu.cfg
menu end
menu begin xfce-desktop
    include stdmenu.cfg
    menu label ^Xfce
    menu title Xfce desktop boot menu
    text help
   Select the 'Xfce lightweight desktop environment' for the Desktop task
    endtext
    label mainmenu-xfce
        menu label ^Back..
        menu exit
    include xfce/menu.cfg
menu end
menu begin rescue
    include stdmenu.cfg
    menu label ^System rescue
    menu title System rescue boot menu
    label mainmenu-rescue
        menu label ^Back..
        menu exit
    include rqtxt.cfg
    include amdrqtxt.cfg
    include rqgtk.cfg
    include amdrqgtk.cfg
menu end
EOF
}
