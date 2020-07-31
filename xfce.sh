PKG+='mtools dosfstools xdg-utils xdg-user-dirs reflector '
PKG+='xorg xorg-xinit xorg-server '
PKG+='gstreamer gst-libav gst-plugins-base gst-plugins-good gstreamer-vaapi  gst-plugins-good '
PKG+='noto-fonts-cjk ttf-dejavu wqy-microhei wqy-microhei-lite wqy-zenhei '
PKG+='pulseaudio pulseaudio-alsa '
PKG+='bluez bluez-utils '
PKG+='mesa xf86-video-vmware haveged'

pacman -S --needed ${PKG} --noconfirm

systemctl enable bluetooth
systemctl start haveged
systemctl enable fstrim.timer

pacman -S --needed lightdm lightdm-webkit2-greeter xfce4 xfce4-goodies --noconfirm

sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-webkit2-greeter/g' /etc/lightdm/lightdm.conf
systemctl enable lightdm


pacman -S --needed xcape cifs-utils --noconfirm

mkdir -p $HOME/smb/omvnas/share
mkdir -p $HOME/smb/omvnas/me
mkdir -p $HOME/smb/omvnas/kid
mkdir -p $HOME/smb/openwrt/share

echo '10.10.10.1	openwrt' >> /etc/hosts
echo '10.10.10.3	openwrt' >> /etc/hosts

echo '//omvnas/share '$HOME'/smb/omvnas/share cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' >> /etc/fstab
echo '//omvnas/me '$HOME'/smb/omvnas/me cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' >> /etc/fstab
echo '//omvnas/kid '$HOME'/smb/omvnas/kid cifs  username=me,password=0928,vers=3.0,noauto,user 0 0' >> /etc/fstab
echo '//openwrt/share '$HOME'/smb/openwrt/share cifs  username=me,password=0928,vers=2.0,noauto,user 0 0' >> /etc/fstab

pacman --needed -S pavucontrol libcanberra libcanberra-pulse --noconfirm

pacman --needed -S file-roller p7zip unrar unace lrzip squashfs-tools --noconfirm

pacman --needed -S ffmpegthumbnailer ffmpegthumbs --noconfirm

pacman -S --needed arc-gtk-theme arc-icon-theme papirus-icon-theme --noconfirm
su syaofox
yay -S mint-themes mint-x-icons mint-y-icons 
yay -S lightdm-webkit-theme-aether-git 
su root
git clone git@github.com:NoiSek/Aether.git ~/.Aether
cp --recursive ~/.Aether /usr/share/lightdm-webkit/themes/Aether