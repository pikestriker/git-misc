#!C:\strawberry\perl\bin\perl -w

package utilities;

use strict;
use Exporter;
use CGI;
use CGI::Session;
use database;
use POSIX;		# using this for dates
use Date::Calc qw(Days_in_Month Delta_Days Add_Delta_Days Add_Delta_YM);

our @ISA = qw( Exporter );
our @EXPORT = qw();
our @EXPORT_OK = qw( getScriptName
										 getFormName
										 checkLastAccount
										 showAccounts
										 privyToAccount
										 redirectIfNotPrivy
										 resolveRedirect
										 printHeader
										 processFields
										 trimWhitespace
										 displayForm
										 printFooter
										 changeAccount
										 populateSessionVars
										 populateRDs );

use constant NO_PARM => -1001;
use constant LOGIN_PAGE 					=> 'LOGIN';
use constant CREATE_PAGE					=> 'CRTEACCTSENDREQUEST';
use constant HOME_PAGE						=> 'HOME_PAGE';
use constant SITE									=> 'SITE';
use constant PROCESS_REQUEST			=> 'PROCESSREQUESTS';

our $utilErrMsg;
our $userId;
our $firstName;
our $surName;
our $acctId;
our $maxRecs = 50;
our $err;
our $rollbackErr;
our $commitErr;
our $errMsg;
our $rollbackErrMsg;
our $commitErrMsg;
our $debug;
our @errArray;

our $rdLoginPage;
our $rdCreatePage;
our $rdHomePage;
our $rdProcessRequest;
our $site;
our $curSess;

# variable definitions that need to remain persistent over multiple function calls
my %markFields       = ();
my %valueFields			 = ();
my $currencyRegEx    = "[+-]?\\d+\\.?\\d{0,2}";
my $posCurrencyRegEx = "\\+?\\d+\\.?\\d{0,2}";
my $integerRegEx     = "[+-]?\\d+";
my $floatRegEx       = "[+-]?\\d+\\.?\\d+";
my $dateRegEx        = "\\d{4}-\\d{2}-\\d{2}";

my $currencyRegExError = "Invalid format!  Please follow the format [+/-]9*.99 (example 22.43 or -35.82)";
my $posCurrencyRegExError = "invalid format!  Please follow the format [+]9*.99 (example 22.43 or +24)";
my $requiredField = "Required field!";
my $dateRegExError = "Invalid format!  Please follow the format yyyy-mm-dd";

my $offset = 0;

my $processError = 0;

sub getScriptName
{
	undef($utilErrMsg);
	
	my $errPre = "Error in getScriptName:  ";
	my $scriptName = shift();
	
	if (!defined($scriptName))
	{
		$utilErrMsg = $errPre . "expects one parameter (script name)";
		return NO_PARM;
	}
	
	# this function assumes that you passed in the script name from the environment variable
	# so it assumes that there is a /cgi-bin/ prefix to the script name that it will strip out
	return substr($scriptName, 9);
}

sub getFormName
{
	undef($utilErrMsg);
	
	my $errPre = "Error in getFormName:  ";
	my $scriptName = shift();
	
	if (!defined($scriptName))
	{
		$utilErrMsg = $errPre . "expects one parameter (script name)";
		return NO_PARM;
	}
	
	my @arrayVals = split ("/", $scriptName);
	
	my $lastVal = pop(@arrayVals);
	
	if (defined($lastVal))
	{
		@arrayVals = split(/\./, $lastVal);
		
		return $arrayVals[0];
	}
	
	$utilErrMsg = $errPre . "problem with the split command";
	return -2;
}

sub checkLastAccount
{
	undef($utilErrMsg);
	
	my $errPre = "Error in checkLastAccount:  ";
	
	my $disconnect = 0;
	
	my $userId = shift();
	my $lastAcctId = $_[0];
	my $err;
	
	if (!defined($userId) || !defined($lastAcctId))
	{
		$utilErrMsg = $errPre . "expects two parameters (user Id and last account Id)";
		return NO_PARM;
	}
	
	if (!database::isConnected())
	{
		database::mydbConnect();
		$disconnect = 1;
	}
	
	if (database::getAccount($lastAcctId) == 0)
	{
		if (database::getUserAccount($userId, $lastAcctId) < 0)
		{
			if (database::getUserGroup($userId, "ADMIN") < 0 || $lastAcctId == 0)
			{
				# not authorized for that account, get their default
				if (database::getAllAccounts($userId) == 0)
				{
					$lastAcctId = $database::resRef->[0]->{'acct_id'};
				}
				else
				{
					$lastAcctId = $database::resRef->[0]->{'acct_id'};
					$utilErrMsg = "Here, $lastAcctId";
				}
				
				$err = database::updateLastAcctId($userId, $lastAcctId);
				$_[0] = $lastAcctId;
			}
		}
	}
	else
	{
		# account doesn't exist
		$err = database::getAllAccounts($userId);
		
		if ($err < 0)
		{
			if ($disconnect)
			{
				database::mydbDisconnect();
				$utilErrMsg = $errPre . "no accounts associated with user, " . $database::dbErrMsg;
				if (database::getUserGroup($userId, "ADMIN") == 0)
				{
					if (database::selectFirstAccount() == 0)
					{
						$lastAcctId = $database::resRef->{'acct_id'};
					}
					else
					{
						$lastAcctId = 0;
					}
				}
				else
				{
					$lastAcctId = 0;
				}
			}
		}
		else
		{
			$lastAcctId = $database::resRef->[0]->{'acct_id'};
		}
		
		$err = database::updateLastAcctId($userId, $lastAcctId);
		$_[0] = $lastAcctId;
	}
	
	if ($disconnect)
	{
		database::mydbDisconnect();
	}
	
	return 0;
}

sub showAccounts
{
	undef($utilErrMsg);

	my $errPre = "Error in showAccounts:  ";
	my $disconnect = 0;
	
	my $userId = shift();
	my $acctId = shift();
	
	if (!defined($userId) || !defined($acctId))
	{
		$utilErrMsg = $errPre . "expects two parameters (user Id and account Id)";
		return -1;
	}
	
	if (!database::isConnected())
	{
		database::mydbConnect();
		$disconnect = 1;
	}
	
	database::getAllAccounts($userId);
	
	my $acctList = $database::resRef;
	
	print <<endHTML;
	      <div class="subheading">Account Selection:</div>
	      <form name="changeaccount" method="post" action="processrequests.pl">
	      <input type="hidden" name="referer" value="http://$ENV{'HTTP_HOST'}$ENV{'SCRIPT_NAME'}" />
	      <select width="30" name="acct_id">
endHTML
	
	foreach my $curAcct (@$acctList)
	{
		my $curAcctId = $curAcct->{'acct_id'};
		my $dbErr = database::getAccountOwner($curAcctId);
		
		if ($dbErr < 0)
		{
			database::mydbDisconnect if ($disconnect);
			$utilErrMsg = $errPre . "Failed to get account owner, " . $database::dbErrMsg;
			return database::NO_REC;
		}
		
		my $ownerId = $database::resRef->[0]->{'userid'};
		$dbErr = database::getUserById($ownerId);
		
		if ($dbErr < 0)
		{
			database::mydbDisconnect if ($disconnect);
			$utilErrMsg = $errPre . "Failed to get user by Id, " . $database::dbErrMsg;
			return database::NO_REC;
		}
		my $userNickname = $database::resRef->[0]->{'user_nickname'};
		
		$dbErr = database::getAccount($curAcct->{'acct_id'});
		
		if ($dbErr < 0)
		{
			database::mydbDisconnect if ($disconnect);
			$utilErrMsg = $errPre . "Failed to get account record, " . $database::dbErrMsg;
			return database::NO_REC;
		}
		my $acctDesc = $database::resRef->[0]->{'acct_desc'};
		
		my $selOption = "Owner:  $userNickname, Account:  $acctDesc (acct# $curAcct->{'acct_id'})";
		
		print "<option value=\"$curAcctId\"";
		print " selected" if ($curAcctId == $acctId);
		print ">$selOption</option>\n";
	}
	print <<endHTML;
	      </select>
	      <input type="submit" name="submit" value="changeAccount" />
	      </form>
endHTML
	
	if ($disconnect)
	{
		database::mydbDisconnect();
	}
	
	return 0;
}

sub privyToAccount
{
	undef ($utilErrMsg);
	
	my $errPre = "Error in privyToAccount:  ";
	
	my $userId = shift();
	my $acctId = shift();
	my $disconnect = 0;
	my $privledged = 0;
	
	if (!defined($userId) || !defined($acctId))
	{
		$utilErrMsg = $errPre . "expects two paramters (user Id and account Id)";
		return 0;					# not priviledged to view account
	}
	
	if (!database::isConnected())
	{
		database::mydbConnect();
		$disconnect = 1;
	}
	
	my $err = database::getAccount($acctId);
	
	if ($err == 0)			# record found
	{
		$err = database::getUserAccount($userId, $acctId);
		
		if ($err == 0)		# record found
		{
			$privledged = 1;
		}
		else
		{
			$err = database::getUserGroup($userId, "ADMIN");
			
			if ($err == 0)   # record found
			{
				$privledged = 1;
			}
		}
	}
	
	$utilErrMsg = $errPre . "database error, " . $database::dbErrMsg if ($err < 0);
		
	database::mydbDisconnect() if ($disconnect);
	
	return $privledged; 
}

sub redirectIfNotPrivy
{
	undef($utilErrMsg);
	
	my $errPre = "Error in redirectIfNotPrivy:  ";
	
	$curSess = CGI::Session->load() if (!defined($curSess));
	my $cgi = new CGI();
	
	populateSessionVars();
	# printDebug();
	
	my $disconnect = 0;
	if (!database::isConnected())
	{
		database::mydbConnect();
		$disconnect = 1;
	}
	
	my $privyToPage = privyToPage();
	my $privledged = privyToAccount($userId, $acctId);
	
	if (!$privledged)
	{
		# going to redirect but set the last acct to zero
		my $err = database::getAllAccounts($userId);
		
		if ($err < 0)
		{
			# not associated with any accounts
			database::mydbDisconnect() if (database::isConnected());
			
			print $curSess->header(-location => $rdCreatePage,
						      					 -status   => 302);
		  exit();
		}
		
		my $firstAcctId = $database::resRef->[0]->{'acct_id'};
		
		$acctId = $firstAcctId;
		$curSess->param("acct_id", $acctId);
		database::updateLastAcctId($userId, $acctId);
		
		database::mydbDisconnect() if (database::isConnected());
		
		print $curSess->header(-location => $rdHomePage,
		                       -status => 302);
		exit();
	}
	
	if (!$privyToPage)
	{
		database::mydbDisconnect() if (database::isConnected());
		
		print $curSess->header(-locaction => $rdHomePage,
					      					 -status    => 302);
		exit();
	}
	
	database::mydbDisconnect if ($disconnect);
	
	return 0;
}

sub resolveRedirect
{
	undef($utilErrMsg);
	
	my $errPre = "Error in resolveRedirect:  ";
	
	my $rdName = shift();
	
	if (!defined($rdName))
	{
		$utilErrMsg = $errPre . "expects one parameter (redirection name)";
		return NO_PARM;
	}
	
	my $disconnect = 0;
	my $resolve = "";
	
	if (!database::isConnected())
	{
		database::mydbConnect();
		$disconnect = 1;
	}
	
	my $err = database::getRedirect($rdName);
	
	if ($err < 0)
	{
		$utilErrMsg = $errPre . $database::dbErrMsg;
		database::mydbDisconnect() if ($disconnect);
		return database::NO_REC;
	}
	
	my $rdPage = $database::resRef->[0]->{'rd_page'};
	
	if ($rdPage =~ m/@/)
	{
		my @list = split ("@", $rdPage);
		if (scalar(@list) != 3)
		{
			$utilErrMsg = $errPre . "misuse of the @ symbol in redirect statement";
			database::mydbDisconnect() if ($disconnect);
			return -1;
		}
		
		$resolve = resolveRedirect($list[1]);
    $resolve = $resolve . $list[2];
    
	}
	else
	{
		$resolve = $rdPage;
	}
	
	database::mydbDisconnect() if ($disconnect);
	return $resolve;
}

sub populateRDs
{
	return 0 if (defined($site) && defined($rdLoginPage) && defined($rdHomePage) && defined($rdCreatePage));
	undef ($utilErrMsg);
	
	my $errPre = "Error in populateRDs:  ";
	
	my $disconnect = 0;
	
	if (!database::isConnected())
	{
		database::mydbConnect();
		$disconnect = 1;
	}
	
	$rdLoginPage  = resolveRedirect(LOGIN_PAGE);
	
	if (defined($utilErrMsg))
	{
		database::mydbDisconnect() if ($disconnect);
		return -1;
	}
	
	$rdHomePage   = resolveRedirect(HOME_PAGE);
	
	if (defined($utilErrMsg))
	{
		database::mydbDisconnect() if ($disconnect);
		return -2;
	}
	
	$rdCreatePage = resolveRedirect(CREATE_PAGE);
	
	if (defined($utilErrMsg))
	{
		database::mydbDisconnect() if ($disconnect);
		return -3;
	}
	
	$rdProcessRequest = resolveRedirect(PROCESS_REQUEST);
	
	if (defined($utilErrMsg))
	{
		database::mydbDisconnect() if ($disconnect);
		return -4;
	}
	
	$site = resolveRedirect(SITE);
	
	database::mydbDisconnect() if ($disconnect);
	
	return -4 if (defined ($utilErrMsg));
	
	return 0;
}

sub populateSessionVars
{
	# if the session (the main ones) are populated then we don't need to get them again
	return if (defined($userId) && defined($acctId) && defined($firstName) && defined($surName));
	
	$curSess = CGI::Session->load() if (!defined($curSess));
	my $cgi = new CGI();
	
  populateRDs();
  
  my $script = $site;
	
	if (defined($ENV{'SCRIPT_NAME'}))
	{
		$script = $ENV{'SCRIPT_NAME'};
		$script =~ s/^\///;
		$script = $site . $script; 
	}
	
	if (!defined($curSess) || $curSess->is_empty() || $curSess->is_expired())
	{
#		print "$rdLoginPage\n$script\n";
		database::mydbDisconnect() if (database::isConnected());
		print $cgi->redirect($rdLoginPage . "?referer=" . $script);
		exit();
	}
	
	$firstName    = $curSess->param('first_nm');
	$surName      = $curSess->param('sur_nm');
	$userId       = $curSess->param('user_id');
	$acctId       = $curSess->param("acct_id");
  $err          = $curSess->param("err");
  $errMsg       = $curSess->param("err_msg");
  $debug        = $curSess->param("debug");
}

sub setSessVarAcct
{
	my $passAcctId = shift();
	
	$passAcctId = 0 if (!defined($passAcctId));
	
	$curSess = CGI::Session->load() if (!defined($curSess));
	
	my $disconnect = 0;
	
	if (!database::isConnected())
	{
		database::mydbConnect();
		$disconnect = 1;
	}
	
	$curSess->param('acct_id', $passAcctId);
	$acctId = $passAcctId;
	database::updateLastAcctId($userId, $passAcctId);
	
	database::mydbDisconnect() if ($disconnect);
}

sub privyToPage
{
	# assumption is that the session variables are already populated
	
	my $sName = getScriptName($ENV{'SCRIPT_NAME'});
	
	my $err = database::getAllUserGroupsByUserId($userId);
	
	foreach my $group (@$database::resRef)
	{
		my $err = database::getGroupScript($group->{'group_cd'}, $sName);
		
		return 1 if ($err == 0);
	}
	
	return 0;
}

sub printDebug
{
	my $cgi = new CGI();
	
	if (defined($curSess) && !$curSess->is_empty() && !$curSess->is_expired)
	{
		print $curSess->header();
	}
	else
	{
		print $cgi->header();
	}
	
	print $cgi->start_html("Debug Information");
	
	print "<table border=\"1\">\n",
				"<tr><td>User Id</td><td>$userId</td></tr>\n",
				"<tr><td>First Name</td><td>$firstName</td></tr>\n",
				"<tr><td>Last Name</td><td>$surName</td></tr>\n",
				"<tr><td>Account Id</td><td>$acctId</td></tr>\n",
				"<tr><td>\$err</td><td>$err</td></tr>\n",
				"<tr><td>Error Message</td><td>$errMsg</td></tr>\n",
				"<tr><td>Commit Error</td><td>$commitErr</td></tr>\n",
				"<tr><td>Commit Error Message</td><td>$commitErrMsg</td></tr>\n",
				"<tr><td>Rollback Error</td><td>$rollbackErr</td></tr>\n",
				"<tr><td>Rollback Error Message</td><td>$rollbackErrMsg</td></tr>\n";
	
	while (@_)
	{
		my $parameter = shift();
		
		if (ref($parameter) eq "ARRAY")
		{
			my $counter = 1;
			foreach my $arrVal (@$parameter)
			{
				print "<tr><td>Array value $counter</td><td>$arrVal</td></tr>\n";
			}
		}
		elsif (ref($parameter) eq "HASH")
		{
			foreach my $key (keys(%$parameter))
			{
				print "<tr><td>$key</td><td>$parameter->{$key}</td></tr>\n";
			}
		}
		else
		{
			print "<tr><td>Some Scalar</td><td>$parameter</td></tr>\n";
		}
	}
	print "</table>\n";
	
	print $cgi->end_html();
	database::specialSpecialDisconnect();
	exit();
}

sub pushError
{
	my $errCd = shift();
	my $errMsg = shift();
	
	$errCd = 0 if (!defined($errCd));
	
	$errMsg = "No error defined" if (!defined($errMsg));
	
	my %errHash = {'err_cd' => $errCd,
		             'err_msg' => $errMsg};
	
	push (@errArray, \%errHash);
}

sub writeErrArray
{
	# in html format
	# the aray is assumed to be a list of hash references
	
	print "<table>\n";
	foreach my $rec (@errArray)
	{
		print "<tr><td>$rec->{'err_cd'}</td><td>$rec->{'err_msg'}</td></tr>\n";
	}
	print "</table>\n";
}

