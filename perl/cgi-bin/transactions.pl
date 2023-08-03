#!C:\strawberry\perl\bin\perl -w

use strict;
use database;
use CGI;
use CGI::Session;
use CGI::Carp qw( warningsToBrowser fatalsToBrowser );
use utilities qw( redirectIfNotPrivy
									printHeader
									processFields
									displayForm
									printFooter );

database::specialSpecialConnect();

redirectIfNotPrivy();

processFields();

printHeader("Transactions", "Transactions");

displayForm();

printFooter();

database::specialSpecialDisconnect();
