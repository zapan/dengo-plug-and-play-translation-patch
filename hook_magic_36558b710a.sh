#!/bin/sh

# Densha de Go! Plug & Play translation patching script
USB_ROOT="/mnt"

error_exit() {
    # Blink the door light to indicate an error
    echo timer > /sys/class/leds/led2/trigger
    echo 100 > /sys/class/leds/led2/delay_on
    echo 100 > /sys/class/leds/led2/delay_off
    exit 1
}

copy_atx() {
  BASENAME=$1
  ORIGINAL="/root/Data/${BASENAME}.atx.orig"
  FILEPATH="/root/Data/${BASENAME}.atx"
  if [ ! -f ${ORIGINAL} ]; then
    ls -al ${FILEPATH}
    md5sum ${FILEPATH}
    mv ${FILEPATH} ${ORIGINAL}
  fi
  cp "${USB_ROOT}/translation/${BASENAME}.atx" ${FILEPATH}
  chmod 664 ${FILEPATH}
  echo ""
}

copy_dat() {
  BASENAME=$1
  FOLDER=$2
  ORIGINAL="/root/Data/cddata/${FOLDER}/${BASENAME}.dat.orig"
  FILEPATH="/root/Data/cddata/${FOLDER}/${BASENAME}.dat"
  if [ ! -f ${ORIGINAL} ]; then
    ls -al ${FILEPATH}
    md5sum ${FILEPATH}
    mv ${FILEPATH} ${ORIGINAL}
  fi
  cp "${USB_ROOT}/translation/cddata/${FOLDER}/${BASENAME}.dat" ${FILEPATH}
  chmod 664 ${FILEPATH}
  chown 1000:1000 ${FILEPATH}
  echo ""
}

copy_2d_dat() {
  copy_dat $1 '2d'
}
copy_common_dat() {
  copy_dat $1 'common'
}
copy_menu_dat() {
  copy_dat $1 'menu'
}


{
# Stop Densha de Go! game app
/etc/init.d/S99dgtype3 stop

# Light the door light to indicate we're running
echo -n none > /sys/class/leds/led2/trigger
echo 1 > /sys/class/leds/led2/brightness

# Check if we need to create a backup
if [ -f "${USB_ROOT}/backup_required" ]; then

    if [ -f "/root/Data/cddata/common/com_mem.dat.orig" ]; then
    	echo "Full backup already done"
    else
    	echo "Running full backup..."

      # We're actually going to create a full factory install package that if you
      # decided to delete the game entirely for some reason, you can just add the
      # factory install flag to the drive and plug it in to reinstall.

      # Tar up the game
      cd /root

      mkdir -p "${USB_ROOT}/backup/"

      if ! tar -c dgf Data/ | gzip -c > "${USB_ROOT}/backup/dgtyp3zzzz.tar.gz"; then
          error_exit
      fi
      # Generate MD5 sum of the tarball
      cd "${USB_ROOT}/backup"
      md5sum dgtyp3zzzz.tar.gz > dgtyp3zzzz.tar.gz.md5

      # Generate MD5 sum of the installed files (per factory install script)
      echo `(find /root/Data/ /root/dgf -type f -exec md5sum {} \;) | awk '{print $1}' | env LC_ALL=C sort | md5sum` > installed.md5
    fi

    # Remove backup flag if successful
    rm "${USB_ROOT}/backup_required"
fi

# Remount with write access
mount -o remount,rw /

if [ -f "${USB_ROOT}/backup_translation" ]; then

    if [ -f "/root/Data/cddata/common/com_mem.dat.orig" ]; then
      echo "Translation backup already done"
    else
      echo "Translation files backup..."

      mkdir -p "${USB_ROOT}/backup/cddata/2d"
      mkdir -p "${USB_ROOT}/backup/cddata/common"
      mkdir -p "${USB_ROOT}/backup/cddata/menu"

      cp /root/Data/cddata/2d/end_mem.dat       "${USB_ROOT}/backup/cddata/2d/"
      cp /root/Data/cddata/2d/game2d_mem.dat    "${USB_ROOT}/backup/cddata/2d/"
      cp /root/Data/cddata/2d/game2d_vram.dat   "${USB_ROOT}/backup/cddata/2d/"
      cp /root/Data/cddata/common/com_mem.dat   "${USB_ROOT}/backup/cddata/common/"
      cp /root/Data/cddata/menu/menu_mem_fj.dat "${USB_ROOT}/backup/cddata/menu/"
      cp /root/Data/cddata/menu/menu_mem_us.dat "${USB_ROOT}/backup/cddata/menu/"

      cp /root/Data/OptionMenu.atx              "${USB_ROOT}/backup/"
      cp /root/Data/TitleMenu.atx               "${USB_ROOT}/backup/"
      cp /root/Data/Warning.atx                 "${USB_ROOT}/backup/"

      echo "Translation files backup OK."
    fi

    # Remove backup flag if successful
    rm "${USB_ROOT}/backup_translation"
    echo ""
fi


if [ -f "${USB_ROOT}/revert_translation" ]; then
    echo "Reverting translation files..."
    mv /root/Data/cddata/2d/end_mem.dat.orig        /root/Data/cddata/2d/end_mem.dat
    mv /root/Data/cddata/2d/game2d_mem.dat.orig     /root/Data/cddata/2d/game2d_mem.dat
    mv /root/Data/cddata/2d/game2d_vram.dat.orig    /root/Data/cddata/2d/game2d_vram.dat
    mv /root/Data/cddata/common/com_mem.dat.orig    /root/Data/cddata/common/com_mem.dat
    mv /root/Data/cddata/menu/menu_mem_fj.dat.orig  /root/Data/cddata/menu/menu_mem_fj.dat
    mv /root/Data/cddata/menu/menu_mem_us.dat.orig  /root/Data/cddata/menu/menu_mem_us.dat

    mv /root/Data/OptionMenu.atx.orig               /root/Data/OptionMenu.atx
    mv /root/Data/TitleMenu.atx.orig                /root/Data/TitleMenu.atx
    mv /root/Data/Warning.atx.orig                  /root/Data/Warning.atx

    rm "${USB_ROOT}/revert_translation"
    echo "Translation files reverted OK."
    echo ""

    poweroff
    exit
fi

# rename orig extension to dat.orig in cddata
find /root/Data/cddata -name '*.orig' ! -name '*.dat.orig' -exec rename -v 's/\.orig$/\.dat.orig/i' {} \;

# Move files into place
echo "Copying ATX files..."
copy_atx OptionMenu
copy_atx TitleMenu
copy_atx Warning

echo "Copying DAT files..."
copy_2d_dat end_mem
copy_2d_dat game2d_mem
copy_2d_dat game2d_vram
copy_common_dat com_mem
copy_menu_dat menu_mem_fj
copy_menu_dat menu_mem_us

echo "We're done, shutdown"
echo ""
poweroff

} >> "${USB_ROOT}/log.txt" 2>&1
