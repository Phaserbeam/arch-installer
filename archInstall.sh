
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
rootPart=$(dialog --stdout --menu "Select the Root Partition" 0 0 0 ${options}) || exit 1
homePart=$(dialog --stdout --menu "Select the Home Partition" 0 0 0 ${options}) || exit 1
bootPart=$(dialog --stdout --menu "Select the Boot Partition" 0 0 0 ${options}) || exit 1

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

arch-chroot /mnt

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "${hostname}" > /etc/hostname
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

# ----------------------
# INSTALL THE BOOTLOADER
#bootctl install
#cat <<EOF > /boot/loader/loader.conf
#default arch
#timeout 3
#EOF
#
#cat <<EOF > /boot/loader/entries/arch.conf
#title Arch linux
#linux /vmlinuz-linux
#initrd /initramfs-linux.img
#options root=UUID=$(blkid -s UUID -o value "$rootPart") rw
#EOF
## ---------------------
#
#
## -------------
## ADD USERS
## -------------
#arch-chroot /mnt useradd -m -G wheel "$user"
#echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
#echo "$user:$userPassword" | chpasswd --root /mnt
#echo "root:$password" | chpasswd --root /mnt
#