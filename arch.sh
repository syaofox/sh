#分区 gpt,uefi分区512M

#mkfs.fat -F32 /dev/sda1
#mkfs.ext4 -L archroot/dev/sda2

#mount /dev/sda2 /mnt

#system-d bootloader
#mkdir /mnt/boot
#mount /dev/sda1 /mnt/boot



echo "时间同步"
timedatectl set-ntp true

echo "更新镜像"
pacman -Syyy
pacman -S reflector
reflector --verbose -c CN --sort rate  -a 6 -p https --save /etc/pacman.d/mirrorlist
#Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch
pacman -Syyy


echo "安装基础包"
# pacstrap -i /mnt base linux linux-headers linux-lts linux-lts-headers linux-firmware intel-ucode sudo nano vim git
pacstrap -i /mnt base base-devel linux-lts linux-lts-headers linux-firmware intel-ucode sudo vim git 

echo "生成fstab"
genfstab -U -p /mnt >> /mnt/etc/fstab

echo "切换系统"
arch-chroot /mnt

echo "设置交换文件"

dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress #8G
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

echo >> /etc/fstab
echo "# 交换文件" >> /etc/fstab
echo "/swapfile none swap defaults 0 0" >> /etc/fstab


echo "设置语言"

sed -i '/#en_US.UTF-8/s/^#//g' /etc/locale.gen
sed -i '/#zh_CN.UTF-8/s/^#//g' /etc/locale.gen
sed -i '/#zh_HK.UTF-8/s/^#//g' /etc/locale.gen
sed -i '/#zh_TW.UTF-8/s/^#//g' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf
#echo "LC_COLLATE=C" >> /etc/locale.conf

echo "设置时区"
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-ntp true
hwclock --systohc --utc

echo "设置hostname"
echo "vm-arch" > /etc/hostname
vim /etc/hosts
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 vm-arch.localdomain	vm-arch" >> /etc/hosts

echo "设置网络"
pacman -S networkmanager
systemctl enable NetworkManager

echo "设置网络"
systemctl disable dhcpcd

echo "root密码"
passwd

echo "添加用户syaofox"
useradd -m -g users -G wheel -s /bin/bash syaofox
passwd syaofox
echo 'syaofox ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo


echo "systemd-bootloader"

pacman -S efibootmgr

bootctl install

sed -i '/#timeout 3/s/^#//g' /boot/loader/loader.conf



echo "title Arch Linux" >> /boot/loader/entries/arch.conf
echo "linux /vmlinuz-linux-lts" >> /boot/loader/entries/arch.conf
echo "initrd /intel-ucode.img" >> /boot/loader/entries/arch.conf
echo "initrd /initramfs-linux-lts.img" >> /boot/loader/entries/arch.conf
echo "options root=\"PARTUUID=XXXX\" rw" >> /boot/loader/entries/arch.conf

partuuid=$(blkid | grep archroot | sed -r "s/.*?PARTUUID=\"(.*?)\"/\1/g")
sed -i "s/PARTUUID=XXXX/PARTUUID=${partuuid}/" /boot/loader/entries/arch.conf




exit

mount -R /mnt