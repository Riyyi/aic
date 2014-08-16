#!/bin/bash

if [[ -f `pwd`/sharedfuncs ]]; then
  source sharedfuncs
else
  echo "missing file: sharedfuncs"
  exit 1
fi

# VARIABLES
  LOCALE="en_US"
  KEYMAP="dvorak"               #(us)
  TIMEZONE="Europe/Amsterdam"
  HARDWARECLOCK="utc"           #(utc/localtime)
  HOSTNAME="arch-laptop"
  INSTALLPARTITION="sda"        #(sda/sdb/sdc)

# COMMON FUNCTIONS
  arch_chroot() {
    arch-chroot $MOUNTPOINT /bin/bash -c "${1}"
  }

pacman -Sy
pacstrap ${MOUNTPOINT} base base-devel
genfstab -U -p ${MOUNTPOINT} >> ${MOUNTPOINT}/etc/fstab
nano ${MOUNTPOINT}/etc/fstab
arch_chroot "sed -i '/'${LOCALE}.UTF-8'/s/^#//' /etc/locale.gen"
arch_chroot "locale-gen"
echo LANG=${LOCALE}.UTF-8 > ${MOUNTPOINT}/etc/locale.conf
export LANG=${LOCALE}.UTF-8
echo "KEYMAP=${KEYMAP}" > ${MOUNTPOINT}/etc/vconsole.conf
arch_chroot "ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime"
arch_chroot "hwclock --systohc --${HARDWARECLOCK}"
echo ${HOSTNAME} > ${MOUNTPOINT}/etc/hostname
arch_chroot "sed -i '/127.0.0.1/s/$/ '${HOSTNAME}'/' /etc/hosts"
arch_chroot "sed -i '/::1/s/$/ '${HOSTNAME}'/' /etc/hosts"
arch_chroot "mkinitcpio -p linux"
pacstrap ${MOUNTPOINT} grub os-prober
arch_chroot "grub-install --target=i386-pc --recheck /dev/${INSTALLPARTITION}"
arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
cp -R `pwd` ${MOUNTPOINT}/root
echo "${BLUE}enter your new root password${RESET}"
arch_chroot "passwd"
reboot
