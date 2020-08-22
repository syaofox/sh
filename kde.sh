#!/bin/bash

loadstrings() {
    INSTALL_DEVICE=
    MIRRORS_SELECTED="no"
    BOOT_PARTION=
    ROOT_PARTION=

    SWAP_COUNT="38912"

    ZONE="Asia"
    SUBZONE="Shanghai"

    ROOT_PASSWORD="0928"
    USER_NAME="syaofox"
    USER_PASSWORD="0928"
    ISSSDTRIM="off"
    HOSTNAME="arch-nuc"

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

    txtbaseinstall="Base Install"
    txtdeskinstall="Desktop Install"
    txtselectmirrors="Select Mirrors"
    txtselectdevice="Select Device"

    txtinitdevice="Init Device"

    txtpartiondevice="Partition Devices"

    txtselectpartion="Select Partitions"
    txtselectedpation="Select %1 device :"

    txteditparts="Edit Partitions"

    txtformatparts="Format Partitions and mount"
    
    txtinstallmediacodecs="Install Mediacodecs"
    
    txtinstallfonts="Install Fonts"


    txtinstallbasepkg="Install Basepkg"

    txtgenfstab="Genfstab"

    txtmakeswap="Set Swapfile"

    txtsethostname="Set Computer Name"
	txtsetlocale="Set Locale"
	txtgenlocale="Gen Locale"
	txtsettime="Set Time"
    txthosts="Set Hosts"

    txtsetrootpassword="Set Rootpasswd"
    txtadduser="Add user"

    txtbootloader="Install Bootloader"

    txtinstallextrapkgs="Install Extra Pakages"
    txtdrivers="Install Drivers"

    txtswitchssdtrim="Switch SSD Trim"

    txtinstallkde="Install KDE"

    txtswappiness="Set Swappiness"

    
    txtconfigSmbShare="Config Samba Share"
    txtfixkonsoleshortcut="Fix konsole Luncher Shortcut"
    txtfixcjk="Fix CJK fonts order"

    txtarchlinuxcn="Setting Archlinuxcn && yay"
    txtinstallyay="Install yay"
    txtaddarchlinuxcn="Add Archlinuxcn"
    txtfixkeyring="Fix Keyring"

    txtinstallsoftware="Install Software"

    txtunmount="Unmount"
    txtreboot="Reboot"
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
	arch-chroot /mnt /root/$(basename "${0}") --chroot ${1} ${2} ${3}
	rm /mnt/root/$(basename "${0}")
	echo "exit"
}


select_mirrors(){
    clear
    echo "Server = https://mirrors.bfsu.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
    pacman -Syyy --noconfirm
    
    reflector -c CN --sort rate  -a 15 -p https --save /etc/pacman.d/mirrorlist
    pacman -Syyy --noconfirm
    vim /etc/pacman.d/mirrorlist
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
    # options+=("pacman-contrib" "(${txtoptional})" on)
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
    truncate -s 0 /mnt/etc/fstab	
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
	HOSTNAME=$(whiptail --backtitle "${apptitle}" --title "${txtsethostname}" --inputbox "" 0 0 $HOSTNAME 3>&1 1>&2 2>&3)
	if [ "$?" = "0" ]; then
		clear
		echo "echo \"${HOSTNAME}\" > /mnt/etc/hostname"
		echo "${HOSTNAME}" > /mnt/etc/hostname
        cat  /mnt/etc/hostname
		
	fi
}

archgenlocale(){
	items=$(ls /usr/share/i18n/locales)
	options=()
    options+=("C" "" on)		
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

	
}

archgenlocalechroot(){
	echo "locale-gen"
	locale-gen
	exit
}

archsettimechroot(){
    print_title "TIMEZONE - https://wiki.archlinux.org/index.php/Timezone"
    print_info "In an operating system the time (clock) is determined by four parts: Time value, Time standard, Time Zone, and DST (Daylight Saving Time if applicable)."

    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    #systemctl enable systemd-timesyncd.service
    # hwclock --systohc --utc
    hwclock --systohc
    exit
}

setrootpasswd(){
    ROOT_PASSWORD=$(whiptail --backtitle "${apptitle}" --title "${txtsetrootpassword}" --inputbox "" 0 0 "${ROOT_PASSWORD}" 3>&1 1>&2 2>&3)
	if [ "$?" = "0" ]; then
		clear
		archchroot setrootpasswd ${ROOT_PASSWORD}
		
	fi
}

