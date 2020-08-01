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
    echo "Server = https://mirrors.bfsu.edu.cn/archlinux/\$repo/os/\$arch" |sudo tee -a /etc/pacman.d/mirrorlist
    sudo pacman -Syyy --noconfirm
    sudo pacman -S  --needed reflector --noconfirm
    #MIRRORLIST_COUNTRY=CN
   #read -p "Input your country:" MIRRORLIST_COUNTRY

    
    sudo reflector --verbose -c ${MIRRORLIST_COUNTRY} --sort rate  -a 6 -p https --save /etc/pacman.d/mirrorlist
    # Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch
    sudo pacman -Syyy --noconfirm
}

function set_intel() {
    local result
    confirm_operation "Do you want to Install Intel Graphics Driver?"
        if [[ ${OPTION} == "y" ]] || [[ ${OPTION} == "" ]]; then
           INTEL_GRAPHICS_DRIVER="yes" 
        else
            INTEL_GRAPHICS_DRIVER="no" 
        fi
}

function set_amd() {
    local result
    confirm_operation "Do you want to Install Amd Graphics Driver?"
        if [[ ${OPTION} == "y" ]] || [[ ${OPTION} == "" ]]; then
           AMD_GRAPHICS_DRIVER="yes" 
        else
            AMD_GRAPHICS_DRIVER="no" 
        fi
}

function set_vmware() {
    local result
    confirm_operation "Do you want to Install vmware Graphics Driver?"
        if [[ ${OPTION} == "y" ]] || [[ ${OPTION} == "" ]];  then
           VMWARE_GRAPHICS_DRIVER="yes" 
        else
            VMWARE_GRAPHICS_DRIVER="no" 
        fi
}

function select_desktop_environment(){
    local desks=("xfce" "kde" "cinnamon" "dde" )
    PS3=${PROMPT_1}
    echo -e "Select Desktop Environment:\n"
    select desk in "${desks[@]}"; do
        if contains_element ${desk} ${desks[@]}; then 
            DESKTOP_ENVIRONMENT=$desk
            break
        else
            invalid_option
        fi
      
    done
}

function install_pkg(){
    sudo pacman -S --needed mtools dosfstools xdg-utils xdg-user-dirs reflector archlinux-keyring nfs-utils --noconfirm
    sudo pacman -S --needed xorg xorg-xinit xorg-server --noconfirm
    sudo pacman -S --needed gstreamer gst-libav gst-plugins-base gst-plugins-good gstreamer-vaapi  gst-plugins-good --noconfirm
    sudo pacman -S --needed noto-fonts-cjk ttf-dejavu wqy-microhei wqy-microhei-lite wqy-zenhei --noconfirm
    sudo pacman -S --needed pulseaudio pulseaudio-alsa --noconfirm
    sudo pacman -S --needed bluez bluez-utils --noconfirm
  
    if [ $INTEL_GRAPHICS_DRIVER == "yes" ];then
        sudo pacman -S --needed xf86-video-intel --noconfirm        
    elif [ $AMD_GRAPHICS_DRIVER == "yes" ];then
        sudo pacman -S --needed xf86-video-amdgpu --noconfirm
     elif [ $VMWARE_GRAPHICS_DRIVER == "yes" ];then
        sudo pacman -S --needed xf86-video-vmware --noconfirm
    else
           invalid_option
    fi

    sudo pacman -S --needed mesa  haveged --noconfirm
    sudo pacman -S --needed traceroute bind-tools  ntfs-3g btrfs-progs exfat-utils gptfdisk  gvfs-fuse fuse2 fuse3 fuseiso cifs-utils smbclient nfs-utils gvfs gvfs-smb

    sudo systemctl enable bluetooth
    sudo systemctl start haveged
    sudo systemctl enable fstrim.timer
}

function systemd_resolved(){
    sudo systemctl start systemd-resolved.service
    sudo systemctl enable systemd-resolved.service
    sudo cp /etc/resolv.conf /etc/resolv.conf.bak
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}

