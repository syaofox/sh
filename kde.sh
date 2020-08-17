#!/bin/bash

loadstrings() {
    INSTALL_DEVICE=
    MIRRORS_SELECTED="no"
    BOOT_PARTION=
    ROOT_PARTION=

    SWAP_COUNT="38912"

    ZONE="Asia"
    SUBZONE="Shanghai"

    # COLORS {{{
        Bold=$(tput bold)
        Reset=$(tput sgr0)

        Red=$(tput setaf 1)
        Yellow=$(tput setaf 3)

        BRed=${Bold}${Red}
        BYellow=${Bold}${Yellow}
    #}}}
    # PROMPTS {{{
        PROMPT_2="Enter n° of options (ex: 1 2 3 or 1-3): "
        PROMPT_1="Enter your option: "
    #}}}

    apptitle="Archlinux With Kde Install Script"
    txtpressanykey="Press any key to continue."
    txtoptional="Optional"

    txtselectmirrors="Select Mirrors"
    txtselectdevice="Select Device"

    txtinitdevice="Init Device"

    txtpartiondevice="Partition Devices"

    txtselectpartion="Select Partitions"
    txtselectedpation="Select %1 device :"

    txteditparts="Edit Partitions"

    txtformatparts="Format Partitions and mount"

    


    txtinstallbasepkg="Install Basepkg"

    txtgenfstab="Genfstab"

    txtmakeswap="Set Swapfile"

    txtsethostname="Set Computer Name"
	txtsetlocale="Set Locale"
	txtgenlocale="Gen Locale"
	txtsettime="Set Time"

    txtunmount="Unmount"
}


preinstalll(){
    timedatectl set-ntp true
    pacman -S  --needed reflector --noconfirm
}

pressanykey(){
	read -n1 -p "${txtpressanykey}"
}

confirm_operation() {
    read -p "${BYellow}$1 [y/N]: ${Reset}" OPTION
    OPTION=`echo "${OPTION}" | tr '[:upper:]' '[:lower:]'`    
}

invalid_option(){
    print_line
    echo "${BRed}Invalid option, Try another one.${Reset}"
    pause
}

print_line() {
    printf "%$(tput cols)s\n" | tr ' ' '-'
}

print_error() { 
    T_COLS=`tput cols`
    echo -e "\n\n${BRed}$1${Reset}\n" | fold -sw $(( $T_COLS - 1 ))
    sleep 3
    return 1
}

print_title() {
    clear
    print_line
    echo -e "# ${Bold}$1${Reset}"
    print_line
    echo ""
}

pause() {
    print_line
    read -e -sn 1 -p "Press enter to continue..."
}

print_info() {
    T_COLS=`tput cols`
    echo -e "${Bold}$1${Reset}\n" | fold -sw $(( $T_COLS - 18)) | sed 's/^/\t/'
}

contains_element() {
    for e in in "${@:2}"; do [[ ${e} == ${1} ]] && break; done;
}



unmountdevices(){
	clear
    swapoff /mnt/swapfile
	echo "umount -R /mnt"
	umount -R /mnt		
}

archchroot(){
	echo "arch-chroot /mnt /root"
	cp ${0} /mnt/root
	chmod 755 /mnt/root/$(basename "${0}")
	arch-chroot /mnt /root/$(basename "${0}") --chroot ${1} ${2}
	rm /mnt/root/$(basename "${0}")
	echo "exit"
}


select_mirrors(){
    echo "Server = https://mirrors.bfsu.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
    pacman -Syyy --noconfirm
    
    reflector -c CN --sort rate  -a 15 -p https --save /etc/pacman.d/mirrorlist
    pacman -Syyy --noconfirm
    cat /etc/pacman.d/mirrorlist
    MIRRORS_SELECTED="yes"
}