archsetrootpasswdchroot(){
    if [ ! "${1}" = "none" ]; then
        echo 'Set root Password:'${1}
        echo root":"${1} | chpasswd
    fi
    
    # useradd -m -G sys,log,network,floppy,scanner,power,rfkill,users,video,storage,optical,lp,audio,wheel,adm ${USER_NAME} && echo '${USER_NAME}:${USER_PASSWORD}' | chpasswd
    # echo '${USER_NAME} ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo
}

adduser(){
    local usrname="0"
    local upsw="0"
    USER_NAME=$(whiptail --backtitle "${apptitle}" --title "${txtadduser}:Set user name" --inputbox "" 0 0 "${USER_NAME}" 3>&1 1>&2 2>&3)
	if [ "$?" = "0" ]; then
		usrname=${USER_NAME}		
	fi

    USER_PASSWORD=$(whiptail --backtitle "${apptitle}" --title "${txtadduser}:Set user password" --inputbox "" 0 0 "${USER_PASSWORD}" 3>&1 1>&2 2>&3)
	if [ "$?" = "0" ]; then
		upsw=${USER_PASSWORD}		
	fi

    if [ "${usrname}" != "0" ] && [ "${upsw}" != "0" ]; then
        archchroot adduser ${usrname} ${upsw}
    fi
}

archadduserchroot(){
    
    
    if [ ! "${1}" = "none" ] && [ ! "${2}" = "none" ]; then
        echo "Adduser User:"${1}" Password"${2}
        
        useradd -m -G sys,log,network,floppy,scanner,power,rfkill,users,video,storage,optical,lp,audio,wheel,adm ${1}
        # echo "passwd "${1}
        # passed=1
        # while [[ ${passed} != 0 ]]; do
        #     passwd ${1}
        #     passed=$?
        # done
        # exit
        echo ${1}":"${2} | chpasswd
        echo "Addsudo User "${1}
        echo ${1}' ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo
    fi
}

setbootloaderchroot(){
    pacman -S --needed efibootmgr grub --noconfirm
    grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
    # mkdir -p /boot/efi/EFI/BOOT
    # cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
    # echo 'bcf boot add 1 fs0:\EFI\grubx64.efi \"My GRUB bootloader\" && exit' > /boot/efi/startup.sh
    grub-mkconfig -o /boot/grub/grub.cfg
}

