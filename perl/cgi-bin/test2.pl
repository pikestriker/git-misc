#!C:\strawberry\perl\bin\perl -w

use strict;
use utilities qw( resolveRedirect );

my $loginPage = resolveRedirect('LOGIN');
print "$loginPage\n";
