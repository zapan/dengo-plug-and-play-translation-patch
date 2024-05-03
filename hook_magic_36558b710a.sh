#!/bin/sh

# Densha de Go! Plug & Play translation patching script
USB_ROOT="/mnt"
ELF="/root/dgf"
ELF_BACKUP="/root/dgf_trans.orig"

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
    echo "backup ${FILEPATH} to ${ORIGINAL}"
    ls -al ${FILEPATH}
    md5sum ${FILEPATH}
    mv ${FILEPATH} ${ORIGINAL}
  fi
  echo "Copying from USB to ${FILEPATH}"
  cp "${USB_ROOT}/translation/${BASENAME}.atx" ${FILEPATH}
  chmod 664 ${FILEPATH}
}

copy_elf() {
  # Check that the game executable is the expected version
  if ! sha1sum -c "${USB_ROOT}/translation/dgf.sha1"; then
      if ! sha1sum -c "${USB_ROOT}/translation/dgf_chimes.sha1"; then
        echo "Game executable SHA1 hash mismatch, this version may not be supported or the game has already been patched."
        error_exit
      fi
  fi

  if [ ! -f ${ELF_BACKUP} ]; then
      echo "backup ${ELF} to ${ELF_BACKUP}"
      ls -al ${ELF}
      sha1sum ${ELF}
      mv ${ELF} ${ELF_BACKUP}
  fi

  # Do patching
  # Copy bspatch to /tmp and apply execute permission
  cp "${USB_ROOT}/bin/bspatch" /tmp/bspatch
  chmod +x /tmp/bspatch


  # Patch the game executable
  if ! LD_LIBRARY_PATH="${USB_ROOT}/bin" /tmp/bspatch ${ELF} /root/dgf_patched "${USB_ROOT}/translation/dgf.patch"; then
      echo "Error patching"
      error_exit
  fi

  # Check that the patched executable is valid
  if ! sha1sum -c "${USB_ROOT}/translation/dgf_patched.sha1"; then
      echo "Patching appears to have produced incorrect file."
      rm /root/dgf_patched
      error_exit
  fi

  # Move files into place
  mv ${ELF} ${ELF_BACKUP}
  mv /root/dgf_patched ${ELF}

  chmod 555 ${ELF}
  chown 1000:1000 ${ELF}
}

copy_dat() {
  BASENAME=$1
  FOLDER=$2
  ORIGINAL="/root/Data/cddata/${FOLDER}/${BASENAME}.dat.orig"
  FILEPATH="/root/Data/cddata/${FOLDER}/${BASENAME}.dat"
  if [ ! -f ${ORIGINAL} ]; then
    echo "backup ${FILEPATH} to ${ORIGINAL}"
    ls -al ${FILEPATH}
    md5sum ${FILEPATH}
    mv ${FILEPATH} ${ORIGINAL}
  fi
  echo "Copying from USB to ${FILEPATH}"
  cp "${USB_ROOT}/translation/cddata/${FOLDER}/${BASENAME}.dat" ${FILEPATH}
  chmod 664 ${FILEPATH}
  chown 1000:1000 ${FILEPATH}
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

    MD5=$(md5sum /root/Data/cddata/common/com_mem.dat | awk '{printf $1}')
    if [ "${MD5}" = "ed52c9807e213e55d9fb9181196a8a88" ]; then
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
    else
      echo "Full backup already done"
    fi

    # Remove backup flag if successful
    rm "${USB_ROOT}/backup_required"
fi

# Remount with write access
mount -o remount,rw /

if [ -f "${USB_ROOT}/backup_translation" ]; then

    MD5=$(md5sum /root/Data/cddata/common/com_mem.dat | awk '{printf $1}')
    if [ "${MD5}" = "ed52c9807e213e55d9fb9181196a8a88" ]; then
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
    else
      echo "Translation backup already done"
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

    if [ ! -f ${ELF_BACKUP} ]; then
        echo "Original dgf executable not found, cannot revert."
        error_exit
    fi
    mv ${ELF_BACKUP} ${ELF}

    rm "${USB_ROOT}/revert_translation"
    echo "Translation files reverted OK."
    echo ""

    poweroff
    exit
fi

# Rename orig extension to dat.orig in cddata
echo "Renaming orig extension to dat.orig in cddata"
find /root/Data/cddata/ -name "*.orig" ! -name '*.dat.orig' -exec sh -c 'mv "$1" "${1%.orig}.dat.orig"' _ {} \;
echo ""

# Move files into place
echo "Copying ATX files..."
copy_atx OptionMenu
copy_atx TitleMenu
copy_atx Warning
echo ""

echo "Copying DAT files..."
copy_2d_dat end_mem
copy_2d_dat game2d_mem
copy_2d_dat game2d_vram
copy_common_dat com_mem
copy_menu_dat menu_mem_fj
copy_menu_dat menu_mem_us
echo ""

echo "Copying ELF file..."
copy_elf

echo "We're done, shutdown"
echo ""
poweroff

} >> "${USB_ROOT}/log.txt" 2>&1