installextrapkgs(){
    pkgs=""
    options=()               
	options+=("haveged" "(${txtoptional})" on)
    options+=("mtools" "(${txtoptional})" on)
    options+=("dosfstools" "(${txtoptional})" on)
    options+=("xdg-utils" "(${txtoptional})" on)
    options+=("xdg-user-dirs" "(${txtoptional})" on)
    
    options+=("reflector" "(${txtoptional})" on)
    options+=("archlinux-keyring" "(${txtoptional})" on)
    options+=("cifs-utils" "(${txtoptional})" on)
    options+=("smbclient" "(${txtoptional})" on)
    options+=("nfs-utils" "(${txtoptional})" on)
    options+=("gvfs" "(${txtoptional})" off)
    options+=("gvfs-smb" "(${txtoptional})" off)

    sel=$(whiptail --backtitle "${apptitle}" --title "${txtinstallextrapkgs}" --checklist "" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	fi


	for itm in $sel; do
		pkgs="$pkgs $(echo $itm | sed 's/"//g')"
	done

    pkgs="$(echo $pkgs | sed 's/\s/_/g')"

	archchroot installextrapkgs "${pkgs}"
    
}

installextrapkgschroot(){
    
    if [ ! "${1}" = "none" ]; then
        clear
        pkgs="$(echo $1 | sed 's/_/ /g')"        
        echo "Install:"${pkgs}
        pacman -S --needed --noconfirm  ${pkgs}

        if [[ "${pkgs}" == *"haveged"* ]]; then		
            systemctl enable haveged
        fi
    fi
}

installdrivers(){
    pkgs=""
    options=()   
      
	options+=("xorg" "(${txtoptional})" on)
    options+=("xorg-xinit" "(${txtoptional})" on)
    options+=("xorg-server" "(${txtoptional})" off)
    

    options+=("networkmanager" "(${txtoptional})" on)
    options+=("pulseaudio" "(${txtoptional})" on)
    options+=("pulseaudio-bluetooth" "(${txtoptional})" on)
    options+=("bluez" "(${txtoptional})" on)
    options+=("bluedevil" "(${txtoptional})" on)
    options+=("powerdevil" "(${txtoptional})" off)

    options+=("xf86-video-intel" "(${txtoptional})" on)
    options+=("vulkan-intel" "(${txtoptional})" off)
    options+=("xf86-video-amdgpu" "(${txtoptional})" on)
    options+=("libva-mesa-driver " "(${txtoptional})" off)
    options+=("vulkan-radeon" "(${txtoptional})" off)
    options+=("mesa" "(${txtoptional})" off)

    options+=("xf86-input-libinput" "(${txtoptional})" on)

    options+=("xf86-video-vmware " "(${txtoptional})" off)




 

    sel=$(whiptail --backtitle "${apptitle}" --title "${txtdrivers}" --checklist "" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	fi
	for itm in $sel; do
		pkgs="$pkgs $(echo $itm | sed 's/"//g')"
	done

    pkgs="$(echo $pkgs | sed 's/\s/_/g')"

	archchroot installdrivers "${pkgs}"
}

installdriverschroot(){
    
    if [ ! "${1}" = "none" ]; then
        clear
        pkgs="$(echo $1 | sed 's/_/ /g')"        
        echo "Install:"${pkgs}
        pacman -S --needed --noconfirm  ${pkgs}

        if [[ "${pkgs}" == *"networkmanager"* ]]; then	
            print_line
            echo "networkmanager"	
            systemctl enable NetworkManager
        fi

        if [[ "${pkgs}" == *"bluez"* ]]; then	
             print_line
            echo "bluetooth"		
            systemctl enable bluetooth
        fi      
       

    fi
}

installmediacodecs(){
    pkgs=""
    options=()   

         
      
	options+=("gstreamer" "(${txtoptional})" on)
    options+=("gst-libav" "(${txtoptional})" on)
    options+=("gst-plugins-bad" "(${txtoptional})" off)
    options+=("gst-plugins-base" "(${txtoptional})" on)
    options+=("gst-plugins-good" "(${txtoptional})" on)
    
    options+=("gst-plugins-good" "(${txtoptional})" on)
    options+=("gst-plugins-ugly" "(${txtoptional})" off)
    
    options+=("gstreamer-vaapi" "(${txtoptional})" on)

    sel=$(whiptail --backtitle "${apptitle}" --title "${txtdrivers}" --checklist "" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	fi
	for itm in $sel; do
		pkgs="$pkgs $(echo $itm | sed 's/"//g')"
	done

    pkgs="$(echo $pkgs | sed 's/\s/_/g')"

	archchroot installmediacodecs "${pkgs}"
}

installfonts(){
    pkgs=""
    options=()   
      
	options+=("noto-fonts-cjk" "" on)
    options+=("noto-fonts-emoji" "" on)
    options+=("ttf-dejavu" "" on)
    options+=("ttf-hack" "" on)    

    options+=("wqy-microhei" "(${txtoptional})" off)
    options+=("wqy-microhei-lite" "(${txtoptional})" off)    
  
    sel=$(whiptail --backtitle "${apptitle}" --title "${txtdrivers}" --checklist "" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	fi
	for itm in $sel; do
		pkgs="$pkgs $(echo $itm | sed 's/"//g')"
	done

    pkgs="$(echo $pkgs | sed 's/\s/_/g')"

	archchroot installfonts "${pkgs}"
}

installkde(){
    pkgs=""
    options=() 

    options+=("plasma" "" on)
    
    options+=("plasma-wayland-session" "" off)
	options+=("plasma-desktop" "" off)
    options+=("kde-gtk-config" "" off)
    options+=("breeze-gtk" "" off)
    options+=("kscreen" "KDE's screen management software" off)        
    options+=("plasma-nm" "Plasma applet for managing network connections" off)
    options+=("plasma-pa" "Sound applet in the system tray" off)

    options+=("sddm" "" on)    
    options+=("sddm-kcm" "KDE Config Module for SDDM" on) 

    options+=("pacman-contrib" "(${txtoptional})" on)
    options+=("packagekit-qt5" "(${txtoptional})" on)
    options+=("discover" "(${txtoptional})" on)

    options+=("konsole" "(${txtoptional})" on)
    options+=("dolphin" "(${txtoptional})" on)    
    options+=("kdegraphics-thumbnailers" "Thumbnail generation(${txtoptional})" on)
    options+=("ffmpegthumbs" "Thumbnail generation(${txtoptional})" on)
    options+=("kate" "(${txtoptional})" on)
    options+=("inkscape" "(${txtoptional})" on)
    options+=("ark" "(${txtoptional})" on)
    options+=("kinfocenter" "info center(${txtoptional})" on)
    options+=("kwalletmanager" "(${txtoptional})" off)
    options+=("gwenview" "(${txtoptional})" on)
    options+=("kipi-plugins" "(${txtoptional})" on)
    options+=("spectacle" "(${txtoptional})" on)
    options+=("okular" "(${txtoptional})" on)
    options+=("vlc" "(${txtoptional})" on)
    options+=("kcalc" "(${txtoptional})" on)
    options+=("kruler" "(${txtoptional})" on)
    options+=("kompare" "(${txtoptional})" on)
    options+=("kdf" "(${txtoptional})" on)
    options+=("juk" "(${txtoptional})" on)
    options+=("sweeper" "(${txtoptional})" on)
    options+=("kcolorchooser" "(${txtoptional})" on)
    options+=("neofetch" "(${txtoptional})" on)
    options+=("htop" "(${txtoptional})" on)


  
    sel=$(whiptail --backtitle "${apptitle}" --title "${txtdrivers}" --checklist "" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	fi
	for itm in $sel; do
		pkgs="$pkgs $(echo $itm | sed 's/"//g')"
	done

    pkgs="$(echo $pkgs | sed 's/\s/_/g')"

	archchroot installkde "${pkgs}" "${USER_NAME}"

}


installkdechroot(){
    if [ ! "${1}" = "none" ]; then
        clear
        pkgs="$(echo $1 | sed 's/_/ /g')"        
        echo "Install:"${pkgs}
        pacman -S --needed --noconfirm  ${pkgs}

        if [[ "${pkgs}" == *"sddm"* ]]; then		
            systemctl enable sddm
        fi
    fi

    # # fix konsole
    # if [ ! "${2}" = "none" ]; then 
    #     mkdir /home/${2}/.local/share/kglobalaccel

    # fi  
   
}

installpkgchroot(){
    if [ ! "${1}" = "none" ]; then
        clear
        pkgs="$(echo $1 | sed 's/_/ /g')"        
        echo "Install:"${pkgs}
        pacman -S --needed --noconfirm  ${pkgs}
    fi
}

switchssdtrim() {
     if [ "${ISSSDTRIM}" = "on" ]; then
            ISSSDTRIM="off"
        else
            ISSSDTRIM="on"
        fi
    archchroot switchssdtrim $ISSSDTRIM
}

switchssdtrimchroot(){
    if [ ! "${1}" = "none" ]; then
        if [ "${1}" = "on" ]; then
            systemctl enable fstrim.timer
        else
            systemctl disable fstrim.timer
        fi
    fi
}

swappinesschroot(){
    echo "Change swappiness >> 10" 
    echo "vm.swappiness=10" |sudo tee -a /etc/sysctl.d/99-swappiness.conf
}

installyay(){
    archchroot installyay $USER_NAME
}

installyaychroot(){
    if [ ! "${1}" = "none" ]; then
        cd /home/${1}
        sudo -u ${1} git clone https://aur.archlinux.org/yay.git
        cd yay
        sudo -u ${1} makepkg -si
    fi
}

configSmbShare(){
    archchroot configSmbShare $USER_NAME
}

configSmbSharechroot(){
    if [ ! "${1}" = "none" ]; then
        mkdir -p /media/smb
        chown -R ${1} /media/smb

        sudo -u ${1} mkdir -p /media/smb/omvnas/me
        sudo -u ${1} mkdir -p /media/smb/omvnas/kid
        sudo -u ${1} mkdir -p /media/smb/omvnas/share
        sudo -u ${1} mkdir -p /media/smb/openwrt/share

        echo '10.10.10.1	openwrt' | tee -a /etc/hosts
        echo '10.10.10.3	omvnas' | tee -a /etc/hosts
        

        echo '//omvnas/share /media/smb/omvnas/share cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' | tee -a /etc/fstab
        echo '//omvnas/me /media/smb/omvnas/me cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' | tee -a /etc/fstab
        echo '//omvnas/kid /media/smb/omvnas/kid cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' | tee -a /etc/fstab
        echo '//openwrt/share /media/smb/openwrt/share cifs  username=root,password=0928,vers=2.0,noauto,user 0 0' | tee -a /etc/fstab

        
    
    fi
}

sethosts(){
    archchroot sethosts ${HOSTNAME}
}

sethostschroot(){
    if [ ! "${1}" = "none" ]; then
        echo '127.0.0.1  localhost' | tee -a /etc/hosts
        echo '::1        localhost' | tee -a /etc/hosts
        echo '127.0.1.1    '${1}'.localdomain '${1} | tee -a /etc/hosts
        cat /etc/hosts
    fi

}

fixkonsoleshortcutchroot(){
    if [ ! "${1}" = "none" ]; then
        sudo -u ${1} mkdir -p /home/${1}/.local/share/kglobalaccel
    fi
}

fixcjkchroot(){
    echo '<?xml version="1.0"?>' > /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '<fontconfig>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '  <alias>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '    <family>sans-serif</family>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '    <prefer>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '      <family>Noto Sans CJK SC</family>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '      <family>Noto Sans CJK TC</family>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '      <family>Noto Sans CJK JP</family>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '    </prefer>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '  </alias>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '  <alias>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '    <family>monospace</family>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '    <prefer>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '      <family>Noto Sans Mono CJK SC</family>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '      <family>Noto Sans Mono CJK TC</family>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '      <family>Noto Sans Mono CJK JP</family>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '    </prefer>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '  </alias>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    echo '</fontconfig>' >> /etc/fonts/conf.d/64-language-selector-prefer.conf
    cat /etc/fonts/conf.d/64-language-selector-prefer.conf
}

installsoftware(){
    pkgs=""
    options=()   
      
	options+=("fcitx5" "(${txtoptional})" on)
    options+=("dropbox" "(${txtoptional})" on)
    options+=("transmission-remote-gtk" "(${txtoptional})" on)
    options+=("google-chrome" "(${txtoptional})" on)
    options+=("firefox" "(${txtoptional})" off)
    options+=("typora" "(${txtoptional})" on)
    options+=("visual-studio-code" "(${txtoptional})" on)
    options+=("vmware" "(${txtoptional})" off)
    
    
    options+=("xdman" "mail(${txtoptional})" off)
    options+=("thunderbird" "mail(${txtoptional})" off)
    options+=("celluloid" "multimedia(${txtoptional})" off)
    options+=("libreoffice" "(${txtoptional})" off)
    options+=("grsync" "(${txtoptional})" off)
    options+=("calibre" "(${txtoptional})" off)
    options+=("exa" "(${txtoptional})" off)

    options+=("kcm-colorful-git" "(${txtoptional})" off)
    options+=("breeze-blurred-git" "(${txtoptional})" off)
     
    
    

    sel=$(whiptail --backtitle "${apptitle}" --title "${txtdrivers}" --checklist "" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	fi
	for itm in $sel; do
		pkgs="$pkgs $(echo $itm | sed 's/"//g')"
	done

    pkgs="$(echo $pkgs | sed 's/\s/_/g')"

	archchroot installsoftware "${pkgs}" $USER_NAME
}

installsoftwarechroot(){
    if [ ! "${1}" = "none" ] &&  [ ! "${2}" = "none" ]; then
        clear
        if [[ "${1}" == *"fcitx5"* ]]; then		
            
            sudo -u ${2} yay -S --needed fictx5 fcitx5-chinese-addons kcm-fcitx5 fcitx5-qt fcitx5-gtk fcitx5-material-color
            print_line 
            sudo -u ${2} echo "export GTK_IM_MODULE=fcitx5" >> /home/${2}/.xprofile
            sudo -u ${2} echo "export XMODIFIERS=@im=fcitx5" >> /home/${2}/.xprofile
            sudo -u ${2} echo "export QT_IM_MODULE=fcitx5" >> /home/${2}/.xprofile
            sudo -u ${2} echo "fcitx5 &" >> /home/${2}/.xprofile


            # print_line 
            # echo "GTK_IM_MODULE=fcitx5" >> /etc/enviroment
            # echo "XMODIFIERS=@im=fcitx5" >> /etc/enviroment
            # echo "QT_IM_MODULE=fcitx5" >> /etc/enviroment

            # sudo -u ${2} echo "[Desktop Entry]" > ~/.config/autostart
            # sudo -u ${2} echo "Categories=System;Utility;" >> ~/.config/autostart
            # sudo -u ${2} echo "Comment=Start Input Method" >> ~/.config/autostart
            # sudo -u ${2} echo "Exec=/usr/bin/fcitx5" >> ~/.config/autostart
            # sudo -u ${2} echo "GenericName=Input Method" >> ~/.config/autostart
            # sudo -u ${2} echo "Icon=fcitx" >> ~/.config/autostart
            # sudo -u ${2} echo "Name=Fcitx 5" >> ~/.config/autostart
            # sudo -u ${2} echo "StartupNotify=false" >> ~/.config/autostart
            # sudo -u ${2} echo "Terminal=false" >> ~/.config/autostart
            # sudo -u ${2} echo "Type=Application" >> ~/.config/autostart
            # sudo -u ${2} echo "X-GNOME-AutoRestart=false" >> ~/.config/autostart
            # sudo -u ${2} echo "X-GNOME-Autostart-Notify=false" >> ~/.config/autostart
            # sudo -u ${2} echo "X-KDE-StartupNotify=false" >> ~/.config/autostart
            # sudo -u ${2} echo "X-KDE-autostart-after=panel" >> ~/.config/autostart

        fi

        if [[ "${1}" == *"dropbox"* ]]; then	
            cd /home/${2}
            sudo -u ${2} curl -L https://linux.dropbox.com/fedora/rpm-public-key.asc > rpm-public-key.asc
            sudo -u ${2} gpg --import rpm-public-key.asc
            sudo -u ${2} yay -S --needed dropbox

        fi      

        if [[ "${1}" == *"transmission-remote-gtk"* ]]; then	
            cd /home/${2}
            sudo -u ${2} yay -S --needed transmission-remote-gtk

        fi

        if [[ "${1}" == *"google-chrome"* ]]; then	
            cd /home/${2}
            sudo -u ${2} yay -S --needed google-chrome

        fi

        if [[ "${1}" == *"firefox"* ]]; then	
            cd /home/${2}
            pacman -S --needed --noconfirm firefox

        fi

        if [[ "${1}" == *"typora"* ]]; then	
            cd /home/${2}
            sudo -u ${2} yay -S --needed typora

        fi

        if [[ "${1}" == *"visual-studio-code"* ]]; then	
            cd /home/${2}
            sudo -u ${2} yay -S --needed visual-studio-code-bin

        fi

        if [[ "${1}" == *"vmware"* ]]; then	
            cd /home/${2}
            pacman -S --needed --noconfirm fuse2 gtkmm linux-headers libcanberra pcsclite
            sudo -u ${2} yay -S ncurses5-compat-libs
            sudo -u ${2} yay -S vmware-workstation
            systemctl enable vmware-networks.service
            modprobe -a vmw_vmci vmmon
            echo 'mks.gl.allowBlacklistedDrivers = "TRUE"' >> /home/${2}/.vmware/preferences
        fi
        
        if [[ "${1}" == *"thunderbird"* ]]; then	
            pacman -S --needed --noconfirm thunderbird thunderbird-i18n-zh-cn

        fi

        if [[ "${1}" == *"celluloid"* ]]; then	
            pacman -S --needed --noconfirm celluloid
        fi
        
        if [[ "${1}" == *"libreoffice"* ]]; then	
            cd /home/${2}
            sudo -u ${2} yay -S --needed libreoffice-fresh ttf-ms-fonts

        fi

        if [[ "${1}" == *"xdman"* ]]; then	
            cd /home/${2}
            sudo -u ${2} yay -S --needed xdman

        fi

        if [[ "${1}" == *"grsync"* ]]; then	
            pacman -S --needed --noconfirm grsync
        fi

        if [[ "${1}" == *"calibre"* ]]; then	
            sudo -u ${2} yay -S --needed calibre
        fi

        if [[ "${1}" == *"exa"* ]]; then	
            pacman -S --needed --noconfirm --needed exa

            echo "alias ll='exa -gl --time-style long-iso --group-directories-first'" >> /home/${2}/.bashrc
        fi

        if [[ "${1}" == *"kcm-colorful-git"* ]]; then	
            sudo -u ${2} yay -S --kcm-colorful-git
        fi

        if [[ "${1}" == *"breeze-blurred-git"* ]]; then	
            sudo -u ${2} yay -S --breeze-blurred-git
        fi


    fi
}


basemenu(){

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
    options+=("${txthosts}" "/etc/hosts")

    options+=("${txtsetrootpassword}" "${ROOT_PASSWORD}")
    options+=("${txtadduser}" "User:${USER_NAME} Password:${USER_PASSWORD}")  

    options+=("${txtbootloader}" "")

    sel=$(whiptail --backtitle "${apptitle}" --title "Select to Run" --menu "" --cancel-button "cancle" --default-item "${nextitem}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
		
    if [ "$?" = "0" ]; then
       case ${sel} in
            "${txtselectmirrors}")
                clear	
				select_mirrors
				pressanykey
				nextitem="${txtselectdevice}"
				;;
            "${txtselectdevice}")
                clear
				select_device
                lsblk
				pressanykey
				nextitem="${txtinitdevice}"
				;;
            "${txtinitdevice}")	
                clear
				init_device
                lsblk
				pressanykey
				nextitem="${txtpartiondevice}"
				;;  
            "${txtpartiondevice}")	
                clear
				partionsdevice
                lsblk
				pressanykey
				nextitem="${txtselectpartion}"
				;;
            "${txtselectpartion}")	
                clear
				select_partion
                lsblk
				pressanykey
				nextitem="${txtformatparts}"
				;;
            "${txtformatparts}")
                clear	
				formatparts
                lsblk
				pressanykey
				nextitem="${txtinstallbasepkg}"
				;; 
            
            "${txtinstallbasepkg}")
                clear
                install_basepkg
                pressanykey
                nextitem="${txtgenfstab}"
                ;;

            "${txtgenfstab}")
                clear
                gen_fstab
                pressanykey
                nextitem="${txtmakeswap}"
                ;;
            "${txtmakeswap}")
                clear
                makeswap
                pressanykey
                nextitem="${txtsethostname}"
                ;;

            "${txtsethostname}")
                clear
				archsethostname
                pressanykey
				nextitem="${txtgenlocale}"
			;;
		
			"${txtgenlocale}")
                clear
				archgenlocale
                pressanykey
				nextitem="${txtsettime}"
			;;

            
            
			
			"${txtsettime}")
                clear
				archchroot settime
                pressanykey
				nextitem="${txthosts}"
			;;

            "${txthosts}")
                clear
				sethosts
                pressanykey
				nextitem="${txtsetrootpassword}"
			;;

            "${txtsetrootpassword}")
                clear
				setrootpasswd
                pressanykey
				nextitem="${txtadduser}"
			;;
            "${txtadduser}")
                clear
				adduser
                pressanykey
				nextitem="${txtbootloader}"
			;;
            "${txtbootloader}")
                clear
				archchroot setbootloader
                pressanykey
				nextitem="${txtbootloader}"
			;;
        esac
		basemenu "${nextitem}"
    fi
}

