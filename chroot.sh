# User information
clear
read -p "Enter the host name: " host
clear
read -p "Enter the user name: " name
clear
read -p "Enter the region: " region
clear
read -p "Enter the zone: " zone

# Host configuration
ln -sf /usr/share/zoneinfo/"$region"/"$zone" /etc/localtime
hwclock --systohc --utc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$host" > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$host.localdomain\t$host"> /etc/hosts

# Grub configuration
if [ $boot_state -gt 0 ]
then
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
  grub-install --target=i386-pc "$rootp"
fi
grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
systemctl enable iptables.service
systemctl enable NetworkManager.service
systemctl enable systemd-timesyncd.service

# User configuration
useradd -mG wheel "$name"
clear
echo "Set a password for your user"
passwd "$name"
clear
echo "Set a password for the root user (admin)"
passwd
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers
