## 基础系统

```sh
timedatectl set-ntp true

pacman -Syyy
pacman -S reflector
reflector -c CN --sort rate  -a 6 -p https --save /etc/pacman.d/mirrorlist
pacman -Syyy

#分区 gpt,uefi分区512M

mkfs.fat -F 32 /dev/sda1
mkfs.ext4 /dev/sda2

mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot



pacstrap /mnt base linux linux-firmware intel-ucode vim dhcpcd efibootmgr 
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

pacman -Syyy
pacman -S reflector
reflector -c CN --sort rate  -a 6 -p https --save /etc/pacman.d/mirrorlist
pacman -Syyy

dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress #8G
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

echo "/swapfile none swap defaults 0 0" >> /etc/fstab

ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-ntp true
hwclock --systohc

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "LC_COLLATE=C" >> /etc/locale.conf
sed -i '/#en_US.UTF-8/s/^#//g' /etc/locale.gen
sed -i '/#zh_CN.UTF-8/s/^#//g' /etc/locale.gen
sed -i '/#zh_HK.UTF-8/s/^#//g' /etc/locale.gen
sed -i '/#zh_TW.UTF-8/s/^#//g' /etc/locale.gen
locale-gen



echo "vm-arch" > /etc/hostname
echo "127.0.0.1		localhost" > /etc/hosts
echo "::1				localhost" > /etc/hosts
echo "127.0.1.1		arch-nuc.localdomain	arch" > /etc/hosts

passwd
```
### grub

```sh
pacman -S  os-prober grub ntfs-3g
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
mkdir /mnt/windows10
mount /dev/sda3 /mnt/windows10 #windows电源管理关闭快速启动
grub-mkconfig -o /boot/grub/grub.cfg
# sudo pacman -S grub-customizer grub主题配置工具
```
### systemd-boot

```sh
bootctl install
echo "timeout 5" >> /boot/loader/loader.conf

# /boot/loader/entries/arch.conf

title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root="PARTUUID=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" rw
# :r! blkid 读入所有partuuid

```

```sh
useradd -mG wheel syaofox
passwd syaofox
visudo
```

```sh
exit
umount -R /mnt
reboot
```

### 疑难解答

#### 无法联网的处理

dhcp分配

```sh
systemctl restart dhcpcd
ip link set enp0s25 up
```

wifi连接

执行命令进入交互

```sh
iwctl
```

```sh
device list #get wlan0
station wlan0 scan
station wlan0 get-networks #get TC
station wlan0 connect TC
exit
```

设置静态ip

```sh
# 添加ip地址
ip addr add 10.10.10.4/24 dev enp5s0 
# 添加网关
ip route add default via 10.10.10.1
# 配置dns
nano /etc/resolv.conf
# 编辑内容
nameserver 114.114.114.114
options edns0
```

#### 添加keyring出错的处理方法

```sh
sudo pacman -Syu haveged
systemctl start haveged
systemctl enable haveged
rm -rf /etc/pacman.d/gnupg
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman-key --populate archlinuxcn
sudo pacman -S archlinuxcn-keyring
```

## 桌面

### 前置

```sh
sudo pacman -S --needed networkmanager network-manager-applet wireless_tools wpa_supplicant dialog mtools dosfstools base-devel linux-headers pacman-contrib archlinux-keyring	zip unzip unrar p7zip lzop rsync traceroute bind-tools dnsutils cronie haveged ntfs-3g btrfs-progs exfat-utils gptfdisk autofs fuse2 fuse3 fuseiso cifs-utils smbclient nfs-utils gvfs gvfs-smb openssh alsa-utils alsa-plugins pulseaudio pulseaudio-alsa bluez bluez-libs xf86-input-libinput xf86-video-intel  xf86-video-amdgpu 

sudo systemctl enable NetworkManager
sudo systemctl enable cronie
sudo systemctl enable haveged
sudo systemctl enable fstrim.timer 

```

### cinnamon

```sh
sudo pacman -S --needed xorg lightdm lightdm-webkit2-greeter cinnamon metacity gnome-terminal gnome-keyring xdg-utils xdg-user-dirs cinnamon-control-center cinnamon-desktop cinnamon-menus cinnamon-screensaver cinnamon-session cinnamon-settings-daemon cjs muffin cinnamon-translations qt5-translations man-pages-zh_cn poppler-data hyphen-en hunspell-en_US gstreamer gst-libav gst-plugins-base gst-plugins-good gstreamer-vaapi  gnome-system-monitor blueberry gnome-calculator

yay -s --needed mintlocale lightdm-webkit-theme-aether font-manager nemo-media-columns libgexiv2 nemo-mediainfo-tab nemo-fileroller ffmpeg ffmpegthumbnailer ffmpegthumbs nemo-preview 

yay -s --needed exa xed xviewer xviewer-plugins xreader xplayer gst-libav python2-xdg

yay -S Plank  #dock
# mint-themes mint-x-icons mint-y-icons papirus-icon-theme arc-gtk-themes

sudo nano /etc/lightdm/lightdm.conf
#  修改 greeter-session=example-gtk-gnome 为 lightdm-webkit2-greeter
sudo systemctl enable lightdm

sudo reboot
```

## 软件

### 包管理软件yay

安装 git

```sh
pacman -S git
```

clone yay

```sh
git clone https://aur.archlinux.org/yay.git
```

安装

```sh
cd yay
makepgk -si PKGBUILD
```

### Archlinxucn

编辑 `/etc/pacman.conf`

添加以下内容

```ini
[archlinuxcn]
Server = https://mirrors.bfsu.edu.cn/archlinuxcn/$arch
```

更新源

```sh
sudo pacman -Syy
```

添加keyring

```sh
sudo pacman -S archlinuxcn-keyring
```

### 输入法

```sh
sudo pacman -S fcitx5 fcitx5-chinese-addons kcm-fcitx5 fcitx5-qt fcitx5-gtk fcitx5-material-color

```

~/.xprofile

```ini
export GTK_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
export QT_IM_MODULE=fcitx5
fcitx5 &
```

~/.xinitrc

```sh
export GTK_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
export QT_IM_MODULE=fcitx5
```

> - 上述内容需要添加在`exec $(get_session)`之前

### digikam

```sh
yay -S digikam jasper qt5-imageformats 
# darktable digikam-plugin-gmic hugin  perl  rawtherapee mariadb #照片管理器
```

### perl-rename

> 批量重命名命令行工具 支持正则替换

```sh
perl-rename -n 's/(\w+) - (\d{1})x(\d{2}).*$/S0$2E$3\.srt/' *.srt
```

### dropbox

gpg密钥导入失败可以本地导入

下载密钥  https://linux.dropbox.com/fedora/rpm-public-key.asc

导入密钥

```sh
gpg --import rpm-public-key.asc
```

### netease-cloud-music-gtk

> gtk开发的网易云音乐轻量版

### rhythmbox

> GTK+ clone of iTunes, used by default in GNOME.

### celluloid

> 基于mpv的视频播放器

```sh
yay -S celluloid
```

### transmission-remote-gtk

> 远程管理