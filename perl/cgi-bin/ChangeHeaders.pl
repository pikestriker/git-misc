#!C:/strawberry/perl/bin/perl -w

use strict;

my @files=`dir /b`;

foreach my $curFile (@files)
{
	chomp $curFile;
	open (FILE, "<$curFile") or die "Unable to open the file $curFile:  $!";
	open (OUTFILE, ">${curFile}.tmp") or die "Unable to open output file ${curFile}.tmp:  $!";
	while (<FILE>)
	{
		if ($_ =~ /^\#\!\/usr\/bin\/perl/)
		{
			print OUTFILE "#!C:\\strawberry\\perl\\bin\\perl -w\n";
		}
		else
		{
			print OUTFILE;
		}
	}
	close(OUTFILE);
	close(FILE);
	
	`del $curFile`;
	`rename $curFile.tmp $curFile`;
}