function install_smb(){
    sudo mkdir -p /media/smb
    sudo chown -R syaofox  /media/smb

    sudo mkdir -p /media/smb/omvnas/me
    sudo mkdir -p /media/smb/omvnas/kid
    sudo mkdir -p /media/smb/omvnas/share
    sudo mkdir -p /media/smb/openwrt/share

    #echo '10.10.10.1	openwrt' |sudo tee -a /etc/hosts
    #echo '10.10.10.3	omvnas' |sudo tee -a /etc/hosts

    echo '//omvnas/share /media/smb/omvnas/share cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' |sudo tee -a /etc/fstab
    echo '//omvnas/me /media/smb/omvnas/me cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' |sudo tee -a /etc/fstab
    echo '//omvnas/kid /media/smb/omvnas/kid cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' |sudo tee -a /etc/fstab
    echo '//openwrt/share /media/smb/openwrt/share cifs  username=root,password=0928,vers=2.0,noauto,user 0 0' |sudo tee -a /etc/fstab
}

function install_yay(){
    
    #git clone https://aur.archlinux.org/yay.git
    #cd yay
    #makepkg -si PKGBUILD
    #rm -rf yay

    echo "Configing Archlinuxcn"


    echo "[archlinuxcn]" |sudo tee -a /etc/pacman.conf
    echo "Server = https://mirrors.bfsu.edu.cn/archlinuxcn/\$arch" |sudo tee -a /etc/pacman.conf

    sudo pacman -Syy --noconfirm

    sudo rm -rf /etc/pacman.d/gnupg
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
    sudo pacman -S archlinuxcn-keyring --noconfirm
    sudo pacman-key --populate archlinuxcn

    sudo pacman -S --needed yay --noconfirm
}

function install_dde(){
    sudo pacman -S --needed xorg deepin deepin-extra
    sudo sed -i 's/^\(#?greeter\)-session\s*=\s*\(.*\)/greeter-session =  lightdm-deepin-greeter #\1/ #\2g' /etc/lightdm/lightdm.conf
   sudo systemctl enable lightdm
}

function install_kde(){
    echo "exec startkde" > ~/.xinitrc

    sudo pacman -S --needed --noconfirm plasma-meta sddm sddm-kcm
    sudo systemctl enable sddm

    sudo pacman -S --needed --noconfirm konsole dolphin ffmpegthumbs kate inkscape ark kinfocenter kwalletmanager gwenview kipi-plugins gimp spectacle  okular vlc speedcrunch kcolorchooser kruler kompare kfind juk kcalc  kdf chromium

    sudo pacman -S --needed --noconfirm discover packagekit-qt5 

    yay -S --needed  kcm-colorful-git breeze-blurred-git
}

function install_xfce() {
    echo "Install Desktop"
    sudo pacman -S --needed lightdm lightdm-webkit2-greeter xfce4 xfce4-goodies --noconfirm

    echo "exec startxfce4" > ~/.xinitrc

    sudo sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-webkit2-greeter/g' /etc/lightdm/lightdm.conf
    sudo systemctl enable lightdm

 

    echo "Install pkgs"
    sudo pacman -S --needed xcape cifs-utils --noconfirm

    echo "Install pkgs"
    sudo pacman -S --needed pavucontrol libcanberra libcanberra-pulse --noconfirm

    sudo pacman -S --needed file-roller p7zip unrar unace lrzip squashfs-tools --noconfirm

    sudo pacman -S --needed ffmpegthumbnailer ffmpegthumbs thunar-media-tags-plugin --noconfirm

    echo "Install Themes"
    sudo pacman -S --needed arc-gtk-theme arc-icon-theme papirus-icon-theme --noconfirm

    echo "Install lightdm-webkit Themes"
    yay -S lightdm-webkit-theme-aether-git

    sudo cp -r /usr/share/lightdm-webkit/themes/lightdm-webkit-theme-aether /usr/share/lightdm-webkit/themes/Aether
    #git clone git@github.com:NoiSek/Aether.git ~/.Aether
    #sudo cp --recursive ~/.Aether /usr/share/lightdm-webkit/themes/Aether
    sudo sed -i 's/^webkit_theme\s*=\s*\(.*\)/webkit_theme = lightdm-webkit-theme-aether #\1/g' /etc/lightdm/lightdm-webkit2-greeter.conf
    sudo sed -i 's/^\(#?greeter\)-session\s*=\s*\(.*\)/greeter-session = lightdm-webkit2-greeter #\1/ #\2g' /etc/lightdm/lightdm.conf

    echo "Install Themes"
    yay -S --needed mint-themes mint-x-icons mint-y-icons
    yay -S --needed lightdm-webkit-theme-aether-git
}

