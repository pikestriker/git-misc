#!C:\strawberry\perl\bin\perl -w

package database;

use strict;
use Exporter;
use DBI;
use Digest::MD5 qw(md5_hex);

# we use the our keywork so that these arrays are available outside of this module
our @ISA = qw( Exporter );
our @EXPORT = qw();
our @EXPORT_OK = qw( mydbConnect
                     getUsers1
                     getUsers2
                     mydbDisconnect 
                     addTransaction 
                     deleteTransactionn );

my $dbh;
my $stmt;
our $dbErrMsg;
our $resRef;
our $moreRecs;

use constant NO_REC      => -1000;
use constant NO_PARM     => -1001;
use constant NO_PREPARE  => -1002;
use constant NO_EXECUTE  => -1003;
use constant NO_HANDLE   => -1004;
use constant REC_FOUND   => -1005;
use constant PARM_ERROR  => -1006;
use constant MISC_ERROR  => -1007;

use constant DBH_ERROR_STRING => "Database handle isn't defined, please connect first";
use constant NO_RECORDS_STRING => "no records to return";

sub mydbConnect
{
  undef ($dbErrMsg);
  $dbh = DBI->connect("dbi:Pg:dbname=website", "www-data", "website");

  if (!defined($dbh) || defined($dbh->err()))
  {
    $dbErrMsg = "Could not connect to mydb:  " . $dbh->errstr();
    return -1;
  }
  
  # turn off auto-commit
  $dbh->{'AutoCommit'} = 0;
  
  return 0;
}

sub specialSpecialConnect
{
	# specialSpecialConnect turns the autocommit flag off
	undef($dbErrMsg);
	my $errPre = "Error in specialSpecialConnect:  ";
	
	$dbh = DBI->connect("dbi:Pg:dbname=website", "www-data", "website");
	
	if (!defined($dbh) || defined($dbh->err()))
	{
		$dbErrMsg = $errPre . "Could not connect to mydb:  " . $dbh->errstr();
		return -1;
	}
	
	$dbh->{'AutoCommit'} = 0;
	
	return 0;
}

sub commitTrans
{
	undef($dbErrMsg);
	my $errPre = "Error in commitTrans:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	$dbh->commit();
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "problem commiting the transaction,  " . $dbh->errstr();
		return MISC_ERROR;
	}
	
	return 0;
}

sub rollbackTrans
{
	undef($dbErrMsg);
	my $errPre = "Error in rollbackTrans:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	$dbh->rollback();
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "problem rolling back the transaction,  " . $dbh->errstr();
		return MISC_ERROR;
	}
	
	return 0;
}

sub isConnected
{
	return 1 if (defined($dbh));
	return 0;
}

sub getUsers1
{
  # Get all the users
  undef $dbErrMsg;
  
  $stmt = $dbh->prepare("select * from users");
  
  if (!defined($stmt) || defined($dbh->err()))
  {
    $dbErrMsg = "Trouble preparing SQL statement:  " . $dbh->errstr();
    return -1;
  }
  $stmt->execute();
  
  if (defined($stmt->err()))
  {
    $dbErrMsg = "There was a problem processing an execute:  " . $stmt->errstr();
    return -2;
  }
  
  # @resSet = $stmt->fetchall_arrayref();
  $resRef = $stmt->fetchall_arrayref({});
#  my $array_ref = $stmt->fetchall_arrayref({});
#  my $ref;
#  my %hash;
#  print ref($array_ref) . "\n";
#  my $counter = 0;
#  foreach $ref (@$array_ref)
#  {
#  	my $refType = ref($ref);
#  	$counter++;
#  	if ($refType eq "HASH")
#  	{
#  	  print "Here is the data for record $counter:\n";
#  	  foreach my $key (keys(%$ref))
#  	  {
#  	  	print "$key => $ref->{$key}\n";
#  	  }
#  	  print "\n\n";
#  	}
#  	print ref($ref) . "\n";
 # 	print "$ref is Here\n";
#  	print "$ref->{'user_sur_nm'}, $ref->{'user_first_nm'}\n";
#  	print "$$ref{'user_sur_nm'}, $$ref{'user_first_nm'}\n";
  	# print "%$ref->{'user_sur_nm'}, %$ref->{'user_first_nm'}\n";
#  }
#  while (my $ref = $stmt->fetchrow_hashref())
#  {
#    print "$ref->{'user_sur_nm'}, $ref->{'user_first_nm'}\n";
#  }
  
  return 0;
}

sub getUserByUsernameAndPassword
{
  # Find out if there is a user and password confirmation
  undef $dbErrMsg;
  
  my $errPre = "Error in getUserByUsernamdAndPassword:  ";
  
  my $user = shift();
  my $password = shift();
  
  if (!defined($dbh))
  {
  	$dbErrMsg = $errPre . "database handle not defined, please connect first";
  	return -1;
  }
  
  if (!defined($user) || !defined($password))
  {
    $dbErrMsg = $errPre . "expects two parameters (user id/email and password";
    return -2;
  }
  
  $stmt = $dbh->prepare("select * from users where user_nickname = ? and password = md5(?)");
  
  if ($dbh->err())
  {
  	$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
  	return -3;
  }
  
  $stmt->execute($user, $password);
  
  if ($stmt->err())
  {
  	$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
  	return -4;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
  	# check for user record based on the email and password
  	$stmt = $dbh->prepare("select * from users where user_email = ? and password = md5(?)");
  	
  	if ($dbh->err())
  	{
  		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
  		return -5;
  	}
  	
  	$stmt->execute($user, $password);
  	
  	if ($stmt->err())
  	{
  		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
  		return -6;
  	}
  	$resRef = $stmt->fetchall_arrayref({});
  
	  if (!@$resRef)
	  {
	  	$dbErrMsg = $errPre . "no records returned";
	    return NO_REC;
	  }
  }
  
  return 0;
}