selectdisk(){
		items=$(lsblk -d -p -n -l -o NAME,SIZE -e 7,11)
		options=()
		IFS_ORIG=$IFS
		IFS=$'\n'
		for item in ${items}
		do  
				options+=("${item}" "")
		done
		IFS=$IFS_ORIG
		result=$(whiptail --backtitle "${APPTITLE}" --title "${1}" --menu "" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
		if [ "$?" != "0" ]
		then
				return 1
		fi
		echo ${result%%\ *}
		return 0    
}

select_device() {
    device=$( selectdisk "${txteditparts} (cfdisk)" )
    if [ "$?" = "0" ]; then
		# clear
		# cfdisk ${device}
        INSTALL_DEVICE=${device}
	fi
    clear
    
    # local devices_list=(`lsblk -d | awk 'NR>1 { print "/dev/" $1 }'`)
    # PS3=${PROMPT_1}
    # echo -e "Select device to install Arch Linux:\n"
    # select device in "${devices_list[@]}"; do
    #     if contains_element ${device} ${devices_list[@]}; then 
    #         confirm_operation "Do you wish to init ${device}(delele partition table)? Data on ${device} will be damaged"
    #         if [[ ${OPTION} == "y" ]] || [[ ${OPTION} == "" ]];  then
    #             dd if=/dev/zero of=${device} bs=512 count=1 conv=notrunc
    #         fi
    #         INSTALL_DEVICE=${device}
    #         cfdisk ${INSTALL_DEVICE}            
    #         break
    #     else            
    #         invalid_option
    #         break
    #     fi
    # done

}

init_device(){
    if (whiptail --backtitle "${apptitle}" --title "${txtinitdevice}" --yesno "Do you wish to init ${INSTALL_DEVICE}(delele partition table)? Data on ${INSTALL_DEVICE} will be damaged" 0 0) then
        clear
        dd if=/dev/zero of=${device} bs=512 count=1 conv=notrunc
    fi
}

partionsdevice(){
    clear
    cfdisk ${INSTALL_DEVICE}
}

select_partion() {

    items=$(lsblk -p -n -l -o NAME -e 7,11)
	options=()
	for item in ${items}; do
		options+=("${item}" "")
	done

	bootdev=$(whiptail --backtitle "${apptitle}" --title "${txtselectpartion}" --menu "${txtselectedpation//%1/boot}" --default-item "${bootdev}" 0 0 0 \
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

    rootdev=$(whiptail --backtitle "${apptitle}" --title "${txtselectpartion}" --menu "${txtselectedpation//%1/root}" --default-item "${rootdev}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	fi
	

    msg="Selected devices :\n\n"
	msg=${msg}"boot : "${bootdev}"\n"
	msg=${msg}"root : "${rootdev}"\n"

    if (whiptail --backtitle "${apptitle}" --title "${txtselectpartion}" --yesno "${msg}" 0 0) then
        BOOT_PARTION=${bootdev}
        ROOT_PARTION=${rootdev}		
	fi           
}

formatparts(){


    if [[ ${BOOT_PARTION} != "" ]] && [[ ${ROOT_PARTION} != "" ]]; then

         msg="Format Partions :\n\n"
        msg=${msg}"boot : "${BOOT_PARTION}"\n"
        msg=${msg}"root : "${ROOT_PARTION}"\n"

        if (whiptail --backtitle "${apptitle}" --title "${txtformatparts}" --yesno "${msg}" 0 0) then
        
            mkfs.fat -F32 ${BOOT_PARTION}
            mkfs.ext4  -L archroot  ${ROOT_PARTION}        
            mount ${ROOT_PARTION} /mnt        
            mkdir -p /mnt/boot/efi 
            mount ${BOOT_PARTION} /mnt/boot/efi
        fi
    fi
}

install_basepkg(){
    pkgs="base"
    options=()
	options+=("linux" "" on)
    options+=("linux-headers" "(${txtoptional})" on)
    options+=("base-devel" "(${txtoptional})" on)
    options+=("linux-firmware" "(${txtoptional})" on)
    options+=("intel-ucode" "(${txtoptional})" on)
    options+=("pacman-contrib" "(${txtoptional})" on)
    options+=("sudo" "(${txtoptional})" on)
    options+=("vim" "(${txtoptional})" on)
    options+=("nano" "(${txtoptional})" on)
    options+=("git" "(${txtoptional})" on)
    options+=("openssh" "(${txtoptional})" on)

    sel=$(whiptail --backtitle "${apptitle}" --title "${txtinstallarchlinuxfirmwares}" --checklist "" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	fi
	for itm in $sel; do
		pkgs="$pkgs $(echo $itm | sed 's/"//g')"
	done

    clear
	echo "pacstrap /mnt ${pkgs}"
	pacstrap /mnt ${pkgs}

    # yes '' | pacstrap -i /mnt base base-devel linux linux-headers linux-firmware pacman-contrib intel-ucode sudo vim git dnsutils openssh
    # yes '' | genfstab -U /mnt >> /mnt/etc/fstab
    # cat /mnt/etc/fstab
}

gen_fstab(){
    yes '' | genfstab -U /mnt >> /mnt/etc/fstab
    cat /mnt/etc/fstab
}

makeswap(){

    
    SWAP_COUNT=$(whiptail --inputbox "Set Swap Count(M)?" 8 39 "${SWAP_COUNT}" --title "${txtmakeswap}" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
        archchroot makeswap ${SWAP_COUNT}	
	else
		echo "User selected Cancel."
	fi
}

archsetswap(){
    if [ ! "${1}" = "none" ]; then
        dd if=/dev/zero of=/swapfile bs=1M count=${1} status=progress #8G
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo >> /etc/fstab
        echo "# Swapfile" >> /etc/fstab
        echo "/swapfile none swap defaults 0 0" >> /etc/fstab
        cat /etc/fstab
    fi
    exit
}

archsethostname(){
	hostname=$(whiptail --backtitle "${apptitle}" --title "${txtsethostname}" --inputbox "" 0 0 "archlinux" 3>&1 1>&2 2>&3)
	if [ "$?" = "0" ]; then
		clear
		echo "echo \"${hostname}\" > /mnt/etc/hostname"
		echo "${hostname}" > /mnt/etc/hostname
        cat  /mnt/etc/hostname
		pressanykey
	fi
}

archgenlocale(){
	items=$(ls /usr/share/i18n/locales)
	options=()
	defsel=""
	for item in ${items}; do
		if [ "${item}" = "en_US" ] || [ "${item}" = "zh_CN" ] || [ "${item}" = "zh_HK" ] || [ "${item}" = "zh_TW" ]; then
            options+=("${item}" "" on)		
		else
            options+=("${item}" "" off)
		fi
	done	
    sel=$(whiptail --backtitle "${apptitle}" --title "${txtgenlocale}" --checklist "" 0 0 0 \
    "${options[@]}" \
    3>&1 1>&2 2>&3)
    if [ ! "$?" = "0" ]; then
		return 1
	fi
	for itm in $sel; do
		locales="$locales $(echo $itm | sed 's/"//g')"
	done
	clear
	
	for locale in $locales; do	
		echo "sed -i '/#${locale}.UTF-8/s/^#//g' /mnt/etc/locale.gen"
		sed -i '/#'${locale}'.UTF-8/s/^#//g' /mnt/etc/locale.gen
	done
	archchroot genlocale

	options=()
	for litm in ${locales}; do
		options+=("${litm}" "")
	done

	sellocale=$(whiptail --backtitle "${apptitle}" --title "${txtsetlocale}" --menu "" 0 0 0 \
    "${options[@]}" \
    3>&1 1>&2 2>&3)
    if [ ! "$?" = "0" ]; then
		return 1
	fi
	clear
	echo "echo \"LANG=${sellocale}.UTF-8\" > /mnt/etc/locale.conf"
    echo "LANG=${sellocale}.UTF-8" > /mnt/etc/locale.conf

	pressanykey
}

archgenlocalechroot(){
	echo "locale-gen"
	locale-gen
	exit
}

archsettimechroot(){
    print_title "TIMEZONE - https://wiki.archlinux.org/index.php/Timezone"
    print_info "In an operating system the time (clock) is determined by four parts: Time value, Time standard, Time Zone, and DST (Daylight Saving Time if applicable)."

    ln -sf /usr/share/zoneinfo/${ZONE}/${SUBZONE} /etc/localtime
    systemctl enable systemd-timesyncd.service
    hwclock --systohc --utc
    exit
}


archmenu(){
	if [ "${1}" = "" ]; then
		nextitem="."
	else
		nextitem=${1}
	fi    

	options=()
	options+=("${txtselectmirrors}" "${MIRRORS_SELECTED}")

    options+=("${txtselectdevice}" "${INSTALL_DEVICE}")
    options+=("${txtinitdevice}" "")        
    options+=("${txtpartiondevice}" "")    
    options+=("${txtselectpartion}" "BOOT:${BOOT_PARTION} ROOT:${ROOT_PARTION}")
    options+=("${txtformatparts}" "")

    options+=("${txtinstallbasepkg}" "")   
    options+=("${txtgenfstab}" "")   
    
    options+=("${txtmakeswap}" "${SWAP_COUNT} MB")

    options+=("${txtsethostname}" "/etc/hostname")	
	options+=("${txtgenlocale}" "/etc/locale.gen")
	options+=("${txtsettime}" "/etc/localtime")
    
    options+=("" "")    
    options+=("${txtunmount}" "")    
    
	sel=$(whiptail --backtitle "${apptitle}" --title "Select to Run" --menu "" --cancel-button "cancle" --default-item "${nextitem}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
		
    if [ "$?" = "0" ]; then
        echo "Pre-Install"
        preinstalll
		case ${sel} in
            "${txtselectmirrors}")	
				select_mirrors
				pressanykey
				nextitem="${txtselectmirrors}"
				;;
            "${txtselectdevice}")	
				select_device
                lsblk
				pressanykey
				nextitem="${txtselectdevice}"
				;;
            "${txtinitdevice}")	
				init_device
                lsblk
				pressanykey
				nextitem="${txtinitdevice}"
				;;  
            "${txtpartiondevice}")	
				partionsdevice
                lsblk
				pressanykey
				nextitem="${txtpartiondevice}"
				;;  
            

                       

            "${txtselectpartion}")	
				select_partion
                lsblk
				pressanykey
				nextitem="${txtselectpartion}"
				;;
            "${txtformatparts}")	
				formatparts
                lsblk
				pressanykey
				nextitem="${txtformatparts}"
				;; 
            
            "${txtinstallbasepkg}")
                install_basepkg
                pressanykey
                nextitem="${txtinstallbasepkg}"
                ;;

            "${txtgenfstab}")
                gen_fstab
                pressanykey
                nextitem="${txtgenfstab}"
                ;;
            "${txtmakeswap}")
                makeswap
                pressanykey
                nextitem="${txtmakeswap}"
                ;;

            "${txtsethostname}")
				archsethostname
                pressanykey
				nextitem="${txtsetkeymap}"
			;;
		
			"${txtgenlocale}")
				archgenlocale
                pressanykey
				nextitem="${txtsettime}"
			;;
			
			"${txtsettime}")
				archchroot settime
                pressanykey
				nextitem="${txtsetrootpassword}"
			;;



            "${txtunmount}")
                unmountdevices
                pressanykey
                nextitem="${txtunmount}"
                ;;

            
                
		esac
		archmenu "${nextitem}"
	fi
}

