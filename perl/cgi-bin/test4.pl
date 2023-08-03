#!C:\strawberry\perl\bin\perl -w

use strict;
use utilities;
use database;
use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

my $cgi = new CGI();

print $cgi->header();
print $cgi->start_html();

print "<table>\n";
foreach my $key ( keys(%ENV) )
{
  print "<tr><td>$key</td><td>$ENV{$key}</td></tr>\n";
}
print "</table>\n";
print $cgi->end_html();
