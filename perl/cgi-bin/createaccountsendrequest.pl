#!C:\strawberry\perl\bin\perl -w

use strict;
use CGI;
use CGI::Session;
use CGI::Carp qw( warningsToBrowser fatalsToBrowser );
use database;
use utilities qw( getScriptName );

my $cgi        = new CGI();
my $curSess    = CGI::Session->load();
my $websiteURL = "http://localhost/";
my $scriptName = getScriptName($ENV{'SCRIPT_NAME'});
my $thisScript = $websiteURL . "cgi-bin/$scriptName";
my $loginURL   = $websiteURL . "cgi-bin/login.pl";
my $processRequest = $websiteURL . "cgi-bin/processrequests.pl";
my $formName1  = "createaccount";
my $formName2  = "sendrequest";

if (!defined($curSess) || $curSess->is_empty() || $curSess->is_expired())
{
  print $cgi->redirect($loginURL . "?referer=$thisScript");
}

# get session and cgi variables
my $userId           = $curSess->param("user_id");
my $firstName        = $curSess->param("first_nm");
my $surName          = $curSess->param("sur_nm");
my $acctId           = $curSess->param("acct_id");

my $submitVal        = $cgi->param("submit");
my $userNickname     = $cgi->param("user_nickname");
my $userEmail        = $cgi->param("user_email");
my $formAcctId       = $cgi->param("form_acct_id");
my $userNicknameMark = "";
my $userEmailMark    = "";
my $formAcctIdMark   = "";
my $dbError          = 0;

sub processFields
{
	if ($submitVal eq "createAccount")
	{
		my $tempVal = database::createNewAccount($userId);
		if ($tempVal < 0)
		{
			$dbError = 1;
		}
		else
		{
			$acctId = $tempVal;
			$curSess->param("acct_id", $acctId);
		}
	}
	elsif ($submitVal eq "sendRequest")
	{
		# need at least one input to send a request to a user
		if (defined($userNickname) && $userNickname ne "")
		{
			database::sendRequestByUserNickname($userNickname, $userId);
		}
		elsif (defined($userEmail) && $userEmail ne "")
		{
			database::sendRequestByUserEmail($userEmail, $userId);
		}
		elsif (defined ($formAcctId) && $formAcctId ne "")
		{
			database::sendRequestByAcctId($formAcctId, $userId);
		}
		else
		{
			$userNicknameMark =
			$userEmailMark =
			$formAcctIdMark =
			"At least one of these fields is required to send a request";
		}
	}
}

database::mydbConnect();

if (defined($submitVal))
{
	processFields();
}

# start of the HTML
print $curSess->header(),
      $cgi->start_html(-title => "Create an Account or Send a Request",
                       -style => {'src' => '/css/mainstyles'});

print "<p>Currently logged in as $surName, $firstName</p>\n";
print "<p>Your User Id = $userId account Id = $acctId</p>\n",
      "<p><div class=\"logout\"><a href=\"$processRequest?submit=logout\">logout</a></div></p>";
print "<h1>Create an Account or Send a Request</h1>\n";

if ($dbError)
{
	print "<p>$database::dbErrMsg</p>\n";
}

if ($acctId == 0)
{
	print "<p>You currently do not have an budget account created nor do you belong as a member on another ",
	      "persons account</p>\n";
}

print <<endHTML; 
				<div class="subheading">Create an account:</div>
				<form name="$formName1" action="$thisScript" action="post">
				<input type="submit" name="submit" value="createAccount" />
				</form>
				<div class="subheading">Send a request:</div>
				<form name="$formName2" action="$thisScript" action="post">
				<table>
				<tr>
				<td>User name:</td>
				<td><input type="text" name="user_nickname" value="$userNickname" /></td>
				<td><div class="mark">$userNicknameMark</div></td>
				</tr>
				<tr>
				<td>User email:</td>
				<td><input type="text" name="user_email" value="$userEmail" /></td>
				<td><div class="mark">$userEmailMark</div></td>
				</tr>
				<tr>
				<td>Account Number:</td>
				<td><input type="text" name="form_acct_id" value="$formAcctId" /></td>
				<td><div class="mark">$formAcctIdMark</div></td>
				</tr>
				</table>
				<input type="reset" value="Reset" />
				<input type="submit" name="submit" value="sendRequest" />
				</form>
endHTML

database::mydbDisconnect();