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

UEFI_BOOT_TYPE="systemd"
UEFI_BIOS_TEXT="Boot Not Detected"
INSTALL_DEVICE=
MIRRORLIST_COUNTRY="CN"
SWAP_COUNT="8192"
LOCALE_UTF8="en_US.UTF-8"
ZONE="Asia"
SUBZONE="Shanghai"
HOSTNAME="arch-nuc"
ROOT_PASSWORD="0928"
USER_NAME="syaofox"
USER_PASSWORD="0928"

MOUNT_POINT="/mnt"

IS_NVME="no"

function print_line() {
    printf "%$(tput cols)s\n" | tr ' ' '-'
}

function print_error() { 
    T_COLS=`tput cols`
    echo -e "\n\n${BRed}$1${Reset}\n" | fold -sw $(( $T_COLS - 1 ))
    sleep 3
    return 1
}

function print_title() {
    clear
    print_line
    echo -e "# ${Bold}$1${Reset}"
    print_line
    echo ""
}

function pause() {
    print_line
    read -e -sn 1 -p "Press enter to continue..."
}

function print_info() {
    T_COLS=`tput cols`
    echo -e "${Bold}$1${Reset}\n" | fold -sw $(( $T_COLS - 18)) | sed 's/^/\t/'
}

function read_input_options() {
    local line
    local packages

    if [[ ! $@ ]]; then
        read -p "${PROMPT_2}" OPTION
    else
        OPTION=$@
    fi
    array=(${OPTION})

    for line in ${array[@]/,/ }; do
        if [[ ${line/-/} != ${line} ]]; then
            for (( i=${line%-*}; i <= ${line#*-}; i++ )); do
                packages+={$i};
            done
        else
            packages+=($line)
        fi
    done

    OPTIONS=(${packages[@]})
}

function contains_element() {
    for e in in "${@:2}"; do [[ ${e} == ${1} ]] && break; done;
}

function unique_elements() {
    RESULT_UNIQUE_ELEMENTS=($(echo $@ | tr ' ' '\n' | sort -u | tr '\n' ' '))
}

function confirm_operation() {
    read -p "${BYellow}$1 [y/N]: ${Reset}" OPTION
    OPTION=`echo "${OPTION}" | tr '[:upper:]' '[:lower:]'`    
}

function uefi_bios_detect() {
    if [[ "$(cat /sys/class/dmi/id/sys_vendor)" == 'Apple Inc.' ]] || [[ "$(cat /sys/class/dmi/id/sys_vendor)" == 'Apple Computer, Inc.' ]]; then
        modprobe -r -q efivars || true  # if MAC
    else
        modprobe -q efivarfs            # all others
    fi

    if [[ -d "/sys/firmware/efi/" ]]; then
        ## Mount efivarfs if it is not already mounted
        if [[ -z $(mount | grep /sys/firmware/efi/efivars) ]]; then
            mount -t efivarfs efivarfs /sys/firmware/efi/efivars
        fi
        UEFI_BIOS_TEXT="UEFI detected"
    else
        UEFI_BIOS_TEXT="BIOS detected"
    fi
}

function check_nvme(){
    if [[ "$(lsblk | grep nvme)" != "" ]]; then
        IS_NVME="yes"
    else
        IS_NVME="no"
    fi
}

function invalid_option() {
    print_line
    echo "${BRed}Invalid option, Try another one.${Reset}"
    pause
}

function checkbox() { 
    #display [X] or [ ]
    [[ "$1" -eq 1 ]] && echo -e "${BBlue}[${Reset}${Bold}X${BBlue}]${Reset}" || echo -e "${BBlue}[ ${BBlue}]${Reset}";
}

function mainmenu_item() { 
    #if the task is done make sure we get the state
    if  [[ $3 != "" ]] && [[ $3 != "/" ]]; then    
        state="${BGreen}[${Reset}$3${BGreen}]${Reset}"
    else
        state="${BGreen}[${Reset}Not Set${BGreen}]${Reset}"
    fi
    echo -e "$(checkbox "$1") ${Bold}$2${Reset} ${state}"
} 

function arch_chroot() {
    arch-chroot ${MOUNT_POINT} "/bin/bash" -c "${1}"
}

function set_mirrors(){
    echo "Server = https://mirrors.bfsu.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
    pacman -Syyy --noconfirm
    pacman -S  --needed reflector --noconfirm
    #MIRRORLIST_COUNTRY=CN
   #read -p "Input your country:" MIRRORLIST_COUNTRY

    
    reflector --verbose -c ${MIRRORLIST_COUNTRY} --sort rate  -a 6 -p https --save /etc/pacman.d/mirrorlist
    # Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch
    pacman -Syyy --noconfirm
}

function select_device() {
    local devices_list=(`lsblk -d | awk 'NR>1 { print "/dev/" $1 }'`)
    PS3=${PROMPT_1}
    echo -e "Select device to install Arch Linux:\n"
    select device in "${devices_list[@]}"; do
        if contains_element ${device} ${devices_list[@]}; then 
            confirm_operation "Data on ${device} will be damaged"
            break
        else
            invalid_option
        fi
    done

    if [[ ${OPTION} == "y" ]] || [[ ${OPTION} == "" ]];  then
        INSTALL_DEVICE=${device}
        return 0
    fi

    return 1
}

function set_password() {
    while true; do
        read -s -p "Password for $1: " password1
        echo
        read -s -p "Confirm the password: " password2
        echo
        if [[ ${password1} == ${password2} ]]; then
            eval $2=${password1}
            break
        fi
        echo "Please try again"
    done 
}

function set_root_password() {
    set_password root ROOT_PASSWORD
    if [[ ! ${ROOT_PASSWORD} ]]; then
        return 1
    fi
}

function set_login_user() {
    local result
    read -p "Input login user name[ex: ${USER_NAME}]: " result
    if [[ ! -z ${result} ]]; then 
        USER_NAME=${result}
    fi
    
    set_password ${USER_NAME} USER_PASSWORD ${USER_PASSWORD}
}

function Set_SwapfileSize(){
    read -p "Input SwapfileCount(M):" SWAP_COUNT
}

function set_hostname() {
    local result
    read -p "Input your Hostname[ex: ${HOSTNAME}}]: " result
    if [[ ! -z ${result} ]]; then 
        HOSTNAME=${result}
    fi
}

function set_uefi_boot_type(){
    #local result
    #read -p "Input efi boot type[ex: ${UEFI_BOOT_TYPE}}]: " result
    #if [[ ! -z ${result} ]]; then 
    #    UEFI_BOOT_TYPE=${result}
    #fi

   local boot_types=("systemd" "grub" )
    PS3=${PROMPT_1}
    echo -e "Select efi boot type:\n"
    select bootrype in "${boot_types[@]}"; do
        if contains_element ${bootrype} ${boot_types[@]}; then 
            UEFI_BOOT_TYPE=$bootrype
            break
        else
            invalid_option
        fi
      
    done

}



function format_devices() {
    # TODO 
    # Support LVM?
    sgdisk --zap-all ${INSTALL_DEVICE}
    local boot_partion="${INSTALL_DEVICE}1"
    local system_partion="${INSTALL_DEVICE}2"

    if [ ${IS_NVME} == "yes" ]; then
        boot_partion="${INSTALL_DEVICE}p1"
        system_partion="${INSTALL_DEVICE}p2"
    fi

    [[ ${UEFI_BIOS_TEXT} == "Boot Not Detected" ]] && print_error "Boot method isn't be detected!"
    [[ ${UEFI_BIOS_TEXT} == "UEFI detected" ]] && printf "n\n1\n\n+512M\nef00\nw\ny\n" | gdisk ${INSTALL_DEVICE} && yes | mkfs.fat -F32 ${boot_partion}
    [[ ${UEFI_BIOS_TEXT} == "BIOS detected" ]] && printf "n\n1\n\n+2M\nef02\nw\ny\n" | gdisk ${INSTALL_DEVICE} && yes | mkfs.ext2 ${boot_partion}

    printf "n\n2\n\n\n8300\nw\ny\n"| gdisk ${INSTALL_DEVICE}
    yes | mkfs.ext4  -L archroot  ${system_partion}

    mount ${system_partion} /mnt
    
    if [[ ${UEFI_BIOS_TEXT} == "UEFI detected" ]] ; then
        if [[ ${UEFI_BOOT_TYPE} = "grub" ]]; then
            mkdir -p /mnt/boot/efi && mount ${boot_partion} /mnt/boot/efi
       elif  [[ ${UEFI_BOOT_TYPE} = "systemd" ]]; then
            mkdir -p /mnt/boot && mount ${boot_partion} /mnt/boot
       fi
    fi
}

function make_swap() {   
    dd if=/dev/zero of=/mnt/swapfile bs=1M count=${SWAP_COUNT} status=progress #8G
    chmod 600 /mnt/swapfile
    mkswap /mnt/swapfile
    swapon /mnt/swapfile
    echo >> /mnt/etc/fstab
    echo "# Swapfile" >> /mnt/etc/fstab
    echo "/swapfile none swap defaults 0 0" >> /mnt/etc/fstab
}

function configure_locale() {
    arch_chroot "sed -i 's/#\(${LOCALE_UTF8}\)/\1/' /etc/locale.gen"
    arch_chroot "sed -i 's/#\(zh_CN.UTF-8\)/\1/' /etc/locale.gen"
    arch_chroot "sed -i 's/#\(zh_HK.UTF-8\)/\1/' /etc/locale.gen"
    arch_chroot "sed -i 's/#\(zh_TW.UTF-8\)/\1/' /etc/locale.gen"

    echo "LANG=${LOCALE_UTF8}" > "${MOUNT_POINT}/etc/locale.conf"
    arch_chroot "locale-gen"
}

function configure_timezone() {
    print_title "TIMEZONE - https://wiki.archlinux.org/index.php/Timezone"
    print_info "In an operating system the time (clock) is determined by four parts: Time value, Time standard, Time Zone, and DST (Daylight Saving Time if applicable)."

    arch_chroot "ln -sf /usr/share/zoneinfo/${ZONE}/${SUBZONE} /etc/localtime"
    #arch_chroot "sed -i '/#NTP=/d' /etc/systemd/timesyncd.conf"
    #arch_chroot "sed -i 's/#Fallback//' /etc/systemd/timesyncd.conf"
    #arch_chroot "echo \"FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org\" >> /etc/systemd/timesyncd.conf"
    arch_chroot "systemctl enable systemd-timesyncd.service"
    arch_chroot "hwclock --systohc ---utc"
}

function configure_hostname() {
    echo "${HOSTNAME}" > "${MOUNT_POINT}/etc/hostname"

    arch_chroot "echo '127.0.0.1  localhost' >> /etc/hosts"
    arch_chroot "echo '::1        localhost' >> /etc/hosts"
    arch_chroot "echo '127.0.1.1    ${HOSTNAME}.localdomain ${HOSTNAME}' >> /etc/hosts"
}

function configure_network(){
    arch_chroot "pacman -S --needed networkmanager network-manager-applet --noconfirm"
    arch_chroot "systemctl enable NetworkManager"
    arch_chroot "systemctl disable dhcpcd"

}

function configure_user() {
    arch_chroot "echo 'root:${ROOT_PASSWORD}' | chpasswd"
    arch_chroot "useradd -m -G wheel ${USER_NAME} && echo '${USER_NAME}:${USER_PASSWORD}' | chpasswd"
    arch_chroot "echo '${USER_NAME} ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo"
}

function bootloader_uefi() {
     if [[ ${UEFI_BOOT_TYPE} = "grub" ]]; then
            bootloader_uefi_grub
       elif  [[ ${UEFI_BOOT_TYPE} = "systemd" ]]; then
            bootloader_uefi_systemd
       fi
}

function bootloader_uefi_grub() {

    arch_chroot "pacman -S efibootmgr grub --noconfirm"
    arch_chroot "grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi"
    arch_chroot "mkdir -p /boot/efi/EFI/BOOT"
    arch_chroot "cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI"
    arch_chroot "echo 'bcf boot add 1 fs0:\EFI\grubx64.efi \"My GRUB bootloader\" && exit' > /boot/efi/startup.sh"
    arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
}

function bootloader_bios() {
     arch_chroot "pacman -S grub --noconfirm"
    arch_chroot "grub-install ${INSTALL_DEVICE}"
    arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
}

function bootloader_uefi_systemd(){
    arch_chroot "pacman -S efibootmgr --noconfirm"
    arch_chroot "bootctl install"
    sed -i '/#timeout 3/s/^#//g' /mnt/boot/loader/loader.conf
    echo "title Arch Linux" >> /mnt/boot/loader/entries/arch.conf
    echo "linux /vmlinuz-linux-lts" >> /mnt/boot/loader/entries/arch.conf
    echo "initrd /intel-ucode.img" >> /mnt/boot/loader/entries/arch.conf
    echo "initrd /initramfs-linux-lts.img" >> /mnt/boot/loader/entries/arch.conf
    partuuid=$(blkid | grep archroot | sed -r 's/.*?PARTUUID=\"(.*?)\"/\1/g')
    echo "options root=\"PARTUUID=${partuuid}\" rw" >> /mnt/boot/loader/entries/arch.conf
}

function bootloader_install() {
    case ${UEFI_BIOS_TEXT} in
        "UEFI detected") bootloader_uefi;;
        "BIOS detected") bootloader_bios;;
        *) print_error "Bootloader isn't detected.";;
    esac
}

