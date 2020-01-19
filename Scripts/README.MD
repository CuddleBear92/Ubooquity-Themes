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