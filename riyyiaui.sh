#!/bin/bash

# VARIABLES
  # COLORS
    BOLD=$(tput bold)
    UNDERLINE=$(tput sgr 0 1)
    RESET=$(tput sgr0)
    # regular colors
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    PURPLE=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    WHITE=$(tput setaf 7)
    # bold
    BRED=${Bold}$(tput setaf 1)
    BGREEN=${Bold}$(tput setaf 2)
    BYELLOW=${Bold}$(tput setaf 3)
    BBLUE=${Bold}$(tput setaf 4)
    BPURPLE=${Bold}$(tput setaf 5)
    BCYAN=${Bold}$(tput setaf 6)
    BWHITE=${Bold}$(tput setaf 7)
  
  MOUNTPOINT="/mnt"

  # LOG FILE
    LOG="install_error.log"
    [[ -f $LOG ]] && rm -f $LOG
    PKG_FAIL="install_pkg_fail_list.log"
    [[ -f $PKG_FAIL ]] && rm -f $PKG_FAIL
    
#COMMON FUNCTIONS
  progress() {
    while true; do
      kill -0 $PID &> /dev/null;
      if [[ $? == 0 ]]; then
	sleep 0.25
      else
	wait $PID
	RETCODE=$?
	echo "$PID's retcode: $RETCODE" >> $LOG
	if [[ $RETCODE == 0 ]] || [[ $RETCODE == 255 ]]; then
	  echo -e "${GREEN}(success)${RESET}"
	else
	  echo -e "${RED}(failed)${RESET}"
	  echo -e "$PKG" >> $PKG_FAIL
	fi
	break
      fi
    done
  }
  
  check_connection(){
    connection_test() {
      ping -c 1 google.com &> /dev/null && return 1 || return 0
    }
    WIRELESS_DEV=`ip link | grep wlp | awk '{print $2}'| sed 's/://' | sed '1!d'`
    if connection_test; then
        echo "ERROR! Connection not found."
        ip link set ${WIRELESS_DEV} up
        wifi-menu ${WIRELESS_DEV}
        check_connection
    fi
  }

  # check if a package is already installed
  is_package_installed() {
    for PKG in $1; do
      pacman -Q $PKG &> /dev/null && return 0;
    done
    return 1
  }

  # install package using pacman
  package_install() {
    echo "${BLUE}installing packages:${RESET}"
    for PKG in ${1}; do
      if ! is_package_installed "${PKG}" ; then
	echo -ne "${PKG} "
	pacman -S --noconfirm --needed ${PKG} >>"$LOG" 2>&1 &
	PID=$!;progress $PID
      else
	echo "${PKG} ${YELLOW}(already installed)${RESET}"
      fi
    done
  }

  arch_chroot() {
    arch-chroot $MOUNTPOINT /bin/bash -c "${1}"
  }

check_connection

pacman -Sy
pacstrap -i ${MOUNTPOINT} base base-devel
genfstab -U -p ${MOUNTPOINT} >> ${MOUNTPOINT}/etc/fstab
nano ${MOUNTPOINT}/etc/fstab
arch_chroot "sed -i '/'en_US.UTF-8'/s/^#//' /etc/locale.gen"
arch_chroot "locale-gen"
echo LANG=en_US.UTF-8 > ${MOUNTPOINT}/etc/locale.conf
export LANG=en_US.UTF-8
echo "KEYMAP=dvorak" > ${MOUNTPOINT}/etc/vconsole.conf
arch_chroot "ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime"
arch_chroot "hwclock --systohc --utc"
echo arch-laptop > ${MOUNTPOINT}/etc/hostname
arch_chroot "sed -i '/127.0.0.1/s/$/ 'arch-laptop'/' /etc/hosts"
arch_chroot "sed -i '/::1/s/$/ 'arch-laptop'/' /etc/hosts"
arch_chroot "mkinitcpio -p linux"
echo "${BLUE}enter your new root password${RESET}"
arch_chroot "passwd"
package_install "grub os-prober"
arch_chroot "grub-install --target=i386-pc --recheck /dev/sda"
arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"

package_install "
    kdebase
    networkmanager
    kdeplasma-applets-plasma-nm
"

systemctl enable kdm.service
reboot