Comixology theme for Ubooquity by KanadaKid

***************************************************
** So a lot of this stuff is hacky, hopefully    **
** it works for you as well as it works for me.  **
***************************************************

To install the base theme:
Unzip comixology.zip to your Ubooquity\themes folder

Settings necessary for this to work correctly:
        ===================Comics=====================
        Comics cover width:	                202
        Comics cover height:                314
        Items per page:	                    36

        ==================Advanced====================
        Hide empty folders:	                true
        Bypass single root folder:	        true
        Enable folder metadata display:	    true
        Reverse proxy prefix:               ubooquity

* If you do not intend to use the publisher pages/data,                    *
* delete comics.css, make a copy of books.css and rename it to comics.css  * 
            
------------------------------------------------------
To install the publisher pages, things get a bit more complicated.

This expects your comic folder to be structured like so:

Comics folder > Publisher > Comic
(ie. Comics\Marvel\Superior Spider-man (2013))

If this is how your stuff is arranged, you can extract 
comixology-extras.zip into your Comics folder.

This should leave a folder.css and folder-info.html in the 
root of your comic folder, and each publisher (Marvel, DC Comics, etc)
folder should get a folder.css, folder.jpg, folder-info.html and header.jpg.

If your publisher folders are named differently, you should just need to move the 
files to the correct folder.

**IMPRINT LINKS (THE BUTTON BAR BELOW THE HEADER) WILL NEED TO BE EDITED MANUALLY**
There is no rhyme or reason behind how Ubooquity numbers pages, so this can't be done automatically.

Theoretically, this should be all it takes to work... 
if not, post in the release thread and we'll try to sort it out.

------------------Customization-------------------------

To set Featured publishers, edit folder-info.html in the root of the comics folder (next to publishers.jpg). 
Use the name of the publisher folder by name.