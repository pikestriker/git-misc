#!C:\strawberry\perl\bin\perl -w

use strict;
use CGI::Session;
use CGI;
use DBI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use utilities qw( checkLastAccount );

my $cgi = new CGI();

print $cgi->header(),
      $cgi->start_html("test page");

print <<endHTML;
       <form name="form1" action="test.pl" method="get">
       <input type="submit" value="createSomething" />
       </form>
       <form name="form2" action="test.pl" method="get">
       <input name="myfield" type="text" />
       <input type="submit" value="sendSomething" />
       </form>
endHTML

print "<table border=\"1\">\n";
print "<tr><td><b>Key</b></td><td><b>Value</b></td></tr>\n";
foreach (keys(%ENV))
{
  print "<tr>\n";
  print "<td>$_</td><td>$ENV{$_}</td>\n";
  print "</tr>\n";
}
print "</table>\n";

#print "<table border=\"1\" cellpadding=\"0\" cellspacing=\"0\">\n";
#foreach my $key (keys(%ENV))
#{
#	if (defined($ENV{$key}))
#	{
#		print "<tr><td>$key</td><td>$ENV{$key}</td></tr>\n";
#	}
#}
#print "</table>\n";
print $cgi->end_html();
#my $dbh = DBI->connect("dbi:Pg:dbname=mydb", "", "");
#
##my $stmt = $dbh->prepare("\\d income_expense");
#my $stmt = $dbh->column_info("", "", "income_expense", "");
#
#if ($dbh->err())
#{
#	print "Error in the prepare statement, " . $dbh->errstr() . "\n";
#	exit 1;
#}
#$stmt->execute();
#
#if ($stmt->err())
#{
#	print "Error in the execute statement, " . $dbh->errstr() . "\n";
#	exit 2;
#}

#my $resRef = $stmt->fetchall_arrayref({});
#
#foreach my $ref (@$resRef)
#{
#	foreach my $key (keys(%$ref))
#	{
#		if (defined($ref->{$key}))
#		{
#			print "$key => $ref->{$key}\n";
#		}
#	}
#	print "-----------------------------------------------------------------------------\n";
#}