sub printHeader
{
	my $cgi = new CGI();
	my $windowTitle = "Generic Title";
	my $formTitle = "Generic Form";
	my $processRequest = "http://localhost/cgi-bin/processrequests.pl";
	
	my $tempWT = shift();
	my $tempFT = shift();
	
	$windowTitle = $tempWT if (defined($tempWT));
	$formTitle = $tempFT if (defined($tempFT));
	
	print $utilities::curSess->header(),
        $cgi->start_html(-title => $windowTitle,
                         -style => {'src' => '/css/mainstyles.css'},
                         -script => {-type => 'text/javascript',
                         						 -src => '/javascript/ajax.js'},
                         -class => 'main');

#	print $utilities::curSess->header();
#	print "<html>\n";
#	print "<head>\n";
#	print "<title>$windowTitle</title>\n";
#	print "<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/mainstyles\" />\n";
#	print "<script src=\"javascript/ajax.js\" type=\"text/javascript\"></script>\n";
#	print "</head>\n";
#	print "<body class=\"main\">\n";

  print "<div class=\"ident\">Currently logged in as $surName, $firstName</div>\n";
  print "<p><div class=\"menu_button\"><a href=\"$processRequest?submit=logout\">logout</a></div>\n";
  print "<div class=\"menu_button\"><a href=\"$rdHomePage\">home</a></div></p>\n";
  
  my $err = showAccounts($userId, $acctId);
  
  #log error to database and terminate if it is a fatal error
  
  print "<h1 class=\"formtitle\">$formTitle</h1>\n";
}

sub printFooter
{
	my $cgi = new CGI();
	print $cgi->end_html();
}

sub processFields
{
	my $cgi = new CGI();
	
	$processError = 0;
	deleteGlobalHashes();
	$valueFields{'submit'} = $cgi->param('submit');
	$errMsg = "";
	$err = 0;
	$commitErr = 0;
	$rollbackErr = 0;
	$commitErrMsg = "";
	$rollbackErrMsg = "";
	
	if (defined($valueFields{'submit'}))
	{
		my $script = getScriptName($ENV{'SCRIPT_NAME'});
		
		if ($script eq "incomeexpenses.pl")
		{
			processIncomeExpenses();
		}
		elsif ($script eq "transactiontypes.pl")
		{
			processTransactionType();
		}
		elsif ($script eq "transactions.pl")
		{
			processTransaction();
		}
		elsif ($script eq "lovcategory.pl")
		{
			processLoVCategory();
		}
		elsif ($script eq "listofvalues.pl")
		{
			processListOfValues();
		}
		elsif ($script eq "groupscripts.pl")
		{
			processGroupScripts();
		}
		elsif ($script eq "usergroups.pl")
		{
			processUserGroups();
		}
		elsif ($script eq "addusertoaccount.pl")
		{
			processAddUserToAccount();
		}
		elsif ($script eq "moneysource.pl")
		{
			processMoneySource();
		}
		elsif ($script eq "buckets.pl")
		{
			processBuckets();
		}
		elsif ($script eq "transfer.pl")
		{
			processTransfer();
		}
	}
	
	if ($err < 0)
  {
  	# printDebug();
  	# if the $err code is less than zero it means we tried to do some database processing
  	$errMsg = $database::dbErrMsg;
  	$rollbackErr = database::rollbackTrans();
  	if ($rollbackErr < 0)
  	{
  		$rollbackErrMsg = $database::dbErrMsg;
  	}
  	$processError = 1;
  	# printDebug($errMsg);
  }
  else
  {
  	# no database errors
  	$commitErr = database::commitTrans();
  	
  	if ($commitErr < 0)
  	{
  		$commitErrMsg = $database::dbErrMsg;
  	}
  	# printDebug($commitErr);
  }
}

sub processIncomeExpenses
{
	my $cgi = new CGI();
	$valueFields{'seq'}            = $cgi->param('seq');
	$valueFields{'fixed_amt'}      = $cgi->param('fixed_amt');
	$valueFields{'freq'}           = $cgi->param('freq');
	$valueFields{'inc_exp'}        = $cgi->param('inc_exp');
	$valueFields{'value_type'}     = $cgi->param('value_type');
	$valueFields{'range_low_amt'}  = $cgi->param('range_low_amt');
	$valueFields{'range_high_amt'} = $cgi->param('range_high_amt');
	$valueFields{'trans_type'}     = $cgi->param('trans_type');
	$valueFields{'incexp_desc'}    = $cgi->param('incexp_desc');
	$valueFields{'auto_process_ind'}   = $cgi->param('auto_process_ind');
	$valueFields{'out_ms_seq'}     = $cgi->param('out_ms_seq');
	$valueFields{'in_ms_seq'}      = $cgi->param('in_ms_seq');
	$valueFields{'last_process_dt'} = $cgi->param('last_process_dt');
	
	setDefaults();
	
  # printDebug(\%valueFields);
	
	if ($valueFields{'submit'} eq "Add" or $valueFields{'submit'} eq "Update")
  {
  	my $currentRec;
    if ($valueFields{'submit'} eq "Update")
    {
    	$err = database::getIncomeExpense($acctId, $valueFields{'seq'});
    	
    	return if ($err < 0);
    	
    	$currentRec = $database::resRef->[0];
    }
    if ($valueFields{'freq'} eq "")
    {
    	$markFields{'freq'} = $requiredField;
    	$processError = 1;
    }
    else
    {
    	$err = database::getListofValue($valueFields{'freq'}, 'FREQENCY');
    	if ($err < 0)
    	{
    		$markFields{'freq'} = "Invalid frequency type of $valueFields{'freq'}";
    		$processError = 1;
    	}
    }
    
    if ($valueFields{'trans_type'} eq "")
    {
    	$markFields{'trans_type'} = $requiredField;
    	$processError = 1;
    }
    else
    {
    	$err = database::getTransactionType($valueFields{'trans_type'}, $acctId);
    	if ($err < 0)
    	{
    		$markFields{'trans_type'} = "Invalid transaction type of $valueFields{'trans_type'}";
    		$processError = 1;
    	}
    }
    
    if ($valueFields{'incexp_desc'} eq "")
    {
    	$markFields{'incexp_desc'} = $requiredField;
    	$processError = 1;
    }
    
    if ($valueFields{'value_type'} eq "")
    {
    	$markFields{'value_type'} = $requiredField;
    	$processError = 1;
    }
    else
    {
    	if ($valueFields{'value_type'} eq "F")
    	{
    		# check the fixed amount here
    		if ($valueFields{'fixed_amt'} eq "")
    		{
    			$markFields{'fixed_amt'} = "Required field when income/expense type is Fixed";
    			$processError = 1;
    		}
    		elsif (!($valueFields{'fixed_amt'} =~ $currencyRegEx))
    		{
    			$markFields{'fixed_amt'} = $currencyRegExError;
    		}
    	}
    	elsif ($valueFields{'value_type'} eq "R")
    	{
    		# check range amounts here
    		if ($valueFields{'range_low_amt'} eq "")
    		{
    			$markFields{'range_low_amt'} = "Required field when income/expense type is Range";
    			$processError = 1;
    		}
    		elsif (!($valueFields{'range_low_amt'} =~ $currencyRegExError))
    		{
    			$markFields{'range_low_amt'} = $currencyRegExError;
    			$processError = 1;
    		}
    		
    		if ($valueFields{'range_high_amt'} eq "")
    		{
    			$markFields{'range_high_amt'} = "Required field when income/expense type is Range";
    			$processError = 1;
    		}
    		elsif(!($valueFields{'range_high_amt'} =~ $currencyRegEx))
    		{
    			$markFields{'range_high_amt'} = $currencyRegExError;
    			$processError = 1;
    		}
    	}
    	else
    	{
    		$markFields{'value_type'} = "Invalid income/expense type of $valueFields{'value_type'}";
    		$processError = 1;
    	}
    }
    
    if ($valueFields{'auto_process_ind'} eq "")
    {
    	$markFields{'auto_process_ind'} = $requiredField;
    	$processError = 1;
    }
    elsif ($valueFields{'auto_process_ind'} ne "Y" && $valueFields{'auto_process_ind'} ne "N")
    {
    	$markFields{'auto_process_ind'} = "Invalid value for auto processing indicator of $valueFields{'auto_process_ind'} must be Y or N";
    	$processError = 1;
    }
    
    if (!$processError)
    {
    	if ($valueFields{'value_type'} eq "R")
    	{
    		$valueFields{'fixed_amt'} = 0;
    	}
    	else
    	{
    		$valueFields{'range_low_amt'} = 0;
    		$valueFields{'range_high_amt'} = 0;
    	}
    }
    
    if ($valueFields{'last_process_dt'} eq "" && 
    	  $valueFields{'submit'} eq "Update" && $currentRec->{'last_process_dt'} ne "")
    {
    	$markFields{'last_process_dt'} = "Can't update to a blank value when updating record";
    	$processError = 1;
    }
    elsif ($valueFields{'last_process_dt'} ne "")
    {
    	if (!($valueFields{'last_process_dt'} =~ $dateRegEx))
    	{
    		$markFields{'last_process_dt'} = $dateRegExError;
    		$processError = 1;
    	}
    }
    
    if ($valueFields{'inc_exp'} eq "")
    {
    	$markFields{'inc_exp'} = $requiredField;
    	$processError = 1;
    }
    else
    {
    	$err = database::getListofValue($valueFields{'inc_exp'}, "EXPINCID");
    	
    	if ($err)
    	{
    		$markFields{'inc_exp'} = "Income/Expense type of $valueFields{'inc_exp'} doesn't exist in the list of values table";
    		$processError = 1;
    	}
    }
    
    if ($valueFields{'in_ms_seq'} eq "" && $valueFields{'out_ms_seq'} eq "")
    {
    	$markFields{'in_ms_seq'} = "One of in or out money source is required";
    	$markFields{'out_ms_seq'} = $markFields{'in_ms_seq'};
    }
    else
    {
    	if ($valueFields{'in_ms_seq'} ne "0")
    	{
    		$err = database::getMoneySource($acctId, $valueFields{'in_ms_seq'});
    		
    		if ($err)
    		{
    			$markFields{'in_ms_seq'} = "Invalid money source sequence of $valueFields{'in_ms_seq'}";
    			$processError = 1;
    		}
    	}
    	else
    	{
    		$valueFields{'in_ms_seq'} = 0;
    	}
    	
    	if ($valueFields{'out_ms_seq'} ne "0")
    	{
    		$err = database::getMoneySource($acctId, $valueFields{'out_ms_seq'});
    		
    		if ($err)
    		{
    			$markFields{'out_ms_seq'} = "Invalid money source sequence of $valueFields{'out_ms_seq'}";
    			$processError = 1;
    		}
    	}
    	else
    	{
    		$valueFields{'out_ms_seq'} = 0;
    	}
    }
    
    # WTF was I on when I wrote this
#    if (defined($valueFields{'freq'}) && defined($valueFields{'freq'}) && defined($valueFields{'freq'}) && 
#        defined($valueFields{'trans_type'}) && defined($valueFields{'incexp_desc'}) &&
#        $valueFields{'freq'} ne "" && $valueFields{'inc_exp'} ne "" && $valueFields{'value_type'} ne "" && 
#        $valueFields{'trans_type'} ne "" && $valueFields{'trans_type'} ne "" &&
#        defined($valueFields{'auto_process_ind'}) && ($valueFields{'auto_process_ind'} eq "Y" || 
#        $valueFields{'auto_process_ind'} eq "N"))
#    {
#      if (($valueFields{'value_type'} eq "R" && defined($valueFields{'range_low_amt'}) && 
#           $valueFields{'range_low_amt'} ne "" && defined($valueFields{'range_high_amt'}) && 
#           $valueFields{'range_high_amt'}) || ($valueFields{'value_type'} eq "F" && 
#           defined($valueFields{'fixed_amt'}) && $valueFields{'fixed_amt'} ne ""))
#      { 
#        if ($valueFields{'value_type'} eq "R" && (!($valueFields{'range_low_amt'} =~ /$currencyRegEx/) || 
#            !($valueFields{'range_high_amt'} =~ /$currencyRegEx/)))
#        {
#          $processError = 1;
#          if (!($valueFields{'range_low_amt'} =~ /$currencyRegEx/))
#          {
#          	$markFields{'range_low_amt'} = "Invalid format!  Please follow the format [+/-]9*.99 (example 22.43 or -35.82)";
#          }
#          
#          if (!($valueFields{'range_high_amt'} =~ /$currencyRegEx/))
#          {
#          	$markFields{'range_high_amt'} = "Invalid format!  Please follow the format [+/-]9*.99 (example 22.43 or -35.82)";
#          }
#        }
#        elsif ($valueFields{'value_type'} eq "F" && !($valueFields{'fixed_amt'} =~ /$currencyRegEx/))
#        {
#          $processError = 1;
#          $markFields{'fixed_amt'} = "Invalid format!  Please follow the format [+/-]9*.99 (example 22.43 or -35.82)"
#        }
#        else
#        {
#          if ($valueFields{'value_type'} eq "R")
#          {
#            $valueFields{'fixed_amt'} = 0;
#          }
#          else
#          {
#          	$valueFields{'range_low_amt'} = 0;
#          	$valueFields{'range_high_amt'} = 0;
#          }
#        }
      
        if ($valueFields{'submit'} eq "Add" && !$processError)
        {
          $err = database::addIncomeExpense($acctId, $valueFields{'freq'}, $valueFields{'inc_exp'}, 
          					$valueFields{'trans_type'}, $valueFields{'incexp_desc'}, $valueFields{'value_type'}, 
          					$valueFields{'fixed_amt'}, $valueFields{'range_low_amt'}, $valueFields{'range_high_amt'},
          				  $userId, $valueFields{'auto_process_ind'}, $valueFields{'out_ms_seq'}, 
          				  $valueFields{'in_ms_seq'}, $valueFields{'last_process_dt'});
        }
        elsif ($valueFields{'submit'} eq "Update" && !$processError)
        {
        	$err = database::getIncomeExpense($acctId, $valueFields{'seq'});
        	
          $err = database::updateIncomeExpense($acctId, $valueFields{'seq'}, $valueFields{'freq'}, 
          					$valueFields{'inc_exp'}, $valueFields{'trans_type'}, $valueFields{'incexp_desc'}, 
          					$valueFields{'value_type'}, $valueFields{'fixed_amt'}, $valueFields{'range_low_amt'}, 
          					$valueFields{'range_high_amt'}, $userId, $valueFields{'auto_process_ind'}, 
          					$valueFields{'out_ms_seq'}, $valueFields{'in_ms_seq'}, $valueFields{'last_process_dt'});
          }
          
          # print printDebug($err, $database::dbErrMsg, \%valueFields);
        }
#      else
#      {
#        $processError = 1;
#        database::getListofValue($valueFields{'value_type'}, "INEXPTYP");
#        if ($valueFields{'value_type'} eq "R" && $valueFields{'range_low_amt'} eq "")
#        {
#        	$markFields{'range_low_amt'} = "Required field when income/expense type is $database::resRef->[0]->{'lov_desc'}";
#        }
#        
#        if ($valueFields{'value_type'} eq "R" && $valueFields{'range_high_amt'} eq "")
#        {
#        	$markFields{'range_high_mark'} = "Required field when income/expense type is $database::resRef->[0]->{'lov_desc'}";
#        }
#        
#        if ($valueFields{'value_type'} eq "F" && $valueFields{'fixed_amt'} eq "")
#        {
#        	$markFields{'fixed_amt'} = "Required field when income/expense type is $database::resRef->[0]->{'lov_desc'}";
#        }
#      }
#    }
#    else
#    {
#      if (!defined($valueFields{'freq'}) || $valueFields{'freq'} eq "")
#      {
#      	$markFields{'freq'} = "Required field";
#      }
#      
#      if (!defined($valueFields{'inc_exp'}) || $valueFields{'inc_exp'} eq "")
#      {
#      	$markFields{'inc_exp'} = "Required field";
#      }
#      
#      if (!defined($valueFields{'value_type'}) || $valueFields{'value_type'} eq "")
#      {
#      	$markFields{'value_type'} = "Required field";
#      }
#      
#      if (!defined($valueFields{'trans_type'}) || $valueFields{'trans_type'} eq "")
#      {
#      	$markFields{'trans_type'} = "Required field";
#      }
#      
#      if (!defined($valueFields{'incexp_desc'}) || $valueFields{'incexp_desc'} eq "")
#      {
#      	$markFields{'incexp_desc'} = "Required field";
#      }
#      
#      $processError = 1;
#    }
#  }
  elsif ($valueFields{'submit'} eq "Delete")
  {
    $err = database::deleteIncomeExpense($acctId, $valueFields{'seq'});
  }
}

