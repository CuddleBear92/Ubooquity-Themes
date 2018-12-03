##cvinfogen.py and bat
Generates the cvinfo file for mylar to use to match with out of the Exported CVID ComicRack can export.
This makes matching flawless when you match correct in CR and names with the orgnaizer.
Made to be used with Python3, just `python cvinfogen PATH-TO-COMICS`.
you can also launch with -f to force and overwrite so it will overwrite if something was wrong or files where already in place (from mylar for example)

##importer.py & librarysync.py
importer.py & librarysync.py will use the folder name as is without touching it, this is broken on the normal mylar release.
This allows you to have any comic structure in mylar for easy use.
On the normal release it would make and map to a folder ruled by the rename rules, even if the renaming was turned off.
This just allows it to match correct no matter the folder name or the folder naming format (as it doesnt create anymore).

