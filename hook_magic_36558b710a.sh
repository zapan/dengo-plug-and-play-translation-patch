#!/bin/sh

# Densha de Go! Plug & Play chimes patching script

USB_ROOT="/mnt"

error_exit() {
    # Blink the door light to indicate an error
    echo timer > /sys/class/leds/led2/trigger
    echo 100 > /sys/class/leds/led2/delay_on
    echo 100 > /sys/class/leds/led2/delay_off
    exit 1
}

{

# Stop Densha de Go! game app
/etc/init.d/S99dgtype3 stop

# Light the door light to indicate we're running
echo -n none > /sys/class/leds/led2/trigger
echo 1 > /sys/class/leds/led2/brightness

# Check if we need to create a backup
if [ -f "${USB_ROOT}/backup_required" ]; then
    # We're actually going to create a full factory install package that if you
    # decided to delete the game entirely for some reason, you can just add the
    # factory install flag to the drive and plug it in to reinstall.

    # Tar up the game
    cd /root
    if ! tar -c dgf Data/ | gzip -c > "${USB_ROOT}/dgtyp3zzzz.tar.gz"; then
        error_exit
    fi
    # Generate MD5 sum of the tarball
    cd "${USB_ROOT}"
    md5sum dgtyp3zzzz.tar.gz > dgtyp3zzzz.tar.gz.md5

    # Generate MD5 sum of the installed files (per factory install script)
    echo `(find /root/Data/ /root/dgf -type f -exec md5sum {} \;) | awk '{print $1}' | env LC_ALL=C sort | md5sum` > installed.md5
    # Remove backup flag if successful
    rm "${USB_ROOT}/backup_required"
fi

# Remount with write access
mount -o remount,rw /

if [ -f "${USB_ROOT}/backup_translation" ]; then

    echo "Translation files backup..."

    cd /root/Data/cddata

    mkdir -p "${USB_ROOT}/backup/cddata/2d"
    mkdir -p "${USB_ROOT}/backup/cddata/common"
    mkdir -p "${USB_ROOT}/backup/cddata/menu"

    cp 2d/end_mem.dat       "${USB_ROOT}/backup/cddata/2d/"
    cp 2d/game2d_mem.dat    "${USB_ROOT}/backup/cddata/2d/"
    cp 2d/game2d_vram.dat   "${USB_ROOT}/backup/cddata/2d/"
    cp common/com_mem.dat   "${USB_ROOT}/backup/cddata/common/"
    cp menu/menu_mem_fj.dat "${USB_ROOT}/backup/cddata/menu/"
    cp menu/menu_mem_us.dat "${USB_ROOT}/backup/cddata/menu/"

    cp 2d/end_mem.dat       2d/end_mem.orig
    cp 2d/game2d_mem.dat    2d/game2d_mem.orig
    cp 2d/game2d_vram.dat   2d/game2d_vram.orig
    cp common/com_mem.dat   common/com_mem.orig
    cp menu/menu_mem_fj.dat menu/menu_mem_fj.orig
    cp menu/menu_mem_us.dat menu/menu_mem_us.orig

    chmod 664 2d/end_mem.orig
    chmod 664 2d/game2d_mem.orig
    chmod 664 2d/game2d_vram.orig
    chmod 664 common/com_mem.orig
    chmod 664 menu/menu_mem_fj.orig
    chmod 664 menu/menu_mem_us.orig

    chown 1000:1000 2d/end_mem.orig
    chown 1000:1000 2d/game2d_mem.orig
    chown 1000:1000 2d/game2d_vram.orig
    chown 1000:1000 common/com_mem.orig
    chown 1000:1000 menu/menu_mem_fj.orig
    chown 1000:1000 menu/menu_mem_us.orig

    # Remove backup flag if successful
    rm "${USB_ROOT}/backup_translation"

    echo "Translation files backup OK."
fi


if [ -f "${USB_ROOT}/revert_translation" ]; then

    echo "Reverting translation files..."

    cd /root/Data/cddata

    mv 2d/end_mem.orig        2d/end_mem.dat
    mv 2d/game2d_mem.orig     2d/game2d_mem.dat
    mv 2d/game2d_vram.orig    2d/game2d_vram.dat
    mv common/com_mem.orig    common/com_mem.dat
    mv menu/menu_mem_fj.orig  menu/menu_mem_fj.dat
    mv menu/menu_mem_us.orig  menu/menu_mem_us.dat

    rm "${USB_ROOT}/revert_translation"

    echo "Translation files reverted OK."

    poweroff
    exit
fi


# Move files into place
cd /root/Data/cddata


df -h

echo "Log original files permissions..."
ls -al 2d/*.orig
ls -al common/*.orig
ls -al menu/*.orig


echo "Copying files..."
cp "${USB_ROOT}/translation/cddata/2d/end_mem.dat"        2d/end_mem.dat
cp "${USB_ROOT}/translation/cddata/2d/game2d_mem.dat"     2d/game2d_mem.dat
cp "${USB_ROOT}/translation/cddata/2d/game2d_vram.dat"    2d/game2d_vram.dat
cp "${USB_ROOT}/translation/cddata/common/com_mem.dat"    common/com_mem.dat
cp "${USB_ROOT}/translation/cddata/menu/menu_mem_fj.dat"  menu/menu_mem_fj.dat
cp "${USB_ROOT}/translation/cddata/menu/menu_mem_us.dat"  menu/menu_mem_us.dat


echo "Changing files permissions..."
chmod 664 2d/end_mem.dat
chmod 664 2d/game2d_mem.dat
chmod 664 2d/game2d_vram.dat
chmod 664 common/com_mem.dat
chmod 664 menu/menu_mem_fj.dat
chmod 664 menu/menu_mem_us.dat

chown 1000:1000 2d/end_mem.dat
chown 1000:1000 2d/game2d_mem.dat
chown 1000:1000 2d/game2d_vram.dat
chown 1000:1000 common/com_mem.dat
chown 1000:1000 menu/menu_mem_fj.dat
chown 1000:1000 menu/menu_mem_us.dat



echo "New files permissions..."
ls -al 2d/*.dat
ls -al common/*.dat
ls -al menu/*.dat

# We're done, shutdown
echo "We're done, shutdown"
poweroff

} > "${USB_ROOT}/log.txt" 2>&1
