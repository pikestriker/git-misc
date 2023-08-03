#!C:\strawberry\perl\bin\perl -w

use CGI;
use CGI::Session;
use strict;

my $cgi = new CGI();
my $curSess = CGI::Session->load();

if (defined($curSess))
{
	if (!$curSess->is_empty() && !$curSess->is_expired())
	{
		print $curSess->header();
		print "Session Id:  " . $curSess->id();
	}
	else
	{
		print $cgi->header();
		print "Session isn't defined or is expired";
	}
}
else
{
	print $cgi->header();
	print "Session isn't defined";
}