sub processTransactionType
{
	my $cgi = new CGI();
	$valueFields{'typeid'}				= $cgi->param('typeid');
	$valueFields{'type_desc'}     = $cgi->param("type_desc");
	$valueFields{'trans_type'}		= $cgi->param('trans_type');
	$valueFields{'buck_seq'}			= $cgi->param('buck_seq');
	
	setDefaults();
	
	my $processing = 0;
	
  if ($valueFields{'submit'} eq "Add" or $valueFields{'submit'} eq "Update")
  {
    if ($valueFields{'typeid'} eq "")
    {
    	$markFields{'typeid'} = "Required Field";
    	$processError = 1;
    }
    else
    {
    	if ($valueFields{'submit'} eq "Add")
    	{
    		if (database::getTransactionType($valueFields{'typeid'}, $acctId) == 0)
    		{
    			$markFields{'typeid'} = "Record with type id of $valueFields{'typeid'} already exists";
    			$processError = 1;
    		}
    	}
    	else
    	{
    		if (database::getTransactionType($valueFields{'typeid'}, $acctId) != 0)
    		{
    			$markFields{'typeid'} = "Record with type id of $valueFields{'typeid'} doesn't exist, can't update";
    			$processError = 1;
    		}
    	}
    }
    
    if ($valueFields{'type_desc'} eq "")
    {
    	$markFields{'type_desc'} = "Required Field";
    	$processError = 1;
    }
    
    if ($valueFields{'trans_type'} eq "")
    {
    	$markFields{'trans_type'} = "Required Field";
    	$processError = 1;
    }
    else
    {
    	if (database::getListofValue($valueFields{'trans_type'}, 'TRNSTYPE') < 0)
    	{
    		$markFields{'trans_type'} = "Invalid transaction type of $valueFields{'trans_type'}";
    		$processError = 1;
    	}
    }
    
#    if ($valueFields{'buck_seq'} eq "")
#    {
#    	$markFields{'buck_seq'} = $requiredField;
#    	$processError = 1;
#    }
		if ($valueFields{'buck_seq'} > 0)
		{
    if (database::getBucket($acctId, $valueFields{'buck_seq'}) != 0)
    	{
    		$markFields{'buck_seq'} = "Bucket with sequence of $valueFields{'buck_seq'} doesn't exist";
    		$processError = 1;
    	}
		}
#    	# the drop down box isn't populated so all the other fields need to exist, if the bucket sequence
#    	# is zero then the create new bucket item is selected
#    	if (!defined($valueFields{'buck_desc'}) || $valueFields{'buck_desc'} eq "")
#    	{
#    		# set it the same as the main transaction type description
#    		$valueFields{'buck_desc'} = "";
#    		$valueFields{'buck_desc'} = $valueFields{'type_desc'} if (defined($valueFields{'type_desc'}));
#    	}
#    	
#    	if (!defined($valueFields{'balance'}) || $valueFields{'balance'} eq "")
#    	{
#    		$markFields{'balance'} = "Required Field";
#    		# printDebug("balance");
#    		$processError = 1;
#    	}
#    	else
#    	{
#    		if (!($valueFields{'balance'} =~ $currencyRegEx))
#    		{
#    			$markFields{'balance'} = $currencyRegExError;
#    			# printDebug("balance");
#    			$processError = 1;
#    		}
#    	}
#    	
#    	if (!defined($valueFields{'refresh_amt'}) || $valueFields{'refresh_amt'} eq "")
#    	{
#    		$markFields{'refresh_amt'} = "Required Field";
#    		# printDebug("refresh_amt");
#    		$processError = 1;
#    	}
#    	else
#    	{
#    		if (!($valueFields{'refresh_amt'} =~ $currencyRegEx))
#    		{
#    			$markFields{'refresh_amt'} = $currencyRegExError;
#    			# printDebug("refresh_amt");
#    			$processError = 1;
#    		}
#    	}
#    	
#    	if (!defined($valueFields{'fix_var'}) || $valueFields{'fix_var'} eq "")
#    	{
#    		$markFields{'fix_var'} = "Required Field";
#    		# printDebug("fix_var");
#    		$processError = 1;
#    	}
#    }
#    else
#    {
#    	# check to make sure that the bucket sequence exists
#    	my $tempErr = database::getBucket($acctId, $valueFields{'buck_seq'});
#    	
#    	if ($tempErr < 0)
#    	{
#    		$markFields{'buck_seq'} = "Invalid Bucket!";
#    		# printDebug();
#    		$processError = 1;
#    	}
#    }
    
#    if (!$processError)
#    {
#    	$buckSeq = 0;
#    	$buckSeq = $valueFields{'buck_seq'} if (!defined($valueFields{'buck_seq'}));
#    	# printDebug();
#    	
#    	if ($buckSeq == 0) # create a new bucket
#    	{
#    		$err = database::addBucket($acctId, $valueFields{'balance'}, $valueFields{'refresh_amt'},
#    															 $valueFields{'fix_var'}, $valueFields{'buck_desc'}, $userId);
#    		
#    		$buckSeq = $err if ($err > 0);
#    		$err = 0 if ($err > 0);
#    	}
#    	elsif ($buckSeq > 0)
#    	{
#    		# make sure the bucket exists
#    		$err = database::getBucket($acctId, $buckSeq);
#    		
#    		if ($err < 0)
#    		{
#    			$markFields{'buck_seq'} = "Bucket doesn't exists";
#    			$processError = 1;
#    			$err = 0;
#    		}
#    		
#    		if ($valueFields{'submit'} eq "Update")
#    		{
#    			$err = database::updateBucket($acctId, $valueFields{'buck_seq'}, $valueFields{'balance'},
#    										$valueFields{'refresh_amt'}, $valueFields{'fix_var'}, $valueFields{'buck_desc'},
#    										$userId);
#    		}
#    	}
#    }

		my $buckSeq = $valueFields{'buck_seq'};
    $valueFields{'typeid'} = uc($valueFields{'typeid'});
    if ($valueFields{'submit'} eq "Add" && !$processError && !$err)
    {
     	$err = database::addTransactionType($valueFields{'typeid'}, $valueFields{'type_desc'}, $acctId, $userId,
      										$valueFields{'trans_type'}, $buckSeq);
    }
    elsif ($valueFields{'submit'} eq "Update" && !$processError && !$err)
    {
     	$err = database::updateTransactionType($valueFields{'typeid'}, $valueFields{'type_desc'}, $acctId, $userId,
      										$valueFields{'trans_type'}, $buckSeq);
    }
  }
  elsif ($valueFields{'submit'} eq "Delete")
  {
  	$processing = 1;
  	if ($valueFields{'typeid'} ne "TO" && $valueFields{'typeid'} ne "TI")
  	{
  		$err = database::deleteTransactionType($valueFields{'typeid'}, $acctId);
  	}
  	else
  	{
  		$err = -1;
  		$database::dbErrMsg = "Can't delete the transfer incoming/outgoing records";
  	}
  }
}

sub processTransaction
{
	my $cgi = new CGI();
	$valueFields{'trans_date'}     = $cgi->param('trans_date');
	$valueFields{'seq'}            = $cgi->param('seq');
	$valueFields{'amt'}            = $cgi->param('amt');
	$valueFields{'inc_exp_seq'}    = $cgi->param('inc_exp_seq');
	$valueFields{'trans_type'}     = $cgi->param('trans_type');
	$valueFields{'trans_txt'}      = $cgi->param('trans_txt');
	$valueFields{'old_trans_date'} = $cgi->param('old_trans_date');
	$valueFields{'ms_seq'}				 = $cgi->param('ms_seq');
	$valueFields{'old_amt'}				 = $cgi->param('old_amt');
	setDefaults();
	# printDebug($valueFields{'submit'});
	
	if ($valueFields{'submit'} eq "Add" or $valueFields{'submit'} eq "Update")
  {
  	my $currentRec;
  	
  	if ($valueFields{'submit'} eq "Update")
  	{
  		# try to get the current record
  		$err = database::getTransaction($acctId, $valueFields{'old_trans_date'}, $valueFields{'seq'});
  		
  		return if ($err);			# no point of validating the record if it can't be updated
  		
  		$currentRec = $database::resRef->[0];
  	}
  	if ($valueFields{'trans_date'} eq "")
  	{
  		$valueFields{'trans_date'} = strftime ("%Y-%m-%d", localtime());
  	}
  	
  	if (!($valueFields{'trans_date'} =~ /$dateRegEx/))
  	{
  		$markFields{'trans_date'} = "Invalid format!  Please follow the format yyyy-mm-dd";
  		$processError = 1;
  	}
  	
  	if ($valueFields{'old_trans_date'} eq "")
		{
			$valueFields{'old_trans_date'} = $valueFields{'trans_date'};
		}
		
  	if ($valueFields{'amt'} eq "")
  	{
  		$markFields{'amt'} = "Required field";
  		$processError = 1;
  	}
  	elsif (!($valueFields{'amt'} =~ /$currencyRegEx/))
  	{
  		$markFields{'amt'} = "Invalid format!  Please follow the format [+/-]9*.99 (example 22.43 or -35.82)";
  		$processError = 1;
  	}
  	
  	if ($valueFields{'inc_exp_seq'} eq "" && $valueFields{'trans_type'} eq "")
  	{
  		$markFields{'inc_exp_seq'} = "One of source or bucket is required";
      $markFields{'trans_type'} = "One of source or bucket is required";
      $processError = 1;
  	}
  	
  	if ($valueFields{'inc_exp_seq'} eq "" && $valueFields{'ms_seq'} eq "")
   	{
   		$processError = 1;
   		$markFields{'ms_seq'} = "Field must be defined when income expense field is blank";
   	}
      
    my $createOpposite = 0;
    my $inOut = "";
    my $msTransType = 1;
    my $inMS = 0;
    my $outMS = 0;
    my $moneySource;
    my $buckSeq = 0;
      
    if ($valueFields{'inc_exp_seq'} ne "")
    {
	   	$err = database::getIncomeExpense($acctId, $valueFields{'inc_exp_seq'});
      	
     	if ($err != 0)
     	{
     		$processError = 1;
     		$markFields{'inc_exp_seq'} = "Income expense record doesn't exist:  " . $database::dbErrMsg;
     	}
     	else
     	{
     		my $recRef = $database::resRef->[0];
     		$err = database::getTransactionType($recRef->{'trans_type'}, $acctId);
      	
      	if ($err != 0)
      	{
      		$processError = 1;
      		$markFields{'trans_type'} = "Transaction type $recRef->{'trans_type'} doesn't exist:  " . $database::dbErrMsg;
      	}
      	else
      	{
	      	if ($valueFields{'submit'} eq "Add")
	      	{ 
		     		if ($recRef->{'out_ms_seq'} == 0 && $recRef->{'in_ms_seq'} != 0)
		     		{
		     			$inOut = "INCOMING";
		     			$moneySource = $recRef->{'in_ms_seq'};
		     		}
		     		elsif ($recRef->{'out_ms_seq'} != 0 && $recRef->{'in_ms_seq'} == 0)
		     		{
		     			$inOut = "OUTGOING";
		     			$moneySource = $recRef->{'out_ms_seq'};
		     		}
		     		elsif ($recRef->{'out_ms_seq'} != 0 && $recRef->{'in_ms_seq'} != 0)
		     		{
		     			$inOut = "OUTGOING";
		     			$moneySource = $recRef->{'out_ms_seq'};
		     			$inMS = $recRef->{'in_ms_seq'};
		     			$createOpposite = 1;
		     		}
		     		$valueFields{'trans_type'} = $recRef->{'trans_type'};
		     		$msTransType = 0;
	      	}
      	}
     	}
    }
     
		if (!$processError)
    {
	    my $err = database::getTransactionType($valueFields{'trans_type'}, $acctId);
      	
     	if ($err != 0)
     	{
     		$markFields{'trans_type'} = "Transaction type record doesn't exist:  " . $database::dbErrMsg;
     		$processError = 1;
     	}
     	else
     	{
     		my $recRef = $database::resRef->[0];
     		$inOut = $recRef->{'trans_type'} if ($msTransType);
     		
     		$buckSeq = 0;
     		$buckSeq = $recRef->{'buck_seq'} if (defined($recRef->{'buck_seq'}));
     	}
    }
      
    $moneySource = $valueFields{'ms_seq'} if (!defined($moneySource) || $moneySource eq "");
      
    if ($valueFields{'submit'} eq "Add" && !$processError)
    {
    	#printDebug();
      $err = database::addTransaction($acctId, $valueFields{'trans_date'}, $valueFields{'amt'}, 
      					$valueFields{'inc_exp_seq'}, $valueFields{'trans_type'}, $valueFields{'trans_txt'}, $userId,
       					$moneySource, $inOut);
      
      if ($err == 0)
      {
      	$err = database::addSubMoneySource($acctId, $moneySource, $valueFields{'amt'}, $inOut, $userId);
      }
      
      if (!$err && $buckSeq > 0)
      {
      	$err = database::addSubBucket($acctId, $buckSeq, $valueFields{'amt'}, $inOut, $userId);
      }
        					
      if ($createOpposite && $err == 0)
      {
      	$inOut = "INCOMING";
       	$moneySource = $inMS;
       	$err = database::addTransaction($acctId, $valueFields{'trans_date'}, $valueFields{'amt'}, 
       						$valueFields{'inc_exp_seq'}, $valueFields{'trans_type'}, $valueFields{'trans_txt'}, $userId,
       						$moneySource, $inOut);
       	
       	if ($err == 0)
       	{
       		$err = database::addSubMoneySource($acctId, $moneySource, $valueFields{'amt'}, $inOut, $userId);
       	}
      }
        					
    }
    elsif ($valueFields{'submit'} eq "Update" && !$processError)
    {
			
			if (!$err)
			{
	      $err = database::updateTransaction($acctId, $valueFields{'trans_date'}, $valueFields{'amt'}, 
	       					$valueFields{'inc_exp_seq'}, $valueFields{'trans_type'}, $valueFields{'trans_txt'}, 
	       					$valueFields{'seq'}, $valueFields{'old_trans_date'}, $userId,
	       					$moneySource, $inOut);
			}
			
			if (!$err)
			{
				# need to check if the money source is differnt then the record prior to the update
				$inOut = $currentRec->{'in_out'};
				my $tempAmt = -$currentRec->{'amt'};
				my $offsetAmt = $valueFields{'amt'} - $currentRec->{'amt'};
				if ($moneySource != $currentRec->{'ms_seq'})
				{
					$err = database::addSubMoneySource($acctId, $currentRec->{'ms_seq'}, $tempAmt, $inOut, $userId);
					$err = database::addSubMoneySource($acctId, $moneySource, $valueFields{'amt'}, $inOut, $userId) if (!$err);
				}
				else
				{
					$err = database::addSubMoneySource($acctId, $moneySource, $offsetAmt, $inOut, $userId);
				}
				
				# find the bucket for the old transaction
				$err = database::getTransactionType($currentRec->{'trans_type'}, $acctId) if (!$err);
				
				if (!$err)
				{
					my $recRef = $database::resRef->[0];
					my $origBuckSeq = 0;
					$origBuckSeq = $recRef->{'buck_seq'} if (defined($recRef->{'buck_seq'}));
					if ($origBuckSeq != $buckSeq)
					{
						$err = database::addSubBucket($acctId, $origBuckSeq, $tempAmt, $inOut, $userId) if ($origBuckSeq > 0);
						$err = database::addSubBucket($acctId, $buckSeq, $valueFields{'amt'}, $inOut, $userId) if (!$err && $buckSeq > 0);
					}
					else
					{
						$err = database::addSubBucket($acctId, $buckSeq, $offsetAmt, $inOut, $userId) if ($buckSeq > 0);
					}
				}
			}
    }
  }
  elsif ($valueFields{'submit'} eq "Delete")
  {
  	$valueFields{'trans_date'} = 0 if !defined($valueFields{'trans_date'});
  	$valueFields{'seq'}        = 0 if !defined($valueFields{'seq'});
  	$err = database::getTransaction($acctId, $valueFields{'trans_date'}, $valueFields{'seq'});
  	
  	if (!$err)
  	{
  		my $currentRec = $database::resRef->[0];
  		
  		$err = database::getTransactionType($currentRec->{'trans_type'}, $acctId);
  		
  		if (!$err)
  		{
  			my $amt = -$currentRec->{'amt'};
  			my $transTypeRec = $database::resRef->[0];
  			
  			my $buckSeq = 0;
  			
  			# bucket sequence may or may not exist but the incoming/outgoing and money source sequence variables
  			# should exist, if they don't then there is a problem with the processing logic earlier in the function
  			# when trying to add or update a record
  			$buckSeq = $transTypeRec->{'buck_seq'} if (defined($transTypeRec->{'buck_seq'}));
  			my $inOut = $currentRec->{'in_out'};
  			my $msSeq = $currentRec->{'ms_seq'};
  			
  			# printDebug($acctId, $msSeq, $amt, $inOut, $userId);
  			
  			$err = database::addSubMoneySource($acctId, $msSeq, $amt, $inOut, $userId);
  			$err = database::addSubBucket($acctId, $buckSeq, $amt, $inOut, $userId) if (!$err && $buckSeq > 0);
  			$err = database::deleteTransaction($acctId, $valueFields{'trans_date'}, $valueFields{'seq'}) if (!$err);
  		}
  	}
  }
}

sub processLoVCategory
{
	my $cgi = new CGI();
	$valueFields{'lov_cat_cd'}				= $cgi->param('lov_cat_cd');
	$valueFields{'cat_desc'}          = $cgi->param("cat_desc");
#	$valueFields{'old_lov_cat_cd'} 		= $cgi->param("old_lov_cat_cd");
#	
#	if (!defined($valueFields{'old_typeid'}) || $valueFields{'old_typeid'} eq "")
#	{
#		$valueFields{'old_lov_cat_cd'} = $valueFields{'lov_cat_cd'};
#	}
	
  if ($valueFields{'submit'} eq "Add" or $valueFields{'submit'} eq "Update")
  {
    # all records should be present
    if (defined($valueFields{'lov_cat_cd'}) && defined($valueFields{'cat_desc'}) &&
        $valueFields{'lov_cat_cd'} ne "" &&  $valueFields{'cat_desc'} ne "")
    {
    	$valueFields{'lov_cat_cd'} = uc($valueFields{'lov_cat_cd'});
    	$valueFields{'old_lov_cat_cd'} = uc($valueFields{'old_lov_cat_cd'});
      if ($valueFields{'submit'} eq "Add")
      {
        $err = database::addLoVCategory($valueFields{'lov_cat_cd'}, $valueFields{'cat_desc'}, $userId);
      }
      else
      {
        $err = database::updateLoVCategory($valueFields{'lov_cat_cd'}, $valueFields{'lov_cat_cd'}, $valueFields{'cat_desc'}, $userId);
      }
    }
    else
    {
      if (!valueFields{'lov_cat_cd'} || $valueFields{'lov_cat_cd'} eq "")
      {
        $markFields{'lov_cat_cd'} = "Required field";
      }
      
      if (!defined($valueFields{'cat_desc'}) || $valueFields{'cat_desc'} eq "")
      {
        $markFields{'cat_desc'} = "Required field";
      }
      
      $processError = 1;
    }
  }
#  elsif ($valueFields{'submit'} eq "Delete")
#  {
#  	$err = database::deleteLoVCategory($valueFields{'lov_cat_cd'});
#  }
}

sub processListOfValues
{
	my $cgi = new CGI();
	
	$valueFields{'lov_cd'}     = $cgi->param('lov_cd');
  $valueFields{'lov_cat_cd'} = $cgi->param('lov_cat_cd');
  $valueFields{'lov_desc'}   = $cgi->param('lov_desc');
  
  
  if ($valueFields{'submit'} eq "Add" or $valueFields{'submit'} eq "Update")
  {
    # all records should be present
    if (defined($valueFields{'lov_cd'}) && defined($valueFields{'lov_cat_cd'}) && 
    		defined($valueFields{'lov_desc'}) && $valueFields{'lov_cd'} ne "" &&
    		$valueFields{'lov_cat_cd'} ne "" && $valueFields{'lov_desc'} ne "")
    {
    	$valueFields{'lov_cd'} = uc($valueFields{'lov_cd'});
    	$valueFields{'lov_cat_cd'} = uc($valueFields{'lov_cat_cd'});
      if ($valueFields{'submit'} eq "Add")
      {
        $err = database::addListofValue($valueFields{'lov_cd'}, $valueFields{'lov_cat_cd'}, $valueFields{'lov_desc'}, $userId);
      }
      else
      {
        $err = database::updateListofValue($valueFields{'lov_cd'}, $valueFields{'lov_cat_cd'}, $valueFields{'lov_desc'}, $userId);
      }
    }
    else
    {
      if (!defined($valueFields{'lov_cd'}) || $valueFields{'lov_cd'} eq "")
      {
        $markFields{'lov_cd'} = "Required field";
      }
  
      if (!defined($valueFields{'lov_cat_cd'}) || $valueFields{'lov_cat_cd'} eq "")
      {
        $markFields{'lov_cat_cd'} = "Required field";
      }
  
      if (!defined($valueFields{'lov_desc'}) || $valueFields{'lov_desc'} eq "")
      {
        $markFields{'lov_desc'} = "Required field";
      }
      
      $processError = 1;
    }
  }
# not going to allow deletes from the application as these can be keys into other tables
# (value itself, the category is used in the application).
#  elsif ($valueFields{'submit'} eq "Delete")
#  {
#    $err = database::deleteListofValue($valueFields{'lov_cd'}, $valueFields{'lov_cat_cd'});
#  }
}

