Densha de Go! Plug & Play Translation Patcher
=======================================

This patch translates the menus and game elements in Densha de Go! Plug & Play from Japanese to English. 

Requirements
------------
You need to have a Densha de Go! Plug & Play Ver.1.13. In addition to this, you
will also need a USB flash drive and a powered USB OTG hub. Please have at
least 2GB free on the USB flash drive for a backup.

The USB OTG hub I use can be found [here](https://www.amazon.ca/gp/product/B07BDJN76M).
You can also use an angle adapter instead of a hub, but I find the quality
inconsistent, meaning that sometimes it may not make contact properly and cause
issues.

Usage
-----

1. Prepare a USB drive by formatting it to FAT32. Make sure that there is a
   partition table present, and the FAT32 partition is the first one, as the
   factory script specifically looks at the first partition. Please search
   online if you need instructions on how to do this.
2. Copy all of the files in this repository (including the `translation` folder) into the root of your USB drive. Eject the USB
   drive from your computer after it is finished copying.
3. Plug the USB drive into your USB OTG hub, then plug the hub into the micro
   USB port on the back of your Densha de Go! Plug & Play. Plug the power
   cable for your USB OTG hub into the hub and a USB power adapter.
4. Turn on your Densha de Go! Plug & Play.
5. The patching script will stop the game app and make a backup of your game
   files, then patch the game data files. While this is in progress, the door light will light. When it is complete, the unit
   will shut down and you can unplug the USB hub and plug in a regular USB
   power cable. If there is an error during processing, the door light will
   flash. If an error occurs, you can find a log at `log.txt` on the USB drive.
6. If the patch was successful, you should now be able to watch almost the entire game in English.

Note: depending on the speed of your USB drive, the backup stage may take a
long time. Expect it to take 30-60 minutes to complete. Once it has been
completed, you can rerun the patching process without going through backup
again if necessary. 

Please safekeep the backup files inside `backup` folder: `dgtyp3zzzz.tar.gz`,
`dgtyp3zzzz.tar.gz.md5`, `installed.md5` and `cddata` folder (it contains your original DAT files)


Uninstallation
--------------
Place a blank file named `revert_translation` on to the USB drive and repeat steps 3-5 to
revert the patch.

Translation Patch Credits
--------------
- Thanks to [DDGCrew](https://sites.google.com/view/ddgcrew/games/densha-de-go-final) team for their awesome translation to English.
- DAT files have been ported from the [DDGCrew](https://sites.google.com/view/ddgcrew/games/densha-de-go-final) PC version to the Plug & Play version using the tools created by [GMMan](https://github.com/GMMan):
  1. [Densha de Go! Final Modding Library](https://github.com/GMMan/libdgf) 
  2. [Densha de Go! Final Texture Converter](https://github.com/GMMan/dgf-texture-convert)
