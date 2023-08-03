#!C:\strawberry\perl\bin\perl -w

use strict;
use database;

print "Hello there!\n";

database::mydbConnect();

my $retVal = database::getLoVCategory("TEST");

print "$retVal\n";

database::mydbDisconnect();