while (( "$#" )); do
	case ${1} in		
		--chroot) chroot=1
							command=${2}
							args=${3};;
	esac
	shift
done

if [ "${chroot}" = "1" ]; then
	case ${command} in
        'makeswap') archsetswap ${args};;
        'genlocale') archgenlocalechroot;;
        'settime') archsettimechroot;;
		# 'setrootpassword') archsetrootpasswordchroot;;
		# 'genlocale') archgenlocalechroot;;
		# 'settimeutc') archsettimeutcchroot;;
		# 'settimelocal') archsettimelocalchroot;;
		# 'genmkinitcpio') archgenmkinitcpiochroot;;
		# 'enabledhcpcd') archenabledhcpcdchroot;;
		# 'grubinstall') archgrubinstallchroot;;
		# 'grubbootloaderinstall') archgrubinstallbootloaderchroot ${args};;
		# 'grubbootloaderefiinstall') archgrubinstallbootloaderefichroot ${args};;
		# 'grubbootloaderefiusbinstall') archgrubinstallbootloaderefiusbchroot ${args};;
		# 'syslinuxbootloaderinstall') archsyslinuxinstallbootloaderchroot ${args};;
		# 'syslinuxbootloaderefiinstall') archsyslinuxinstallbootloaderefichroot ${args};;
		# 'systemdbootloaderinstall') archsystemdinstallchroot ${args};;
		# 'refindbootloaderinstall') archrefindinstallchroot ${args};;
		# 'archdiinstallandlaunch') archdiinstallandlaunchchroot;;
		# 'archdiinstall') archdiinstallchroot;;
		# 'archdilaunch') archdilaunchchroot;;
	esac
else
	loadstrings
	archmenu
fi

exit 0

