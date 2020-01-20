# comixology-to-ubooquity.py
Requires Python3
Requires Requests, beautifulsoup4 and html5lib

Use --scrape-series to scrape series pages and images aswell as publishers.
Use -d/--destination to set destination
Use -D for request delays in seconds.
-ss to skip series folders.
-sp to skip publisher folders.

Set Requests on a timer of atleast 2 sec unless you are willing to risk getting blocked (a VPN might be smart if you set no limits)
A full scrape can take a day or two.

Example of run: `python3 comixology-to-ubooquity.py --scrape-series -D 1 3 -ss -sp -d "/volume1/Comics/CUexport/"`


If the script give you an error mid run, please make an issue about it.
Clearing out the Publisher or Series folder (depending on your skip settings) and retrying the script will prob work if everything is setup correctly.

Note the script makes an extra un-needed folder for all the publisher images, this is not required with v2 of the Comixology theme but could be used for those that use v1... for some reason.

# Cover_Extract_0.5.py
Extracts Files marked as cover in the ComicRack .xml metadata files inside of archives.

# cvinfogen.py
Generates cvinfo file with comicvine urls from CVID's in folder names.
Just like MyLar and others make but rather after the fact.

# find_nonwebp.py
Finds archives with jpegs and other image formats that ISN'T WebP inside the archive.
Generates a Comicbook List you can import into ComicRack.
This is made cause there is no easy way to filter or find these files inside of ComicRack, this is for cleanup.

# UCC
Backup of the Generator
Generates Comic Story arcs, Authors and Book Series.
https://ubooquity.userecho.com/communities/1/topics/620-generic-comic-arcs-for-any-theme