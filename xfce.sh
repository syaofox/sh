#!/bin/bash

set -e
echo "Setting Mirrors"

pacman -Syyy
pacman -S reflector
reflector --verbose -c CN --sort rate  -a 6 -p https --save /etc/pacman.d/mirrorlist
#Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch
pacman -Syyy
pacman -S --needed mtools dosfstools xdg-utils xdg-user-dirs reflector --noconfirm
pacman -S --needed xorg xorg-xinit xorg-server --noconfirm
pacman -S --needed gstreamer gst-libav gst-plugins-base gst-plugins-good gstreamer-vaapi  gst-plugins-good --noconfirm
pacman -S --needed noto-fonts-cjk ttf-dejavu wqy-microhei wqy-microhei-lite wqy-zenhei --noconfirm
pacman -S --needed pulseaudio pulseaudio-alsa --noconfirm
pacman -S --needed bluez bluez-utils --noconfirm
pacman -S --needed mesa xf86-video-vmware haveged --noconfirm


systemctl enable bluetooth
systemctl start haveged
systemctl enable fstrim.timer

pacman -S --needed lightdm lightdm-webkit2-greeter xfce4 xfce4-goodies --noconfirm

sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-webkit2-greeter/g' /etc/lightdm/lightdm.conf
systemctl enable lightdm


pacman -S --needed xcape cifs-utils --noconfirm

mkdir -p /media/smb
chown -R syaofox  /media/smb


mkdir -p /media/smb/omvnas/me
mkdir -p /media/smb/omvnas/kid
mkdir -p /media/smb/openwrt/share

echo '10.10.10.1	openwrt' >> /etc/hosts
echo '10.10.10.3	openwrt' >> /etc/hosts

echo '//omvnas/share /media/smb/omvnas/share cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' >> /etc/fstab
echo '//omvnas/me /media/smb/omvnas/me cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' >> /etc/fstab
echo '//omvnas/kid /media/smb/omvnas/kid cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' >> /etc/fstab
echo '//openwrt/share /media/smb/openwrt/share cifs  username=me,password=0928,vers=2.0,noauto,user 0 0' >> /etc/fstab

pacman --needed -S pavucontrol libcanberra libcanberra-pulse --noconfirm

pacman --needed -S file-roller p7zip unrar unace lrzip squashfs-tools --noconfirm

pacman --needed -S ffmpegthumbnailer ffmpegthumbs --noconfirm

pacman -S --needed arc-gtk-theme arc-icon-theme papirus-icon-theme --noconfirm



# yay
#su syaofox -c "git clone https://aur.archlinux.org/yay.git /tmp/yay"
#su syaofox -c "cd /tmp/yay"
#su syaofox -c "makepkg -si PKGBUILD"



rm -rf /etc/pacman.d/gnupg
pacman-key --init
pacman-key --populate archlinux
pacman-key --populate archlinuxcn

echo "[archlinuxcn]" >> /etc/pacman.conf
echo "Server = https://mirrors.bfsu.edu.cn/archlinuxcn/\$arch" >> /etc/pacman.conf

pacman -Syy
pacman -S  archlinuxcn-keyring
pacman -S yay

su syaofox -c "yay -S mint-themes mint-x-icons mint-y-icons"
su syaofox -c "yay -S lightdm-webkit-theme-aether-git"

# yay -S lightdm-webkit-theme-aether-git

git clone git@github.com:NoiSek/Aether.git /home/syaofox/.Aether
cp --recursive /home/syaofox/.Aether /usr/share/lightdm-webkit/themes/Aether

sed -i 's/^webkit_theme\s*=\s*\(.*\)/webkit_theme = lightdm-webkit-theme-aether #\1/g' /etc/lightdm/lightdm-webkit2-greeter.conf
sed -i 's/^\(#?greeter\)-session\s*=\s*\(.*\)/greeter-session = lightdm-webkit2-greeter #\1/ #\2g' /etc/lightdm/lightdm.conf