function system_install() {
    format_devices
    #configure_mirrorlist

    timedatectl set-ntp true

    # Install system-base
    yes '' | pacstrap -i /mnt base base-devel linux-lts linux-lts-headers linux-firmware pacman-contrib intel-ucode sudo vim git dnsutils openssh
    yes '' | genfstab -U /mnt >> /mnt/etc/fstab

    # swap file
    make_swap
    configure_locale
    configure_timezone
    configure_hostname
    configure_network
    configure_user

    bootloader_install
    umount -R ${MOUNT_POINT}
    #arch_chroot "systemctl enable dhcpcd sshd"
}

function install() {

     if [[ ${INSTALL_DEVICE} = "grub" ]]; then
        echo "havenot choose instal divice"
         exit
    fi


    confirm_operation "Operation is irreversible, Are you sure?"
    if [[ ${OPTION} = "y" ]] || [[ ${OPTION} == "" ]];  then
        system_install

        print_line
        confirm_operation "Do you want to reboot system?"
        if [[ ${OPTION} == "y" ]] || [[ ${OPTION} == "" ]];  then
           reboot 
        fi
        exit 0
    else
        return
    fi
}

if (( $EUID != 0 )); then
    print_line
    echo "Please run as root"
    exit
fi

uefi_bios_detect
check_nvme
#pause
checklist=( 0 0 0 0 0 0 0 )