addarchlinuxcnchroot(){
    echo "Configing Archlinuxcn"

    if [ "$(cat /etc/pacman.conf | grep "[archlinuxcn]")" != "" ]; then
        sed -i 's/^\[archlinuxcn\]$//g' /etc/pacman.conf 
        sed -i 's/^Server = https\:\/\/mirrors\.bfsu\.edu\.cn.*arch$//g' /etc/pacman.conf 
        
    fi

    echo "[archlinuxcn]" | tee -a /etc/pacman.conf
    echo "Server = https://mirrors.bfsu.edu.cn/archlinuxcn/\$arch" | tee -a /etc/pacman.conf
    pacman -Syy --noconfirm
    pacman -S archlinuxcn-keyring --noconfirm
    pacman -S pacman-key --populate archlinuxcn --noconfirm
    pacman -Syyy --noconfirm
}

fixkeyringchroot(){
    rm -rf /etc/pacman.d/gnupg
    pacman-key --init
    pacman-key --populate archlinux
    pacman -Syyy --noconfirm
}

archlinuxcnmenu(){
    if [ "${1}" = "" ]; then
		nextitem="."
	else
		nextitem=${1}
	fi  

    options=()
    options+=("${txtinstallyay}" "")
	options+=("${txtaddarchlinuxcn}" "")
    options+=("${txtfixkeyring}" "")

    sel=$(whiptail --backtitle "${apptitle}" --title "Select to Run" --menu "" --cancel-button "cancle" --default-item "${nextitem}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
    if [ "$?" = "0" ]; then
       case ${sel} in

            "${txtinstallyay}")
                clear
				installyay
                pressanykey
				nextitem="${txtinstallyay}"
			;; 

            "${txtaddarchlinuxcn}")
                archchroot addarchlinuxcn
                pressanykey
				nextitem="${txtaddarchlinuxcn}"
			;;
            "${txtfixkeyring}")
                archchroot fixkeyring
                pressanykey
				nextitem="${txtfixkeyring}"
			;;
        esac
		archlinuxcnmenu "${nextitem}"
    fi
}

