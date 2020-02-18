# testarchives.pl
#
# Tests all the archives of the matching filetypes in the current directory and subdirectories.
# The results are saved in a text file named "corrupt.txt".
# If there is a directory named "corrupt" in the current directory, archives with errors will be moved to it.
#
# You are free to modify and distribute this file
# (C)'2010 malor89
#
# last modified: 11/21/10
#
##########################################################################

$sevenzip = "C:\\Program Files\\7-Zip\\7z.exe";  #path to 7z.exe from 7-zip program, make sure to use \\ and not single \ in path
$filetypes = "cbr|cbz|cb7";  #filetypes to test, use | between types
$skipdir = "System Volume Information|$RECYCLE.BIN|corrupt";   #don't scan these directories, use | between names

open (OUT, ">>corrupt.txt");
listdir(".");
printf ("%-79s\n", " ");
print "\n--- Done ---\n";
sleep(600);
close (OUT);
exit;

sub listdir{
	my ($dir) = @_;
	my ($file, @files, @list);
	opendir(DIR, $dir) || return;
	@files = grep { /^[^.]/} readdir(DIR);
	closedir DIR;

	foreach $file(sort(@files)) {
		if (-d "$dir\\$file") {
			if (! ($file =~/^$skipdir$/i)) {
				listdir("$dir\\$file");
			}
		} elsif ($file =~ /\.($filetypes)$/i) {
			open (DATA, "\"$sevenzip\" t \"$dir\\$file\"|");
			@list = <DATA>;
			close(DATA);
			$info = $list[$#list-1];
			if ($info =~ /Sub items Errors: (\d+)/) {
				if ($1 == 1) {
					printf ("%-79s\n", substr($file,0,70).": $1 Error");
				} else {
					printf ("%-79s\n", substr($file,0,69).": $1 Errors");
				}
				print OUT "$dir\\$file\t$1\n";
				if(not (-e "corrupt\\$file")) {
					rename  ("$dir\\$file", "corrupt\\$file");
				}
			} else {
				printf ("%-79s\r", substr($file,0,75).": OK");
			}
		}
	}
}
