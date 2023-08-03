#!C:\strawberry\perl\bin\perl -w

use strict;

print "Content-type: text/html\n\n";

print <<endHTML;
<html>
<head>
<title>This is a gameboard</title>
<link rel="stylesheet" href="/css/greensquares.css" type="text/css" />
</head>
<body>
<table class="greenboard">
endHTML
for ((my $i) = 0; $i < 8; $i++)
{
  print "<tr>\n";
  for ((my $j) = 0; $j < 8; $j++)
  {
    print "<td class=\"greensquare\"></td>\n";
  }
  print "</tr>\n";
}
print <<endHTML;
</table>
</body>
</html>
endHTML