desktopmenu(){
    if [ "${1}" = "" ]; then
		nextitem="."
	else
		nextitem=${1}
	fi    

    options=()
	options+=("${txtinstallextrapkgs}" "")
    options+=("${txtdrivers}" "")
    options+=("${txtinstallmediacodecs}" "")
    options+=("${txtinstallfonts}" "")
    options+=("${txtswitchssdtrim}" "$ISSSDTRIM")

    options+=("${txtinstallkde}" "")

    options+=("${txtswappiness}" "")
    # options+=("${txtinstallyay}" "")
    options+=("${txtconfigSmbShare}" "")
    options+=("${txtfixkonsoleshortcut}" "")
    options+=("${txtfixcjk}" "")
    options+=("${txtarchlinuxcn}" "")
    

    options+=("${txtinstallsoftware}" "")
    

    sel=$(whiptail --backtitle "${apptitle}" --title "Select to Run" --menu "" --cancel-button "cancle" --default-item "${nextitem}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
		
    if [ "$?" = "0" ]; then
       case ${sel} in
             "${txtinstallextrapkgs}")
                clear
				installextrapkgs
                pressanykey
				nextitem="${txtdrivers}"
			;;
            
            "${txtdrivers}")
                clear
				installdrivers
                pressanykey
				nextitem="${txtinstallmediacodecs}"
			;;
            
            "${txtinstallmediacodecs}")
                clear
				installmediacodecs
                pressanykey
				nextitem="${txtinstallfonts}"
			;;

            "${txtinstallfonts}")
                clear
				installfonts
                pressanykey
				nextitem="${txtswitchssdtrim}"
			;;
            "${txtswitchssdtrim}")
                clear
				switchssdtrim
                pressanykey
				nextitem="${txtinstallkde}"
			;; 
            "${txtinstallkde}")
                clear
				installkde
                pressanykey
				nextitem="${txtswappiness}"
			;; 
            "${txtswappiness}")
                clear
				archchroot swappiness
                pressanykey
				nextitem="${txtconfigSmbShare}"
			;; 
            # "${txtinstallyay}")
            #     clear
			# 	installyay
            #     pressanykey
			# 	nextitem="${txtconfigSmbShare}"
			# ;; 
            
            "${txtconfigSmbShare}")
                clear				
                configSmbShare
                pressanykey
				nextitem="${txtfixkonsoleshortcut}"
			;; 

            "${txtfixkonsoleshortcut}")
                clear				
                archchroot fixkonsoleshortcut $USER_NAME
                pressanykey
				nextitem="${txtfixcjk}"
			;; 

            "${txtfixcjk}")
                clear
                archchroot fixcjk				
                pressanykey
				nextitem="${txtarchlinuxcn}"
			;; 

            "${txtarchlinuxcn}")
                clear				
                archlinuxcnmenu                
				nextitem="${txtinstallsoftware}"
			;; 

            
            "${txtinstallsoftware}")
                clear				
                installsoftware
                pressanykey
				nextitem="${txtinstallsoftware}"
			;; 


            

        esac
		desktopmenu "${nextitem}"
    fi

}

