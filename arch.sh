#!/bin/bash

apptitle="Archi Install Script Ver:20200805"

pressanykey(){
	read -n1 -p "${txtpressanykey}"
}

changemirrors(){
	if [[ ! -f /etc/pacman.d/mirrorlist.backup ]]; then
			cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
	fi    
	
	options=()		
	options+=("China" "")
	options+=("Japan" "")

	country=$(whiptail --backtitle "${APPTITLE}" --title "${txtselectcountry}" --menu "" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
			return 1    
	fi

	clear
	echo "reflector $country"
	reflector --verbose -c $country --sort rate  -a 12 -p https --save /etc/pacman.d/mirrorlist
	pressanykey
}


loadstrings(){
    txtexit="Exit"
	txtback="Back"
    txtoptional="Optional"

    txtmainmenu="Main Menu"

    txtpressanykey="Press any key to continue."

    txtchangemirrors="Change Mirrors By Country"

    txtselectcountry="Select country"

    txtreboot="Reboot"


}


rebootpc(){
	if (whiptail --backtitle "${apptitle}" --title "${txtreboot}" --yesno "${txtreboot} ?" --defaultno 0 0) then
		clear
		reboot
	fi
}

mainmenu(){
    if [ "${1}" = "" ]; then
		nextitem="."
	else
		nextitem=${1}
	fi
	options=()
    options+=("${txtchangemirrors}" "(${txtoptional})")
    options+=("" "")
	options+=("${txtreboot}" "")
	sel=$(whiptail --backtitle "${apptitle}" --title "${txtmainmenu}" --menu "" --cancel-button "${txtexit}" --default-item "${nextitem}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)	

    if [ "$?" = "0" ]; then
		case ${sel} in			
			"${txtchangemirrors}")
				changemirrors
				# nextitem="${txtdiskpartmenu}"
			;;			
			# "${txtdiskpartmenu}")
			# 	diskpartmenu
			# 	nextitem="${txtselectpartsmenu}"
			# ;;
			# "${txtselectpartsmenu}")
			# 	selectparts
			# 	nextitem="${txtreboot}"
			# ;;
			"${txtreboot}")
				rebootpc
				nextitem="${txtreboot}"
			;;
		esac
		mainmenu "${nextitem}"
	else
		clear
	fi
}

loadstrings
mainmenu