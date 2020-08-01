#!/bin/bash

set -e

function pinyin(){
    sudo pacman -S fcitx5 fcitx5-chinese-addons kcm-fcitx5 fcitx5-qt fcitx5-gtk fcitx5-material-color
    echo "export GTK_IM_MODULE=fcitx5" >> ~/.xprofile
    echo "export XMODIFIERS=@im=fcitx5" >> ~/.xprofile
    echo "export QT_IM_MODULE=fcitx5" >> ~/.xprofile
    echo "fcitx5 &" >> ~/.xprofile

    echo "export GTK_IM_MODULE=fcitx5" >> ~/.xinitrc
    echo "export XMODIFIERS=@im=fcitx5" >> ~/.xinitrc
    echo "export QT_IM_MODULE=fcitx5" >> ~/.xinitrc
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
    
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si PKGBUILD
    rm -rf yay

    echo "Configing Archlinuxcn"


    echo "[archlinuxcn]" |sudo tee -a /etc/pacman.conf
    echo "Server = https://mirrors.bfsu.edu.cn/archlinuxcn/\$arch" |sudo tee -a /etc/pacman.conf

    sudo pacman -Syy

    sudo rm -rf /etc/pacman.d/gnupg
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
    sudo pacman -S archlinuxcn-keyring --noconfirm
    sudo pacman-key --populate archlinuxcn
}

function set_mirrors(){
     sudo pacman -Syyy
    sudo pacman -S reflector
    sudo reflector --verbose -c CN --sort rate  -a 6 -p https --save /etc/pacman.d/mirrorlist
    # Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch
    sudo pacman -Syyy
}

function install_pkg(){
    sudo pacman -S --needed mtools dosfstools xdg-utils xdg-user-dirs reflector archlinux-keyring nfs-utils --noconfirm
    sudo pacman -S --needed xorg xorg-xinit xorg-server --noconfirm
    sudo pacman -S --needed gstreamer gst-libav gst-plugins-base gst-plugins-good gstreamer-vaapi  gst-plugins-good --noconfirm
    sudo pacman -S --needed noto-fonts-cjk ttf-dejavu wqy-microhei wqy-microhei-lite wqy-zenhei --noconfirm
    sudo pacman -S --needed pulseaudio pulseaudio-alsa --noconfirm
    sudo pacman -S --needed bluez bluez-utils --noconfirm
    sudo pacman -S --needed mesa xf86-video-vmware haveged --noconfirm
    sudo pacman -S --needed traceroute bind-tools  ntfs-3g btrfs-progs exfat-utils gptfdisk  gvfs-fuse fuse2 fuse3 fuseiso cifs-utils smbclient nfs-utils gvfs gvfs-smb
    echo "enable Server"
    sudo systemctl enable bluetooth
    sudo systemctl start haveged
    sudo systemctl enable fstrim.timer
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


    echo "Install Themes"
    yay -S --needed mint-themes mint-x-icons mint-y-icons
    yay -S --needed lightdm-webkit-theme-aether-git

    echo "Install lightdm-webkit Themes"
    yay -S lightdm-webkit-theme-aether-git

    sudo cp -r /usr/share/lightdm-webkit/themes/lightdm-webkit-theme-aether /usr/share/lightdm-webkit/themes/Aether
    #git clone git@github.com:NoiSek/Aether.git ~/.Aether
    #sudo cp --recursive ~/.Aether /usr/share/lightdm-webkit/themes/Aether
    sudo sed -i 's/^webkit_theme\s*=\s*\(.*\)/webkit_theme = lightdm-webkit-theme-aether #\1/g' /etc/lightdm/lightdm-webkit2-greeter.conf
    sudo sed -i 's/^\(#?greeter\)-session\s*=\s*\(.*\)/greeter-session = lightdm-webkit2-greeter #\1/ #\2g' /etc/lightdm/lightdm.conf
}

function install_kde(){

}

echo "Setting Mirrors"
set_mirrors

echo "Install pkgs"
install_pkg

echo "enable systemd_resolved"
systemd_resolved

echo "Setting smb"
install_smb

echo "Install yay"
install_yay

echo "select desktop"
select var in xfce  cinnamon kde;
do
    break
done 

if [ $var == xfce ];then
        echo "Install xfce"
        install_xfce
        
elif [ $var == cinnamon ];then
        echo "cinnamon"
else
        echo "kde"
        install_kde
fi
