# Preparation
pacman -Syyy
timedatectl set-ntp true
packages="base base-devel git grub linux linux-firmware linux-headers networkmanager sudo vim"

# User and Device Information
disks=$(lsblk -p -n -l -o NAME -e 7,11)
clear
lsblk
PS3='Enter the number of device name you want to install to: '
select dev in ${disks}
do
    break
done

boot_state=`ls /sys/firmware | grep -c "efi"`
cpu_state=`cat /proc/cpuinfo | grep -c "Intel"`
gpu_state=`lspci -vnn | grep -c "NVIDIA"`

# Disk Preparation
wipefs -a "$dev"
if [ $boot_state -gt 0 ]
then
	printf "g\nn\n\n\n+256M\nt\n1\nn\n\n\n\nw\n" | fdisk "$dev"
	efip=`lsblk $dev -p -n -l -o NAME -e 7,11 | sed -n 2p`
	rootp=`lsblk $dev -p -n -l -o NAME -e 7,11 | sed -n 3p`
	mkfs.fat -F32 "$efip"
	mkfs.ext4 "$rootp"
	mount "$rootp" /mnt
	mkdir /mnt/boot
	mount "$efip" /mnt/boot
	packages="${packages} efibootmgr"
else
	printf "n\n\n\n\n\n\nw\n" | fdisk "$dev"
	rootp=`lsblk $dev -p -n -l -o NAME -e 7,11 | sed -n 2p`
	mkfs.ext4 "$rootp"
	mount "$rootp" /mnt
fi

# CPU and GPU configuration
if [ $cpu_state -gt 0 ]
then
	packages="${packages} intel-ucode xf86-video-intel"
else
	cpu_state=`cat /proc/cpuinfo | grep -c "AMD"`
	if [ $cpu_state -gt 0 ]
	then
		packages="${packages} amd-ucode"
	fi
fi

if [ $gpu_state -gt 0 ]
then
	packages="${packages} nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings"
else
	gpu_state=`lspci -vnn | grep -c "NVIDIA"`
	if [ $gpu_state -gt 0 ]
	then
		packages="${packages} xf86-video-amdgpu mesa lib32-mesa"
	fi
fi

# Install packages
echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
pacstrap /mnt $packages

# Generate File system table
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot
curl -L JustinCardona.github.io/chroot.sh > chroot.sh
echo "rootp=$dev" | cat - chroot.sh > temp && mv temp chroot.sh
echo "boot_state=$boot_state" | cat - chroot.sh > temp && mv temp chroot.sh
mv chroot.sh /mnt
arch-chroot /mnt sh chroot.sh
rm /mnt/chroot.sh
arch-chroot /mnt
