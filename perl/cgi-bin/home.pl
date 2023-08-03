#!C:\strawberry\perl\bin\perl -w

use strict;
use database;		# my defined perl module
use CGI;
use CGI::Session;
use POSIX;		# using this for dates
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use utilities qw( printHeader
									redirectIfNotPrivy );

my %scriptProcessed=();
database::mydbConnect();

redirectIfNotPrivy();

printHeader("Home Page", "Home Page");

my $err = database::getAllUserGroupsByUserId($utilities::userId);
my $recs = $database::resRef;

print "<input type=\"button\" value=\"Get Response\" onclick=\"callServerScript('/cgi-bin/processbuckets.pl', '', callBackFunction);\" />\n";
print "<div id=\"ajaxarea\"></div>\n";

print "<p>Here is a list of places that you can go:</p>\n";
foreach my $ref (@$recs)
{
	$err = database::getAllGroupScriptsByGroupCd($ref->{'group_cd'});
	
	my $scriptList = $database::resRef;
	
	foreach my $script (@$scriptList)
	{
		if (!defined($scriptProcessed{$script->{'script_name'}}))
		{
			$scriptProcessed{$script->{'script_name'}} = 1;
			my $scriptURL = $utilities::site . "cgi-bin/" . $script->{'script_name'};
			print "<a href=\"$scriptURL\">$scriptURL</a><br>\n";
		}
	}
}
database::mydbDisconnect();
