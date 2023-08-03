#!C:\strawberry\perl\bin\perl -w

use strict;
use database;
use CGI;
use CGI::Session;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use utilities qw( checkLastAccount
									populateSessionVars
									populateRDs );

my $curSess = CGI::Session->load();
my $cgi = new CGI();
my $login = 1;
my $loginError = 0;

my $username = $cgi->param('uname');
my $password = $cgi->param('password');
my $firstName;
my $surName;
my $userId;
my $acctId;
my $errCd = 0;
my $referer = $cgi->param('referer');

my $websiteURL = "http://localhost/";
my $homeScriptName = "home.pl";
my $homeScript = $websiteURL . "cgi-bin/$homeScriptName";
my $createAccountSendRequest = "cgi-bin/createaccountsendrequest.pl";

#if (!defined($referer) || $referer eq "")
#{
#	$referer = $homeScript;
#}

# $cgi->delete_all();

if (defined($curSess) && !$curSess->is_empty() && !$curSess->is_expired())
{
  $firstName = $curSess->param('first_nm');
  $surName = $curSess->param('sur_nm');
  $userId = $curSess->param('user_id');
  print $curSess->header(),
        $cgi->start_html("Login Page"),
        $cgi->p("You are already logged in $surName, $firstName!"),
        $cgi->end_html();
  exit(0);
}
elsif (defined($username) && defined($password))
{
#  print $curSess->header(),
#        $cgi->start_html("Login Page"),
#        $cgi->p("Your have successfully logged in $username and $password!");
#  database::getUsers2($username, $password) or die "Error calling getUsers2\n";
#  print $cgi->end_html;
#    exit(0);
  database::mydbConnect();
  $errCd = database::getUserByUsernameAndPassword($username, $password);
  if ($errCd < 0)
  {
    $loginError = 1;
    $login = 1;
  }
  else
  {
    # successfully logged in get the information back from the database call
    $curSess = new CGI::Session();
    $firstName = $database::resRef->[0]->{'user_first_nm'};
    $surName = $database::resRef->[0]->{'user_sur_nm'};
    $userId = $database::resRef->[0]->{'userid'};
    $acctId = $database::resRef->[0]->{'last_acct_id'};
    my $err = checkLastAccount($userId, $acctId);
    my $errMsg = $utilities::utilErrMsg;
    
    $curSess->param("first_nm", $firstName);
    $curSess->param("sur_nm", $surName);
    $curSess->param("user_id", $userId);
    $curSess->param("acct_id", $acctId);
    $curSess->param("err", $err);
    $curSess->param("err_msg", $errMsg);
    populateRDs();
    
    $referer = $utilities::rdCreatePage if ($acctId == 0);
    $utilities::acctId = $acctId;
    $utilities::userId = $userId;
    
    $errCd = utilities::autoProcessBuckets();
    
    if ($errCd < 0)
    {
    	# utilities::printDebug($errCd, $utilities::utilErrMsg);
    	database::rollbackTrans();
    }
    else
    {
    	database::commitTrans();
    }
    
    if (!defined($referer) || $referer eq "")
    {
    	$referer = $utilities::rdHomePage;
    }
    
    if ($referer && $referer ne "")
    {
      print $curSess->header(-location => $referer,
                             -status => 302);
      database::mydbDisconnect();
      exit 0;
    }
    
    $login = 0;
  }
  database::mydbDisconnect();
}

if ($login)
{
  print $cgi->header();
  print $cgi->start_html("Login Page");
  
  # print $cgi->p($referer);
  if (defined($referer) && $referer ne "" && $referer ne $homeScript)
  {
    print $cgi->p("You have tried to access page $referer, please login in first (you will be redirected back to the page once you log in"), $cgi->br(), "\n";
  }
  
  print "<form name=\"myform\" method=\"POST\" action=\"/cgi-bin/login.pl\">\n";

  if ($referer)
  {
    print "<input type=\"hidden\" name=\"referer\" value=\"$referer\" />\n";
  }
  print "Username:  <input type=\"text\" name=\"uname\" />\n";
  print "Password:  <input type=\"password\" name=\"password\" />\n";
  print "<input type=\"reset\" name=\"reset\" />\n";
  print "<input type=\"submit\" name=\"submit\" />\n";
  
  if ($loginError)
  {
    print "<p>Error Code:  $errCd, Error trying to login, please try again!\n";
    # print $cgi->p($database::errMsg);
  }
  print "</form>\n";
  print $cgi->end_html();
}
else
{
  $firstName = $curSess->param("first_nm");
  $surName = $curSess->param("sur_nm");
  print $curSess->header(),
        $cgi->start_html("Login Page"),
        $cgi->p("You have successfully logged in $firstName $surName!"),
        $cgi->end_html();
}