function install_pinyin(){
    sudo pacman -S fcitx5 fcitx5-chinese-addons kcm-fcitx5 fcitx5-qt fcitx5-gtk fcitx5-material-color
    echo "export GTK_IM_MODULE=fcitx5" >> ~/.xprofile
    echo "export XMODIFIERS=@im=fcitx5" >> ~/.xprofile
    echo "export QT_IM_MODULE=fcitx5" >> ~/.xprofile
    echo "fcitx5 &" >> ~/.xprofile

    echo "export GTK_IM_MODULE=fcitx5" >> ~/.xinitrc
    echo "export XMODIFIERS=@im=fcitx5" >> ~/.xinitrc
    echo "export QT_IM_MODULE=fcitx5" >> ~/.xinitrc
}

function install() {
    install_pkg
    systemd_resolved
    install_smb
    install_yay
    

    if [ $DESKTOP_ENVIRONMENT == "xfce" ];then
        install_xfce
        
    elif [ $DESKTOP_ENVIRONMENT == "cinnamon" ];then
            install_cinnamon
    elif [ $DESKTOP_ENVIRONMENT == "dde" ];then
            install_dde
    else
            install_kde
    fi

    install_pinyin

    print_line
    confirm_operation "Do you want to reboot system?"
    if [[ ${OPTION} == "y" ]] || [[ ${OPTION} == "" ]];  then
        reboot 
    fi
    exit 0
}



if (( $EUID == 0 )); then
    echo "Do not run as root!"
    exit
fi
checklist=( 0 0 0 0 0 )

MIRRORLIST_COUNTRY="CN"
INTEL_GRAPHICS_DRIVER="yes"
AMD_GRAPHICS_DRIVER="yes"
VMWARE_GRAPHICS_DRIVER="no"
DESKTOP_ENVIRONMENT="xfce"

while true; do
    print_title "ARCHLINUX DESKTOP ENVIRONMEENT INSTALL "
    echo ""
    echo " 1) $(mainmenu_item "${checklist[1]}"  "Set Mirrors"             "${MIRRORLIST_COUNTRY}" )"
    echo " 2) $(mainmenu_item "${checklist[2]}"  "Intel Graphics Driver"             "${INTEL_GRAPHICS_DRIVER}" )"
    echo " 3) $(mainmenu_item "${checklist[3]}"  "Amd Graphics Driver"              "${AMD_GRAPHICS_DRIVER}" )"
    echo " 4) $(mainmenu_item "${checklist[4]}"  "VMWare Graphics Driver"              "${VMWARE_GRAPHICS_DRIVER}" )"
    echo " 5) $(mainmenu_item "${checklist[5]}"  "Select Desktop Environment"              "${DESKTOP_ENVIRONMENT}" )"
    
    echo ""
    echo " i) install"
    echo " q) quit"
    echo ""

    read_input_options
    for OPT in ${OPTIONS[@]}; do
        case ${OPT} in
            1) set_mirrors && checklist[1]=1;;
            2) set_intel && checklist[2]=1;;
            3) set_amd && checklist[3]=1;;
            4) set_vmware && checklist[4]=1;;
            5) select_desktop_environment && checklist[5]=1;;
            "i") install;;
            "q") exit 0;;
            *) invalid_option;;
        esac
    done
done