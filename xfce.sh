#!/bin/bash

set -e
echo "Setting Mirrors"

sudo pacman -Syyy
sudo pacman -S reflector
sudo reflector --verbose -c CN --sort rate  -a 6 -p https --save /etc/pacman.d/mirrorlist
# Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch
sudo pacman -Syyy
sudo pacman -S --needed mtools dosfstools xdg-utils xdg-user-dirs reflector --noconfirm
sudo pacman -S --needed xorg xorg-xinit xorg-server --noconfirm
sudo pacman -S --needed gstreamer gst-libav gst-plugins-base gst-plugins-good gstreamer-vaapi  gst-plugins-good --noconfirm
sudo pacman -S --needed noto-fonts-cjk ttf-dejavu wqy-microhei wqy-microhei-lite wqy-zenhei --noconfirm
sudo pacman -S --needed pulseaudio pulseaudio-alsa --noconfirm
sudo pacman -S --needed bluez bluez-utils --noconfirm
sudo pacman -S --needed mesa xf86-video-vmware haveged --noconfirm

echo "enable Server"
sudo systemctl enable bluetooth
sudo systemctl start haveged
sudo systemctl enable fstrim.timer

echo "Install Desktop"
sudo pacman -S --needed lightdm lightdm-webkit2-greeter xfce4 xfce4-goodies --noconfirm

sudo sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-webkit2-greeter/g' /etc/lightdm/lightdm.conf
sudo systemctl enable lightdm

echo "Install pkgs"
sudo pacman -S --needed xcape cifs-utils --noconfirm

echo "Setting smb"
sudo mkdir -p /media/smb
sudo chown -R syaofox  /media/smb

sudo mkdir -p /media/smb/omvnas/me
sudo mkdir -p /media/smb/omvnas/kid
sudo mkdir -p /media/smb/openwrt/share

echo '10.10.10.1	openwrt' |sudo tee -a /etc/hosts
echo '10.10.10.3	omvnas' |sudo tee -a /etc/hosts

echo '//omvnas/share /media/smb/omvnas/share cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' |sudo tee -a /etc/fstab
echo '//omvnas/me /media/smb/omvnas/me cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' |sudo tee -a /etc/fstab
echo '//omvnas/kid /media/smb/omvnas/kid cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' |sudo tee -a /etc/fstab
echo '//openwrt/share /media/smb/openwrt/share cifs  username=me,password=0928,vers=2.0,noauto,user 0 0' |sudo tee -a /etc/fstab

echo "Install pkgs"
sudo pacman -S --needed pavucontrol libcanberra libcanberra-pulse --noconfirm

sudo pacman -S --needed file-roller p7zip unrar unace lrzip squashfs-tools --noconfirm

sudo pacman -S --needed ffmpegthumbnailer ffmpegthumbs --noconfirm

echo "Install Themes"
sudo pacman -S --needed arc-gtk-theme arc-icon-theme papirus-icon-theme --noconfirm



echo "Install yay"
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


#echo "Install yay"
#pacman -Syy
#pacman -S yay

echo "Install Themes"
yay -S --needed mint-themes mint-x-icons mint-y-icons
yay -S --needed lightdm-webkit-theme-aether-git

echo "Install lightdm-webkit Themes"
yay -S lightdm-webkit-theme-aether-git

sudo cp -r /usr/share/lightdm-webkit/themes/lightdm-webkit-theme-aether /usr/share/lightdm-webkit/themes/Aether
#git clone git@github.com:NoiSek/Aether.git ~/.Aether
#sudo cp --recursive ~/.Aether /usr/share/lightdm-webkit/themes/Aether
#sudo sed -i 's/^webkit_theme\s*=\s*\(.*\)/webkit_theme = lightdm-webkit-theme-aether #\1/g' /etc/lightdm/lightdm-webkit2-greeter.conf
#sudo sed -i 's/^\(#?greeter\)-session\s*=\s*\(.*\)/greeter-session = lightdm-webkit2-greeter #\1/ #\2g' /etc/lightdm/lightdm.conf