sub processGroupScripts
{
	my $cgi = new CGI();
	$valueFields{'group_cd'}             = $cgi->param('group_cd');
	$valueFields{'form_script_name'}     = $cgi->param('form_script_name');
	$valueFields{'old_group_cd'}         = $cgi->param('old_group_cd');
	$valueFields{'old_form_script_name'} = $cgi->param('old_form_script_name');
	$valueFields{'old_group_cd'}         = $valueFields{'group_cd'} if (!defined($valueFields{'old_group_cd'}));
	$valueFields{'old_form_script_name'} = $valueFields{'form_script_name'} if (!defined($valueFields{'old_form_script_name'}));
  if ($valueFields{'submit'} eq "Add" or $valueFields{'submit'} eq "Update")
  {
    # all records should be present
    if (defined($valueFields{'group_cd'}) && defined($valueFields{'form_script_name'}) &&
        $valueFields{'group_cd'} ne "" &&  $valueFields{'form_script_name'} ne "")
    {
      if ( -e $valueFields{'form_script_name'})				# perl script has to exist on the file system
      {
        if ($valueFields{'submit'} eq "Add")
        {
          $err = database::addGroupScript($valueFields{'group_cd'}, $valueFields{'form_script_name'}, $userId);
        }
        elsif ($valueFields{'submit'} eq "Update")
        {
          $err = database::updateGroupScript($valueFields{'group_cd'}, $valueFields{'form_script_name'},
          																	 $valueFields{'old_group_cd'}, $valueFields{'old_form_script_name'}, $userId);
        }
      }
      else
      {
        $markFields{'form_script_name'} = "Script has to exist";
        $processError = 1;
      }
    }
    else
    {
      if (!defined($valueFields{'form_script_name'}) || $valueFields{'form_script_name'} eq "")
      {
        $markFields{'form_script_name'} = "Required field";
      }
      
      if (!defined($valueFields{'group_cd'}) || $valueFields{'group_cd'} eq "")
      {
        $markFields{'group_cd'} = "Required field";
      }
      
      $processError = 1;
    }
  }
  elsif ($valueFields{'submit'} eq "Delete")
  {
    $err = database::deleteGroupScript($valueFields{'group_cd'}, $valueFields{'form_script_name'});
  }
}

sub processUserGroups
{
	my $cgi = new CGI();
	$valueFields{'group_cd'}      = $cgi->param('group_cd');
	$valueFields{'old_group_cd'}  = $cgi->param('old_group_cd');
	$valueFields{'form_user'}     = $cgi->param('form_user');
	$valueFields{'old_form_user'} = $cgi->param('old_form_user');
  if ($valueFields{'submit'} eq "Add" or $valueFields{'submit'} eq "Update")
  {
    # all records should be present
    if (defined($valueFields{'group_cd'}) && defined($valueFields{'form_user'}) &&
        $valueFields{'group_cd'} ne "" &&  $valueFields{'form_user'} ne "")
    {
      if ($valueFields{'submit'} eq "Add")
      {
        $err = database::addUserGroup($valueFields{'form_user'}, $valueFields{'group_cd'}, $userId);
      }
      elsif ($valueFields{'submit'} eq "Update")
      {
        $err = database::updateUserGroup($valueFields{'form_user'}, $valueFields{'group_cd'}, 
        																 $valueFields{'old_form_user'}, $valueFields{'old_group_cd'}, $userId);
      }
    }
    else
    {
      if (!defined($valueFields{'form_user'}) || $valueFields{'form_user'} eq "")
      {
        $markFields{'form_user'} = "Required field";
      }
      
      if (!defined($valueFields{'group_cd'}) || $valueFields{'group_cd'} eq "")
      {
        $markFields{'group_cd'} = "Required field";
      }
      
      $processError = 1;
    }
  }
  elsif ($valueFields{'submit'} eq "Delete")
  {
    $err = database::deleteUserGroup($valueFields{'form_user'}, $valueFields{'group_cd'});
  }
}

sub processTransfer
{
	my $cgi = new CGI();
	
	$valueFields{'transfer_dt'} = $cgi->param('transfer_dt');
	$valueFields{'ms_out'} = $cgi->param('ms_out');
	$valueFields{'ms_in'}  = $cgi->param('ms_in');
	$valueFields{'amt'} = $cgi->param('amt');
	setDefaults();
	
  if ($valueFields{'submit'} eq "Transfer")
  {
  	my $fromAccount;
  	my $toAccount;
    # all records should be present (except date)
    if ($valueFields{'transfer_dt'} eq "")
    {
    	$valueFields{'transfer_dt'} = strftime ("%Y-%m-%d", localtime());
    }
    
    if (!($valueFields{'transfer_dt'} =~ $dateRegEx))
    {
    	$markFields{'transfer_dt'} = $dateRegExError;
    	$processError = 1;
    }
    if ($valueFields{'ms_out'} eq "")
    {
    	$markFields{'ms_out'} = $requiredField;
    	$processError = 1;
    }
    else
    {
    	$err = database::getMoneySource($acctId, $valueFields{'ms_out'});
    	
    	if ($err < 0)
    	{
    		$markFields{'ms_out'} = "Money source of $valueFields{'ms_out'} doesn't exist";
    		$processError = 1;
    	}
    	else
    	{
    		$fromAccount = $database::resRef->[0]->{'source_txt'};
    	}
    }
    
    if ($valueFields{'ms_in'} eq "")
    {
    	$markFields{'ms_in'} = $requiredField;
    	$processError = 1;
    }
    else
    {
    	$err = database::getMoneySource($acctId, $valueFields{'ms_in'});
    	
    	if ($err < 0)
    	{
    		$markFields{'ms_in'} = "Money source of $valueFields{'ms_in'} doesn't exist";
    		$processError = 1;
    	}
    	else
    	{
    		$toAccount = $database::resRef->[0]->{'source_txt'};
    	}
    }
    
    if ($valueFields{'amt'} eq "")
    {
    	$markFields{'amt'} = $requiredField;
    	$processError = 1;
    }
    elsif (!($valueFields{'amt'} =~ $posCurrencyRegEx))
    {
    	$markFields{'amt'} = $posCurrencyRegExError;
    	$processError = 1;
    }
    
    if (!$processError && !$err)
    {
    	# create the transaction records
    	my $msSeq = $valueFields{'ms_out'};
    	my $inOut = "OUTGOING";
    	my $transType = "TO";
    	my $incExp = "";
    	my $desc = "Transfer from " . substr($fromAccount, 0, 16) . " to " . substr($toAccount, 0, 16);
    	$err = database::addTransaction($acctId, $valueFields{'transfer_dt'}, $valueFields{'amt'}, $incExp, 
    																	$transType, $desc, $userId, $msSeq, $inOut);
    																	
    	$err = database::addSubMoneySource($acctId, $msSeq, $valueFields{'amt'}, $inOut, $userId) if (!$err);
    	
    	if (!$err)
    	{
	    	$inOut = "INCOMING";
	    	$transType = "TI";
	    	$msSeq = $valueFields{'ms_in'};
	    	$err = database::addTransaction($acctId, $valueFields{'transfer_dt'}, $valueFields{'amt'}, $incExp, 
	    																	$transType, $desc, $userId, $msSeq, $inOut);
	    																	
	    	$err = database::addSubMoneySource($acctId, $msSeq, $valueFields{'amt'}, $inOut, $userId) if (!$err);
    	}
    }
  }
}

sub processAddUserToAccount
{
	my $cgi = new CGI();
	
	$valueFields{'form_user'}    = $cgi->param('form_user');
	$valueFields{'access_level'} = $cgi->param('access_level');
	
	if (defined($valueFields{'submit'}) && ($valueFields{'submit'} eq "Add" || $valueFields{'submit'} eq "Update"))
	{
		if (defined($valueFields{'form_user'}) && defined($valueFields{'access_level'}) &&
			  $valueFields{'form_user'} ne "" && $valueFields{'access_level'})
		{
			#find the form user
			my $tempErr = database::getUserByNickname($valueFields{'form_user'});
			
			if ($tempErr != 0)
			{
				$tempErr = database::getUserByEmail($valueFields{'form_user'});
				
				if ($tempErr != 0)
				{
					$markFields{'form_user'} = "Username or email not found";
					$processError = 1;
				}
			}
			
			my $formUserId;
			
			if (!$processError)
			{
				$formUserId = $database::resRef->[0]->{'userid'};
			}
			
			#make sure the account access exists in the list of values
			$tempErr = database::getListofValue($valueFields{'access_level'}, 'ACCTACES');
			
			if ($tempErr != 0)
			{
				$processError = 1;
				$markFields{'access_level'} = "Access Level $valueFields{'access_level'} doesn't exist";
			}
			
			if ($valueFields{'submit'} eq "Add" && !$processError)
			{
				$err = database::addUserAccount($formUserId, $acctId, $valueFields{'access_level'}, $userId);
			}
			elsif ($valueFields{'submit'} eq "Update" && !$processError)
			{
				$err = database::updateUserAccount($formUserId, $acctId, $valueFields{'access_level'}, $userId);
			}
		}
		else
		{
			if (!defined($valueFields{'form_user'}) || $valueFields{'form_user'} eq "")
			{
				$markFields{'form_user'} = "Required field";
			}
			
			if (!defined($valueFields{'access_level'}) || $valueFields{'access_level'} eq "")
			{
				$markFields{'access_level'} = "Required field";
			}
			
			$processError = 1;
		}
	}
	elsif(defined($valueFields{'submit'}) && $valueFields{'submit'} eq "Delete")
	{
		my $tempErr = database::getUserAccount($valueFields{'form_user'}, $acctId);
		
		if ($tempErr == 0)
		{
			my $accessLevel = $database::resRef->[0]->{'access'};
			
			if ($accessLevel eq "OWNER")
			{
				$processError = 1;
				$markFields{'form_user'} = "Can't delete the owner of the account";
			}
			else
			{
				$err = database::deleteUserAccount($valueFields{'form_user'}, $acctId);
			}
		}
	}
}

sub processMoneySource()
{
	my $cgi = new CGI();
	$valueFields{'seq'}         = $cgi->param('seq');
	$valueFields{'source_txt'}  = $cgi->param('source_txt');
	$valueFields{'source_type'} = $cgi->param('source_type');
	$valueFields{'balance'}     = $cgi->param('balance');
	
	setDefaults();
	
	if (defined($valueFields{'submit'}) && ($valueFields{'submit'} eq "Add" || $valueFields{'submit'} eq "Update"))
	{
		my $validBalance = 0;
		if (defined($valueFields{'balance'}))
		{
			if ($valueFields{'balance'} =~ $currencyRegEx)
			{
				$validBalance = 1;
			}
		}
		else
		{
			$validBalance = 1;
		}
		if (defined($valueFields{'source_txt'}) && $valueFields{'source_txt'} ne "" &&
				defined($valueFields{'source_type'}) && $valueFields{'source_type'} ne "" &&
				$validBalance)
		{
			if ($valueFields{'submit'} eq "Add")
			{
				$err = database::addMoneySource($acctId, $valueFields{'source_txt'}, $valueFields{'source_type'},
																				$userId, $valueFields{'balance'});
			}
			else
			{
				$err = database::updateMoneySource($acctId, $valueFields{'seq'}, $valueFields{'source_txt'},
																					 $valueFields{'source_type'}, $userId, $valueFields{'balance'});
			}
		}
		else
		{
			$processError = 1;
			
			if (!defined($valueFields{'source_txt'}) || $valueFields{'source_txt'} eq "")
			{
				$markFields{'source_txt'} = "Required Field";
			}
			
			if (!defined($valueFields{'source_type'}) || $valueFields{'source_type'} eq "")
			{
				$markFields{'source_type'} = "Required Field";
			}
			
			if (!$validBalance)
			{
				$markFields{'balance'} = "Invalid format!  Please follow the format [+/-]9*.99 (example 22.43 or -35.82)";
			}
		}
	}
	elsif (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "Delete")
	{
		#perhaps have a warning here if the balance is != 0 and if there are transactions to and from this account
		$err = database::deleteMoneySource($acctId, $valueFields{'seq'});
	}
}

sub processBuckets
{
	my $cgi = new CGI();
	$valueFields{'seq'}         		 = $cgi->param("seq");
	$valueFields{'buck_desc'}   		 = $cgi->param("buck_desc");
	$valueFields{'balance'}     		 = $cgi->param("balance");
	$valueFields{'refresh_amt'} 		 = $cgi->param("refresh_amt");
	$valueFields{'fix_var'}     		 = $cgi->param("fix_var");
	$valueFields{'refresh_freq'}     = $cgi->param("refresh_freq");
	$valueFields{'last_process_dt'}  = $cgi->param("last_process_dt");
	$valueFields{'auto_process_ind'} = $cgi->param("auto_process_ind");
	
	setDefaults();
	
	if ($valueFields{'submit'} eq "Add" || $valueFields{'submit'} eq "Update")
	{
		my $currentRec;
		if ($valueFields{'submit'} eq "Update")
		{
			$err = database::getBucket($acctId, $valueFields{'seq'});
			return if ($err);
			$currentRec = $database::resRef->[0];
		}
		
		if ($valueFields{'buck_desc'} eq "")
		{
			$markFields{'buck_desc'} = $requiredField;
			$processError = 1;
		}
		
		if ($valueFields{'balance'} eq "")
		{
			$markFields{'balance'} = $requiredField;
			$processError = 1;
		}
		elsif (!($valueFields{'balance'} =~ $currencyRegEx))
		{
			$markFields{'balance'} = $currencyRegExError;
			$processError = 1;
		}
		
		if ($valueFields{'refresh_amt'} eq "")
		{
			$markFields{'refresh_amt'} = $requiredField;
			$processError = 1;
		}
		elsif (!($valueFields{'refresh_amt'} =~ $currencyRegEx))
		{
			$markFields{'refresh_amt'} = $currencyRegExError;
			$processError = 1;
		}
		
		if ($valueFields{'refresh_freq'} eq "")
		{
			$markFields{'refresh_freq'} = $requiredField;
			$processError = 1;
		}
		else
		{
			my $tempErr = database::getListofValue($valueFields{'refresh_freq'}, 'FREQENCY');
			
			if ($tempErr)
			{
				$markFields{'refresh_freq'} = "refresh frequency of $valueFields{'refresh_freq'} ins't a valie value";
				$processError = 1;
			}
		}
		
		if ($valueFields{'auto_process_ind'} eq "")
		{
			$valueFields{'auto_process_ind'} = "N";
		}
		if ($valueFields{'auto_process_ind'} ne "Y" && $valueFields{'auto_process_ind'} ne "N")
		{
			$markFields{'auto_process_ind'} = "Stop trying to pass me crap like $valueFields{'auto_process_ind'} you haxor!!!";
			$processError = 1;
		}
		
		if ($valueFields{'fix_var'} eq "")
		{
			$markFields{'fix_var'} = $requiredField;
			$processError = 1;
		}
		else
		{
			my $tempErr = database::getListofValue($valueFields{'fix_var'}, 'BUCKTYPE');
			
			if ($tempErr < 0)
			{
				$markFields{'fix_var'} = "bucket type, $valueFields{'fix_var'}, isn't a valid value";
				$processError = 1;
			}
		}
		
		if ($valueFields{'submit'} eq "Add" && !$processError)
		{
			$err = database::addBucket($acctId, $valueFields{'balance'}, $valueFields{'refresh_amt'},
																 $valueFields{'fix_var'}, $valueFields{'buck_desc'}, $userId,
																 $valueFields{'refresh_freq'}, $valueFields{'last_process_dt'},
																 $valueFields{'auto_process_ind'});
		}
		elsif (!$processError)
		{
			$err = database::updateBucket($acctId, $valueFields{'seq'}, $valueFields{'balance'}, $valueFields{'refresh_amt'},
																		$valueFields{'fix_var'}, $valueFields{'buck_desc'}, $userId,
																		$valueFields{'refresh_freq'}, $valueFields{'last_process_dt'},
																		$valueFields{'auto_process_ind'});
		}
	}
	elsif ($valueFields{'submit'} eq "Delete")
	{
		$err = database::deleteBucket($acctId, $valueFields{'seq'});
	}
}

sub trimWhitespace
{
	# expects one parameter
	my $string = shift();
	
	$string =~ s/^\s+//g;
	$string =~ s/\s+$//g;
	
	return $string;
}

sub displayForm
{
	my $script = getScriptName($ENV{'SCRIPT_NAME'});

	print "<div class=\"mark\">$errMsg</div><br>\n" if ($err < 0);
	print "<div class=\"mark\">$rollbackErrMsg</div><br>\n" if ($rollbackErr < 0);
	print "<div class=\"mark\">$commitErrMsg</div><br>\n" if ($commitErr < 0);
	
	if ($script eq "incomeexpenses.pl")
	{
		displayIncomeExpense();
	}
	elsif ($script eq "transactiontypes.pl")
	{
		displayTransactionTypes();
	}
	elsif ($script eq "transactions.pl")
	{
		displayTransactions();
	}
	elsif ($script eq "lovcategory.pl")
	{
		displayLoVCategory();
	}
	elsif ($script eq "listofvalues.pl")
	{
		displayListOfValues();
	}
	elsif ($script eq "groupscripts.pl")
	{
		displayGroupsScripts();
	}
	elsif ($script eq "usergroups.pl")
	{
		displayUserGroups();
	}
	elsif ($script eq "addusertoaccount.pl")
	{
		displayUserAccounts();
	}
	elsif ($script eq "moneysource.pl")
	{
		displayMoneySource();
	}
	elsif ($script eq "buckets.pl")
	{
		displayBuckets();
	}
	elsif ($script eq "transfer.pl")
	{
		displayTransfer();
	}
}

