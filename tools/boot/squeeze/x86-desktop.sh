# Functions to convert isolinux config to allow selection of desktop
# environment for certain images.

create_desktop_dir() {
	local desktop=$1 title

	case $desktop in
		kde)	title=KDE ;;
		xfce)	title=Xfce ;;
		lxde)	title=LXDE ;;
	esac

	cp -r boot$N/isolinux/desktop boot$N/isolinux/$desktop
	sed -i "s:%desktop%:$desktop:
		s:%dt-name%:$title:" boot$N/isolinux/$desktop/*.cfg
}

modify_for_single_desktop() {
	# Cleanup
	rm boot$N/isolinux/dtmenu.cfg
	rm -r boot$N/isolinux/desktop

	# Set default desktop, or remove if not applicable
	if [ "$DESKTOP" ]; then
		sed -i "s:%desktop%:$DESKTOP:g" boot$N/isolinux/*.cfg
	else
		sed -i "s/desktop=%desktop% //" boot$N/isolinux/*.cfg
	fi
}

modify_for_light_desktop() {
	local desktop

	for file in boot$N/isolinux/{,amd}{,ad}{txt,gtk}.cfg; do
		if [ -e $file ]; then
			mv $file boot$N/isolinux/desktop
		fi
	done
	sed -i "s/desktop=%desktop% //" boot$N/isolinux/*.cfg

	for desktop in xfce lxde; do
		create_desktop_dir $desktop
	done

	# Cleanup
	rm -r boot$N/isolinux/desktop
	rm boot$N/isolinux/prompt.cfg boot$N/isolinux/dtmenu.cfg

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

modify_for_all_desktop() {
	local desktop

	for file in boot$N/isolinux/{,amd}{,ad}{txt,gtk}.cfg; do
		if [ -e $file ]; then
			cp $file boot$N/isolinux/desktop
		fi
	done
	sed -i "s/desktop=%desktop% //" boot$N/isolinux/*.cfg

	for desktop in kde xfce lxde; do
		create_desktop_dir $desktop
	done

	# Cleanup
	rm -r boot$N/isolinux/desktop
}
