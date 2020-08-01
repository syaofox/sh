#!/bin/bash
set -e
#分区 gpt,uefi分区512M

function arch_chroot() {
    arch-chroot /mnt "/bin/bash" -c "${1}"
}

echo "Server = https://mirrors.bfsu.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
pacman -Syyy

echo "Format & Mount"

mkfs.fat -F32 /dev/sda1
mkfs.ext4 -L archroot /dev/sda2
mount /dev/sda2 /mnt
#system-d bootloader
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

echo "Setting ntp time"
timedatectl set-ntp true

echo "Setting Mirrors"
pacman -S --needed reflector
reflector --verbose -c CN --sort rate  -a 6 -p https --save /etc/pacman.d/mirrorlist
#Server = https://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch
pacman -Syyy


echo "Installing base"
# pacstrap -i /mnt base linux linux-headers linux-lts linux-lts-headers linux-firmware intel-ucode sudo nano vim git
pacstrap -i /mnt base base-devel linux-lts linux-lts-headers linux-firmware pacman-contrib intel-ucode sudo vim git dnsutils

echo "Genning fstab"
genfstab -U -p /mnt >> /mnt/etc/fstab

echo "Setting Swapfile"
dd if=/dev/zero of=/mnt/swapfile bs=1M count=8192 status=progress #8G
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
echo >> /mnt/etc/fstab
echo "# Swapfile" >> /mnt/etc/fstab
echo "/swapfile none swap defaults 0 0" >> /mnt/etc/fstab


echo "Seting Lanuage"
sed -i '/#en_US.UTF-8/s/^#//g' /mnt/etc/locale.gen
sed -i '/#zh_CN.UTF-8/s/^#//g' /mnt/etc/locale.gen
sed -i '/#zh_HK.UTF-8/s/^#//g' /mnt/etc/locale.gen
sed -i '/#zh_TW.UTF-8/s/^#//g' /mnt/etc/locale.gen
arch_chroot "locale-gen"
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

echo "Setting Timezone"
arch_chroot "ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime"
arch_chroot "timedatectl set-ntp true"
arch_chroot "hwclock --systohc --utc"

echo "Setting Hostname"
echo "vm-arch" > /mnt/etc/hostname
echo "127.0.0.1 localhost" >> /mnt/etc/hosts
echo "::1 localhost" >> /mnt/etc/hosts
echo "127.0.1.1 vm-arch.localdomain	vm-arch" >> /mnt/etc/hosts

echo "Setting Network"
arch_chroot "pacman -S networkmanager network-manager-applet"
arch_chroot "systemctl enable NetworkManager"
arch_chroot "systemctl disable dhcpcd"

echo "Add Root Password"
arch_chroot "passwd"

echo "Add syaofox"
arch_chroot "useradd -m -g users -G wheel -s /bin/bash syaofox"
arch_chroot "passwd syaofox"
arch_chroot "echo 'syaofox ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo"


echo "Setting Systemd-bootloader"

arch_chroot "pacman -S efibootmgr"
arch_chroot "bootctl install"
sed -i '/#timeout 3/s/^#//g' /mnt/boot/loader/loader.conf
echo "title Arch Linux" >> /mnt/boot/loader/entries/arch.conf
echo "linux /vmlinuz-linux-lts" >> /mnt/boot/loader/entries/arch.conf
echo "initrd /intel-ucode.img" >> /mnt/boot/loader/entries/arch.conf
echo "initrd /initramfs-linux-lts.img" >> /mnt/boot/loader/entries/arch.conf
partuuid=$(blkid | grep archroot | sed -r 's/.*?PARTUUID=\"(.*?)\"/\1/g')
echo "options root=\"PARTUUID=${partuuid}\" rw" >> /mnt/boot/loader/entries/arch.conf

echo "umount"
umount -R /mnt