sub displayIncomeExpense
{
	my $cgi = new CGI();
	my $scriptName = getScriptName($ENV{'SCRIPT_NAME'});
	my $formName = getFormName($scriptName);
	
  getOffset();
  
	$err = database::getIncomeExpenseByAcctAndLimit($acctId, $offset, $maxRecs);
	my $recCount = database::getIncomeExpenseCountByAcct($acctId);
	my $addOrUpdate = "Add";

	if ($err < 0)
	{
	  print $cgi->p($database::dbErrMsg);
	}
	else
	{
	  my $records = $database::resRef;
	  print <<endTag;
	        <table class="basic">
	        <tr>
	        <td class="basic"><b>Frequency</b></td><td class="basic"><b>Income/Expense</b></td>
	        <td class="basic"><b>Transaction Type</b></td><td class="basic"><b>Income/Expense Description</b></td>
	        <td class="basic"><b>Amount Expected</b></td><td class="basic"><b>Fixed Amount</b></td>
	        <td class="basic"><b>Rangle Low Amount</b></td><td class="basic"><b>Range High Amount</b></td>
	        <td class="basic"><b>Auto Process Indicator</b></td><td class="basic"><b>Out Money Source</b></td>
	        <td class="basic"><b>In Money Source</b></td><td class="basic"><b>Last Process Date</b></td>
	        <td class="basic"><b>Update</b></td><td class="basic"><b>Delete</b></td>
	        </tr>
endTag

		foreach my $ref (@$records)
	  {
	    print "<tr>\n";
	    
	    database::getListofValue($ref->{'freq'}, "FREQENCY");
	    my $temp = $database::resRef->[0];
	    print "<td class=\"basic\">$temp->{'lov_desc'}</td>\n";
	    
	    database::getListofValue($ref->{'inc_exp'}, "EXPINCID");
	    $temp = $database::resRef->[0];
	    print "<td class=\"basic\">$temp->{'lov_desc'}</td>\n";
	    
	    database::getTransactionType($ref->{'trans_type'}, $acctId);
	    $temp = $database::resRef->[0];
	    print "<td class=\"basic\">$temp->{'type_desc'}</td>\n",
	          "<td class=\"basic\">$ref->{'incexp_desc'}</td>\n";
	    
	    my $outMSText = "None";
	    my $inMSText  = "None";
	    
	    if ($ref->{'out_ms_seq'} > 0)
	    {
	    	database::getMoneySource($acctId, $ref->{'out_ms_seq'});
	    	$temp = $database::resRef->[0];
	    	$outMSText = $temp->{'source_txt'};
	    }
	    
	    if ($ref->{'in_ms_seq'} > 0)
	    {
	    	database::getMoneySource($acctId, $ref->{'in_ms_seq'});
	    	$temp = $database::resRef->[0];
	    	$inMSText = $temp->{'source_txt'};
	    }
	    
	    database::getListofValue($ref->{'value_type'}, "INEXPTYP");
	    $temp = $database::resRef->[0];
	    my $lastProcDate = $ref->{'last_process_dt'};
	    $lastProcDate = "Never" if (!defined($lastProcDate));
	    
	    print <<endTag;
	          <td class="basic">$temp->{'lov_desc'}</td>
	          <td class="basic">$ref->{'fixed_amt'}</td><td class="basic">$ref->{'range_low_amt'}</td>
	          <td class="basic">$ref->{'range_high_amt'}</td><td class="basic">$ref->{'auto_process_ind'}</td>
	          <td class="basic">$outMSText</td><td class="basic">$inMSText</td>
	          <td class="basic">$lastProcDate</td>
	          <td class="basic"><a href="/cgi-bin/$scriptName?seq=$ref->{'seq'}&submit=UpdateRec">Update</a></td>
	          <td class="basic"><a href="/cgi-bin/$scriptName?seq=$ref->{'seq'}&submit=Delete">Delete</a></td></tr>
endTag
  	}
  	print "</table>\n";
    printPageNav($recCount);
 
		if ($valueFields{'submit'} eq "UpdateRec")
		{ 
			my $singleRec;
			
			$err = database::getIncomeExpense($acctId, $valueFields{'seq'});
			# printDebug();
			
    	if ($err == 0)
      {
    		$singleRec = $database::resRef->[0];
    		
    		foreach my $key (keys(%$singleRec))
    		{
    			$valueFields{$key} = $singleRec->{$key};
    		}
    		$addOrUpdate = "Update";
      }
		}
		elsif (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "Update" && $processError)
		{
			# need to do this if we tried to update a record and it failed
			$addOrUpdate = "Update";
		}
		elsif (!$processError)
		{
			# clear the fields
			clearFields();
			clearMarks();
		}
  }
  
  if ($err)
  {
  	print $cgi->p($database::dbErrMsg);
  }
  else
  {
    database::getAllListofValuesByCatCd("FREQENCY");
    my $freqList = $database::resRef;
    database::getAllListofValuesByCatCd("EXPINCID");
    my $incExpCd = $database::resRef;
    database::getAllListofValuesByCatCd("INEXPTYP");
    my $incExpType = $database::resRef;
    database::getAllTransactionTypes($acctId);
    my $transTypeList = $database::resRef;
    database::getAllMoneySourcesByAcct($acctId);
    my $moneySourceList = $database::resRef;

    print "<form name=\"$formName\" method=\"POST\" action=\"/cgi-bin/$scriptName\">\n",
          "<input type=\"hidden\" name=\"seq\" value=\"$valueFields{'seq'}\" />\n",
          "<table><tr><td>Frequency:</td><td>",
          "<select name=\"freq\">";
    foreach my $ref (@$freqList)
    {
      print "<option value=\"$ref->{'lov_cd'}\"";
      
      if ($valueFields{'freq'} eq $ref->{'lov_cd'})
      {
        print " selected";
      }
      
      print ">$ref->{'lov_desc'}</option>\n";
    }
    print "</select></td><td><div class=\"mark\">$markFields{'freq'}</div></td></tr>\n",
          "<tr><td>Income or Expense:</td>\n",
          "<td><select name=\"inc_exp\">\n";
    foreach my $ref (@$incExpCd)
    {
      print "<option value=\"$ref->{'lov_cd'}\"";
      
      if ($valueFields{'inc_exp'} eq $ref->{'lov_cd'})
      {
        print " selected";
      }
      
      print ">$ref->{'lov_desc'}</option>\n";
    }
    
    print "</select></td><td><div class=\"mark\">$markFields{'inc_exp'}</div></td></tr>\n",
          "<tr><td>Transaction type:</td><td>",
          "<select name=\"trans_type\">\n";
    foreach my $ref (@$transTypeList)
    {
      print "<option value=\"$ref->{'typeid'}\"";
      
      if ($valueFields{'trans_type'} eq $ref->{'typeid'})
      {
        print " selected";
      }
      
      print ">$ref->{'type_desc'}</option>\n";
    }
    
    print <<endTag;
          </select></td><td><div class="mark">$markFields{'trans_type'}</div></td></tr>
          <tr><td>Income/Expense Description:</td><td>
          <input type="text" name="incexp_desc" size="30" maxlength="50" value="$valueFields{'incexp_desc'}" />
          </td><td><div class="mark">$markFields{'incexp_desc'}</div></td></tr>
          <tr><td>Income/Expense type:</td><td>
          <select name="value_type">
endTag
    foreach my $ref (@$incExpType)
    {
      print "<option value=\"$ref->{'lov_cd'}\"";
      
      if ($valueFields{'value_type'} eq $ref->{'lov_cd'})
      {
        print " selected";
      }
      
      print ">$ref->{'lov_desc'}</option>\n";
    }
    print <<endTag;
          </select></td><td><div class="mark">$markFields{'value_type'}</div></td></tr>
          <tr><td>Fixed amount:</td><td>
          <input type="text" name="fixed_amt" size="15" maxlength="15" value="$valueFields{'fixed_amt'}" />
          </td><td><div class="mark">$markFields{'fixed_amt'}</div></td></tr>
          <tr><td>Ranged Low Amount:</td><td>
          <input type="text" name="range_low_amt" size="15" maxlength="15" value="$valueFields{'range_low_amt'}" />
          </td><td><div class="mark">$markFields{'range_low_amt'}</div></td></tr>
          <tr><td>Ranged High Amount:</td><td>
          <input type="text" name="range_high_amt" size="15" maxlength="15" value="$valueFields{'range_high_amt'}" />
          </td><td><div class="mark">$markFields{'range_high_amt'}</div></td></tr>
          <tr><td>Auto Process Indicator:</td><td><select name="auto_process_ind">
endTag
		print "<option value=\"Y\"";
		print " selected" if ($valueFields{'auto_process_ind'} eq "Y");
		print ">Yes</option>\n";
		print "<option value=\"N\"";
		print " selected" if ($valueFields{'auto_process_ind'} eq "N");
		print ">No</option>\n";
		print <<endTag;
					</select></td><td><div class="mark">$markFields{'auto_process_ind'}</div></td></tr>
					<tr><td>Outgoing Money Source:</td>
					<td><select name="out_ms_seq">
endTag
		print "<option value=\"0\"";
		print " selected" if ($valueFields{'out_ms_seq'} == 0);
		print "></opiton>\n";
		
		foreach my $ref (@$moneySourceList)
		{
			print "<option value=\"$ref->{'seq'}\"";
			print " selected" if ($valueFields{'out_ms_seq'} == $ref->{'seq'});
			print ">$ref->{'source_txt'}</option>\n";
		}
		
		print <<endTag;
					</select></td><td><div class="mark">$markFields{'out_ms_seq'}</div></td></tr>
					<tr><td>Incoming Money Source:</td>
					<td><select name="in_ms_seq">
endTag
		print "<option value=\"0\"";
		print " selected" if ($valueFields{'in_ms_seq'} == 0);
		print "></option>\n";
		
		foreach my $ref (@$moneySourceList)
		{
			print "<option value=\"$ref->{'seq'}\"";
			print " selected" if ($valueFields{'in_ms_seq'} == $ref->{'seq'});
			print ">$ref->{'source_txt'}</option>\n";
		}
		
		print <<endTag;
					</select></td><td><div class="mark">$markFields{'in_ms_seq'}</div></td></tr>
					<tr><td>Last Process Date:</td><td><input type="text" name="last_process_dt" size="10" maxlength="10" value="$valueFields{'last_process_dt'}" /></td>
					<td><div class="mark">$markFields{'last_process_dt'}</div></td></tr>
          </table>
          <input type="reset" name="reset" />
          <input type="submit" name="submit" value="$addOrUpdate" />
          </form>
endTag
  }
}

sub displayTransactionTypes
{
	my $cgi = new CGI();
	my $scriptName = getScriptName($ENV{'SCRIPT_NAME'});
	my $formName = getFormName($scriptName);
	
	# printError();
	
  getOffset();
  
  $err = database::getTransactionTypesAndLimit($acctId, $offset, $maxRecs);
  # printDebug();
  my $recCount = database::getTransactionTypesCountByAcct($acctId);
  
	# $err = database::getIncomeExpenseByAcctAndLimit($acctId, $offset, $maxRecs);
	# my $recCount = database::getIncomeExpenseCountByAcct($acctId);
	my $addOrUpdate = "Add";
	
	if ($err < 0)
	{
	  print "<p>There was an error processing the database statement</p>\n";
	}
	else
	{
	  print <<endHTML;
	  			<table class="basic">
	  			<tr><td class="basic"><b>Type Id</b></td><td class="basic"><b>Type Description</b></td>
	  			<td class="basic"><b>Transaction Type</b></td>
	  			<td class="basic"><b>Bucket Description</b></td><td class="basic"><b>Bucket Balance</b></td>
	  			<td class="basic"><b>Bucket Refresh Amount</b></td><td class="basic"><b>Variable/Fixed Bucket</b></td>
	  			<td class="basic"><b>Delete</b></td><td class="basic"><b>Update</b></td></tr>
endHTML

		my $transRecs = $database::resRef;
	  foreach my $ref (@$transRecs)
	  {
	  	my %buckVal;
	  	$buckVal{'buck_desc'} = "";
	  	$buckVal{'balance'} = "";
	  	$buckVal{'refresh_amt'} = "";
	  	$buckVal{'fix_var'} = "";
	  	
	  	if ($ref->{'buck_seq'} > 0)
	  	{
	  		my $err = database::getBucket($acctId, $ref->{'buck_seq'});
	  		
	  		if ($err == 0)
	  		{
	  			my $buckRec = $database::resRef->[0];
	  			foreach my $buckField (keys(%buckVal))
	  			{
	  				$buckVal{$buckField} = $buckRec->{$buckField};
	  			}
	  		}
	  	}
	    print <<endOfTable;
	       <tr>
	       <td class="basic">$ref->{'typeid'}</td><td class="basic">$ref->{'type_desc'}</td>
	       <td class="basic">$ref->{'trans_type'}</td>
	       <td class="basic">$buckVal{'buck_desc'}</td><td class="basic">$buckVal{'balance'}</td>
	       <td class="basic">$buckVal{'refresh_amt'}</td><td class="basic">$buckVal{'fix_var'}</td>
	       <td class="basic"><a href="/cgi-bin/$scriptName?typeid=$ref->{'typeid'}&submit=Delete">Delete</a></td>
	       <td class="basic"><a href="/cgi-bin/$scriptName?typeid=$ref->{'typeid'}&submit=UpdateRec">Update</a></td>
	       </tr>
endOfTable
	  }
	  
	  print "</table>\n";
	  printPageNav($recCount);
	  
	  if (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "UpdateRec")
		{ 
			my $singleRec;
			
			$err = database::getTransactionType($valueFields{'typeid'}, $acctId);
			
    	if ($err == 0)
      {
    		$singleRec = $database::resRef->[0];
    		
    		foreach my $key (keys(%$singleRec))
    		{
    			$valueFields{$key} = $singleRec->{$key};
    		}
    		
    		$addOrUpdate = "Update";
      }
		}
		elsif (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "Update" && $processError)
		{
			# need to do this if we tried to update a record and it failed
			$addOrUpdate = "Update";
		}
		elsif (!$processError)
		{
			# clear the fields
			clearFields();
			clearMarks();
		}
		
		my $tempErr = database::getBucketsByAcctId($acctId);
		my $buckList=[];
		$buckList = $database::resRef if ($tempErr == 0);
		
		$tempErr = database::getAllListofValuesByCatCd('BUCKTYPE');
		my $fixVarList = [];
		$fixVarList = $database::resRef if ($tempErr == 0);
		
	  
	  print <<endHTML;
	  			<form name="$formName" action="/cgi-bin/$scriptName" method="POST">
	  			<table>
	  			<tr><td>Transaction Type:</td>
endHTML

		print "<td><input type=\"text\" name=\"typeid\" maxlength=\"2\" size=\"4\" value=\"$valueFields{'typeid'}\" ";
		print "readonly=\"true\" " if ($addOrUpdate eq "Update");
		print " /></td>\n";
	  print <<endHTML;	
	  			<td><div class="mark">$markFields{'typeid'}</div></td></tr>
	  			<tr><td>Transaction Type Description:</td>
	  			<td><input type="text" name="type_desc" maxlength="50" size="30" value="$valueFields{'type_desc'}" /></td>
	  			<td><div class="mark">$markFields{'type_desc'}</div></td></tr>
	  			<tr><td>Incoming/Outgoing:</td>
	  			<td><select name="trans_type">
endHTML
		database::getAllListofValuesByCatCd('TRNSTYPE');
		
		foreach my $ref (@$database::resRef)
		{
			print "<option value=\"$ref->{'lov_cd'}\"";
			
			if ($ref->{'lov_cd'} eq $valueFields{'trans_type'})
			{
				print " selected";
			}
			
			print ">$ref->{'lov_cd'}</option>\n";
		}

		print <<endHTML;
					</select></td><td><div class="mark">$markFields{'trans_type'}</div></td></tr>
					<tr><td>Bucket:</td>
					<td><select name="buck_seq">
endHTML
		print "<option value=\"0\"";
		print " selected" if ($valueFields{'buck_seq'} eq "");
		print "></option>\n";

		foreach my $ref (@$buckList)
		{
			my $class = "PosAmt";
			$class = "NegAmt" if ($ref->{'balance'} < 0);
			print "<option value=\"$ref->{'seq'}\"";
			print " selected" if ($valueFields{'buck_seq'} == $ref->{'seq'});
			print ">$ref->{'buck_desc'}&nbsp;(Balance:<div class=\"$class\">&nbsp;&nbsp;$ref->{'balance'}</div>)</option>\n";
		}

		print <<endHTML;
					</select></td><td><div class="mark">$markFields{'buck_seq'}</div></td></tr>
	  			</table>
	  			<input type="reset" name="reset" />
          <input type="submit" name="submit" value="$addOrUpdate" />
	  			</form>
endHTML
	}
}

#
# This subroutine is used to display the transactions screen filter which will include two date picker forms
# plus a filter for the bucket type
# Parameters:
#    $transTypeList - a reference to an array of hash references containing the transaction types
#    $fromDate - the from date to use in the date picker
#    $toDate - the to date to use in the date picker
#
sub displayTransactionsFilter
{
	my $cgi = new CGI();
	my $transTypeList = shift();
	my $fromDate = shift();
	my $toDate = shift();
	my $scriptName = $ENV{'SCRIPT_NAME'};
	my $curTransType = $cgi->param("filter_trans_type");
	
	$curTransType = "" if (!defined($curTransType));
	
	print  "<form name=\"formfilter\" method=\"get\" action=\"$scriptName\">\n";
	datePicker(1, 1, 1, 0, $fromDate, 0);
	datePicker(1, 1, 1, 0, $toDate, 1);
	print <<endTag;
		<table class="filter"><tr class="filter">
		<td class="filter">Bucket:</td><td class="filter"><select name="filter_trans_type">
	    <option
endTag
	    if ($curTransType eq "")
	    {
	      print " selected";
	    }
	    print "></option>\n";
	    foreach my $ref (@$transTypeList)
	    {
	      print "<option value=\"$ref->{'typeid'}\"";
	      
	      if ($curTransType eq $ref->{'typeid'})
	      {
	        print " selected";
	      }
	      
	      print ">$ref->{'type_desc'}</option>\n";
	    }
	print <<endTag;
		</select></td></tr><tr class="filter">
		<td class="filter"><input type="submit" name="submit" value="Filter" />
		<td class="filter"><input type="reset" name="reset" />
		</td></tr></table>
		</form>
endTag
}

