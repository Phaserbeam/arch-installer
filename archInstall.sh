
pacman -Syk dialog
timedatectl set-ntp true
echo "Connect to the Internet!"
iwctl \
station wlan0 get-networks
nmtui
echo -n "Hostname: "
read $hostname
echo -n "User: "
read $user
echo -n "User Password: "
read -s $userPassword
echo
echo -n "Repeat the User Password:"
read -s $userPassword2
[[ "$userPassword" == "$userPassword2" ]] || (echo "Passwords did not match"; exit 1)
echo
echo -n "Root Password: "
read -s password
echo
echo -n "Repeat the Root Password: "
read -s password2
echo
[[ "$password" == "$password2" ]] || (echo "Passwords did not match"; exit 1)

# -----------------------
# SELECT AND FORMAT DISKS
# -----------------------
devicelist=$(lsblk -dpn -o NAME,SIZE | grep -Ev "boot|rpmb|loop" | tac)
device=$(dialog --stdout --menu "Select your Installation Disk " 0 0 0 ${devicelist}) || exit 1
echo ${device}

cfdisk ${device}

options=$(lsblk ${device} -pln -o NAME,SIZE)
bootPart=$(dialog --stdout --menu "Select the Boot Partition" 0 0 0 ${options}) || exit 1
rootPart=$(dialog --stdout --menu "Select the Root Partition" 0 0 0 ${options}) || exit 1
homePart=$(dialog --stdout --menu "Select the Home Partition" 0 0 0 ${options}) || exit 1

echo "Root Partition: " $rootPart
echo "Home Partition: " $homePart
echo "Boot Partition: " $bootPart

mkfs.ext4 $homePart
mkfs.ext4 $rootPart
mount $rootPart /mnt
mount $homePart /mnt/home --mkdir
mount $bootPart /mnt/boot --mkdir
# -----------------------------

pacstrap -K /mnt linux linux-firmware base base-devel networkmanager intel-ucode vim git
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt bash -c 'echo "LANG=en_US.UTF-8" > /etc/locale.conf'
arch-chroot /mnt bash -c 'echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen'
arch-chroot /mnt bash -c 'locale-gen'
arch-chroot /mnt bash -c 'echo "${hostname}" > /etc/hostname'
arch-chroot /mnt bash -c 'ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime'
arch-chroot /mnt hwclock --systohc

# ----------------------
# INSTALL THE BOOTLOADER
# ----------------------
arch-chroot /mnt bootctl install
arch-chroot /mnt bash -c 'cat <<EOF > /boot/loader/loader.conf
default arch
timeout 3
EOF'

arch-chroot /mnt bash -c 'cat <<EOF > /boot/loader/entries/arch.conf
title Arch linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value "$rootPart") rw
EOF'
# ---------------------


# -------------
# ADD USERS
# -------------
echo "ADDING USERS"
echo "$password"
echo "$user"
echo "$userPassword"
read
arch-chroot /mnt useradd -m -G wheel "$user"
arch-chroot /mnt bash -c 'echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers'

echo "$user:$userPassword" | chpasswd --root /mnt
echo "root:$password" | chpasswd --root /mnt