while true; do
    print_title "ARCHLINUX ULTIMATE INSTALL "
    echo " ${UEFI_BIOS_TEXT}"
    echo " nvmedisk ${IS_NVME}"
    echo ""
    echo " 1) $(mainmenu_item "${checklist[1]}"  "Set Mirrors"             "${MIRRORLIST_COUNTRY}" )"
    echo " 2) $(mainmenu_item "${checklist[2]}"  "Select Device"              "${INSTALL_DEVICE}" )"
    echo " 3) $(mainmenu_item "${checklist[3]}"  "Set SwapfileSize"              "${SWAP_COUNT}M" )"
    echo " 4) $(mainmenu_item "${checklist[4]}"  "Set Hostname"              "${HOSTNAME}" )"
    echo " 5) $(mainmenu_item "${checklist[5]}"  "Set Root Password"          "${ROOT_PASSWORD}" )"
    echo " 6) $(mainmenu_item "${checklist[6]}"  "Set Login User"             "${USER_NAME}/${USER_PASSWORD}" )"
    echo " 7) $(mainmenu_item "${checklist[7]}"  "Set UEFI boot type"             "${UEFI_BOOT_TYPE}" )"
    
    echo ""
    echo " i) install"
    echo " q) quit"
    echo ""

    read_input_options
    for OPT in ${OPTIONS[@]}; do
        case ${OPT} in
            1) set_mirrors && checklist[1]=1;;
            2) select_device && checklist[2]=1;;
            3) Set_SwapfileSize && checklist[3]=1;;
            4) set_hostname && checklist[4]=1;;
            5) set_root_password && checklist[5]=1;;
            6) set_login_user && checklist[6]=1;;
            7) set_uefi_boot_type && checklist[7]=1;;
            "i") install;;
            "q") exit 0;;
            *) invalid_option;;
        esac
    done
done