sub getUserById
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getUserById:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle not defined, please connect first";
		return -1;
	}
	
	my $userId = shift();
	
	if (!defined($userId))
	{
		$dbErrMsg = $errPre . "expects one paramter (user Id)";
		return -2;
	}
	
	$stmt = $dbh->prepare("select * from users where userid = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return -3;
	}
	
	$stmt->execute($userId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return -4;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getUserByNickname
{
	# since the user nickname is unique it will return one record
	undef ($dbErrMsg);
	
	my $errPre = "Error in getUserByNickname:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle not defined, please connect first";
		return -1;
	}
	
	my $userNickname = shift();
	
	if (!defined($userNickname))
	{
		$dbErrMsg = $errPre . "expects one parameter (user nickname)";
		return -2;
	}
	
	$stmt = $dbh->prepare("select * from users where user_nickname = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return -3;
	}
	
	$stmt->execute($userNickname);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return -4;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getUserByEmail
{
	# this is another unique key in the users table, it will only return one record
	undef($dbErrMsg);
	
	my $errPre = "Error in getUserByEmail:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle not defined, please connect first";
		return -1;
	}
	
	my $userEmail = shift();
	
	if (!defined($userEmail))
	{
		$dbErrMsg = $errPre . "expects one parameter (user email)";
		return -2;
	}
	
	$stmt = $dbh->prepare("select * from users where user_email = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return -3;
	}
	
	$stmt->execute($userEmail);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return -4;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub updateLastAcctId
{
	undef($dbErrMsg);
	
	my $errPre = "Error in updateLastAcctId:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle not defined, please connect first";
		return NO_HANDLE;
	}
	
	my $userId = shift();
	my $acctId = shift();
	
	if (!defined($userId) || !defined($acctId))
	{
		$dbErrMsg = $errPre . "expects two parameters (user Id, account Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("update users set last_acct_id = ?, upd_id = ?, upd_ts = now() where userid = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $userId, $userId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

# transaction_type routines
sub getAllTransactionTypes
{
  undef ($dbErrMsg);
  
  my $errPre = "Error in getAllTransactionTypes:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $acctId = shift();
  
  if (!defined($acctId))
  {
  	$dbErrMsg = $errPre . "expects one parameter (account Id)";
  	return NO_PARM;
  }
  
  $stmt = $dbh->prepare("Select * from transaction_type where acct_id = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($acctId);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
  	$dbErrMsg = $errPre . "no records returned";
  	return NO_REC;
  }
  
  return 0;
}

sub addTransactionType
{
  undef ($dbErrMsg);
  
  my $errPre = "Error in addTransactionType:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $typeId = shift();
  my $typeDesc = shift();
  my $acctId = shift();
  my $userId = shift();			#who is adding the transaction
  my $transType = shift();
  my $buckSeq = shift();

  if (!defined($typeId) || !defined($typeDesc) || !defined($acctId) || !defined($userId) ||
  		!defined($transType) || !defined($buckSeq) || $typeId eq "" || $typeDesc eq "" ||
  		$acctId eq "" || $transType eq "" || $buckSeq eq "")
  {
    $dbErrMsg = $errPre . "expects six parameters (type Id, type description, account Id, user Id, " .
    						"transaction type and bucket sequence)";
    return NO_PARM;
  }
    
  $stmt = $dbh->prepare ("insert into transaction_type (typeid, type_desc, acct_id, crtn_id, upd_id, trans_type, " .
  											 "buck_seq) values (?, ?, ?, ?, ?, ?, ?)");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute ($typeId, $typeDesc, $acctId, $userId, $userId, $transType, $buckSeq);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub deleteTransactionType
{
  undef($dbErrMsg);
  
  my $errPre = "Error in deleteTransactionType:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $typeId = shift();
  my $acctId = shift();
  
  if (!defined($typeId) || !defined($acctId))
  {
    $dbErrMsg = $errPre . "expects two parameters (type Id and account Id)";
    return NO_PARM;
  }
  
  my $err = getTransactionType($typeId, $acctId);
  
  if ($err < 0)
  {
  	return $err;							# propogate the error through
  }
  
  $stmt = $dbh->prepare("delete from transaction_type where typeid = ? and acct_id = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($typeId, $acctId);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub updateTransactionType
{
	undef($dbErrMsg);
	
	my $errPre = "Error in updateTransactionType:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $typeId = shift();
  my $typeDesc = shift();
  my $acctId = shift();
  my $userId = shift();
  my $transType = shift();
  my $buckSeq = shift();
  
  if (!defined($typeId) || !defined($typeDesc) || !defined($acctId) ||
  		!defined($userId) || !defined($transType) || !defined($buckSeq) ||
  		$typeId eq "" || $typeDesc eq "" || $acctId eq "" || $userId eq "" ||
  		$transType eq "" || $buckSeq eq "")
  {
    $dbErrMsg = $errPre . "expects six parameters (type Id, type description " .
    											"account Id, user Id, transaction type and bucket sequence)";
    return NO_PARM;
  }

  $stmt = $dbh->prepare("update transaction_type set type_desc = ?, upd_id = ?, upd_ts = now(), " .
  											"trans_type = ?, buck_seq = ? where typeid = ? and acct_id = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($typeDesc, $userId, $transType, $buckSeq, $typeId, $acctId);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE; 
  }
  
  return 0;
}

sub getTransactionType
{
  undef($dbErrMsg);
  
  my $errPre = "Error in getTransactionType:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $typeId = shift();
  my $acctId = shift();
  
  if (!defined($typeId) || !defined($acctId))
  {
    $dbErrMsg = $errPre . "expects two parameters (type Id and account Id)";
    return NO_PARM;
  }
  
  $stmt = $dbh->prepare("select * from transaction_type where typeid = ? and acct_id = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($typeId, $acctId);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "no record exists";
    return NO_REC;
  }
  
  return 0;
}

sub getTransactionTypesAndLimit
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getTransactionTypesAndLimit:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle not defined, please connect first";
		return NO_HANDLE;
	}

	my $acctId = shift();
	my $offset = shift();
	my $recLimit = shift();
	
	if (!defined($acctId) || !defined($offset) || !defined($recLimit))
	{
		$dbErrMsg = $errPre . "expects three parameters (account Id, offset and record limit)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from transaction_type where acct_id = ? order by crtn_ts desc " .
												"limit ? offset ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $recLimit, $offset);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getTransactionTypesCountByAcct
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getTransactionTypesCountByAcct:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	
	if (!defined($acctId))
	{
		$dbErrMsg = $errPre . "expects one parameter (account Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare ("select count(*) as numrecs from transaction_type where acct_id = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	my $tempResRef = $stmt->fetchall_arrayref({});
	
	return $tempResRef->[0]->{'numrecs'};
}

sub getAllIncomeExpenseValues
{
  # this gets all the fixed expense/income values for a specified user
  undef($dbErrMsg);

  my $userId = shift();
  
  if (!$dbh)
  {
    $dbErrMsg = "Database handle not set in getAllIncomeExpenseValues, please connect first";
    return -1;
  }
  
  if (!$userId)
  {
    $dbErrMsg = "Must enter the user Id as a parameter in getAllIncomeExpenseValues";
    return -2;
  }
  
  $stmt = $dbh->prepare("select * from income_expense where userid = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = "There was an error in the prepare statement in getAllIncomeExpenseValues, " . $dbh->errstr();
    return -3;
  }
  
  $stmt->execute($userId);
  
  if ($stmt->err())
  {
    $dbErrMsg = "There was an error in the execute statement in getAllIncomeExpenseValues, " . $dbh->errstr();
    return -4;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = "There are no records returned in the query in getAllIncomeExpenseValues, " . $dbh->errstr();
    return NO_REC;
  }
  
  return 0;
}

#frequency functions
sub getFrequencyList
{
  undef($dbErrMsg);
  
  if (!$dbh)
  {
    $dbErrMsg = "The database handle is not set in getFrequencyList, please connect first";
    return -1;
  }
  
  $stmt = $dbh->prepare("select * from frequency");
  
  if ($dbh->err())
  {
    $dbErrMsg = "There was a problem with the prepare statement in getFrequencyList, " . $dbh->errstr();
    return -2;
  }
  
  $stmt->execute();
  
  if ($stmt->err())
  {
    $dbErrMsg = "There is an error in the excute statement in getFrequencyList, " . $stmt->errstr();
    return -3;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (scalar(@$resRef) < 0)
  {
    $dbErrMsg = "There are no rows to return in getFrequencyList";
    return NO_REC;
  }
  
  return 0;
}

sub getFrequency
{
  undef ($dbErrMsg);
  
  if (!$dbh)
  {
    $dbErrMsg = "The database handle is not set in getFrequency, please connect to the database first";
    return -1;
  }
  
  my $freqCd = shift();
  
  if (!$freqCd)
  {
    $dbErrMsg = "Need to send the frequency code in as a parameter in getFrequency";
    return -2;
  }
  
  $stmt = $dbh->prepare("select * from frequency where freq_cd = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = "There is an error in the prepare statement in getFrequency, " . $dbh->errstr();
    return -3;
  }
  
  $stmt->execute($freqCd);
  
  if ($stmt->err())
  {
    $dbErrMsg = "There is an error in the execute statement in getFrequency, " . $stmt->errstr();
    return -4;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (scalar(@$resRef) < 0)
  {
    $dbErrMsg = "No rows returned in getFrequency";
    return NO_REC;
  }
  
  return 0;
}

# lov category
sub getAllLoVCategories
{
  undef($dbErrMsg);
  
  my $errPre = "Error in getAllLoVCategories:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not set, please connect first";
    return NO_HANDLE;
  }
  
  $stmt = $dbh->prepare("select * from lov_category");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute();
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "There are no records being returned";
    return NO_REC;
  }
  
  return 0;
}

sub getLoVCategory
{
  # This is to get a specific LoV category
  undef($dbErrMsg);
  
  my $errPre = "Error in getLoVCategory:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle is not yet defined, please connect first";
    return NO_HANDLE;
  }
  
  my $catCd = shift();
  
  if (!defined($catCd))
  {
    $dbErrMsg = $errPre . "expects one parameter (category code)";
    return NO_PARM;
  }
  
  $stmt = $dbh->prepare("select * from lov_category where lov_cat_cd = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($catCd);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "There are no rows to return";
    return NO_REC;
  }
  
  return 0;
}

sub addLoVCategory
{
  undef($dbErrMsg);
  
  my $errPre = "Error in addLoVCategory:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $lovCatCd = shift();
  my $catDesc = shift();
  my $userId = shift();
  
  if (!defined($lovCatCd) || !defined($catDesc) || !defined($userId))
  {
    $dbErrMsg = $errPre . "expects three parameters (category code, category description and user Id)";
    return NO_PARM;
  }
  
  if (getLoVCategory($lovCatCd) == 0)
  {
    $dbErrMsg = $errPre . "Category code $lovCatCd already exists";
    return PARM_ERROR;
  }
  
  $stmt = $dbh->prepare("insert into lov_category (lov_cat_cd, cat_desc, crtn_id, upd_id) values (?, ?, ?, ?)");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($lovCatCd, $catDesc, $userId, $userId);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub deleteLoVCategory
{
  undef($dbErrMsg);
  
  my $errPre = "Error in deleteLoVCategory:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $lovCatCd = shift();
  
  if (!defined($lovCatCd))
  {
    $dbErrMsg = $errPre . "expects one parameter (category code)";
    return NO_PARM;
  }
  
  if (getLoVCategory($lovCatCd) < 0)
  {
    $dbErrMsg = $errPre . "LoV Category code $lovCatCd doesn't exist, " . $dbErrMsg;
    return PARM_ERROR;
  }
  
  $stmt = $dbh->prepare("delete from lov_category where lov_cat_cd = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($lovCatCd);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub updateLoVCategory
{
  undef($dbErrMsg);
  
  my $errPre = "Error in updateLoVCategory:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
    return NO_HANDLE;
  }
  
  my $lovCatCd = shift();
  my $catDesc = shift();
  my $userId = shift();
  my $oldLovCatCd = shift();
  
  if (!defined($lovCatCd) || !defined($catDesc) || !defined($userId) || !defined($oldLovCatCd))
  {
    $dbErrMsg = $errPre . "expects four parameters (category code, category description, user Id " . 
    					  " and old category code)";
    return NO_PARM;
  }
  
  if (getLoVCategory($lovCatCd) < 0)
  {
    $dbErrMsg = $errPre . "Category code $lovCatCd doesn't exist, " . $dbErrMsg;
    return PARM_ERROR;
  }
  
  $stmt = $dbh->prepare("update lov_category set lov_cat_cd = ?, cat_desc = ?, upd_id = ?, upd_ts = now() " . 
  											"where lov_cat_cd = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($lovCatCd, $catDesc, $userId, $oldLovCatCd);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }

# not allowing an update of the LoV category code in the application  
#  if ($lovCatCd ne $oldLovCatCd)
#  {
#  	# need to update the list of value entries
#  	if (updateLoVCatCdByCatCd($oldLovCatCd, $lovCatCd) < 0)
#  	{
#  		$dbErrMsg = $errPre . "parameter error ($dbErrMsg)";
#  		return PARM_ERROR;
#  	}
#  }
  
  return 0;
}

sub getAllCategoriesAndLimit
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getAllCategoriesAndLimit:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $offset = shift();
	my $recLimit = shift();
	
	if (!defined($offset) || !defined($recLimit))
	{
		$dbErrMsg = $errPre . "expects two parameters (offset and record limit)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from lov_category order by crtn_ts desc offset ? limit ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($offset, $recLimit);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getCategoriesCount
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getCategoriesCount:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	$stmt = $dbh->prepare("select count(*) as rec_count from lov_category");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute();
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	my $tempRef = $stmt->fetchall_arrayref({});
	
	return $tempRef->[0]->{'rec_count'};
}

# list of values
sub updateLoVCatCdByCatCd
{
	undef($dbErrMsg);
	
	my $errPre = "Error in updateLoVCatCdByCatCd:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $oldCatCd = shift();
	my $newCatCd = shift();
	
	if (!defined($oldCatCd) || !defined($newCatCd))
	{
		$dbErrMsg = $errPre . "expects two parameters (old category code and new category code";
		return NO_PARM;
	}
	
	if (getLoVCategory($newCatCd) < 0)
	{
		$dbErrMsg = $errPre . "parameter error ($dbErrMsg)";
		return PARM_ERROR;
	}
	
	$stmt = $dbh->prepare("update list_of_values set lov_cat_cd = ? where lov_cat_cd = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($newCatCd, $oldCatCd);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}
sub getAllListofValues
{
  undef($dbErrMsg);
  
  my $errPre = "Error in getAllListofValues:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not set, please connect first";
    return NO_HANDLE;
  }
  
  $stmt = $dbh->prepare("select * from list_of_values");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute();
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "There are no records being returned";
    return NO_REC;
  }
  
  return 0;
}

sub getListofValue
{
  # This is to get a specific List of Value entry
  undef($dbErrMsg);
  
  my $errPre = "Error in getListofValue:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle is not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $lovCd = shift();
  my $catCd = shift();
  
  if (!defined($catCd) || !defined($lovCd))
  {
    $dbErrMsg = $errPre . "expects two parameters (LoV code, and category code)";
    return NO_PARM;
  }
  
  $stmt = $dbh->prepare("select * from list_of_values where lov_cd = ? and lov_cat_cd = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($lovCd, $catCd);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "No records to return";
    return NO_REC;
  }
  
  return 0;
}

sub getAllListofValuesByCatCd
{
  undef($dbErrMsg);
  
  my $errPre = "Error in getAllListofValuesByCatCd:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle is not yet defined, please connect first";
    return NO_HANDLE;
  }
  
  my $catCd = shift();
  
  if (!defined($catCd))
  {
    $dbErrMsg = $errPre . "expects one parameter (category code)";
    return NO_PARM;
  }
  
  $stmt = $dbh->prepare("select * from list_of_values where lov_cat_cd = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($catCd);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "No records returned";
    return NO_REC;
  }
  
  return 0;
}

sub addListofValue
{
  undef($dbErrMsg);
  
  my $errPre = "Error in addListofValue:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $lovCd = shift();
  my $lovCatCd = shift();
  my $catDesc = shift();
  my $userId = shift();
  
  if (!defined($lovCatCd) || !defined($catDesc) || !defined($userId) || !defined($lovCd))
  {
    $dbErrMsg = $errPre . "expects four parameters (lov_cd, lov_cat_cd, cat_desc and user Id)";
    return NO_PARM;
  }
  
  if (getLoVCategory($lovCatCd) < 0)
  {
    $dbErrMsg = $errPre . "Category code $lovCatCd doesn't exist, it needs to exist";
    return PARM_ERROR;
  }
  
  if (getListofValue($lovCd, $lovCatCd) == 0)
  {
    $dbErrMsg = $errPre . "LoV code $lovCd, Cat code $lovCatCd combination already exists";
    return PARM_ERROR;
  }
  
  $stmt = $dbh->prepare("insert into list_of_values (lov_cd, lov_cat_cd, lov_desc, crtn_id, upd_id) values (?, ?, ?, ?, ?)");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($lovCd, $lovCatCd, $catDesc, $userId, $userId);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub deleteListofValue
{
  undef($dbErrMsg);
  
  my $errPre = "Error in deleteListofValue:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $lovCd = shift();
  my $lovCatCd = shift();
  
  if (!defined($lovCatCd) || !defined($lovCd))
  {
    $dbErrMsg = $errPre . "expects two paramters (lov_cd, lov_cat_cd)";
    return NO_PARM;
  }
  
  if (getListofValue($lovCd, $lovCatCd) < 0)
  {
    $dbErrMsg = $errPre . "LoV code $lovCd, Cat code $lovCatCd doesn't exist";
    return PARM_ERROR;
  }
  
  $stmt = $dbh->prepare("delete from list_of_values where lov_cd = ? and lov_cat_cd = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($lovCd, $lovCatCd);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub updateListofValue
{
  undef($dbErrMsg);
  
  my $errPre = "Error in updateListofValue:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
    return NO_HANDLE;
  }
  
  my $lovCd = shift();
  my $lovCatCd = shift();
  my $lovDesc = shift();
  my $userId = shift();
  
  if (!defined($lovCatCd) || !defined($lovCd))
  {
    $dbErrMsg = $errPre . "expects four parameters (lov_cd, lov_cat_cd, lov_desc, user Id)";
    return NO_PARM;
  }
  
  if (getListofValue($lovCd, $lovCatCd) < 0)
  {
    $dbErrMsg = $errPre . "List of Value code $lovCd, Category code $lovCatCd combination doesn't exist";
    return PARM_ERROR;
  }
  
  $stmt = $dbh->prepare("update list_of_values set lov_desc = ?, upd_id = ?, upd_ts = now() where lov_cd = ? and lov_cat_cd = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($lovDesc, $userId, $lovCd, $lovCatCd);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub getListofValuesAndLimit
{
	undef ($dbErrMsg);
	
	my $errPre = "Error in getListofValuesAndLimit:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $offset = shift();
	my $limit  = shift();
	
	if (!defined($offset) || !defined($limit))
	{
		$dbErrMsg = $errPre . "expects two parameters (record set offset and how many records)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from list_of_values order by lov_cat_cd offset ? limit ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($offset, $limit);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
}

sub getListofValuesCount
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getListofValuesCount:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	$stmt = $dbh->prepare("select count(*) as row_count from list_of_values");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute();
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	my $tempRef = $stmt->fetchall_arrayref({});
	
	return $tempRef->[0]->{'row_count'};
}

# income/expense functions
sub getAllIncomeExpense
{
  undef($dbErrMsg);
  
  my $errPre = "Error in getAllIncomeExpense:  ";
  
  if (!$dbh)
  {
    $dbErrMsg = $errPre . "Database handle not set, please connect first";
    return NO_HANDLE;
  }

  my $acctId = shift();
  
  if (!$acctId)
  {
    $dbErrMsg = $errPre. "expects one parameter (user Id)";
    return NO_PARM;
  }
  
  $stmt = $dbh->prepare("select * from income_expense where acct_id = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($acctId);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "There are no records being returned";
    return NO_REC;
  }
  
  return 0;
}

sub getIncomeExpense
{
  undef($dbErrMsg);
  
  my $errPre = "Error in getIncomeExpense:  ";
  
  if (!$dbh)
  {
    $dbErrMsg = $errPre . "Database handle is not yet defined, please connect first";
    return NO_HANDLE;
  }
  
  my $acctId = shift();
  my $seq = shift();
  
  if (!defined($acctId) || !defined($seq))
  {
    $dbErrMsg = $errPre . "expects two parameters (account Id and sequence)";
    return NO_PARM;
  }
  
  $stmt = $dbh->prepare("select * from income_expense where acct_id = ? and seq = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($acctId, $seq);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "There are no rows to return";
    return NO_REC;
  }
  
  return 0;
}

sub getIncomeExpenseByAcctAndLimit
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getIncomeExpenseByAcctAndLimit:  ";
	$moreRecs = 0;
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $offset = shift();
	my $recLimit = shift();
	
	if (!defined($acctId) || !defined($offset) || !defined($recLimit))
	{
		$dbErrMsg = $errPre . "expects three parameters (account Id, offset and record limit)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from income_expense where acct_id = ? order by seq desc limit ? offset ?");
	
	if ($dbh->errstr())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $recLimit, $offset);
	
	if ($stmt->errstr())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
#	my $numRecs = scalar(@$resRef);
#	
#	if ($numRecs >= $recLimit)
#	{
#		my $nextSeq = $resRef->[$numRecs - 1]->{'seq'};
#		$stmt = $dbh->prepare("select * from income_expense where acct_id = ? and seq > ? limit 1");
#		
#		if ($dbh->errstr())
#		{
#			$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
#			return NO_PREPARE;
#		}
#		
#		$stmt->execute($acctId, $nextSeq);
#		
#		if ($stmt->errstr())
#		{
#			$dbErrMsg = $errPre . "execute statement, " . $dbh->errstr();
#			return NO_EXECUTE;
#		}
#		
#		my $nextRecs = $stmt->fetchall_arrayref({});
#		
#		if (@$nextRecs)
#		{
#			$moreRecs = 1;
#		}
#	}
	
	return 0;
}

sub getIncomeExpenseCountByAcct
{
	undef ($dbErrMsg);
	
	my $errPre = "Error in getIncomeExpenseCountByAcct:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	
	if (!defined($acctId))
	{
		$dbErrMsg = $errPre . "expects one parameter (account Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select count(*) as numrecs from income_expense where acct_id = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	my $tempRef = $stmt->fetchall_arrayref({});
	
	return $tempRef->[0]->{'numrecs'};
}

#
#This subroutine is used to get a list of all the buckets by account id
#Parameters
#  $acctId - the account to use
#
sub getIncomeExpensesByAcctId
{
	undef ($dbErrMsg);
	
	my $errPre = "Error in getIncomeExpensesByAcctId:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	
	if (!defined($acctId))
	{
		$dbErrMsg = $errPre . "expects one parameter (account Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from income_expense where acct_id = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	return 0;
}

sub addIncomeExpense
{
  undef($dbErrMsg);
  
  my $errPre = "Error in addIncomeExpense:  ";
  
  if (!$dbh)
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $acctId = shift();
  my $freq = shift();
  my $incExp = shift();
  my $transType = shift();
  my $incexpDesc = shift();
  my $valueType = shift();
  my $fixedAmt = shift();
  my $rangeLowAmt = shift();
  my $rangeHighAmt = shift();
  my $userId = shift();
  my $autoProcessInd = shift();
  my $outMSSeq = shift();
  my $inMSSeq = shift();
  my $lastProcessDt = shift();
  
  if (!defined($freq) || !defined($incExp) || !defined($transType) || !defined($incexpDesc) || 
      !defined($valueType) || !defined($fixedAmt) || !defined($rangeLowAmt) || !defined($rangeHighAmt) || 
      !defined($acctId) || !defined($userId) || !defined($autoProcessInd) || !defined($outMSSeq) ||
      !defined($inMSSeq) || !defined($lastProcessDt))
  {
    $dbErrMsg = $errPre . "expects fourteen parameters (acctId, freq, incExp, transType, incexpDesc, " .
                "valueType, fixed amount, range low amount, range high amount, user Id, auto processing indicator, " . 
                "out money source sequence, in money source sequence and last process date)";
    return PARM_ERROR;
  }
  
  undef($lastProcessDt) if ($lastProcessDt eq "");
  
#  if (getListofValue($freq, "FREQENCY") < 0)
#  {
#    $dbErrMsg = $errPre . "Parameter error, Frequency, $freq doesn't exist in the list of values table";
#    return PARM_ERROR;
#  }
#  
#  if (getListofValue($incExp, "EXPINCID") < 0)
#  {
#    $dbErrMsg = $errPre . "Parameter error, Expense/Income type $incExp doesn't exist in the list of " .
#    						"values table";
#    return PARM_ERROR;
#  }
#  
#  if (getListofValue($valueType, "INEXPTYP") < 0)
#  {
#    $dbErrMsg = $errPre . "Parameter error, Record type code, $valueType doesn't exist in the list of " .
#                "values table";
#    return PARM_ERROR;
#  }
#  
#  if (getTransactionType($transType, $acctId) < 0)
#  {
#    $dbErrMsg = $errPre . "Parameter error, Transaction type, $transType doesn't exist in the transaction " .
#    						"type table";
#    return PARM_ERROR;
#  }
#  
#  if ($outMSSeq > 0)
#  {
#  	if (getMoneySource($acctId, $outMSSeq) < 0)
#  	{
#  		$dbErrMsg = $dbErrMsg . $errPre . "Money source sequence $outMSSeq doesn't exist";
#  		return PARM_ERROR;
#  	}
#  }
#  
#  if ($inMSSeq > 0)
#  {
#  	if (getMoneySource($acctId, $inMSSeq) < 0)
#  	{
#  		$dbErrMsg = $dbErrMsg . $errPre . "Money source sequence $inMSSeq doesn't exist";
#  		return PARM_ERROR;
#  	}
#  }
  
  $stmt = $dbh->prepare("select max(seq) as seq from income_expense where acct_id = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($acctId);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $dbh->errstr();
    return NO_EXECUTE;
  }
  
  my $seq = 1;
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (@$resRef)
  {
    $seq = $resRef->[0]->{'seq'} + 1;
  }
  
  $stmt = $dbh->prepare("insert into income_expense (acct_id, seq, fixed_amt, freq, crtn_id, upd_id, inc_exp, " .
                        "value_type, range_low_amt, range_high_amt, trans_type, incexp_desc, " .
                        "auto_process_ind, out_ms_seq, in_ms_seq, last_process_dt) values " .
                        "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($acctId, $seq, $fixedAmt, $freq, $userId, $userId, $incExp, $valueType, $rangeLowAmt,
                 $rangeHighAmt, $transType, $incexpDesc, $autoProcessInd, $outMSSeq, $inMSSeq,
                 $lastProcessDt);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub updateIncomeExpense
{
  undef($dbErrMsg);
  
  my $errPre = "Error in updateIncomeExpense:  ";
  
  if (!$dbh)
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $acctId = shift();
  my $seq = shift();
  my $freq = shift();
  my $incExp = shift();
  my $transType = shift();
  my $incexpDesc = shift();
  my $valueType = shift();
  my $fixedAmt = shift();
  my $rangeLowAmt = shift();
  my $rangeHighAmt = shift();
  my $userId = shift();
  my $autoProcessInd = shift();
  my $outMSSeq = shift();
  my $inMSSeq = shift();
  my $lastProcessDt = shift();
  
  if (!defined($seq) || !defined($freq) || !defined($incExp) || !defined($transType) || 
      !defined($incexpDesc) || !defined($valueType) || !defined($fixedAmt) || !defined($rangeLowAmt) || 
      !defined($rangeHighAmt) || !defined($userId) || !defined($acctId) || !defined($autoProcessInd) ||
      !defined($outMSSeq) || !defined($inMSSeq) || !defined($inMSSeq))
  {
    $dbErrMsg = $errPre . "expects fifteen parameters (account Id, sequence, freq, incExp, transType, incexpDesc, " .
    						"valueType, fixed amount, range low amount, range high amount, user Id, auto process indicator, " . 
    						"out money source sequence, in money source sequence and last process date)";
    return NO_PARM;
  }
  
  undef($lastProcessDt) if ($lastProcessDt eq "");
  
#  if (getListofValue($freq, "FREQENCY") < 0)
#  {
#    $dbErrMsg = $errPre . "Parameter error, Frequency, $freq doesn't exist in the list of values table";
#    return PARM_ERROR;
#  }
#  
#  if (getListofValue($incExp, "EXPINCID") < 0)
#  {
#    $dbErrMsg = $errPre . "Parameter error, Expense/Income type $incExp doesn't exist in the list of values table";
#    return PARM_ERROR;
#  }
#  
#  if (getListofValue($valueType, "INEXPTYP") < 0)
#  {
#    $dbErrMsg = $errPre . "Parameter error, Record type code, $valueType doesn't exist in the list of values table";
#    return PARM_ERROR;
#  }
#  
#  if (getTransactionType($transType, $acctId) < 0)
#  {
#    $dbErrMsg = $errPre . "Parameter error, Transaction type, $transType doesn't exist in the transaction type table";
#    return PARM_ERROR;
#  }
  
#  if ($outMSSeq > 0)
#  {
#  	if (getMoneySource($acctId, $outMSSeq) < 0)
#  	{
#  		$dbErrMsg = $dbErrMsg . $errPre . "Money source sequence $outMSSeq doesn't exist";
#  		return PARM_ERROR;
#  	}
#  }
#  
#  if ($inMSSeq > 0)
#  {
#  	if (getMoneySource($acctId, $inMSSeq) < 0)
#  	{
#  		$dbErrMsg = $dbErrMsg . $errPre . "Money souce sequence $inMSSeq doesn't exist";
#  		return PARM_ERROR;
#  	}
#  }
  
#  $stmt = $dbh->prepare("select * from income_expense where acct_id = ? and seq = ?");
#  
#  if ($dbh->err())
#  {
#    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
#    return NO_PREPARE;
#  }
#  
#  $stmt->execute($acctId, $seq);
#  
#  if ($stmt->err())
#  {
#    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
#    return NO_EXECUTE;
#  }
#  
#  $resRef = $stmt->fetchall_arrayref({});
#  
#  if (!@$resRef)
#  {
#    $dbErrMsg = $errPre . "Record with user Id, $userId and sequence $seq exists";
#    return NO_REC;
#  }
  
  $stmt = $dbh->prepare("update income_expense set freq = ?, fixed_amt = ?, upd_id = ?, upd_ts = now(), " .
                        "inc_exp = ?, value_type = ?, range_low_amt = ?, range_high_amt = ?, trans_type = ?, " .
                        "incexp_desc = ?, auto_process_ind = ?, out_ms_seq = ?, in_ms_seq = ?, " .
                        "last_process_dt = ? where acct_id = ? and seq = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($freq, $fixedAmt, $userId, $incExp, $valueType, $rangeLowAmt, $rangeHighAmt, $transType,
                 $incexpDesc, $autoProcessInd, $outMSSeq, $inMSSeq, $lastProcessDt, $acctId, $seq);
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $dbh->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub deleteIncomeExpense
{
  undef($dbErrMsg);
  
  my $errPre = "Error in deleteIncomeExpense:  ";
  
  if (!$dbh)
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
 
  my $acctId = shift();
  my $seq = shift();
  
  if (!defined($acctId) || !defined($seq))
  {
    $dbErrMsg = $errPre . "expects two paramters (account Id and sequence)";
    return NO_PARM;
  }
  
  if (getIncomeExpense($acctId, $seq) < 0)
  {
    $dbErrMsg = $errPre . "record doesn't exist with acct Id of $acctId and sequence $seq";
    return NO_REC;
  }
  
  $stmt = $dbh->prepare("delete from income_expense where acct_id = ? and seq = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($acctId, $seq);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

# transactions functions
sub getAllTransactions
{
  undef($dbErrMsg);
  
  my $errPre = "Error in getAllTransactions:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
    return NO_HANDLE;
  }

  my $acctId = shift();
  
  if (!defined($acctId))
  {
    $dbErrMsg = $errPre . "expects one parameter (account Id)";
    return NO_PARM;
  }
  
  $stmt = $dbh->prepare("select * from transactions where acct_id = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre .  "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($acctId);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "There are no records being returned";
    return NO_REC;
  }
  
  return 0;
}

sub getTransaction
{
  undef($dbErrMsg);
  
  my $errPre = "Error in getTransaction:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle is not yet defined, please connect first";
    return NO_HANDLE;
  }
  
  my $acctId = shift();
  my $transDate = shift();
  my $seq = shift();
  
  if (!defined($acctId) || !defined($seq) || !defined($transDate))
  {
    $dbErrMsg = $errPre . "expects three parameters (account Id, sequence and transaction date)";
    return NO_PARM;
  }
  
  $stmt = $dbh->prepare("select * from transactions where acct_id = ? and seq = ? and trans_date = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($acctId, $seq, $transDate);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "There are no rows to return";
    return NO_REC;
  }
  
  return 0;
}

sub addTransaction
{
  undef($dbErrMsg);
  
  my $errPre = "Error in addTransaction:  ";
  
  #$userId, $transDate, $amt, $incExpSeq, $transType, $transTxt
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $acctId = shift();
  my $transDate = shift();
  my $amt = shift();
  my $incExpSeq = shift();
  my $transType = shift();
  my $transTxt = shift();
  my $userId = shift();
  my $msSeq  = shift();
  my $inOut  = shift();

  if (!defined($acctId) || !defined($transDate) || !defined($amt) || !defined($incExpSeq) ||
      !defined($transType) || !defined($transTxt) || !defined($userId) || !defined($msSeq) ||
      !defined($inOut))
  {
    $dbErrMsg = $errPre . "expects nine parameters (account Id, transaction date, amount, income/expense record, " .
                "bucket, transaction description, user Id, money source and incoming or outgoing transaction)";
    return NO_PARM;
  }
  
  my $tempTrans;
  if ($incExpSeq ne "")
  {
    if (getIncomeExpense($acctId, $incExpSeq) < 0)
    {
      $dbErrMsg = $errPre . "Parameter error, Income/Expense record with sequence $incExpSeq doesn't exist " .
                  "in the income expense table";
      return PARM_ERROR;
    }
    else
    {
      $tempTrans = $resRef->[0]->{'trans_type'};
      
      if ($transType ne $tempTrans && $transType ne "")
      {
        $dbErrMsg = $errPre . "transaction type must match the income/expense transaction type";
        return PARM_ERROR;
      }
    }
  }
  
  if ($transType ne "")
  {
    if (getTransactionType($transType, $acctId) < 0)
    {
      $dbErrMsg = $errPre . "Parameter error, transaction type $transType doesn't exist in the " .
                  " transaction type table";
      return PARM_ERROR;
    }
    else
    {
      if ($incExpSeq ne "")
      {
        if ($tempTrans ne $transType)
        {
          $dbErrMsg = $errPre . "Parameter error, transaction type $transType not equal to income/expense " .
                      "transaction type $tempTrans, they must be equal";
          return PARM_ERROR;
        }
      }
    }
  }
  
  if (getListofValue($inOut, 'TRNSTYPE') < 0)
  {
  	$dbErrMsg = $dbErrMsg . $errPre . "transaction type of $inOut doesn't exist";
  	return PARM_ERROR;
  }
  
  if (getMoneySource($acctId, $msSeq) < 0)
  {
  	$dbErrMsg = $dbErrMsg . $errPre . "money source with sequence $msSeq doesn't exist";
  	return PARM_ERROR;
  }
  
  my $i = 1;
  $stmt = $dbh->prepare("select max(seq) as seq from transactions where acct_id = ? and trans_date = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement $i, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($acctId, $transDate);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement $i, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  my $seq = 1;
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (@$resRef)
  {
    $seq = $resRef->[0]->{'seq'} + 1;
  }
  
  if ($incExpSeq eq "")
  {
    $incExpSeq = 0;
  }
  
  $stmt = $dbh->prepare("insert into transactions (acct_id, trans_date, seq, amt, inc_exp_seq, crtn_id, " .
                        "upd_id, trans_type, trans_txt, ms_seq, in_out) values " .
                        "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
  $i = 2;
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement $i, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($acctId, $transDate, $seq, $amt, $incExpSeq, $userId, $userId, $transType, $transTxt,
  							 $msSeq, $inOut);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement $i, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub updateTransaction
{
  undef($dbErrMsg);
  
  my $errPre = "Error in updateTransaction:  ";
  
  #$userId, $transDate, $amt, $incExpSeq, $transType, $transTxt, $seq, $oldTransDate
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $acctId = shift();
  my $transDate = shift();
  my $amt = shift();
  my $incExpSeq = shift();
  my $transType = shift();
  my $transTxt = shift();
  my $seq = shift();
  my $oldTransDate = shift();
  my $userId = shift();
  my $msSeq  = shift();
  my $inOut  = shift();

  if (!defined($acctId) || !defined($transDate) || !defined($amt) || !defined($incExpSeq) ||
      !defined($transType) || !defined($transTxt) || !defined($seq) || !defined($oldTransDate) ||
      !defined($userId) || !defined($msSeq) || !defined($inOut))
  {
    $dbErrMsg = $errPre . "expects ten parameters (account Id, transaction date, amount, income/expense " .    
                "record, bucket, transaction description, sequence, old transaction date, user Id, " . 
                "money source and incoming or outgoing transaction)";
    return NO_PARM;
  }
  
  my $tempTrans;
  if ($incExpSeq ne "")
  {
    if (getIncomeExpense($acctId, $incExpSeq) < 0)
    {
      $dbErrMsg = $errPre . "Parameter error, Income/Expense record with sequence $incExpSeq doesn't " . 
                  "exist in the income expense table";
      return PARM_ERROR;
    }
    else
    {
      $tempTrans = $resRef->[0]->{'trans_type'};
      
      if ($transType ne $tempTrans && $transType ne "")
      {
        $dbErrMsg = $errPre . "parameter error, transaction type must match the income/expense transaction type";
        return PARM_ERROR;
      }
    }
  }
  
  my $oldSeq = $seq;
  
  if ($transType ne "")
  {
    if (getTransactionType($transType, $acctId) < 0)
    {
      $dbErrMsg = $errPre . "Parameter error, transaction type $transType doesn't exist in the " .
                  " transaction type table";
      return PARM_ERROR;
    }
    else
    {
      if ($incExpSeq ne "")
      {
        if ($tempTrans ne $transType)
        {
          $dbErrMsg = $errPre . "Parameter error, transaction type $transType not equal to income/expense " .
                      "transaction type $tempTrans, they must be equal";
          return PARM_ERROR;
        }
      }
    }
  }
  
  if (getListofValue($inOut, 'TRNSTYPE') < 0)
  {
  	$dbErrMsg = $dbErrMsg . $errPre . "transaction type of $inOut doesn't exist";
  	return PARM_ERROR;
  }
  
  if (getMoneySource($acctId, $msSeq) < 0)
  {
  	$dbErrMsg = $dbErrMsg . $errPre . "money source with sequence $msSeq doesn't exist";
  	return PARM_ERROR;
  }
  
  my $i = 1;
  
  if ($transDate ne $oldTransDate)
  {
    $stmt = $dbh->prepare("select max(seq) as seq from transactions where acct_id = ? and trans_date = ?");
  
    if ($dbh->err())
    {
      $dbErrMsg = $errPre . "prepare statement $i, " . $dbh->errstr();
      return NO_PREPARE;
    }
  
    $stmt->execute($acctId, $transDate);
  
    if ($stmt->err())
    {
      $dbErrMsg = $errPre . "execute statement $i, " . $stmt->errstr();
      return NO_EXECUTE;
    }
  
    $seq = 1;
  
    $resRef = $stmt->fetchall_arrayref({});
  
    if (@$resRef)
    {
      $seq = $resRef->[0]->{'seq'} + 1;
    }
  }
  
  if ($incExpSeq eq "")
  {
    $incExpSeq = 0;
  }
  
  if (getTransaction($acctId, $oldTransDate, $oldSeq) < 0)
  {
    $dbErrMsg = $errPre . "record with transaction date of $oldTransDate and sequence of $oldSeq " .
                "doesn't exist";
    return PARM_ERROR;
  }
  
  $stmt = $dbh->prepare("update transactions set trans_date = ?, seq = ?, amt = ?, inc_exp_seq = ?, upd_id = ?, " .
                        "upd_ts = now(), trans_type = ?, trans_txt = ?, ms_seq = ?, in_out = ? " . 
                        "where acct_id = ? and trans_date = ? and seq = ?");
  
  $i = 2;
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement $i, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($transDate, $seq, $amt, $incExpSeq, $userId, $transType, $transTxt, $msSeq, $inOut, 
  							 $acctId, $oldTransDate, $oldSeq);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement $i, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub deleteTransaction
{
  undef($dbErrMsg);
  
  my $errPre = "Error in deleteTransaction:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
 
  my $acctId = shift();
  my $transDate = shift();
  my $seq = shift();
  
  if (!defined($acctId) || !defined($transDate) || !defined($seq))
  {
    $dbErrMsg = $errPre . "expects three paramters (account Id, transaction date and sequence)";
    return NO_PARM;
  }
  
  if (getTransaction($acctId, $transDate, $seq) < 0)
  {
    $dbErrMsg = $errPre . "transaction record doesn't exist with transaction date of $transDate and sequence $seq";
    return PARM_ERROR;
  }
  
  $stmt = $dbh->prepare("delete from transactions where acct_id = ? and trans_date = ? and seq = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($acctId, $transDate, $seq);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub getTransactionsByDateAndLimit
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getTransactionsByDateAndLimit:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId   = shift();
	my $fromDate = shift();
	my $toDate   = shift();
	my $offset   = shift();
	my $maxRecs  = shift();
	my $fromTransType = shift();
	my $toTransType;
	
	if (defined($fromTransType) && $fromTransType ne "")
	{
		$toTransType = $fromTransType;
	}
	else
	{
		$fromTransType = "  ";
		$toTransType = "ZZ";
	}
	
	if (!defined($acctId) || !defined($fromDate) || !defined($toDate) || !defined($offset) ||
		  !defined($maxRecs))
	{
		$dbErrMsg = $errPre . "expects five parameters (account Id, from date, to date, offset and max records)";
		return NO_PARM;
	}
	
	my $stmt = $dbh->prepare("select * from transactions " .
							 " where acct_id = ?" .
							 "   and trans_date between ? and ? " .
							 "   and trans_type between ? and ? " .
							 " order by trans_date desc, seq desc offset ? limit ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " .  $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $fromDate, $toDate, $fromTransType, $toTransType, $offset, $maxRecs);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getTransactionsCountByAcctAndDate
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getTransactionsCountByAcctAndDate:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId   = shift();
	my $fromDate = shift();
	my $toDate   = shift();
	my $fromTransType = shift();
	my $toTransType;
	
	if (defined($fromTransType) && $fromTransType ne "")
	{
		$toTransType = $fromTransType;
	}
	else
	{
		$fromTransType = "  ";
		$toTransType = "ZZ";
	}
	
	if (!defined($acctId) || !defined($fromDate) || !defined($toDate))
	{
		$dbErrMsg = $errPre . "expects three parameters (account Id, from date and to date)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select count(*) as numrecs from transactions".
					      " where acct_id = ?" .
					      "   and trans_date between ? and ?" . 
					      "   and trans_type between ? and ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $fromDate, $toDate, $fromTransType, $toTransType);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	my $tempRef = $stmt->fetchall_arrayref({});
	
	return $tempRef->[0]->{'numrecs'};
}


# group scripts functions
sub getAllGroupScripts
{
  undef($dbErrMsg);
  
  my $errPre = "Error in getAllGroupScripts:  ";
  
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  $stmt = $dbh->prepare("select * from group_scripts");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute();
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "There are no records to return";
    return NO_REC;
  }
  
  return 0;
}

sub getAllGroupScriptsByGroupCd
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getAllGroupScriptsByGroupCd:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle is not defined, please connect first";
		return NO_HANDLE;
	}
	
	my $groupCd = shift();
	
	if (!defined($groupCd))
	{
		$dbErrMsg = $errPre . "expects one parameter (group code)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from group_scripts where group_cd = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($groupCd);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getGroupScript
{
  undef($dbErrMsg);
  
  my $errPre = "Error in getGroupScript:  ";
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $groupCd = shift();
  my $scriptName = shift();
  
  if (!defined($groupCd) || !defined($scriptName))
  {
    $dbErrMsg = $errPre . "Expects two parameters (group code and script name)";
    return NO_PARM;
  }
  
  $stmt = $dbh->prepare("select * from group_scripts where group_cd = ? and script_name = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "Prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($groupCd, $scriptName);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "Execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "There are no records being returned";
    return NO_REC;
  }
  
  return 0;
}

sub addGroupScript
{
  undef ($dbErrMsg);
  
  my $errPre = "Error in addGroupScript:  ";
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $groupCd = shift();
  my $scriptName = shift();
  my $userId = shift();
  
  if (!defined($groupCd) || !defined($scriptName) || !defined($userId))
  {
    $dbErrMsg = $errPre . "expects three parameters (user Id, group code, script name)";
    return NO_PARM;
  }
  
  if (getListofValue($groupCd, "GROUP") < 0)
  {
    $dbErrMsg = $errPre . "group code $groupCd doesn't exist in list of values, " . $dbh->errstr();
    return PARM_ERROR;
  }
  
  if (getGroupScript($groupCd, $scriptName) == 0)
  {
    $dbErrMsg = $errPre . "group code $groupCd and script name $scriptName already exists";
    return PARM_ERROR;
  }
  
  $stmt = $dbh->prepare ("insert into group_scripts (group_cd, script_name, crtn_id, upd_id) values (?, ?, ?, ?)");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statment, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute ($groupCd, $scriptName, $userId, $userId);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub updateGroupScript
{
  undef ($dbErrMsg);
  
  my $errPre = "Error in UpdateGroupScript:  ";
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $groupCd = shift();
  my $scriptName = shift();
  my $oldGroupCd = shift();
  my $oldScriptName = shift();
  my $userId = shift();
  
  if (!defined($groupCd) || !defined($scriptName) || 
      !defined($oldGroupCd) || !defined($oldScriptName) || !defined($userId))
  {
    $dbErrMsg = $errPre . "expects five parameters (group code, script name, old group code, old script name " .
                "and user Id)";
    return NO_PARM;
  }
  
  if (getListofValue($groupCd, "GROUP") < 0)
  {
    $dbErrMsg = $errPre . "group code $groupCd doesn't exist in list of values, " . $dbh->errstr();
    return PARM_ERROR;
  }
  
  if (getGroupScript($groupCd, $scriptName) == 0)
  {
    $dbErrMsg = $errPre . "group code $groupCd and script name $scriptName already exists";
    return PARM_ERROR;
  }
  
  if (getGroupScript($oldGroupCd, $oldScriptName) < 0)
  {
  	$dbErrMsg = $errPre . "can't update a record that doesn't exist, group code $oldGroupCd, script name $oldScriptName";
  	return PARM_ERROR;
  }
  
  $stmt = $dbh->prepare ("update group_scripts set group_cd = ?, script_name = ?, upd_id = ?, upd_ts = now() " .
                         "where group_cd = ? and script_name = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statment, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute ($groupCd, $scriptName, $userId, $oldGroupCd, $oldScriptName);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  return 0;
}

sub deleteGroupScript
{
	undef($dbErrMsg);
	
	my $errPre = "Error in deleteGroupScript:  ";
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle not defined, please connect first";
		return NO_HANDLE;
	}
	
	my $groupCd = shift();
	my $scriptName = shift();
	
	if (!defined($groupCd) || !defined($scriptName))
	{
		$dbErrMsg = $errPre . "expects two parameters (group code and script name)";
		return NO_PARM;
	}
	
	if (getGroupScript($groupCd, $scriptName) < 0)
	{
		$dbErrMsg = $errPre . "doesn't exist";
		return PARM_ERROR;
	}
	
	$stmt = $dbh->prepare("delete from group_scripts where group_cd = ? and script_name = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "with the prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($groupCd, $scriptName);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "with the execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub getGroupScriptsAndLimit
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getGroupScriptsAndLimit:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $offset = shift();
	my $limit  = shift();
	
	if (!defined($offset) || !defined($limit))
	{
		$dbErrMsg = $errPre . "expects two parameters (offset and record limit)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from group_scripts order by crtn_ts desc offset ? limit ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($offset, $limit);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getGroupScriptsCount
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getGroupScriptsCount:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	$stmt = $dbh->prepare("select count(*) as row_count from group_scripts");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute();
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	my $tempRef = $stmt->fetchall_arrayref({});
	
	return $tempRef->[0]->{'row_count'};
}

#user_groups
sub getAllUserGroups
{
  undef($dbErrMsg);
  
  my $errPre = "Error in getAllUserGroups:  ";
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  $stmt = $dbh->prepare("select * from user_groups");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "Prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute();
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "Execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "There are no records being returned";
    return NO_REC;
  }
  
  return 0;
}

sub getUserGroup
{
	undef($dbErrMsg);
  
  my $errPre = "Error in getAllUserGroups:  ";
  if (!defined($dbh))
  {
    $dbErrMsg = $errPre . "Database handle not defined, please connect first";
    return NO_HANDLE;
  }
  
  my $formUserId = shift();
  my $groupCd = shift();
  
  if (!defined($formUserId) || !defined($groupCd))
  {
  	$dbErrMsg = $errPre . "expects two parameters (user Id and group code)";
  	return NO_PARM;
  }
  
  $stmt = $dbh->prepare("select * from user_groups where userid = ? and group_cd = ?");
  
  if ($dbh->err())
  {
    $dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
    return NO_PREPARE;
  }
  
  $stmt->execute($formUserId, $groupCd);
  
  if ($stmt->err())
  {
    $dbErrMsg = $errPre . "Execute statement, " . $stmt->errstr();
    return NO_EXECUTE;
  }
  
  $resRef = $stmt->fetchall_arrayref({});
  
  if (!@$resRef)
  {
    $dbErrMsg = $errPre . "There are no records being returned";
    return NO_REC;
  }
  
	return 0;
}

sub getAllUserGroupsByUserId
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getAllUserGroupsByUser:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle is not defined, please connect first";
		return NO_HANDLE;
	}
	
	my $userId = shift();
	
	if (!defined($userId))
	{
		$dbErrMsg = $errPre . "expects one parameter (user Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from user_groups where userid = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($userId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub addUserGroup
{
	undef ($dbErrMsg);
	
	my $errPre = "Error in addUserGroup:  ";
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle is not defined, please connect first";
		return NO_HANDLE;
	}
	
	my $formUser = shift();
	my $groupCd = shift();
	my $userId = shift();
	
	if (!defined($formUser) || !defined($groupCd) || !defined($userId))
	{
		$dbErrMsg = $errPre . "expects three parameters (user nickname (or email), group code and user Id)";
		return NO_PARM;
	}
	
	if (getUserByNickname($formUser) < 0)
	{
		if (getUserByEmail($formUser) < 0)
		{
			$dbErrMsg = $errPre . "user nickname or email by $formUser doesn't exist";
			return PARM_ERROR;
		}
	}
	
	my $formUserId = $resRef->[0]->{'userid'};
	
	if (getListofValue($groupCd, "GROUP") < 0)
	{
		$dbErrMsg = $errPre . "group $groupCd doesn't exist";
		return PARM_ERROR;
	}
	
	if (getUserGroup($formUserId, $groupCd) == 0)
	{
		$dbErrMsg = $errPre . "record with user $formUser and group $groupCd already exists";
		return PARM_ERROR;
	}
	
	$stmt = $dbh->prepare("insert into user_groups (userid, group_cd, crtn_id, upd_id) " .
	                      "values (?, ?, ?, ?)");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($formUserId, $groupCd, $userId, $userId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub updateUserGroup
{
	undef ($dbErrMsg);
	
	my $errPre = "Error in updateUserGroup:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle is not defined, please connect first";
		return NO_HANDLE;
	}
	
	my $formUser = shift();
	my $groupCd = shift();
	my $userId = shift();
	my $oldFormUserId = shift();
	my $oldGroupCd = shift();
	
	if (!defined($formUser) || !defined($groupCd) || !defined($userId) ||
	    !defined($oldFormUserId) || !defined($oldGroupCd))
	{
		$dbErrMsg = $errPre . "expects five parameters (user nickname (or email), group code, user Id, " .
		            "old user nickname (or email) and old group code)";
		return NO_PARM;
	}
	
	if (getUserGroup($oldFormUserId, $oldGroupCd) < 0)
	{
		$dbErrMsg = $errPre . "record with user Id of $oldFormUserId " .
		            "and group of $oldGroupCd";
		return PARM_ERROR;
	}
	
	if (getUserByNickname($formUser) < 0)
	{
		if (getUserByEmail($formUser) < 0)
		{
			$dbErrMsg = $errPre . "user nickname or email by $formUser doesn't exist";
			return PARM_ERROR;
		}
	}
	
	my $formUserId = $resRef->[0]->{'userid'};
	
	if (getListofValue("GROUP", $groupCd) < 0)
	{
		$dbErrMsg = $errPre . "group $groupCd doesn't exist";
		return PARM_ERROR;
	}
	
	$stmt = $dbh->prepare("update user_groups set userid = ?, group_cd = ?, upd_id = ?, upd_ts = now() " .
	                      "where userid = ? and group_cd = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($formUserId, $groupCd, $userId, $oldFormUserId, $oldGroupCd);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub deleteUserGroup
{
	undef($dbErrMsg);
	
	my $errPre = "Error in deleteUserGroup:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $formUserId = shift();
	my $groupCd = shift();
	
	if (!defined($formUserId) || !defined($groupCd))
	{
		$dbErrMsg = $errPre . "expects two parameters (form user Id and group code)";
		return NO_PARM;
	}
	
	if (getUserGroup($formUserId, $groupCd) < 0)
	{
		$dbErrMsg = $errPre . "user Id $formUserId and group code $groupCd doesn't exist";
		return PARM_ERROR;
	}
	
	$stmt = $dbh->prepare("delete from user_groups where userid = ? and group_cd = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "perpare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($formUserId, $groupCd);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $dbh->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub getUserGroupsAndLimit
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getUserGroupsAndLimit:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $offset = shift();
	my $limit  = shift();
	
	if (!defined($offset) || !defined($limit))
	{
		$dbErrMsg = $errPre . "expects two parameters (offset and record limit)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from user_groups order by crtn_ts offset ? limit ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($offset, $limit);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getUserGroupsCount
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getUserGroupsCount:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	$stmt = $dbh->prepare("select count(*) as row_count from user_groups");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute();
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	my $tempRef = $stmt->fetchall_arrayref({});
	
	return $tempRef->[0]->{'row_count'};
}

sub mydbDisconnect
{
  if (defined($dbh))
  {
  	$dbh->rollback();
    $dbh->disconnect();
  }
}

sub specialSpecialDisconnect
{
	if (defined($dbh))
	{
		$dbh->rollback();
		$dbh->disconnect();
	}
}

# user_accounts
sub getUserAccount
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getAccount:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle not defined, please connect first";
		return NO_HANDLE;
	}
	
	my $userId = shift();
	my $acctId = shift();
	
	if (!defined($userId) || !defined($acctId))
	{
		$dbErrMsg = $errPre . "expects two parameters (user Id and account Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from user_accounts where userid = ? and acct_id = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($userId, $acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	return 0;
}

sub getAccountsOwned
{
	undef ($dbErrMsg);
	
	my $errPre = "Error in getAccountsOwned:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle not defined, please connect first";
		return NO_HANDLE;
	}
	
	my $userId = shift();
	
	if (!defined($userId))
	{
		$dbErrMsg = $errPre . "expects one parameter (user Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from user_accounts where userId = ? and access = 'OWNER'");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($userId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statment, " . $dbh->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub getAllAccounts
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getAllAccounts:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle not defined, please connect first";
		return NO_HANDLE;
	}
	
	my $userId = shift();
	
	if (!defined($userId))
	{
		$dbErrMsg = $errPre . "expects one parameter (user Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from user_accounts where userid = ? order by access");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($userId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statment, " . $dbh->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre. "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getLastAccount
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getLastAccount:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle not defined, please connect first";
		return NO_HANDLE;
	}
	
	my $userId = shift();
	
	if (!defined($userId))
	{
		$dbErrMsg = $errPre . "expects one parameter (userId)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select max(acct_id) as acct_id from user_accounts where userid = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($userId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return $resRef->[0]->{'acct_id'};
}

sub getAccountOwner
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getAccountOwner:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle not defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	
	if (!defined($acctId))
	{
		$dbErrMsg = $errPre . "expects one parameter (acct Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from user_accounts where acct_id = ? and access = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, "OWNER");
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub addUserAccount
{
	undef($dbErrMsg);
	
	my $errPre = "Error in addUserAccount:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle not defined, please connect first";
		return NO_HANDLE;
	}
	
	my $userId = shift();
	my $acctId = shift();
	my $access = shift();
	my $crtnUser = shift();
	
	if (!defined($userId) || !defined($acctId) || !defined($access) || !defined($crtnUser))
	{
		$dbErrMsg = $errPre . "expects four parameters (user Id, account Id, access level and creation user)";
		return NO_PARM;
	}
	
	if (getUserAccount($userId, $acctId) == 0)
	{
		$dbErrMsg = $errPre . "record already exists with user Id $userId and account Id $acctId";
		return REC_FOUND;
	}
	
	$stmt = $dbh->prepare("insert into user_accounts (userid, acct_id, access, crtn_id, upd_id) values " .
	                      "(?, ?, ?, ?, ?)");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($userId, $acctId, $access, $crtnUser, $crtnUser);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $dbh->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub updateUserAccount
{
	undef($dbErrMsg);
	
	my $errPre = "Error in updateUserAccount:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $userId = shift();
	my $acctId = shift();
	my $access = shift();
	my $crtnUser = shift();
	
	if (!defined($userId) || !defined($acctId) || !defined($access) || !defined($crtnUser))
	{
		$dbErrMsg = $errPre . "expects four parameters (user Id, account Id, access level and creation user)";
		return NO_PARM;
	}
	
	if (getUserAccount($userId, $acctId) < 0)
	{
		$dbErrMsg = $errPre . "user $userId and account $acctId combination doesn't exist";
		return PARM_ERROR;
	}
	
	$stmt = $dbh->prepare("update user_accounts set access = ?, upd_id = ?, upd_ts = now() " .
												"where userid = ? and acct_id = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($access, $crtnUser, $userId, $acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
}

sub deleteUserAccount
{
	undef($dbErrMsg);
	
	my $errPre = "Error in deleteUserAccount:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $userId = shift();
	my $acctId = shift();
	
	if (!defined($userId) || !defined($acctId))
	{
		$dbErrMsg = $errPre . "expects two parameters (user Id and account Id)";
		return NO_PARM;
	}
	
	if (getUserAccount($userId, $acctId) < 0)
	{
		$dbErrMsg = $errPre . "combination user $userId and account $acctId not found";
		return PARM_ERROR;
	}
	
	$stmt = $dbh->prepare("delete from user_accounts where userid = ? and acct_id = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($userId, $acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub getUserAccountsAndLimit
{
	undef ($dbErrMsg);
	
	my $errPre = "Error in getUserAccountsAndLimit:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $offset = shift();
	my $limit  = shift();
	
	if (!defined($offset) || !defined($limit) || !defined($acctId))
	{
		$dbErrMsg = $errPre . "expects three parameters (account Id, offset and record limit)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from user_accounts where acct_id = ? order by crtn_ts desc offset ? limit ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $offset, $limit);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getUserAccountsCountByAcct
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getUserAccountsCountByAcct:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	
	if (!defined($acctId))
	{
		$dbErrMsg = $errPre . "expects one parameter (account Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select count(*) as row_count from user_accounts where acct_id = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	my $tempRef = $stmt->fetchall_arrayref({});
	
	return $tempRef->[0]->{'row_count'};
}

sub createNewAccount
{
	undef($dbErrMsg);
	
	my $errPre = "Error in createNewAcct:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle is not defined, please connect first";
		return NO_HANDLE;
	}
	
	my $userId = shift();
	
	if (!defined($userId))
	{
		$dbErrMsg = $errPre . "expects one parameter (user Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare ("insert into user_accounts (userid, access, crtn_id, upd_id) values " .
	                       "(?, ?, ?, ?)");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($userId, "OWNER", $userId, $userId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	my $lastAcctId = getLastAccount($userId);
	if ($lastAcctId < 0)
	{
		return NO_REC;
	}
	
	updateLastAcctId($userId, $lastAcctId);
	
	return $lastAcctId;
}

sub getAccount
{
	undef ($dbErrMsg);
	
	my $errPre = "Error in getAccout:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	
	if (!defined($acctId))
	{
		$dbErrMsg = $errPre . "expects one parameter (account Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from accounts where acct_id = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "exectute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub selectFirstAccount
{
	undef($dbErrMsg);
	
	my $errPre = "Error in selectFirstAccount:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	$stmt = $dbh->prepare("select * from accounts");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute();
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchrow_hashref();
	
	if (!%$resRef)
	{
		$dbErrMsg = $errPre . "no records to return";
		return NO_REC;
	}
	
	return 0;
}

# redirect table
sub getRedirect
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getRedirect:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $rdName = shift();
	
	if (!defined($rdName))
	{
		$dbErrMsg = $errPre . "expects one parameter (redirection name)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from redirect where rd_name = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($rdName);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getAllMoneySourcesByAcct
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getAllMoneySourcesByAcct:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	
	if (!defined($acctId))
	{
		$dbErrMsg = $errPre . "expects one parameter (account Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from money_source where acct_id = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getAllMoneySourcesByAcctAndLimit
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getAllMoneySourcesByAcctAndLimit:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $offset = shift();
	my $limit  = shift();
	
	if (!defined($acctId) || !defined($offset) || !defined($limit))
	{
		$dbErrMsg = $errPre . "expects three parameters (account Id, offset and limit)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from money_source where acct_id = ? order by crtn_ts desc offset ? limit ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $offset, $limit);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getMoneySource
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getMoneySource:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $seq    = shift();
	
	if (!defined($acctId) || !defined($seq))
	{
		$dbErrMsg = $errPre . "expects two parameters (account Id and sequence)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from money_source where acct_id = ? and seq = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $seq);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $dbh->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getMoneySourceCountByAcct
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getMoneySourceCountByAcct:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	
	if (!defined($acctId))
	{
		$dbErrMsg = $errPre . "expects one parameter (account Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select count(*) as row_count from money_source where acct_id = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	my $tempRef = $stmt->fetchall_arrayref({});
	
	return $tempRef->[0]->{'row_count'};
}

sub addMoneySource
{
	undef($dbErrMsg);
	
	my $errPre = "Error in addMoneySource:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId     = shift();
	my $sourceTxt  = shift();
	my $sourceType = shift();
	my $crtnUser   = shift();
	my $balance    = shift();
	$balance = 0.0 if (!defined($balance));
	
	if (!defined($acctId) || !defined($sourceTxt) || !defined($sourceType) || !defined($crtnUser))
	{
		$dbErrMsg = $errPre . "expects four parameters (account Id, source description, source type and creation user) " .
								"may also have an optional balance parameer";
		return NO_PARM;
	}
	
	if (getListofValue($sourceType, 'SRCTYPE') < 0)
	{
		$dbErrMsg = $dbErrMsg . $errPre . "source type $sourceType doesn't exist";
		return PARM_ERROR;
	}
	
	my $seq = 1;
	
	$stmt = $dbh->prepare("select max(seq) as max_seq from money_source where acct_id = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "first prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "first execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (@$resRef)
	{
		$seq = $resRef->[0]->{'max_seq'} + 1;
	}
	
	$stmt = $dbh->prepare("insert into money_source (acct_id, seq, source_txt, source_type, balance, crtn_id, " .
												"upd_id) values (?, ?, ?, ?, ?, ?, ?)");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "second prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $seq, $sourceTxt, $sourceType, $balance, $crtnUser, $crtnUser);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "second execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub updateMoneySource
{
	undef($dbErrMsg);
	
	my $errPre = "Error in updateMoneySource:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId     = shift();
	my $seq				 = shift();
	my $sourceTxt  = shift();
	my $sourceType = shift();
	my $updUser    = shift();
	my $balance    = shift();
	
	if (!defined($acctId) || !defined($sourceTxt) || !defined($sourceType) || !defined($updUser) ||
	    !defined($balance) || !defined($seq))
	{
		$dbErrMsg = $errPre . "expects six parameters (account Id, sequence, source text, source type, updated " .
							  "user Id and balance)";
		return NO_PARM;
	}
	
	if (getMoneySource($acctId, $seq) < 0)
	{
		$dbErrMsg = $dbErrMsg . $errPre . "account doesn't exist";
		return PARM_ERROR;
	}
	
	if (getListofValue($sourceType, 'SRCTYPE') < 0)
	{
		$dbErrMsg = $dbErrMsg . $errPre . "source type $sourceType doesn't exist";
		return PARM_ERROR;
	}
	
	$stmt = $dbh->prepare("update money_source set source_txt = ?, source_type = ?, balance = ?, upd_id = ?, " .
												"upd_ts = now() where acct_id = ? and seq = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($sourceTxt, $sourceType, $balance, $updUser, $acctId, $seq);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statment, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub deleteMoneySource
{
	# would advise not to delete the record (have transaction records associated with the account)
	undef($dbErrMsg);
	
	my $errPre = "Error in deleteMoneySource:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $seq    = shift();
	
	if (!defined($acctId) || !defined($seq))
	{
		$dbErrMsg = $errPre . "expects two parameters (account Id and sequence)";
		return NO_PARM;
	}
	
	if (getMoneySource($acctId, $seq) < 0)
	{
		$dbErrMsg = $dbErrMsg . $errPre . "record doesn't exist";
		return PARM_ERROR;
	}
	
	$stmt = $dbh->prepare("delete from money_source where acct_id = ? and seq = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $seq);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub addIncomingToMoneySource
{
	my $errPre = "Error in addIncomingToMoneySource:  ";
	
	undef($dbErrMsg);
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $msSeq  = shift();
	my $amt    = shift();
	my $userId = shift();
	
	if (!defined($acctId) || $acctId eq "" || !defined($msSeq) || $msSeq eq "" ||
			!defined($amt) || $amt eq "" || !defined($userId) || $userId eq "")
	{
		$dbErrMsg = $errPre . "expects four parameters (account Id, money source, amount and user Id)";
		return NO_PARM;
	}
	
	if (getMoneySource($acctId, $msSeq) < 0)
	{
		$dbErrMsg = $errPre . "parameter error:  " . $dbErrMsg;
		return PARM_ERROR;
	}
	
	my $newAmt = $database::resRef->[0]->{'balance'} + $amt;
	
	$stmt = $dbh->prepare("update money_source set amt = ?, upd_id = ? upd_ts = current_timestamp where acct_id = ? and seq = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "Prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($newAmt, $userId, $acctId, $msSeq);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "Execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub manipulateMSBalance
{
	my $errPre = "Error in manipulateMSBalance:  ";
	
	undef($dbErrMsg);
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $msSeq  = shift();
	my $amt    = shift();
	my $userId = shift();
	my $operation = shift();
	
	if (!defined($acctId) || $acctId eq "" || !defined($msSeq) || $msSeq eq "" ||
			!defined($amt) || $amt eq "" || !defined($userId) || $userId eq "" ||
			!defined($operation) || $operation eq "")
	{
		$dbErrMsg = $errPre . "expects five parameters (account Id, money source, amount, user Id and operation)";
		return NO_PARM;
	}
	
	if (getMoneySource($acctId, $msSeq) < 0)
	{
		$dbErrMsg = $errPre . "parameter error:  " . $dbErrMsg;
		return PARM_ERROR;
	}
	
	my $newAmt = $database::resRef->[0]->{'balance'};
	if ($operation  eq "subtract")
	{
		$newAmt = $newAmt - $amt;
	}
	elsif ($operation eq "add")
	{
		$newAmt = $newAmt + $amt;
	}
	
	$stmt = $dbh->prepare("update money_source set amt = ?, upd_id = ? upd_ts = current_timestamp where acct_id = ? and seq = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "Prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($newAmt, $userId, $acctId, $msSeq);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "Execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}
sub subOutgoingToMoneySource
{
	my $errPre = "Error in subOutgoingToMoneySource:  ";
	
	undef($dbErrMsg);
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $msSeq  = shift();
	my $amt    = shift();
	my $userId = shift();
	
	if (!defined($acctId) || $acctId eq "" || !defined($msSeq) || $msSeq eq "" ||
			!defined($amt) || $amt eq "" || !defined($userId) || $userId eq "")
	{
		$dbErrMsg = $errPre . "expects four parameters (account Id, money source, amount and user Id)";
		return NO_PARM;
	}
	
	if (getMoneySource($acctId, $msSeq) < 0)
	{
		$dbErrMsg = $errPre . "parameter error:  " . $dbErrMsg;
		return PARM_ERROR;
	}
	
	my $newAmt = $database::resRef->[0]->{'balance'} - $amt;
	
	$stmt = $dbh->prepare("update money_source set amt = ?, upd_id = ? upd_ts = current_timestamp where acct_id = ? and seq = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "Prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($newAmt, $userId, $acctId, $msSeq);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "Execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}
sub addSubMoneySource
{
	# this subroutine will add or subtract based on the input of the parameter
	# inOut which needs to be INCOMING or OUTGOING and the type of the money source
	# DEBIT or CREDIT
	# Here are the scenarios:
	# 	INCOMING/DEBIT  - adds to the balance
	#		INCOMING/CREDIT - subtracts from the balance
	#		OUTGOING/DEBIT  - subtracts from the balance
	#		OUTGOING/CREDIT - adds to the balance
	my $errPre = "Error in addSubMoneySource:  ";
	
	undef($dbErrMsg);
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "Database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $msSeq  = shift();
	my $amt    = shift();
	my $inOut  = shift();
	my $userId = shift();
	
	if (!defined($acctId) || !defined($msSeq) || !defined($amt) || !defined($inOut) || !defined($userId) ||
			$acctId eq "" || $msSeq eq "" || $amt eq "" || $inOut eq "" || $userId eq "")
	{
		$dbErrMsg = $errPre . "expects five parameters (account Id, money source, amount, in/out type and user Id)";
		return NO_PARM;
	}
	
	if ($inOut ne "INCOMING" && $inOut ne "OUTGOING")
	{
		$dbErrMsg = $errPre . "in/out type of $inOut is invalid, it needs to be either INCOMING or OUTGOING";
		return PARM_ERROR;
	}
	
	if (getMoneySource($acctId, $msSeq) < 0)
	{
		$dbErrMsg = $errPre . "parameter error:  " . $dbErrMsg;
		return PARM_ERROR;
	}
	
	my $curAmt = $database::resRef->[0]->{'balance'};
	my $newAmt = $curAmt;
	my $msType = $database::resRef->[0]->{'source_type'};
	
	if ($inOut eq "INCOMING" && $msType eq "DEBIT")
	{
		$newAmt = $curAmt + $amt;
	}
	elsif ($inOut eq "INCOMING" && $msType eq "CREDIT")
	{
		$newAmt = $curAmt - $amt;
	}
	elsif ($inOut eq "OUTGOING" && $msType eq "DEBIT")
	{
		$newAmt = $curAmt - $amt;
	}
	elsif ($inOut eq "OUTGOING" && $msType eq "CREDIT")
	{
		$newAmt = $curAmt + $amt;
	}
	
	$stmt = $dbh->prepare("update money_source set balance = ?, upd_id = ?, upd_ts = current_timestamp where acct_id = ? and seq = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "Prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($newAmt, $userId, $acctId, $msSeq);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "Execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

# buckets table
sub getBucketsByAcctId
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getBucketsByAcctId:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	
	if (!defined($acctId) || $acctId eq "")
	{
		$dbErrMsg = $errPre . "expects one parameter (account Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from buckets where acct_id = ? order by crtn_ts desc");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub getBucketByAcctAndLimit
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getBucketByAcctAndLimit:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . DBH_ERROR_STRING;
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $offset = shift();
	my $limit  = shift();
	
	if (!defined($acctId) || !defined($offset) || !defined($limit) ||
			$acctId eq "" || $offset eq "" || $limit eq "")
	{
		$dbErrMsg = $errPre . "expects three parameters (account Id, offset and record limit";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from buckets where acct_id = ? offset ? limit ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $offset, $limit);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . NO_RECORDS_STRING;
		return NO_REC;
	}
	
	return 0;
}

sub getBucketsCountByAcct
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getBucketsCountByAcct:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . DBH_ERROR_STRING;
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	
	if (!defined($acctId) || $acctId eq "")
	{
		$dbErrMsg = $errPre . "expects one parameter (account Id)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select count(*) as row_count from buckets where acct_id = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	my $tempRef = $stmt->fetchall_arrayref({});
	
	return $tempRef->[0]->{'row_count'}; 
}

sub getBucket
{
	undef($dbErrMsg);
	
	my $errPre = "Error in getBucket:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $seq    = shift();
	
	if (!defined($acctId) || $acctId eq "" || !defined($seq) || $seq eq "")
	{
		$dbErrMsg = $errPre . "expects two parameters (account Id and sequence)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("select * from buckets where acct_id = ? and seq = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $seq);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	$resRef = $stmt->fetchall_arrayref({});
	
	if (!@$resRef)
	{
		$dbErrMsg = $errPre . "no records returned";
		return NO_REC;
	}
	
	return 0;
}

sub addBucket
{
	undef($dbErrMsg);
	
	my $errPre = "Error in addBucket:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $balance = shift();
	my $refreshAmt = shift();
	my $fixVar = shift();
	my $buckDesc = shift();
	my $userId = shift();
	my $refreshFreq = shift();
	my $lastProcessDt = shift();
	my $autoProcessInd = shift();
	
	if (!defined($acctId) || $acctId eq "" || !defined($balance) || $balance eq "" || !defined($refreshAmt) ||
			$refreshAmt eq "" || !defined($fixVar) || $fixVar eq "" || !defined($buckDesc) || $buckDesc eq "" ||
			!defined($userId) || $userId eq "" || !defined($refreshFreq) || $refreshFreq eq "" ||
			!defined($lastProcessDt) || !defined($autoProcessInd) || $autoProcessInd eq "")
	{
		$dbErrMsg = $errPre . "expects nine parameters (account Id, balance, refresh amount, fixed or variable, " .
								"bucket description, user Id, refresh frequency, last process date and auto process indicator)";
		return NO_PARM;
	}
	
	$lastProcessDt = "null" if ($lastProcessDt eq "");

	my $i = 1;
	
	my $seq = 1;
	
	$stmt = $dbh->prepare("select max(seq) as max_seq from buckets where acct_id = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement # $i, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement # $i, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	my $tempRef = $stmt->fetchall_arrayref({});
	
	if (@$tempRef)
	{
		$seq = $tempRef->[0]->{'max_seq'} + 1;
	}
	
	$stmt = $dbh->prepare("insert into buckets (acct_id, seq, balance, refresh_amt, fix_var, buck_desc, " .
												"refresh_freq, last_process_dt, auto_process_ind, crtn_id, upd_id) " .
												"values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
	
	$i = 2;
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement # $i, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $seq, $balance, $refreshAmt, $fixVar, $buckDesc, $refreshFreq, $lastProcessDt,
								 $autoProcessInd, $userId, $userId);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement # $i, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return $seq;
}

sub deleteBucket
{
	undef($dbErrMsg);
	
	my $errPre = "Error in deleteBucket:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $seq    = shift();
	
	if (!defined($acctId) || $acctId eq "" || !defined($seq) || $seq eq "")
	{
		$dbErrMsg = $errPre . "expects two parameters (account Id and sequence)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("delete from buckets where acct_id = ? and seq = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($acctId, $seq);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub updateBucket
{
	undef($dbErrMsg);
	
	my $errPre = "Error in updateBucket:  ";
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $seq    = shift();
	my $balance = shift();
	my $refreshAmt = shift();
	my $fixVar = shift();
	my $buckDesc = shift();
	my $userId = shift();
	my $refreshFreq = shift();
	my $lastProcessDt = shift();
	my $autoProcessInd = shift();
	
	if (!defined($acctId) || $acctId eq "" || !defined($seq) || $seq eq "" || !defined($balance) || $balance eq "" ||
			!defined($refreshAmt) || $refreshAmt eq "" || !defined($fixVar) || $fixVar eq "" || !defined($buckDesc) ||
			$buckDesc eq "" || !defined($userId) || $userId eq "" || !defined($refreshFreq) || $refreshFreq eq "" ||
			!defined($lastProcessDt) || !defined($autoProcessInd) || $autoProcessInd eq "")
	{
		$dbErrMsg = $errPre . "expects ten parameters (account Id, sequence, balance, refresh amount, fixed/variable, " .
								"bucket description, user Id, refresh frequency, last process date, auto process indicator";
		return NO_PARM;
	}
	
	undef($lastProcessDt) if ($lastProcessDt eq "");
	
	$stmt = $dbh->prepare("update buckets set balance = ?, refresh_amt = ?, fix_var = ?, buck_desc = ?, " .
												"refresh_freq = ?, last_process_dt = ?, auto_process_ind = ?, upd_id = ?, " .
												"upd_ts = now() where acct_id = ? and seq = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($balance, $refreshAmt, $fixVar, $buckDesc, $refreshFreq, $lastProcessDt, $autoProcessInd,
								 $userId, $acctId, $seq);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub addSubBucket
{
	undef($dbErrMsg);
	
	my $errPre = "Error in addSubBucket:  ";
	
	my $acctId  = shift();
	my $buckSeq = shift();
	my $amt     = shift();
	my $inOut   = shift();
	my $userId  = shift();
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "handle isn't defined please connect first";
		return NO_HANDLE;
	}
	
	if (!defined($acctId) || !defined($inOut) || !defined($buckSeq) || !defined($amt) || !defined($userId) ||
			$acctId eq "" || $inOut eq "" || $buckSeq eq "" || $amt eq "" || $userId eq "")
	{
		$dbErrMsg = $errPre . "expects five parameters (account Id, in/out transaction, bucket, amount and user Id";
		return NO_PARM;		
	}
	
	if ($inOut eq "INCOMING")
	{
		$stmt = $dbh->prepare("update buckets set balance = balance + ?, upd_id = ?, upd_ts = now() where acct_id = ? and " .
													"seq = ?");
	}
	elsif ($inOut eq "OUTGOING")
	{
		$stmt = $dbh->prepare("update buckets set balance = balance - ?, upd_id = ?, upd_ts = now() where acct_id = ? and " .
													"seq = ?");
	}
	else
	{
		$dbErrMsg = $errPre . "in/out value of $inOut is invalid, must be INCOMING or OUTGOING";
		return PARM_ERROR;
	}
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($amt, $userId, $acctId, $buckSeq);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}

sub refreshBucket
{
	my $errPre = "Error in refreshBucket:  ";
	
	undef($dbErrMsg);
	
	if (!defined($dbh))
	{
		$dbErrMsg = $errPre . "database handle isn't defined, please connect first";
		return NO_HANDLE;
	}
	
	my $acctId = shift();
	my $userId = shift();
	my $buckSeq = shift();
	my $lastProcessDt = shift();
	
	if (!defined($acctId) || $acctId eq "" || !defined($buckSeq) || $buckSeq eq "" ||
			!defined($userId) || $userId eq "" || !defined($lastProcessDt) || $lastProcessDt eq "")
	{
		$dbErrMsg = $errPre . "expects four parameters (account Id, user Id, bucket sequence and last process date)";
		return NO_PARM;
	}
	
	$stmt = $dbh->prepare("update buckets set balance = balance + refresh_amt, last_process_dt = ?, " .
												"upd_id = ?, upd_ts = now() " .
												"where acct_id = ? and seq = ?");
	
	if ($dbh->err())
	{
		$dbErrMsg = $errPre . "prepare statement, " . $dbh->errstr();
		return NO_PREPARE;
	}
	
	$stmt->execute($lastProcessDt, $userId, $acctId, $buckSeq);
	
	if ($stmt->err())
	{
		$dbErrMsg = $errPre . "execute statement, " . $stmt->errstr();
		return NO_EXECUTE;
	}
	
	return 0;
}
1;