# softmenu(){

# }

archmenu(){
	if [ "${1}" = "" ]; then
		nextitem="."
	else
		nextitem=${1}
	fi    

	options=()

    options+=("${txtbaseinstall}" "")

	
    options+=("${txtdeskinstall}" "")
        
    
    options+=("" "")    
    options+=("${txtunmount}" "")
    options+=("${txtreboot}" "")
    
	sel=$(whiptail --backtitle "${apptitle}" --title "Select to Run" --menu "" --cancel-button "cancle" --default-item "${nextitem}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
		
    if [ "$?" = "0" ]; then
       
		case ${sel} in
            

            "${txtbaseinstall}")
                # clear	
                basemenu
                nextitem="${txtdeskinstall}"
                ;;

            "${txtdeskinstall}")
                # clear
				desktopmenu
                # pressanykey
				nextitem="${txtunmount}"
			;;


            "${txtunmount}")
                unmountdevices
                pressanykey
                nextitem="${txtreboot}"
                ;;
            "${txtreboot}")
                reboot
                ;;          
             
		esac
		archmenu "${nextitem}"
	fi
}

while (( "$#" )); do
	case ${1} in		
		--chroot) chroot=1
							command=${2}
							arg1=${3}
                            arg2=${4};;
	esac
	shift
done