sub displayTransactions
{
	
	my $cgi = new CGI();
	my $scriptName = getScriptName($ENV{'SCRIPT_NAME'});
	my $formName = getFormName($scriptName);
	my $year0 = $cgi->param("year0");
	my $month0 = $cgi->param("month0");
	my $day0 = $cgi->param("day0");
	my $year1 = $cgi->param("year1");
	my $month1 = $cgi->param("month1");
	my $day1 = $cgi->param("day1");
	my $transType = $cgi->param("filter_trans_type");
	my $passthroughParms = "";
	
	$transType = "" if (!defined($transType));
	
	if (!validateYearMonthDay($year0, $month0, $day0) ||
	 	!validateYearMonthDay($year1, $month1, $day1))
	{
		my $curDate = strftime ("%Y-%m-%d", localtime());
		$year1 = substr($curDate, 0, 4);
		$month1 = substr($curDate, 5, 2);
		$day1 = substr($curDate, 8, 2);
		($year0, $month0, $day0) = Add_Delta_YM($year1, $month1, $day1, 0, -1);
		
	}
	else
	{
		$passthroughParms = "&year0=$year0&month0=$month0&day0=$day0&&year1=$year1" .
						    "&month1=$month1&day1=$day1&filter_trans_type=$transType";
	}
	
	my $fromDate = "$year0-$month0-$day0";
	my $toDate   = "$year1-$month1-$day1";
	
	getOffset();
	
	my $addOrUpdate = "Add";
	
	my $singleRec;
	  if ($valueFields{'submit'} eq "UpdateRec")
	  {
	    $err = database::getTransaction($acctId, $valueFields{'trans_date'}, $valueFields{'seq'});
	    $singleRec = $database::resRef->[0];
	  }
	  
	  if ($err)
	  {
	    print $cgi->p($database::dbErrMsg);
	  }
	  else
	  {
	    database::getAllIncomeExpense($acctId);
	    my $incExpList = $database::resRef;
	    database::getAllMoneySourcesByAcct($acctId);
	    my $msList = $database::resRef;
	    database::getBucketsByAcctId($acctId);
	    my $bucketList = $database::resRef;
	    database::getAllTransactionTypes($acctId);
			my $transTypeList = $database::resRef;
	    my @buckBalances;
	    
	    foreach my $ref (@$bucketList)
	    {
	    	$buckBalances[$ref->{'seq'}] = $ref->{'balance'};
	    }
#			thought I would have an incoming or outgoing field in the form but this is not the case
#			as the transaction can be added based on the income/expense field or the bucket field (in case 
#			the income/expense field has an account specified in both the incoming and outgoing money source
#			it will create two transactions, one incoming and one outgoing
#	    database::getAllListofValuesByCatCd('TRNSTYPE');
#	    my $inOutList = $database::resRef;
	
	    if (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "UpdateRec")
			{ 
				my $singleRec;
				
				$err = database::getTransaction($acctId, $valueFields{'trans_date'}, $valueFields{'seq'});
				
	    	if ($err == 0)
	      {
	    		$singleRec = $database::resRef->[0];
	    		
	    		foreach my $key (keys(%$singleRec))
	    		{
	    			$valueFields{$key} = $singleRec->{$key};
	    		}
	    		$valueFields{'old_trans_date'} = $singleRec->{'trans_date'};
	    		$addOrUpdate = "Update";
	      }
			}
			elsif (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "Update" && $processError)
			{
				# need to do this if we tried to update a record and it failed
				$addOrUpdate = "Update";
			}
			elsif (!$processError)
			{
				# clear the fields
				clearFields();
				clearMarks();
			}
	    print <<endTag;
	          <form name="$formName" method="POST" action="/cgi-bin/$scriptName">
	          <input type="hidden" name="seq" value="$valueFields{'seq'}" />
	          <input type="hidden" name="old_trans_date" value="$valueFields{'old_trans_date'}" />
	          <table><tr><td>Date:</td><td>
	          <input type="text" name="trans_date" value="$valueFields{'trans_date'}" size="10" maxlength="10" /></td><td>
	          <div class="mark">$markFields{'trans_date'}</div></td></tr>
	          <tr><td>Amount:</td><td>
	          <input type="text" name="amt" value="$valueFields{'amt'}" size="15" maxlength="15" /></td><td>
	          <div class="mark">$markFields{'amt'}</div></td></tr>
	          <tr><td>Money Source:</td><td><select name="ms_seq">
endTag
			foreach my $ref (@$msList)
			{
				print "<option value=\"$ref->{'seq'}\"";
				print " selected" if ($valueFields{'ms_seq'} == $ref->{'seq'});
				print ">$ref->{'source_txt'} (balance: $ref->{'balance'})</option>\n";
			}

			# TODO:  Need to update the Income/Expense field to read only on a record update.  The user
			# will be allowed to update the transaction type but will be unable to update the original
			# income/expense record
			print <<endTag;
						</select></td><td><div class="mark">$markFields{'ms_seq'}</div></td></tr>
	    			<tr><td>Income/Expense:</td><td><select name="inc_exp_seq">
endTag
			print "<option";
	    if ($valueFields{'inc_exp_seq'} eq "")
	    {
	      print " selected";
	    }
	    print "></option>\n";
	    foreach my $ref (@$incExpList)
	    {
	      print "<option value=\"$ref->{'seq'}\"";
	      
	      if ($valueFields{'inc_exp_seq'} == $ref->{'seq'})
	      {
	        print " selected";
	      }
	      elsif ($addOrUpdate eq "Update")
	      {
	        print " disabled=\"disabled\"";
	      }
	      
	      print ">$ref->{'incexp_desc'}</option>\n";
	    }
	    print <<endTag;
	          </select></td><td><div class="mark">$markFields{'inc_exp_seq'}</div></td></tr>
	          <tr><td>Bucket:</td>
	          <td><select name="trans_type">
	          <option
endTag
	    if ($valueFields{'trans_type'} eq "")
	    {
	      print " selected";
	    }
	    print "></option>\n";
	    foreach my $ref (@$transTypeList)
	    {
	      print "<option value=\"$ref->{'typeid'}\"";
	      
	      if ($valueFields{'trans_type'} eq $ref->{'typeid'})
	      {
	        print " selected";
	      }
	      
	      print ">$ref->{'type_desc'}";
	      print "&nbsp;(Balance:  $buckBalances[$ref->{'buck_seq'}])" if (defined($buckBalances[$ref->{'buck_seq'}]));
	      print "</option>\n";
	    }
	    print <<endTag;
	          </select></td><td><div class="mark">$markFields{'trans_type'}</div></td></tr>
	          <tr><td>Description:</td><td>
	          <input name="trans_txt" size="30" maxlength="50" value="$valueFields{'trans_txt'}" /></td><td>$markFields{'trans_txt'}</td></tr></table>
	          <input type="reset" name="reset" />
	          <input type="submit" name="submit" value="$addOrUpdate" />
	          </form>
endTag
	
	# getting this list now because it is going to be passed into the filter function and used
	# later in this function as well
	displayTransactionsFilter($transTypeList, $fromDate, $toDate);

	my $recCount = database::getTransactionsCountByAcctAndDate($acctId, $fromDate, $toDate, $transType);
	$err = database::getTransactionsByDateAndLimit($acctId, $fromDate, $toDate, $offset, $maxRecs, $transType);
	
	# printDebug($err, database::NO_REC);

	if ($err < 0 && $err != database::NO_REC)
	{
	  print $cgi->p($database::dbErrMsg);
	}
	else
	{
	  $err = 0;
	  my $records = $database::resRef;
	  print <<endTag;
	        <table class="basic">
	        <tr>
	        <td class="basic"><b>Transaction Date</b></td><td class="basic"><b>Outgoing Amt</b></td>
	        <td class="basic"><b>Incoming Amt</b></td><td class="basic"><b>Money Source</b></td>
	        <td class="basic"><b>Source</b></td><td class="basic"><b>Bucket</b></td>
	        <td class="basic"><b>Description</b></td>
	        <td class="basic"><b>Update</b></td><td class="basic"><b>Delete</b></td>
	        </tr>
endTag
		my $outTotal = 0;
		my $inTotal = 0;
	  foreach my $ref (@$records)
	  {
	    print "<tr>\n";
	    
	    print "<td class=\"basic\">$ref->{'trans_date'}</td>\n";
	    
	    if ($ref->{'in_out'} eq "INCOMING")
	    {
	    	print "<td class=\"basic\"></td><td class=\"basic\">$ref->{'amt'}</td>\n";
	    	$inTotal += $ref->{'amt'};
	    }
	    else
	    {
	    	print "<td class=\"basic\">$ref->{'amt'}</td><td class=\"basic\"></td>\n";
	    	$outTotal += $ref->{'amt'};
	    }
	    
	    database::getMoneySource($acctId, $ref->{'ms_seq'});
	    my $temp = $database::resRef->[0];
	    print "<td class=\"basic\">$temp->{'source_txt'}</td>\n";
	    
	    database::getIncomeExpense($acctId, $ref->{'inc_exp_seq'});
	    $temp = $database::resRef;
	    print "<td class=\"basic\">$temp->[0]->{'incexp_desc'}</td>";
	    
	    database::getTransactionType($ref->{'trans_type'}, $acctId);
	    $temp = $database::resRef;
	    
	    print <<endTag;
	          <td class="basic">$temp->[0]->{'type_desc'}</td>
	          <td class="basic">$ref->{'trans_txt'}</td>
	          <td class="basic"><a href="/cgi-bin/$scriptName?seq=$ref->{'seq'}&trans_date=$ref->{'trans_date'}$passthroughParms&submit=UpdateRec">Update</a></td>
	          <td class="basic"><a href="/cgi-bin/$scriptName?seq=$ref->{'seq'}&trans_date=$ref->{'trans_date'}$passthroughParms&submit=Delete">Delete</a></td></tr>
endTag
	  }
	  print <<endTag;
	  			<tr><td class="basic"><b>Totals</b></td><td class="basic"><b>$outTotal<b></td>
	  			<td class="basic"><b>$inTotal</b></td><td class="basic"></td><td class="basic"></td>
	  			<td class="basic"></td><td class="basic"></td><td class="basic"></td>
	  			<td class="basic"></td></tr>
endTag
	  
	  print "</table>\n";
	  printPageNav($recCount, $passthroughParms);
	      
	  }
	}
}

sub displayLoVCategory
{
	my $cgi = new CGI();
	my $scriptName = getScriptName($ENV{'SCRIPT_NAME'});
	my $formName = getFormName($scriptName);
	
	getOffset();
	
	my $addOrUpdate = "Add";
	
	$err = database::getAllCategoriesAndLimit($offset, $maxRecs);
	my $errMsg = $database::dbErrMsg;
	
	my $recCount = database::getCategoriesCount();
  # $err = database::getAllLoVCategories();
	
	if ($err < 0 && $err != database::NO_REC)
	{
	  print $cgi->p($errMsg);
	}
	else
	{
		my $records = $database::resRef;
	  print <<endTag;
	        <table class="basic">
	        <tr>
	        <td class="basic"><b>Category Code</b></td><td class="basic"><b>Category Description</b></td>
	        <td class="basic"><b>Update</b></td>
	        </tr>
endTag
	  foreach my $ref (@$records)
	  {
	  	print <<endTag;
	    <tr>
	    <td class="basic">$ref->{'lov_cat_cd'}</td><td class="basic">$ref->{'cat_desc'}</td>
	    <td class="basic"><a href="/cgi-bin/$scriptName?lov_cat_cd=$ref->{'lov_cat_cd'}&submit=UpdateRec">Update</a></td>
endTag
	  }
	  
	  print "</table>\n";
	  printPageNav($recCount);
	  
  	if (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "UpdateRec")
		{ 
			my $singleRec;
			
			$err = database::getLoVCategory($valueFields{'lov_cat_cd'});
			
    	if ($err == 0)
      {
    		$singleRec = $database::resRef->[0];
    		
    		foreach my $key (keys(%$singleRec))
    		{
    			$valueFields{$key} = $singleRec->{$key};
    		}
    		$addOrUpdate = "Update";
      }
		}
		elsif (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "Update" && $processError)
		{
			# need to do this if we tried to update a record and it failed
			$addOrUpdate = "Update";
		}
		elsif (!$processError)
		{
			# clear the fields
			clearFields();
			clearMarks();
		}
    print <<endTag;
          <form name="$formName" method="POST" action="/cgi-bin/$scriptName">
          <table><tr><td>Category Code:</td><td>
          <input type="text" name="lov_cat_cd" value="$valueFields{'lov_cat_cd'}" size="8" maxlength="8" 
endTag
		
		if ($addOrUpdate eq "Update")
		{
			print "readonly=\"readonly\"";
		}
		print <<endTag;
					/></td><td>
          <div class="mark">$markFields{'lov_cat_cd'}</div></td></tr>
          <tr><td>Description:</td><td>
          <input type="text" name="cat_desc" value="$valueFields{'cat_desc'}" size="30" maxlength="50" /></td><td>
          <div class="mark">$markFields{'lov_cat_cd'}</div></td></tr></table>
          <input type="reset" name="reset" />
          <input type="submit" name="submit" value="$addOrUpdate" />
          </form>
endTag
	}
}

sub displayListOfValues
{
	my $cgi = new CGI();
	my $scriptName = getScriptName($ENV{'SCRIPT_NAME'});
	my $formName = getFormName($scriptName);
	
	getOffset();
	
	my $addOrUpdate = "Add";
	
	$err = database::getListofValuesAndLimit($offset, $maxRecs);
	my $errMsg = $database::dbErrMsg;
	
	my $recCount = database::getListofValuesCount();
	
	if ($err < 0 && $err != database::NO_REC)
	{
	  print $cgi->p($errMsg);
	}
	else
	{
		my $records = $database::resRef;
	  print <<endTag;
	        <table class="basic">
	        <tr>
	        <td class="basic"><b>LoV Code</b></td><td class="basic"><b>LoV Category Code</b></td>
	        <td class="basic"><b>Category Description</b></td><td class="basic"><b>Update</b></td>
	        </tr>
endTag
		foreach my $ref (@$records)
		{
			print <<endTag;
			<tr>
			<td class="basic">$ref->{'lov_cd'}</td><td class="basic">$ref->{'lov_cat_cd'}</td>
			<td class="basic">$ref->{'lov_desc'}</td>
			<td class="basic"><a href="/cgi-bin/$scriptName?lov_cd=$ref->{'lov_cd'}&lov_cat_cd=$ref->{'lov_cat_cd'}&submit=UpdateRec">Update</a></td>
endTag
		}
		
		print "</table>\n";
	  printPageNav($recCount);
	  
  	if (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "UpdateRec")
		{ 
			my $singleRec;
			
			$err = database::getListofValue($valueFields{'lov_cd'}, $valueFields{'lov_cat_cd'});
			
    	if ($err == 0)
      {
    		$singleRec = $database::resRef->[0];
    		
    		foreach my $key (keys(%$singleRec))
    		{
    			$valueFields{$key} = $singleRec->{$key};
    		}
    		$addOrUpdate = "Update";
      }
		}
		elsif (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "Update" && $processError)
		{
			# need to do this if we tried to update a record and it failed
			$addOrUpdate = "Update";
		}
		elsif (!$processError)
		{
			# clear the fields
			clearFields();
			clearMarks();
		}
		
		database::getAllLoVCategories();
		
    print <<endTag;
    			<form name="$formName" method="POST" action="/cgi-bin/$scriptName">
          <table><tr><td>List of Value Code:</td><td>
          <input type="text" name="lov_cd" size="8" maxlength="8" value="$valueFields{'lov_cd'}"
endTag
    
    if ($addOrUpdate eq "Update")
    {
      print "readonly=\"readonly\" ";
    }
    
    print <<endTag;
    			/></td><td><div class="mark">$markFields{'lov_cd'}</div></td></tr>
          <tr><td>Category Code:</td>
          <td><select name="lov_cat_cd">
endTag

    foreach my $ref (@$database::resRef)
    {
      print "<option";
      
      if ($valueFields{'lov_cat_cd'} eq $ref->{'lov_cat_cd'})
      {
        print " selected";
      }
      elsif ($addOrUpdate eq "Update")
      {
        print " disabled=\"disabled\"";
      }
      
      print ">$ref->{'lov_cat_cd'}</option>\n";
    }
    print <<endTag;
    			</select></td><td><div class="mark">$markFields{'lov_cat_cd'}</div></td></tr>
          <tr><td>List of Value Description:</td><td>
          <input type="text" name="lov_desc" size="30" maxlength="50" value="$valueFields{'lov_desc'}" />
          </td><td><div class="mark">$markFields{'lov_desc'}</div></td></tr></table>
    			<input type="reset" name="reset" />
          <input type="submit" name="submit" value="$addOrUpdate" />
          </form>
endTag
	}
}

sub displayGroupsScripts
{
	my $cgi = new CGI();
	my $scriptName = getScriptName($ENV{'SCRIPT_NAME'});
	my $formName = getFormName($scriptName);
	
	getOffset();
	
	my $addOrUpdate = "Add";
	
	$err = database::getGroupScriptsAndLimit($offset, $maxRecs);
	my $errMsg = $database::dbErrMsg;
	
	my $recCount = database::getGroupScriptsCount();
  # $err = database::getAllLoVCategories();
	
	if ($err < 0 && $err != database::NO_REC)
	{
	  print $cgi->p($errMsg);
	}
	else
	{
		my $records = $database::resRef;
	  print <<endTag;
	        <table class="basic">
	        <tr>
	        <td class="basic"><b>Group Code</b></td><td class="basic"><b>Script Name</b></td>
	        <td class="basic"><b>Update</b></td><td class="basic"><b>Delete</b></td>
	        </tr>
endTag
		foreach my $ref (@$records)
		{
			print <<endTag;
			<tr>
			<td class="basic">$ref->{'group_cd'}</td><td class="basic">$ref->{'script_name'}</td>
			<td class="basic"><a href="/cgi-bin/$scriptName?group_cd=$ref->{'group_cd'}&form_script_name=$ref->{'script_name'}&submit=UpdateRec">Update</a></td>
			<td class="basic"><a href="/cgi-bin/$scriptName?group_cd=$ref->{'group_cd'}&form_script_name=$ref->{'script_name'}&submit=Delete">Delete</a></td>
endTag
		}
		
		print "</table>\n";
	  printPageNav($recCount);
	  
  	if (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "UpdateRec")
		{ 
			my $singleRec;
			
			$err = database::getGroupScript($valueFields{'group_cd'}, $valueFields{'form_script_name'});
			
    	if ($err == 0)
      {
    		$singleRec = $database::resRef->[0];
    		
    		foreach my $key (keys(%$singleRec))
    		{
    			$valueFields{$key} = $singleRec->{$key};
    		}
    		$addOrUpdate = "Update";
      }
		}
		elsif (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "Update" && $processError)
		{
			# need to do this if we tried to update a record and it failed
			$addOrUpdate = "Update";
		}
		elsif (!$processError)
		{
			# clear the fields
			clearFields();
			clearMarks();
		}
		
		database::getAllListofValuesByCatCd('GROUP');
		
		print <<endTag;
					<form name="$formName" method="POST" action="/cgi-bin/$scriptName">
					<input type="hidden" name="old_group_cd" value="$valueFields{'old_group_cd'}" />
					<input type="hidden" name="old_script_name" value="$valueFields{'old_script_name'}" />
					<table><tr><td>Group Code:</td><td>
					<select name="group_cd">
endTag
		foreach my $ref (@$database::resRef)
		{
			print "<option value=\"$ref->{'lov_cd'}\"";
			
			if ($valueFields{'group_cd'} eq $ref->{'lov_cd'})
			{
				print " selected";
			}
			
			print ">$ref->{'lov_cd'}</option>\n";
		}
		
		print <<endTag;
		</select></td><td><div class="mark">$markFields{'group_cd'}</div></td></tr>
		<tr><td>Script Name:</td>
		<td><input type="text" size="15" maxlength="30" name="form_script_name" value="$valueFields{'form_script_name'}" /></td>
		<td><div class="mark">$markFields{'form_script_name'}</div></td></tr></table>
		<input type="reset" name="reset" />
		<input type="submit" name="submit" value="$addOrUpdate" />
endTag
	}
}

