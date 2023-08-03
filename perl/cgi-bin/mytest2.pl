#!C:\strawberry\perl\bin\perl -w

use strict;

sub changeName
{
	my $curName = shift;
	print "Current name = $$curName\n";
	$$curName = "Loser!";
}

my $name = "Richard";
changeName(\$name);
print "New name = $name\n";
my $blah = chr(0xff) . chr(0xff);
print "$blah, are a retard\n";
