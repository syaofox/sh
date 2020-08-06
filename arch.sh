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
    
    txtdiskpartmenu="Disk Patitions"    
    txtpartitions="Partitions"
    txteditparts="Edit Partitions"

    txtreboot="Reboot"


}


rebootpc(){
	if (whiptail --backtitle "${apptitle}" --title "${txtreboot}" --yesno "${txtreboot} ?" --defaultno 0 0) then
		clear
		reboot
	fi
}

diskpartcfdisk(){
    device=$( selectdisk "${txteditparts} (cfdisk)" )
	if [ "$?" = "0" ]; then
		clear
		cfdisk ${device}
	fi
}

selectparts(){
	items=$(lsblk -p -n -l -o NAME -e 7,11)
	options=()
	for item in ${items}; do
		options+=("${item}" "")
	done

	bootdev=$(whiptail --backtitle "${apptitle}" --title "${txtselectpartsmenu}" --menu "${txtselectdevice//%1/boot}" --default-item "${bootdev}" 0 0 0 \
		"none" "-" \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	else
		if [ "${bootdev}" = "none" ]; then
			bootdev=
		fi
	fi

	swapdev=$(whiptail --backtitle "${apptitle}" --title "${txtselectpartsmenu}" --menu "${txtselectdevice//%1/swap}" --default-item "${swapdev}" 0 0 0 \
		"none" "-" \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	else
		if [ "${swapdev}" = "none" ]; then
			swapdev=
		fi
	fi

	rootdev=$(whiptail --backtitle "${apptitle}" --title "${txtselectpartsmenu}" --menu "${txtselectdevice//%1/root}" --default-item "${rootdev}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	fi
	realrootdev=${rootdev}

	homedev=$(whiptail --backtitle "${apptitle}" --title "${txtselectpartsmenu}" --menu "${txtselectdevice//%1/home}" 0 0 0 \
		"none" "-" \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	else
		if [ "${homedev}" = "none" ]; then
			homedev=
		fi
	fi

	msg="${txtselecteddevices}\n\n"
	msg=${msg}"boot : "${bootdev}"\n"
	msg=${msg}"swap : "${swapdev}"\n"
	msg=${msg}"root : "${rootdev}"\n"
	msg=${msg}"home : "${homedev}"\n\n"
	if (whiptail --backtitle "${apptitle}" --title "${txtselectpartsmenu}" --yesno "${msg}" 0 0) then
		isnvme=0
		if [ "${bootdev::8}" == "/dev/nvm" ]; then
			isnvme=1
		fi
		if [ "${rootdev::8}" == "/dev/nvm" ]; then
			isnvme=1
		fi
		mountmenu
	fi
}

diskpartmenu(){
	if [ "${1}" = "" ]; then
		nextitem="."
	else
		nextitem=${1}
	fi
	options=()
	options+=("${txteditparts} (cfdisk)" "")
	sel=$(whiptail --backtitle "${apptitle}" --title "${txtdiskpartmenu}" --menu "" --cancel-button "${txtback}" --default-item "${nextitem}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
    if [ "$?" = "0" ]; then
		case ${sel} in
			"${txteditparts} (cfdisk)")
				diskpartcfdisk
				nextitem="${txteditparts} (cfdisk)"			
		esac
		diskpartmenu "${nextitem}"
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
    options+=("${txtpartitions}" "")
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
			"${txtpartitions}")
                diskpartmenu
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