sub displayUserGroups
{
	my $cgi = new CGI();
	my $scriptName = getScriptName($ENV{'SCRIPT_NAME'});
	my $formName = getFormName($scriptName);
	
	getOffset();
	
	my $addOrUpdate = "Add";
	
	$err = database::getUserGroupsAndLimit($offset, $maxRecs);
	my $errMsg = $database::dbErrMsg;
	
	my $recCount = database::getUserGroupsCount();
  # $err = database::getAllLoVCategories();
	
	if ($err < 0 && $err != database::NO_REC)
	{
	  print $cgi->p($errMsg);
	}
	else
	{
		my $records = $database::resRef;
	  print <<endTag;
	        <table class="basic">
	        <tr>
	        <td class="basic"><b>User</b></td><td class="basic"><b>Group Code</b></td>
	        <td class="basic"><b>Update</b></td><td class="basic"><b>Delete</b></td>
	        </tr>
endTag
		foreach my $ref (@$records)
		{
			database::getUserById($ref->{'userid'});
			my $userRec = $database::resRef;
			print <<endTag;
			<tr>
			<td class="basic">$userRec->[0]->{'user_nickname'}</td><td class="basic">$ref->{'group_cd'}</td>
			<td class="basic"><a href="/cgi-bin/$scriptName?form_user=$ref->{'userid'}&group_cd=$ref->{'group_cd'}&submit=UpdateRec">Update</a></td>
			<td class="basic"><a href="/cgi-bin/$scriptName?form_user=$ref->{'userid'}&group_cd=$ref->{'group_cd'}&submit=Delete">Delete</a></td>
endTag
		}
		
		print "</table>\n";
	  printPageNav($recCount);
	  
  	if (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "UpdateRec")
		{ 
			my $singleRec;
			
			$err = database::getUserGroup($valueFields{'form_user'}, $valueFields{'group_cd'});
			
    	if ($err == 0)
      {
    		$singleRec = $database::resRef->[0];
    		
    		foreach my $key (keys(%$singleRec))
    		{
    			$valueFields{$key} = $singleRec->{$key};
    		}
    		
    		database::getUserById($valueFields{'userid'});
    		my $userRec = $database::resRef->[0];
    		$valueFields{'old_form_user'} = $singleRec->{'userid'};
    		$valueFields{'form_user'}     = $userRec->{'user_nickname'}; 
    		$addOrUpdate = "Update";
      }
		}
		elsif (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "Update" && $processError)
		{
			# need to do this if we tried to update a record and it failed
			$addOrUpdate = "Update";
		}
		elsif (!$processError)
		{
			# clear the fields
			clearFields();
			clearMarks();
		}
		
		database::getAllListofValuesByCatCd('GROUP');
		
		print <<endTag;
					<form name="$formName" method="POST" action="/cgi-bin/$scriptName">
					<input type="hidden" name="old_form_user" value="$valueFields{'old_from_user'}" />
					<input type="hidden" name="old_group_cd" value="$valueFields{'old_group_cd'}" />
					<table><tr><td>User Id:</td>
					<td><input type="text" name="form_user" size="15" maxlength="15" value="$valueFields{'form_user'}" /></td>
					<td><div class="mark">$markFields{'form_user'}</div></td></tr>
					<tr><td>Group Code:</td><td>
					<select name="group_cd">
endTag
		foreach my $ref (@$database::resRef)
		{
			print "<option value=\"$ref->{'lov_cd'}\"";
			
			if ($valueFields{'group_cd'} eq $ref->{'lov_cd'})
			{
				print " selected";
			}
			
			print ">$ref->{'lov_cd'}</option>\n";
		}
		
		print <<endTag;
		</select></td><td><div class="mark">$markFields{'group_cd'}</div></td></tr></table>
		<input type="reset" name="reset" />
		<input type="submit" name="submit" value="$addOrUpdate" />
endTag
	}
}

sub displayMoneySource
{
	my $cgi = new CGI();
	my $scriptName = getScriptName($ENV{'SCRIPT_NAME'});
	my $formName = getFormName($scriptName);
	
	getOffset();
	
	my $addOrUpdate = "Add";
	
	$err = database::getAllMoneySourcesByAcctAndLimit($acctId, $offset, $maxRecs);
	my $errMsg = $database::dbErrMsg;
	
	my $recCount = database::getMoneySourceCountByAcct();
  # $err = database::getAllLoVCategories();
	
	if ($err < 0 && $err != database::NO_REC)
	{
	  print $cgi->p($errMsg);
	}
	else
	{
		my $records = $database::resRef;
	  print <<endTag;
	        <table class="basic">
	        <tr>
	        <td class="basic"><b>Money Source</b></td><td class="basic"><b>Source Type</b></td>
	        <td class="basic"><b>Balance</b></td>
	        <td class="basic"><b>Update</b></td><td class="basic"><b>Delete</b></td>
	        </tr>
endTag
		foreach my $ref (@$records)
		{
			print <<endTag;
			<tr>
			<td class="basic">$ref->{'source_txt'}</td><td class="basic">$ref->{'source_type'}</td>
			<td class="basic">$ref->{'balance'}</td>
			<td class="basic"><a href="/cgi-bin/$scriptName?seq=$ref->{'seq'}&submit=UpdateRec">Update</a></td>
			<td class="basic"><a href="/cgi-bin/$scriptName?seq=$ref->{'seq'}&submit=Delete">Delete</a></td>
endTag
		}
		
		print "</table>\n";
	  printPageNav($recCount);
	  
  	if (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "UpdateRec")
		{ 
			my $singleRec;
			
			$err = database::getMoneySource($acctId, $valueFields{'seq'});
			
    	if ($err == 0)
      {
    		$singleRec = $database::resRef->[0];
    		
    		foreach my $key (keys(%$singleRec))
    		{
    			$valueFields{$key} = $singleRec->{$key};
    		}
    		
    		$addOrUpdate = "Update";
      }
		}
		elsif (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "Update" && $processError)
		{
			# need to do this if we tried to update a record and it failed
			$addOrUpdate = "Update";
		}
		elsif (!$processError)
		{
			# clear the fields
			clearFields();
			clearMarks();
		}
		
		print <<endTag;
					<form name="$formName" method="POST" action="/cgi-bin/$scriptName">
					<input type="hidden" name="seq" value="$valueFields{'seq'}" />
					<table><tr><td>Source Description:</td>
					<td><input type="text" name="source_txt" size="30" maxlength="50" value="$valueFields{'source_txt'}" /></td>
					<td><div class="mark">$markFields{'source_txt'}</div></td></tr>
					<tr><td>Source Type:</td><td>
					<select name="source_type">
endTag
		database::getAllListofValuesByCatCd('SRCTYPE');
		foreach my $ref (@$database::resRef)
		{
			print "<option value=\"$ref->{'lov_cd'}\"";
			
			if ($valueFields{'source_type'} eq $ref->{'lov_cd'})
			{
				print " selected";
			}
			
			print ">$ref->{'lov_cd'}</option>\n";
		}
		
		print <<endTag;
		</select></td><td><div class="mark">$markFields{'source_type'}</div></td></tr>
		<tr><td>Source Balance:</td><td>
		<input type="text" name="balance" value="$valueFields{'balance'}" size="15" maxlength="15" />
		</td><td><div class="mark">$markFields{'balance'}</div></td></tr></table>
		<input type="reset" name="reset" />
		<input type="submit" name="submit" value="$addOrUpdate" />
		</form>
endTag
	}
}