if [ "${chroot}" = "1" ]; then
	case ${command} in
        'makeswap') archsetswap ${arg1};;
        'genlocale') archgenlocalechroot;;
        'settime') archsettimechroot;;
        'sethosts') sethostschroot ${arg1};;
        'setrootpasswd') archsetrootpasswdchroot ${arg1};;
        'adduser') archadduserchroot ${arg1} ${arg2};;
        'setbootloader') setbootloaderchroot;;
        'installextrapkgs') installextrapkgschroot ${arg1};;
        'installdrivers') installdriverschroot ${arg1};;
        'installmediacodecs') installpkgchroot ${arg1};;
        'installfonts') installpkgchroot ${arg1};;
        'switchssdtrim') switchssdtrimchroot ${arg1};;
        'installkde') installkdechroot ${arg1} ${arg2};;
        'swappiness') swappinesschroot;;
        'installyay') installyaychroot ${arg1};;
        'configSmbShare') configSmbSharechroot ${arg1};;
        'fixkonsoleshortcut') fixkonsoleshortcutchroot ${arg1};;
        'fixcjk') fixcjkchroot;;
        'installsoftware') installsoftwarechroot ${arg1} ${arg2};;
        
        'addarchlinuxcn') addarchlinuxcnchroot;;
        'fixkeyring') fixkeyringchroot;;
        
        
	esac
else
	loadstrings
    echo "Pre-Install"
    preinstalll
	archmenu
fi

exit 0

