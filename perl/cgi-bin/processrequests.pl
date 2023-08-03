#!C:\strawberry\perl\bin\perl -w

use strict;
use database;
use CGI;
use CGI::Session;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use utilities qw( redirectIfNotPrivy
									changeAccount );

database::mydbConnect();

redirectIfNotPrivy();
my $cgi = new CGI();
my $login = 1;
my $loginError = 0;

my $referer = $cgi->param('referer');
my $submitVal = $cgi->param("submit");

if ($submitVal eq "logout")
{
	if (defined($utilities::curSess))
	{
		$utilities::curSess->delete();
		print $cgi->redirect($utilities::rdLoginPage);
	}
}
elsif ($submitVal eq "changeAccount")
{
	my $newAcct = $cgi->param("acct_id");
	
	my $err = changeAccount($newAcct) if (defined($newAcct));
	
	print $utilities::curSess->header(-location => $referer,
						      					        -status   => 302);
}

database::mydbDisconnect();