sub displayUserAccounts
{
	my $cgi = new CGI();
	my $scriptName = getScriptName($ENV{'SCRIPT_NAME'});
	my $formName = getFormName($scriptName);
	
	getOffset();
	
	my $addOrUpdate = "Add";
	
	$err = database::getUserAccountsAndLimit($acctId, $offset, $maxRecs);
	my $errMsg = $database::dbErrMsg;
	
	my $recCount = database::getUserAccountsCountByAcct($acctId);
  # $err = database::getAllLoVCategories();
	
	if ($err < 0 && $err != database::NO_REC)
	{
	  print $cgi->p($errMsg);
	}
	else
	{
		my $records = $database::resRef;
	  print <<endTag;
	        <table class="basic">
	        <tr>
	        <td class="basic"><b>User</b></td><td class="basic"><b>Account</b></td>
	        <td class="basic"><b>Access</b></td>
	        <td class="basic"><b>Update</b></td><td class="basic"><b>Delete</b></td>
	        </tr>
endTag
		foreach my $ref (@$records)
		{
			database::getUserById($ref->{'userid'});
			my $userRec = $database::resRef->[0];
			database::getAccount($ref->{'acct_id'});
			my $acctRec = $database::resRef->[0];
			print <<endTag;
			<tr>
			<td class="basic">$userRec->{'user_nickname'}</td>
			<td class="basic">$acctRec->{'acct_desc'} (account # $acctRec->{'acct_id'})</td><td class="basic">$ref->{'access'}</td>
			<td class="basic"><a href="/cgi-bin/$scriptName?form_user=$ref->{'userid'}&submit=UpdateRec">Update</a></td>
			<td class="basic"><a href="/cgi-bin/$scriptName?form_user=$ref->{'userid'}&submit=Delete">Delete</a></td>
endTag
		}
		
		print "</table>\n";
	  printPageNav($recCount);
	  
  	if (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "UpdateRec")
		{ 
			my $singleRec;
			
			$err = database::getUserAccount($valueFields{'form_user'}, $acctId);
			
    	if ($err == 0)
      {
    		$singleRec = $database::resRef->[0];
    		
    		foreach my $key (keys(%$singleRec))
    		{
    			$valueFields{$key} = $singleRec->{$key};
    		}
    		
    		database::getUserById($valueFields{'userid'});
    		my $userRec = $database::resRef->[0];
    		$addOrUpdate = "Update";
      }
		}
		elsif (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "Update" && $processError)
		{
			# need to do this if we tried to update a record and it failed
			$addOrUpdate = "Update";
		}
		elsif (!$processError)
		{
			# clear the fields
			clearFields();
			clearMarks();
		}
		
		database::getAllListofValuesByCatCd('ACCTACES');
		
		print <<endTag;
					<form name="$formName" method="POST" action="/cgi-bin/$scriptName">
					<table><tr><td>User Id:</td>
					<td><input type="text" name="form_user" size="15" maxlength="15" value="$valueFields{'form_user'}" /></td>
					<td><div class="mark">$markFields{'form_user'}</div></td></tr>
					<tr><td>Access Level:</td><td>
					<select name="access_level">
endTag
		foreach my $ref (@$database::resRef)
		{
			if ($ref->{'lov_cd'} ne "OWNER")
			{
				print "<option value=\"$ref->{'lov_cd'}\"";
				
				if ($valueFields{'access_level'} eq $ref->{'lov_cd'})
				{
					print " selected";
				}
				
				print ">$ref->{'lov_cd'}</option>\n";
			}
		}
		
		print <<endTag;
		</select></td><td><div class="mark">$markFields{'access_level'}</div></td></tr></table>
		<input type="reset" name="reset" />
		<input type="submit" name="submit" value="$addOrUpdate" />
		</form>
endTag
	}
}

sub displayBuckets
{
	my $cgi = new CGI();
	my $scriptName = getScriptName($ENV{'SCRIPT_NAME'});
	my $formName = getFormName($scriptName);
	
	# printDebug($scriptName);
	
	getOffset();
	
	my $addOrUpdate = "Add";
	
	$err = database::getBucketByAcctAndLimit($acctId, $offset, $maxRecs);
	my $errMsg = $database::dbErrMsg;
	
	my $recCount = database::getBucketsCountByAcct($acctId);
  # $err = database::getAllLoVCategories();
	
	if ($err < 0 && $err != database::NO_REC)
	{
	  print $cgi->p($errMsg);
	}
	else
	{
		my $records = $database::resRef;
	  print <<endTag;
	        <table class="basic">
	        <tr>
	        <td class="basic"><b>Description</b></td><td class="basic"><b>Balance</b></td>
	        <td class="basic"><b>Refresh Amount</b></td><td class="basic"><b>Fixed/Variable</b></td>
	        <td class="basic"><b>Refresh Frequency</b></td><td class="basic"><b>Last Process Date</b></td>
	        <td class="basic"><b>Auto process Indicator</b></td>
	        <td class="basic"><b>Update</b></td><td class="basic"><b>Delete</b></td>
	        </tr>
endTag
		foreach my $ref (@$records)
		{
			database::getListofValue($ref->{'refresh_freq'}, 'FREQENCY');
			my $refreshFreq = $database::resRef->[0]->{'lov_desc'};
			database::getUserById($ref->{'userid'});
			my $userRec = $database::resRef->[0];
			database::getAccount($ref->{'acct_id'});
			my $acctRec = $database::resRef->[0];
			my $lastProcessDate = "Never";
			$lastProcessDate = $ref->{'last_process_dt'} if (defined($ref->{'last_process_dt'}));
			print <<endTag;
			<tr>
			<td class="basic">$ref->{'buck_desc'}</td><td class="basic">$ref->{'balance'}</td>
			<td class="basic">$ref->{'refresh_amt'}</td><td class="basic">$ref->{'fix_var'}</td>
			<td class="basic">$refreshFreq</td><td class="basic">$lastProcessDate</td>
			<td class="basic">$ref->{'auto_process_ind'}</td>
			<td class="basic"><a href="/cgi-bin/$scriptName?seq=$ref->{'seq'}&submit=UpdateRec">Update</a></td>
			<td class="basic"><a href="/cgi-bin/$scriptName?seq=$ref->{'seq'}&submit=Delete">Delete</a></td>
endTag
		}
		
		print "</table>\n";
	  printPageNav($recCount);
	  
  	if (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "UpdateRec")
		{ 
			my $singleRec;
			
			$err = database::getBucket($acctId, $valueFields{'seq'});
			
    	if ($err == 0)
      {
    		$singleRec = $database::resRef->[0];
    		
    		foreach my $key (keys(%$singleRec))
    		{
    			$valueFields{$key} = $singleRec->{$key};
    		}
    		
    		database::getUserById($valueFields{'userid'});
    		my $userRec = $database::resRef->[0];
    		$addOrUpdate = "Update";
      }
		}
		elsif (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "Update" && $processError)
		{
			# need to do this if we tried to update a record and it failed
			$addOrUpdate = "Update";
		}
		elsif (!$processError)
		{
			# clear the fields
			clearFields();
			clearMarks();
		}
		
		my $formDErr = database::getAllListofValuesByCatCd('BUCKTYPE');
		
		print <<endTag;
					<form name="$formName" method="POST" action="/cgi-bin/$scriptName">
					<input type="hidden" name="seq" value="$valueFields{'seq'}" />
					<table><tr><td>Bucket Description:</td>
					<td><input type="text" name="buck_desc" size="30" maxlength="50" value="$valueFields{'buck_desc'}" /></td>
					<td><div class="mark">$markFields{'buck_desc'}</div></td></tr>
					<tr><td>Balance:</td><td>
					<input type="text" name="balance" size="15" maxlength="15" value="$valueFields{'balance'}" /></td>
					<td><div class="mark">$markFields{'balance'}</div></td></tr>
					<tr><td>Refresh Amount:</td><td>
					<input type="text" name="refresh_amt" size="15" maxlength="15" value="$valueFields{'refresh_amt'}" /></td>
					<td><div class="mark">$markFields{'refresh_amt'}</div></td></tr>
					<tr><td>Fixed/Variable:</td><td>
					<select name="fix_var">
endTag
		if ($formDErr == 0)
		{
			foreach my $fixVarVal (@$database::resRef)
			{
				print "<option value=\"$fixVarVal->{'lov_cd'}\"";
				print " selected" if ($valueFields{'fix_var'} eq $fixVarVal->{'lov_cd'});
				print ">$fixVarVal->{'lov_cd'}</option>\n";
			}
		}
		
		$formDErr = database::getAllListofValuesByCatCd('FREQENCY');
		
		print <<endTag;
					</select></td><td><div class="mark">$markFields{'fix_var'}</div></td></tr>
					<tr><td>Refresh Frequency</td><td>
					<select name="refresh_freq">
endTag
		if (!$formDErr)
		{
			foreach my $refreshFreq (@$database::resRef)
			{
				print "<option value=\"$refreshFreq->{'lov_cd'}\"";
				print " selected" if ($refreshFreq->{'lov_cd'} eq $valueFields{'refresh_freq'});
				print ">$refreshFreq->{'lov_desc'}</option>\n";
			}
		}
		print <<endTag;
					</select></td><td><div class="mark">$markFields{'refresh_freq'}</div></td></tr>
					<tr><td>Last Process Date</td>
					<td><input type="text" name="last_process_dt" size="15" maxlength="10" value="$valueFields{'last_process_dt'}" /></td>
					<td><div class="mark">$markFields{'last_process_dt'}</div></td></tr>
					<tr><td>Auto Process Indicator</td>
endTag
		print "<td><input type=\"checkbox\" name=\"auto_process_ind\" value=\"Y\"";
		print " checked" if ($valueFields{'auto_process_ind'} eq "Y");
		print " /></td>\n";
		print <<endTag;
					<td><div class="mark">$markFields{'auto_process_ind'}</div></td></tr>
					</table>
					<input type="reset" name="reset" />
					<input type="submit" name="submit" value="$addOrUpdate" />
					</form>
endTag
	}
}

sub displayTransfer
{
	my $cgi = new CGI();
	my $scriptName = getScriptName($ENV{'SCRIPT_NAME'});
	my $formName = getFormName($scriptName);
	
	# printError();
	
  # getOffset();
  
  # $err = database::getTransactionTypesAndLimit($acctId, $offset, $maxRecs);
  # printDebug();
  # my $recCount = database::getTransactionTypesCountByAcct($acctId);
  
	# $err = database::getIncomeExpenseByAcctAndLimit($acctId, $offset, $maxRecs);
	# my $recCount = database::getIncomeExpenseCountByAcct($acctId);
	my $addOrUpdate = "Transfer";
	  
#	if (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "UpdateRec")
#	{ 
#		my $singleRec;
#			
#		$err = database::getTransactionType($valueFields{'typeid'}, $acctId);
#			
#   	if ($err == 0)
#    {
#   		$singleRec = $database::resRef->[0];
#    		
#   		foreach my $key (keys(%$singleRec))
#   		{
#   			$valueFields{$key} = $singleRec->{$key};
#   		}
#    		
#   		$addOrUpdate = "Update";
#     }
#	}
#		if (defined($valueFields{'submit'}) && $valueFields{'submit'} eq "Tranfer" && $processError)
#		{
#			# need to do this if we tried to update a record and it failed
#			$addOrUpdate = "Update";
#		}
		if (!$processError)
		{
			# clear the fields
			clearFields();
			clearMarks();
		}
		
		
		my $tempErr = database::getAllMoneySourcesByAcct($acctId);
		my $moneySourceList=[];
		$moneySourceList = $database::resRef if ($tempErr == 0);
	  
	  print <<endHTML;
	  			<form name="$formName" action="/cgi-bin/$scriptName" method="POST">
	  			<table>
	  			<tr><td>Transfer Date:</td>
	  			<td><input type="text" name="transfer_dt" value="$valueFields{'transfer_dt'}" size="10" maxlength="10"/></td>
	  			<td><div class="mark">$markFields{'transfer_dt'}</div></td></tr>
	  			<tr><td>From:</td>
	  			<td><select name="ms_out">
endHTML
		foreach my $ref (@$moneySourceList)
		{
			print "<option value=\"$ref->{'seq'}\"";
			print " selected" if ($valueFields{'ms_out'} == $ref->{'seq'});
			print ">$ref->{'source_txt'} (Balance: $ref->{'balance'})</option>\n";
		}
		print <<endHTML;
					</select></td><td><div class="mark">$markFields{'ms_out'}</div></td></tr>
					<tr><td>To:</td>
					<td><select name="ms_in">
endHTML
		foreach my $ref (@$moneySourceList)
		{
			print "<option value=\"$ref->{'seq'}\"";
			print " selected" if ($valueFields{'ms_in'} == $ref->{'seq'});
			print ">$ref->{'source_txt'} (Balance: $ref->{'balance'})</option>\n";
		}
		
		print <<endHTML;
					</select></td><td><div class="mark">$markFields{'ms_in'}</div></td></tr>
					<tr><td>Amount:</td>
					<td><input type="text" name="amt" size="15" maxlength="15" value="$valueFields{'amt'}" /></td>
					<td><div class="mark">$markFields{'amt'}</div></td></tr>
					</table>
	  			<input type="reset" name="reset" />
          <input type="submit" name="submit" value="$addOrUpdate" />
	  			</form>
endHTML
}

sub printPageNav
{
	my $numRecs = shift();
	my $passThroughParms = shift();
	
	$passThroughParms = "" if (!defined($passThroughParms));
	
	if (!defined($numRecs) || $maxRecs == 0 || $numRecs <= $maxRecs || $numRecs <= 0)
	{
		return;
	}
	
	my $quotient = $numRecs / $maxRecs;
	
	my $numPages = int($quotient);
	
	$numPages++ if ($quotient > $numPages);
	
	my $curPage = int($offset / $maxRecs) + 1;
	my $curPagePlus = $curPage + 1;
	my $curPageMinus = $curPage - 1;
	my $scriptName = getScriptName($ENV{'SCRIPT_NAME'});
	
	print "<div class=\"nav\">\n";
	
	if ($curPage != 1)
	{
		print "<a href=\"${site}cgi-bin/$scriptName?page=1$passThroughParms\">&lt;&lt;</a>\n";
		print "<a href=\"${site}cgi-bin/$scriptName?page=$curPageMinus$passThroughParms\">&lt;</a>\n";
	}
	
	for ((my $i) = 1; $i <= $numPages; $i++)
	{
		if ($curPage == $i)
		{
			print "$i\n";
		}
		else
		{
			print "<a href=\"${site}cgi-bin/$scriptName?page=$i$passThroughParms\">$i</a>\n";
		}
	}
	
	if ($curPage != $numPages)
	{
		print "<a href=\"${site}cgi-bin/$scriptName?page=$curPagePlus$passThroughParms\">&gt;</a>\n";
		print "<a href=\"${site}cgi-bin/$scriptName?page=$numPages$passThroughParms\">&gt;&gt;</a>\n";
	}
	
	print "</div>";
}

sub getOffset
{
	my $cgi = new CGI();
	
	my $page = $cgi->param("page");
  
  if (defined($page))
  {
  	$offset = ($page - 1) * $maxRecs;
  }
  else
  {
  	$offset = 0;
  }
}

sub clearFields
{
	foreach my $key (keys(%valueFields))
	{
		$valueFields{$key} = "";
	}
}

sub clearMarks
{
	foreach my $key (keys(%markFields))
	{
		$markFields{$key} = "";
	}
}

#
# This subroutine sets up a form to display a date picker.  Will automatically default to todays
# date
# Parameters:
#   $displayYear - boolean whether to display the year
#   $displayMonth - boolean whether to display the month
#   $displayDay - boolean whether to display the day
#   $displayForm - tells whether or not to include the form tags and submit reset buttons
#   $dateToUse - will set the date to this value if it is a valid date, optional will default to today
#   $sequence - to display multiple date pickers on a single form, optional will default to zero
#
sub datePicker
{
	my $cgi = new CGI();
	
	my $displayYear  = shift();
	my $displayMonth = shift();
	my $displayDay   = shift();
	my $displayForm  = shift();
	my $dateToUse    = shift();
	my $sequence     = shift();
	
	$sequence = 0 if (!defined($sequence) || $sequence == "");
	
	my $scriptName = $ENV{'SCRIPT_NAME'};
	
	my @months = ( "January", "Feburary", "March", "April", "May", "June", "July", "August",
								 "September", "October", "November", "December" ); 
	
	my $curMonth = $cgi->param("month$sequence");
	my $curYear  = $cgi->param("year$sequence");
	my $curDay   = $cgi->param("day$sequence");

	my $curDate = $dateToUse;
	
	$curDate = strftime ("%Y-%m-%d", localtime()) if (!validateDate($curDate));
	
	if (!defined($curMonth) || $curMonth eq "")
	{
		$curMonth = substr($curDate, 5, 2);
	}
	
	if (!defined($curYear) || $curYear eq "")
	{
		$curYear = substr($curDate, 0, 4);
	}
	
	if (!defined($curDay) || $curDay eq "")
	{
		$curDay = substr($curDate, 8, 2);
	}
	
	my $toYear = substr($curDate, 0, 4);
	
	print "<table class=\"filter\">\n<tr>\n";
	
	if (!$sequence)
	{
		print "<td class=\"datepick\">Year</td>\n" if ($displayYear);
		print "<td class=\"datepick\">Month</td>\n" if ($displayMonth);
		print "<td class=\"datepick\">Day</td>\n" if ($displayDay);
	}
	
	print "</tr>\n<tr>\n";
	
	if ($displayForm)
	{
		print  "<form name=\"datepicker\" method=\"get\" action=\"$scriptName\">\n";
	}
	if ($displayYear)
	{
		print "<td class=\"datepick\"><select name=\"year$sequence\">\n";
		for (my $i = 2000; $i <= $toYear; $i++)
		{
			print "<option value=\"$i\"";
			
			if ($i == $curYear)
			{
				print " selected"
			}
			
			print ">$i</option>\n";
		}
	}
	if ($displayMonth)
	{
		print "</select></td>\n";
		print "<td class=\"datepick\"><select name=\"month$sequence\">\n";
		
		for (my $i = 0; $i <= $#months; $i++)
		{
			my $monthVal = $i + 1;
			$monthVal = "0" . $monthVal if ($monthVal < 10);
			print "<option value=\"$monthVal\"";
			
			if ($curMonth == $monthVal)
			{
				print " selected";
			}
			
			print ">$months[$i]</option>\n";
		}
	}
	
	if ($displayDay)
	{
		print "</select></td>\n";
		print "<td class=\"datepick\"><select name=\"day$sequence\">\n";
		
		for (my $i = 1; $i <=31; $i++)
		{
			print "<option value=\"$i\"";
			
			print " selected" if ($curDay == $i);
			
			print ">$i</option>\n";
		}
	}
	
	print "</select></td>\n";
	
	if ($displayForm)
	{
		print <<endTag;
		<td class="datepick"><input type="submit" name="submit" value="Pick Date" />
		<td class="datepick"><input type="reset" name="reset" />
		</form>
endTag
	}
	print "</table>\n";
}

sub validateDate
{
	my $date =  shift();
	
	return 0 if (!defined($date));
	
	my $year = substr($date, 0, 4);
	my $month = substr($date, 5, 2);
	my $day = substr($date, 8, 2);
	
	return 0 if (!validateYearMonth($year, $month));
	
	if ($month == 4 || $month == 6 || $month == 9 || $month == 11)
	{
		return 0 if ($day > 30);
	}
	
	if ($month == 2)
	{
		return 0 if ($day > 29);
		
		return 0 if (($year % 4) > 0 && $day == 29);
		
		return 0 if (($year % 4) == 0 && ($year % 400) == 0 && $day == 29);
	}
	
	return 1;
}

sub getLastDayofMonth
{
	my $curDate = strftime ("%Y-%m-%d", localtime());
	my $year = shift();
	my $month = shift();
	
	$year = substr($curDate, 0, 4) if (!defined($year));
	
	$month = substr($curDate, 5, 2) if (!defined($month));
	
	for (my $i = 31; $i > 27; $i--)
	{
		my $dateVal = "$year-$month-$i";
		
		return $dateVal if (validateDate($dateVal));
	}
}

sub validateYearMonth
{
	my $year = shift();
	my $month = shift();
	
	return 0 if (!defined($year) || !defined($month));
	
	return 0 if (!($year =~ /$integerRegEx/) || $year < 0);
	
	return 0 if (!($month =~ /$integerRegEx/) || $month < 1 || $month > 12);
	
	return 1;
}

sub validateYearMonthDay
{
	my $year = shift();
	my $month = shift();
	my $day = shift();
	
	return 0 if (!validateYearMonth($year, $month));
		
	return 0 if (!defined($day));
		
	return 0 if (!($day =~ /$integerRegEx/) || $day < 0 || $day > 31);
	
	return 0 if (($month == 2 || $month == 4 || $month == 6 || $month == 9 || 
				  $month == 11) && $day > 30);
	
	if ($month == 2)
	{
		return 0 if ($day == 30);
		
		if ($day == 29)
		{
			return 0 if ($year % 4 != 0);
			
			if ($year % 100 == 0)
			{
				return 0 if ($year %400 != 0);
			}
		}
	}
	
	return 1;
}

sub changeAccount
{
	undef($utilErrMsg);
	
	my $errPre = "Error in changeAccount:  ";
	
	my $newAcct = shift();
	
	# printDebug($newAcct);
	
	if (!defined($newAcct))
	{
		$utilErrMsg = $errPre . "expects one parameter (new account)";
		return NO_PARM;
	}
	
	if (privyToAccount($userId, $newAcct))
	{
		setSessVarAcct($newAcct);
	}
	else
	{
		return -1;
	}
}

sub printBucketListCombo
{
	my $inSeq = shift();
	$inSeq = 0 if (!defined($inSeq) || $inSeq eq "");
	my $tempErr = database::getBucketsByAcctId($acctId);
	my $buckList = [];
	$buckList = $database::resRef if ($tempErr == 0);
	
	print "<select name=\"buck_seq\">\n";
	
	foreach my $ref (@$buckList)
	{
		my $moneyClass = "pos_money";
		$moneyClass = "neg_money" if ($ref->{'balance'} < 0);
		print "<option value=\"$ref->{'seq'}\"";
		print " selected" if ($ref->{'seq'} == $inSeq);
		print ">$ref->{'buck_desc'} <div class=\"$moneyClass\">$ref->{'balance'}</div></option>\n";
	}
	
	print "</select>\n";
}

sub printError
{
	if ($err < 0)
	{
		print "<p>$errMsg</p>\n";
	}
}

sub deleteGlobalHashes
{
	foreach my $key (keys(%valueFields))
	{
		delete($valueFields{$key});
	}
	
	foreach my $key (keys(%markFields))
	{
		delete($markFields{$key});
	}
}

sub setDefaults
{
	foreach my $key (keys(%valueFields))
	{
		if (!defined($valueFields{$key}))
		{
			$valueFields{$key} = "";
		}
		
		if (!defined($markFields{$key}))
		{
			$markFields{$key} = "";
		}
	}
}

sub autoProcessBuckets
{
	my $errPre = "Error in autoProcessBuckets:  ";
	
	if (!database::isConnected())
	{
		$utilErrMsg = $errPre . "Not connected to database";
		return database::NO_HANDLE;
	}
	
	# get all the users accounts
	my $dbErr = database::getAllAccounts($userId);
	
	if ($dbErr)
	{
		$utilErrMsg = $errPre . $database::dbErrMsg;
		return $dbErr;
	}
	
	my $accountList = $database::resRef;
	
	foreach my $account (@$accountList)
	{
		if ($account->{'access'} ne "READ")
		{
			# get the buckets
			$dbErr = database::getBucketsByAcctId($account->{'acct_id'});
			
			if ($dbErr && $dbErr != database::NO_REC)
			{
				$utilErrMsg = $errPre . $database::dbErrMsg;
				return $dbErr;
			}
			
			my $bucketList = $database::resRef;
			
			foreach my $bucket (@$bucketList)
			{
				if ($bucket->{'auto_process_ind'} eq "Y")
				{
					# need to check the last date (if null then refresh the amount) and compare it to the frequency.
					if (!defined($bucket->{'last_process_dt'}))
					{
						my $tempDate = strftime ("%Y-%m-%d", localtime());
						$dbErr = database::refreshBucket($account->{'acct_id'}, $userId, $bucket->{'seq'}, $tempDate);
						
						if ($dbErr < 0)
						{
							$utilErrMsg = $errPre . $database::dbErrMsg;
							return $dbErr;
						}
					}
					else
					{
						my $numToProcess;
						my $lastProcessDate;
						calculateProcessDate($bucket->{'last_process_dt'}, $bucket->{'refresh_freq'},
																	\$lastProcessDate, \$numToProcess);
						
						if ($numToProcess > 0)
						{
							# make a decision on whether or not to process the refresh a certain number of time ($numToProcess)
							# times or just once, perhaps make this dependant on a database flag?
							
							$dbErr = database::refreshBucket($account->{'acct_id'}, $userId, $bucket->{'seq'}, $lastProcessDate);
							
							if ($dbErr < 0)
							{
								$utilErrMsg = $errPre . $database::dbErrMsg;
								return $dbErr;
							}
						}
					}
				}
			}
		}
	}
	return 0;
}

#
#This subroutine is used to calculate the next process date as well as the number of times to process
#For example our process frequency is weekly, if the last process date is 2012-10-29 and the current
#date is 2012-11-12 then the number of times to process is 2 and the last process output date would be 2012-11-12 since
#two weeks have passed
#Parameters:
#  lastProcessDate - the last time the transaction was processed
#  frequency - the frequency of the processing (WE - weekly, BW - Bi-Weekly, MO - monthly, BM - bi-monthly)
#  lastProcessDateOut - output date from the input date (could be the same as the input)
#  numProcess - output number to process (see example above)
#
sub calculateProcessDate
{
	my $lastProcessDate = shift();
	my $frequency = shift();
	my $lastProcessDateOut = shift();
	my $numToProcessOut = shift();
	
	$lastProcessDate = "" if (!defined($lastProcessDate));
	$frequency = "" if (!defined($frequency));
	
	if ($lastProcessDate eq "" || $frequency eq "" || !defined($lastProcessDateOut) || !defined($numToProcessOut))
	{
		return -1;
	}
	
	my $year = substr($lastProcessDate, 0, 4);
	my $month = substr($lastProcessDate, 5, 2);
	my $day = substr($lastProcessDate, 8, 2);
	
	my $curDate = strftime("%Y-%m-%d", localtime());
	my $curYear = substr($curDate, 0, 4);
	my $curMonth = substr($curDate, 5, 2);
	my $curDay = substr($curDate, 8, 2);
	
	my $dayDiff = Delta_Days($year, $month, $day, $curYear, $curMonth, $curDay);
	my $lastProcessYear;
	my $lastProcessMonth;
	my $lastProcessDay;
	my $refresh;
	my $numToProcess = 0;
	my $daysToAdd = 0;
	
	if ($frequency eq "WE")
	{
		$numToProcess = int($dayDiff / 7);
		$daysToAdd = $numToProcess * 7;
		# printDebug($numToProcess, $daysToAdd, $dayDiff);
	}
	elsif ($frequency eq "BW")
	{
		$numToProcess = int($dayDiff / 14);
		$daysToAdd = $numToProcess * 14;
	}
	elsif ($frequency eq "BM")
	{
		#bi-monthly calculation is a little harder to do
		my $procYear = $year;
		my $procMonth = $month;
		my $procDay = $day;
		my $daysInMonth = Days_in_Month($procYear, $procMonth);
		my $daysDivide2 = int($daysInMonth / 2);
		my $addOne = $daysInMonth % 2;
		my $curDaysToAdd = 0;
		$daysToAdd = 0;
		$numToProcess = 0;
		
		if ($day < $daysDivide2)
		{
			$curDaysToAdd = $daysDivide2;
		}
		else
		{
			$curDaysToAdd = $daysDivide2 + $addOne;
		}
		
		while ($curDaysToAdd < $dayDiff)
		{
			Add_Delta_Days($procYear, $procMonth, $procDay, $curDaysToAdd);
			
			$dayDiff -= $curDaysToAdd;
			$daysToAdd += $curDaysToAdd;
			
			$daysInMonth = Days_in_Month($procYear, $procMonth);
			$daysDivide2 = int($daysInMonth / 2);
			$addOne = $daysInMonth % 2;
			
			if ($procDay < $daysDivide2)
			{
				$curDaysToAdd = $daysDivide2;
			}
			else
			{
				$curDaysToAdd = $daysDivide2 + $addOne;
			}
		}
		$numToProcess++;
	}
	elsif ($frequency eq "MO")
	{
		my $procYear = $year;
		my $procMonth = $month;
		my $daysInMonth = Days_in_Month($procYear, $procMonth);
		
		$daysToAdd = 0;
		$numToProcess = 0;
		
		while ($daysInMonth <= $dayDiff)
		{
			$daysToAdd += $daysInMonth;
			$numToProcess++;
			$dayDiff -= $daysInMonth;
			
			$procMonth++;
			if ($procMonth > 12)
			{
				$procMonth = 1;
				$procYear++;
			}
			$daysInMonth = Days_in_Month($procYear, $procMonth);
		}
	}
	
	($year, $month, $day) = Add_Delta_Days ($year, $month, $day, $daysToAdd);
	
	$month = "0" . $month if ($month < 10);
	$day = "0" . $day if ($day < 10);
	
	$$lastProcessDateOut = "$year-$month-$day";
	$$numToProcessOut = $numToProcess;
}

#
#This subroutine is used to automatically process the income expenses if they are flagged
#to do so
#
sub autoProcessIncomeExpense
{
	
}

#
#This subroutine is going to be used to get the information for the transactions screen
#Parameters:
#  fromDate - from date
#  toDate - to date for the transactions
#  bucket - the bucket the transaction came from
#  outputRecs - the array of hash references
#  outMoneySum - output of the out money
#  inMoneySum - output of the in money
#


1;